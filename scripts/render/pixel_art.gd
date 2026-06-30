class_name PixelArt
extends RefCounted
## Procedural 16-bit art kit. Everything in the slice is drawn from code (zero
## asset imports), so the "SNES-era" look has to be *generated*: ordered-dither
## metal floors, beveled riveted wall plates, shaded humanoid actors, glowing
## pickups and a soft vignette. Textures are baked once into ImageTextures and
## cached by colour, so per-frame redraws stay cheap.

const TILE := 16

# 4x4 Bayer matrix (0..15) for ordered dithering — the classic SNES gradient trick.
const BAYER := [
	[0, 8, 2, 10],
	[12, 4, 14, 6],
	[3, 11, 1, 9],
	[15, 7, 13, 5],
]

static var _floor_cache: Dictionary = {}
static var _wall_cache: Dictionary = {}
static var _vignette: ImageTexture = null


# --- colour ramps --------------------------------------------------------------

static func lit(c: Color, amt: float) -> Color:
	return c.lightened(amt)


static func shade(c: Color, amt: float) -> Color:
	return c.darkened(amt)


# --- floor: dithered metal deck plate -----------------------------------------

static func floor_texture(base: Color) -> ImageTexture:
	var key := base.to_html()
	if _floor_cache.has(key):
		return _floor_cache[key]

	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var dark := base
	var light := base.lightened(0.10)
	var seam := base.darkened(0.45)
	var bolt := base.lightened(0.30)
	var bolt_sh := base.darkened(0.35)

	for y in TILE:
		for x in TILE:
			# Ordered dither between the two deck shades -> brushed-metal speckle.
			var t: int = BAYER[y & 3][x & 3]
			var col := light if t < 7 else dark
			# Plate seams on the top/left edge of every tile.
			if x == 0 or y == 0:
				col = seam
			img.set_pixel(x, y, col)

	# Corner rivets (lit dot + shadow) sell the panelling.
	_rivet(img, 3, 3, bolt, bolt_sh)
	_rivet(img, TILE - 4, TILE - 4, bolt, bolt_sh)

	var tex := ImageTexture.create_from_image(img)
	_floor_cache[key] = tex
	return tex


# --- wall: beveled plate with rivets ------------------------------------------

static func wall_texture(base: Color) -> ImageTexture:
	var key := base.to_html()
	if _wall_cache.has(key):
		return _wall_cache[key]

	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var hi := base.lightened(0.34)
	var sh := base.darkened(0.40)
	var bolt := base.lightened(0.45)
	var bolt_sh := base.darkened(0.45)

	for y in TILE:
		for x in TILE:
			var col := base
			# Vertical brushed striping.
			if x % 4 == 1:
				col = base.lightened(0.06)
			elif x % 4 == 3:
				col = base.darkened(0.08)
			# Bevel: lit top/left, shadowed bottom/right.
			if y == 0 or x == 0:
				col = hi
			elif y == TILE - 1 or x == TILE - 1:
				col = sh
			img.set_pixel(x, y, col)

	for p in [Vector2i(3, 3), Vector2i(TILE - 4, 3), Vector2i(3, TILE - 4), Vector2i(TILE - 4, TILE - 4)]:
		_rivet(img, p.x, p.y, bolt, bolt_sh)

	var tex := ImageTexture.create_from_image(img)
	_wall_cache[key] = tex
	return tex


static func _rivet(img: Image, x: int, y: int, lite: Color, dark: Color) -> void:
	if x < 1 or y < 1 or x >= TILE - 1 or y >= TILE - 1:
		return
	img.set_pixel(x, y, lite)
	img.set_pixel(x + 1, y, lite)
	img.set_pixel(x, y + 1, dark)
	img.set_pixel(x + 1, y + 1, dark)


# --- vignette: soft edge darkening for depth ----------------------------------

static func vignette() -> ImageTexture:
	if _vignette != null:
		return _vignette
	var w := int(Grid.SCREEN.x)
	var h := int(Grid.SCREEN.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx := w * 0.5
	var cy := h * 0.5
	var maxd := sqrt(cx * cx + cy * cy)
	for y in h:
		for x in w:
			var dx := (x - cx) / maxd
			var dy := (y - cy) / maxd
			var d := sqrt(dx * dx + dy * dy) / 0.7071
			var a := clampf((d - 0.55) / 0.45, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.02, 0.02, 0.05, a * 0.55))
	_vignette = ImageTexture.create_from_image(img)
	return _vignette


# --- actors: shaded little humanoids -------------------------------------------

## Draws a centred 16-bit character in [ci]'s local space (origin = tile centre).
## [facing] orients the visor/face; [accent] is a light/badge colour (the player's
## HUD nub, an NPC's trim). Set [is_player] for the brighter suit highlight.
static func draw_actor(ci: CanvasItem, body: Color, facing: Vector2i, accent: Color, is_player: bool = false) -> void:
	var hi := body.lightened(0.30 if is_player else 0.22)
	var sh := body.darkened(0.34)
	var skin := Color("d8a87a")
	var skin_sh := skin.darkened(0.22)

	# Contact shadow.
	ci.draw_colored_polygon(_ellipse(Vector2(0, 6.5), 5.0, 2.0), Color(0, 0, 0, 0.32))

	# Legs.
	ci.draw_rect(Rect2(-3, 2, 2, 5), sh)
	ci.draw_rect(Rect2(1, 2, 2, 5), sh)
	ci.draw_rect(Rect2(-3, 6, 2, 1), body.darkened(0.5))
	ci.draw_rect(Rect2(1, 6, 2, 1), body.darkened(0.5))

	# Torso: lit on the left, shaded on the right (single overhead key light).
	ci.draw_rect(Rect2(-4, -3, 8, 6), body)
	ci.draw_rect(Rect2(-4, -3, 3, 6), hi)
	ci.draw_rect(Rect2(2, -3, 2, 6), sh)
	ci.draw_rect(Rect2(-4, -3, 8, 1), body.lightened(0.12))   # collar highlight
	# Accent badge / shoulder light.
	ci.draw_rect(Rect2(-1, -1, 2, 2), accent)

	# Head.
	var looking_away := facing == Vector2i.UP
	ci.draw_rect(Rect2(-3, -9, 6, 6), skin if not looking_away else skin_sh)
	ci.draw_rect(Rect2(-3, -9, 6, 2), Color("3a3038"))        # hair / helmet cap
	ci.draw_rect(Rect2(-3, -9, 1, 6), skin_sh)                # cheek shadow

	# Face / visor facing direction.
	if not looking_away:
		var eye := Color("10141c")
		match facing:
			Vector2i.LEFT:
				ci.draw_rect(Rect2(-2, -6, 1, 1), eye)
			Vector2i.RIGHT:
				ci.draw_rect(Rect2(1, -6, 1, 1), eye)
			_:
				ci.draw_rect(Rect2(-2, -6, 1, 1), eye)
				ci.draw_rect(Rect2(1, -6, 1, 1), eye)
	else:
		ci.draw_rect(Rect2(-3, -7, 6, 1), Color("2a222c"))


# --- pickups: glowing item ----------------------------------------------------

static func draw_item(ci: CanvasItem, center: Vector2, color: Color, pulse: float) -> void:
	var glow := 0.5 + 0.5 * pulse
	ci.draw_circle(center, 6.0, Color(color.r, color.g, color.b, 0.10 * glow))
	ci.draw_circle(center, 4.0, Color(color.r, color.g, color.b, 0.18 * glow))
	var r := Rect2(center - Vector2(3, 3), Vector2(6, 6))
	ci.draw_rect(r, color)
	ci.draw_rect(r, color.lightened(0.4), false, 1.0)
	# Specular glint, top-left.
	ci.draw_rect(Rect2(center + Vector2(-2, -2), Vector2(1, 1)), Color(1, 1, 1, 0.7 * glow))


static func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 12
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
