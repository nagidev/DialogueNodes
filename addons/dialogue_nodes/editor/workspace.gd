@tool
extends Control


signal node_added(node_name)
signal node_deleted(node_name)

@export var nodeScenes: Array[PackedScene] = [
	preload("res://addons/dialogue_nodes/nodes/StartNode.tscn"),
	preload("res://addons/dialogue_nodes/nodes/DialogueNode.tscn"),
	preload("res://addons/dialogue_nodes/nodes/CommentNode.tscn"),
	preload("res://addons/dialogue_nodes/nodes/SignalNode.tscn"),
	preload("res://addons/dialogue_nodes/nodes/SetNode.tscn"),
	preload("res://addons/dialogue_nodes/nodes/ConditionNode.tscn")
]

@onready var files = $SidePanel/Files
@onready var data = $SidePanel/Data
@onready var graph = $Graph
@onready var popup = $Graph/PopupMenu

var cursor_pos = Vector2.ZERO
var nodes = []
var request_node = null
var request_slot = null
var loading_file : bool = false


func _ready():
	init_nodes()


func show_menu(pos):
	var pop_pos = pos + graph.global_position + Vector2(get_window().position)
	popup.popup(Rect2(pop_pos.x, pop_pos.y, popup.size.x, popup.size.y))
	cursor_pos = (pos + graph.scroll_offset) / graph.zoom


# maybe move the function to editor.gd
func init_nodes():
	# empty and resize the nodes list
	nodes.clear()
	nodes.resize(len(nodeScenes))
	
	# add entries for nodes
	for i in range(len(nodeScenes)):
		var scene = nodeScenes[i]
		var scene_instance = scene.instantiate()
		var scene_name = scene_instance.name
		nodes[i] = {'name': scene_name, 'scene': scene}
		scene_instance.queue_free()


func add_node(id, clone = null, node_name = '', offset = null):
	var new_node
	
	if clone:
		# duplicate node
		id = int(clone.name.split('_')[0])
		clone.selected = false
	else:
		_select_all_nodes(false)
	
	# create new node
	new_node = nodes[id].scene.instantiate()
	
	#new_node.offset = (get_viewport().get_mouse_position() + graph.scroll_offset) / graph.zoom - (new_node.rect_size * 0.5) if offset == null else offset
	new_node.position_offset = cursor_pos - (new_node.size * 0.5) if offset == null else offset
	new_node.selected = true
	
	new_node.dragged.connect(_on_node_dragged)
	new_node.delete_request.connect(remove_node.bind(new_node))
	new_node.modified.connect(graph._on_modified)
	new_node.delete_request.connect(graph._on_modified)
	
	# dialogue node signals
	if new_node.has_signal('connection_move'):
		new_node.connection_move.connect(_move_connection_slot.bind(new_node))
	
	# set nodeId and add to graph
	new_node.name = (str(id)+'_1') if node_name == '' else node_name
	
	graph.add_child(new_node, true)
	new_node.title = nodes[id].name + ' #' + new_node.name.split('_')[1]
	
	# set up values, if clone
	if clone:
		new_node._from_dict(graph, clone._to_dict(graph))
	
	# connect to previous node if required
	if request_node:
		if new_node.is_slot_enabled_left(0):
			# remove any connection from this slot to previous node
			_remove_invalid_connections(request_node, request_slot)
			# make new connection
			graph.connect_node(request_node, request_slot, new_node.name, 0)
		request_node = null
		request_slot = null
	
	if not loading_file:
		files.modify_file()
	node_added.emit(new_node.name)
	
	return new_node


func remove_node(node):
	_remove_all_connections(node.name)
	
	node.queue_free()
	
	node_deleted.emit(node.name)


func remove_all_nodes():
	for child in graph.get_children():
		if child is GraphNode:
			remove_node(child)
			child.name += '_' # workaround


func _remove_invalid_connections(from, from_slot= -1, to= null, to_slot= -1):
	for connection in graph.get_connection_list():
		if connection['from_node'] == from:
			if connection['to_node'] != to and connection['from_port'] == from_slot:
				graph.disconnect_node(
					connection['from_node'], connection['from_port'], connection['to_node'], connection['to_port']
				)


func _remove_all_connections(node):
	for connection in graph.get_connection_list():
		if connection['from_node'] == node or connection['to_node'] == node:
			graph.disconnect_node(connection['from_node'], connection['from_port'], connection['to_node'], connection['to_port'])


func _move_connection_slot(old_slot, new_slot, node):
	for connection in graph.get_connection_list():
		if connection['from_node'] == node.name:
			if connection['from_port'] == new_slot:
				graph.disconnect_node(connection['from_node'], connection['from_port'], connection['to_node'], connection['to_port'])
			elif connection['from_port'] == old_slot:
				graph.disconnect_node(connection['from_node'], connection['from_port'], connection['to_node'], connection['to_port'])
				graph.connect_node(connection['from_node'], new_slot, connection['to_node'], connection['to_port'])


func _on_node_dragged(_from, to):
	cursor_pos = to


func _on_nodes_duplicated():
	for child in graph.get_children():
		if child is GraphNode and child.is_selected():
			cursor_pos = (get_viewport().get_mouse_position() - graph.global_position + graph.scroll_offset) / graph.zoom
			add_node(-1, child)


func _on_nodes_delete(node_names):
	for node_name in node_names:
		remove_node(graph.get_node( NodePath(node_name) ))


func _select_all_nodes(select = true):
	for child in graph.get_children():
		if child is GraphNode:
			child.selected = select


func _on_connection_to_empty(from, from_slot, release_position):
	request_node = from
	request_slot = from_slot
	show_menu(release_position)


func _on_connection_request(from, from_slot, to, to_slot):
	if from != to:
		# remove any connection from this slot to previous node
		_remove_invalid_connections(from, from_slot)
		
		# create new connction
		graph.connect_node(from, from_slot, to, to_slot)


func _on_disconnection_request(from, from_slot, to, to_slot):
	graph.disconnect_node(from, from_slot, to, to_slot)


func _on_file_modified():
	if not loading_file:
		files.modify_file()


func _on_file_closed():
	remove_all_nodes()
	
	if files.get_item_count() == 0:
		graph.hide()
		data.hide()
