@tool
extends Container
##
## Call Node Return
##
## Represents a possible return of a CallNode's method. Used mainly to manage itself and to
## pass interactions to the CallNode that owns it.

signal text_changed(ret: Control, new_text: String)
signal requested_removal(ret: Control)

@export var _line_edit_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/LineEdit.svg')
@export var _text_edit_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/TextEdit.svg')

var type: Variant.Type = Variant.Type.TYPE_NIL

var _call_node: GraphNode = null
var _ret: String = ""

@onready var _line_edit: LineEdit = %ReturnLineEdit
@onready var _text_edit: TextEdit = %ReturnTextEdit

@onready var _swap_edit_button: Button = %SwapEditButton


func set_call_node(call_node: GraphNode) -> void:
	if call_node != get_parent_control():
		push_error('A CallNodeReturn MUST be a direct child of the CallNode is bound to!')
		return
	_call_node = call_node


func get_ret() -> String:
	return _ret


func set_ret(new_ret: String) -> void:
	_ret = new_ret
	_line_edit.text = new_ret
	_text_edit.text = new_ret


func set_type(new_type: Variant.Type) -> void:
	var placeholder: String = type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ''
	_line_edit.placeholder_text = placeholder
	_text_edit.placeholder_text = placeholder

	type = new_type


func _validate_input_type() -> bool:
	return (
		type == Variant.Type.TYPE_NIL
		or type == Variant.Type.TYPE_STRING
		or typeof(str_to_var(_ret)) == type
	)


func _on_return_line_edit_text_changed(new_text: String) -> void:
	_ret = new_text
	if !_line_edit.visible:
		return
	_text_edit.text = _ret


func _on_return_text_edit_text_changed() -> void:
	_ret = _text_edit.text
	if !_text_edit.visible:
		return
	_line_edit.text = _ret


func _on_swap_edit_button_pressed() -> void:
	_line_edit.visible = !_line_edit.visible
	_text_edit.visible = !_text_edit.visible

	_swap_edit_button.icon = _line_edit_icon if _line_edit.visible else _text_edit_icon
	_call_node.reset_size()


func _on_remove_button_pressed() -> void:
	requested_removal.emit(self)


func _on_return_input_focus_exited() -> void:
	if !_validate_input_type():
		push_error(
			'Return <%s> in CallNode <%s> cannot be converted to the needed type <%s>!'
			% [_ret, _call_node.title, type_string(type)]
		)
	_call_node.reset_size()
