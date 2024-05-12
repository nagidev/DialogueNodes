## Data for processing dialogue through a [param DialogueParser].
@icon('res://addons/dialogue_nodes/icons/Dialogue.svg')
class_name DialogueData
extends Resource

## Contains the start IDs as keys and their respective node name as values.
## Example: { "START": "0_1" }
@export var starts : Dictionary = {}
## Contains all the data for each node in a dialogue graph with their node names as keys.[br]
## Example: [code]{ "0_1": { "link": "1_1", "offset": Vector2(0, 0), "start_id": "START" } }[/code]
@export var nodes : Dictionary = {}
## Contains the variable data including the variable name, data type and initial value.[br]
## Example: [code]{ "COINS": { "type": TYPE_INT, "value": 10 } }[/code]
@export var variables : Dictionary = {}
## Contains the node names of all the nodes not connected to a dialogue tree
@export var strays : Array[String] = []
## Path to the [param CharacterList] resource file.
@export var characters := ''
