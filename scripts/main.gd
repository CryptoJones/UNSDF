extends Node2D
## Boot scene. Builds the world container, the persistent Player, and the HUD,
## wires them into the autoload singletons, then loads the opening room (A1).

var hud: Hud


func _ready() -> void:
	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	var player := Player.new()
	player.name = "Player"
	world.add_child(player)

	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)

	DialogueManager.hud = hud
	RoomManager.setup(world, player, hud)

	GameState.flag_changed.connect(_on_flag_changed)
	RoomManager.start_game()


func _on_flag_changed(flag: StringName, value: Variant) -> void:
	if flag == &"demo_clear" and value:
		hud.show_demo_clear()
