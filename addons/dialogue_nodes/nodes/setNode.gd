@tool
extends GraphNode


signal modified

@onready var variable = $HBoxContainer/Variable
@onready var type = $HBoxContainer/Type
@onready var value = $HBoxContainer/Value


func _to_dict(graph):
	var dict = {}
	dict['variable'] = variable.text
	dict['type'] = type.selected
	dict['value'] = value.text
	
	var next_nodes = graph.get_next(name)
	
	if len(next_nodes) > 0:
		dict['link'] = next_nodes[0]
	else:
		dict['link'] = 'END'
	
	return dict


func _from_dict(_graph, dict):
	variable.text = dict['variable']
	type.selected = dict['type']
	value.text = dict['value']
	
	return [dict['link']]


func set_variable(_new_var):
	_on_modified()


func set_type(_new_type):
	_on_modified()


func set_value(_new_val):
	_on_modified()


func _on_modified():
	modified.emit()
