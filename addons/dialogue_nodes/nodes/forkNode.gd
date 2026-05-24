@tool
extends GraphNode
##
## Fork Node
##
## Groups a list of output options, each with a condition. The first condition (top to
## bottom) to be valid is used to exit, with a default option with no conditions always last.


signal modified
signal disconnection_from_request(from_node: String, from_port: int)
signal connection_shift_request(from_node: String, old_port: int, new_port: int)

@onready var fork_title: LineEdit = $ForkTitle
@onready var add_button: Button = $AddButton

const ForkItemScene := preload('res://addons/dialogue_nodes/nodes/sub_nodes/ForkItem.tscn')

var undo_redo: EditorUndoRedoManager
var forks: Array[Control] = []
var base_color: Color = Color.WHITE
var last_variable_list: Array[String]


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := {}
	
	dict['fork_title'] = fork_title.text
	
	# get forks connected to other nodes
	var forks_dict := {}
	for connection in graph.get_connections(name):
		var idx: int = connection['from_port'] # this returns index starting from 0
		
		if idx == forks.size():
			dict['default'] = connection['to_node']
			continue
		
		forks_dict[idx] = {}
		forks_dict[idx]['condition'] = forks[idx].get_condition()
		forks_dict[idx]['link'] = connection['to_node']
	
	# get forks not connected to any nodes
	for idx in range(forks.size()):
		if forks_dict.has(idx): continue
		
		forks_dict[idx] = {}
		forks_dict[idx]['condition'] = forks[idx].get_condition()
		forks_dict[idx]['link'] = 'END'
	if not dict.has('default'): dict['default'] = 'END'
	
	# store fork info in dict
	dict['forks'] = forks_dict
	
	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	# The sequence of links is very important
	var next_nodes: Array[String] = []
	
	fork_title.text = dict['fork_title']
	
	for idx in dict['forks']:
		var new_item := ForkItemScene.instantiate()
		add_item(new_item, idx + 1)
		new_item.set_condition(dict['forks'][idx]['condition'])
		var link: String = dict['forks'][idx]['link']
		next_nodes.append(dict['forks'][idx]['link'])
	next_nodes.append(dict['default'])
	
	return next_nodes


func update_slots() -> void:
	for item in forks:
		set_slot(item.get_index(), false, 0, base_color, true, 0, base_color)
	
	set_slot(add_button.get_index(), false, 0, base_color, false, 0, base_color)
	set_slot(add_button.get_index() + 1, false, 0, base_color, true, 0, base_color)


func add_item(new_item: BoxContainer, to_idx := -1) -> void:
	if new_item.get_parent() != self: add_child(new_item, true)
	move_child(new_item, to_idx)
	
	new_item.undo_redo = undo_redo
	
	new_item.modified.connect(_on_modified)
	new_item.delete_requested.connect(_on_item_deleted.bind(new_item))
	forks.append(new_item)
	
	# sort forks in the array
	forks.sort_custom(func (op1, op2):
		return op1.get_index() < op2.get_index()
		)
	
	# shift slot connections
	var index := forks.find(new_item)
	for i in range(forks.size() - 1, index, -1):
		connection_shift_request.emit(name, i - 1, i)
	
	# shift default slot connection
	var old_default_slot := add_button.get_index()
	set_slot(old_default_slot + 1, false, 0, base_color, true, 0, base_color)
	connection_shift_request.emit(name, forks.size() - 1, forks.size())
	update_slots()
	
	# add variables to dropdown
	new_item.update_variables(last_variable_list)


func remove_item(item: BoxContainer) -> void:
	# shift slot connections
	var index := forks.find(item)
	for i in range(index, forks.size() - 1):
		connection_shift_request.emit(name, i + 1, i)
	
	# shift default slot connection
	var new_default_slot := add_button.get_index()
	call_deferred('set_slot', new_default_slot, false, 0, base_color, true, 0, base_color)
	connection_shift_request.emit(name, forks.size(), forks.size() - 1)
	
	forks.erase(item)
	item.modified.disconnect(_on_modified)
	item.delete_requested.disconnect(_on_item_deleted)
	
	if item.get_parent() == self: remove_child(item)
	update_slots()


func _on_add_button_pressed() -> void:
	var new_item := ForkItemScene.instantiate()
	
	if not undo_redo:
		add_item(new_item, -3)
		return
	
	undo_redo.create_action('Add fork item')
	undo_redo.add_do_method(self, 'add_item', new_item, -3)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_do_reference(new_item)
	undo_redo.add_undo_method(self, 'remove_item', new_item)
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.commit_action()


func _on_item_deleted(item: BoxContainer) -> void:
	if not undo_redo:
		remove_item(item)
		return
	
	var idx := item.get_index()
	disconnection_from_request.emit(name, forks.find(item))
	
	undo_redo.create_action('Remove fork item')
	undo_redo.add_do_method(self, 'remove_item', item)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'add_item', item, idx)
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.commit_action()


func _on_modified() -> void:
	reset_size()
	modified.emit()

	
func _on_variables_updated(variables_list: Array[String]) -> void:
	last_variable_list = variables_list
	for fork in forks:
		fork.update_variables(variables_list)
