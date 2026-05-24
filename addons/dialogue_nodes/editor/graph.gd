@tool
extends GraphEdit


signal modified
signal characters_updated(character_list: Array[Character])
signal variables_updated(variable_list: Array[String])
signal run_requested(start_node_idx: int)

@export var NodeScenes: Array[PackedScene] = [
	preload('res://addons/dialogue_nodes/nodes/StartNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/DialogueNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/CommentNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/SignalNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/SetNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/ConditionNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/NestNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/ForkNode.tscn'),
	preload('res://addons/dialogue_nodes/nodes/GraphFrame.tscn')
]
@export var detach_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/ExternalLink.svg')

@onready var popup_menu := $PopupMenu

const _duplicate_offset := Vector2(20, 20)

var undo_redo: EditorUndoRedoManager
var starts: Array[String] = []
var cursor_pos := Vector2.ZERO
var selected_nodes := []
var request_node := ''
var request_port := -1
var last_character_list: Array[Character] = []
var last_variable_list: Array[String] = []

var editor_settings: EditorSettings
var base_color: Color

func _ready() -> void:
	init_add_menu(popup_menu)
	
	if not Engine.is_editor_hint(): return
	editor_settings = EditorInterface.get_editor_settings()
	editor_settings.settings_changed.connect(update_slots_color)


func _input(_event) -> void:
	if (not popup_menu.visible) and request_port > -1:
		request_node = ''
		request_port = -1


func get_data() -> DialogueData:
	var data := DialogueData.new()
	
	# get start nodes and their trees
	for start in starts:
		var start_node := get_node(NodePath(start))
		data = start_node.tree_to_data(self, data)
	
	# get stray nodes
	data.strays.clear()
	for node in get_children():
		if node is GraphElement and not data.nodes.has(node.name):
			data.strays.append(node.name)
			data.nodes[node.name] = node._to_dict(self)
			data.nodes[node.name]['offset'] = node.position_offset
	
	return data


func load_data(data: DialogueData) -> void:
	# clear graph
	clear_connections()
	for node in get_children():
		if node is GraphElement:
			node.queue_free()
	request_node = ''
	request_port = -1
	
	# add start nodes and their trees
	for node_name in data.starts.values():
		var offset: Vector2 = data.nodes[node_name]['offset']
		var start_node: GraphNode = add_node(0, node_name, offset)
		start_node.data_to_tree(self, data)
		request_node = ''
		request_port = -1
	
	# add strays
	var _start_node = get_node(starts[0])
	for node_name in data.strays:
		_start_node.data_to_tree(self, data, node_name)
	request_node = ''
	request_port = -1
	
	update_slots_color()
	
	# call after loading hooks for nodes
	for node in get_children():
		if node.has_method('_after_loaded'):
			node._after_loaded(self)


func init_add_menu(add_menu: PopupMenu) -> void:
	# clear if already existing items
	add_menu.clear()
	
	# add entries for nodes in the nodes list
	for i in range(NodeScenes.size()):
		var scene_instance := NodeScenes[i].instantiate()
		var scene_name := scene_instance.name
		scene_instance.queue_free()
		add_menu.add_item(scene_name, i)


func add_node(id: int, node_name := '', offset := cursor_pos) -> GraphElement:
	deselect_all_nodes()
	
	# create new node
	var new_node := NodeScenes[id].instantiate()
	new_node.position_offset = offset
	new_node.undo_redo = undo_redo
	new_node.selected = true
	selected_nodes.append(new_node)
	
	# set nodeId and add to graph
	new_node.name = (str(id)+'_1') if node_name == '' else node_name
	add_child(new_node, true)
	new_node.title += ' #' + new_node.name.split('_')[1]
	
	# connect signals
	connect_node_signals(new_node)
	
	# connect to node if requested
	if request_port > -1 and new_node.is_slot_enabled_left(0):
		var prev_connection := get_connections(request_node, request_port)
		if prev_connection.size() > 0:
			disconnect_node(request_node, request_port, prev_connection[0]['to_node'], prev_connection[0]['to_port'])
		connect_node(request_node, request_port, new_node.name, 0)
	
	match id:
		0: # start node
			add_to_starts(new_node.name)
			new_node.set_ID('START' + new_node.name.split('_')[1])
		1: # dialogue node
			new_node._on_characters_updated(last_character_list)
			new_node._on_variables_updated(last_variable_list)
		4: # set node
			new_node._on_variables_updated(last_variable_list)
		5: # conditional node
			new_node._on_variables_updated(last_variable_list)
		7: # fork node
			new_node._on_variables_updated(last_variable_list)

	
	return new_node


func connect_node_signals(node: GraphElement) -> void:
	var id := int(node.name.split('_')[0])
	
	node.dragged.connect(_on_node_dragged.bind(node))
	node.modified.connect(_on_modified)
	
	match id:
		0: # start node
			node.run_requested.connect(_on_run_requested.bind(node))
		1: # dialogue node
			characters_updated.connect(node._on_characters_updated)
			node.disconnection_from_request.connect(_on_disconnection_from_request)
			node.connection_shift_request.connect(_on_connection_shift_request)
			variables_updated.connect(node._on_variables_updated)
		4: # set node
			variables_updated.connect(node._on_variables_updated)
		5: # conditional node
			variables_updated.connect(node._on_variables_updated)
		7: # fork node
			node.disconnection_from_request.connect(_on_disconnection_from_request)
			node.connection_shift_request.connect(_on_connection_shift_request)
			variables_updated.connect(node._on_variables_updated)



func disconnect_node_signals(node: GraphElement) -> void:
	var id := int(node.name.split('_')[0])
	
	node.dragged.disconnect(_on_node_dragged.bind(node))
	node.modified.disconnect(_on_modified)
	
	match id:
		0: # start node
			node.run_requested.disconnect(_on_run_requested.bind(node))
		1: # dialogue node
			characters_updated.disconnect(node._on_characters_updated)
			node.disconnection_from_request.disconnect(_on_disconnection_from_request)
			node.connection_shift_request.disconnect(_on_connection_shift_request)
			variables_updated.disconnect(node._on_variables_updated)
		4: # set node
			variables_updated.disconnect(node._on_variables_updated)
		5: # conditional node
			variables_updated.disconnect(node._on_variables_updated)
		7: # fork node
			node.disconnection_from_request.disconnect(_on_disconnection_from_request)
			node.connection_shift_request.disconnect(_on_connection_shift_request)
			variables_updated.disconnect(node._on_variables_updated)


func show_add_menu(pos: Vector2) -> void:
	var pop_pos := pos + global_position + Vector2(get_window().position)
	popup_menu.popup(Rect2(pop_pos.x, pop_pos.y, popup_menu.size.x, popup_menu.size.y))
	cursor_pos = (pos + scroll_offset) / zoom


func deselect_all_nodes() -> void:
	for node in selected_nodes:
		node.selected = false
	selected_nodes.clear()


func get_connections(from_node: String, from_port := -1) -> Array:
	var found_connections := []
	for connection in get_connection_list():
		if connection['from_node'] == from_node:
			if from_port > -1:
				if connection['from_port'] == from_port:
					found_connections.append(connection)
			else:
				found_connections.append(connection)
	return found_connections


func add_to_starts(node_name: String) -> void:
	if not starts.has(node_name):
		starts.append(node_name)


func remove_from_starts(node_name: String) -> void:
	starts.erase(node_name)


func attach_node_to_frame(element: StringName, frame: StringName) -> void:
	attach_graph_element_to_frame(element, frame)
	
	var frame_node: GraphFrame = get_node(NodePath(frame))
	frame_node.attach_node(element)
	
	var node: GraphElement = get_node(NodePath(element))
	if not is_instance_valid(node): return
	elif node.get_titlebar_hbox().has_node('DetachButton'): return
	var detach_button := Button.new()
	detach_button.icon = detach_icon
	detach_button.name = 'DetachButton'
	detach_button.flat = true
	node.get_titlebar_hbox().add_child(detach_button, true)
	detach_button.pressed.connect(
		_on_graph_elements_unlinked_to_frame_request.bind(element, frame)
	)


func detach_node_from_frame(element: StringName, frame: StringName) -> void:
	detach_graph_element_from_frame(element)
	
	var frame_node: GraphFrame = get_node(NodePath(frame))
	if not frame_node.attached_nodes.has(element): return
	frame_node.detach_node(element)
	
	var node: GraphElement = get_node(NodePath(element))
	if not is_instance_valid(node): return
	var detach_button: Button = node.get_titlebar_hbox().get_node('DetachButton')
	detach_button.pressed.disconnect(_on_graph_elements_unlinked_to_frame_request)
	detach_button.queue_free()


func update_slots_color(nodes: Array = get_children()) -> void:
	if not editor_settings: return
	
	const light_color := Color.WHITE
	const dark_color := Color.BLACK
	base_color = editor_settings.get_setting('interface/theme/base_color')
	base_color = light_color if base_color.v < 0.5 else dark_color
	
	for node in nodes:
		if not node is GraphNode: continue
		
		for i in range(node.get_child_count()):
			var enabled_left: bool = node.is_slot_enabled_left(i)
			var enabled_right: bool = node.is_slot_enabled_right(i)
			var color_left: Color = node.get_slot_color_left(i)
			if color_left.is_equal_approx(light_color) or color_left.is_equal_approx(dark_color): color_left = base_color
			var color_right: Color = node.get_slot_color_right(i)
			if color_right.is_equal_approx(light_color) or color_right.is_equal_approx(dark_color): color_right = base_color
			node.set_slot(i, enabled_left, 0, color_left, enabled_right, 0, color_right)
		
		if 'base_color' in node: node.base_color = base_color


func _on_add_menu_pressed(id: int) -> void:
	if not undo_redo:
		add_node(id)
		return
	
	_on_modified()
	
	var prev_connection := get_connections(request_node, request_port)
	var new_node: GraphElement = add_node(id)
	
	undo_redo.create_action('Add graph node')
	undo_redo.add_do_method(self, 'add_child', new_node)
	if id == 0:
		undo_redo.add_do_method(self, 'add_to_starts', new_node.name)
	elif id == 8:
		undo_redo.add_do_method(self, 'add_to_frames', new_node.name)
	undo_redo.add_do_method(self, 'connect_node_signals', new_node)
	undo_redo.add_do_reference(new_node)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	if request_port > -1:
		if prev_connection.size() > 0:
			undo_redo.add_do_method(self, 'disconnect_node', request_node, request_port, prev_connection[0]['to_node'], prev_connection[0]['to_port'])
			undo_redo.add_undo_method(self, 'connect_node', request_node, request_port, prev_connection[0]['to_node'], prev_connection[0]['to_port'])
		undo_redo.add_do_method(self, 'connect_node', request_node, request_port, new_node.name, 0)
		undo_redo.add_undo_method(self, 'disconnect_node', request_node, request_port, new_node.name, 0)
	undo_redo.add_undo_method(self, 'disconnect_node_signals', new_node)
	if id == 0:
		undo_redo.add_undo_method(self, 'remove_from_starts', new_node.name)
	elif id == 8:
		undo_redo.add_undo_method(self, 'remove_from_frames', new_node.name)
	undo_redo.add_undo_method(self, 'remove_child', new_node)
	undo_redo.add_undo_method(self, 'deselect_all_nodes')
	undo_redo.commit_action(false)
	
	request_node = ''
	request_port = -1
	
	# set slot colors
	update_slots_color([new_node])


func _on_node_selected(node: GraphElement) -> void:
	if not selected_nodes.has(node):
		selected_nodes.append(node)


func _on_node_deselected(node: GraphElement) -> void:
	if selected_nodes.has(node):
		selected_nodes.erase(node)


func _on_node_dragged(from: Vector2, to: Vector2, node: GraphElement) -> void:
	if not undo_redo:
		cursor_pos = to
		return
	
	_on_modified()
	
	undo_redo.create_action('Drag node: ' + str(from) + '->' + str(to))
	undo_redo.add_do_property(node, 'position_offset', to)
	undo_redo.add_do_property(self, 'cursor_pos', to)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_property(self, 'cursor_pos', cursor_pos)
	undo_redo.add_undo_property(node, 'position_offset', from)
	undo_redo.commit_action(false)


func _on_duplicate_nodes_request() -> void:
	if selected_nodes.size() == 0: return
	
	var nodes_to_duplicate := selected_nodes.duplicate()
	var duplicated_nodes := []
	
	for node in nodes_to_duplicate:
		var clone_id := int(node.name.split('_')[0])
		var clone_node: GraphElement = add_node(clone_id)
		clone_node._from_dict(node._to_dict(self))
		clone_node.position_offset = node.position_offset + _duplicate_offset
		if clone_id == 1:
			clone_node._on_characters_updated(last_character_list)
			clone_node._on_variables_updated(last_variable_list)
		elif clone_id == 4 or clone_id == 5 or clone_id == 7:
			clone_node._on_variables_updated(last_variable_list)
			
		duplicated_nodes.append(clone_node)
	
	update_slots_color(duplicated_nodes)
	_on_modified()
	
	if not undo_redo:
		return
	
	# create undo_redo history
	undo_redo.create_action('Duplicate node(s)')
	selected_nodes = nodes_to_duplicate
	deselect_all_nodes()
	for node in duplicated_nodes:
		var id := int(node.name.split('_')[0])
		node.selected = true
		_on_node_selected(node)
		undo_redo.add_do_method(self, 'add_child', node)
		if id == 0:
			undo_redo.add_do_method(self, 'add_to_starts', node.name)
		undo_redo.add_do_method(self, 'connect_node_signals', node)
		undo_redo.add_do_reference(node)
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(self, 'disconnect_node_signals', node)
		if id == 0:
			undo_redo.add_undo_method(self, 'remove_from_starts', node.name)
		undo_redo.add_undo_method(self, 'remove_child', node)
		undo_redo.add_undo_method(self, 'deselect_all_nodes')
	
	undo_redo.commit_action(false)


func _on_delete_nodes_request(_nodes) -> void:
	if not undo_redo:
		for node in selected_nodes:
			remove_child(node)
			node.queue_free()
			for connection in get_connection_list():
				if connection['from_node'] == node.name or connection['to_node'] == node.name:
					disconnect_node(connection['from_node'], connection['from_port'], connection['to_node'], connection['to_port'])
		deselect_all_nodes()
		return
	
	# detach nodes from frames (if any)
	for node: GraphElement in selected_nodes:
		var titlebar: HBoxContainer = node.get_titlebar_hbox()
		if not titlebar.has_node('DetachButton'): continue
		var detach_button: Button = titlebar.get_node('DetachButton')
		if is_instance_valid(detach_button):
			detach_button.pressed.emit()
	
	# delete nodes
	undo_redo.create_action('Delete node(s)')
	for node: GraphElement in selected_nodes:
		var id := int(node.name.split('_')[0])
		var connections := []
		
		for connection in get_connection_list():
			if connection['from_node'] == node.name or connection['to_node'] == node.name:
				connections.append(connection)
		
		for conn in connections:
			undo_redo.add_do_method(self, 'disconnect_node', conn['from_node'], conn['from_port'], conn['to_node'], conn['to_port'])
		undo_redo.add_do_method(self, 'disconnect_node_signals', node)
		if id == 0:
			undo_redo.add_do_method(self, 'remove_from_starts', node.name)
		elif id == 8:
			for element in node.attached_nodes:
				undo_redo.add_do_method(self, 'detach_node_from_frame', element, node.name)
		undo_redo.add_do_method(self, 'remove_child', node)
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(self, 'add_child', node)
		if id == 0:
			undo_redo.add_undo_method(self, 'add_to_starts', node.name)
		elif id == 8:
			for element in node.attached_nodes:
				undo_redo.add_undo_method(self, 'attach_node_to_frame', element, node.name)
		undo_redo.add_undo_method(self, 'connect_node_signals', node)
		for conn in connections:
			undo_redo.add_undo_method(self, 'connect_node', conn['from_node'], conn['from_port'], conn['to_node'], conn['to_port'])
		undo_redo.add_undo_reference(node)
	undo_redo.commit_action()
	deselect_all_nodes()


func _on_connection_to_empty(from_node: String, from_port: int, release_position :Vector2) -> void:
	request_node = from_node
	request_port = from_port
	show_add_menu(release_position)


func _on_connection_request(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	if not undo_redo:
		var prev_connection := get_connections(from_node, from_port)
		if prev_connection.size() > 0:
			disconnect_node(from_node, from_port, prev_connection[0]['to_node'], prev_connection[0]['to_port'])
		connect_node(from_node, from_port, to_node, to_port)
		return
	
	# find previous connection (if any)
	var prev_connection := get_connections(from_node, from_port)
	
	undo_redo.create_action('Connect nodes')
	if prev_connection.size() > 0:
		undo_redo.add_do_method(self, 'disconnect_node', from_node, from_port, prev_connection[0]['to_node'], prev_connection[0]['to_port'])
	undo_redo.add_do_method(self, 'connect_node', from_node, from_port, to_node, to_port)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'disconnect_node', from_node, from_port, to_node, to_port)
	if prev_connection.size() > 0:
		undo_redo.add_undo_method(self, 'connect_node', from_node, from_port, prev_connection[0]['to_node'], prev_connection[0]['to_port'])
	undo_redo.commit_action()


func _on_disconnection_request(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	if not undo_redo: return
	
	undo_redo.create_action('Disconnect nodes')
	undo_redo.add_do_method(self, 'disconnect_node', from_node, from_port, to_node, to_port)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'connect_node', from_node, from_port, to_node, to_port)
	undo_redo.commit_action()


func _on_disconnection_from_request(from_node: String, from_port: int) -> void:
	if not undo_redo: return
	
	var connections := get_connections(from_node, from_port)
	
	undo_redo.create_action('Disconnect nodes')
	for conn in connections:
		undo_redo.add_do_method(self, 'disconnect_node', from_node, from_port, conn['to_node'], conn['to_port'])
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(self, 'connect_node', from_node, from_port, conn['to_node'], conn['to_port'])
	undo_redo.commit_action()


func _on_connection_shift_request(from_node: String, old_port: int, new_port: int) -> void:
	var connections := get_connections(from_node, old_port)
	
	if connections.size() == 0: return
	
	disconnect_node(from_node, old_port, connections[0]['to_node'], connections[0]['to_port'])
	connect_node(from_node, new_port, connections[0]['to_node'], connections[0]['to_port'])


func _on_characters_updated(character_list: Array[Character]) -> void:
	if not is_inside_tree(): return
	
	last_character_list = character_list
	characters_updated.emit(character_list)

func _on_variables_updated(variable_list: Array[String]) -> void:
	if not is_inside_tree(): return
	
	last_variable_list = variable_list
	variables_updated.emit(variable_list)

func _on_run_requested(node: GraphElement) -> void:
	var idx := starts.find(node.name)
	if idx == -1: return
	
	run_requested.emit(idx)


func _on_modified() -> void:
	modified.emit()


func _on_graph_elements_linked_to_frame_request(elements: Array, frame: StringName) -> void:
	if not undo_redo:
		for element_name: StringName in elements:
			attach_node_to_frame(element_name, frame)
		return
	
	undo_redo.create_action('Attach to frame')
	for element_name: StringName in elements:
		undo_redo.add_do_method(self, 'attach_node_to_frame', element_name, frame)
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(self, 'detach_node_from_frame', element_name, frame)
	undo_redo.commit_action()


func _on_graph_elements_unlinked_to_frame_request(element: StringName, frame: StringName) -> void:
	if not undo_redo:
		detach_node_from_frame(element, frame)
		return
	
	undo_redo.create_action('Detach from frame')
	undo_redo.add_do_method(self, 'detach_node_from_frame', element, frame)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'attach_node_to_frame', element, frame)
	undo_redo.commit_action()
