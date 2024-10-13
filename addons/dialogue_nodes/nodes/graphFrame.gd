@tool
extends GraphFrame


signal modified

@export var edit_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/Edit.svg')
@export var check_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/Check.svg')
@export var cross_icon: Texture2D = preload('res://addons/dialogue_nodes/icons/Cross.svg')

@onready var instruction_label: Label = $InstructionLabel

var undo_redo: EditorUndoRedoManager
var attached_nodes: Array[StringName] = []
var title_label: Label
var edit_button: Button
var title_edit: LineEdit
var check_button: Button
var cross_button: Button
var color_button: ColorPickerButton


func _ready() -> void:
	title_label = get_titlebar_hbox().get_child(0)
	
	edit_button = Button.new()
	edit_button.icon = edit_icon
	edit_button.flat = true
	edit_button.pressed.connect(_on_edit_button_pressed)
	get_titlebar_hbox().add_child(edit_button)
	
	title_edit = LineEdit.new()
	title_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_edit.flat = true
	title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_titlebar_hbox().add_child(title_edit)
	title_edit.hide()
	
	check_button = Button.new()
	check_button.icon = check_icon
	check_button.flat = true
	check_button.pressed.connect(_on_check_button_pressed)
	get_titlebar_hbox().add_child(check_button)
	check_button.hide()
	
	cross_button = Button.new()
	cross_button.icon = cross_icon
	cross_button.flat = true
	cross_button.pressed.connect(_on_cross_button_pressed)
	get_titlebar_hbox().add_child(cross_button)
	cross_button.hide()
	
	color_button = ColorPickerButton.new()
	color_button.custom_minimum_size = Vector2(30, 0)
	color_button.color = tint_color
	color_button.popup_closed.connect(_on_color_changed)
	get_titlebar_hbox().add_child(color_button)


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := {}
	dict['title'] = title
	dict['tint_color'] = tint_color
	dict['attached_nodes'] = attached_nodes
	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	title = dict['title']
	tint_color = dict['tint_color']
	color_button.color = tint_color
	attached_nodes = dict['attached_nodes']
	return []


func _after_loaded(graph: GraphEdit) -> void:
	for node in attached_nodes:
		graph.attach_node_to_frame(node, name)
	instruction_label.visible = attached_nodes.size() == 0


func attach_node(element: StringName) -> void:
	if attached_nodes.has(element): return
	attached_nodes.append(element)
	instruction_label.visible = attached_nodes.size() == 0


func detach_node(element: StringName) -> void:
	attached_nodes.erase(element)
	if attached_nodes.size() == 0:
		instruction_label.show()
		size = Vector2(400, 200)


func toggle_edit(toggled_on: bool) -> void:
	title_label.visible = not toggled_on
	edit_button.visible = not toggled_on
	
	title_edit.visible = toggled_on
	check_button.visible = toggled_on
	cross_button.visible = toggled_on


func _on_edit_button_pressed() -> void:
	toggle_edit(true)
	
	title_edit.text = title
	title_edit.grab_focus()


func _on_check_button_pressed() -> void:
	toggle_edit(false)
	if not undo_redo:
		set_title(title_edit.text)
		return
	
	undo_redo.create_action('Set title')
	undo_redo.add_do_method(self, 'set_title', title_edit.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_title', title)
	undo_redo.commit_action()


func _on_cross_button_pressed() -> void:
	toggle_edit(false)
	
	title_edit.text = title


func _on_color_changed() -> void:
	if not undo_redo:
		tint_color = color_button.color
		return
	
	undo_redo.create_action('Set tint color')
	undo_redo.add_do_method(self, 'set_tint_color', color_button.color)
	undo_redo.add_do_method(color_button, 'set_pick_color', color_button.color)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_tint_color', tint_color)
	undo_redo.add_undo_method(color_button, 'set_pick_color', tint_color)
	undo_redo.commit_action()


func _on_modified() -> void:
	modified.emit()
