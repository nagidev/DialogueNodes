@tool
extends Container
##
## Call Node Return
##
## Represents a possible return of a CallNode's method. Used mainly to manage itself and to
## pass interactions to the CallNode that owns it.

@export_range(0.0, 30.0, 0.1) var _font_size_margin: float = 15.0

signal text_changed(ret: Control, new_text: String)
signal requested_removal(ret: Control)

var type: Variant.Type = Variant.Type.TYPE_NIL

var _call_node: GraphNode = null
var _ret: String = ""

@onready var _input: TextEdit = %ReturnTextEdit


func set_call_node(call_node: GraphNode) -> void:
	if call_node != get_parent_control():
		push_error('A CallNodeReturn MUST be a direct child of the CallNode is bound to!')
		return
	_call_node = call_node


func get_ret() -> String:
	return _ret


func set_ret(new_ret: String) -> void:
	_ret = new_ret
	_input.text = new_ret


func set_type(new_type: Variant.Type) -> void:
	_input.placeholder_text = type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ''
	type = new_type


func _validate_input_type() -> bool:
	return (
		type == Variant.Type.TYPE_NIL
		or type == Variant.Type.TYPE_STRING
		or typeof(str_to_var(_ret)) == type
	)


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


func _on_return_text_edit_text_changed() -> void:
	_ret = _input.text
	_resize_input_to_arg()
	_input.text = _ret


func _on_remove_button_pressed() -> void:
	requested_removal.emit(self)


func _on_return_text_edit_focus_exited() -> void:
	if !_validate_input_type():
		push_error(
			'Return <%s> in CallNode <%s> cannot be converted to the needed type <%s>!'
			% [_ret, _call_node.title, type_string(type)]
		)
	_call_node.reset_size()
