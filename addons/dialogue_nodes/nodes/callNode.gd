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

var _arg_scene: PackedScene = preload("res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeArgument.tscn")
var _return_scene: PackedScene = preload("res://addons/dialogue_nodes/nodes/sub_nodes/CallNodeReturn.tscn")

@onready var _method_button: OptionButton = %MethodSelector
@onready var _args_container: Container = %ArgumentsContainer


func _ready() -> void:
	_reload_library(DEFAULT_CALLS)
	_reload_method_ui()
	_reload_args_ui()


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


func _reload_args_ui() -> void:
	if _active_method.is_empty():
		for child: Node in _args_container.get_children():
			child.queue_free()
			_args_container.remove_child(child)
		return
	
	var _old_args: Dictionary = {}
	for node in _args_container.get_children():
		_old_args[node.arg_name] = node
	
	var args_size: int = _active_method.args.size()
	var non_def_args: int = args_size - _active_method.default_args.size()
	for i: int in range(0, args_size):
		var arg: Dictionary = _active_method.args[i]
		if (
			_old_args.has(arg.name)
			and arg.type == _old_args[arg.name].type
			and (i < non_def_args or _active_method.default_args[i - non_def_args] == _old_args[arg.name].default_arg)
		):
			_old_args.erase(arg.name)
			continue
		
		var new_arg_slot: Control = _arg_scene.instantiate()
		_args_container.add_child(new_arg_slot)
		new_arg_slot.set_data(
			arg.name,
			arg.type,
			null if i < non_def_args else _active_method.default_args[i - non_def_args]
		)
	
	for outdated_arg: Node in _old_args.values():
		_args_container.remove_child(outdated_arg)
		outdated_arg.queue_free()


func _to_dict(graph: GraphEdit) -> Dictionary:
	return {}


func _from_dict(dict: Dictionary) -> Array[String]:
	return [] as Array[String]


func _on_calls_script_changed() -> void:
	pass
	#_reload_library()
	#_reload_method_ui()
	#_reload_args_ui()


func _on_method_selector_item_selected(index: int):
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
