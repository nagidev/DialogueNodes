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
signal disconnection_from_request(from_node: String, from_port: int)
signal connection_shift_request(from_node: String, old_port: int, new_port: int)

var undo_redo: EditorUndoRedoManager

var _calls_script: Script = null
var _calls: Dictionary = {}
var _active_method: Dictionary = {}
var _num_rets: int = 0

var base_color: Color = Color.WHITE

var _arg_scene: PackedScene = preload("res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeArgument.tscn")
var _ret_scene: PackedScene = preload("res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeReturn.tscn")

@onready var _method_button: OptionButton = %MethodSelector
@onready var _args_section_container: Container = %ArgumentsSectionContainer
@onready var _args_container: Container = %ArgumentsContainer

@onready var _ret_button: Button = %AddReturnButton
@onready var _def_ret: Control = %DefaultLabel

@onready var _ret_idx_start: int = _ret_button.get_index()


# -------------------------------------------------------------------------------------------------
# Core
# -------------------------------------------------------------------------------------------------
func _ready() -> void:
	_reload_library(DEFAULT_CALLS)
	_reload_method_ui()
	_reload_args_ui()
	_reload_rets_ui()
	_update_slots()


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := {}
	
	# Export Library
	dict['library'] = _calls_script.resource_path
	
	# Export Method
	dict['method'] = _active_method
	
	# Export Arguments
	var args_arr := []
	for arg: Control in _args_container.get_children():
		args_arr.push_back(arg.get_arg())
	dict['args'] = args_arr
	
	# Export Connected Returns
	var rets_dict := {}
	for connection: Dictionary in graph.get_connections(name):
		var idx: int = connection['from_port'] # this returns index starting from 0
		
		if idx == _num_rets:
			dict['default'] = connection['to_node']
			continue
		
		rets_dict[idx] = {}
		rets_dict[idx]['value'] = get_child(_ret_idx_start + idx).get_ret()
		rets_dict[idx]['link'] = connection['to_node']
	
	# Export Unconnected Returns
	for idx: int in _num_rets:
		if rets_dict.has(idx): continue
		
		rets_dict[idx] = {}
		rets_dict[idx]['value'] = get_child(_ret_idx_start + idx).get_ret()
		rets_dict[idx]['link'] = 'END'
	
	dict['rets'] = rets_dict
	
	# Export Default Return
	if not dict.has('default'): dict['default'] = 'END'
	
	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	# Import Library
	_reload_library(load(dict['library']))
	
	# Import Method
	_reload_method_ui()
	if dict['method'].is_empty():
		_clear_method()
	else:
		_set_method(dict['method'].name)
		for i: int in _method_button.item_count:
			if _method_button.get_item_text(i) == dict['method'].name:
				_method_button.select(i)
				break
	
	# Import Arguments
	var args: Array[Node] = _args_container.get_children()
	for idx: int in dict['args'].size():
		args[idx].set_arg(dict['args'][idx])
	
	# Import Returns
	var next_nodes: Array[String] = []
	for idx: int in dict['rets']:
		var ret: Control = _add_return()
		ret.set_ret(dict['rets'][idx]['value'])
		next_nodes.append(dict['rets'][idx]['link'])
	next_nodes.append(dict['default'])
	
	return next_nodes


func _update_slots() -> void:
	var children: Array[Node] = get_children()
	for i: int in range(_ret_idx_start, _ret_idx_start + _num_rets):
		var ret: Control = children[i]
		set_slot(ret.get_index(), false, 0, base_color, true, 0, base_color)
	set_slot(_ret_button.get_index(), false, 0, base_color, false, 0, base_color)
	set_slot(_def_ret.get_index(), false, 0, base_color, true, 0, base_color)


# -------------------------------------------------------------------------------------------------
# Library
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


# -------------------------------------------------------------------------------------------------
# Method
# -------------------------------------------------------------------------------------------------
func _reload_method_ui() -> void:
	var curr_method_name: String = ''
	if _method_button.selected > -1:
		curr_method_name = _method_button.get_item_text(_method_button.selected)
	
	_method_button.clear()
	_method_button.selected = -1
	_method_button.add_item('', 0)

	var idx: int = 1
	for method: Dictionary in _calls.values():
		_method_button.add_item(method.name, idx)
		if method.name == curr_method_name:
			_method_button.selected = idx
		idx += 1


func _set_method(method_name: String) -> void:
	if !_calls.has(method_name):
		push_error("CallNode's selected method <%s> is not in calls library!" % method_name)
		return
	_active_method = _calls[method_name]
	_reload_args_ui()
	_reload_rets_ui()


func _clear_method() -> void:
	_active_method = {}
	_reload_args_ui()
	_reload_rets_ui()


# -------------------------------------------------------------------------------------------------
# Arguments
# -------------------------------------------------------------------------------------------------
func _reload_args_ui() -> void:
	# If no active method, clear all arguments
	if _active_method.is_empty():
		_clear_arguments()
		_args_section_container.visible = false
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
		_add_argument(arg, "", null if i < non_def_args else _active_method.default_args[i - non_def_args])
	
	# Remove old arguments that do not exist in new method.
	for outdated_arg: Node in _old_args.values():
		outdated_arg.queue_free()

	# Show/Hide Arguments section based on prevailing arguments
	_args_section_container.visible = _args_container.get_child_count() > 0


func _add_argument(arg_data: Dictionary, arg: String = "", default_arg = null) -> Control:
	var new_arg_ui: Control = _arg_scene.instantiate()
	_args_container.add_child(new_arg_ui)
	new_arg_ui.set_call_node(self)
	new_arg_ui.set_data(
		arg_data.name,
		arg_data.type,
		arg,
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
	
	# Shift Return Connections
	for i: int in range(_num_rets - 1, new_ret.get_index() - _ret_idx_start, -1):
		connection_shift_request.emit(name, i - 1, i)
	
	# Shift Default Return Connection
	set_slot(_ret_idx_start + _num_rets + 1, false, 0, base_color, true, 0, base_color)
	connection_shift_request.emit(name, _num_rets - 1, _num_rets)
	
	_update_slots()
	return new_ret


func _remove_return(ret: Control) -> Control:
	# Shift Return Connections
	var ret_idx: int = ret.get_index() - _ret_idx_start
	disconnection_from_request.emit(name, ret_idx)
	for i: int in range(ret_idx, _num_rets - 1):
		connection_shift_request.emit(name, i + 1, i)
	
	# Shift Default Return Connection
	connection_shift_request.emit(name, _num_rets, _num_rets - 1)
	
	if ret.requested_removal.is_connected(_on_return_requested_removal):
		ret.requested_removal.disconnect(_on_return_requested_removal)
	
	if ret.get_parent() != self:
		push_error('Cannot remove Return <%s> from CallNode <%s>. Not a child!' % [ret.name, title])
	else:
		remove_child(ret)
		_num_rets -= 1
	ret.queue_free()
	reset_size()
	
	_update_slots()
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
		_clear_method()
		return

	var method_name: String = _method_button.get_item_text(index)
	if method_name.is_empty():
		_clear_method()
		return

	_set_method(method_name)


func _on_add_return_button_pressed() -> void:
	_add_return()


func _on_return_requested_removal(ret: Control) -> void:
	_remove_return(ret)
