tool
extends HSplitContainer
# TODO : redo duplication code

signal node_added(node_name)
signal node_deleted(node_name)

export (Array, String, FILE, "*.tscn, *.scn") var nodeScenes

onready var graph = $Graph
onready var popup = $Graph/PopupMenu

var cursor_pos = Vector2.ZERO
var nodes = []


func _ready():
	init_nodes()


func show_menu(pos):
	popup.popup(Rect2(pos.x, pos.y, popup.rect_size.x, popup.rect_size.y))
	cursor_pos = pos + graph.scroll_offset


## Nodes 
# maybe move the function to editor.gd
func init_nodes():
	# empty and resize the nodes list
	nodes.clear()
	nodes.resize(len(nodeScenes))
	
	# add entries for nodes
	for i in range(len(nodeScenes)):
		var scene = load(nodeScenes[i])
		var scene_name = scene.instance().name
		nodes[i] = {"name": scene_name, "scene": scene}


func add_node(id, clone = null, node_id = '', offset = null):
	var new_node
	
	if clone:
		# duplicate node
		new_node = clone.duplicate()
		clone.selected = false
		id = int(clone.name.split('_')[0])
	else:
		# create new node
		new_node = nodes[id].scene.instance()
		_select_all_nodes(false)
	
	new_node.offset = (get_viewport().get_mouse_position() + graph.scroll_offset) / graph.zoom - (new_node.rect_size * 0.5) if offset == null else offset
	new_node.selected = true
	
	new_node.connect("dragged", self, "_on_node_dragged")
	new_node.connect("close_request", self, "remove_node", [new_node])
	
	# dialogue node signals
	if new_node.has_signal("connection_move"):
		new_node.connect("connection_move", self, "_move_connection_slot", [new_node])
	
	# set nodeId and add to graph
	new_node.name = (str(id)+'_1') if node_id == '' else node_id
	
	graph.add_child(new_node, true)
	new_node.title = nodes[id].name + ' #' + new_node.name.split('_')[1]
	
	emit_signal("node_added", new_node.name)


func remove_node(node):
	
	_remove_all_connections(node.name)
	
	node.queue_free()
	
	emit_signal("node_deleted", node.name)


func _remove_invalid_connections(from, from_slot= -1, to= null, to_slot= -1):
	for connection in graph.get_connection_list():
		if connection['from'] == from:
			if connection['to'] != to and connection['from_port'] == from_slot:
				graph.disconnect_node(
					connection['from'], connection['from_port'], connection['to'], connection['to_port']
				)


func _remove_all_connections(node):
	for connection in graph.get_connection_list():
		if connection['from'] == node or connection['to'] == node:
			graph.disconnect_node(connection['from'], connection['from_port'], connection['to'], connection['to_port'])


func _move_connection_slot(old_slot, new_slot, node):
	for connection in graph.get_connection_list():
		if connection['from'] == node.name:
			if connection['from_port'] == new_slot:
				graph.disconnect_node(connection['from'], connection['from_port'], connection['to'], connection['to_port'])
			elif connection['from_port'] == old_slot:
				graph.disconnect_node(connection['from'], connection['from_port'], connection['to'], connection['to_port'])
				graph.connect_node(connection['from'], new_slot, connection['to'], connection['to_port'])


func _on_node_dragged(_from, to):
	cursor_pos = to


func _on_nodes_duplicated():
	for child in graph.get_children():
		if child is GraphNode and child.is_selected():
			add_node(-1, child)


func _on_nodes_delete():
	for child in graph.get_children():
		if child is GraphNode and child.is_selected():
			remove_node(child)


func _select_all_nodes(select = true):
	for child in graph.get_children():
		if child is GraphNode:
			child.selected = select


func _on_connection_to_empty(from, from_slot, release_position):
	show_menu(release_position)
	# TODO : attach new node to this one


func _on_connection_request(from, from_slot, to, to_slot):
	if from != to:
		# remove any connection from this slot to previous node
		_remove_invalid_connections(from, from_slot)
		
		# create new connction
		graph.connect_node(from, from_slot, to, to_slot)


func _on_disconnection_request(from, from_slot, to, to_slot):
	graph.disconnect_node(from, from_slot, to, to_slot)

