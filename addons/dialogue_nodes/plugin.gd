tool
extends EditorPlugin

var scene


func _enter_tree():
	scene = preload("res://addons/dialogue_nodes/NodeEditor.tscn").instance()
	#add_control_to_bottom_panel(scene, 'Dialogue Nodes')
	
	get_editor_interface().get_editor_viewport().add_child(scene)
	make_visible(false)
	print('Plugin Enabled')


func _exit_tree():
	#remove_control_from_bottom_panel(scene)
	# Remove from main viewport
	if scene:
		scene.queue_free()
	scene.free()
	print('Plugin Disabled')


func has_main_screen():
	return true


func make_visible(visible):
	if scene:
		scene.visible = visible


func get_plugin_name():
	return "Dialogue Nodes"


func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Script", "EditorIcons")
