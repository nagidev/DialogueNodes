@tool
extends GraphNode


signal modified

@onready var path: LineEdit = $BoxContainer/FilePath
@onready var file_path: String = path.text
@onready var ID: LineEdit = $ID
@onready var start_id: String = ID.text
@onready var open_dialog: FileDialog = $OpenDialog
@onready var path_timer: Timer = $PathTimer
@onready var id_timer: Timer = $IDTimer

var undo_redo : EditorUndoRedoManager


func _to_dict(graph : GraphEdit):
	var dict := {}
	var connections : Array = graph.get_connections(name)
	
	dict['file_path'] = file_path
	dict['start_id'] = start_id
	dict['link'] = connections[0]['to_node'] if connections.size() > 0 else 'END'
	
	return dict


func _from_dict(dict : Dictionary):
	set_path(dict['file_path'])
	set_ID(dict['start_id'])
	
	return [dict['link']]


func set_path(new_path: String):
	file_path = new_path
	if path.text != file_path:
		path.text = file_path


func set_ID(new_id: String):
	start_id = new_id
	if ID.text != start_id:
		ID.text = start_id


func _on_browse_button_pressed() -> void:
	open_dialog.popup_centered()


func _on_file_selected(new_path: String) -> void:
	path.text = new_path
	_on_path_timer_timeout()


func _on_file_path_changed(_path) -> void:
	path_timer.stop()
	path_timer.start()


func _on_path_timer_timeout() -> void:
	if not undo_redo:
		file_path = path.text
		return
	
	undo_redo.create_action('Set file path')
	undo_redo.add_do_method(self, 'set_path', path.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_path', file_path)
	undo_redo.commit_action()


func _on_ID_changed(_id):
	id_timer.stop()
	id_timer.start()


func _on_id_timer_timeout():
	if not undo_redo:
		start_id = ID.text
		return
	
	undo_redo.create_action('Set start ID')
	undo_redo.add_do_method(self, 'set_ID', ID.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_ID', start_id)
	undo_redo.commit_action()


func _on_modified():
	modified.emit()
