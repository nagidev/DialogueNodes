extends Control

onready var dialogue_box = $DialogueBox

func _on_Button_pressed():
	if not dialogue_box.running:
		dialogue_box.start()
