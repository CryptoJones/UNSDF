class_name Player
extends Node2D
## Grid-stepped, 8-direction movement with a painted character sprite that faces
## the way you move. Walk into a crate (cardinally) to push it; hold Grab and back
## straight out of a faced crate to pull it.

const STEP_TIME := 0.10
const TARGET_H := 54.0   # on-screen sprite height in the 320x240 space

# facing vector -> sprite asset suffix
const DIRS := {
	Vector2i(0, 1): "down", Vector2i(0, -1): "up",
	Vector2i(-1, 0): "left", Vector2i(1, 0): "right",
	Vector2i(-1, 1): "down_left", Vector2i(1, 1): "down_right",
	Vector2i(-1, -1): "up_left", Vector2i(1, -1): "up_right",
}

var cell: Vector2i
var facing := Vector2i(0, 1)
var room   # Room

var _busy := false
var _sprite: Sprite2D
var _tex: Dictionary = {}


func _ready() -> void:
	z_index = 20
	for d in DIRS:
		_tex[d] = load("res://assets/sprites/recruit_%s.png" % DIRS[d])
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	_update_sprite()


func place(c: Vector2i) -> void:
	cell = c
	position = Grid.cell_to_pos(c)


func _update_sprite() -> void:
	var t: Texture2D = _tex.get(facing)
	if t == null:
		return
	_sprite.texture = t
	var s := TARGET_H / float(t.get_height())
	_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(0, -TARGET_H * 0.42)   # lift so the feet sit on the cell


func _process(_delta: float) -> void:
	if _busy or _locked_out():
		return
	var dir := _read_dir()
	if dir != Vector2i.ZERO:
		_attempt(dir)


func _locked_out() -> bool:
	return room == null or DialogueManager.active or RoomManager.is_busy()


## Combine the axes into one of eight directions.
func _read_dir() -> Vector2i:
	var dx := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	var dy := int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	return Vector2i(dx, dy)


func _attempt(dir: Vector2i) -> void:
	var cardinal := dir.x == 0 or dir.y == 0

	if cardinal and Input.is_action_pressed("grab"):
		_attempt_pull(dir)
		return

	facing = dir
	_update_sprite()

	var target := cell + dir

	# Don't let a diagonal step squeeze between two wall corners.
	if not cardinal:
		if room.is_wall(cell + Vector2i(dir.x, 0)) and room.is_wall(cell + Vector2i(0, dir.y)):
			return

	var door: String = room.door_dir_for(target)
	if door != "":
		RoomManager.use_exit(door)
		return
	if room.is_wall(target) or room.npc_at(target) != null:
		return   # bump — facing is set so we can still interact

	var crate = room.crate_at(target)
	if crate != null:
		if not cardinal:
			return   # crates only push along cardinals
		var beyond := target + dir
		if room.can_crate_enter(beyond):
			room.move_crate(target, beyond)
			_step(target)
		return

	_step(target)


## Pull: grip the crate we're facing and back straight out of it.
func _attempt_pull(dir: Vector2i) -> void:
	var front := cell + facing
	if room.crate_at(front) == null:
		return
	if dir != -facing:
		return
	var back := cell + dir
	if room.is_wall(back) or room.door_dir_for(back) != "":
		return
	if room.crate_at(back) != null or room.npc_at(back) != null:
		return
	room.move_crate(front, cell)   # crate slides into the cell we vacate
	_step(back)


func _step(target: Vector2i) -> void:
	_busy = true
	cell = target
	var tw := create_tween()
	tw.tween_property(self, "position", Grid.cell_to_pos(target), STEP_TIME)
	await tw.finished
	_busy = false
	if room != null:
		room.collect_item(cell)


func _unhandled_input(event: InputEvent) -> void:
	if _locked_out():
		return
	if event.is_action_pressed("interact"):
		var n = room.npc_at(cell + facing)
		if n != null:
			DialogueManager.start(n)
			get_viewport().set_input_as_handled()
