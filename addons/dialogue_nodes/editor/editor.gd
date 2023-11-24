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
onready var data = $Main/Workspace/SidePanel/Data
onready var characters = $Main/Workspace/SidePanel/Data/Characters
onready var variables = $Main/Workspace/SidePanel/Data/Variables
onready var dialogue = $DialogueBox
onready var newDialogue = $NewDialog
onready var saveDialogue = $SaveDialog
onready var openDialogue = $OpenDialog


var start_nodes = []
var comment_nodes = []
var _debug = false


func _ready():
	dialogue.popup_exclusive = false
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
	var data : DialogueData = DialogueData.new()
	data.starts = {}
	data.nodes = {}
	data.variables = {}
	data.comments = []
	data.strays = []
	
	data = start_node.tree_to_data(graph, data)
	data.variables = variables.to_dict()
	data.characters = characters.filePath.text
	dialogue.dialogue_data = data
	
	if dialogue.dialogue_data.starts.has(start_node.ID):
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


func get_data():
	var data = DialogueData.new()
	
	# add trees to dict
	data.starts = {}
	data.nodes = {}
	for start_node_name in start_nodes:
		var start_node = graph.get_node(start_node_name)
		data = start_node.tree_to_data(graph, data)
	
	# add comments to data
	data.comments = []
	for i in range(len(comment_nodes)):
		var node = graph.get_node(comment_nodes[i])
		data.comments.append(node.name)
		data.nodes[node.name] = node._to_dict(graph)
		data.nodes[node.name]['offset'] = node.offset
	
	# add variables to dict
	data.variables = variables.to_dict()
	
	# add stray nodes
	data.strays = []
	for node in graph.get_children():
		if node is GraphNode and not data.nodes.has(node.name):
			data.strays.append(node.name)
			data.nodes[node.name] = node._to_dict(graph)
			data.nodes[node.name]['offset'] = node.offset
	
	data.characters = characters.filePath.text
	
	return data


func open_data(data : DialogueData):
	
	# clear graph
	workspace.remove_all_nodes()
	yield(get_tree(), "idle_frame") #
	
	# add all start nodes with their trees
	workspace.loading_file = true
	for id in data.starts:
		var start_node_name = data.starts[id]
		var type = int(start_node_name.split('_')[0])
		var offset = data.nodes[start_node_name]['offset']
		var start_node = workspace.add_node(type, null, start_node_name, offset)
		start_node.data_to_tree(workspace, data)
	
	for node_name in data.comments:
		var type = int(node_name.split('_')[0])
		var offset = data.nodes[node_name]['offset']
		var comment_node = workspace.add_node(type, null, node_name, offset)
		comment_node._from_dict(graph, data.nodes[node_name])
	
	variables.from_dict(data.variables)
	
	for node_name in data.strays:
		var type = int(node_name.split('_')[0])
		var offset = data.nodes[node_name]['offset']
		var new_node = workspace.add_node(type, null, node_name, offset)
		new_node._from_dict(graph, data.nodes[node_name])
	
	characters.load_file(data.characters)
	
	workspace.request_node = null
	workspace.request_slot = null
	workspace.loading_file = false


func new_file(path):
	files.new_file(path)
	graph.show()
	data.show()


func open_file(path):
	files.open_file(path)


func save_file(path, data = get_data()):
	files.save_as_file(path, data)


func toggle_side_panel():
	side_panel.visible = not side_panel.visible


func _on_node_added(node_name):
	var type = node_name.split('_')[0]
	
	match( type ):
		'0':
			start_nodes.append(node_name)
			var node = graph.get_node(node_name)
			node.connect("run_tree", self, "_run_tree", [node])
		'1':
			var node = graph.get_node(node_name)
			characters.connect("file_selected", node, "_on_characters_loaded")
			node._on_characters_loaded(characters.characterList)
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
		3:
			# Close all
			files.close_all()


func _on_file_opened(dialogueData : DialogueData):
	open_data(dialogueData)
	graph.show()
	data.show()


func _on_file_closed():
	variables.remove_all_variables()


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


func _on_dialogue_started(id):
	if _debug:
		print_debug('Dialogue started: ', id)


func _on_dialogue_variable_changed(var_name, value):
	variables.set_value(var_name, value)
	
	if _debug:
		print_debug('Variable changed: ', var_name, ' = ', value)


func _on_dialogue_signal(value):
	if _debug:
		print_debug('Signal emitted with value: ', value)


func _on_dialogue_ended():
	if _debug:
		print_debug('Dialogue ended')


func _on_dialogue_cancelled():
	dialogue.stop()
