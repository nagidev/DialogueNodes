@tool
extends Container
##
## Call Node Argument
##
## Represents an argument in a CallNode's method. Used to store the argument's data, as well as
## react to user editing based on said data.

var arg_name: String = ""
var type: Variant.Type = Variant.Type.TYPE_NIL
var default_arg = null

var _call_node: GraphNode = null

@onready var _label: Label = %ArgumentLabel
@onready var _input: LineEdit = %ArgumentInput
@onready var _button: Button = %ResetButton


func _ready() -> void:
	_button.visible = false


func set_call_node(call_node: GraphNode) -> void:
	_call_node = call_node


func get_data() -> Dictionary:
	return { "name": arg_name, "type": type, "default": default_arg }


func set_data(new_name: String, new_type: Variant.Type, new_default) -> void:
	# Set Name
	_label.text = new_name
	arg_name = new_name

	# Set Type
	_input.placeholder_text = (
		type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ""
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


func _on_argument_input_focus_exited() -> void:
	if type == Variant.Type.TYPE_NIL:
		return
	var convert_test = type_convert(_input.text, type)
	if typeof(convert_test) != type:
		push_warning(
			"Argument <%s> in CallNode <%s> cannot be converted to type <%s>!"
			% [name, _call_node.title, type_string(type)]
		)
	
	print(_input.text)
	print(convert_test)
