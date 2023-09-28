extends Control

var demos: Array[String] = [
	"res://examples/Example1.json",
	"res://examples/Example2.json",
	"res://examples/Example3.json",
	"res://examples/Example4.json"
]

var starts: Array[String] = [
	"SIGNALS",
	"SETGET",
	"CONDITION"
]

@onready var dialogue_box = $DialogueBox
@onready var particles = $Particles

var selected_start = -1

func _ready():
	for file in demos:
		var label = file.split("/")[-1].split(".")[0]
		$DemoSelector.add_item(label)
	pass
	for start in starts:
		$StartSelector.add_item(start)
	pass


func explode(_a=0):
	particles.emitting = true


func _on_Button_pressed():
	if not dialogue_box.running:
		if $StartSelector.visible:
			dialogue_box.start(starts[selected_start])
		else:
			dialogue_box.start()


func _on_dialogue_signal(value):
	match(value):
		'explode': explode()


func _on_demo_selected(index):
	print("loading file:", demos[index])
	dialogue_box.load_file(demos[index])
	if index == 3:
		$StartSelector.visible = true
		selected_start = 0
	else:
		$StartSelector.visible = false
		selected_start = -1

func _on_start_selected(index):
	print("selected start:" + starts[index])
	selected_start = index