@tool
extends GraphNode


signal modified

@onready var condition_list: BoxContainer = $ConditionList

var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	condition_list.undo_redo = undo_redo


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict = {}
	dict['condition'] = condition_list._to_dict()
	
	dict['true'] = 'END'
	dict['false'] = 'END'
	
	for connection in graph.get_connection_list():
		if connection['from_node'] == name:
			if connection['from_port'] == 0:
				dict['true'] = connection['to_node']
			elif connection['from_port'] == 1:
				dict['false'] = connection['to_node']
	
	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	condition_list._from_dict(dict['condition'])
	
	return [dict['true'], dict['false']]


func _on_modified() -> void:
	reset_size()
	modified.emit()

func _on_variables_updated(variables_list: Array[String]) -> void:
	condition_list.update_variables(variables_list)
