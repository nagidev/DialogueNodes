@tool
extends Container
##
## Call Node Argument
##
## Represents an argument in a CallNode's method. Used to store the argument's data, as well as
## react to user editing based on said data.

@export var _line_edit_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/LineEdit.svg')
@export var _text_edit_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/TextEdit.svg')

var arg_name: String = ''
var type: Variant.Type = Variant.Type.TYPE_NIL
var default_arg = null

var _call_node: GraphNode = null
var _arg: String = ""

@onready var _label: Label = %ArgumentLabel
@onready var _line_edit: LineEdit = %ArgumentLineEdit
@onready var _text_edit: TextEdit = %ArgumentTextEdit

@onready var _reset_button: Button = %ResetButton
@onready var _swap_edit_button: Button = %SwapEditButton


func _ready() -> void:
	_text_edit.visible = false
	_reset_button.visible = false


func set_call_node(call_node: GraphNode) -> void:
	_call_node = call_node


func get_arg() -> String:
	return _arg


func set_arg(new_arg: String) -> void:
	_arg = new_arg
	_line_edit.text = new_arg
	_text_edit.text = new_arg
	_set_reset_button_visibility()


func get_data() -> Dictionary:
	return { 'name': arg_name, 'type': type, 'argument': _arg, 'default': default_arg }


func set_data(new_name: String, new_type: Variant.Type, argument: String, new_default) -> void:
	# Set Name
	_label.text = new_name
	arg_name = new_name
	
	# Set Type
	var placeholder: String = type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ''
	_line_edit.placeholder_text = placeholder
	_text_edit.placeholder_text = placeholder
	type = new_type
	
	# Set Default Value
	default_arg = new_default
	
	# Set Argument
	if !argument.is_empty():
		set_arg(argument)
	else:
		set_arg(str(new_default) if new_default != null else '')


func _set_reset_button_visibility() -> void:
	_reset_button.visible = _arg != (str(default_arg) if default_arg != null else '')


func _validate_input_type() -> bool:
	return (
		type == Variant.Type.TYPE_NIL
		or type == Variant.Type.TYPE_STRING
		or typeof(str_to_var(_arg)) == type
	)


func _on_argument_line_edit_text_changed(new_text: String) -> void:
	_arg = new_text
	if !_line_edit.visible:
		return
	_text_edit.text = _arg
	_set_reset_button_visibility()


func _on_argument_text_edit_text_changed() -> void:
	_arg = _text_edit.text
	if !_text_edit.visible:
		return
	_line_edit.text = _arg
	_set_reset_button_visibility()


func _on_reset_button_pressed() -> void:
	_arg = str(default_arg) if default_arg != null else ''
	_line_edit.text = _arg
	_text_edit.text = _arg
	_set_reset_button_visibility()
	_call_node.reset_size.call_deferred()


func _on_any_argument_edit_focus_exited() -> void:
	if !_validate_input_type():
		push_error(
			'Argument <%s> with value <%s> in CallNode <%s> cannot be converted to the needed type <%s>!'
			% [arg_name, _arg, _call_node.title, type_string(type)]
		)
	_call_node.reset_size()


func _on_swap_edit_button_pressed() -> void:
	_line_edit.visible = !_line_edit.visible
	_text_edit.visible = !_text_edit.visible

	_swap_edit_button.icon = _line_edit_icon if _line_edit.visible else _text_edit_icon
	_call_node.reset_size()
