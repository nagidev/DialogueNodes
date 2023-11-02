@tool
extends EditorPlugin
# TODO : Undo/Redo support

var editor


func _enter_tree():
	editor = preload('res://addons/dialogue_nodes/NodeEditor.tscn').instantiate()
	
	# add editor to main viewport
	get_editor_interface().get_editor_main_screen().add_child(editor)
	var editor_settings = get_editor_interface().get_editor_settings()
	var base_color : Color = editor_settings.get_setting('interface/theme/base_color')
	editor._base_color = Color.WHITE if base_color.v < 0.5 else Color.BLACK
	_make_visible(false)
	
	# add dialogue provider node
	add_custom_type(
		'DialogueBox',
		'Panel',
		preload('res://addons/dialogue_nodes/objects/dialogueBox.gd'),
		preload('res://addons/dialogue_nodes/icons/Dialogue.svg'))
	
	print_debug('Plugin Enabled')


func _exit_tree():
	# Remove from main viewport
	if editor:
		editor.queue_free()
	
	remove_custom_type('DialogueBox')
	
	print_debug('Plugin Disabled')


func _has_main_screen():
	return true


func _make_visible(visible):
	if editor:
		editor.visible = visible


func _get_plugin_name():
	return 'Dialogue Nodes'


func _get_plugin_icon():
	# get_editor_interface().get_base_control().get_icon('Script', 'EditorIcons')
	return preload('res://addons/dialogue_nodes/icons/Dialogue.svg')


func _save_external_data():
	if editor:
		editor.files.save_all()

