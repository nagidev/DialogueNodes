tool
extends Control

signal file_selected(characterList)
signal modified

export var openDialog_path : NodePath

onready var loadButton = $HBoxContainer/LoadButton
onready var filePath = $HBoxContainer/FilePath
onready var resetButton = $HBoxContainer/ResetButton


var characterList : Array
var openDialog


func _ready():
	openDialog = get_node(openDialog_path)


func load_file(path : String):
	filePath.text = path
	_on_filePath_changed()
	
	if path.ends_with('.tres') and load(path) is CharacterList:
		return
	
	if path != '':
		printerr('Invalid character resource file!')


func _on_loadButton_pressed():
	openDialog.popup_centered()


func _on_resetButton_pressed():
	filePath.text = ""
	_on_filePath_changed()


func _on_filePath_changed():
	characterList = []
	if filePath.text == "":
		resetButton.hide()
	else:
		resetButton.show()
		
		var path = filePath.text
		if path.ends_with('.tres'):
			var file = ResourceLoader.load(path, '', true)
			if file is CharacterList:
				characterList = file.characters
	emit_signal("file_selected", characterList)
	emit_signal("modified")
