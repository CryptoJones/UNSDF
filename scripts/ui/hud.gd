class_name Hud
extends CanvasLayer
## 16-bit UI. A large bottom-half dialogue box with a drawn character portrait,
## a transient status line, a room label, a fade layer, and the DEMO CLEAR
## overlay. Rendered crisp at native resolution (canvas_items stretch), so the
## text stays sharp and readable at any window size.

const SCREEN := Vector2(320, 240)

var _panel: Panel
var _portrait: Portrait
var _portrait_img: TextureRect
var _speaker: Label
var _text: RichTextLabel
var _choice_box: VBoxContainer
var _choice_labels: Array = []
var _status: Label
var _status_timer := 0.0
var _room_label: Label
var _fade: ColorRect
var _demo: Control


## A little drawn face for the speaker — beats a flat colour swatch.
class Portrait extends Control:
	var tint := Color("6e7a8a")

	func set_tint(c: Color) -> void:
		tint = c
		queue_redraw()

	func _draw() -> void:
		var s := size.x
		var cx := s * 0.5
		var skin := Color("d8a87a")
		# Backdrop + bevel frame.
		draw_rect(Rect2(Vector2.ZERO, size), Color("0a0e16"))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.16, 0.22, 0.6))
		# Suit / shoulders.
		draw_rect(Rect2(cx - s * 0.36, s - s * 0.30, s * 0.72, s * 0.34), tint)
		draw_rect(Rect2(cx - s * 0.36, s - s * 0.30, s * 0.72, s * 0.07), tint.lightened(0.25))
		draw_rect(Rect2(cx - 1, s - s * 0.22, s * 0.10, s * 0.10), tint.lightened(0.5))  # badge
		# Neck.
		draw_rect(Rect2(cx - s * 0.09, s - s * 0.40, s * 0.18, s * 0.16), skin.darkened(0.12))
		# Head.
		var hw := s * 0.5
		draw_rect(Rect2(cx - hw * 0.5, s * 0.18, hw, hw), skin)
		draw_rect(Rect2(cx - hw * 0.5, s * 0.18, hw * 0.22, hw), skin.darkened(0.2))   # cheek shadow
		# Hair.
		draw_rect(Rect2(cx - hw * 0.5, s * 0.13, hw, hw * 0.32), Color("332b33"))
		draw_rect(Rect2(cx - hw * 0.5, s * 0.13, hw, hw * 0.10), Color("443a44"))
		# Eyes + glint.
		var ey := s * 0.42
		draw_rect(Rect2(cx - hw * 0.34, ey, hw * 0.18, hw * 0.18), Color("10141c"))
		draw_rect(Rect2(cx + hw * 0.16, ey, hw * 0.18, hw * 0.18), Color("10141c"))
		draw_rect(Rect2(cx - hw * 0.32, ey, 1, 1), Color(1, 1, 1, 0.8))
		# Edge frame on top.
		draw_rect(Rect2(Vector2.ZERO, size), tint.lightened(0.3), false, 1.0)


func _ready() -> void:
	layer = 10
	_build()


func _build() -> void:
	_room_label = _make_label(Vector2(7, 5), 11, Color("9ab4cc"))
	add_child(_room_label)

	_status = _make_label(Vector2(7, 21), 11, Color("f0d264"))
	_status.modulate.a = 0.0
	add_child(_status)

	# Dialogue box: a near-fullscreen comms panel. A big portrait header up top,
	# then a roomy body that never clips, with choices along the bottom.
	_panel = Panel.new()
	_panel.position = Vector2(4, 4)
	_panel.size = Vector2(312, 232)
	_panel.visible = false
	_panel.add_theme_stylebox_override("panel", _dialogue_box())
	add_child(_panel)

	_portrait = Portrait.new()
	_portrait.position = Vector2(10, 10)
	_portrait.size = Vector2(72, 72)
	_panel.add_child(_portrait)

	# Painted portrait (preferred); clipped to the same frame, hidden until a
	# speaker with portrait art talks.
	_portrait_img = TextureRect.new()
	_portrait_img.position = Vector2(10, 10)
	_portrait_img.size = Vector2(72, 72)
	_portrait_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait_img.clip_contents = true
	_portrait_img.visible = false
	_panel.add_child(_portrait_img)

	_speaker = _make_label(Vector2(92, 20), 16, Color("f0d264"))
	_panel.add_child(_speaker)

	# Divider under the header.
	var rule := ColorRect.new()
	rule.position = Vector2(12, 88)
	rule.size = Vector2(290, 1)
	rule.color = Color("3a6e7a")
	_panel.add_child(rule)

	_text = RichTextLabel.new()
	_text.position = Vector2(12, 94)
	_text.size = Vector2(296, 130)
	_text.bbcode_enabled = false
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", 13)
	_text.add_theme_color_override("default_color", Color("d6e2ee"))
	_panel.add_child(_text)

	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(16, 184)
	_choice_box.size = Vector2(288, 44)
	_choice_box.add_theme_constant_override("separation", 1)
	_panel.add_child(_choice_box)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = SCREEN
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_demo = _build_demo(SCREEN)
	add_child(_demo)


func _dialogue_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("0e1422")
	sb.border_color = Color("4a8a96")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 4
	return sb


func _make_label(pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_demo(screen: Vector2) -> Control:
	var c := Control.new()
	c.size = screen
	c.visible = false
	c.modulate.a = 0.0
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.size = screen
	c.add_child(bg)
	var title := _make_label(Vector2(0, 92), 30, Color("4ad6e8"))
	title.text = "DEMO CLEAR"
	title.size = Vector2(screen.x, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(title)
	var sub := _make_label(Vector2(0, 134), 12, Color("c0c8d0"))
	sub.text = "The Cold Mercy undocks. Tier-9 shrinks behind you."
	sub.size = Vector2(screen.x, 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(sub)
	return c


func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer < 0.6:
			_status.modulate.a = maxf(0.0, _status_timer / 0.6)


# --- dialogue ------------------------------------------------------------------

func show_dialogue(speaker: String, portrait: Color, text: String, choices: Array, portrait_id: String = "") -> void:
	_panel.visible = true
	_speaker.text = speaker
	# Painted portrait if we have art for this speaker; else the drawn face.
	var path := "res://assets/portraits/%s.png" % portrait_id
	if portrait_id != "" and ResourceLoader.exists(path):
		_portrait_img.texture = load(path)
		_portrait_img.visible = true
		_portrait.visible = false
	else:
		_portrait_img.visible = false
		_portrait.visible = true
		_portrait.set_tint(portrait)
	_text.text = text
	# Give the body the whole box when there's nothing to choose; otherwise
	# reserve the lower strip for the choices so neither clips.
	_text.size.y = 86 if not choices.is_empty() else 130
	for child in _choice_box.get_children():
		child.queue_free()
	_choice_labels.clear()
	for i in choices.size():
		var l := _make_label(Vector2.ZERO, 13, Color("c0c8d0"))
		l.text = "  " + str(choices[i])
		_choice_box.add_child(l)
		_choice_labels.append(l)
	if not _choice_labels.is_empty():
		highlight_choice(0)


func highlight_choice(idx: int) -> void:
	for i in _choice_labels.size():
		var l: Label = _choice_labels[i]
		var body: String = l.text.substr(2)
		if i == idx:
			l.text = "> " + body
			l.add_theme_color_override("font_color", Color("f0d264"))
		else:
			l.text = "  " + body
			l.add_theme_color_override("font_color", Color("9aa6b4"))


func hide_dialogue() -> void:
	_panel.visible = false


# --- status / room / fade / win ------------------------------------------------

func status(text: String) -> void:
	_status.text = text
	_status.modulate.a = 1.0
	_status_timer = 2.6


func set_room_label(room_name: String, id: StringName) -> void:
	_room_label.text = "%s  %s" % [str(id), room_name]


func fade_to(alpha: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", alpha, dur)
	await tw.finished


func show_demo_clear() -> void:
	_demo.visible = true
	var tw := create_tween()
	tw.tween_property(_demo, "modulate:a", 1.0, 0.6)
