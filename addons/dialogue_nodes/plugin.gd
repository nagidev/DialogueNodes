@tool
extends EditorPlugin
# TODO : Undo/Redo support

const EditorScene = preload('res://addons/dialogue_nodes/NodeEditor.tscn')
var editor

func _enter_tree():
	editor = EditorScene.instantiate()
	# add editor to main viewport
	get_editor_interface().get_editor_main_screen().add_child(editor)
	
	# get base color from editor settings
	var editor_settings = get_editor_interface().get_editor_settings()
	var base_color : Color = editor_settings.get_setting('interface/theme/base_color')
	editor._base_color = Color.WHITE if base_color.v < 0.5 else Color.BLACK
	
	_make_visible(false)

func _exit_tree():
	# remove from main viewport
	if is_instance_valid(editor):
		editor.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if is_instance_valid(editor):
		editor.visible = visible

func _get_plugin_name():
	return 'Dialogue Nodes'

func _get_plugin_icon():
	return preload('res://addons/dialogue_nodes/icons/Dialogue.svg')

func _save_external_data():
	if is_instance_valid(editor):
		editor.files.save_all()

