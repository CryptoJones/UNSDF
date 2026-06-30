class_name Decor
extends RefCounted
## Set dressing — the "space stuff" that fills a room so it reads like a lived-in
## station deck instead of an empty box. Everything here is either WALL-MOUNTED
## (drawn on the non-walkable border tiles, like Zelda lining its dungeon walls
## with statues and torches) or a FLAT FLOOR DECAL (meant to be walked over).
## Nothing collides, so the critical path and the D2 puzzle are never affected.
##
## Each room maps to a theme: an accent colour, a cycle of props for the back and
## side walls, and a floor-decal style. Placement is deterministic (hashed by
## room + cell) so a room looks the same every visit but distinct from its
## neighbours.

const TILE := 16

# room id -> { accent, back:[tokens], side:[tokens], floor:token }
const THEMES := {
	&"A1": {"accent": "5ad6e8", "back": ["screen", "panel", "screen", "lights"], "side": ["pipe", "locker"], "floor": "mat"},
	&"A2": {"accent": "ff5a4a", "back": ["screen", "screen", "console", "screen"], "side": ["screen", "pipe"], "floor": "caution"},
	&"A3": {"accent": "e8a23a", "back": ["pipe", "vent", "panel", "pipe"], "side": ["pipe", "conduit"], "floor": "grate"},
	&"A4": {"accent": "8a96a8", "back": ["locker", "crate", "locker", "crate"], "side": ["locker", "pipe"], "floor": "grate"},
	&"B1": {"accent": "6ad6c4", "back": ["screen", "lights", "panel", "lights"], "side": ["pipe", "screen"], "floor": "mat"},
	&"B2": {"accent": "e8a23a", "back": ["crate", "conduit", "crate", "pipe"], "side": ["conduit", "crate"], "floor": "caution"},
	&"B3": {"accent": "7a96a8", "back": ["pipe", "vent", "pipe", "vent"], "side": ["pipe", "pipe"], "floor": "grate"},
	&"B4": {"accent": "ff5a4a", "back": ["panel", "lights", "panel", "lights"], "side": ["pipe", "panel"], "floor": "caution"},
	&"C1": {"accent": "8a7a3a", "back": ["barrel", "pipe", "barrel", "vent"], "side": ["pipe", "barrel"], "floor": "stain"},
	&"C2": {"accent": "ff8a3a", "back": ["console", "tank", "pipe", "tank"], "side": ["pipe", "console"], "floor": "reactor"},
	&"C3": {"accent": "5ad6e8", "back": ["crate", "console", "crate", "lights"], "side": ["crate", "pipe"], "floor": "mat"},
	&"C4": {"accent": "ff8a3a", "back": ["tank", "panel", "tank", "pipe"], "side": ["tank", "pipe"], "floor": "caution"},
	&"D1": {"accent": "5ae8a0", "back": ["tank", "pipe", "tank", "vent"], "side": ["pipe", "tank"], "floor": "reactor"},
	&"D2": {"accent": "6ab4e8", "back": ["crate", "crate", "console", "crate"], "side": ["crate", "pipe"], "floor": "grate"},
	&"D3": {"accent": "8ad6ff", "back": ["dish", "screen", "console", "dish"], "side": ["pipe", "screen"], "floor": "grate"},
	&"D4": {"accent": "ffce4a", "back": ["panel", "lights", "console", "lights"], "side": ["pipe", "panel"], "floor": "caution"},
}


static func paint(ci: CanvasItem, room_id: StringName, data: Dictionary, occupied: Dictionary, glow: float) -> void:
	var theme: Dictionary = THEMES.get(room_id, THEMES[&"A3"])
	var accent := Color(theme["accent"])
	var seed: int = abs(hash(room_id))
	var exits: Dictionary = data.get("exits", {})

	_macro_grid(ci, seed)
	_walkways(ci, accent, exits)
	_central_feature(ci, theme["floor"], accent, occupied, glow, seed)
	_floor(ci, room_id, theme, accent, exits, occupied, glow, seed)
	_grounding_shadow(ci)
	_back_wall(ci, theme, accent, exits, glow, seed)
	_side_walls(ci, theme, accent, exits, glow, seed)
	_bottom_wall(ci, accent, exits, seed)


# --- macro floor: big plate grid + walkways -----------------------------------

## Heavy seams every two tiles read as large welded deck plates, with bolts at
## the intersections. This alone turns the uniform field into a built floor.
static func _macro_grid(ci: CanvasItem, seed: int) -> void:
	var seam := Color(0.04, 0.05, 0.07, 0.55)
	var bolt := Color(0.62, 0.68, 0.74, 0.22)
	for gx in range(2, Grid.COLS - 1, 2):
		ci.draw_rect(Rect2(gx * TILE, TILE, 1, Grid.SCREEN.y - TILE * 2), seam)
	for gy in range(3, Grid.ROWS - 1, 2):
		ci.draw_rect(Rect2(TILE, gy * TILE, Grid.SCREEN.x - TILE * 2, 1), seam)
	for gx in range(2, Grid.COLS - 1, 2):
		for gy in range(3, Grid.ROWS - 1, 2):
			ci.draw_rect(Rect2(gx * TILE - 1, gy * TILE - 1, 2, 2), bolt)
	# A scatter of darker accent plates for tonal variation.
	for y in range(1, Grid.ROWS - 1):
		for x in range(1, Grid.COLS - 1):
			if abs(hash(Vector2i(x, y) * 31 + Vector2i(seed, seed))) % 9 == 0:
				ci.draw_rect(Rect2(x * TILE + 1, y * TILE + 1, TILE - 1, TILE - 1), Color(0, 0, 0, 0.16))


## Lighter painted walkway lanes that link the doors through the room, edged with
## dashed safety lines — the eye reads circulation, so the space feels designed.
static func _walkways(ci: CanvasItem, accent: Color, exits: Dictionary) -> void:
	var lane := Color(0.62, 0.70, 0.80, 0.05)
	var cx := Grid.COLS / 2
	var cy := Grid.ROWS / 2
	# Cross lanes through the centre.
	var vlane := Rect2((cx - 1) * TILE, TILE, 3 * TILE, Grid.SCREEN.y - TILE * 2)
	var hlane := Rect2(TILE, (cy - 1) * TILE, Grid.SCREEN.x - TILE * 2, 3 * TILE)
	ci.draw_rect(vlane, lane)
	ci.draw_rect(hlane, lane)
	# Dashed safety edging on the horizontal lane.
	for x in range(2, Grid.COLS - 2):
		if x % 2 == 0:
			ci.draw_rect(Rect2(x * TILE + 2, (cy - 1) * TILE, 8, 1), Color(0.9, 0.72, 0.2, 0.30))
			ci.draw_rect(Rect2(x * TILE + 2, (cy + 2) * TILE - 1, 8, 1), Color(0.9, 0.72, 0.2, 0.30))


# --- central feature: a themed centrepiece ------------------------------------

static func _central_feature(ci: CanvasItem, kind: String, accent: Color, occupied: Dictionary, glow: float, seed: int) -> void:
	var cx := Grid.SCREEN.x * 0.5
	var cy := Grid.SCREEN.y * 0.5
	# Don't stamp a big centrepiece over a puzzle/NPC that lives at the centre.
	if occupied.has(Vector2i(Grid.COLS / 2, Grid.ROWS / 2)):
		return
	match kind:
		"reactor": _feature_reactor(ci, cx, cy, accent, glow)
		"caution": _feature_loadpad(ci, cx, cy)
		"grate": _feature_trench(ci, cx, cy, accent)
		"stain": _feature_pit(ci, cx, cy)
		_: _feature_holotable(ci, cx, cy, accent, glow)


static func _feature_reactor(ci: CanvasItem, cx: float, cy: float, accent: Color, glow: float) -> void:
	for i in range(4, 0, -1):
		var r := i * 7.0
		var a := 0.10 + 0.06 * (4 - i) + 0.10 * glow
		ci.draw_circle(Vector2(cx, cy), r, Color(accent.r, accent.g, accent.b, a))
	ci.draw_circle(Vector2(cx, cy), 28.0, Color("0a0e14"))
	ci.draw_circle(Vector2(cx, cy), 26.0, Color(accent.r, accent.g, accent.b, 0.18))
	ci.draw_circle(Vector2(cx, cy), 10.0 + 2.0 * glow, accent * (0.7 + 0.4 * glow))
	# Spokes.
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		ci.draw_rect(Rect2(cx + d.x * 26 - 2, cy + d.y * 26 - 2, 4, 4), Color("3a4654"))
	ci.draw_arc(Vector2(cx, cy), 28.0, 0, TAU, 24, accent.darkened(0.2), 1.0)


static func _feature_holotable(ci: CanvasItem, cx: float, cy: float, accent: Color, glow: float) -> void:
	ci.draw_rect(Rect2(cx - 22, cy - 12, 44, 26), Color("1a222e"))           # base
	ci.draw_rect(Rect2(cx - 22, cy - 12, 44, 2), Color("32404e"))
	ci.draw_rect(Rect2(cx - 22, cy + 12, 44, 2), Color("0c1018"))
	ci.draw_rect(Rect2(cx - 18, cy - 8, 36, 16), Color("0a0e14"))            # well
	# Projected hologram.
	ci.draw_circle(Vector2(cx, cy), 12.0, Color(accent.r, accent.g, accent.b, 0.14 + 0.10 * glow))
	for i in 3:
		ci.draw_arc(Vector2(cx, cy - 2), 4.0 + i * 3.0, 0, TAU, 16, Color(accent.r, accent.g, accent.b, 0.5 * glow), 1.0)


static func _feature_loadpad(ci: CanvasItem, cx: float, cy: float) -> void:
	var r := Rect2(cx - 40, cy - 24, 80, 48)
	ci.draw_rect(r, Color(0.05, 0.05, 0.06, 0.35))
	# Hazard-striped border.
	for i in range(0, 80, 8):
		ci.draw_rect(Rect2(cx - 40 + i, cy - 24, 4, 3), Color("e8b23a"))
		ci.draw_rect(Rect2(cx - 40 + i, cy + 21, 4, 3), Color("e8b23a"))
	# Corner brackets.
	for c in [Vector2(-40, -24), Vector2(36, -24), Vector2(-40, 21), Vector2(36, 21)]:
		ci.draw_rect(Rect2(cx + c.x, cy + c.y, 4, 8), Color("c0c4cc"))
		ci.draw_rect(Rect2(cx + c.x, cy + c.y, 8, 4), Color("c0c4cc"))


static func _feature_trench(ci: CanvasItem, cx: float, cy: float, accent: Color) -> void:
	var r := Rect2(cx - 36, cy - 8, 72, 16)
	ci.draw_rect(r, Color(0.03, 0.04, 0.05, 0.7))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color("32404e"))   # rail
	ci.draw_rect(Rect2(r.position + Vector2(0, 14), Vector2(r.size.x, 2)), Color("12161e"))
	for x in range(0, 72, 4):
		ci.draw_rect(Rect2(cx - 36 + x, cy - 6, 1, 12), Color(accent.r, accent.g, accent.b, 0.12))


static func _feature_pit(ci: CanvasItem, cx: float, cy: float) -> void:
	ci.draw_circle(Vector2(cx, cy), 26.0, Color(0.02, 0.03, 0.02, 0.6))
	ci.draw_circle(Vector2(cx, cy), 18.0, Color(0.0, 0.0, 0.0, 0.55))
	for a in range(0, 360, 30):
		var v := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a)))
		ci.draw_rect(Rect2(Vector2(cx, cy) + v * 22 - Vector2(1, 1), Vector2(2, 2)), Color("3a3a2e"))
	ci.draw_arc(Vector2(cx, cy), 26.0, 0, TAU, 24, Color("4a4a3a"), 1.0)


# --- floor decals (flat, walkable) --------------------------------------------

static func _floor(ci: CanvasItem, _room_id: StringName, theme: Dictionary, accent: Color, exits: Dictionary, occupied: Dictionary, glow: float, seed: int) -> void:
	# Hazard chevrons fanning inward from every door (an entry threshold).
	for side in exits.keys():
		for c in _door_inner_cells(side):
			if occupied.has(c):
				continue
			_chevron(ci, c, _dir(side), Color("e8b23a"))

	var kind: String = theme["floor"]
	var cmid := Vector2i(Grid.COLS / 2, Grid.ROWS / 2)
	for y in range(1, Grid.ROWS - 1):
		for x in range(1, Grid.COLS - 1):
			var c := Vector2i(x, y)
			if occupied.has(c):
				continue
			# Keep the central feature's footprint clear.
			if absi(x - cmid.x) <= 2 and absi(y - cmid.y) <= 2:
				continue
			var h: int = abs(hash(Vector2i(x * 7, y * 13) + Vector2i(seed, 0)))
			# Themed base texture (denser than before, higher contrast).
			match kind:
				"grate":
					if (x + y) % 2 == 0 and h % 3 < 2:
						_grate(ci, c)
				"stain":
					if h % 4 == 0:
						_stain(ci, c, Color(0.07, 0.06, 0.03, 0.55))
					elif h % 4 == 2:
						_grate(ci, c)
				"reactor":
					if h % 5 == 0:
						_grate(ci, c)
					elif h % 7 == 0:
						_floor_light(ci, c, accent, glow)
				"caution":
					if h % 6 == 0:
						_grate(ci, c)
				_:  # "mat"
					if h % 6 == 0:
						_floor_light(ci, c, accent, glow)
			# A second, theme-agnostic pass of hard clutter for fill + contrast.
			var hc := (h >> 3) % 13
			match hc:
				0, 1: _floor_hatch(ci, c)
				2: _floor_vent(ci, c)
				3: _cable_tray(ci, c, accent, h)
				4: _pallet(ci, c)
				5: _stencil(ci, c, h)


static func _grounding_shadow(ci: CanvasItem) -> void:
	# Soft shadow along the base of the back wall so the furniture sits on the deck.
	ci.draw_rect(Rect2(TILE, TILE, Grid.SCREEN.x - TILE * 2, 3), Color(0, 0, 0, 0.22))


# --- wall furniture ------------------------------------------------------------

static func _back_wall(ci: CanvasItem, theme: Dictionary, accent: Color, exits: Dictionary, glow: float, seed: int) -> void:
	var pattern: Array = theme["back"]
	for x in range(1, Grid.COLS - 1):
		if x in Grid.NS_DOOR_COLS and exits.has("north"):
			continue
		var token: String = pattern[(x + seed) % pattern.size()]
		_prop(ci, token, Vector2i(x, 0), accent, glow, seed)


static func _side_walls(ci: CanvasItem, theme: Dictionary, accent: Color, exits: Dictionary, glow: float, seed: int) -> void:
	var pattern: Array = theme["side"]
	for y in range(1, Grid.ROWS - 1):
		if y in Grid.EW_DOOR_ROWS and exits.has("west"):
			pass
		else:
			_prop(ci, pattern[(y + seed) % pattern.size()], Vector2i(0, y), accent, glow, seed)
		if y in Grid.EW_DOOR_ROWS and exits.has("east"):
			pass
		else:
			_prop(ci, pattern[(y + seed + 1) % pattern.size()], Vector2i(Grid.COLS - 1, y), accent, glow, seed)


static func _bottom_wall(ci: CanvasItem, accent: Color, exits: Dictionary, seed: int) -> void:
	for x in range(1, Grid.COLS - 1):
		if x in Grid.NS_DOOR_COLS and exits.has("south"):
			continue
		# A conduit run with occasional status lights along the bottom wall.
		var c := Vector2i(x, Grid.ROWS - 1)
		if (x + seed) % 5 == 0:
			_lights(ci, c, accent, 1.0)
		else:
			_conduit_h(ci, c, accent)


# --- prop dispatch -------------------------------------------------------------

static func _prop(ci: CanvasItem, token: String, cell: Vector2i, accent: Color, glow: float, seed: int) -> void:
	match token:
		"screen": _screen(ci, cell, accent, glow)
		"console": _console(ci, cell, accent, glow)
		"panel": _panel(ci, cell, seed)
		"vent": _vent(ci, cell)
		"lights": _lights(ci, cell, accent, glow)
		"locker": _locker(ci, cell)
		"crate": _crate(ci, cell)
		"barrel": _barrel(ci, cell, accent)
		"tank": _tank(ci, cell, accent, glow)
		"dish": _dish(ci, cell, accent, glow)
		"conduit": _conduit_v(ci, cell, accent)
		_: _pipe_seg(ci, cell)


# --- individual prop art (anchored to the floor line of [cell]) ----------------

static func _base(cell: Vector2i) -> Vector2:
	# Top-left of the cell.
	return Vector2(cell.x * TILE, cell.y * TILE)


static func _screen(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(2, 4), Vector2(12, 11)), Color("0a0e16"))         # housing
	ci.draw_rect(Rect2(b + Vector2(2, 4), Vector2(12, 1)), Color("2a3340"))
	var sc := Rect2(b + Vector2(3, 6), Vector2(10, 7))
	ci.draw_rect(sc, accent.darkened(0.35))                                          # screen
	for i in range(0, 7, 2):
		ci.draw_rect(Rect2(sc.position + Vector2(0, i), Vector2(10, 1)), accent.darkened(0.1) * (0.8 + 0.4 * glow))
	ci.draw_rect(Rect2(b + Vector2(3, 6), Vector2(3, 1)), accent.lightened(0.4))     # glint
	ci.draw_rect(Rect2(b + Vector2(2, 15), Vector2(12, 2)), Color(accent.r, accent.g, accent.b, 0.14 * glow))


static func _console(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(1, 6), Vector2(14, 10)), Color("242c38"))         # cabinet
	ci.draw_rect(Rect2(b + Vector2(1, 6), Vector2(14, 1)), Color("3a4654"))
	ci.draw_rect(Rect2(b + Vector2(1, 15), Vector2(14, 1)), Color("12161e"))
	# Indicator lights.
	for i in 4:
		var on := (i + cell.x) % 2 == 0
		ci.draw_rect(Rect2(b + Vector2(3 + i * 3, 8), Vector2(2, 2)), accent if on else accent.darkened(0.6))
	# Little readout panel.
	ci.draw_rect(Rect2(b + Vector2(3, 11), Vector2(10, 3)), accent.darkened(0.4) * (0.85 + 0.3 * glow))


static func _panel(ci: CanvasItem, cell: Vector2i, seed: int) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(2, 5), Vector2(12, 10)), Color("1a2230"))
	ci.draw_rect(Rect2(b + Vector2(2, 5), Vector2(12, 10)), Color("46566a"), false, 1.0)
	# Caution chevrons.
	if (cell.x + seed) % 2 == 0:
		for i in 3:
			ci.draw_rect(Rect2(b + Vector2(3 + i * 4, 8), Vector2(2, 4)), Color("e8b23a"))
	else:
		ci.draw_rect(Rect2(b + Vector2(4, 8), Vector2(8, 1)), Color("6a7a8a"))
		ci.draw_rect(Rect2(b + Vector2(4, 11), Vector2(8, 1)), Color("6a7a8a"))


static func _vent(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(2, 5), Vector2(12, 10)), Color("181f29"))
	for i in range(0, 5):
		ci.draw_rect(Rect2(b + Vector2(3, 6 + i * 2), Vector2(10, 1)), Color("3a4654"))


static func _lights(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(1, 12), Vector2(14, 2)), Color("e8eef6") * (0.7 + 0.3 * glow))   # strip light
	ci.draw_rect(Rect2(b + Vector2(1, 14), Vector2(14, 2)), Color(1, 1, 1, 0.12 * glow))
	ci.draw_rect(Rect2(b + Vector2(2, 6), Vector2(3, 3)), accent)
	ci.draw_rect(Rect2(b + Vector2(11, 6), Vector2(3, 3)), accent.darkened(0.3))


static func _locker(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	var col := Color("3a4656")
	ci.draw_rect(Rect2(b + Vector2(2, 3), Vector2(12, 13)), col)
	ci.draw_rect(Rect2(b + Vector2(2, 3), Vector2(12, 1)), col.lightened(0.3))
	ci.draw_rect(Rect2(b + Vector2(8, 3), Vector2(1, 13)), col.darkened(0.35))     # door split
	ci.draw_rect(Rect2(b + Vector2(6, 9), Vector2(1, 2)), Color("c0c4cc"))         # handle
	ci.draw_rect(Rect2(b + Vector2(10, 9), Vector2(1, 2)), Color("c0c4cc"))
	ci.draw_rect(Rect2(b + Vector2(2, 3), Vector2(12, 13)), col.darkened(0.5), false, 1.0)


static func _crate(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	var col := Color("6e5836")
	ci.draw_rect(Rect2(b + Vector2(3, 6), Vector2(11, 10)), col)
	ci.draw_rect(Rect2(b + Vector2(3, 6), Vector2(11, 1)), col.lightened(0.3))
	ci.draw_rect(Rect2(b + Vector2(3, 10), Vector2(11, 2)), col.darkened(0.3))     # strap
	ci.draw_rect(Rect2(b + Vector2(3, 6), Vector2(11, 10)), col.darkened(0.5), false, 1.0)


static func _barrel(ci: CanvasItem, cell: Vector2i, accent: Color) -> void:
	var b := _base(cell)
	var col := Color("4a5240")
	ci.draw_rect(Rect2(b + Vector2(4, 4), Vector2(9, 12)), col)
	ci.draw_rect(Rect2(b + Vector2(4, 4), Vector2(2, 12)), col.lightened(0.25))    # left highlight
	ci.draw_rect(Rect2(b + Vector2(11, 4), Vector2(2, 12)), col.darkened(0.35))    # right shadow
	ci.draw_rect(Rect2(b + Vector2(4, 7), Vector2(9, 1)), col.darkened(0.4))       # band
	ci.draw_rect(Rect2(b + Vector2(4, 12), Vector2(9, 1)), col.darkened(0.4))
	ci.draw_rect(Rect2(b + Vector2(5, 5), Vector2(3, 2)), accent.darkened(0.2))    # hazard label


static func _tank(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	var col := Color("31404e")
	ci.draw_rect(Rect2(b + Vector2(4, 2), Vector2(9, 14)), col)
	ci.draw_rect(Rect2(b + Vector2(4, 2), Vector2(2, 14)), col.lightened(0.28))
	ci.draw_rect(Rect2(b + Vector2(11, 2), Vector2(2, 14)), col.darkened(0.35))
	# Glowing gauge.
	ci.draw_rect(Rect2(b + Vector2(6, 6), Vector2(5, 6)), Color("0a0e14"))
	ci.draw_rect(Rect2(b + Vector2(7, 7 + (1.0 - glow) * 4), Vector2(3, 4 - (1.0 - glow) * 3)), accent)
	ci.draw_rect(Rect2(b + Vector2(5, 2), Vector2(7, 1)), col.darkened(0.5))       # cap


static func _dish(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(7, 8), Vector2(2, 8)), Color("2a3340"))         # mast
	ci.draw_rect(Rect2(b + Vector2(3, 4), Vector2(10, 5)), Color("46566a"))        # dish
	ci.draw_rect(Rect2(b + Vector2(4, 5), Vector2(8, 3)), Color("1a2028"))
	ci.draw_rect(Rect2(b + Vector2(7, 6), Vector2(1, 1)), accent * (0.6 + 0.6 * glow))   # feed glow


static func _conduit_v(ci: CanvasItem, cell: Vector2i, accent: Color) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(5, 0), Vector2(2, TILE)), Color("2a323c"))
	ci.draw_rect(Rect2(b + Vector2(8, 0), Vector2(1, TILE)), accent.darkened(0.4))
	if cell.y % 3 == 0:
		ci.draw_rect(Rect2(b + Vector2(4, 7), Vector2(5, 2)), Color("3a4654"))     # clamp


static func _conduit_h(ci: CanvasItem, cell: Vector2i, accent: Color) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(0, 7), Vector2(TILE, 2)), Color("2a323c"))
	ci.draw_rect(Rect2(b + Vector2(0, 10), Vector2(TILE, 1)), accent.darkened(0.4))
	if cell.x % 3 == 0:
		ci.draw_rect(Rect2(b + Vector2(7, 6), Vector2(2, 5)), Color("3a4654"))


static func _pipe_seg(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	var horizontal := cell.y == 0 or cell.y == Grid.ROWS - 1
	if horizontal:
		ci.draw_rect(Rect2(b + Vector2(0, 9), Vector2(TILE, 5)), Color("525e54"))
		ci.draw_rect(Rect2(b + Vector2(0, 9), Vector2(TILE, 1)), Color("70806e"))
		ci.draw_rect(Rect2(b + Vector2(0, 13), Vector2(TILE, 1)), Color("32382e"))
		if cell.x % 4 == 0:
			ci.draw_rect(Rect2(b + Vector2(6, 8), Vector2(4, 7)), Color("5e6a5c"))   # flange
	else:
		ci.draw_rect(Rect2(b + Vector2(9, 0), Vector2(5, TILE)), Color("525e54"))
		ci.draw_rect(Rect2(b + Vector2(9, 0), Vector2(1, TILE)), Color("70806e"))
		ci.draw_rect(Rect2(b + Vector2(13, 0), Vector2(1, TILE)), Color("32382e"))
		if cell.y % 4 == 0:
			ci.draw_rect(Rect2(b + Vector2(8, 6), Vector2(7, 4)), Color("5e6a5c"))


# --- floor decal primitives ----------------------------------------------------

static func _chevron(ci: CanvasItem, cell: Vector2i, dir: Vector2i, col: Color) -> void:
	var b := _base(cell)
	for i in 3:
		var o := i * 3
		if dir == Vector2i.UP or dir == Vector2i.DOWN:
			var yy := o if dir == Vector2i.DOWN else (TILE - 2 - o)
			ci.draw_rect(Rect2(b + Vector2(3, yy), Vector2(4, 2)), col)
			ci.draw_rect(Rect2(b + Vector2(9, yy), Vector2(4, 2)), col)
		else:
			var xx := o if dir == Vector2i.RIGHT else (TILE - 2 - o)
			ci.draw_rect(Rect2(b + Vector2(xx, 3), Vector2(2, 4)), col)
			ci.draw_rect(Rect2(b + Vector2(xx, 9), Vector2(2, 4)), col)


static func _grate(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(2, 2), Vector2(12, 12)), Color(0.04, 0.05, 0.07, 0.5))
	for i in range(2, 14, 3):
		ci.draw_rect(Rect2(b + Vector2(i, 2), Vector2(1, 12)), Color(0.5, 0.55, 0.6, 0.14))
		ci.draw_rect(Rect2(b + Vector2(2, i), Vector2(12, 1)), Color(0.5, 0.55, 0.6, 0.10))


static func _stain(ci: CanvasItem, cell: Vector2i, col: Color) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(3, 5), Vector2(9, 7)), col)
	ci.draw_rect(Rect2(b + Vector2(6, 3), Vector2(5, 4)), col)
	ci.draw_rect(Rect2(b + Vector2(2, 9), Vector2(4, 4)), col)


static func _reactor(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(3, 3), Vector2(10, 10)), Color("0a0e14"))
	ci.draw_rect(Rect2(b + Vector2(4, 4), Vector2(8, 8)), Color(accent.r, accent.g, accent.b, 0.35 + 0.35 * glow))
	ci.draw_rect(Rect2(b + Vector2(6, 6), Vector2(4, 4)), accent * (0.7 + 0.4 * glow))
	ci.draw_rect(Rect2(b + Vector2(3, 3), Vector2(10, 10)), accent.darkened(0.2), false, 1.0)


static func _caution(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	for i in 4:
		ci.draw_rect(Rect2(b + Vector2(i * 4, 0), Vector2(2, TILE)), Color(0.9, 0.7, 0.18, 0.5))


static func _floor_light(ci: CanvasItem, cell: Vector2i, accent: Color, glow: float) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(5, 5), Vector2(6, 6)), Color(accent.r, accent.g, accent.b, 0.18 + 0.12 * glow))
	ci.draw_rect(Rect2(b + Vector2(6, 6), Vector2(4, 4)), Color(accent.r, accent.g, accent.b, 0.30 * glow))


# --- flat clutter (walkable, high-contrast fill) ------------------------------

static func _floor_hatch(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(3, 3), Vector2(10, 10)), Color("181f29"))
	ci.draw_rect(Rect2(b + Vector2(3, 3), Vector2(10, 10)), Color("3a4654"), false, 1.0)
	ci.draw_rect(Rect2(b + Vector2(7, 4), Vector2(2, 8)), Color("12161e"))         # seam
	ci.draw_rect(Rect2(b + Vector2(4, 4), Vector2(2, 2)), Color("4a5666"))         # bolts
	ci.draw_rect(Rect2(b + Vector2(10, 10), Vector2(2, 2)), Color("4a5666"))


static func _floor_vent(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(2, 4), Vector2(12, 8)), Color("0e131b"))
	for i in range(0, 6):
		ci.draw_rect(Rect2(b + Vector2(3, 5 + i), Vector2(10, 1)), Color("2e3a48") if i % 2 == 0 else Color("12161e"))


static func _cable_tray(ci: CanvasItem, cell: Vector2i, accent: Color, h: int) -> void:
	var b := _base(cell)
	var horiz := h % 2 == 0
	if horiz:
		ci.draw_rect(Rect2(b + Vector2(0, 5), Vector2(TILE, 6)), Color("161b22"))
		ci.draw_rect(Rect2(b + Vector2(0, 6), Vector2(TILE, 1)), Color("d08a3a"))
		ci.draw_rect(Rect2(b + Vector2(0, 8), Vector2(TILE, 1)), accent.darkened(0.2))
		ci.draw_rect(Rect2(b + Vector2(0, 10), Vector2(TILE, 1)), Color("3a8a6a"))
	else:
		ci.draw_rect(Rect2(b + Vector2(5, 0), Vector2(6, TILE)), Color("161b22"))
		ci.draw_rect(Rect2(b + Vector2(6, 0), Vector2(1, TILE)), Color("d08a3a"))
		ci.draw_rect(Rect2(b + Vector2(8, 0), Vector2(1, TILE)), accent.darkened(0.2))
		ci.draw_rect(Rect2(b + Vector2(10, 0), Vector2(1, TILE)), Color("3a8a6a"))


static func _pallet(ci: CanvasItem, cell: Vector2i) -> void:
	var b := _base(cell)
	ci.draw_rect(Rect2(b + Vector2(2, 2), Vector2(12, 12)), Color(0, 0, 0, 0.18))   # shadow
	ci.draw_rect(Rect2(b + Vector2(2, 2), Vector2(12, 12)), Color("2a323c"))
	ci.draw_rect(Rect2(b + Vector2(2, 2), Vector2(12, 12)), Color("48566a"), false, 1.0)
	# Painted load-marking X.
	ci.draw_line(b + Vector2(3, 3), b + Vector2(13, 13), Color("c8a23a"), 1.0)
	ci.draw_line(b + Vector2(13, 3), b + Vector2(3, 13), Color("c8a23a"), 1.0)


static func _stencil(ci: CanvasItem, cell: Vector2i, h: int) -> void:
	# Stencilled deck markings — short bars that read as painted text/codes.
	var b := _base(cell)
	var col := Color("8a96a0", 0.5)
	var rows := 2 + h % 2
	for r in rows:
		var w := 4 + (h >> r) % 8
		ci.draw_rect(Rect2(b + Vector2(3, 4 + r * 4), Vector2(w, 2)), col)


# --- helpers -------------------------------------------------------------------

static func _dir(side: String) -> Vector2i:
	return Grid.dir_vec(side)


static func _door_inner_cells(side: String) -> Array:
	# The two floor cells just inside a door gap.
	match side:
		"north": return [Vector2i(9, 1), Vector2i(10, 1)]
		"south": return [Vector2i(9, Grid.ROWS - 2), Vector2i(10, Grid.ROWS - 2)]
		"west": return [Vector2i(1, 7), Vector2i(1, 8)]
		"east": return [Vector2i(Grid.COLS - 2, 7), Vector2i(Grid.COLS - 2, 8)]
	return []
