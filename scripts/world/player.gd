class_name Player
extends Node2D
## Grid-locked, push/pull movement. No dash, no combat (per the locked spec).
## Walk into a crate to push it; hold Grab and back straight away to pull it.

const STEP_TIME := 0.10

var cell: Vector2i
var facing := Vector2i.DOWN
var room   # Room

var _busy := false


func _ready() -> void:
	z_index = 20


func place(c: Vector2i) -> void:
	cell = c
	position = Grid.cell_to_pos(c)
	queue_redraw()


func _process(_delta: float) -> void:
	if _busy or _locked_out():
		return
	var dir := _read_dir()
	if dir != Vector2i.ZERO:
		_attempt(dir)


func _locked_out() -> bool:
	return room == null or DialogueManager.active or RoomManager.is_busy()


func _read_dir() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _attempt(dir: Vector2i) -> void:
	if Input.is_action_pressed("grab"):
		_attempt_pull(dir)
		return

	facing = dir
	queue_redraw()

	var target := cell + dir
	var door: String = room.door_dir_for(target)
	if door != "":
		RoomManager.use_exit(door)
		return
	if room.is_wall(target) or room.npc_at(target) != null:
		return   # bump — facing is set so we can still interact

	var crate = room.crate_at(target)
	if crate != null:
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


func _draw() -> void:
	var s := float(Grid.TILE)
	var half := s * 0.5
	var body := Rect2(-half + 2, -half + 2, s - 4, s - 4)
	draw_rect(body, Color("d6e0ea"))
	draw_rect(body, Color("3a4a63"), false, 1.0)
	var f := Vector2(facing)
	draw_rect(Rect2(f.x * 4.0 - 2.0, f.y * 4.0 - 2.0, 4, 4), Color("e85a3a"))
