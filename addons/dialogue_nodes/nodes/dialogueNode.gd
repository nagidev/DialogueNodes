tool
extends "res://addons/dialogue_nodes/nodes/baseNode.gd"

signal speakerChanged(newSpeaker)
signal slotRemoved(slot_left, slot_right)

onready var speaker = $Speaker
onready var dialogue = $Dialogue
onready var optionsToggle = $OptionsToggle
onready var options = $Options
onready var option = $Options/Option1

func _ready():
	optionsToggle.connect('toggled', self, '_on_options_toggled')
	option.connect('text_entered', self, '_on_option_added', [option])
	option.connect('focus_exited', self, '_on_option_focus_exited', [option])
	option.connect('text_changed', self, '_on_modified')
	speaker.connect("text_changed", self, "_on_modified")
	dialogue.connect("text_changed", self, "_on_modified")


func updateUI():
	var key = 0
	
	for i in range(options.get_child_count()):
		if options.get_child(i).editable:
			options.get_child(i).placeholder_text = 'Option ' + str(key + 1)
			options.get_child(i).set('custom_colors/font_color', Color(Colors[key]))
			
			if key == 0:
				set_slot(key, true, 0, WHITE, true, 0, Color(Colors[key]))
			elif options.get_child(i).text != '':
				set_slot(key, false, 0, WHITE, true, 0, Color(Colors[key]))
			
			key = min(key + 1, 3)
			
		else:
			emit_signal("slotRemoved", -1, options.get_child_count()-2)
	
	update()


func countEmptyOptions():
	var count = 0
	for currentOption in options.get_children():
		if currentOption.text == '':
			count += 1
	return count


func addEmptyOption():
	var newOption = options.get_child(0).duplicate()
	newOption.editable = true
	newOption.text = ''
	newOption.connect('text_entered', self, '_on_option_added', [newOption])
	newOption.connect('focus_exited', self, '_on_option_focus_exited', [newOption])
	newOption.connect('text_changed', self, '_on_modified')
	options.add_child(newOption)


func addOption(optionText):
	var count = options.get_child_count()
	var newOption
	
	# Get the last option containing no text
	for i in range(min(count, 4)):
		if options.get_child(i).text == '':
			newOption = options.get_child(i)
			set_slot(i, i==0, 0, WHITE, true, 0, Colors[i])
			addEmptyOption()
			break
	
	newOption.editable = true
	newOption.text = optionText
	newOption.disconnect('text_entered', self, '_on_option_added')
	newOption.disconnect('focus_exited', self, '_on_option_focus_exited')
	newOption.connect('text_entered', self, '_on_option_added', [newOption])
	newOption.connect('focus_exited', self, '_on_option_focus_exited', [newOption])
	
	updateUI()


func removeOption(newOption):
	if options.get_child_count()>1:
			newOption.editable = false
			newOption.queue_free()
			if countEmptyOptions() == 1:
				addEmptyOption()
			# Update placeholder text
			updateUI()


func getOptionNames():
	var optionNames = []
	
	if options.visible:
		for node in options.get_children():
			if node is LineEdit and node.text != '':
				optionNames.append(node.text)
	
	return optionNames


func getSpeaker():
	return speaker.text


func setSpeaker(newSpeaker):
	speaker.text = newSpeaker


func getDialogue():
	return dialogue.text


func setDialogue(newDialogue):
	dialogue.text = newDialogue


func setSlot(id, left= false, right= false):
	if id < 4:
		set_slot(id, left, 0, WHITE, right, 0, Color(Colors[id]))


func _on_options_toggled(pressed):
	options.visible = pressed


func _on_option_added(newText, currentOption):
	
	if newText == '':
		removeOption(currentOption)
	elif countEmptyOptions() == 0 and options.get_child_count() < 4:
		addEmptyOption()
		# Update placeholder text
		updateUI()
	else:
		# Update placeholder text
		updateUI()


func _on_option_focus_exited(currentOption):
	if currentOption.text == '':
		removeOption(currentOption)


func _on_Speaker_changed(newText):
	emit_signal("speakerChanged", newText)
