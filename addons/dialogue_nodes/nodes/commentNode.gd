@tool
extends GraphNode


signal modified

@onready var textEdit = $TextEdit

var _minsize = Vector2.ZERO

func _ready():
	_on_resize(size)
	_minsize = size


func _to_dict(_graph):
	var dict = {}
	
	dict['comment'] = textEdit.text
	dict['size'] = {}
	dict['size']['x'] = size.x
	dict['size']['y'] = size.y
	
	return dict


func _from_dict(_graph, dict):
	if dict.has('size'):
		size = Vector2( float(dict['size']['x']), float(dict['size']['y']) )
	
	_on_resize(size)
	
	textEdit.text = dict['comment']


func _on_resize(new_minsize):
	new_minsize.x = max(new_minsize.x, _minsize.x)
	new_minsize.y = max(new_minsize.y, _minsize.y)
	custom_minimum_size = new_minsize
	size = new_minsize
	textEdit.custom_minimum_size.y = new_minsize.y - 32
	_on_node_modified()


func _on_node_modified(_a=0, _b=0):
	modified.emit()
