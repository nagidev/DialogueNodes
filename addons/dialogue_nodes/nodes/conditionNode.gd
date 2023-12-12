@tool
extends GraphNode


enum {EQUAL, NEQUAL, GREATER, LESS, GEQUAL, LEQUAL}

signal modified

@onready var value1 = $HBoxContainer/Value1
@onready var operator = $HBoxContainer/Operator
@onready var value2 = $HBoxContainer/Value2

@onready var trueLabel = $TrueLabel
@onready var falseLabel = $FalseLabel


func _to_dict(graph):
	var dict = {}
	dict['value1'] = value1.text
	dict['operator'] = operator.selected
	dict['value2'] = value2.text
	
	dict['true'] = 'END'
	dict['false'] = 'END'
	
	for connection in graph.get_connection_list():
		if connection['from_node'] == name:
			if connection['from_port'] == 0:
				dict['true'] = connection['to_node']
			elif connection['from_port'] == 1:
				dict['false'] = connection['to_node']
	
	return dict


func _from_dict(_graph, dict):
	value1.text = dict['value1']
	operator.selected = dict['operator']
	value2.text = dict['value2']
	
	
	return [dict['true'], dict['false']]


func set_type(_new_type):
	_on_modified()


func set_value(_new_val):
	_on_modified()


func _on_modified():
	modified.emit()
