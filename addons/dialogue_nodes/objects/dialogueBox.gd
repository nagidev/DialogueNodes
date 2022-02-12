tool
extends PopupDialog
class_name DialogueBox

signal dialogue_started(id)
signal dialogue_proceeded
signal dialogue_signal(value)
signal dialogue_ended
signal variable_changed(var_name, value)

export (String, FILE, "*.json; Dialogue JSON File") var dialogue_file setget load_file
export (String) var start_id
export (int, 1, 8) var max_options = 4
export (int, 'Begin', 'Center', 'End') var options_alignment = 2 setget _set_options_alignment
export (Array, RichTextEffect) var custom_effects = [RichTextWait.new()]

var speaker : Label
var dialogue : RichTextLabel
var options : HBoxContainer
var dict = null setget set_dict
var variables = {}
var running = false
var next_icon = preload("res://addons/dialogue_nodes/icons/Play.svg")


func _enter_tree():
	# setup popup properties
	popup_exclusive = true
	rect_min_size = Vector2(300, 72)
	
	## dialogue box setup code ##
	# note : edit the code below to change the layout of your dialogue box
	
	# setup containers
	var margin_container = MarginContainer.new()
	add_child(margin_container)
	margin_container.anchor_left = 0
	margin_container.anchor_top = 0
	margin_container.anchor_right = 1
	margin_container.anchor_bottom = 1
	margin_container.margin_left = 4
	margin_container.margin_top = 4
	margin_container.margin_right = -4
	margin_container.margin_bottom = -4
	
	var vbox_container = VBoxContainer.new()
	margin_container.add_child(vbox_container)
	
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
	if dict:
		init_variables(dict['variables'])


func load_file(path):
	dialogue_file = path
	
	if path == '':
		dict = null
	else:
		var file = File.new()
		file.open(path, File.READ)
		dict = parse_json(file.get_as_text())
		file.close()
		
		if typeof(dict) != TYPE_DICTIONARY:
			printerr('Unsupported file!')
			dict = null


func set_dict(new_dict):
	dict = new_dict
	if dict:
		init_variables(dict['variables'])


func init_variables(var_dict):
	variables.clear()
	
	for var_name in var_dict:
		var type = int(var_dict[var_name]['type'])
		var value = var_dict[var_name]['value']
		
		set_variable(var_name, type, value)


func start(id = start_id):
	if !dict:
		printerr('No dialogue data!')
		return
	elif !dict['start'].has(id):
		printerr('Start ID not present!')
		return
	
	running = true
	proceed(dict['start'][id])
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
			proceed(dict[idx]['link'])
		'1':
			# dialogue
			set_dialogue(dict[idx])
		'3':
			# signal
			emit_signal('dialogue_signal', dict[idx]['signalValue'])
			proceed(dict[idx]['link'])
		'4':
			# set
			var var_dict = dict[idx]
			
			var var_name = var_dict['variable']
			var value = var_dict['value']
			var var_type = typeof(variables[var_name]) if variables.has(var_name) else TYPE_STRING
			var operator = int(var_dict['type'])
			
			set_variable(var_name, var_type, value, operator)
			
			if variables.has(var_name):
				emit_signal("variable_changed", var_name, variables[var_name])
			
			proceed(var_dict['link'])
		_:
			if dict[idx].has('link'):
				proceed(dict[idx]['link'])
			else:
				stop()
	emit_signal("dialogue_proceeded")


func stop():
	running = false
	hide()
	emit_signal("dialogue_ended")


func set_dialogue(dict):
	speaker.text = dict['speaker']
	dialogue.bbcode_text = process_text(dict['dialogue'])
	
	# hide all options
	for option in options.get_children():
		option.icon = null
		option.hide()
	
	# set options
	for idx in dict['options']:
		var option = options.get_child(int(idx))
		option.text = dict['options'][idx]['text']
		if option.is_connected('pressed', self, 'proceed'):
			option.disconnect("pressed", self, 'proceed')
		option.connect("pressed", self, 'proceed', [dict['options'][idx]['link']])
		option.show()
	
	# if single empty option
	if len(dict['options']) == 1 and options.get_child(0).text == '':
		options.get_child(0).icon = next_icon
	
	# wait some time then grab focus
	yield(get_tree().create_timer(0.5), "timeout")
	options.get_child(0).grab_focus()


func process_text(text : String):
	for i in range(text.count('{{')):
		# Find tag position
		var tag_start = text.find('{{')+2
		var tag_len = text.find('}}') - tag_start
		
		# Find variable value
		var var_name = text.substr(tag_start, tag_len)
		var value = 'undefined'
		if variables.has(var_name):
			value = variables[var_name]
		
		# Remove tag
		text.erase(tag_start-2, tag_len+4)
		
		# Insert value
		text = text.insert(tag_start-2, value)
	
	return text


func set_variable(var_name, type, value, operator = 0):
	
	# Set datatype of value
	match type:
		TYPE_STRING:
			value = str(value)
		TYPE_INT:
			value = int(value)
		TYPE_REAL:
			value = float(value)
		TYPE_BOOL:
			value = bool(value)
	
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


func _set_options_alignment(value):
	options_alignment = value
	if options:
		options.alignment = options_alignment
