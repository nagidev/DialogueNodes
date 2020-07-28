tool
extends GraphNode

const WHITE = Color('#eeeeee')
const Colors = ['#54e0a1', 'edbc47', '47a3ed', 'ff5588']

export(String, 'Start', 'End', 'Dialogue', 'Comment') var nodeType = 'Start'


func _ready():
	connect("resize_request", self, '_on_resize_request')


func getType():
	return nodeType


func _on_resize_request(new_minsize):
	rect_size = new_minsize
