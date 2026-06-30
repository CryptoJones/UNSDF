class_name Hud
extends CanvasLayer
## Minimalist 16-bit UI: a floating text box with a portrait swatch, a transient
## status line, a room label, a fade layer, and the DEMO CLEAR overlay.
## No HP bar — the slice is stealth/logic only (per the locked spec).

var _panel: Panel
var _portrait: ColorRect
var _speaker: Label
var _text: RichTextLabel
var _choice_box: VBoxContainer
var _choice_labels: Array = []
var _status: Label
var _status_timer := 0.0
var _room_label: Label
var _fade: ColorRect
var _demo: Control


func _ready() -> void:
	layer = 10
	_build()


func _build() -> void:
	var screen := Vector2(Grid.SCREEN)

	_room_label = _make_label(Vector2(6, 4), 9, Color("8aa0b8"))
	add_child(_room_label)

	_status = _make_label(Vector2(6, 16), 9, Color("e8c84a"))
	_status.modulate.a = 0.0
	add_child(_status)

	_panel = Panel.new()
	_panel.position = Vector2(8, 150)
	_panel.size = Vector2(304, 82)
	_panel.visible = false
	add_child(_panel)

	_portrait = ColorRect.new()
	_portrait.position = Vector2(8, 8)
	_portrait.size = Vector2(28, 28)
	_panel.add_child(_portrait)

	_speaker = _make_label(Vector2(44, 6), 9, Color("e8c84a"))
	_panel.add_child(_speaker)

	_text = RichTextLabel.new()
	_text.position = Vector2(44, 22)
	_text.size = Vector2(252, 32)
	_text.bbcode_enabled = false
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", 9)
	_panel.add_child(_text)

	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(44, 54)
	_choice_box.add_theme_constant_override("separation", 0)
	_panel.add_child(_choice_box)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = screen
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_demo = _build_demo(screen)
	add_child(_demo)


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
	bg.color = Color(0, 0, 0, 0.82)
	bg.size = screen
	c.add_child(bg)
	var title := _make_label(Vector2(0, 96), 22, Color("4ad6e8"))
	title.text = "DEMO CLEAR"
	title.size = Vector2(screen.x, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(title)
	var sub := _make_label(Vector2(0, 130), 9, Color("c0c8d0"))
	sub.text = "The Cold Mercy undocks. Tier-9 shrinks behind you."
	sub.size = Vector2(screen.x, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(sub)
	return c


func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer < 0.6:
			_status.modulate.a = maxf(0.0, _status_timer / 0.6)


# --- dialogue ------------------------------------------------------------------

func show_dialogue(speaker: String, portrait: Color, text: String, choices: Array) -> void:
	_panel.visible = true
	_speaker.text = speaker
	_portrait.color = portrait
	_text.text = text
	for child in _choice_box.get_children():
		child.queue_free()
	_choice_labels.clear()
	for i in choices.size():
		var l := _make_label(Vector2.ZERO, 9, Color("c0c8d0"))
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
			l.add_theme_color_override("font_color", Color("e8c84a"))
		else:
			l.text = "  " + body
			l.add_theme_color_override("font_color", Color("c0c8d0"))


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
