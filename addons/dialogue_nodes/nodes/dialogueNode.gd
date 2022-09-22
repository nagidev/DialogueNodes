tool
extends GraphNode


signal modified
signal connection_move(old_slot, new_slot)

export var max_options = 4

onready var speaker = $Speaker
onready var dialogue = $Dialogue

var options : Array = []

func _ready():
	for i in range(max_options):
		if has_node("Option"+str(i+1)):
			var option = get_node("Option"+str(i+1))
			options.append(option)
			option.connect("text_changed", self, "_on_option_changed", [options[0]])
			option.connect("text_entered", self, "_on_option_entered", [options[0]])
			option.connect("focus_exited", self, "_on_option_entered", ['', options[0]])
			set_slot(option.get_index(), false, 0, Color.white, true, 0, Color.white)
	dialogue.add_color_region('[', ']', Color('a5efac'))


func add_option(new_text= ''):
	if len(options) == max_options:
		return
	
	var new_option = LineEdit.new()
	var id = len(options)
	
	new_option.name = 'Option'+str(id+1)
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
	
	speaker.text = speaker.text.replace("{", "").replace("}", "")
	dict['speaker'] = speaker.text
	dict['dialogue'] = dialogue.text
	dict['size'] = {}
	dict['size']['x'] = rect_size.x
	dict['size']['y'] = rect_size.y
	
	# get options connected to other nodes
	var options_dict = {}
	for connection in graph.get_connection_list():
		if connection['from'] == name:
			var idx = connection['from_port'] # this returns index starting from 0
			options_dict[idx] = {}
			options_dict[idx]['text'] = options[int(idx)].text
			options_dict[idx]['link'] = connection['to']
	
	# get options not connected
	for i in range(len(options)):
		if not options_dict.has(i) and options[i].text != '':
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


func _from_dict(graph, dict):
	var next_nodes = []
	
	# set values
	speaker.text = dict['speaker']
	dialogue.text = dict['dialogue']
	
	# remove any existing options
	for option in options:
		option.queue_free()
	options.clear()
	
	# add new options
	for key in dict['options']:
		add_option(dict['options'][key]['text'])
		next_nodes.append(dict['options'][key]['link'])
	
	# set size of node
	if dict.has('size'):
		var new_size = Vector2( float(dict['size']['x']), float(dict['size']['y']) )
		_on_resize(new_size, true)
	
	_update_slots()
	 
	return next_nodes


func _on_option_changed(new_text, option_node):
	if option_node == options[-1]:
		add_option()
	if new_text != '':
		_update_slots()
	_on_node_modified()


func _on_option_entered(new_text, option_node):
	if option_node.text == '':
		remove_option(option_node)
		_update_slots()
	_on_node_modified()


func _on_resize(new_size, _loading = false):
	new_size.x = max(new_size.x, rect_min_size.x)
	new_size.y = max(new_size.y, rect_min_size.y)
	
	rect_size = new_size
	
	if not _loading:
		_on_node_modified()


func _on_node_modified(_a=0, _b=0):
	emit_signal("modified")
