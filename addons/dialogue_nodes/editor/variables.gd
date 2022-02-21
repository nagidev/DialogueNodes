tool
extends VBoxContainer


signal modified


var delete_icon = preload("res://addons/dialogue_nodes/icons/Remove.svg")
var types = [TYPE_STRING, TYPE_INT, TYPE_REAL, TYPE_BOOL]


func add_variable(new_name='', new_type=0, new_value = ''):
	# Variable container
	var new_variable = HBoxContainer.new()
	new_variable.name = 'Variable0'
	add_child(new_variable, true)
	
	# Name
	var var_name = LineEdit.new()
	var_name.name = 'Name'
	var_name.text = new_name
	var_name.placeholder_text = 'Variable Name'
	var_name.size_flags_horizontal = SIZE_EXPAND_FILL
	new_variable.add_child(var_name)
	var _res = var_name.connect("text_changed", self, "_on_modified")
	
	# Type
	var type = OptionButton.new()
	type.name = 'Type'
	type.add_item('String', TYPE_STRING)
	type.add_item('Int', TYPE_INT)
	type.add_item('Float', TYPE_REAL)
	type.add_item('Bool', TYPE_BOOL)
	new_variable.add_child(type, true)
	type.selected = types.find(new_type)
	_res = type.connect("item_selected", self, "_on_modified")
	
	# Value
	var var_val = LineEdit.new()
	var_val.name = 'Value'
	var_val.text = new_value
	var_val.placeholder_text = 'Value'
	var_val.size_flags_horizontal = SIZE_EXPAND_FILL
	new_variable.add_child(var_val)
	_res = var_val.connect("text_changed", self, "_on_modified")
	
	# Delete button
	var delete = Button.new()
	delete.name = 'DeleteButton'
	new_variable.add_child(delete)
	delete.icon = delete_icon
	delete.connect("pressed", self, "remove_variable", [new_variable])
	
	_on_modified()
	
	return new_variable


func remove_variable(variable):
	variable.queue_free()
	_on_modified()


func remove_all_variables():
	for child in get_children():
		if child is HBoxContainer:
			remove_variable(child)


func get_variable(var_name):
	for child in get_children():
		if child is HBoxContainer and child.get_node('Name').text == var_name:
			return child
	
	printerr('Variable not found : ', var_name)
	return null


func get_value(var_name):
	return get_variable(var_name).get_node('Value').text


func set_value(var_name, value):
	var variable = get_variable(var_name)
	variable.get_node('Value').text = str(value)


func to_dict():
	var dict = {}
	
	for child in get_children():
		if child is HBoxContainer:
			var var_name = child.get_node('Name').text
			var type = child.get_node('Type').get_item_id(child.get_node('Type').selected)
			var var_val = child.get_node('Value').text
			if var_name != '':
				dict[var_name] = {'type': type, 'value': var_val}
	
	return dict


func from_dict(dict):
	# remove old variables
	remove_all_variables()
	
	# add values
	for var_name in dict:
		add_variable(var_name, int(dict[var_name]['type']), dict[var_name]['value'])


func _on_modified(_a=0, _b=0):
	emit_signal("modified")
