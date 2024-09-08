@tool
## A node for displaying branching dialogues, primarily created using the Dialogue Nodes editor.
class_name DialogueBox
extends Panel
 

## Triggered when a dialogue has started. Passes [param id] of the dialogue tree as defined in the StartNode.
signal dialogue_started(id : String)
## Triggered when a single dialogue block has been processed.
## Passes [param speaker] which can be a [String] or a [param Character] resource, a [param dialogue] containing the text to be displayed
## and an [param options] list containing the texts for each option.
signal dialogue_processed(speaker : Variant, dialogue : String, options : Array[String])
## Triggered when an option is selected
signal option_selected(idx : int)
## Triggered when a SignalNode is encountered while processing the dialogue.
## Passes a [param value] of type [String] that is defined in the SignalNode in the dialogue tree.
signal dialogue_signal(value : String)
## Triggered when a variable value is changed.
## Passes the [param variable_name] along with it's [param value]
signal variable_changed(variable_name : String, value)
## Triggered when a dialogue tree has ended processing and reached the end of the dialogue.
## The [DialogueBox] may hide based on the [member hide_on_dialogue_end] property.
signal dialogue_ended


@export_group('Data')
## Contains the [param DialogueData] resource created using the Dialogue Nodes editor.
@export var data : DialogueData :
	get:
		return data
	set(value):
		data = value
		if _dialogue_parser:
			_dialogue_parser.data = value
			variables = _dialogue_parser.variables
			characters = _dialogue_parser.characters
## The default start ID to begin dialogue from. This is the value you set in the Dialogue Nodes editor.
@export var start_id : String

@export_group('Speaker')
## The default color for the speaker label.
@export var default_speaker_color := Color.WHITE :
	set(value):
		default_speaker_color = value
		if speaker_label: speaker_label.modulate = default_speaker_color
## Hide the character portrait (useful for custom character portrait implementations).
@export var hide_portrait := false :
	set(value):
		hide_portrait = value
		if portrait: portrait.visible = not hide_portrait
## Sample portrait image that is visible in editor. This will not show in-game.
@export var sample_portrait := preload('res://addons/dialogue_nodes/icons/Portrait.png') :
	set(value):
		sample_portrait = value
		if portrait: portrait.texture = sample_portrait

@export_group('Dialogue')
## Speed of scroll when using joystick/keyboard input
@export var scroll_speed := 4
## Input action used to skip dialogue animation
@export var skip_input_action := 'ui_cancel'
## Custom RichTextEffects that can be used in the dialogue as bbcodes.[br]
## Example: [code][ghost]Spooky dialogue![/ghost][/code]
@export var custom_effects : Array[RichTextEffect] = [
	RichTextWait.new(),
	RichTextGhost.new(),
	RichTextMatrix.new()
	]

@export_group('Options')
## The maximum number of options to show in the dialogue box.
@export var max_options_count := 4 :
	get:
		return max_options_count
	set(value):
		max_options_count = max(value, 1)
		
		if options_container:
			# clear all options
			for option in options_container.get_children():
				options_container.remove_child(option)
				option.queue_free()
		
			for idx in range(max_options_count):
				var button = Button.new()
				options_container.add_child(button)
				button.text = 'Option '+str(idx+1)
				button.pressed.connect(select_option.bind(idx))
## Icon displayed when no text options are available.
@export var next_icon : Texture2D = preload('res://addons/dialogue_nodes/icons/Play.svg')
## Alignment of options.
@export_enum('Begin', 'Center', 'End') var options_alignment := 2 :
	set(value):
		options_alignment = value
		if options_container:
			options_container.alignment = options_alignment
## Orientation of options.
@export var options_vertical := false :
	set(value):
		options_vertical = value
		if options_container:
			options_container.vertical = options_vertical
## Position of options along the dialogue box.
@export_enum('Top', 'Left', 'Right', 'Bottom') var options_position := 3 :
	set(value):
		options_position = value
		if not options_container: return
		if not _main_container: return
		if not _sub_container: return
		
		options_container.get_parent().remove_child(options_container)
		match value:
			0:
				# top
				_sub_container.add_child(options_container)
				_sub_container.move_child(options_container, 0)
			3:
				# bottom
				_sub_container.add_child(options_container)
			1:
				# left
				_main_container.add_child(options_container)
				_main_container.move_child(options_container, 0)
			2:
				# right
				_main_container.add_child(options_container)

@export_group('Misc')
## Hide dialogue box at the end of a dialogue
@export var hide_on_dialogue_end := true

## Contains the variable data from the [param DialogueData] parsed in an easy to access dictionary.[br]
## Example: [code]{ "COINS": 10, "NAME": "Obama", "ALIVE": true }[/code]
var variables : Dictionary
## Contains all the [param Character] resources loaded from the path in the [member data].
var characters : Array[Character]
## Displays the portrait image of the speaker in the [DialogueBox]. Access the speaker's texture by [member DialogueBox.portrait.texture]. This value is automatically set while running a dialogue tree.
var portrait : TextureRect
## Displays the name of the speaker in the [DialogueBox]. Access the speaker name by [code]DialogueBox.speaker_label.text[/code]. This value is automatically set while running a dialogue tree.
var speaker_label : Label
## Displays the dialogue text. This node's value is automatically set while running a dialogue tree.
var dialogue_label : RichTextLabel
## Contains all the option buttons. The currently displayed options are visible while the rest are hidden. This value is automatically set while running a dialogue tree.
var options_container : BoxContainer

# [param DialogueParser] used for parsing the dialogue [member data].
# NOTE: Using [param DialogueParser] as a child instead of extending from it, because [DialogueBox] needs to extend from [Panel].
var _dialogue_parser : DialogueParser
var _main_container : BoxContainer
var _sub_container : BoxContainer
var _wait_effect : RichTextWait


func _enter_tree():
	if get_child_count() > 0:
		for child in get_children():
			remove_child(child)
			child.queue_free()
	
	var margin_container = MarginContainer.new()
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override('margin_left', 4)
	margin_container.add_theme_constant_override('margin_top', 4)
	margin_container.add_theme_constant_override('margin_right', 4)
	margin_container.add_theme_constant_override('margin_bottom', 4)
	
	_main_container = BoxContainer.new()
	margin_container.add_child(_main_container)
	
	portrait = TextureRect.new()
	_main_container.add_child(portrait)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait.texture = sample_portrait
	portrait.visible = not hide_portrait
	
	_sub_container = BoxContainer.new()
	_main_container.add_child(_sub_container)
	_sub_container.vertical = true
	_sub_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	speaker_label = Label.new()
	_sub_container.add_child(speaker_label)
	speaker_label.text = 'Speaker'
	
	dialogue_label = RichTextLabel.new()
	_sub_container.add_child(dialogue_label)
	dialogue_label.text = 'Some dialogue text to demonstrate how an actual dialogue might look like.'
	dialogue_label.bbcode_enabled = true
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.custom_effects = custom_effects
	
	options_container = BoxContainer.new()
	_sub_container.add_child(options_container)
	options_container.alignment = BoxContainer.ALIGNMENT_END
	max_options_count = max_options_count
	options_alignment = options_alignment
	options_vertical = options_vertical
	options_position = options_position
	
	_dialogue_parser = DialogueParser.new()
	add_child(_dialogue_parser)
	_dialogue_parser.data = data
	variables = _dialogue_parser.variables
	characters = _dialogue_parser.characters
	
	_dialogue_parser.dialogue_started.connect(_on_dialogue_started)
	_dialogue_parser.dialogue_processed.connect(_on_dialogue_processed)
	_dialogue_parser.option_selected.connect(_on_option_selected)
	_dialogue_parser.dialogue_signal.connect(_on_dialogue_signal)
	_dialogue_parser.variable_changed.connect(_on_variable_changed)
	_dialogue_parser.dialogue_ended.connect(_on_dialogue_ended)


func _ready():
	for effect in custom_effects:
		if effect is RichTextWait:
			_wait_effect = effect
			_wait_effect.wait_finished.connect(_on_wait_finished)
			break
	
	hide()


func _process(delta):
	if not is_running(): return
	
	# scrolling for longer dialogues
	var scroll_amt := 0.0
	if options_vertical:
		scroll_amt = Input.get_axis("ui_left", "ui_right")
	else:
		scroll_amt = Input.get_axis("ui_up", "ui_down")
	
	if scroll_amt:
		dialogue_label.get_v_scroll_bar().value += int(scroll_amt * scroll_speed)


func _input(event):
	if is_running() and Input.is_action_just_pressed(skip_input_action):
		if _wait_effect and not _wait_effect.skip:
			_wait_effect.skip = true
			await get_tree().process_frame
			_on_wait_finished()


## Starts processing the dialogue [member data], starting with the Start Node with its ID set to [param start_id].
func start(id := start_id):
	if not _dialogue_parser: return
	_dialogue_parser.start(id)


## Stops processing the dialogue tree.
func stop():
	if not _dialogue_parser: return
	_dialogue_parser.stop()


## Continues processing the dialogue tree from the node connected to the option at [param idx].
func select_option(idx : int):
	if not _dialogue_parser: return
	_dialogue_parser.select_option(idx)


## Returns [code]true[/code] if the [DialogueBox] is processing a dialogue tree.
func is_running():
	return _dialogue_parser.is_running()


func _on_dialogue_started(id : String):
	speaker_label.text = ''
	portrait.texture = null
	dialogue_label.text = ''
	show()
	dialogue_started.emit(id)


func _on_dialogue_processed(speaker : Variant, dialogue : String, options : Array[String]):
	# set speaker
	speaker_label.text = ''
	portrait.texture = null
	portrait.visible = not hide_portrait
	if speaker is Character:
		speaker_label.text = speaker.name
		speaker_label.modulate = speaker.color
		portrait.texture = speaker.image
		if not speaker.image: portrait.hide()
	elif speaker is String:
		speaker_label.text = speaker
		speaker_label.modulate = Color.WHITE
		portrait.hide()
	
	# set dialogue
	dialogue_label.text = _dialogue_parser._update_wait_tags(dialogue_label, dialogue)
	dialogue_label.get_v_scroll_bar().set_value_no_signal(0)
	for effect in custom_effects:
		if effect is RichTextWait:
			effect.skip = false
			break
	
	# set options
	for idx in range(options_container.get_child_count()):
		var option : Button = options_container.get_child(idx)
		if idx >= options.size():
			option.hide()
			continue
		option.text = options[idx].replace('[br]', '\n')
		option.show()
	options_container.get_child(0).icon = next_icon if options.size() == 1 and options[0] == '' else null
	options_container.hide()
	
	dialogue_processed.emit(speaker, dialogue, options)


func _on_option_selected(idx : int):
	option_selected.emit(idx)


func _on_dialogue_signal(value : String):
	dialogue_signal.emit(value)


func _on_variable_changed(variable_name : String, value):
	variable_changed.emit(variable_name, value)


func _on_dialogue_ended():
	if hide_on_dialogue_end: hide()
	dialogue_ended.emit()


func _on_wait_finished():
	options_container.show()
	options_container.get_child(0).grab_focus()
