extends Node

# Autoloaded singleton: holds menu selections and sets up input actions
# for both players (since this project ships no .tscn input map to avoid
# hand-authored InputEvent resource errors).

var selected_time: float = 60.0


func _ready() -> void:
	_setup_input_action("move_left_a", KEY_A)
	_setup_input_action("move_right_a", KEY_D)
	_setup_input_action("jump_a", KEY_W)

	_setup_input_action("move_left_b", KEY_LEFT)
	_setup_input_action("move_right_b", KEY_RIGHT)
	_setup_input_action("jump_b", KEY_UP)


func _setup_input_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
