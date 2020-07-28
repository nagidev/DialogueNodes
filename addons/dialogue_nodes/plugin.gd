tool
extends EditorPlugin

var scene


func _enter_tree():
	scene = preload("res://addons/dialogue_nodes/NodeEditor.tscn").instance()
	add_control_to_bottom_panel(scene, 'Dialogue Nodes')
	print('Plugin Enabled')


func _exit_tree():
	remove_control_from_bottom_panel(scene)
	scene.free()
	print('Plugin Disabled')
