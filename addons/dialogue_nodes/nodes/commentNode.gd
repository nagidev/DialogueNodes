tool
extends "res://addons/dialogue_nodes/nodes/baseNode.gd"

onready var commentNode = $Comment


func _ready():
	commentNode.connect('text_changed', self, "_on_modified")


func getCommentText():
	return commentNode.text


func setCommentText(newText):
	commentNode.text = newText
