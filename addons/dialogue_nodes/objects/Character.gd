@icon('res://addons/dialogue_nodes/icons/Character.svg')
## The data for a speaker in a dialogue.
class_name Character
extends Resource

@export var name : String = '' :
    set(value):
        name = value
        translated_name = tr(value)
@export var image : Texture2D
@export var color : Color = Color.WHITE

var translated_name : String = ''
