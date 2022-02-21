tool
extends GraphNode


signal modified
signal run_tree

onready var ID = $HBoxContainer/ID.text


# convert graph/tree from this node to dict
func tree_to_dict(graph, dict= {}, node= self):
	var next_nodes = graph.get_next(node.name)
	
	# setup
	if node == self:
		if ID == '':
			printerr(title, ' has no ID!')
			return dict
		elif len(next_nodes) == 0:
			printerr(title, ' is not connected!')
			return dict
		if not dict.has('start'):
			dict['start'] = {ID : name}
		else:
			dict['start'][ID] = name
	
	# add data for current node
	dict[node.name] = node._to_dict(graph)
	dict[node.name]['offset'] = {'x' : node.offset.x, 'y' : node.offset.y}
	
	# add data for next nodes
	for next_node in next_nodes:
		# if node already defined in dict
		if dict.has(next_node):
			continue
		# get dict from node
		dict = tree_to_dict(graph, dict, graph.get_node(next_node))
	
	return dict


func dict_to_tree(workspace, dict, node_name= name):
	var next_nodes = []
	
	# setup and end
	if node_name == name:
		next_nodes = _from_dict(workspace.graph, dict[node_name])
		workspace.request_node = node_name
		workspace.request_slot = 0
	elif node_name == 'END':
		workspace.request_node = null
		workspace.request_slot = null
		return
	elif not workspace.graph.has_node(node_name):
		var type = int(node_name.split('_')[0])
		var offset = Vector2( float(dict[node_name]['offset']['x']), float(dict[node_name]['offset']['y']) )
		var node = workspace.add_node(type, null, node_name, offset)
		next_nodes = node._from_dict(workspace.graph, dict[node_name])
	elif workspace.graph.has_node(node_name):
		workspace.graph.connect_node(workspace.request_node, workspace.request_slot, node_name, 0)
	
	for i in range(len(next_nodes)):
		workspace.request_node = node_name
		workspace.request_slot = i
		dict_to_tree(workspace, dict, next_nodes[i])


func _to_dict(graph):
	var dict = {}
	var next = graph.get_next(name)
	
	if len(next) == 0:
		next.append('END')
	
	dict['start_id'] = ID
	dict['link'] = next[0]
	
	return dict


func _from_dict(graph, dict):
	ID = dict['start_id']
	get_node("HBoxContainer/ID").text = ID
	return [dict['link']]


func _on_ID_changed(new_id):
	ID = new_id
	emit_signal("modified")


func _on_run_pressed():
	emit_signal("run_tree")
