tool
extends PopupDialog
class_name DialogueBox

signal dialogue_started(id)
signal dialogue_proceeded
signal dialogue_signal(value)
signal dialogue_ended

export (String, FILE, "*.json; Dialogue JSON File") var dialogue_file setget load_file
export (String) var start_id
export (int, 1, 8) var max_options = 4
export (int, 'Begin', 'Center', 'End') var options_alignment = 2 setget _set_options_alignment
export (Array, RichTextEffect) var custom_effects = [RichTextWait.new()]

var speaker : Label
var dialogue : RichTextLabel
var options : HBoxContainer
var dict = null
var running = false
var next_icon = preload("res://addons/dialogue_nodes/icons/Play.svg")


func _enter_tree():
	# setup popup properties
	popup_exclusive = true
	rect_min_size = Vector2(300, 100)
	
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


func _exit_tree():
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()


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
	emit_signal("dialogue_proceeded")


func stop():
	running = false
	hide()
	emit_signal("dialogue_ended")


func set_dialogue(dict):
	speaker.text = dict['speaker']
	dialogue.bbcode_text = dict['dialogue']
	
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
	
	options.get_child(0).grab_focus()


func _set_options_alignment(value):
	options_alignment = value
	if options:
		options.alignment = options_alignment
