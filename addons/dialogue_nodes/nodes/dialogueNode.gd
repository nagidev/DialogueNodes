tool
extends "res://addons/dialogue_nodes/nodes/baseNode.gd"

signal speakerChanged(newSpeaker)

onready var speaker = $Speaker
onready var dialogue = $Dialogue
onready var optionsToggle = $OptionsToggle
onready var options = $Options
onready var option = $Options/Option1

func _ready():
	optionsToggle.connect("toggled", self, '_on_options_toggled')
	option.connect("text_entered", self, '_on_option_added', [option])
	option.connect('focus_exited', self, '_on_option_focus_exited', [option])


func updateUI(off=1):
	clear_all_slots()
	
	for i in range(options.get_child_count()):
		options.get_child(i).placeholder_text = 'Option ' + str(i+off)
		options.get_child(i).set('custom_colors/font_color', Color(Colors[i+off-1]))
		if i == 0:
			set_slot(i, true, 0, WHITE, true, 0, Color(Colors[i]))
		elif options.get_child(i).text != '':
			set_slot(i, false, 0, WHITE, true, 0, Color(Colors[i]))


func countEmptyOptions():
	var count = 0
	for currentOption in options.get_children():
		if currentOption.text == '':
			count += 1
	return count


func addEmptyOption():
	var newOption = options.get_child(0).duplicate()
	newOption.text = ''
	newOption.connect('text_entered', self, '_on_option_added', [newOption])
	newOption.connect('focus_exited', self, '_on_option_focus_exited', [newOption])
	options.add_child(newOption)


func getOptionNames():
	var optionNames = []
	
	if options.visible:
		for node in options.get_children():
			if node is LineEdit and node.text != '':
				optionNames.append(node.text)
	
	return optionNames


func _on_options_toggled(pressed):
	options.visible = pressed


func getSpeaker():
	return speaker.text


func setSpeaker(newSpeaker):
	speaker.text = newSpeaker


func getDialogue():
	return dialogue.text


func _on_option_added(newText, currentOption):
	
	if newText == '':
		if options.get_child_count()>1:
			currentOption.queue_free()
			if countEmptyOptions() == 1:
				addEmptyOption()
			# Update placeholder text
			updateUI(0)
	elif countEmptyOptions() == 0 and options.get_child_count() < 4:
		addEmptyOption()
		# Update placeholder text
		updateUI()
	else:
		# Update placeholder text
		updateUI()


func _on_option_focus_exited(currentOption):
	if currentOption.text == '':
		if options.get_child_count()>1:
			currentOption.queue_free()
			if countEmptyOptions() == 1:
				addEmptyOption()
			# Update placeholder text
			updateUI(0)


func _on_Speaker_changed(newText):
	emit_signal("speakerChanged", newText)
