@tool
extends HBoxContainer

signal modified
signal text_changed(new_text: String)

@onready var line_edit := $LineEdit
@onready var filter_button := $FilterButton
@onready var filter_panel := $FilterPanel
@onready var condition_list := $FilterPanel/ConditionList

var undo_redo: EditorUndoRedoManager :
	set(value):
		undo_redo = value
		if is_instance_valid(condition_list):
			condition_list.undo_redo = undo_redo
var text := ''
var filter_popup_offset := 50


func set_text(new_text: String) -> void:
	if line_edit.text != new_text:
		line_edit.text = new_text
		filter_button.visible = new_text != ''
	text = new_text


func get_condition() -> Array[Dictionary]:
	return condition_list._to_dict()


func set_condition(new_condition: Array[Dictionary]) -> void:
	condition_list._from_dict(new_condition)
	filter_button.text = '' if condition_list.is_empty() else '*'


func _on_filter_button_pressed() -> void:
	var popup_pos: Vector2 = global_position + filter_button.position + Vector2(0, filter_button.size.y + size.y + filter_popup_offset)
	filter_panel.popup(Rect2i(popup_pos, filter_panel.size))


func _on_text_changed(new_text: String) -> void:
	filter_button.visible = new_text != ''
	text_changed.emit(new_text)


func _on_text_focus_exited() -> void:
	focus_exited.emit()


func _on_modified() -> void:
	filter_button.text = '' if condition_list.is_empty() else '*'
	filter_panel.size.y = 0
	modified.emit()

func update_variables(variable_list: Array[String]) -> void:
	condition_list.update_variables(variable_list)
