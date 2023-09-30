@tool
extends GraphNode


signal modified
signal connection_move(old_slot, new_slot)

@export var max_options = 4

@onready var speaker = $HBoxContainer/Speaker
@onready var customSpeaker := $HBoxContainer/CustomSpeaker
@onready var characterToggle = $HBoxContainer/CharacterToggle
@onready var dialogue = $Dialogue

var curSpeaker : int = -1
var options : Array = []
var _base_color : Color = Color.WHITE

func _ready():
	for i in range(max_options):
		if has_node("Option"+str(i+1)):
			var option = get_node( NodePath("Option"+str(i+1)) )
			options.append(option)
			option.text_changed.connect(_on_option_changed.bind(option))
			option.text_submitted.connect(_on_option_entered.bind(option))
			option.focus_exited.connect(_on_option_entered.bind('', option))
			set_slot(option.get_index(), false, 0, _base_color, true, 0, _base_color)
	
	# add bbcode syntax highlighting in dialogue
	if not dialogue.syntax_highlighter.has_color_region('['):
		dialogue.syntax_highlighter.add_color_region('[', ']', Color('a5efac'))


func add_option(new_text= ''):
	if len(options) == max_options:
		return
	
	var new_option = LineEdit.new()
	var id = len(options)
	
	new_option.name = 'Option'+str(id+1)
	new_option.text = new_text
	new_option.placeholder_text = "Option"+str(id+1)
	
	options.append(new_option)
	new_option.connect("text_changed", Callable(self, "_on_option_changed").bind(new_option))
	new_option.connect("text_submitted", Callable(self, "_on_option_entered").bind(new_option))
	new_option.connect("focus_exited", Callable(self, "_on_option_entered").bind('', new_option))
	
	add_child(new_option, true)


func remove_option(option_node):
	if len(options) == 1:
		return
	
	var i = options.find(option_node) + 1
	
	while i < len(options):
		options[i-1].text = options[i].text
		connection_move.emit(i, i-1)
		i += 1
	
	options[-1].text = ''
	options[-1].queue_free()
	options.pop_back()


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
		customSpeaker.text = customSpeaker.text.replace("{", "").replace("}", "")
		dict['speaker'] = customSpeaker.text
	elif speaker.visible:
		var speakerIdx := -1
		if speaker.item_count > 0:
			speakerIdx = curSpeaker
		dict['speaker'] = float(speakerIdx)
	
	dict['dialogue'] = dialogue.text
	dict['size'] = {}
	dict['size']['x'] = size.x
	dict['size']['y'] = size.y
	
	# get options connected to other nodes
	var options_dict = {}
	for connection in graph.get_connection_list():
		if connection['from'] == name:
			var idx = connection['from_port'] # this returns index starting from 0
			options_dict[idx] = {}
			options_dict[idx]['text'] = options[int(idx)].text
			options_dict[idx]['link'] = connection['to']
	
	# get options not connected
	for i in range(len(options)):
		if not options_dict.has(i) and options[i].text != '':
			options_dict[str(i)] = {}
			options_dict[str(i)]['text'] = options[i].text
			options_dict[str(i)]['link'] = 'END'
	
	# single empty disconnected option
	if not options_dict.has(0):
		options_dict[str(0)] = {}
		options_dict[str(0)]['text'] = options[0].text
		options_dict[str(0)]['link'] = 'END'
	
	# store options info in dict
	dict['options'] = options_dict
	
	return dict


func _from_dict(graph, dict):
	var next_nodes = []
	
	# set values
	if dict['speaker'] is String:
		customSpeaker.text = dict['speaker']
	elif dict['speaker'] is float:
		curSpeaker = int(dict['speaker'])
		characterToggle.button_pressed = true
	dialogue.text = dict['dialogue']
	
	# remove any existing options
	for option in options:
		option.queue_free()
	options.clear()
	
	# add new options
	for key in dict['options']:
		add_option(dict['options'][key]['text'])
		next_nodes.append(dict['options'][key]['link'])
	
	# set size of node
	if dict.has('size'):
		var new_size = Vector2( float(dict['size']['x']), float(dict['size']['y']) )
		_on_resize(new_size, true)
	
	_update_slots()
	
	return next_nodes


func _on_option_changed(new_text, option_node):
	if option_node == options[-1]:
		add_option()
	if new_text != '':
		_update_slots()
	_on_node_modified()


func _on_option_entered(new_text, option_node):
	if option_node.text == '':
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


func _on_node_modified(_a=0, _b=0):
	modified.emit()
