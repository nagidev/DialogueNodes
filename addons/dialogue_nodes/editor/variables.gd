@tool
extends Control


signal modified

@onready var var_container = $ScrollContainer/VBoxContainer

var variable_item_scene = preload('res://addons/dialogue_nodes/editor/VariableItem.tscn')

func add_variable(new_name= '', new_type= TYPE_STRING, new_value= ''):
	var new_variable = variable_item_scene.instantiate()
	var_container.add_child(new_variable, true)
	
	new_variable.var_name.text = new_name
	new_variable.type.select(new_variable.types.find(new_type))
	new_variable._on_type_changed(new_variable.types.find(new_type))
	new_variable.set_value(new_value)
	new_variable.modified.connect(_on_modified)
	
	_on_modified()
	
	return new_variable


func remove_variable(variable):
	variable.queue_free()
	_on_modified()


func remove_all_variables():
	for child in var_container.get_children():
		if child is HBoxContainer:
			remove_variable(child)


func get_variable(var_name):
	for child in var_container.get_children():
		if child is HBoxContainer and child.var_name.text == var_name:
			return child
	
	printerr('Variable not found : ', var_name)
	return null


func get_value(var_name):
	return get_variable(var_name).get_value()


func set_value(var_name, value):
	if var_name == '':
		return
	get_variable(var_name).set_value(value)


func to_dict():
	var dict = {}
	
	for child in var_container.get_children():
		if child is HBoxContainer:
			var var_name = child.var_name.text
			var type = child.type.get_item_id(child.type.selected)
			var var_val = child.get_value()
			if var_name != '':
				dict[var_name] = {'type': type, 'value': var_val}
	
	return dict


func from_dict(dict):
	# remove old variables
	remove_all_variables()
	
	# add values
	for var_name in dict:
		add_variable(var_name, int(dict[var_name]['type']), dict[var_name]['value'])


func _on_modified(_a= 0, _b= 0):
	modified.emit()
