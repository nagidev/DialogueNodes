tool
extends GraphNode
# TODO : deal with empty options

signal connection_move(old_slot, new_slot)

export var max_options = 4

onready var speaker = $Speaker
onready var dialogue = $Dialogue

var _minsize = Vector2.ZERO
var options = []

func _ready():
	_on_resize(rect_size)
	_minsize = rect_size
	
	options.append(get_node("Option1"))
	options[0].connect("text_changed", self, "_on_option_changed", [options[0]])
	options[0].connect("text_entered", self, "_on_option_entered", [options[0]])
	options[0].connect("focus_exited", self, "_on_option_entered", ['', options[0]])
	set_slot(options[0].get_index(), false, 0, Color.white, true, 0, Color.white)


func add_option(new_text= ''):
	if len(options) == max_options:
		return
	
	var new_option = options[0].duplicate()
	var id = len(options)
	
	new_option.text = new_text
	new_option.placeholder_text = "Option"+str(id+1)
	
	options.append(new_option)
	new_option.connect("text_changed", self, "_on_option_changed", [new_option])
	new_option.connect("text_entered", self, "_on_option_entered", [new_option])
	new_option.connect("focus_exited", self, "_on_option_entered", ['', new_option])
	
	add_child(new_option, true)


func remove_option(option_node):
	if len(options) == 1:
		return
	
	var i = options.find(option_node) + 1
	
	while i < len(options):
		options[i-1].text = options[i].text
		emit_signal("connection_move", i, i-1)
		i += 1
	
	options[-1].text = ''
	options[-1].queue_free()
	options.pop_back()


func _update_slots():
	
	# turn off all slots whose options are empty
	for i in range(len(options)):
		set_slot(options[i].get_index(), false, 0, Color.white, (options[i].text != ''), 0, Color.white)
	
	# set the first slot to true anyway
	set_slot(options[0].get_index(), false, 0, Color.white, true, 0, Color.white)


func _to_dict(graph):
	var dict = {}
	
	dict['speaker'] = speaker.text
	dict['dialogue'] = dialogue.text
	
	# get options connected to other nodes
	var options_dict = {}
	for connection in graph.get_connection_list():
		if connection['from'] == name:
			var idx = connection['from_port'] # this returns index starting from 0
			options_dict[idx] = {}
			options_dict[idx]['text'] = options[int(idx)].text
			options_dict[idx]['link'] = connection['to']
	
	# get options not connected
	for i in range(len(options)-1):
		if not options_dict.has(i):
			options_dict[str(i)] = {}
			options_dict[str(i)]['text'] = options[i].text
			options_dict[str(i)]['link'] = 'END'
	
	# single empty disconnected option
	if not options_dict.has(0):
		options_dict[str(0)] = {}
		options_dict[str(0)]['text'] = options[0].text
		options_dict[str(0)]['link'] = 'END'
	
	# store options info in dict
	dict['options'] = options_dict
	
	return dict


func _on_option_changed(new_text, option_node):
	if option_node == options[-1]:
		add_option()
	if new_text != '':
		_update_slots()


func _on_option_entered(new_text, option_node):
	if option_node.text == '':
		remove_option(option_node)
		_update_slots()


func _on_resize(new_minsize):
	new_minsize.x = max(new_minsize.x, _minsize.x)
	new_minsize.y = max(new_minsize.y, _minsize.y)
	rect_min_size = new_minsize
	rect_size = new_minsize
	dialogue.rect_min_size.y = new_minsize.y - dialogue.rect_position.y - 16
