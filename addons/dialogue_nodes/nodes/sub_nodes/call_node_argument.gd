@tool
extends Container
##
## Call Node Argument
##
## Represents an argument in a CallNode's method. Used to store the argument's data, as well as
## react to user editing based on said data.

signal changed_value(arg: Control, old: String, new: String)

# NOTE: Not a fan of this being defined here. Systematic default colors (Error, Warning, etc.)
# should be customizable, but the default value should be "centralized" somewhere in the addon
# so that all Nodes and such can refer to it. I'd recommend a custom Resource instance.
@export var invalid_color = Color.DARK_RED
@export_range(0.0, 30.0, 0.1) var _font_size_margin: float = 15.0

var arg_name: String = ''
var type: Variant.Type = Variant.Type.TYPE_NIL
var default_arg = null

var _call_node: GraphNode = null
var _arg: String = ''

@onready var _label: Label = %ArgumentLabel
@onready var _input: TextEdit = %ArgumentTextEdit

@onready var _reset_button: Button = %ResetButton


func _ready() -> void:
	_input.text = ''
	_reset_button.visible = false
	_resize_input_to_arg()


func set_call_node(call_node: GraphNode) -> void:
	_call_node = call_node


func get_arg() -> String:
	return _arg


func set_arg(new_arg: String) -> void:
	_arg = new_arg
	_input.text = new_arg
	_set_reset_button_visibility()
	_resize_input_to_arg()
	
	if _validate_contents():
		_input.remove_theme_color_override('background_color')
	else:
		_input.add_theme_color_override('background_color', invalid_color)
	
	_call_node.reset_size.call_deferred()


func get_data() -> Dictionary:
	return { 'name': arg_name, 'type': type, 'argument': _arg, 'default': default_arg }


func set_data(new_name: String, new_type: Variant.Type, argument: String, new_default) -> void:
	# Set Name
	_label.text = new_name
	arg_name = new_name
	
	# Set Type
	_input.placeholder_text = type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ''
	type = new_type
	
	# Set Default Value
	default_arg = new_default
	
	# Set Argument
	if !argument.is_empty():
		set_arg(argument)
	else:
		set_arg(str(new_default) if new_default != null else '')


func _validate_text_type() -> bool:
	var var_parsed_text: String = (
		_input.text
		if _input.text.count("{{") <= 0
		else _input.text  # TODO: Return Variable-Parsed text.
	)
	return (
		type == Variant.Type.TYPE_NIL
		or type == Variant.Type.TYPE_STRING
		or var_parsed_text.is_empty()
		or typeof(str_to_var(var_parsed_text)) == type
	)


func _set_reset_button_visibility() -> void:
	_reset_button.visible = _arg != (str(default_arg) if default_arg != null else '')


func _resize_input_to_arg() -> void:
	var font: Font = get_theme_default_font()
	
	var lines: PackedStringArray = []
	if _input.text.is_empty():
		lines = _input.placeholder_text.split("\n")
	else:
		for line_idx: int in _input.get_line_count():
			lines.push_back(_input.get_line(line_idx))
	
	var max_width: int = -1
	for line: String in lines:
		var str_size: int = font.get_string_size(line).x
		if str_size > max_width:
			max_width = str_size
	
	_input.custom_minimum_size.x = max_width + _font_size_margin


func _validate_contents() -> bool:
	var invalid_vars: Array[String] = []  # TODO: Call method that returns vars that could not be parsed (Array[String]).
	if !invalid_vars.is_empty():
		push_error(
			'Argument <%s> with value <%s> in <%s> has invalid variables <%s>!'
			% [arg_name, _input.text, _call_node.title, str(invalid_vars)]
		)
		return false
	if !_validate_text_type():
		push_error(
			'Argument <%s> with value <%s> in <%s> cannot be converted to the needed type <%s>!'
			% [arg_name, _input.text, _call_node.title, type_string(type)]
		)
		return false
	return true


func _on_argument_text_edit_text_changed() -> void:
	_resize_input_to_arg()


func _on_reset_button_pressed() -> void:
	changed_value.emit(self, _arg, var_to_str(default_arg) if default_arg != null else '')


func _on_argument_text_edit_focus_exited() -> void:
	if _input.text == _arg:
		return
	changed_value.emit(self, _arg, _input.text)
