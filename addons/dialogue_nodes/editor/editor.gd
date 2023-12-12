@tool
extends Control


@onready var fileMenu = $Main/ToolBar/FileMenu
@onready var addMenu = $Main/ToolBar/AddMenu
@onready var popupMenu = $Main/Workspace/Graph/PopupMenu
@onready var runMenu = $Main/ToolBar/RunMenu
@onready var debugMenu = $Main/ToolBar/DebugMenu
@onready var workspace = $Main/Workspace
@onready var graph = $Main/Workspace/Graph
@onready var side_panel = $Main/Workspace/SidePanel
@onready var files : Files = $Main/Workspace/SidePanel/Files
@onready var data = $Main/Workspace/SidePanel/Data
@onready var characters = $Main/Workspace/SidePanel/Data/Characters
@onready var variables = $Main/Workspace/SidePanel/Data/Variables
@onready var version_number = $Main/Statusbar/VersionNumber
@onready var dialogue = $DialogueBox
@onready var dialogueBG = $DialogBackground
@onready var newDialogue = $NewDialog
@onready var saveDialogue = $SaveDialog
@onready var openDialogue = $OpenDialog


var start_nodes = []
var comment_nodes = []
var _debug = false
var _base_color : Color


func _ready():
	init_menus()
	data.hide()
	
	addMenu.get_popup().id_pressed.connect(workspace.add_node)
	runMenu.get_popup().id_pressed.connect(_on_run_menu_pressed)
	fileMenu.get_popup().id_pressed.connect(_on_file_menu_pressed)
	debugMenu.get_popup().id_pressed.connect(_on_debug_menu_pressed)
	
	dialogue.dialogue_started.connect(_on_dialogue_started)
	dialogue.dialogue_signal.connect(_on_dialogue_signal)
	dialogue.variable_changed.connect(_on_dialogue_variable_changed)
	dialogue.dialogue_ended.connect(_on_dialogue_ended)
	dialogue.option_selected.connect(_on_dialogue_option_selected)
	
	var config = ConfigFile.new()
	config.load('res://addons/dialogue_nodes/plugin.cfg')
	version_number.text = config.get_value('plugin', 'version')


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
		dialogueBG.show()
		dialogue.options.get_child(0).grab_focus()
		dialogue.start(start_node.ID)


func _update_run_menu():
	runMenu.get_popup().clear()
	
	if len(start_nodes) == 0:
		runMenu.get_popup().add_item('Add a Start Node first!')
		runMenu.get_popup().set_item_disabled(0, true)
		return
	
	for start_node_name in start_nodes:
		var ID = graph.get_node( NodePath(start_node_name) ).ID
		runMenu.get_popup().add_item(ID)


func get_data() -> DialogueData:
	var data = DialogueData.new()
	
	# add trees to data
	data.starts = {}
	data.nodes = {}
	for start_node_name in start_nodes:
		var start_node = graph.get_node( NodePath(start_node_name) )
		data = start_node.tree_to_data(graph, data)
	
	# add comments to data
	data.comments.clear()
	for i in range(len(comment_nodes)):
		var node = graph.get_node( NodePath(comment_nodes[i]) )
		data.comments.append(node.name)
		data.nodes[node.name] = node._to_dict(graph)
		data.nodes[node.name]['offset'] = node.position_offset
	
	# add variables to data
	data.variables = variables.to_dict()
	
	# add stray nodes
	data.strays.clear()
	for node in graph.get_children():
		if node is GraphNode and not data.nodes.has(node.name):
			data.strays.append(node.name)
			data.nodes[node.name] = node._to_dict(graph)
			data.nodes[node.name]['offset'] = node.position_offset
	
	data.characters = characters.filePath.text
	
	return data


func open_data(data : DialogueData):
	# clear graph
	workspace.remove_all_nodes()
	#await get_tree().idle_frame
	
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


func save_file(path, data : DialogueData = get_data()):
	files.save_as_file(path, data)


func toggle_side_panel():
	side_panel.visible = not side_panel.visible


func _on_node_added(node_name):
	var type = node_name.split('_')[0]
	var node : GraphNode = graph.get_node( NodePath(node_name) )
	
	if node.is_slot_enabled_left(0):
		node.set_slot_color_left(0, _base_color)
	
	match( type ):
		'0':
			start_nodes.append(node_name)
			node.set_slot_color_right(0, _base_color)
			node.run_tree.connect(_run_tree.bind(node))
		'1':
			node._set_syntax_color(_base_color)
			characters.file_selected.connect(node._on_characters_loaded)
			node._on_characters_loaded(characters.characterList)
		'2':
			comment_nodes.append(node_name)
		'3', '4':
			node.set_slot_color_right(0, _base_color)


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
	var start_node = graph.get_node( NodePath(start_nodes[int(id)]) )
	
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


func _on_dialogue_started(id : String):
	if _debug:
		print_debug('Dialogue started: ', id)


func _on_dialogue_variable_changed(var_name, value):
	variables.set_value(var_name, value)
	files.modify_file()
	
	if _debug:
		print('Variable changed:', var_name, ', value:', value)


func _on_dialogue_signal(value):
	if _debug:
		print('Dialogue emitted signal with value:', value)


func _on_dialogue_ended():
	dialogueBG.hide()
	if _debug:
		print('Dialogue finished')


func _on_dialogue_option_selected(idx):
	if _debug:
		print('Option selected. idx: ', idx, ', text: ', dialogue.options.get_child(idx).text)


func _on_dialog_background_input(event):
	if event is InputEventMouseButton:
		dialogue.stop()


func _on_version_number_pressed():
	DisplayServer.clipboard_set('v'+version_number.text)
