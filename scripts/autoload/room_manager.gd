extends Node
## Builds rooms from RoomDB, handles screen-to-screen transitions, door locks,
## and respawn-on-caught. Autoload singleton: "RoomManager".
##
## Rooms are rebuilt fresh from data on every entry, so crates and puzzle layout
## reset automatically when you leave and come back (the soft-lock guard).

var world: Node2D
var player   # Player
var hud      # Hud
var current_room   # Room
var current_id: StringName = &""

var _transitioning := false


func setup(world_node: Node2D, player_node, hud_node) -> void:
	world = world_node
	player = player_node
	hud = hud_node


func is_busy() -> bool:
	return _transitioning


func start_game() -> void:
	_swap_room(&"A1", "start")
	_after_enter(&"A1", "start")


## Called by the Player when it walks into an open door gap.
func use_exit(side: String) -> void:
	if _transitioning or current_room == null:
		return
	var ex: Variant = current_room.exits.get(side)
	if ex == null:
		return
	var lock: Variant = ex.get("lock")
	if lock != null and not _lock_open(lock):
		if hud:
			hud.status(lock.get("msg", "Locked."))
		return
	_slide_to(ex["to"], Grid.opposite(side), side)


func _lock_open(lock: Dictionary) -> bool:
	if lock.has("flag") and not GameState.has_flag(lock["flag"]):
		return false
	if lock.has("item") and not Inventory.has(lock["item"]):
		return false
	return true


func respawn_at_checkpoint() -> void:
	if _transitioning:
		return
	_caught_sequence()


func _caught_sequence() -> void:
	_transitioning = true
	if hud:
		hud.status("CAUGHT! Escorted back.")
		await hud.fade_to(1.0, 0.22)
	_swap_room(GameState.checkpoint_room, GameState.checkpoint_side)
	_after_enter(GameState.checkpoint_room, GameState.checkpoint_side)
	if hud:
		await hud.fade_to(0.0, 0.22)
	_transitioning = false


## Instant build at origin (used for game start and caught-respawn).
func _swap_room(room_id: StringName, enter_side: String) -> void:
	var data: Dictionary = RoomDB.get_room(room_id)
	var room := Room.new()
	room.setup(room_id, data)
	world.add_child(room)
	room.position = Vector2.ZERO
	if current_room != null:
		current_room.queue_free()
	current_room = room
	current_id = room_id
	player.room = room
	player.place(_spawn_for(room, enter_side))
	world.position = Vector2.ZERO


func _spawn_for(room, enter_side: String) -> Vector2i:
	if enter_side == "start":
		return room.start_cell()
	return Grid.spawn_cell_for(enter_side)


func _after_enter(room_id: StringName, enter_side: String) -> void:
	var data: Dictionary = RoomDB.get_room(room_id)
	if not data.get("hazard", false):
		GameState.set_checkpoint(room_id, enter_side)
	if hud:
		hud.set_room_label(data.get("name", str(room_id)), room_id)


## Zelda-style slide: the next room enters from the travel direction while the
## whole world scrolls one screen over.
func _slide_to(room_id: StringName, enter_side: String, travel_side: String) -> void:
	_transitioning = true
	var data: Dictionary = RoomDB.get_room(room_id)
	var next := Room.new()
	next.setup(room_id, data)
	var offset := Vector2(Grid.dir_vec(travel_side)) * Grid.SCREEN
	next.position = offset
	world.add_child(next)

	var spawn := Grid.spawn_cell_for(enter_side)
	player.room = next
	player.place(spawn)
	player.position += offset

	var old = current_room
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(world, "position", -offset, 0.40)
	await tw.finished

	if old != null:
		old.queue_free()
	next.position = Vector2.ZERO
	player.position = Grid.cell_to_pos(spawn)
	world.position = Vector2.ZERO
	current_room = next
	current_id = room_id
	_transitioning = false
	_after_enter(room_id, enter_side)
