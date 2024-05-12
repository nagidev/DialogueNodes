extends Node3D


@onready var camera = $Camera3D
@onready var focus = $FocusPoint
@onready var greg = $Greg
@onready var clara = $Clara
@onready var binkle = $Binkle
@onready var bubble = $DialogueBubble
@onready var audio_player = $FocusPoint/AudioStreamPlayer3D

var tween : Tween


func _ready():
	bubble.custom_effects[0].char_displayed.connect(_on_char_displayed)


func _physics_process(_delta):
	camera.look_at(focus.global_position * 0.6 + Vector3(0, 1, 0))
	# press TAB to start the dialogue
	if Input.is_action_just_released('ui_focus_next') and not bubble.is_running():
		bubble.start('START')


func _on_dialogue_processed(speaker, _dialogue, _options):
	if (speaker is String and speaker == 'Greg') or (speaker is Character and speaker.name == 'Greg'):
		bubble.follow_node = greg
	elif speaker is Character and speaker.name == 'Clara':
		bubble.follow_node = clara
	elif speaker is Character and speaker.name == 'Binkle Doodle':
		bubble.follow_node = binkle
	
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(focus, 'position', bubble.follow_node.position, 1.0)


func _on_dialogue_signal(value):
	if value == 'doodle_in':
		var doodle_tween = create_tween()
		doodle_tween.tween_property(binkle, 'position', Vector3(binkle.position.x, 0, binkle.position.z), 3.0)
	if value == 'doodle_out':
		var doodle_tween = create_tween()
		doodle_tween.tween_property(binkle, 'position', Vector3(binkle.position.x, -2, binkle.position.z), 3.0)


func _on_char_displayed(_idx):
	audio_player.play()
