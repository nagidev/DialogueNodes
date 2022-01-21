tool
extends GraphEdit
# TODO : find some way to discard arguments from signals

signal modified


func get_next(node_name):
	var next = []
	for connection in get_connection_list():
		if connection['from'] == node_name:
			next.append(connection['to'])
	
	return next


func _on_modified( _a=0, _b=0, _c=0, _d=0 ):
	emit_signal("modified")
