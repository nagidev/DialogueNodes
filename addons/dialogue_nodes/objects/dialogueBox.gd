tool
extends PopupDialog
class_name DialogueBox


signal dialogue_started(id)
signal dialogue_proceeded
signal dialogue_signal(value)
signal dialogue_ended
signal variable_changed(var_name, value)

export (Resource) var dialogue_data setget set_data
export (String) var start_id
export (bool) var hide_on_dialogue_end = true
export (int, 1, 8) var max_options = 4 setget _set_options_count
export (int, 'Begin', 'Center', 'End') var options_alignment = 2 setget _set_options_alignment
export (bool) var options_vertical = false setget _set_options_vertical
export (int, 'Top', 'Left', 'Right', 'Bottom') var options_position = 3 setget _set_options_position
export (Texture) var next_icon = preload('res://addons/dialogue_nodes/icons/Play.svg')

export (Texture) var sample_portrait = preload('res://addons/dialogue_nodes/icons/Portrait.png') setget _set_sample_portrait
export var portrait_size = 128 setget _set_portrait_size
export var hide_portrait := false setget _set_portrait_visibility

export (Color) var default_speaker_color = Color.white setget _set_default_speaker_color
export (float, 1.0, 10.0) var scroll_speed = 4.0
export (Array, RichTextEffect) var custom_effects = [RichTextWait.new()]

var speaker : Label
var portrait : TextureRect
var dialogue : RichTextLabel
var options : GridContainer
var variables = {}
var running = false
var characterList : CharacterList = null

var _hbox_container : HBoxContainer
var _vbox_container : VBoxContainer


func _enter_tree():
	# setup popup properties
	popup_exclusive = true
	rect_min_size = Vector2(300, 72)
	
	## dialogue box setup code ##
	# note : edit the code below to change the layout of your dialogue box
	
	# setup containers
	var margin_container = MarginContainer.new()
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_WIDE)
	margin_container.margin_left = 4
	margin_container.margin_top = 4
	margin_container.margin_right = -4
	margin_container.margin_bottom = -4
	
	_hbox_container = HBoxContainer.new()
	margin_container.add_child(_hbox_container)
	
	# setup portrait image
	portrait = TextureRect.new()
	_hbox_container.add_child(portrait)
	portrait.texture = sample_portrait
	portrait.expand = true
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.rect_min_size = Vector2(portrait_size, 0)
	
	_vbox_container = VBoxContainer.new()
	_hbox_container.add_child(_vbox_container)
	_vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# setup speaker, dialogue
	speaker = Label.new()
	_vbox_container.add_child(speaker)
	speaker.text = 'Speaker'
	
	dialogue = RichTextLabel.new()
	_vbox_container.add_child(dialogue)
	dialogue.bbcode_text = 'Sample dialogue.\nLoad a [u]dialogue file[/u].'
	dialogue.bbcode_enabled = true
	dialogue.size_flags_vertical = SIZE_EXPAND_FILL
	dialogue.custom_effects = custom_effects
	
	# setup options
	options = GridContainer.new()
	_vbox_container.add_child(options)
	options.columns = max_options
	
	for i in range(max_options):
		var button = Button.new()
		options.add_child(button)
		button.text = 'Option '+str(i+1)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.size_flags_vertical = SIZE_EXPAND_FILL


func _ready():
	_set_options_alignment(options_alignment)
	_set_options_vertical(options_vertical)
	_set_options_position(options_position)
	
	if dialogue_data:
		_init_variables(dialogue_data.variables)
	
	for effect in custom_effects:
		if effect is RichTextWait:
			effect.connect("wait_finished", self, "show_options")
			break


func _process(delta):
	# scrolling for longer dialogues
	if not running:
		return

	var scroll_amt := 0.0
	if options_vertical:
		scroll_amt = Input.get_axis("ui_left", "ui_right")
	else:
		scroll_amt = Input.get_axis("ui_up", "ui_down")

	if scroll_amt:
		dialogue.get_v_scroll().value += int(scroll_amt * scroll_speed)


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		custom_effects[0].skip = true


func set_data(new_data : DialogueData):
	if new_data and not new_data is DialogueData:
		printerr('Unsupported file!')
		return
	
	dialogue_data = new_data
	if dialogue_data:
		# load variables from the dialogue_data
		_init_variables(dialogue_data.variables)

		# load characters
		characterList = null
		if dialogue_data.characters.ends_with('.tres'):
			var file = ResourceLoader.load(dialogue_data.characters, '', true)
			if file is CharacterList:
				characterList = file


func _init_variables(var_dict):
	variables.clear()
	
	for var_name in var_dict:
		var type = int(var_dict[var_name]['type'])
		var value = var_dict[var_name]['value']
		
		set_variable(var_name, type, value)


func start(id = start_id):
	if !dialogue_data:
		printerr('No dialogue dialogue_data!')
		return
	elif !dialogue_data.starts.has(id):
		printerr('Start ID not present!')
		return
	
	running = true
	proceed(dialogue_data.starts[id])
	emit_signal("dialogue_started", id)


func proceed(idx):
	if idx == 'END':
		stop()
		return
	
	var type = idx.split('_')[0]
	
	# define how to process the current node type
	match(type):
		'0':
			# start
			popup()
			proceed(dialogue_data.nodes[idx]['link'])
		'1':
			# dialogue
			_set_dialogue(dialogue_data.nodes[idx])
		'3':
			# signal
			emit_signal('dialogue_signal', dialogue_data.nodes[idx]['signalValue'])
			proceed(dialogue_data.nodes[idx]['link'])
		'4':
			# set
			var var_dict = dialogue_data.nodes[idx]
			
			var var_name = var_dict['variable']
			var value = var_dict['value']
			var var_type = typeof(variables[var_name]) if variables.has(var_name) else TYPE_STRING
			var operator = int(var_dict['type'])
			
			set_variable(var_name, var_type, value, operator)
			
			if variables.has(var_name):
				emit_signal("variable_changed", var_name, variables[var_name])
			
			proceed(var_dict['link'])
		'5':
			# condition
			var result = _check_condition((dialogue_data.nodes[idx]))

			# Proceed
			proceed(dialogue_data.nodes[idx][str(result).to_lower()])
		_:
			if dialogue_data.nodes[idx].has('link'):
				proceed(dialogue_data.nodes[idx]['link'])
			else:
				stop()
	emit_signal("dialogue_proceeded")


func stop():
	running = false
	if hide_on_dialogue_end:
		reset()
		hide()
	emit_signal("dialogue_ended")


func reset():
	speaker.text = ''
	dialogue.text = ''
	portrait.texture = null


func _set_dialogue(dict):
	# set speaker and portrait
	speaker.text = ''
	speaker.modulate = default_speaker_color
	portrait.texture = null
	portrait.hide()
	if dict['speaker'] is String:
		speaker.text = dict['speaker']
	elif dict['speaker'] is int and characterList:
		var idx = int(dict['speaker'])
		if idx > -1 and idx < characterList.characters.size():
			speaker.text = characterList.characters[idx].name
			speaker.modulate = characterList.characters[idx].color
			if characterList.characters[idx].image:
				portrait.texture = characterList.characters[idx].image
				portrait.show()
	
	dialogue.bbcode_text = _process_text(dict['dialogue'])
	dialogue.get_v_scroll().value = 0
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
		option.text = _process_text(option_dict['text'], false)
		if option.is_connected('pressed', self, 'proceed'):
			option.disconnect("pressed", self, 'proceed')
		option.connect('pressed', self, 'proceed', [option_dict['link']])
		
		if option_dict.has('condition') and not option_dict['condition'].empty():
			option.visible = _check_condition(option_dict['condition'])
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
		if option.is_connected('pressed', self, 'proceed'):
			option.disconnect('pressed', self, 'proceed')
		option.connect('pressed', self, 'proceed', ['END'])
		option.show()
	
	# if single empty option
	if len(dict['options']) == 1 and options.get_child(0).text == '':
		options.get_child(0).icon = next_icon


func _process_text(text : String, is_dialogue = true):
	# Fill if empty
	if text == '' and is_dialogue:
		text = ' '
	
	# Add variables
	text = text.format(variables, '{{_}}')
	
	# Add a wait if none present
	if text.count('[wait') == 0 and is_dialogue:
		text = '[wait]' + text + '[/wait]'
	
	# Update [wait] with last attribute for showing options
	# Find the actual position of the last character sans bbcode
	var last := text.length()-1
	var find_pos = 0
	for i in range(text.count(']')):
		var tag_start = text.findn('[', find_pos)
		var tag_end = text.findn(']', find_pos)
		var tag_len = (tag_end - tag_start) +1
		find_pos = tag_end + 1
		last -= tag_len
	last -= text.count('\n')
	# Update tags
	text = text.replace('[wait', '[wait last='+str(last))
	
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


func set_variable(var_name: String, type: int, value, operator = 0):
	
	# Set datatype of value
	match type:
		TYPE_STRING:
			value = str(value)
			
			# Check for invalud operators
			if operator > 2:
				printerr("Invalid operator for type: String")
				return
		TYPE_INT:
			value = int(value)
		TYPE_REAL:
			value = float(value)
		TYPE_BOOL:
			value = (value == "true") if value is String else bool(value)
			
			# Check for invalid operators
			if operator > 0:
				printerr("Invalid operator for type: Boolean")
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


func _check_condition(cond_dict: Dictionary):
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
		TYPE_REAL:
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
	if options and options.is_inside_tree():
		options.show()
		for option in options.get_children():
			if option.visible:
				option.grab_focus()
				break


func _set_options_count(value):
	max_options = value
	
	if options:
		# clear all options
		for option in options.get_children():
			options.remove_child(option)
			option.queue_free()

		for i in range(max_options):
			var button = Button.new()
			button.text = 'Option '+str(i+1)
			options.add_child(button)
		
		_set_options_vertical(options_vertical)


func _set_options_alignment(value):
	options_alignment = value
	
	if options:
		match options_alignment:
			0:
				# Begin
				options.size_flags_horizontal = 0
				options.size_flags_vertical = 0
			1:
				# Center
				options.size_flags_horizontal = SIZE_SHRINK_CENTER
				options.size_flags_vertical = SIZE_SHRINK_CENTER
			2:
				# End
				options.size_flags_horizontal = SIZE_SHRINK_END
				options.size_flags_vertical = SIZE_SHRINK_END


func _set_options_vertical(value):
	options_vertical = value
	
	if options:
		options.columns = 1 if options_vertical else max_options


func _set_options_position(value):
	options_position = value
	
	if options:
		options.get_parent().remove_child(options)

		match value:
			0:
				# top
				_vbox_container.add_child(options)
				_vbox_container.move_child(options, 0)
			3:
				# bottom
				_vbox_container.add_child(options)
			1:
				# left
				_hbox_container.add_child(options)
				_hbox_container.move_child(options, 1)
			2:
				# right
				_hbox_container.add_child(options)


func _set_sample_portrait(value):
	sample_portrait = value
	portrait.texture = sample_portrait


func _set_portrait_size(value):
	portrait_size = value
	portrait.rect_min_size = Vector2(portrait_size, 0)


func _set_portrait_visibility(value):
	hide_portrait = value
	portrait.visible = not hide_portrait


func _set_default_speaker_color(value):
	default_speaker_color = value
	
	if speaker:
		speaker.modulate = default_speaker_color
