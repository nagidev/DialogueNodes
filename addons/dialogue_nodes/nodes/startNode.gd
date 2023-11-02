@tool
extends GraphNode


signal modified
signal run_tree

@onready var ID = $HBoxContainer/ID.text


# convert graph/tree from this node to data
func tree_to_data(graph, data := DialogueData.new(), node : GraphNode = self):
	var next_nodes = graph.get_next(node.name)
	
	# setup
	if node == self:
		if ID == '':
			printerr(title, ' has no ID!')
			return data
		elif len(next_nodes) == 0:
			printerr(title, ' is not connected!')
			return data
		data.starts[ID] = name
	
	# add data for current node
	data.nodes[node.name] = node._to_dict(graph)
	data.nodes[node.name]['offset'] = node.position_offset
	
	# add data for next nodes
	for next_node in next_nodes:
		# if node already defined in data
		if data.nodes.has(next_node):
			continue
		# get data from node
		data = tree_to_data(graph, data, graph.get_node( NodePath(next_node) ))
	
	return data


func data_to_tree(workspace, data : DialogueData, node_name := name):
	var next_nodes = []
	
	# setup and end
	if node_name == name:
		next_nodes = _from_dict(workspace.graph, data.nodes[node_name])
		workspace.request_node = node_name
		workspace.request_slot = 0
	elif node_name == 'END':
		workspace.request_node = null
		workspace.request_slot = null
		return
	elif not workspace.graph.has_node( NodePath(node_name) ):
		var type = int(node_name.split('_')[0])
		var offset = data.nodes[node_name]['offset']
		var node = workspace.add_node(type, null, node_name, offset)
		next_nodes = node._from_dict(workspace.graph, data.nodes[node_name])
	elif workspace.graph.has_node( NodePath(node_name) ):
		workspace.graph.connect_node(workspace.request_node, workspace.request_slot, node_name, 0)
	
	for i in range(len(next_nodes)):
		workspace.request_node = node_name
		workspace.request_slot = i
		data_to_tree(workspace, data, next_nodes[i])


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
	get_node('HBoxContainer/ID').text = ID
	return [dict['link']]


func _on_ID_changed(new_id):
	ID = new_id
	modified.emit()


func _on_run_pressed():
	run_tree.emit()
