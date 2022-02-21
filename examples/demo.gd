extends Control


onready var dialogue_box = $DialogueBox
onready var particles = $Particles

func explode(_a=0):
	particles.emitting = true


func _on_Button_pressed():
	if not dialogue_box.running:
		dialogue_box.start()


func _on_dialogue_signal(value):
	match(value):
		'explode': explode()

