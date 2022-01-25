tool
extends RichTextEffect
class_name RichTextWait

var bbcode = 'wait'
var current_char = 0

func _process_custom_fx(char_fx):
	var waitTime = char_fx.env.get('time', 0.0)
	var speed = char_fx.env.get('speed', 10.0)
	
	if char_fx.elapsed_time > waitTime:
		char_fx.visible = false
		if float(char_fx.elapsed_time) > float(char_fx.absolute_index / speed) + float(waitTime) :
			char_fx.visible = true
	else:
		char_fx.visible = false
	
	return true
