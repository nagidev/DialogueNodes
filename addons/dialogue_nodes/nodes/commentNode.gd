tool
extends GraphNode


onready var textEdit = $TextEdit

var _minsize = Vector2.ZERO

func _ready():
	_on_resize(rect_size)
	_minsize = rect_size


func _to_dict(_graph):
	var dict = {}
	
	dict['comment'] = textEdit.text
	dict['size'] = {}
	dict['size']['x'] = rect_size.x
	dict['size']['y'] = rect_size.y
	
	return dict


func _from_dict(_graph, dict):
	textEdit.text = dict['comment']
	rect_size = Vector2( float(dict['size']['x']), float(dict['size']['y']) )


func _on_resize(new_minsize):
	new_minsize.x = max(new_minsize.x, _minsize.x)
	new_minsize.y = max(new_minsize.y, _minsize.y)
	rect_min_size = new_minsize
	rect_size = new_minsize
	textEdit.rect_min_size.y = new_minsize.y - 32
