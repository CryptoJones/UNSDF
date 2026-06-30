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
	var body := Rect2(-half + 1, -half + 1, s - 2, s - 2)
	draw_rect(body, Color("6e5836"))
	draw_rect(body, Color("9a7c48"), false, 1.0)
	draw_line(Vector2(-half + 2, -half + 2), Vector2(half - 2, half - 2), Color("4a3c24"), 1.0)
	draw_line(Vector2(half - 2, -half + 2), Vector2(-half + 2, half - 2), Color("4a3c24"), 1.0)
