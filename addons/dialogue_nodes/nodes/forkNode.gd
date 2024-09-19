@tool
extends GraphNode
##
## Fork Node
##
## Groups a list of output options, each with a condition. The first condition (top to
## bottom) to be valid is used to exit, with a default option with no conditions always last.

signal modified
signal disconnection_from_request(from_node : String, from_port : int)
signal connection_shift_request(from_node : String, old_port : int, new_port : int)

@export var max_options := -1
@export var color_option : Color = Color.GREEN_YELLOW
@export var color_default : Color = Color.INDIAN_RED

var undo_redo : EditorUndoRedoManager
var last_size := size

var options: Array = []
var empty_option : BoxContainer
var option_height: int = 0

@onready var title_label: LineEdit = %Title
@onready var first_option_index: int = %ForkOption1.get_index()
@onready var default_option: BoxContainer = %DefaultForkOption

@onready var orig_height: int = size.y  # Includes 2 options (starter + default)

@onready var OptionScene := preload("res://addons/dialogue_nodes/nodes/sub_nodes/forkOption.tscn")


func _ready():
	options.clear()
	add_option(get_child(first_option_index))
	update_slots()
	reset_size()


func _to_dict(graph : GraphEdit):
	var dict = {}
	
	# get values
	dict['title'] = title_label.text
	
	# get options connected to other nodes (including separate default option)
	var options_dict := {}
	for connection in graph.get_connections(name):
		var idx : int = connection['from_port'] # this returns index starting from 0
		
		if idx < options.size():
			options_dict[idx] = {}
			options_dict[idx]['text'] = options[idx].text
			options_dict[idx]['link'] = connection['to_node']
			options_dict[idx]['condition'] = (
				options[idx].get_condition() if options[idx].text != '' else {}
			)
		else:
			dict['default_option'] = { 'link': connection['to_node'] }
	
	# get options not connected (including separate default option)
	for i in options.size():
		if not options_dict.has(i) and options[i].text != '':
			options_dict[i] = {}
			options_dict[i]['text'] = options[i].text
			options_dict[i]['link'] = 'END'
			options_dict[i]['condition'] = options[i].get_condition()
	if !dict.has('default_option'):
		dict['default_option'] = { 'link': 'END' }
	
	# if no options where registered (aside from default), record a single empty option
	if options_dict.is_empty():
		options_dict[0] = {}
		options_dict[0]['text'] = ''
		options_dict[0]['link'] = 'END'
		options_dict[0]['condition'] = {}
	
	# store options info in dict
	dict['options'] = options_dict
	
	return dict


func _from_dict(dict : Dictionary):
	var next_nodes = []
	
	# set values
	title_label.text = dict['title']

	# remove any existing options (if any)
	for option in options:
		option.queue_free()
	options.clear()
	
	# add new options
	for idx in dict['options']:
		var condition := {}
		if dict['options'][idx].has('condition'):
			condition = dict['options'][idx]['condition']
		var new_option := instantiate_option()
		add_option(new_option, first_option_index + int(idx))
		new_option.set_text(dict['options'][idx]['text'])
		new_option.set_condition(condition)
		next_nodes.append(dict['options'][idx]['link'])
	
	# add empty option if any space left
	if (max_options < 0 or options.size() < max_options) and options.back().text != '':
		var new_option := instantiate_option()
		add_option(new_option)
	
	# add default option link
	next_nodes.append(dict['default_option']['link'])
	update_slots()
	
	# set size of node
	reset_size()
	
	return next_nodes


func instantiate_option() -> BoxContainer:
	var option : BoxContainer = null
	if OptionScene.can_instantiate():
		option = OptionScene.instantiate()
		option.toggle_expand_to_text(true)
	else:
		printerr("Cannot instantiate OptionScene!")
	return option


func add_option(option : BoxContainer, to_idx := -1):
	if option.get_parent() != self:
		if !options.is_empty():
			options.back().add_sibling(option, true)
		else:
			add_child(option, true)
			move_child(option, default_option.get_index())
	if to_idx > -1: move_child(option, to_idx)
	
	option.undo_redo = undo_redo
	option.text_changed.connect(_on_option_text_changed.bind(option))
	option.focus_exited.connect(_on_option_focus_exited.bind(option))
	options.append(option)
	
	# sort options in the array
	options.sort_custom(func (op1, op2): return op1.get_index() < op2.get_index())
	
	# shift slot connections
	var options_count := options.size()
	var idx := options.find(option)
	for i in range(options_count - 1, idx, -1):
		if options[i].text != '':
			connection_shift_request.emit(name, i - 1, i)
	
	# if more than the empty option exists, shift the default option also
	if options_count > 1:
		connection_shift_request.emit(name, options_count - 2, options_count - 1)


func remove_option(option : BoxContainer):
	# shift slot connections
	var options_count := options.size()
	var idx := options.find(option)
	for i in range(idx, options_count - 1):
		if options[i + 1].text != '':
			connection_shift_request.emit(name, i + 1, i)
	
	# if more than the empty option exists, shift the default option also
	if options_count > 1:
		connection_shift_request.emit(name, options_count - 1, options_count - 2)
	
	options.erase(option)
	option.text_changed.disconnect(_on_option_text_changed.bind(option))
	option.focus_exited.disconnect(_on_option_focus_exited.bind(option))
	
	if option.get_parent() == self: remove_child(option)
	
	reset_size()


func update_slots():
	for option in options:
		var enabled : bool = option.text != ''
		set_slot(option.get_slot_index(), false, 0, color_option, enabled, 0, color_option)
	set_slot(options.back().get_index() + 1, false, 0, color_default, true, 0, color_default)


func _on_title_focus_exited():
	reset_size()


func _on_option_text_changed(new_text : String, option : BoxContainer):
	if not undo_redo: return
	
	var idx = option.get_index()
	
	# case 0 : option was queued for deletion but changed from '' to 'something'
	if option == empty_option:
		if new_text == '': return
		undo_redo.create_action('Set option text')
		undo_redo.add_do_method(option, 'set_text', new_text)
		undo_redo.add_do_method(self, 'update_slots')
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(option, 'set_text', option.text)
		undo_redo.add_undo_method(self, 'update_slots')
		undo_redo.commit_action()
		empty_option = null
		return
	
	if new_text == option.text: return
	
	# case 1 : option changed from '' to 'something'
	if option.text == '':
		if idx == options.back().get_index() and (max_options < 0 or options.size() < max_options):
			var new_option := instantiate_option()
			
			undo_redo.create_action('Set option text')
			undo_redo.add_do_method(option, 'set_text', new_text)
			undo_redo.add_do_method(self, 'add_option', new_option)
			undo_redo.add_do_method(self, 'update_slots')
			undo_redo.add_do_reference(new_option)
			undo_redo.add_do_method(self, '_on_modified')
			undo_redo.add_undo_method(self, '_on_modified')
			undo_redo.add_undo_method(option, 'set_text', option.text)
			undo_redo.add_undo_method(self, 'remove_option', new_option)
			undo_redo.add_undo_method(self, 'update_slots')
			undo_redo.add_undo_method(self, 'set_size', size)
			undo_redo.commit_action()
			return
	
	# case 2 : option changed from 'something' to ''
	elif new_text == '':
		if idx != options.back().get_index():
			empty_option = option
			return
		disconnection_from_request.emit(name, idx - first_option_index)
	
	# case 3 : text changed from something to something else (neither are '')
	undo_redo.create_action('Set option text')
	undo_redo.add_do_method(option, 'set_text', new_text)
	undo_redo.add_do_method(self, 'update_slots')
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(option, 'set_text', option.text)
	undo_redo.add_undo_method(self, 'update_slots')
	undo_redo.commit_action()


func _on_option_focus_exited(option : BoxContainer):
	if not undo_redo: return
	
	# case 2 : remove option when focus exits
	if option == empty_option:
		var idx = option.get_index()
		
		disconnection_from_request.emit(name, idx - first_option_index)
		
		undo_redo.create_action('Remove option')
		undo_redo.add_do_method(self, 'remove_option', option)
		# if the last option has some text, then create a new empty option
		if options.back().text != '':
			var new_option := instantiate_option()
			undo_redo.add_do_method(self, 'add_option', new_option)
			undo_redo.add_do_reference(new_option)
			undo_redo.add_undo_method(self, 'remove_option', new_option)
		undo_redo.add_do_method(self, 'update_slots')
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(self, 'add_option', option, idx)
		undo_redo.add_undo_method(option, 'set_text', option.text)
		undo_redo.add_undo_method(self, 'update_slots')
		undo_redo.commit_action()
		empty_option = null

	reset_size()


func _on_modified():
	modified.emit()
