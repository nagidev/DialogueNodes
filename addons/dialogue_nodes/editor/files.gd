tool
extends ItemList


signal opened(dict)
signal switched(dict)
signal closed

export (NodePath) var editor_path
export (NodePath) var newDialogue_path
export (NodePath) var saveDialogue_path
export (NodePath) var openDialogue_path
export (NodePath) var confirmDialogue_path

var script_icon = preload("res://addons/dialogue_nodes/icons/Script.svg")
var files = {}
var editor
var newDialogue
var saveDialogue
var openDialogue
var confirmDialogue

var current : int
var queued : int # for closing


func _ready():
	editor = get_node(editor_path)
	newDialogue = get_node(newDialogue_path)
	saveDialogue = get_node(saveDialogue_path)
	openDialogue = get_node(openDialogue_path)
	confirmDialogue = get_node(confirmDialogue_path)
	
	##
	confirmDialogue.get_ok().hide()
	confirmDialogue.add_button("Save", true, "save_file")
	confirmDialogue.add_button("Discard", true, "discard_file")
	confirmDialogue.add_cancel("Cancel")
	
	current = -1
	queued = -1
	
	
func _show_dir(idx):
	var metadata = get_item_metadata(idx)
	var parts = metadata['path'].split('/')
	set_item_text(idx, parts[-2] + '/' + parts[-1])
	

func _is_file_open(node_name):
	
	for idx in range(get_item_count()):
		if get_item_metadata(idx)['id'] == node_name:
			return true
	
	return false


func _get_file_idx(node_name):
	
	for idx in range(get_item_count()):
		if get_item_metadata(idx)['id'] == node_name:
			return idx
	
	return -1


func create_file(file_name, file_dir, dict):
	var new_idx : int
	var node_name = file_dir.split('/')[-1] + '>' + file_name.split('.')[0]
	
	if _is_file_open(node_name):
		# file already open
		new_idx = _get_file_idx(node_name)
		select_file(new_idx)
	else:
		# init new file data
		new_idx = get_item_count()
		var new_file = {
			'id': node_name,
			'path': file_dir+'/'+file_name,
			'dict': dict,
			'modified': false}
		
		# add new file item
		add_item(file_name, script_icon)
		set_item_tooltip(new_idx, file_name)

		# set metadata
		set_item_metadata(new_idx, new_file)

		# show directory if files have the same name
		for idx in range(get_item_count()):
			if idx != new_idx and get_item_metadata(idx)['path'].split('/')[-1] == file_name:
				_show_dir(idx)
				_show_dir(new_idx)
		
		# select the new file
		select_file(new_idx)
	
	return new_idx


func select_file(idx):
	if idx < 0:
		return
	
	if current > -1:
		# update the dict of old current
		var metadata = get_item_metadata(current)
		metadata['dict'] = editor.get_dict()
		set_item_metadata(current, metadata)

	##
#	if idx == current:
#		print('already selected!')
#		return
	##

	current = idx
	var dict = get_item_metadata(current)['dict']
	select(current)
	emit_signal("switched", dict)


func modify_file(idx = current):
	if idx < 0:
		return
	var metadata = get_item_metadata(idx)
	metadata['modified'] = true
	set_item_metadata(idx, metadata)
	set_item_text(idx, metadata['path'].split('/')[-1]+'(*)')


func new_file(path):
	var file_name : String = newDialogue.current_file
	var file_dir : String = newDialogue.current_dir
	var dict = editor._empty_dict
	
	create_file(file_name, file_dir, dict)
	save_file(current)
	
	emit_signal("switched", dict)


func open_file(path, internal = false):
	# open/read file
	var file = File.new()
	file.open(path, File.READ)
	
	var dict = parse_json(file.get_as_text())
	file.close()
	
	var file_name : String
	var file_dir : String
	
	if typeof(dict) == TYPE_DICTIONARY:
		file_name = openDialogue.current_file
		file_dir = openDialogue.current_dir
	else:
		printerr('File not supported!')
		return
	
	# create, setup file button
	var file_idx = create_file(file_name, file_dir, dict)
	
	#print('File opened: ', get_item_metadata(file_idx)['path'])
	if not internal:
		emit_signal("opened", get_item_metadata(file_idx)['dict'])


func save_file(idx = current):
	if idx < 0:
		return
	
	var metadata = get_item_metadata(idx)
	# update the dict if needed
	if idx == current:
		metadata['dict'] = editor.get_dict()
		set_item_metadata(current, metadata)
	
	var file = File.new()
	file.open(metadata['path'], File.WRITE)
	
	# save dict to json file	
	file.store_line(to_json(metadata['dict']))
	file.close()
	
	print('File saved: ', metadata['path'])
	
	metadata['modified'] = false
	set_item_metadata(idx, metadata)
	set_item_text(idx, metadata['path'].split('/')[-1])


func save_as_file(path, dict):
	var file_name : String = saveDialogue.current_file
	var file_dir : String = saveDialogue.current_dir
	
	create_file(file_name, file_dir, dict)
	save_file(current)
	emit_signal("switched", dict)


func save_all():
	for idx in range(get_item_count()):
		save_file(idx)


func close_file(idx = current):
	if idx < 0:
		return
	
	var metadata = get_item_metadata(idx)

	if metadata['modified'] and idx != queued:
		confirmDialogue.popup_centered()
		queued = idx
		return
	elif idx == current:
		if get_item_count() == 1:
			current = -1
		elif get_item_count() == current+1:
			current -= 1
	
	remove_item(idx)
	emit_signal("closed")
	
	print('File closed: ', metadata['path'])
	
	if current > -1:
		select(current)
		emit_signal("switched", get_item_metadata(current)['dict'])


func _on_confirmDialog_action(action):
	if queued > -1:
		match(action):
			"save_file":
				save_file(queued)
				close_file(queued)
				queued = -1
			"discard_file":
				close_file(queued)
				queued = -1
	confirmDialogue.hide()
