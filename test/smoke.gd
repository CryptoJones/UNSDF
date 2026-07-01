extends Node
## Headless invariant + logic smoke test. Run with:
##   godot --headless --path . test/smoke.tscn
## Exits 0 if all checks pass, 1 otherwise. Not part of the shipped game.

var _fail := 0
var _pass := 0


func _ready() -> void:
	print("=== UNSDF smoke test ===")
	_test_graph_symmetry()
	_test_goal_isolation()
	_test_dialogue_integrity()
	_test_locks()
	_test_puzzle()
	print("=== %d passed, %d failed ===" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		printerr("FAIL: " + msg)


func _test_graph_symmetry() -> void:
	for id in RoomDB.ROOMS:
		for side in RoomDB.ROOMS[id].get("exits", {}):
			var to: StringName = RoomDB.ROOMS[id]["exits"][side]["to"]
			_check(RoomDB.has_room(to), "%s.%s -> missing room %s" % [id, side, to])
			var back = RoomDB.ROOMS[to].get("exits", {}).get(Grid.opposite(side), null)
			_check(back != null and back["to"] == id, "%s.%s has no matching return door in %s" % [id, side, to])


func _test_goal_isolation() -> void:
	# Nothing but C4 may point into C3.
	for id in RoomDB.ROOMS:
		if id == &"C4":
			continue
		for side in RoomDB.ROOMS[id].get("exits", {}):
			_check(RoomDB.ROOMS[id]["exits"][side]["to"] != &"C3", "%s leaks straight into C3 via %s" % [id, side])
	# The only ingress to the {B4,C4,C3} cluster from outside is the locked B3->B4.
	var cluster := [&"B4", &"C4", &"C3"]
	for id in RoomDB.ROOMS:
		if id in cluster:
			continue
		for side in RoomDB.ROOMS[id].get("exits", {}):
			var to: StringName = RoomDB.ROOMS[id]["exits"][side]["to"]
			if to in cluster:
				var lock = RoomDB.ROOMS[id]["exits"][side].get("lock")
				_check(id == &"B3" and lock != null, "unguarded entry into the sealed cluster: %s.%s -> %s" % [id, side, to])


func _test_dialogue_integrity() -> void:
	for tid in DialogueDB.TREES:
		var tree: Dictionary = DialogueDB.TREES[tid]
		var ids: Array = []
		for k in tree.keys():
			if k != "_start_if":
				ids.append(k)
		_check("root" in ids, "%s missing root node" % tid)
		for rule in tree.get("_start_if", []):
			_check(rule[1] in ids, "%s _start_if -> missing node %s" % [tid, rule[1]])
		for nid in ids:
			var node: Dictionary = tree[nid]
			if node.has("next"):
				_check(node["next"] in ids, "%s.%s next -> missing node %s" % [tid, nid, node["next"]])
			for ch in node.get("choices", []):
				_check(ch.has("text"), "%s.%s has a choice with no text" % [tid, nid])
				if ch.has("goto"):
					_check(ch["goto"] in ids, "%s.%s goto -> missing node %s" % [tid, nid, ch["goto"]])


func _test_locks() -> void:
	for id in RoomDB.ROOMS:
		for side in RoomDB.ROOMS[id].get("exits", {}):
			var lock = RoomDB.ROOMS[id]["exits"][side].get("lock")
			if lock == null:
				continue
			_check(lock.has("msg"), "%s.%s lock has no player message" % [id, side])
			if lock.has("item"):
				_check(not ItemDB.get_item(lock["item"]).is_empty(), "%s.%s lock references unknown item %s" % [id, side, lock["item"]])


func _test_puzzle() -> void:
	var room := Room.new()
	add_child(room)
	room.setup(&"D2", RoomDB.get_room(&"D2"))
	_check(not GameState.has_flag(&"d2_cache_open"), "cache reported open before the puzzle was solved")
	var player_cell := Grid.spawn_cell_for("north")
	var facing := Vector2i.DOWN
	for action in ["D", "D", "D", "D", "D", "L", "D", "GU", "GU", "L", "GR", "GR", "GR", "GR", "U", "L", "PD", "PD", "L", "GR", "GR", "U", "R", "GL", "GL", "GL"]:
		var state := _apply_puzzle_action(room, player_cell, facing, action)
		_check(state["ok"], "legal puzzle path failed at action %s" % action)
		if not state["ok"]:
			break
		player_cell = state["cell"]
		facing = state["facing"]
	_check(GameState.has_flag(&"d2_cache_open"), "three plates pressed but the cache did not open")
	_check(room.item_at(Vector2i(10, 2)) != null, "Power Core did not spawn at the cache")
	room.collect_item(Vector2i(10, 2))
	_check(Inventory.has(&"power_core"), "Power Core was not added to inventory on pickup")
	room.queue_free()


func _apply_puzzle_action(room: Room, player_cell: Vector2i, facing: Vector2i, action: String) -> Dictionary:
	var grab := action.begins_with("G")
	var push := action.begins_with("P")
	var dir := _action_dir(action[-1])
	if dir == Vector2i.ZERO:
		return {"ok": false, "cell": player_cell, "facing": facing}
	if grab:
		if dir != -facing:
			return {"ok": false, "cell": player_cell, "facing": facing}
		var front := player_cell + facing
		var back := player_cell + dir
		if room.crate_at(front) == null:
			return {"ok": false, "cell": player_cell, "facing": facing}
		if not _can_player_enter(room, back):
			return {"ok": false, "cell": player_cell, "facing": facing}
		room.move_crate(front, player_cell)
		return {"ok": true, "cell": back, "facing": facing}

	var target := player_cell + dir
	if push:
		var beyond := target + dir
		if room.crate_at(target) == null or not room.can_crate_enter(beyond):
			return {"ok": false, "cell": player_cell, "facing": dir}
		room.move_crate(target, beyond)
		return {"ok": true, "cell": target, "facing": dir}

	if not _can_player_enter(room, target):
		return {"ok": false, "cell": player_cell, "facing": dir}
	return {"ok": true, "cell": target, "facing": dir}


func _can_player_enter(room: Room, cell: Vector2i) -> bool:
	if room.is_wall(cell) or room.door_dir_for(cell) != "":
		return false
	if room.crate_at(cell) != null or room.npc_at(cell) != null:
		return false
	return true


func _action_dir(suffix: String) -> Vector2i:
	match suffix:
		"U": return Vector2i.UP
		"D": return Vector2i.DOWN
		"L": return Vector2i.LEFT
		"R": return Vector2i.RIGHT
	return Vector2i.ZERO
