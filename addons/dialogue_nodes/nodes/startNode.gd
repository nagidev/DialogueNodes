tool
extends GraphNode


signal run_tree

onready var ID = $HBoxContainer/ID.text


# convert graph/tree from this node to dict
func tree_to_dict(graph, dict= {}, node= self):
	var next_nodes = graph.get_next(node.name)
	
	# setup
	if node == self:
		if len(next_nodes) == 0:
			printerr(title, ' is not connected! Discarding...')
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


func _to_dict(graph):
	var dict = {}
	
	dict['start_id'] = ID
	dict['link'] = graph.get_next(name)[0]
	
	return dict


func _on_ID_changed(new_id):
	ID = new_id


func _on_run_pressed():
	emit_signal("run_tree")
