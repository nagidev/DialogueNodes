@tool
extends GraphNode


enum {STRING, INT, FLOAT, BOOL}

signal modified

@onready var variable = $HBoxContainer/Variable
@onready var operator = $HBoxContainer/Operator
@onready var type = $HBoxContainer/Type

@onready var string_value : LineEdit = $HBoxContainer/StringValue
@onready var int_value : SpinBox = $HBoxContainer/IntValue
@onready var float_value : SpinBox = $HBoxContainer/FloatValue
@onready var bool_value : CheckBox = $HBoxContainer/BoolValue

var types = [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL]
var last_shown : Control

func _ready():
	last_shown = string_value
	operator_add_string()

func _to_dict(graph):
	var dict = {}
	dict['variable'] = variable.text
	dict['type'] = operator.selected
	
	if (variable.text) == '':
		printerr(title + ' has an empty variable!')
		
	match(types[type.selected]):
		TYPE_STRING:
			dict['value'] = string_value.text
		TYPE_INT:
			dict['value'] = int(int_value.value)
		TYPE_FLOAT:
			dict['value'] = float_value.value
		TYPE_BOOL:
			dict['value'] = bool_value.button_pressed
		_:	
			dict['value'] = string_value.text
			print('ConditionNode: Invalid type set to dict')

	var next_nodes = graph.get_next(name)
	
	if len(next_nodes) > 0:
		dict['link'] = next_nodes[0]
	else:
		dict['link'] = 'END'
	
	return dict


func _from_dict(_graph, dict):
	var retrieved_value = dict['value']
	variable.text = dict['variable']
	
	match(typeof(retrieved_value)):
		TYPE_STRING:
			operator_add_string()
			string_value.text = retrieved_value
			type.selected = 0
		TYPE_INT:
			operator_add_number()
			int_value.value = retrieved_value
			type.selected = 1
		TYPE_FLOAT:
			operator_add_number()
			float_value.value = retrieved_value
			type.selected = 2
		TYPE_BOOL:
			operator_add_boolean()
			bool_value.button_pressed = retrieved_value
			type.selected = 3
		_:	
			print('ConditionNode: Cannot retrieve value of type ' + str(typeof(retrieved_value)))
	
	operator.selected = dict['type']
	
	return [dict['link']]

func operator_add_boolean():
	operator.clear()
	operator.add_item('=', 0)

func operator_add_string():
	operator.clear()
	operator.add_item('=', 0)
	operator.add_item('+=', 1)
	
func operator_add_number():
	operator.clear()
	operator.add_item('=', 0)
	operator.add_item('+=', 1)
	operator.add_item('-=', 2)
	operator.add_item('*=', 3)
	operator.add_item('/=', 4)

func clear_values():
	string_value.text = ""
	int_value.value = 0
	float_value.value = 0
	bool_value.button_pressed = false

func _on_type_changed(new_idx : int):
	if last_shown:
		last_shown.hide()

	match types[new_idx]:
		TYPE_STRING:
			string_value.show()
			operator_add_string()
			last_shown = string_value
		TYPE_INT:
			int_value.show()
			operator_add_number()
			last_shown = int_value
		TYPE_FLOAT:
			float_value.show()
			operator_add_number()
			last_shown = float_value
		TYPE_BOOL:
			bool_value.show()
			operator_add_boolean()
			last_shown = bool_value
			
	_on_modified()

func set_variable(_new_var):
	_on_modified()


func set_operator(_new_type):
	_on_modified()


func set_value(_new_val):
	_on_modified()


func _on_modified():
	modified.emit()
