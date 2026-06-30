extends Node
## Global flags + respawn checkpoint + input registration.
## Autoload singleton: "GameState".

signal flag_changed(flag: StringName, value: Variant)
signal caught

var flags: Dictionary = {}
var checkpoint_room: StringName = &"A1"
var checkpoint_side: String = "start"


func _ready() -> void:
	_register_input()


func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func has_flag(flag: StringName) -> bool:
	return bool(flags.get(flag, false))


func set_checkpoint(room: StringName, side: String) -> void:
	checkpoint_room = room
	checkpoint_side = side


## Called by a stealth hazard when it spots the player.
func trigger_caught() -> void:
	caught.emit()
	RoomManager.respawn_at_checkpoint()


## Register movement / action inputs at runtime so the bindings live in code,
## not in a fragile project.godot [input] block.
func _register_input() -> void:
	var binds := {
		&"move_up": [KEY_UP, KEY_W],
		&"move_down": [KEY_DOWN, KEY_S],
		&"move_left": [KEY_LEFT, KEY_A],
		&"move_right": [KEY_RIGHT, KEY_D],
		&"interact": [KEY_Z, KEY_ENTER, KEY_SPACE],
		&"grab": [KEY_X, KEY_SHIFT],
	}
	for action in binds:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		for keycode in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
