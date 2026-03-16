@tool
extends BoxContainer


signal modified
signal delete_requested

@onready var condition_button: Button = $ConditionButton
@onready var condition_panel: PopupPanel = $ConditionPanel
@onready var condition_list: BoxContainer = $ConditionPanel/ConditionList

const operator_texts := ['==', '!=', '>', '<', '>=', '<=']
const combiner_texts := ['OR', 'AND']

var undo_redo : EditorUndoRedoManager :
	set(value):
		undo_redo = value
		if is_instance_valid(condition_list):
			condition_list.undo_redo = undo_redo
var condition_popup_offset := 50

func get_condition() -> Array[Dictionary]:
	return condition_list._to_dict()


func set_condition(new_condition: Array[Dictionary]) -> void:
	condition_list._from_dict(new_condition)
	update_button_text()


func is_empty() -> bool:
	return condition_list.is_empty()


func update_button_text() -> void:
	condition_button.text = 'Set condition'
	var new_condition: Array = condition_list._to_dict()
	if new_condition.size() == 0: return
	
	var new_text := ''
	for cond_dict: Dictionary in new_condition:
		if cond_dict.is_empty():
			new_text += 'true '
			continue
		new_text += cond_dict.value1 + ' '
		new_text += operator_texts[cond_dict.operator] + ' '
		new_text += cond_dict.value2 + ' '
		if cond_dict.has('combiner'): new_text += combiner_texts[cond_dict.combiner] + ' '
	condition_button.text = new_text


func _on_condition_button_pressed() -> void:
	var popup_pos : Vector2 = global_position + condition_button.position + Vector2(0, condition_button.size.y + size.y + condition_popup_offset)
	condition_panel.popup(Rect2i(popup_pos, condition_panel.size))


func _on_delete_button_pressed() -> void:
	delete_requested.emit()


func _on_condition_panel_hide() -> void:
	update_button_text()


func _on_modified() -> void:
	condition_panel.size.y = 0
	modified.emit()

func update_variables(variables_list: Array[String]) -> void:
	condition_list.update_variables(variables_list)
	
