@tool
extends GraphEdit
# TODO : find some way to discard arguments from signals

signal modified


func get_next(node_name):
	var next = []
	for connection in get_connection_list():
		if connection['from_node'] == node_name:
			next.append(connection['to_node'])
	
	return next


func _on_modified( _a=0, _b=0, _c=0, _d=0 ):
	modified.emit()
