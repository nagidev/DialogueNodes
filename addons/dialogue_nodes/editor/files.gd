@tool
extends ItemList
class_name Files


signal opened(data : DialogueData)
signal switched(data : DialogueData)
signal closed

@export var editor_path: NodePath
@export var newDialogue_path: NodePath
@export var saveDialogue_path: NodePath
@export var openDialogue_path: NodePath
@export var confirmDialogue_path: NodePath

@onready var popupMenu = $PopupMenu

var file_icon = preload('res://addons/dialogue_nodes/icons/Script.svg')
var editor
var newDialogue
var saveDialogue
var openDialogue
var confirmDialogue

var current : int
var queued : Array # for closing


func _ready():
	editor = get_node(editor_path)
	newDialogue = get_node(newDialogue_path)
	saveDialogue = get_node(saveDialogue_path)
	openDialogue = get_node(openDialogue_path)
	confirmDialogue = get_node(confirmDialogue_path)
	
	confirmDialogue.get_ok_button().hide()
	confirmDialogue.add_button('Save', true, 'save_file')
	confirmDialogue.add_button('Discard', true, 'discard_file')
	confirmDialogue.add_cancel_button('Cancel')
	
	current = -1
	queued = []


func _exit_tree():
	close_all(true)
	file_icon = null


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


func create_file(file_name, file_dir, data : DialogueData):
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
			'data': data,
			'modified': false}
		
		# add new file item
		add_item(file_name, file_icon)
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
		# update the data of previous current
		var metadata = get_item_metadata(current)
		metadata['data'] = editor.get_data()
		set_item_metadata(current, metadata)
	
	current = idx
	var data : DialogueData= get_item_metadata(current)['data']
	select(current)
	switched.emit(data)


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
	var data = DialogueData.new()
	
	create_file(file_name, file_dir, data)
	save_file(current)
	
	switched.emit(data)


func open_file(path, internal = false):
	# open/read file
	var data = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_REPLACE)
	
	var file_name : String
	var file_dir : String
	
	if data is DialogueData:
		file_name = openDialogue.current_file
		file_dir = openDialogue.current_dir
	else:
		printerr('File not supported!')
		return
	
	# create, setup file button
	var file_idx = create_file(file_name, file_dir, data)
	
	if not internal:
		opened.emit(get_item_metadata(file_idx)['data'])


func save_file(idx = current):
	if idx < 0:
		return
	
	var metadata = get_item_metadata(idx)
	# update the data if needed
	if idx == current:
		metadata['data'] = editor.get_data()
		set_item_metadata(current, metadata)
	
	# save dialogue data to file
	ResourceSaver.save(metadata['data'], metadata['path'])
	
	if editor._debug:
		print('File saved: ', metadata['path'])
	
	metadata['modified'] = false
	set_item_metadata(idx, metadata)
	set_item_text(idx, metadata['path'].split('/')[-1])


func save_as_file(path, data):
	var file_name : String = saveDialogue.current_file
	var file_dir : String = saveDialogue.current_dir
	
	create_file(file_name, file_dir, data)
	save_file(current)
	switched.emit(data)


func save_all():
	for idx in range(get_item_count()):
		save_file(idx)


func close_file(idx = current):
	if idx < 0:
		return
	
	var metadata = get_item_metadata(idx)
	var count = get_item_count()

	if metadata['modified'] and not idx in queued:
		queued.append(idx)
		confirmDialogue.popup_centered()
		return
	elif idx == current:
		if count == 1:
			current = -1
		elif count == current+1:
			current -= 1
	
	remove_item(idx)
	closed.emit()
	
	if editor._debug:
		print('File closed: ', metadata['path'])
	
	if current > -1:
		select(current)
		switched.emit(get_item_metadata(current)['data'])


func close_all(force_close = false):
	# Check if any file is modified
	var modified = false
	for idx in range(get_item_count()):
		if get_item_metadata(idx)['modified']:
			modified = true
			break
	
	# Store all files in queue, ask for confirmation
	if modified and not force_close:
		queued.clear()
		for idx in range(get_item_count()):
			queued.push_front(idx)
		confirmDialogue.popup_centered()
		return
	
	# If none are modified, close all files
	current = -1
	for idx in range(get_item_count()):
		close_file(0)


func _on_confirmDialog_action(action):
	if len(queued) > 0:
		match (action):
			'save_file':
				for idx in queued:
					save_file(idx)
					close_file(idx)
					await get_tree().idle_frame
			'discard_file':
				for idx in queued:
					close_file(idx)
	confirmDialogue.hide()


func _on_confirmDialog_hide():
	queued.clear()


func _on_empty_clicked(at_pos, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var pop_pos = at_pos + global_position + Vector2(get_window().position)
		popupMenu.popup(Rect2(pop_pos, popupMenu.size))


func _on_item_clicked(index, at_pos, mouse_button_index):
	_on_empty_clicked(at_pos, mouse_button_index)
