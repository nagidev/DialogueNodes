tool
extends GraphNode

signal nodeModified

const WHITE = Color('#eeeeee')
const Colors = ['#54e0a1', 'edbc47', '47a3ed', 'ff5588']

export(String, 'Start', 'End', 'Dialogue', 'Comment') var nodeType = 'Start'


func _ready():
	connect("resize_request", self, '_on_resize_request')
	connect("close_request", self, '_on_modified')
	connect("dragged", self, '_on_modified')


func getType():
	return nodeType


func _on_resize_request(new_minsize):
	rect_size = new_minsize


func _on_modified(arg1= 0, arg2= 0, arg3= 0):
	emit_signal("nodeModified")
