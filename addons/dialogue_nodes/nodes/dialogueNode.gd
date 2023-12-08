@tool
extends GraphNode


signal modified
signal connection_move(old_slot, new_slot)

@export var max_options = 4
@export var bbcode_color = Color('a5efac')

@onready var speaker = $HBoxContainer/Speaker
@onready var customSpeaker := $HBoxContainer/CustomSpeaker
@onready var characterToggle = $HBoxContainer/CharacterToggle
@onready var dialogue = %Dialogue
@onready var dialogue_panel = %DialoguePanel
@onready var dialogue_expanded = %DialogueExpanded

var curSpeaker : int = -1
var options : Array = []
var option_scene := preload("res://addons/dialogue_nodes/nodes/DialogueNodeOption.tscn")
var _base_color : Color = Color.WHITE

func _ready():
	for i in range(max_options):
		if has_node('Option'+str(i+1)):
			var option = get_node( NodePath('Option'+str(i+1)) )
			options.append(option)
			option.text_changed.connect(_on_option_changed.bind(option))
			option.text_submitted.connect(_on_option_entered.bind(option))
			option.focus_exited.connect(_on_option_entered.bind('', option))
			set_slot(option.get_index(), false, 0, _base_color, true, 0, _base_color)
	
	# add bbcode syntax highlighting in dialogue
	if not dialogue.syntax_highlighter.has_color_region('['):
		dialogue.syntax_highlighter.add_color_region('[', ']', bbcode_color)
	if not dialogue_expanded.syntax_highlighter.has_color_region('['):
		dialogue_expanded.syntax_highlighter.add_color_region('[', ']', bbcode_color)


func _exit_tree():
	option_scene = null
	options.clear()


func add_option(new_text= '', new_condition= {}):
	if len(options) == max_options:
		return
	
	var new_option = option_scene.instantiate()
	var id = len(options)
	
	new_option.name = 'Option'+str(id+1)
	add_child(new_option, true)
	new_option.set_text(new_text)
	new_option.set_placeholder_text('Option'+str(id+1))
	new_option.set_condition(new_condition)
	
	options.append(new_option)
	new_option.text_changed.connect(_on_option_changed.bind(new_option))
	new_option.text_submitted.connect(_on_option_entered.bind(new_option))
	new_option.focus_exited.connect(_on_option_entered.bind('', new_option))


func remove_option(option_node):
	if len(options) == 1:
		return
	
	var i = options.find(option_node) + 1
	
	while i < len(options):
		options[i-1].set_text(options[i].text)
		options[i-1].set_condition(options[i].get_condition())
		connection_move.emit(i, i-1)
		i += 1
	
	options[-1].set_text('')
	options[-1].queue_free()
	options.pop_back()
	
	if i == len(options):
		options[i].grab_focus()


func _update_slots():
	# turn off all slots whose options are empty
	for i in range(len(options)):
		set_slot(options[i].get_index(), false, 0, _base_color, (options[i].text != ''), 0, _base_color)
	
	# set the first slot to true anyway
	set_slot(options[0].get_index(), false, 0, _base_color, true, 0, _base_color)


func _set_syntax_color(color):
	_base_color = color
	dialogue.syntax_highlighter.number_color = color
	dialogue.syntax_highlighter.symbol_color = color
	dialogue.syntax_highlighter.function_color = color
	dialogue.syntax_highlighter.member_variable_color = color


func _to_dict(graph):
	var dict = {}
	
	if customSpeaker.visible:
		customSpeaker.text = customSpeaker.text.replace('{', '').replace('}', '')
		dict['speaker'] = customSpeaker.text
	elif speaker.visible:
		var speakerIdx := -1
		if speaker.item_count > 0:
			speakerIdx = curSpeaker
		dict['speaker'] = speakerIdx
	
	dict['dialogue'] = dialogue.text
	dict['size'] = {}
	dict['size'] = size
	
	# get options connected to other nodes
	var options_dict = {}
	for connection in graph.get_connection_list():
		if connection['from_node'] == name:
			var idx : int = connection['from_port'] # this returns index starting from 0
			options_dict[idx] = {}
			options_dict[idx]['text'] = options[idx].text
			options_dict[idx]['link'] = connection['to_node']
			options_dict[idx]['condition'] = options[idx].get_condition() if options[idx].text != '' else {}
	
	# get options not connected
	for i in range(len(options)):
		if not options_dict.has(i) and options[i].text != '':
			options_dict[i] = {}
			options_dict[i]['text'] = options[i].text
			options_dict[i]['link'] = 'END'
			options_dict[i]['condition'] = options[i].get_condition()
	
	# single empty disconnected option
	if not options_dict.has(0):
		options_dict[0] = {}
		options_dict[0]['text'] = options[0].text
		options_dict[0]['link'] = 'END'
		options_dict[0]['condition'] = {}
	
	# store options info in dict
	dict['options'] = options_dict
	
	return dict


func _from_dict(graph, dict):
	var next_nodes = []
	
	# set values
	if dict['speaker'] is String:
		customSpeaker.text = dict['speaker']
	elif dict['speaker'] is int:
		curSpeaker = dict['speaker']
		characterToggle.button_pressed = true
	dialogue.text = dict['dialogue']
	
	# remove any existing options
	for option in options:
		option.queue_free()
	options.clear()
	
	# add new options
	for key in dict['options']:
		var condition = {}
		if dict['options'][key].has('condition'):
			condition = dict['options'][key]['condition']
		add_option(dict['options'][key]['text'], condition)
		next_nodes.append(dict['options'][key]['link'])
	
	# set size of node
	if dict.has('size'):
		var new_size: Vector2
		if dict['size'] is Vector2:
			new_size = dict['size']
		else: # for dialogue files created before v1.0.2
			new_size = Vector2( float(dict['size']['x']), float(dict['size']['y']) )
		_on_resize(new_size, true)
	
	_update_slots()
	
	return next_nodes


# on text change
func _on_option_changed(new_text, option_node):
	if option_node == options[-1]:
		add_option()
	if new_text != '':
		_update_slots()
	_on_node_modified()


# on text confirmation
func _on_option_entered(_new_text, option_node):
	if option_node.text == '' and option_node != options[-1]:
		remove_option(option_node)
		_update_slots()
	_on_node_modified()


func _on_resize(new_size, _loading = false):
	new_size.x = max(new_size.x, custom_minimum_size.x)
	new_size.y = max(new_size.y, custom_minimum_size.y)
	
	size = new_size
	
	if not _loading:
		_on_node_modified()


func _on_character_toggled(useCharacter):
	if useCharacter:
		speaker.show()
		customSpeaker.hide()
	else:
		speaker.hide()
		customSpeaker.show()
	_on_node_modified()


func _on_characters_loaded(newCharacterList : Array[Character]):
	speaker.clear()
	
	for newCharacter in newCharacterList:
		speaker.add_item(newCharacter.name)
	
	if newCharacterList.size() > 0:
		if curSpeaker < newCharacterList.size():
			speaker.selected = curSpeaker
		else:
			curSpeaker = 0


func _on_speaker_selected(idx : int):
	curSpeaker = idx
	_on_node_modified()


func _on_expand_button_pressed():
	dialogue_expanded.text = dialogue.text
	dialogue_panel.popup_centered()
	dialogue_expanded.grab_focus()


func _on_dialogue_expanded_text_changed():
	dialogue.text = dialogue_expanded.text


func _on_dialogue_close_button_pressed():
	dialogue_panel.hide()


func _on_node_modified(_a=0, _b=0):
	modified.emit()
