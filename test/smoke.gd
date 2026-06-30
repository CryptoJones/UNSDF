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
	room.move_crate(Vector2i(6, 6), Vector2i(10, 6))
	room.move_crate(Vector2i(8, 9), Vector2i(10, 8))
	room.move_crate(Vector2i(13, 6), Vector2i(10, 7))
	_check(GameState.has_flag(&"d2_cache_open"), "three plates pressed but the cache did not open")
	_check(room.item_at(Vector2i(10, 2)) != null, "Power Core did not spawn at the cache")
	room.collect_item(Vector2i(10, 2))
	_check(Inventory.has(&"power_core"), "Power Core was not added to inventory on pickup")
	room.queue_free()
