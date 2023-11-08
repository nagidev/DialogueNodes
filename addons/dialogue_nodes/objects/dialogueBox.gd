@tool
extends Panel
class_name DialogueBox


signal dialogue_started(id: String)
signal dialogue_proceeded(node_type: String)
signal dialogue_signal(value: String)
signal dialogue_ended
signal variable_changed(var_name: String, value)

@export_group('Data')
## Dialigue file created in the Dialogue Nodes editor
@export var dialogue_file : DialogueData = null : set = load_data
## Start ID to begin dialogue from
@export var start_id: String

@export_group('Visuals')
## Maximum possible number of options
@export_range(1, 8) var max_options = 4: set = _set_options_count
## Alignment of options
@export_enum('Begin', 'Center', 'End') var options_alignment = 2: set = _set_options_alignment
## Orientation of options
@export var options_vertical : bool = false: set = _set_options_vertical
## Position of options along the dialogue box
@export_enum('Top', 'Left', 'Right', 'Bottom') var options_position = 3: set = _set_options_position
## Icon displayed when no options are available
@export var next_icon := preload('res://addons/dialogue_nodes/icons/Play.svg')
## Default color for the speaker label
@export var default_speaker_color := Color.WHITE: set = _set_default_speaker_color
## Hide the character portrait (useful for custom character portrait implementations)
@export var hide_character_portrait := false

@export_group('Misc')
## Input action used to skip dialougue animation
@export var skip_input_action := 'ui_cancel'
## Hide dialogue box at the end of a dialogue
@export var hide_on_dialogue_end := true
## Custom RichTextEffects used (Ex: wait, ghost)
@export var custom_effects : Array[RichTextEffect] = [
		RichTextWait.new(),
		RichTextGhost.new()
		]

var speaker : Label
var portrait : TextureRect
var dialogue : RichTextLabel
var options : BoxContainer
var hbox_container : HBoxContainer
var vbox_container : VBoxContainer
var data : DialogueData = null : set= set_data
var variables = {}
var running = false
var characterList : CharacterList = null


func _enter_tree():
	if get_child_count() > 0:
		for child in get_children():
			remove_child(child)
			child.queue_free()
	
	## dialogue box setup code ##
	# note : edit the code below to change the layout of your dialogue box
	
	# setup dialog panel
	custom_minimum_size = Vector2(256, 128)
	
	# setup containers
	var margin_container := MarginContainer.new()
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.offset_left = 4
	margin_container.offset_top = 4
	margin_container.offset_right = -4
	margin_container.offset_bottom = -4
	
	hbox_container = HBoxContainer.new()
	margin_container.add_child(hbox_container)
	
	# setup portrait image
	portrait = TextureRect.new()
	hbox_container.add_child(portrait)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	portrait.size_flags_stretch_ratio = 0
	
	
	vbox_container = VBoxContainer.new()
	hbox_container.add_child(vbox_container)
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# setup speaker, dialogue
	speaker = Label.new()
	vbox_container.add_child(speaker)
	speaker.text = 'Speaker'
	
	dialogue = RichTextLabel.new()
	vbox_container.add_child(dialogue)
	dialogue.text = 'Sample dialogue.\nLoad a [u]dialogue file[/u].'
	dialogue.scroll_following = false
	dialogue.bbcode_enabled = true
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue.custom_effects = custom_effects
	
	# setup options
	options = BoxContainer.new()
	vbox_container.add_child(options)
	options.alignment = options_alignment
	
	for i in range(max_options):
		var button = Button.new()
		button.text = 'Option '+str(i+1)
		options.add_child(button)


func _ready():
	_set_options_alignment(options_alignment)
	_set_options_vertical(options_vertical)
	_set_options_position(options_position)
	
	hide()
	if hide_character_portrait:
		portrait.hide()
	
	if data:
		init_variables(data.variables)
	
	for effect in custom_effects:
		if effect is RichTextWait:
			effect.wait_finished.connect(show_options)
			break


func _input(event):
	if Input.is_action_just_pressed(skip_input_action):
		custom_effects[0].skip = true
		options.show()


func load_data(new_data : DialogueData):
	data = null
	
	if new_data and not new_data is DialogueData:
		printerr('Unsupported file!')
		return
	
	dialogue_file = new_data
	set_data(new_data)


func set_data(new_data : DialogueData):
	data = new_data
	if data:
		# load variables from the data
		init_variables(data.variables)
		
		# load characters
		characterList = null
		if data.characters.ends_with('.tres'):
			var file = ResourceLoader.load(data.characters, '', ResourceLoader.CACHE_MODE_REPLACE)
			if file is CharacterList:
				characterList = file


func init_variables(var_dict):
	variables.clear()
	
	for var_name in var_dict:
		var type = int(var_dict[var_name]['type'])
		var value = var_dict[var_name]['value']
		
		set_variable(var_name, type, value)


func start(id = start_id):
	if !data:
		printerr('No dialogue data!')
		return
	elif !data.starts.has(id):
		printerr('Start ID not present!')
		return
	
	running = true
	proceed(data.starts[id])
	dialogue_started.emit(id)


func proceed(idx):
	if idx == 'END' or not running:
		stop()
		return
	
	var type = idx.split('_')[0]
	
	# define how to process the current node type
	match(type):
		'0':
			# start
			show()
			proceed(data.nodes[idx]['link'])
		'1':
			# dialogue
			set_dialogue(data.nodes[idx])
		'3':
			# signal
			dialogue_signal.emit(data.nodes[idx]['signalValue'])
			proceed(data.nodes[idx]['link'])
		'4':
			# set
			var var_dict = data.nodes[idx]
			
			var var_name = var_dict['variable']
			var value = var_dict['value']
			var var_type = typeof(variables[var_name]) if variables.has(var_name) else TYPE_STRING
			var operator = int(var_dict['type'])
			
			set_variable(var_name, var_type, value, operator)
			
			if variables.has(var_name):
				variable_changed.emit(var_name, variables[var_name])
			
			proceed(var_dict['link'])
		'5':
			# condition
			var result = check_condition((data.nodes[idx]))
			
			# Proceed
			proceed(data.nodes[idx][str(result).to_lower()])
		_:
			if data.nodes[idx].has('link'):
				proceed(data.nodes[idx]['link'])
			else:
				stop()
	dialogue_proceeded.emit(type)


func stop():
	running = false
	if hide_on_dialogue_end:
		reset()
		hide()
	dialogue_ended.emit()


func reset():
	speaker.text = ''
	dialogue.text = ''
	portrait.texture = null


func set_dialogue(dict):
	# set speaker and portrait
	speaker.text = ''
	speaker.modulate = default_speaker_color
	portrait.texture = null
	if dict['speaker'] is String:
		speaker.text = dict['speaker']
	elif dict['speaker'] is int and characterList:
		var idx = dict['speaker']
		if idx > -1 and idx < characterList.characters.size():
			speaker.text = characterList.characters[idx].name
			speaker.modulate = characterList.characters[idx].color
			if characterList.characters[idx].image:
				portrait.texture = characterList.characters[idx].image
	
	dialogue.text = '' # workaround for bug
	dialogue.text = process_text(dict['dialogue'])
	custom_effects[0].skip = false
	
	# hide all options
	options.hide()
	for option in options.get_children():
		option.icon = null
		option.hide()
	
	# set options
	for idx in dict['options']:
		var option = options.get_child(int(idx))
		var option_dict = dict['options'][idx]
		option.text = process_text(option_dict['text'], false)
		if option.is_connected('pressed', proceed):
			option.disconnect('pressed', proceed)
		option.pressed.connect(proceed.bind(option_dict['link']))
		
		if option_dict.has('condition') and not option_dict['condition'].is_empty():
			option.visible = check_condition(option_dict['condition'])
		else:
			option.show()
	
	# set single option to show if none visible
	var _options_visible = 0
	for option in options.get_children():
		_options_visible += 1 if option.visible else 0
	if _options_visible == 0:
		var option = options.get_child(0)
		option.text = ''
		option.icon = next_icon
		if option.is_connected('pressed', proceed):
			option.disconnect('pressed', proceed)
		option.pressed.connect(proceed.bind('END'))
		option.show()
	
	# if single empty option
	if len(dict['options']) == 1 and options.get_child(0).text == '':
		options.get_child(0).icon = next_icon


func process_text(text : String, is_dialogue = true):
	# Fill if empty
	if text == '' and is_dialogue:
		text = ' '
	
	# Add variables
	var formatted_variables = {}
	for key in variables.keys():
		if variables[key] is float:
			formatted_variables[key] = '%0.2f' % variables[key]
		else:
			formatted_variables[key] = variables[key]
	text = text.format(formatted_variables, '{{_}}')
	
	# return text now if not a dialogue
	if not is_dialogue:
		return text
	
	# Add a wait if none present at beginning
	if not text.begins_with('[wait'):
		text = '[wait]' + text + '[/wait]'
	
	# Update [wait] with last attribute for showing options
	# Find the actual position of the last character sans bbcode
	var regex = RegEx.new()
	regex.compile('\\n|\\[img\\].*?\\[\\/img\\]|\\[.*?\\]')
	var textLength = regex.sub(text, '', true).length()
	
	var idx = 0
	var char_idx = -1
	var char_count = 0
	var waits = []
	while idx < text.length():
		match text[idx]:
			'[':
				var open_tag_start = text.findn('[wait', idx)
				var open_tag_end = text.findn(']', idx)
				var end_tag = text.findn('[/wait]', idx)
				
				var img_tag = text.findn('[img', idx)
				var img_tag_end = text.findn('[/img]', idx)
				
				if open_tag_start == idx:
					var start = char_idx + 1
					waits.push_back({ 'at': open_tag_end, 'start': start })
					idx = open_tag_end + 1
				elif end_tag == idx:
					var start_data = waits.pop_back()
					var insertText = ' start='+str(start_data.start)+' last='+str(start_data.last)+' length='+str(textLength)
					text = text.insert(start_data.at, insertText)
					idx = end_tag + insertText.length() + 7
				elif img_tag == idx:
					idx = img_tag_end + 6
				else:
					idx = open_tag_end + 1
			'\n':
				idx += 1
			_:
				idx += 1
				char_idx += 1
				char_count += 1
				if waits.size():
					waits[-1]['last'] = char_count - 1
	
	# insert waits if any left
	while len(waits) > 0:
		var start_data = waits.pop_back()
		var insertText = ' start='+str(start_data.start)+' last='+str(char_count - 1)+' length='+str(textLength)
		text = text.insert(start_data.at, insertText)
	
	return text


func get_variable(text : String):
	# Find tag position
	var tag_start = text.find('{{')+2
	var tag_len = text.find('}}') - tag_start
	
	# Find variable value
	var var_name = text.substr(tag_start, tag_len)
	var value = 'undefined'
	if variables.has(var_name):
		value = variables[var_name]
	
	return value


func set_variable(var_name, type, value, operator = 0):
	
	# Set datatype of value
	match type:
		TYPE_STRING:
			value = str(value)
			
			# Check for invalud operators
			if operator > 2:
				printerr('Invalid operator for type: String')
				return
		TYPE_INT:
			value = int(value)
		TYPE_FLOAT:
			value = float(value)
		TYPE_BOOL:
			value = (value == 'true') if value is String else bool(value)
			
			# Check for invalid operators
			if operator > 0:
				printerr('Invalid operator for type: Boolean')
				return
	
	# Perform operation
	match operator:
		0:
			# =
			variables[var_name] = value
		1:
			# +=
			variables[var_name] += value
		2:
			# -=
			variables[var_name] -= value
		3:
			# *=
			variables[var_name] *= value
		4:
			# /=
			variables[var_name] /= value


func check_condition(cond_dict: Dictionary):
	var value1 = cond_dict['value1']
	var value2 = cond_dict['value2']
	var type = TYPE_STRING
	
	# Get variables if needed
	if value1.count('{{') > 0:
		value1 = get_variable(value1)
		type = typeof(value1)
	if value2.count('{{') > 0:
		value2 = get_variable(value2)
		type = typeof(value2)
	
	# Set datatype of values
	match type:
		TYPE_STRING:
			value1 = str(value1)
			value2 = str(value2)
		TYPE_INT:
			value1 = int(value1)
			value2 = int(value2)
		TYPE_FLOAT:
			value1 = float(value1)
			value2 = float(value2)
		TYPE_BOOL:
			value1 = (value1 == 'true') if value1 is String else value1
			value2 = (value2 == 'true') if value2 is String else value2
	
	# Perform operation
	var result : bool = false
	match int(cond_dict['operator']):
		0:
			result = value1 == value2
		1:
			result = value1 != value2
		2:
			result = value1 > value2
		3:
			result = value1 < value2
		4:
			result = value1 >= value2
		5:
			result = value1 <= value2
	
	return result


func show_options():
	if options.is_inside_tree():
		options.show()
		for option in options.get_children():
			if option.visible:
				option.grab_focus()
				break


func _set_options_count(value):
	max_options = max(1, value)
	
	if options:
		# clear all options
		for option in options.get_children():
			options.remove_child(option)
			option.queue_free()
		
		for i in range(max_options):
			var button = Button.new()
			button.text = 'Option '+str(i+1)
			options.add_child(button)


func _set_options_alignment(value):
	options_alignment = value
	if options:
		options.alignment = options_alignment


func _set_options_vertical(value):
	options_vertical = value
	if options:
		options.vertical = options_vertical


func _set_options_position(value):
	options_position = value
	if options:
		var cur_parent = options.get_parent()
		cur_parent.remove_child(options)
		
		match value:
			0:
				# top
				vbox_container.add_child(options)
				vbox_container.move_child(options, 0)
			3:
				# bottom
				vbox_container.add_child(options)
			1:
				# left
				hbox_container.add_child(options)
				hbox_container.move_child(options, 0)
			2:
				# right
				hbox_container.add_child(options)


func _set_default_speaker_color(value):
	default_speaker_color = value
	if speaker:
		speaker.modulate = default_speaker_color
