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
var _amb := 0.0                # ambient clock for item glow / hazard pulse
var _hazard := false


func setup(id: StringName, data: Dictionary) -> void:
	room_id = id
	_data = data
	exits = data.get("exits", {})
	_floor = data.get("floor", RoomDB.FLOOR)
	_wall = data.get("wall", RoomDB.WALL)
	_plates = data.get("plates", [])
	_puzzle = data.get("puzzle", {})
	_hazard = bool(data.get("hazard", false))
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

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
	_amb += delta
	# Repaint when something is alive on screen (camera cones, glowing pickups,
	# hazard alarm wash). Static rooms only repaint on entry, so this stays cheap.
	if not _cameras.is_empty() or not _items.is_empty() or _hazard:
		queue_redraw()

	if _cameras.is_empty():
		return
	_cam_time += delta
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


# --- rendering -----------------------------------------------------------------

func _draw() -> void:
	# Dithered metal deck, tiled across the whole screen.
	draw_texture_rect(PixelArt.floor_texture(_floor), Rect2(Vector2.ZERO, Grid.SCREEN), true)

	# Beveled, riveted wall plates around the border (door gaps left open).
	var wall_tex := PixelArt.wall_texture(_wall)
	for x in range(Grid.COLS):
		_draw_border_cell(Vector2i(x, 0), wall_tex)
		_draw_border_cell(Vector2i(x, Grid.ROWS - 1), wall_tex)
	for y in range(Grid.ROWS):
		_draw_border_cell(Vector2i(0, y), wall_tex)
		_draw_border_cell(Vector2i(Grid.COLS - 1, y), wall_tex)

	_draw_door_marks()

	# Set dressing — fill the deck with themed "space stuff" (wall-mounted gear +
	# flat floor decals). Drawn under the interactive layer below.
	Decor.paint(self, room_id, _data, _occupied_cells(), 0.5 + 0.5 * sin(_amb * 2.0))

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

	_draw_atmosphere()


func _tile_rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * Grid.TILE, c.y * Grid.TILE, Grid.TILE, Grid.TILE)


## Interior cells that gameplay owns — decor must not paint over these.
func _occupied_cells() -> Dictionary:
	var occ: Dictionary = {}
	for c in _npcs:
		occ[c] = true
	for c in _items:
		occ[c] = true
	for c in _crates:
		occ[c] = true
	for p in _plates:
		occ[p] = true
	for cam in _cameras:
		occ[cam["cell"]] = true
	if not _puzzle.is_empty():
		occ[_puzzle.get("reward", {}).get("cell", Vector2i(10, 2))] = true
	return occ


func _draw_border_cell(c: Vector2i, wall_tex: Texture2D) -> void:
	var r := _tile_rect(c)
	if is_wall(c):
		draw_texture(wall_tex, r.position)
	else:
		# Door threshold: a lit floor lip so openings read as passable.
		draw_rect(r, _floor.lightened(0.16))
		draw_rect(r, _floor.darkened(0.3), false, 1.0)


func _draw_plate(p: Vector2i) -> void:
	var pressed := _crates.has(p)
	var r := _tile_rect(p)
	draw_rect(r.grow(-2), Color("2a2214"))
	var face := r.grow(-3)
	draw_rect(face, Color("e8a23a") if pressed else Color("6e5a3a"))
	# Inset bevel: dark bottom-right, light top-left.
	draw_rect(face, Color("3a2e1a"), false, 1.0)
	draw_line(face.position, face.position + Vector2(face.size.x, 0), Color("ffd27a") if pressed else Color("8a7048"), 1.0)
	if pressed:
		draw_rect(r.grow(-1), Color(0.95, 0.7, 0.25, 0.10))   # glow when held


func _draw_cache() -> void:
	var rc: Vector2i = _puzzle.get("reward", {}).get("cell", Vector2i(10, 2))
	var r := _tile_rect(rc)
	draw_rect(r.grow(-1), Color("0c2028"))
	draw_rect(r.grow(-3), Color("12303a"))
	draw_rect(r.grow(-1), Color("4ad6e8"), false, 1.0)
	draw_line(r.position + Vector2(2, 2), r.position + Vector2(Grid.TILE - 2, 2), Color("7ae8f4"), 1.0)


func _draw_item(c: Vector2i, it: Dictionary) -> void:
	var center := Grid.cell_to_pos(c) + Vector2(0, sin(_amb * 2.2) * 1.0)   # gentle bob
	PixelArt.draw_item(self, center, ItemDB.item_color(it["item"]), 0.5 + 0.5 * sin(_amb * 3.0))


func _draw_npc(c: Vector2i, n: Dictionary) -> void:
	var t := Transform2D(0.0, Grid.cell_to_pos(c))
	draw_set_transform_matrix(t)
	var col: Color = n.get("color", Color("6e7a8a"))
	PixelArt.draw_actor(self, col, Vector2i.DOWN, col.lightened(0.45), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_camera(cam: Dictionary) -> void:
	var armed := _cam_armed(cam)
	var pulse := 0.5 + 0.5 * sin(_amb * 8.0)
	var cone := Color(0.95, 0.2, 0.2, 0.20 + 0.12 * pulse) if armed else Color(0.45, 0.5, 0.62, 0.10)
	for c in _camera_cells(cam):
		draw_rect(_tile_rect(c), cone)
	# Housing.
	var hr := _tile_rect(cam["cell"]).grow(-3)
	draw_rect(hr, Color("c0c4cc"))
	draw_rect(hr, Color("6a6e78"), false, 1.0)
	draw_rect(Rect2(hr.position, Vector2(hr.size.x, 1)), Color("e6e8ee"))
	# Lens (red when armed).
	var f := Vector2(cam["facing"])
	var lens := Grid.cell_to_pos(cam["cell"]) + f * 4.0
	draw_circle(lens, 2.5, Color(0.95, 0.15, 0.15) if armed else Color(0.28, 0.3, 0.36))
	if armed:
		draw_circle(lens, 4.0 + pulse * 1.5, Color(0.95, 0.2, 0.2, 0.18))


func _draw_door_marks() -> void:
	for side in exits.keys():
		var locked := _is_locked(side)
		for c in _door_cells(side):
			var r := _tile_rect(c)
			# Frame.
			draw_rect(r.grow(-2), Color("10141c"))
			var col := Color("7a2424") if locked else Color("2f5a64")
			draw_rect(r.grow(-4), col)
			# Status light strip.
			var light := Color("ff4a4a") if locked else Color("5ad6c4")
			draw_rect(Rect2(r.position + Vector2(5, 3), Vector2(Grid.TILE - 10, 2)), light)


func _draw_atmosphere() -> void:
	# Cool fluorescent wash from the ceiling.
	draw_rect(Rect2(Vector2(0, Grid.TILE), Vector2(Grid.SCREEN.x, 6)), Color(0.7, 0.85, 1.0, 0.05))
	# Hazard rooms breathe an orange/red alarm tint (stronger when a camera is armed).
	if _hazard:
		var armed := false
		for cam in _cameras:
			if _cam_armed(cam):
				armed = true
				break
		var base_a := 0.10 + 0.04 * (0.5 + 0.5 * sin(_amb * 2.0))
		var a := 0.22 + 0.10 * (0.5 + 0.5 * sin(_amb * 8.0)) if armed else base_a
		draw_rect(Rect2(Vector2.ZERO, Grid.SCREEN), Color(0.9, 0.25, 0.15, a))
	# Edge vignette for depth.
	draw_texture(PixelArt.vignette(), Vector2.ZERO)


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
