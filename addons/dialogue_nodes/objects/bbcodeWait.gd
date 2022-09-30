tool
extends RichTextEffect
class_name RichTextWait

signal wait_finished

var bbcode = 'wait'
var finished = false
var skip = false

func _process_custom_fx(char_fx):
	var waitTime = float(char_fx.env.get('time', 0.0))
	var speed = float(char_fx.env.get('speed', 40.0))
	var last = int(char_fx.env.get('last', 0))
	
	if float(char_fx.elapsed_time) > float(char_fx.absolute_index / speed) + waitTime or skip :
		char_fx.visible = true
		
		if char_fx.absolute_index >= last and not finished:
			emit_signal("wait_finished")
			finished = true
	else:
		char_fx.visible = false
		finished = false
	
	return true
