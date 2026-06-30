class_name Room
extends Node2D
## One screen of the station, built from a RoomDB entry. Owns its walls, doors,
## crates, pressure-plate puzzle, NPC markers, item pickups and security cameras.
## Placeholder art only — everything is drawn from code so the slice runs with
## zero asset imports.

var room_id: StringName = &""
var exits: Dictionary = {}

var _data: Dictionary = {}
var _floor := RoomDB.FLOOR
var _wall := RoomDB.WALL
var _plates: Array = []
var _puzzle: Dictionary = {}

var _crates: Dictionary = {}   # Vector2i -> Pushable
var _npcs: Dictionary = {}     # Vector2i -> npc dict
var _items: Dictionary = {}    # Vector2i -> { item: StringName }
var _cameras: Array = []
var _cam_time := 0.0


func setup(id: StringName, data: Dictionary) -> void:
	room_id = id
	_data = data
	exits = data.get("exits", {})
	_floor = data.get("floor", RoomDB.FLOOR)
	_wall = data.get("wall", RoomDB.WALL)
	_plates = data.get("plates", [])
	_puzzle = data.get("puzzle", {})

	for c in data.get("crates", []):
		var crate := Pushable.new()
		crate.setup(c)
		add_child(crate)
		_crates[c] = crate

	for n in data.get("npcs", []):
		_npcs[n["cell"]] = n

	for it in data.get("items", []):
		if GameState.has_flag(_taken_flag(it["item"])):
			continue
		if it.has("require_flag") and not GameState.has_flag(it["require_flag"]):
			continue
		_items[it["cell"]] = {"item": it["item"]}

	for cam in data.get("cameras", []):
		_cameras.append({
			"cell": cam["cell"],
			"facing": Grid.dir_vec(cam["facing"]),
			"range": int(cam.get("range", 5)),
			"on": float(cam.get("on", 1.5)),
			"off": float(cam.get("off", 1.5)),
			"phase": float(cam.get("phase", 0.0)),
		})

	# Puzzle solved on a previous visit? The solve flag persists; reopen the cache.
	if not _puzzle.is_empty() and GameState.has_flag(_puzzle.get("solve_flag", &"")):
		_open_cache()

	queue_redraw()


# --- queries used by the Player ------------------------------------------------

func start_cell() -> Vector2i:
	return _data.get("start_cell", Vector2i(Grid.COLS / 2, Grid.ROWS / 2))


func is_wall(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= Grid.COLS or c.y >= Grid.ROWS:
		return true
	var border := c.x == 0 or c.y == 0 or c.x == Grid.COLS - 1 or c.y == Grid.ROWS - 1
	if border:
		return door_dir_for(c) == ""
	return false


func door_dir_for(c: Vector2i) -> String:
	if c.y == 0 and exits.has("north") and c.x in Grid.NS_DOOR_COLS:
		return "north"
	if c.y == Grid.ROWS - 1 and exits.has("south") and c.x in Grid.NS_DOOR_COLS:
		return "south"
	if c.x == 0 and exits.has("west") and c.y in Grid.EW_DOOR_ROWS:
		return "west"
	if c.x == Grid.COLS - 1 and exits.has("east") and c.y in Grid.EW_DOOR_ROWS:
		return "east"
	return ""


func crate_at(c: Vector2i):
	return _crates.get(c, null)


func npc_at(c: Vector2i):
	return _npcs.get(c, null)


func item_at(c: Vector2i):
	return _items.get(c, null)


func can_crate_enter(c: Vector2i) -> bool:
	if is_wall(c) or door_dir_for(c) != "":
		return false
	if _crates.has(c) or _npcs.has(c):
		return false
	return true


func move_crate(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var crate = _crates.get(from_cell)
	if crate == null:
		return
	_crates.erase(from_cell)
	_crates[to_cell] = crate
	crate.move_to(to_cell)
	_evaluate_puzzle()
	queue_redraw()


func collect_item(c: Vector2i) -> void:
	var it = _items.get(c)
	if it == null:
		return
	Inventory.add(it["item"])
	GameState.set_flag(_taken_flag(it["item"]))
	_items.erase(c)
	queue_redraw()
	if RoomManager.hud:
		RoomManager.hud.status("Picked up: " + ItemDB.item_name(it["item"]))


# --- puzzle --------------------------------------------------------------------

func _evaluate_puzzle() -> void:
	if _puzzle.is_empty() or GameState.has_flag(_puzzle["solve_flag"]):
		return
	for p in _plates:
		if not _crates.has(p):
			return
	GameState.set_flag(_puzzle["solve_flag"])
	if RoomManager.hud:
		RoomManager.hud.status("A wall panel slides open with a pneumatic hiss.")
	_open_cache()


func _open_cache() -> void:
	var reward: Dictionary = _puzzle.get("reward", {})
	if reward.is_empty():
		return
	var item: StringName = reward["item"]
	if not GameState.has_flag(_taken_flag(item)):
		_items[reward["cell"]] = {"item": item}
	queue_redraw()


func _taken_flag(item: StringName) -> StringName:
	return StringName("taken_" + String(item))


# --- cameras -------------------------------------------------------------------

func _process(delta: float) -> void:
	if _cameras.is_empty():
		return
	_cam_time += delta
	queue_redraw()
	if RoomManager.is_busy() or DialogueManager.active:
		return
	var p = RoomManager.player
	if p == null:
		return
	for cam in _cameras:
		if not _cam_armed(cam):
			continue
		if p.cell in _camera_cells(cam):
			GameState.trigger_caught()
			return


func _cam_armed(cam: Dictionary) -> bool:
	var period: float = cam["on"] + cam["off"]
	if period <= 0.0:
		return true
	return fmod(_cam_time + cam["phase"], period) < cam["on"]


func _camera_cells(cam: Dictionary) -> Array:
	var out: Array = []
	for i in range(1, cam["range"] + 1):
		var c: Vector2i = cam["cell"] + cam["facing"] * i
		if is_wall(c):
			break
		out.append(c)
	return out


# --- rendering (placeholder) ---------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Grid.SCREEN), _floor)

	for x in range(Grid.COLS):
		_draw_border_cell(Vector2i(x, 0))
		_draw_border_cell(Vector2i(x, Grid.ROWS - 1))
	for y in range(Grid.ROWS):
		_draw_border_cell(Vector2i(0, y))
		_draw_border_cell(Vector2i(Grid.COLS - 1, y))

	for p in _plates:
		_draw_plate(p)
	if not _puzzle.is_empty() and GameState.has_flag(_puzzle.get("solve_flag", &"")):
		_draw_cache()
	for c in _items:
		_draw_item(c, _items[c])
	for c in _npcs:
		_draw_npc(c, _npcs[c])
	for cam in _cameras:
		_draw_camera(cam)
	_draw_door_marks()


func _tile_rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * Grid.TILE, c.y * Grid.TILE, Grid.TILE, Grid.TILE)


func _draw_border_cell(c: Vector2i) -> void:
	var r := _tile_rect(c)
	if is_wall(c):
		draw_rect(r, _wall)
		draw_line(r.position, r.position + Vector2(Grid.TILE, 0), _wall.lightened(0.2), 1.0)
	else:
		draw_rect(r, _floor.lightened(0.10))


func _draw_plate(p: Vector2i) -> void:
	var pressed := _crates.has(p)
	draw_rect(_tile_rect(p).grow(-3), Color("e8a23a") if pressed else Color("6e5a3a"))
	draw_rect(_tile_rect(p).grow(-2), Color("3a2e1a"), false, 1.0)


func _draw_cache() -> void:
	var rc: Vector2i = _puzzle.get("reward", {}).get("cell", Vector2i(10, 2))
	var r := _tile_rect(rc).grow(-1)
	draw_rect(r, Color("12303a"))
	draw_rect(r, Color("4ad6e8"), false, 1.0)


func _draw_item(c: Vector2i, it: Dictionary) -> void:
	var r := _tile_rect(c).grow(-4)
	draw_rect(r, ItemDB.item_color(it["item"]))
	draw_rect(r, Color.WHITE, false, 1.0)


func _draw_npc(c: Vector2i, n: Dictionary) -> void:
	var r := _tile_rect(c).grow(-2)
	draw_rect(r, n.get("color", Color("6e7a8a")))
	draw_rect(Rect2(r.position + Vector2(3, 1), Vector2(r.size.x - 6, 4)), Color("e0c9a6"))
	draw_rect(r, Color("10141c"), false, 1.0)


func _draw_camera(cam: Dictionary) -> void:
	var armed := _cam_armed(cam)
	var cone := Color(0.9, 0.2, 0.2, 0.28) if armed else Color(0.4, 0.4, 0.5, 0.12)
	for c in _camera_cells(cam):
		draw_rect(_tile_rect(c), cone)
	draw_rect(_tile_rect(cam["cell"]).grow(-3), Color("c0c4cc"))
	var f := Vector2(cam["facing"])
	draw_circle(Grid.cell_to_pos(cam["cell"]) + f * 4.0, 2.0, Color(0.9, 0.2, 0.2) if armed else Color(0.3, 0.3, 0.35))


func _draw_door_marks() -> void:
	for side in exits.keys():
		var col := Color("8a2a2a") if _is_locked(side) else Color("3a6e7a")
		for c in _door_cells(side):
			draw_rect(_tile_rect(c).grow(-5), col)


func _is_locked(side: String) -> bool:
	var lock = exits.get(side, {}).get("lock")
	if lock == null:
		return false
	if lock.has("flag") and not GameState.has_flag(lock["flag"]):
		return true
	if lock.has("item") and not Inventory.has(lock["item"]):
		return true
	return false


func _door_cells(side: String) -> Array:
	match side:
		"north": return [Vector2i(9, 0), Vector2i(10, 0)]
		"south": return [Vector2i(9, Grid.ROWS - 1), Vector2i(10, Grid.ROWS - 1)]
		"west": return [Vector2i(0, 7), Vector2i(0, 8)]
		"east": return [Vector2i(Grid.COLS - 1, 7), Vector2i(Grid.COLS - 1, 8)]
	return []
