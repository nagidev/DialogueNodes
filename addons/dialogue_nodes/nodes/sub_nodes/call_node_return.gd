@tool
extends Container
##
## Call Node Return
##
## Represents a possible return of a CallNode's method. Used mainly to manage itself and to
## pass interactions to the CallNode that owns it.

signal text_changed(ret: Control, new_text: String)
signal requested_removal(ret: Control)

var type: Variant.Type = Variant.Type.TYPE_NIL

var _call_node: GraphNode = null

@onready var _input: LineEdit = %ReturnInput


func set_call_node(call_node: GraphNode) -> void:
	if call_node != get_parent_control():
		push_error("A CallNodeReturn MUST be a direct child of the CallNode is bound to!")
		return
	_call_node = call_node


func set_type(new_type: Variant.Type) -> void:
	_input.placeholder_text = (
		type_string(new_type) if new_type != Variant.Type.TYPE_NIL else ""
	)
	type = new_type


func _on_return_input_focus_exited() -> void:
	if type == Variant.Type.TYPE_NIL:
		return
	var convert_test = type_convert(_input.text, type)
	if typeof(convert_test) != type:
		push_warning(
			"Return <%s> in CallNode <%s> cannot be converted to type <%s>!"
			% [name, _call_node.title, type_string(type)]
		)


func _on_remove_button_pressed() -> void:
	requested_removal.emit(self)
