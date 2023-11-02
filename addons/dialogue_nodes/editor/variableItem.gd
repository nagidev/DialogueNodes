@tool
extends HBoxContainer

signal modified

@onready var var_name : LineEdit = $Name
@onready var type = $Type
@onready var string_value : LineEdit = $StringValue
@onready var int_value : SpinBox = $IntValue
@onready var float_value : SpinBox = $FloatValue
@onready var bool_value : CheckBox = $BoolValue

var types = [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL]
var last_shown : Control

func _ready():
	last_shown = string_value
	
	for i in range(type.item_count):
		type.set_item_id(i, types[i])
	
	type.item_selected.connect(_on_type_changed)
	
	var_name.text_changed.connect(_on_modified)
	type.item_selected.connect(_on_modified)
	string_value.text_changed.connect(_on_modified)
	int_value.value_changed.connect(_on_modified)
	float_value.value_changed.connect(_on_modified)
	bool_value.toggled.connect(_on_modified)


func get_value():
	match types[type.selected]:
		TYPE_STRING:
			return string_value.text
		TYPE_INT:
			return int_value.value
		TYPE_FLOAT:
			return float_value.value
		TYPE_BOOL:
			return bool_value.button_pressed
	return ''


func set_value(new_value):
	match types[type.selected]:
		TYPE_STRING:
			string_value.text = str(new_value)
		TYPE_INT:
			int_value.value = int(new_value)
		TYPE_FLOAT:
			float_value.value = float(new_value)
		TYPE_BOOL:
			bool_value.button_pressed = bool(new_value)


func _on_type_changed(new_idx : int):
	if last_shown:
		last_shown.hide()
	
	match types[new_idx]:
		TYPE_STRING:
			string_value.show()
			last_shown = string_value
		TYPE_INT:
			int_value.show()
			last_shown = int_value
		TYPE_FLOAT:
			float_value.show()
			last_shown = float_value
		TYPE_BOOL:
			bool_value.show()
			last_shown = bool_value


func _on_delete_pressed():
	_on_modified()
	queue_free()


func _on_modified(_a= 0, _b= 0):
	modified.emit()
