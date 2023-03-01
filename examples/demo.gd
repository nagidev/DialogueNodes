extends Control

export (Array, String, FILE, "*.json") var demos

onready var dialogue_box = $DialogueBox
onready var particles = $Particles


func _ready():
	for file in demos:
		var label = file.split("/")[-1].split(".")[0]
		$DemoSelector.add_item(label)


func explode(_a=0):
	particles.emitting = true


func _on_Button_pressed():
	if not dialogue_box.running:
		dialogue_box.start()


func _on_dialogue_signal(value):
	match(value):
		'explode': explode()


func _on_demo_selected(index):
	dialogue_box.load_file(demos[index])
