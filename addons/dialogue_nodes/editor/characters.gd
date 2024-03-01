@tool
extends Control

signal file_selected(characterList : Array[Resource])
signal modified

@onready var loadButton = $HBoxContainer/LoadButton
@onready var filePath = $HBoxContainer/FilePath
@onready var resetButton = $HBoxContainer/ResetButton
@onready var openDialog = $OpenDialog

var characterList : Array[Resource]


func load_file(path : String):
	filePath.text = path
	_on_filePath_changed()
	
	if path.ends_with('.tres'):
		var resource = load(path)
		if resource is Resource:
			for dict in resource.get_property_list():
				if dict.name == 'Characters':
					return
	
	if path != '':
		printerr('Invalid character resource file!')


func _on_loadButton_pressed():
	openDialog.popup_centered()


func _on_resetButton_pressed():
	filePath.text = ''
	_on_filePath_changed()


func _on_filePath_changed():
	characterList = []
	if filePath.text == '':
		resetButton.hide()
	else:
		resetButton.show()
		
		var path = filePath.text
		if path.ends_with('.tres'):
			var file = load(path)
			if file is Resource:
				for dict in file.get_property_list():
					if dict.name == 'Characters':
						characterList = file.Characters

	file_selected.emit(characterList)
	modified.emit()
