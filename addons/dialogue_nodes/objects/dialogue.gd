tool
extends PopupDialog

onready var speaker = $Speaker
onready var dialogue = $Dialogue
onready var options = $Options

var cur_dict = null
var cur_id = null


func proceed(id):
	if id == 'END':
		hide()
	
	var type = id.split('_')[0]
	
	match(type):
		'0':
			popup_centered()
			proceed(cur_dict[id]['link'])
		'1':
			_set_dialogue(cur_dict[id])


func run_from_dict(dict, start_id):
	
	cur_dict = dict
	cur_id = dict['start'][start_id]
	
	proceed(dict['start'][start_id])


func _set_dialogue(dict):
	speaker.text = dict['speaker']
	dialogue.bbcode_text = dict['dialogue']
	
	# hide all options
	for option in options.get_children():
		option.hide()
	
	# set options
	for idx in dict['options']:
		var option = options.get_child(int(idx))
		option.text = dict['options'][idx]['text']
		if option.is_connected('pressed', self, 'proceed'):
			option.disconnect("pressed", self, 'proceed')
		option.connect("pressed", self, 'proceed', [dict['options'][idx]['link']])
		option.show()
