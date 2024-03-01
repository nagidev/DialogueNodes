@tool
extends GraphNode

enum {EQUAL, NEQUAL, GREATER, LESS, GEQUAL, LEQUAL}

signal modified

@onready var variable = $HBoxContainer/Variable
@onready var operator = $HBoxContainer/Operator
@onready var type = $HBoxContainer/Type

@onready var string_value : LineEdit = $HBoxContainer/StringValue
@onready var int_value : SpinBox = $HBoxContainer/IntValue
@onready var float_value : SpinBox = $HBoxContainer/FloatValue
@onready var bool_value : CheckBox = $HBoxContainer/BoolValue

@onready var trueLabel = $TrueLabel
@onready var falseLabel = $FalseLabel

var types = [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_OBJECT]
var last_shown : Control
var is_operators_full: bool

func _ready():
	last_shown = string_value
	is_operators_full = true
	operator_add_simple()
	
func _to_dict(graph):
	var dict = {}
	dict['value1'] = variable.text
	dict['operator'] = operator.selected
	
	dict['true'] = 'END'
	dict['false'] = 'END'
	
	if variable.text == '':
		printerr(title + ' has an empty variable name')
		
	match(types[type.selected]):
		TYPE_STRING:
			dict['value2'] = string_value.text
		TYPE_INT:
			dict['value2'] = int(int_value.value)
		TYPE_FLOAT:
			dict['value2'] = float_value.value
		TYPE_BOOL:
			dict['value2'] = bool_value.button_pressed
		TYPE_OBJECT:
			dict['value2'] = '{{' + string_value.text + '}}'
			if string_value.text == '':
				printerr(title + ': comparison variable is empty!')
		_:
			dict['value2'] = string_value.text
			print('ConditionNode: Invalid type set to dict')
		
	for connection in graph.get_connection_list():
		if connection['from_node'] == name:
			if connection['from_port'] == 0:
				dict['true'] = connection['to_node']
			elif connection['from_port'] == 1:
				dict['false'] = connection['to_node']
	
	return dict


func _from_dict(_graph, dict):
	clear_values()
	variable.text = dict['value1'] 
	
	var retrieved_value = dict['value2']
	
	match(typeof(retrieved_value)):
		TYPE_STRING:
			#checks if variable
			if retrieved_value.begins_with('{{') and retrieved_value.ends_with('}}'):
				operator_add_full()
				string_value.text = retrieved_value.replace('{{', '').replace('}}', '')
				type.selected = 4
			else:
				operator_add_simple()
				string_value.text = retrieved_value
				type.selected = 0
		TYPE_INT:
			operator_add_full()
			int_value.value = retrieved_value
			type.selected = 1
		TYPE_FLOAT:
			operator_add_full()
			float_value.value = retrieved_value
			type.selected = 2
		TYPE_BOOL:
			operator_add_simple()
			bool_value.button_pressed = retrieved_value
			type.selected = 3
		_:	
			print('ConditionNode: Cannot retrieve value of type ' + str(typeof(retrieved_value)))
	
	operator.selected = dict['operator']
	
	return [dict['true'], dict['false']]

func clear_values():
	string_value.text = ""
	int_value.value = 0
	float_value.value = 0
	bool_value.button_pressed = false

func operator_add_simple():
	if is_operators_full:
		is_operators_full = false
		operator.clear()
		operator.add_item('==', 0)
		operator.add_item('!=', 1)

func operator_add_full():
	if not is_operators_full:
		is_operators_full = true
		operator.clear()
		operator.add_item('==', 0)
		operator.add_item('!=', 1)
		operator.add_item('>', 2)
		operator.add_item('<', 3)
		operator.add_item('>=', 4)
		operator.add_item('<=', 5)
	
func set_operator(_new_operator):
	_on_modified()

func set_value(_new_val):
	_on_modified()

func _on_type_changed(new_idx : int):
	if last_shown:
		last_shown.hide()

	match types[new_idx]:
		TYPE_STRING:
			string_value.show()
			operator_add_simple()
			last_shown = string_value
		TYPE_INT:
			int_value.show()
			operator_add_full()
			last_shown = int_value
		TYPE_FLOAT:
			float_value.show()
			operator_add_full()
			last_shown = float_value
		TYPE_BOOL:
			bool_value.show()
			operator_add_simple()
			last_shown = bool_value
		TYPE_OBJECT:
			string_value.show()
			operator_add_full()
			last_shown = string_value
	
	_on_modified()

func _on_modified():
	modified.emit()
