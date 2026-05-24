@tool
extends GraphNode


signal modified

@onready var variable := $BoxContainer/Variable
@onready var variable_timer := $VariableTimer
@onready var type := $BoxContainer/Type
@onready var value := $BoxContainer/Value
@onready var value_timer := $ValueTimer

var undo_redo: EditorUndoRedoManager
var last_variable: String
var last_type: int
var last_value: String
var cur_variable := -1

func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := {}
	var connections: Array = graph.get_connections(name)
	
	dict['cur_variable'] = cur_variable
	dict['variable'] = graph.last_variable_list[cur_variable]
	dict['type'] = type.selected
	dict['value'] = value.text
	dict['link'] = connections[0]['to_node'] if connections.size() > 0 else 'END'
	
	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	cur_variable = dict['cur_variable']
	type.selected = dict['type']
	value.text = dict['value']
	
	last_variable = variable.text
	last_type = type.selected
	last_value = value.text
	
	return [dict['link']]


func set_variable(new_variable: String) -> void:
	if variable.text != new_variable:
		variable.text = new_variable
	last_variable = new_variable


func set_value(new_value: String) -> void:
	if value.text != new_value:
		value.text = new_value
	last_value = new_value


func _on_variable_changed(_new_text) -> void:
	variable_timer.stop()
	variable_timer.start()


func _on_variable_timer_timeout() -> void:
	if not undo_redo: return
	
	undo_redo.create_action('Set variable name')
	undo_redo.add_do_method(self, 'set_variable', variable.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_variable', last_variable)
	undo_redo.commit_action()


func _on_type_selected(idx: int) -> void:
	if not undo_redo: return
	
	undo_redo.create_action('Set operator type')
	undo_redo.add_do_method(type, 'select', idx)
	undo_redo.add_do_property(self, 'last_type', idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(type, 'select', last_type)
	undo_redo.add_undo_property(self, 'last_type', last_type)
	undo_redo.commit_action()


func _on_value_changed(_new_text) -> void:
	value_timer.stop()
	value_timer.start()


func _on_value_timer_timeout() -> void:
	if not undo_redo: return
	
	undo_redo.create_action('Set value')
	undo_redo.add_do_method(self, 'set_value', value.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', last_value)
	undo_redo.commit_action()


func _on_modified() -> void:
	modified.emit()

func _on_variables_updated(variables_list: Array[String]) -> void:
	variable.clear()
	
	for variable_name in variables_list:
		variable.add_item(variable_name)
	
	if variables_list.size() > 0:
		if cur_variable > variables_list.size():
			cur_variable = 0
		variable.select(cur_variable)
	else:
		variable.select(-1)

func _on_variable_selected(idx: int) -> void:
	if not undo_redo: 
		cur_variable = idx
		variable.select(idx)
		_on_modified()
		return
	
	undo_redo.create_action('Set variable')
	undo_redo.add_do_property(self, 'cur_variable', idx)
	undo_redo.add_do_method(variable, 'select', idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_property(self, 'cur_variable', cur_variable)
	undo_redo.add_undo_method(variable, 'select', cur_variable)
	undo_redo.commit_action()
