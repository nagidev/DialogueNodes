@tool
extends Container
##
## Call Node Argument
##
## Represents an argument in a CallNode's method. Used to store the argument's data, as well as
## react to user editing based on said data.

## A copy-paste of the <Variant.Type> enum, but I can't do .keys() on that one... dumb.
enum TYPE_STR {
	TYPE_NIL = 0,
	TYPE_BOOL = 1,
	TYPE_INT = 2,
	TYPE_FLOAT = 3,
	TYPE_STRING = 4,
	TYPE_VECTOR2 = 5,
	TYPE_VECTOR2I = 6,
	TYPE_RECT2 = 7,
	TYPE_RECT2I = 8,
	TYPE_VECTOR3 = 9,
	TYPE_VECTOR3I = 10,
	TYPE_TRANSFORM2D = 11,
	TYPE_VECTOR4 = 12,
	TYPE_VECTOR4I = 13,
	TYPE_PLANE = 14,
	TYPE_QUATERNION = 15,
	TYPE_AABB = 16,
	TYPE_BASIS = 17,
	TYPE_TRANSFORM3D = 18,
	TYPE_PROJECTION = 19,
	TYPE_COLOR = 20,
	TYPE_STRING_NAME = 21,
	TYPE_NODE_PATH = 22,
	TYPE_RID = 23,
	TYPE_OBJECT = 24,
	TYPE_CALLABLE = 25,
	TYPE_SIGNAL = 26,
	TYPE_DICTIONARY = 27,
	TYPE_ARRAY = 28,
	TYPE_PACKED_BYTE_ARRAY = 29,
	TYPE_PACKED_INT32_ARRAY = 30,
	TYPE_PACKED_INT64_ARRAY = 31,
	TYPE_PACKED_FLOAT32_ARRAY = 32,
	TYPE_PACKED_FLOAT64_ARRAY = 33,
	TYPE_PACKED_STRING_ARRAY = 34,
	TYPE_PACKED_VECTOR2_ARRAY = 35,
	TYPE_PACKED_VECTOR3_ARRAY = 36,
	TYPE_PACKED_COLOR_ARRAY = 37,
	TYPE_PACKED_VECTOR4_ARRAY = 38,
	TYPE_MAX = 39
}

var arg_name: String = ""
var type: Variant.Type = Variant.Type.TYPE_NIL
var default_arg = null

@onready var _label: Label = %ArgumentLabel
@onready var _input: LineEdit = %ArgumentInput
@onready var _button: Button = %ResetButton


func get_data() -> Dictionary:
	return { "name": arg_name, "type": type, "default": default_arg }


func set_data(new_name: String, new_type: Variant.Type, new_default) -> void:
	# Set Name
	_label.text = new_name
	arg_name = new_name

	# Set Type
	_input.placeholder_text = (
		"" if new_type == Variant.Type.TYPE_NIL else TYPE_STR.keys()[int(new_type)]
	)
	type = new_type

	# Set Default Value
	_input.text = str(new_default if new_default != null else "")
	default_arg = new_default


func _on_argument_input_text_changed(new_text: String) -> void:
	_button.visible = new_text != (str(default_arg) if default_arg != null else "")


func _on_reset_button_pressed() -> void:
	_input.text = str(default_arg) if default_arg != null else ""
	_on_argument_input_text_changed(_input.text)
