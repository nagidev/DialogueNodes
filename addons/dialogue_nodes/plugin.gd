tool
extends EditorPlugin
# TODO : Undo/Redo support

var editor


func _enter_tree():
	editor = preload("res://addons/dialogue_nodes/NodeEditor.tscn").instance()
	
	# add editor to main viewport
	get_editor_interface().get_editor_viewport().add_child(editor)
	make_visible(false)
	
	# add dialogue provider node
	add_custom_type(
		'DialogueBox',
		'PopupDialog',
		preload("res://addons/dialogue_nodes/objects/dialogueBox.gd"),
		preload("res://addons/dialogue_nodes/icons/Dialogue.svg"))
	
	print_debug('Plugin Enabled')


func _exit_tree():
	# Remove from main viewport
	if editor:
		editor.queue_free()
	
	remove_custom_type('DialogueBox')
	
	print_debug('Plugin Disabled')


func has_main_screen():
	return true


func make_visible(visible):
	if editor:
		editor.visible = visible


func get_plugin_name():
	return "Dialogue Nodes"


func get_plugin_icon():
	# get_editor_interface().get_base_control().get_icon("Script", "EditorIcons")
	return preload("res://addons/dialogue_nodes/icons/Dialogue.svg")


func save_external_data():
	if editor:
		editor.files.save_all()
