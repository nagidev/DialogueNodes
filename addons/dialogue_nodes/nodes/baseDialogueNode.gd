@abstract
@tool
extends GraphNode
class_name BaseDialogueNode
## To create a custom node:
## 1. Create new scene inheriting from this class.
## 2. Add that scene to popup menu in Graph.tscn.
## 3. Add new function to DialogueParser.gd. I tried to refactor the code such that that logic could be defined in these classes, but they need access to too much data/methods local to parser.
## 4. Add reference to new function inside DialogueParser._proceed. If you search for the comment that reads "ADD NEW FUNCTIONS HERE", you'll find it.

signal modified()
signal disconnection_from_request(from_node: String, from_port: int)
signal connection_shift_request(from_node: String, old_port: int, new_port: int)

var undo_redo: EditorUndoRedoManager

@abstract func _from_dict(dict: Dictionary) -> Array[String]
@abstract func _to_dict(graph: GraphEdit) -> Dictionary
## If node needs access to variable list, define this function in its script.
#func _on_variables_updated(variables_list: Array[String]) -> void: pass
## If node needs access to character list, define this function in its script.
#func _on_characters_updated(character_list: Array[Character]) -> void: pass


func _on_modified() -> void:
	modified.emit()
