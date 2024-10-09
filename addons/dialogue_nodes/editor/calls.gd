@tool
extends Script
##
## Default Method Database for CallNodes
##
## Method database for all function calls made from DialogueCalls.
## This script is expected to be expanded by the user, customized to their needs.
## Alternativelly, the user may create new scripts to call methods from.

func sample_method(nickname, age: int, height: float = 5.1) -> String:
	return "My name is %s, I am %d years old, and I am %.2 feet tall!" % [nickname, age, height]
