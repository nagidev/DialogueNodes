@tool
extends GraphNode
##
## Call Node
##
## This Node calls a method from a [Script] with the given parameters and matching the returned
## value to a list of given values, exiting the Node through the first matching value found.
## A default Script [code]calls.gd[/code] exists,
## but it is expected from the user to customize it or create more scripts to refer to.
## [br][br]
## While in-game, CallNode's will search [code]root[/code]'s children,
## looking for a [Node] (an Autoload, most likely) that holds an instance of its assigned [Script].
## If none is found, a [Script] instance is loaded instead,
## although in the second case only [color=Indian_Red][i]static[/i][/color] methods can be used.
## [br][br]
## [color=Yellow]Warning[/color]: All [i]Arguments[/i] and [i]Returns[/i] must be formatted
## so they can be converted to their appropriate types via [method @GlobalScope.str_to_var].
## [br][br]
## [color=Yellow]Warning[/color]: If more than one child of [code]root[/code] has an instance
## of the same [Script], only the first one will ever be used by CallNodes!
## I.e., if [i]Autoloads[/i] share scripts, only the first one loaded will be used by CallNodes.

# NOTE: The current implementation does not allow for multiple Autoloads using the same Script.
# I considered it a very niche use-case, so I ignored it, specially since there's seemingly
# no easy way to read Godot's Autoload list to place on a [OptionButton] listing them.
# However, it could still be integrated, but there would be no easy way to warn of potential bugs.

const DEFAULT_CALLS: String = 'res://addons/dialogue_nodes/editor/calls.gd'

const HIDDEN_ICON: Texture2D = preload("res://addons/dialogue_nodes/icons/GuiVisibilityHidden.svg")
const VISIBLE_ICON: Texture2D = preload("res://addons/dialogue_nodes/icons/GuiVisibilityVisible.svg")

signal modified
signal disconnection_from_request(from_node: String, from_port: int)
signal connection_shift_request(from_node: String, old_port: int, new_port: int)

var undo_redo: EditorUndoRedoManager

var base_color: Color = Color.WHITE

var _loaded_file: String = DEFAULT_CALLS
var _calls: Dictionary = {}
var _active_method: Dictionary = {}
var _num_rets: int = 0

var _arg_scene: PackedScene = preload('res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeArgument.tscn')
var _ret_scene: PackedScene = preload('res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeReturn.tscn')

@onready var _method_library_container: Container = %MethodLibraryContainer
@onready var _method_library_button: Button = %MethodLibraryButton

@onready var _file_path: LineEdit = %FilePath
@onready var _file_dialog: FileDialog = %FileDialog
@onready var _reimport_button: Button = %ReimportButton

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
	_set_library(DEFAULT_CALLS)
	
	_reload_args_ui()
	_reload_rets_ui()
	_update_slots()


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := {}
	
	# Export Library
	dict['library'] = _loaded_file
	
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
	_set_library(dict['library'])
	
	# Import Method
	_reload_method_ui()
	if dict['method'].is_empty():
		_set_method("")
	else:
		if _set_method(dict['method'].name) == true:
			for i: int in _method_button.item_count:
				if _method_button.get_item_text(i) == dict['method'].name:
					_method_button.select(i)
					break
		else:
			_method_button.select(-1)
	
	# Import Arguments
	if !_active_method.is_empty():
		var args: Array[Node] = _args_container.get_children()
		if args.size() != dict['args'].size():
			push_error(
				"Number of Args of CallNode's <%s> Save and loaded Method <%s> do not match <%d != %d>!"
				% [title, _active_method.name, args.size(), dict['args'].size()]
			)
		else:
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
func _set_library(path: String) -> bool:
	_file_path.text = path
	_calls.clear()
	
	if not ResourceLoader.exists(path, "Script"):
		push_error("Cannot set <%s> as Method Library to <%s>. File path is invalid!" % [path, title])
		_loaded_file = ''
		_reimport_button.visible = false
		_set_method('')
		_reload_method_ui()
		_reload_args_ui()
		return false
	
	_loaded_file = path
	var script: Script = ResourceLoader.load(path, "Script")
	
	# Re-write Calls Library with new methods
	for method: Dictionary in script.get_script_method_list():
		_calls[method.name] = method
	_reimport_button.visible = true
	
	_reload_method_ui()
	_reload_args_ui()
	return true


func _is_script_equal(script_file: String) -> bool:
	var script: Script = ResourceLoader.load(_loaded_file, "Script")
	for method: Dictionary in script.get_script_method_list():
		if (
			not _calls.has(method.name)
			or _calls[method.name].args != method.args
			or _calls[method.name].default_args != method.default_args
			or _calls[method.name].default_args != method.default_args
			or _calls[method.name].return != method.return
		):
			return false
	return true


func _request_library_change(new_path: String) -> void:
	if _loaded_file == new_path:
		return
	
	if not undo_redo:
		_set_library(new_path)
		return
	
	undo_redo.create_action('CallNode Method Script Changed')
	undo_redo.add_do_method(self, '_set_library', new_path)
	undo_redo.add_do_method(self, '_on_modified')
	
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_set_library', _loaded_file)
	undo_redo.add_undo_method(_method_button, 'select', _active_method.index if !_active_method.is_empty() else 0)
	undo_redo.add_undo_method(self, '_set_method', _active_method.name if !_active_method.is_empty() else '')
	for arg: Node in _args_container.get_children():
		undo_redo.add_undo_method(self, '_set_argument', arg.arg_name, arg.get_arg())
	
	undo_redo.commit_action()


# -------------------------------------------------------------------------------------------------
# Method
# -------------------------------------------------------------------------------------------------
func _reload_method_ui() -> void:
	var curr_method_name: String = ''
	if _method_button.selected > -1:
		curr_method_name = _method_button.get_item_text(_method_button.selected)
	
	_method_button.clear()
	_method_button.add_item('', 0)
	_method_button.select(0)
	
	var idx: int = 1
	for method: Dictionary in _calls.values():
		method.index = idx
		_method_button.add_item(method.name, idx)
		if method.name == curr_method_name:
			_method_button.select(idx)
		idx += 1


func _set_method(method_name: String) -> bool:
	if method_name.is_empty():
		_active_method = {}
	else:
		if !_calls.has(method_name):
			push_error("CallNode's selected method <%s> is not in calls library!" % method_name)
			return false
		_active_method = _calls[method_name]
	
	_reload_args_ui()
	_reload_rets_ui()
	reset_size()
	return true


func _toggle_library_ui(toggled_on: bool) -> void:
	_method_library_container.visible = toggled_on
	_method_library_button.icon = VISIBLE_ICON if toggled_on else HIDDEN_ICON
	reset_size()


# -------------------------------------------------------------------------------------------------
# Arguments
# -------------------------------------------------------------------------------------------------
func _get_argument(arg_name: String) -> Control:
	for arg: Node in _args_container.get_children():
		if arg.arg_name == arg_name:
			return arg as Control
	return null


func _set_argument(arg_name: String, arg_value: String) -> bool:
	var arg: Node = _get_argument(arg_name)
	if arg != null:
		arg.set_arg(arg_value)
	return arg != null


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
		_add_argument(arg, '', null if i < non_def_args else _active_method.default_args[i - non_def_args])
	
	# Remove old arguments that do not exist in new method.
	for outdated_arg: Node in _old_args.values():
		outdated_arg.queue_free()
	
	# Show/Hide Arguments section based on prevailing arguments
	_args_section_container.visible = _args_container.get_child_count() > 0


func _add_argument(arg_data: Dictionary, arg: String = '', default_arg = null) -> Control:
	var new_arg_ui: Control = _arg_scene.instantiate()
	_args_container.add_child(new_arg_ui)
	new_arg_ui.changed_value.connect(_on_changed_argument)
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
	# Reset the type hint on all existing returns.
	for idx: int in range(_ret_idx_start, _ret_idx_start + _num_rets):
		var ret: Node = get_child(idx)
		if ret != null:
			ret.set_type(_active_method.return.type if !_active_method.is_empty() else Variant.Type.TYPE_NIL)


func _get_return(idx: int) -> Control:
	if idx < 0 or idx >= _num_rets:
		return null
	return get_child(_ret_idx_start + idx) as Control


func _set_return(idx: int, ret_value: String) -> bool:
	var ret: Control = _get_return(idx)
	if ret != null:
		ret.set_ret(ret_value)
	return ret != null


func _add_return(idx: int = _num_rets) -> Control:
	var new_ret: Control = _ret_scene.instantiate()
	add_child(new_ret)
	move_child(new_ret, _ret_idx_start + idx)
	_num_rets += 1
	
	new_ret.changed_value.connect(_on_changed_return)
	new_ret.requested_removal.connect(_on_return_requested_removal)
	new_ret.set_call_node(self)
	new_ret.set_type(_active_method.return.type if !_active_method.is_empty() else Variant.Type.TYPE_NIL)
	
	# Shift Default Return Connection
	connection_shift_request.emit(name, _num_rets - 1, _num_rets)
	
	# Shift Return Connections
	for i: int in range(_num_rets - 1, new_ret.get_index() - _ret_idx_start, -1):
		connection_shift_request.emit(name, i - 1, i)
	
	_update_slots()
	
	return new_ret


func _remove_return(ret: Control) -> Control:
	# Shift Return Connections
	var ret_idx: int = ret.get_index() - _ret_idx_start
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


func _remove_return_at(idx: int) -> void:
	var ret: Node = _get_return(idx)
	if ret != null:
		_remove_return.call_deferred(ret)  # Needed deferred or Undo/Redo goes crazy.


func clear_returns() -> void:
	for idx: int in range(_ret_idx_start, _ret_idx_start + _num_rets):
		var ret: Node = get_child(idx)
		if ret != null:
			_remove_return(ret)


# -------------------------------------------------------------------------------------------------
# Signals: Method Library
# -------------------------------------------------------------------------------------------------
func _on_method_library_button_toggled(toggled_on: bool) -> void:
	if not undo_redo:
		_toggle_library_ui(toggled_on)
		return
	
	undo_redo.create_action('Set Method Visbility in <%s>' % title)
	undo_redo.add_do_method(self, '_toggle_library_ui', toggled_on)
	undo_redo.add_undo_method(self, '_toggle_library_ui', !toggled_on)
	undo_redo.commit_action()


func _on_browse_button_pressed() -> void:
	_file_dialog.popup_centered()


func _on_file_dialog_file_selected(path: String) -> void:
	_request_library_change(path)


func _on_file_path_text_submitted(new_text: String):
	_request_library_change(new_text)


func _on_file_path_focus_exited() -> void:
	_request_library_change(_file_path.text)


# NOTE: It would be ideal if this could be done automatically when the file is edited.
# Maybe an Editor-wide "save" signal or EditorPlugin <resource_saved> signal could help.
func _on_reimport_button_pressed() -> void:
	if not _loaded_file.is_empty() and not _is_script_equal(_loaded_file):
		print_debug("Reimported Method Library <%s> in <%s>." % [_loaded_file, title])
		_set_library(_loaded_file)


# -------------------------------------------------------------------------------------------------
# Signals: Method
# -------------------------------------------------------------------------------------------------
func _on_method_selector_item_selected(index: int) -> void:
	if index == -1:
		return
	
	# If active method was reselected, do nothing.
	var method_name: String = _method_button.get_item_text(index)
	if _active_method.is_empty():
		if method_name.is_empty():
			return
	elif _active_method.name == _method_button.get_item_text(index):
		return
	
	# Else, Select new Method.
	undo_redo.create_action('Selected Method <%s>' % method_name if !method_name.is_empty() else 'Cleared Method')
	undo_redo.add_do_method(_method_button, 'select', index)
	undo_redo.add_do_method(self, '_set_method', method_name)
	undo_redo.add_undo_method(_method_button, 'select', _active_method.index if !_active_method.is_empty() else 0)
	undo_redo.add_undo_method(self, '_set_method', _active_method.name if !_active_method.is_empty() else '')

	if !_active_method.is_empty():
		for arg_data: Dictionary in _active_method.args:
			undo_redo.add_undo_method(self, '_set_argument', arg_data.name, _get_argument(arg_data.name).get_arg())

	undo_redo.commit_action()


# -------------------------------------------------------------------------------------------------
# Signals: Arguments
# -------------------------------------------------------------------------------------------------
func _on_changed_argument(arg: Control, old: String, new: String) -> void:
	if not undo_redo:
		_set_argument(arg.arg_name, new)
		return
	
	undo_redo.create_action('Edited Argument <%s> in <%s>' % [arg.arg_name, title])
	undo_redo.add_do_method(self, '_set_argument', arg.arg_name, new)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_set_argument', arg.arg_name, old)
	undo_redo.commit_action()


# -------------------------------------------------------------------------------------------------
# Signals: Returns
# -------------------------------------------------------------------------------------------------
func _on_add_return_button_pressed() -> void:
	if not undo_redo:
		_add_return(_num_rets)
		return
	
	undo_redo.create_action('Added Return on <%s>' % title)
	undo_redo.add_do_method(self, '_add_return', _num_rets)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_remove_return_at', _num_rets)
	undo_redo.commit_action()


func _on_return_requested_removal(ret: Control) -> void:
	var relative_idx: int = ret.get_index() - _ret_idx_start
	disconnection_from_request.emit(name, relative_idx)
	
	if not undo_redo:
		_remove_return_at(relative_idx)
		return
	
	undo_redo.create_action('Remove Return on <%s>' % title)
	undo_redo.add_do_method(self, '_remove_return_at', relative_idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_add_return', relative_idx)
	undo_redo.add_undo_method(self, '_set_return', relative_idx, ret.get_ret())
	undo_redo.commit_action()


func _on_changed_return(ret: Control, old: String, new: String) -> void:
	var ret_idx: int = ret.get_index() - _ret_idx_start
	
	if not undo_redo:
		_set_return(ret_idx, new)
		return
	
	undo_redo.create_action('Edited Return <%s> in <%s>' % [ret_idx, title])
	undo_redo.add_do_method(self, '_set_return', ret_idx, new)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_set_return', ret_idx, old)
	undo_redo.commit_action()


func _on_modified() -> void:
	modified.emit()
