tool
extends Control
# TODO : find a way to decide which node to keep track of [37] "match(type)..."

onready var addMenu = $Main/ToolBar/AddMenu
onready var popupMenu = $Main/Workspace/Graph/PopupMenu
onready var workspace = $Main/Workspace
onready var graph = $Main/Workspace/Graph
onready var side_panel = $Main/Workspace/SidePanel
onready var dialogue = $Dialogue


var start_nodes = []
var comment_nodes = []


func _ready():
	init_menus()
	
	addMenu.get_popup().connect("id_pressed", workspace, "add_node")


func init_menus():
	# clear if already existing items
	addMenu.get_popup().clear()
	popupMenu.clear()
	
	# add items to both menus based on the nodes list
	for i in range(len(workspace.nodes)):
		addMenu.get_popup().add_item(workspace.nodes[i].name, i)
		popupMenu.add_item(workspace.nodes[i].name, i)


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


func _run_tree(start_node):
	if start_node.ID == '':
		printerr(start_node.title, ' has no ID! Aborting...')
		return
	
	var dict = start_node.tree_to_dict(graph)
	
	if dict.size():
		dialogue.run_from_dict(dict, start_node.ID)


# Side panel
func toggle_side_panel():
	side_panel.visible = not side_panel.visible
