tool
extends PopupDialog
class_name DialogueBox


signal dialogue_started(id)
signal dialogue_proceeded
signal dialogue_signal(value)
signal dialogue_ended
signal variable_changed(var_name, value)

export (Resource) var dialogue_file setget load_data
export (String) var start_id
export (int, 1, 8) var max_options = 4
export (int, 'Begin', 'Center', 'End') var options_alignment = 2 setget _set_options_alignment
export (Texture) var next_icon = preload("res://addons/dialogue_nodes/icons/Play.svg")
export (Array, RichTextEffect) var custom_effects = [RichTextWait.new()]

var speaker : Label
var portrait : TextureRect
var dialogue : RichTextLabel
var options : HBoxContainer
var data : DialogueData = null setget set_data
var variables = {}
var running = false
var characterList : CharacterList = null


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
	
	var hbox_container = HBoxContainer.new()
	margin_container.add_child(hbox_container)
	
	# setup portrait image
	portrait = TextureRect.new()
	hbox_container.add_child(portrait)
	portrait.expand = true
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.size_flags_stretch_ratio = 0.2
	
	var vbox_container = VBoxContainer.new()
	hbox_container.add_child(vbox_container)
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# setup speaker, dialogue
	speaker = Label.new()
	vbox_container.add_child(speaker)
	speaker.text = 'Speaker'
	
	dialogue = RichTextLabel.new()
	vbox_container.add_child(dialogue)
	dialogue.bbcode_text = 'Sample dialogue.\nLoad a [u]dialogue file[/u].'
	dialogue.scroll_following = true
	dialogue.bbcode_enabled = true
	dialogue.size_flags_vertical = SIZE_EXPAND_FILL
	dialogue.custom_effects = custom_effects
	
	# setup options
	options = HBoxContainer.new()
	vbox_container.add_child(options)
	options.alignment = options_alignment
	
	for i in range(max_options):
		var button = Button.new()
		button.text = 'Option '+str(i+1)
		options.add_child(button)


func _ready():
	if data:
		init_variables(data.variables)
	
	for effect in custom_effects:
		if effect is RichTextWait:
			effect.connect("wait_finished", self, "show_options")
			break


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		custom_effects[0].skip = true


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
			var file = ResourceLoader.load(data.characters, '', true)
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
			proceed(data.nodes[idx]['link'])
		'1':
			# dialogue
			set_dialogue(data.nodes[idx])
		'3':
			# signal
			emit_signal('dialogue_signal', data.nodes[idx]['signalValue'])
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
				emit_signal("variable_changed", var_name, variables[var_name])
			
			proceed(var_dict['link'])
		'5':
			# condition
			handle_condition(data.nodes[idx])
		_:
			if data.nodes[idx].has('link'):
				proceed(data.nodes[idx]['link'])
			else:
				stop()
	emit_signal("dialogue_proceeded")


func stop():
	running = false
	hide()
	emit_signal("dialogue_ended")


func set_dialogue(dict):
	# set speaker and portrait
	speaker.text = ''
	portrait.texture = null
	portrait.hide()
	if dict['speaker'] is String:
		speaker.text = dict['speaker']
	elif dict['speaker'] is int and characterList:
		var idx = int(dict['speaker'])
		if idx > -1 and idx < characterList.characters.size():
			speaker.text = characterList.characters[idx].name
			if characterList.characters[idx].image:
				portrait.texture = characterList.characters[idx].image
				portrait.show()
	
	dialogue.bbcode_text = process_text(dict['dialogue'])
	custom_effects[0].skip = false
	
	# hide all options
	options.hide()
	for option in options.get_children():
		option.icon = null
		option.hide()
	
	# set options
	for idx in dict['options']:
		var option = options.get_child(int(idx))
		option.text = process_text(dict['options'][idx]['text'], false)
		if option.is_connected('pressed', self, 'proceed'):
			option.disconnect("pressed", self, 'proceed')
		option.connect("pressed", self, 'proceed', [dict['options'][idx]['link']])
		option.show()
	
	# if single empty option
	if len(dict['options']) == 1 and options.get_child(0).text == '':
		options.get_child(0).icon = next_icon


func process_text(text : String, is_dialogue = true):
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


func set_variable(var_name, type, value, operator = 0):
	
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


func handle_condition(cond_dict):
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
			value1 = (value1 == "true") if value1 is String else value1
			value2 = (value2 == "true") if value2 is String else value2
	
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
	
	# Proceed
	proceed(cond_dict[str(result).to_lower()])


func show_options():
	options.show()
	options.get_child(0).grab_focus()


func _set_options_alignment(value):
	options_alignment = value
	if options:
		options.alignment = options_alignment
