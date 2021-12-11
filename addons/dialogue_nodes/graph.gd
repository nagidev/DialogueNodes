tool
extends GraphEdit
# TODO :

func get_next(node_name):
	var next = []
	for connection in get_connection_list():
		if connection['from'] == node_name:
			next.append(connection['to'])
	
	return next
