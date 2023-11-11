extends Resource
class_name DialogueData

@export var starts : Dictionary = {}
@export var nodes : Dictionary = {}
@export var variables : Dictionary = {}
@export var comments : Array[String] = []
@export var strays : Array[String] = []
## Path to the [CharacterList] resource file.
@export var characters = ''
