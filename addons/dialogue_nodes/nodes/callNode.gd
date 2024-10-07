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

@onready var _method_button: OptionButton = %MethodSelection


func _ready() -> void:
	_reload_library(DEFAULT_CALLS)


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
	
	# Update Method Button UI
	var curr_method_name: String = ""
	if _method_button.selected > -1:
		curr_method_name = _method_button.get_item_text(_method_button.selected)
	
	_method_button.clear()
	var idx: int = 0
	for method: Dictionary in _calls.values():
		_method_button.add_item(method.name, idx)
		if method.name == curr_method_name:
			_method_button.selected = idx
		idx += 1
	
	_calls_script = script
	return true


func _to_dict(graph: GraphEdit) -> Dictionary:
	return {}


func _from_dict(dict: Dictionary) -> Array[String]:
	return [] as Array[String]


func _on_calls_script_changed() -> void:
	pass
	#_reload_library()
