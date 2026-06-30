class_name Pushable
extends Node2D
## A heavy cargo crate. The Player drives movement through Room.move_crate();
## this node just animates between grid cells.

const MOVE_TIME := 0.09

var cell: Vector2i


func setup(start_cell: Vector2i) -> void:
	cell = start_cell
	position = Grid.cell_to_pos(start_cell)


func move_to(target: Vector2i) -> void:
	cell = target
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position", Grid.cell_to_pos(target), MOVE_TIME)


func _draw() -> void:
	var s := float(Grid.TILE)
	var half := s * 0.5
	var base := Color("7a6038")
	# Contact shadow.
	draw_rect(Rect2(-half + 2, half - 3, s - 4, 3), Color(0, 0, 0, 0.28))
	# Metal cargo container with beveled edges.
	var body := Rect2(-half + 1, -half + 1, s - 2, s - 2)
	draw_rect(body, base)
	draw_rect(Rect2(body.position, Vector2(body.size.x, 1)), base.lightened(0.35))   # top light
	draw_rect(Rect2(body.position, Vector2(1, body.size.y)), base.lightened(0.22))   # left light
	draw_rect(Rect2(body.position + Vector2(body.size.x - 1, 0), Vector2(1, body.size.y)), base.darkened(0.4))
	draw_rect(Rect2(body.position + Vector2(0, body.size.y - 1), Vector2(body.size.x, 1)), base.darkened(0.45))
	# Cross-brace + corner rivets.
	draw_rect(Rect2(-half + 3, -1, s - 6, 2), base.darkened(0.28))
	draw_rect(Rect2(-1, -half + 3, 2, s - 6), base.darkened(0.28))
	for p in [Vector2(-half + 3, -half + 3), Vector2(half - 5, -half + 3), Vector2(-half + 3, half - 5), Vector2(half - 5, half - 5)]:
		draw_rect(Rect2(p, Vector2(2, 2)), base.lightened(0.4))
	draw_rect(body, Color("3a2c18"), false, 1.0)
