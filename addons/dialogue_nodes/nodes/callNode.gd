@tool
extends GraphNode
##
## Call Node
##
## This Node calls a function from an expandable library of callables to determine which Node
## output to take based on what the method returned.
## The library, a static object called [DialogueCalls], is expected to be expanded by the user.

const DEFAULT_CALLS: Script = preload("res://addons/dialogue_nodes/editor/calls.gd")

signal modified

var undo_redo: EditorUndoRedoManager

var _calls_script: Script = null
var _calls: Dictionary = {}
var _active_method: Dictionary = {}
var _num_rets: int = 0

var _arg_scene: PackedScene = preload("res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeArgument.tscn")
var _ret_scene: PackedScene = preload("res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeReturn.tscn")

@onready var _method_button: OptionButton = %MethodSelector
@onready var _args_section_container: Container = %ArgumentsSectionContainer
@onready var _args_container: Container = %ArgumentsContainer

@onready var _ret_button: Button = %AddReturnButton

@onready var _ret_idx_start: int = _ret_button.get_index()


# -------------------------------------------------------------------------------------------------
# Core
# -------------------------------------------------------------------------------------------------
func _ready() -> void:
	_reload_library(DEFAULT_CALLS)
	_reload_method_ui()
	_reload_args_ui()
	_reload_rets_ui()


func _to_dict(graph: GraphEdit) -> Dictionary:
	return {}


func _from_dict(dict: Dictionary) -> Array[String]:
	return [] as Array[String]


# -------------------------------------------------------------------------------------------------
# Method
# -------------------------------------------------------------------------------------------------
func _reload_library(script: Script) -> bool:
	if script == null:
		push_error("Cannot reload CallNode's library with a NULL script!")
		return false
	
	# Swap signal connections
	if _calls_script != null and _calls_script.script_changed.is_connected(_on_calls_script_changed):
		_calls_script.script_changed.disconnect(_on_calls_script_changed)
	script.script_changed.connect(_on_calls_script_changed, ConnectFlags.CONNECT_DEFERRED)
	
	# Re-write Calls Library with new methods
	_calls.clear()
	for method: Dictionary in script.get_script_method_list():
		_calls[method.name] = method
	
	_calls_script = script
	return true


func _reload_method_ui() -> void:
	var curr_method_name: String = ""
	if _method_button.selected > -1:
		curr_method_name = _method_button.get_item_text(_method_button.selected)
	
	_method_button.clear()
	_method_button.selected = -1
	_method_button.add_item("", 0)

	var idx: int = 1
	for method: Dictionary in _calls.values():
		_method_button.add_item(method.name, idx)
		if method.name == curr_method_name:
			_method_button.selected = idx
		idx += 1


# -------------------------------------------------------------------------------------------------
# Arguments
# -------------------------------------------------------------------------------------------------
func _reload_args_ui() -> void:
	# If no active method, clear all arguments
	if _active_method.is_empty():
		_clear_arguments()
		return
	
	# Remove old arguments (don't destroy them yet)
	var _old_args: Dictionary = {}
	for node: Node in _args_container.get_children():
		_old_args[node.arg_name] = node
		_args_container.remove_child(node)
	
	# Instantiate all new resources, recover data from old ones if duplicated
	var args_size: int = _active_method.args.size()
	var non_def_args: int = args_size - _active_method.default_args.size()
	for i: int in range(0, args_size):
		# If old argument exactly matches new one, re-add it to container and unmark it as "old".
		var arg: Dictionary = _active_method.args[i]
		if (
			_old_args.has(arg.name)
			and arg.type == _old_args[arg.name].type
			and (i < non_def_args or _active_method.default_args[i - non_def_args] == _old_args[arg.name].default_arg)
		):
			_args_container.add_child(_old_args[arg.name])
			_old_args.erase(arg.name)
			continue
		
		# If new argument, instantiate a UI for it and set it up.
		_add_argument(arg, null if i < non_def_args else _active_method.default_args[i - non_def_args])
	
	# Remove old arguments that do not exist in new method.
	for outdated_arg: Node in _old_args.values():
		outdated_arg.queue_free()

	# Show/Hide Arguments section based on prevailing arguments
	_args_section_container.visible = _args_container.get_child_count() > 0


func _add_argument(arg_data: Dictionary, default_arg = null) -> Control:
	var new_arg_ui: Control = _arg_scene.instantiate()
	_args_container.add_child(new_arg_ui)
	new_arg_ui.set_call_node(self)
	new_arg_ui.set_data(
		arg_data.name,
		arg_data.type,
		default_arg
	)
	return new_arg_ui


func _remove_argument(arg: Control) -> Control:
	_args_container.remove_child(arg)
	arg.queue_free()
	reset_size()
	return arg


func _clear_arguments() -> void:
	for arg: Node in _args_container.get_children():
		_remove_argument(arg)


# -------------------------------------------------------------------------------------------------
# Returns
# -------------------------------------------------------------------------------------------------
func _reload_rets_ui() -> void:
	# @Choms-TODO: Add "automatic" bool returns, disallow adding more or less.
	#if !_active_method.is_empty() and _active_method.return.type == Variant.Type.TYPE_BOOL:
		#clear_returns()
		#var true_ret: Control = _add_return()
		#var false_ret: Control = _add_return()
		#return

	# Reset the type hint on all existing returns.
	for idx: int in range(_ret_idx_start, _ret_idx_start + _num_rets):
		var ret: Node = get_child(idx)
		if ret != null:
			ret.set_type(_active_method.return.type if !_active_method.is_empty() else Variant.Type.TYPE_NIL)


func _add_return() -> Control:
	var new_ret: Control = _ret_scene.instantiate()
	add_child(new_ret)
	move_child(new_ret, _ret_button.get_index())
	_num_rets += 1
	
	new_ret.requested_removal.connect(_on_return_requested_removal)
	new_ret.set_type(_active_method.return.type if !_active_method.is_empty() else Variant.Type.TYPE_NIL)
	return new_ret


func _remove_return(ret: Control) -> Control:
	if ret.requested_removal.is_connected(_on_return_requested_removal):
		ret.requested_removal.disconnect(_on_return_requested_removal)
	
	if ret.get_parent() != self:
		push_error("Cannot remove Return <%s> from CallNode <%s>. Not a child!" % [ret.name, title])
	else:
		remove_child(ret)
		_num_rets -= 1
	ret.queue_free()
	reset_size()
	return ret


func clear_returns() -> void:
	for idx: int in range(_ret_idx_start, _ret_idx_start + _num_rets):
		var ret: Node = get_child(idx)
		if ret != null:
			_remove_return(ret)


# -------------------------------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------------------------------
func _on_calls_script_changed() -> void:
	pass
	#_reload_library()
	#_reload_method_ui()
	#_reload_args_ui()


func _on_method_selector_item_selected(index: int) -> void:
	if index == -1:
		_active_method = {}
	else:
		var method_name: String = _method_button.get_item_text(index)
		if method_name.is_empty():
			_active_method = {}
		elif !_calls.has(method_name):
			push_error("CallNode's selected method <%s> is not in calls library!" % method_name)
		else:
			_active_method = _calls[method_name]
	_reload_args_ui()
	_reload_rets_ui()


func _on_add_return_button_pressed() -> void:
	_add_return()


func _on_return_requested_removal(ret: Control) -> void:
	_remove_return(ret)
