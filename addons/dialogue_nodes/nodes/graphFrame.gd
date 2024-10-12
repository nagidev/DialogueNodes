@tool
extends GraphFrame


signal modified

@onready var instruction_label: Label = $InstructionLabel

var undo_redo: EditorUndoRedoManager
var attached_nodes: Array[StringName] = []


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := {}
	dict['attached_nodes'] = attached_nodes
	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	attached_nodes = dict['attached_nodes']
	return []


func _after_loaded(graph: GraphEdit) -> void:
	for node in attached_nodes:
		graph.attach_node_to_frame(node, name)
	instruction_label.visible = attached_nodes.size() == 0


func attach_node(element: StringName) -> void:
	if attached_nodes.has(element): return
	attached_nodes.append(element)
	instruction_label.visible = attached_nodes.size() == 0


func detach_node(element: StringName) -> void:
	attached_nodes.erase(element)
	instruction_label.visible = attached_nodes.size() == 0
