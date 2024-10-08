@tool
extends EditorPlugin


const EditorScene := preload('res://addons/dialogue_nodes/Editor.tscn')
const DialogueBoxScene := preload('res://addons/dialogue_nodes/objects/DialogueBox.gd')
const DialogueBubbleScene := preload('res://addons/dialogue_nodes/objects/DialogueBubble.gd')
const DialogueBoxIcon := preload('res://addons/dialogue_nodes/icons/DialogueBox.svg')
const DialogueBubbleIcon := preload('res://addons/dialogue_nodes/icons/DialogueBubble.svg')

var editor: Control


func _enter_tree() -> void:
	editor = EditorScene.instantiate()
	
	# add editor to main viewport
	get_editor_interface().get_editor_main_screen().add_child(editor)
	
	# get undo redo manager
	editor.undo_redo = get_undo_redo()
	
	_make_visible(false)
	
	# add dialogue box and bubble nodes
	add_custom_type(
		'DialogueBox',
		'Panel',
		DialogueBoxScene,
		DialogueBoxIcon)
	add_custom_type(
		'DialogueBubble',
		'RichTextLabel',
		DialogueBubbleScene,
		DialogueBubbleIcon
	)
	
	print_debug('Plugin Enabled')


func _exit_tree() -> void:
	# remove from main viewport
	if is_instance_valid(editor):
		editor.queue_free()
	
	remove_custom_type('DialogueBox')
	
	print_debug('Plugin Disabled')


func _has_main_screen() -> bool:
	return true


func _make_visible(visible) -> void:
	if is_instance_valid(editor):
		editor.visible = visible


func _get_plugin_name() -> String:
	return 'Dialogue'


func _get_plugin_icon() -> Texture2D:
	return preload('res://addons/dialogue_nodes/icons/Dialogue.svg')


func _handles(object) -> bool:
	return object is DialogueData


func _edit(object) -> void:
	if object is DialogueData and is_instance_valid(editor):
		editor.files.open_file(object.resource_path)


func _save_external_data() -> void:
	if is_instance_valid(editor):
		editor.files.save_all()
