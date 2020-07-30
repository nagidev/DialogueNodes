tool
extends "res://addons/dialogue_nodes/nodes/baseNode.gd"

onready var commentNode = $Comment


func getCommentText():
	return commentNode.text


func setCommentText(newText):
	commentNode.text = newText
