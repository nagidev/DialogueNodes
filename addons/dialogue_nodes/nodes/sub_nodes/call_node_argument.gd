@tool
extends Container
##
## Call Node Argument
##
## Represents an argument in a CallNode's method. Used to store the argument's data, as well as
## react to user editing based on said data.

var arg_name: String = ''
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


func get_arg() -> String:
	return _input.text


func set_arg(new_arg: String) -> void:
	_input.text = new_arg
	_button.visible = new_arg != (str(default_arg) if default_arg != null else '')


func get_data() -> Dictionary:
	return { 'name': arg_name, 'type': type, 'argument': _input.text, 'default': default_arg }


func set_data(new_name: String, new_type: Variant.Type, argument: String, new_default) -> void:
	# Set Name
	_label.text = new_name
	arg_name = new_name
	
	# Set Type
	_input.placeholder_text = (
		type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ''
	)
	type = new_type
	
	# Set Default Value
	default_arg = new_default
	
	# Set Argument
	if !argument.is_empty():
		set_arg(argument)
	else:
		set_arg(str(new_default) if new_default != null else '')


func _validate_input_type() -> bool:
	return (
		type == Variant.Type.TYPE_NIL
		or type == Variant.Type.TYPE_STRING
		or typeof(str_to_var(_input.text)) == type
	)


func _on_argument_input_text_changed(new_text: String) -> void:
	_button.visible = new_text != (str(default_arg) if default_arg != null else '')


func _on_reset_button_pressed() -> void:
	_input.text = str(default_arg) if default_arg != null else ''
	_on_argument_input_text_changed(_input.text)


func _on_argument_input_focus_exited() -> void:
	if !_validate_input_type():
		push_error(
			'Argument <%s> with value <%s> in CallNode <%s> cannot be converted to the needed type <%s>!'
			% [arg_name, _input.text, _call_node.title, type_string(type)]
		)
	_call_node.reset_size()
