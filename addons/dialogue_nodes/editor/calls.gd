@tool
extends Script
##
## Default Method Database for CallNodes
##
## Method database for all function calls made from DialogueCalls.
## This script is expected to be expanded by the user, customized to their needs.
## Alternativelly, the user may create new scripts to call methods from.
## [br][br]
## Note: Cannot return void nor a container (must always return something that is not Array/Dict).


static func roll_dice(die_name: String, faces: int = 6) -> int:
	var result: int = randi_range(1, faces)
	print("Die %s rolled (<%d> faces). Result is <%d>." % [die_name, faces, result])
	return result
