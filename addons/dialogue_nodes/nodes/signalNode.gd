@tool
extends GraphNode


signal modified

@onready var value = $SignalValue


func _to_dict(graph):
	var dict = {}
	dict['signalValue'] = value.text
	
	var next_nodes = graph.get_next(name)
	
	if len(next_nodes) > 0:
		dict['link'] = next_nodes[0]
	else:
		dict['link'] = 'END'
	
	return dict


func _from_dict(_graph, dict):
	value.text = dict['signalValue']
	
	return [dict['link']]


func _on_node_modified(_a=0, _b=0):
	modified.emit()
