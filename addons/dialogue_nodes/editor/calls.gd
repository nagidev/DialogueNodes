@tool
##
## Default Method Database for CallNodes
##
## Default method library for all function calls made from CallNodes.
## This script is expected to be expanded by the user and customized to their needs.
## Alternativelly, the user may create new [Script] files to call methods from.
## [br][br]
## [color=Yellow]Warning[/color]: [Array] and [Dictionary] arguments [b]cannot[/b] have default values.
## It is recommended that Static Typing is not used to specify their contents either,
## e.g. [code]Array[int][/code].


static func print_text(text: String) -> void:
	print(text)


static func roll_a_die(die_name: String, ignore: Array, faces: int = 6) -> int:
	var result: int = -1
	for i: int in 100:
		result = randi_range(1, faces)
		if !ignore.has(result):
			break
	if result == -1:
		push_error(
			"Die %s rolled (<%d> faces). Set to ignore <%s>. Rolling a valid result was imposible!"
			% [die_name, faces, ignore]
		)
		return -1
	
	print("Die %s rolled (<%d> faces). Result is <%d>." % [die_name, faces, result])
	return result


static func roll_dice(dice: Dictionary) -> Array:
	var results: Array[int] = []
	for die_name: String in dice:
		var die: Dictionary = dice[die_name]
		if !die.has("faces"):
			push_error("Invalid dice <%s>. Cannot roll, it has no faces key!" % die_name)
			continue
		
		var result: int = roll_a_die(die_name, die.ignore if die.has("ignore") else [], die.faces)
		if result != -1:
			results.push_back(result)
	print("Several dice where rolled, results are <%s>." % str(results))
	return results
