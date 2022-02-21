tool
extends Control


onready var fileMenu = $Main/ToolBar/FileMenu
onready var addMenu = $Main/ToolBar/AddMenu
onready var popupMenu = $Main/Workspace/Graph/PopupMenu
onready var runMenu = $Main/ToolBar/RunMenu
onready var debugMenu = $Main/ToolBar/DebugMenu
onready var workspace = $Main/Workspace
onready var graph = $Main/Workspace/Graph
onready var side_panel = $Main/Workspace/SidePanel
onready var files = $Main/Workspace/SidePanel/Files
onready var variables = $Main/Workspace/SidePanel/Variables
onready var dialogue = $DialogueBox
onready var newDialogue = $NewDialog
onready var saveDialogue = $SaveDialog
onready var openDialogue = $OpenDialog


var start_nodes = []
var comment_nodes = []
var _empty_dict = {'start': {}, 'comments': {}}
var _debug = false


func _ready():
	init_menus()
	
	addMenu.get_popup().connect("id_pressed", workspace, "add_node")
	runMenu.get_popup().connect("id_pressed", self, "_on_run_menu_pressed")
	fileMenu.get_popup().connect("id_pressed", self, "_on_file_menu_pressed")
	debugMenu.get_popup().connect("id_pressed", self, "_on_debug_menu_pressed")


func init_menus():
	# clear if already existing items
	addMenu.get_popup().clear()
	popupMenu.clear()
	
	# add items to both menus based on the nodes list
	for i in range(len(workspace.nodes)):
		addMenu.get_popup().add_item(workspace.nodes[i].name, i)
		popupMenu.add_item(workspace.nodes[i].name, i)
	
	# hide if no files are open
	if files.get_child_count() == 0:
		addMenu.hide()
		runMenu.hide()


# Run
func _run_tree(start_node):	
	var dict = start_node.tree_to_dict(graph)
	dict['variables'] = variables.to_dict()
	dialogue.dict = dict
	
	if dialogue.dict:
		dialogue.start(start_node.ID)


func _update_run_menu():
	runMenu.get_popup().clear()
	
	if len(start_nodes) == 0:
		runMenu.get_popup().add_item('Add a Start Node first!')
		runMenu.get_popup().set_item_disabled(0, true)
		return
	
	for start_node_name in start_nodes:
		var ID = graph.get_node(start_node_name).ID
		runMenu.get_popup().add_item(ID)


func get_dict():
	var dict = {}
	
	# add trees to dict
	dict['start'] = {}
	for start_node_name in start_nodes:
		var start_node = graph.get_node(start_node_name)
		dict = start_node.tree_to_dict(graph, dict)
	
	# add comments to dict
	var comments = {}
	for i in range(len(comment_nodes)):
		var node = graph.get_node(comment_nodes[i])
		comments[i] = node.name
		dict[node.name] = node._to_dict(graph)
		dict[node.name]['offset'] = {'x' : node.offset.x, 'y' : node.offset.y}
	dict['comments'] = comments
	
	# add variables to dict
	dict['variables'] = variables.to_dict()
	
	# add stray nodes #
	var strays = {}
	for node in graph.get_children():
		if node is GraphNode and not dict.has(node.name):
			strays[node.name] = node.name
			dict[node.name] = node._to_dict(graph)
			dict[node.name]['offset'] = {'x' : node.offset.x, 'y' : node.offset.y}
	dict['strays'] = strays
	
	return dict


func open_dict(dict):
	
	# clear graph
	workspace.remove_all_nodes()
	#yield(graph, "gui_input") #
	
	# add all start nodes with their trees
	workspace.loading_file = true
	for id in dict['start']:
		var start_node_name = dict['start'][id]
		var type = int(start_node_name.split('_')[0])
		var offset = Vector2( float(dict[start_node_name]['offset']['x']), float(dict[start_node_name]['offset']['y']) )
		var start_node = workspace.add_node(type, null, start_node_name, offset)
		start_node.dict_to_tree(workspace, dict)
	
	if dict.has('comments'):
		for key in dict['comments']:
			var node_name = dict['comments'][key]
			var type = int(node_name.split('_')[0])
			var offset = Vector2( float(dict[node_name]['offset']['x']), float(dict[node_name]['offset']['y']) )
			var comment_node = workspace.add_node(type, null, node_name, offset)
			comment_node._from_dict(graph, dict[node_name])
	
	if dict.has('variables'):
		variables.from_dict(dict['variables'])
	
	if dict.has('strays'):
		for key in dict['strays']:
			var node_name = dict['strays'][key]
			var type = int(node_name.split('_')[0])
			var offset = Vector2( float(dict[node_name]['offset']['x']), float(dict[node_name]['offset']['y']) )
			var new_node = workspace.add_node(type, null, node_name, offset)
			new_node._from_dict(graph, dict[node_name])
	
	workspace.request_node = null
	workspace.request_slot = null
	workspace.loading_file = false


func new_file(path):
	files.new_file(path)
	graph.show()
	variables.show()


func open_file(path):
	files.open_file(path)


func save_file(path, dict = get_dict()):
	files.save_as_file(path, dict)


func toggle_side_panel():
	side_panel.visible = not side_panel.visible


func _on_node_added(node_name):
	var type = node_name.split('_')[0]
	
	match( type ):
		'0':
			start_nodes.append(node_name)
			var node = graph.get_node(node_name)
			node.connect("run_tree", self, "_run_tree", [node])
		'2':
			comment_nodes.append(node_name)


func _on_node_deleted(node_name):
	var type = node_name.split('_')[0]
	
	match( type ):
		'0':
			start_nodes.erase(node_name)
		'2':
			comment_nodes.erase(node_name)


func _on_file_menu_pressed(id):
	
	match( id ):
		0:
			newDialogue.popup_centered()
		1:
			openDialogue.popup_centered()
		2:
			files.save_file()
		3:
			if files.get_item_count() > 0:
				saveDialogue.popup_centered()
		4:
			files.close_file()
			variables.remove_all_variables()
		5:
			files.close_all()
			variables.remove_all_variables()


func _on_file_popup_pressed(id):
	match (id):
		0:
			# Save
			files.save_file()
		1:
			# Save as
			if files.get_item_count() > 0:
				saveDialogue.popup_centered()
		2:
			# Close
			files.close_file()
			variables.remove_all_variables()
		3:
			# Close all
			files.close_all()
			variables.remove_all_variables()


func _on_file_opened(dict):
	open_dict(dict)
	graph.show()
	variables.show()


func _on_file_request_dict(file_button):
	file_button.dict = get_dict()


func _on_run_menu_pressed(id):
	var start_node = graph.get_node(start_nodes[int(id)])
	
	_run_tree(start_node)


func _on_debug_menu_pressed(id):
	match (id):
		0:
			var popup = debugMenu.get_popup()
			_debug = !_debug
			popup.set_item_checked(id, _debug)


func _on_graph_visibility_changed():
	addMenu.visible = graph.visible
	runMenu.visible = graph.visible


func _on_dialogue_variable_changed(var_name, value):
	variables.set_value(var_name, value)
