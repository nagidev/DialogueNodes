tool
extends "res://addons/dialogue_nodes/nodes/baseNode.gd"

onready var ID = $ID

func getID():
	if ID.text == '':
		return name
	return ID.text


func setID(newID):
	ID.text = newID
