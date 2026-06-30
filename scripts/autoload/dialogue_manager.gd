extends Node
## Walks a DialogueDB tree and drives the HUD. Autoload singleton: "DialogueManager".

signal started
signal finished

var active := false
var hud   # Hud node, assigned by Main on boot.

var _tree: Dictionary = {}
var _node_id: String = ""
var _choices: Array = []
var _sel := 0
var _speaker := ""
var _portrait := Color("6e7a8a")


## npc = { dialogue: StringName, name: String, color: Color }
func start(npc: Dictionary) -> void:
	if active:
		return
	var tree: Dictionary = DialogueDB.get_tree(npc.get("dialogue", &""))
	if tree.is_empty():
		return
	_tree = tree
	_speaker = npc.get("name", "")
	_portrait = npc.get("color", Color("6e7a8a"))
	active = true
	started.emit()
	_goto(_resolve_start())


func _resolve_start() -> String:
	for rule in _tree.get("_start_if", []):
		if GameState.has_flag(rule[0]):
			return rule[1]
	return "root"


func _goto(node_id: String) -> void:
	_node_id = node_id
	var node: Dictionary = _tree[node_id]
	_run_actions(node)
	_choices = _visible_choices(node)
	_sel = 0
	if hud:
		hud.show_dialogue(node.get("speaker", _speaker), _portrait, node.get("text", ""), _choice_labels())


func _choice_labels() -> Array:
	var out: Array = []
	for c in _choices:
		out.append(c.get("text", "..."))
	return out


func _visible_choices(node: Dictionary) -> Array:
	var out: Array = []
	for c in node.get("choices", []):
		if _choice_allowed(c):
			out.append(c)
	return out


func _choice_allowed(c: Dictionary) -> bool:
	if c.has("require_item") and not Inventory.has(c["require_item"]):
		return false
	if c.has("require_flag") and not GameState.has_flag(c["require_flag"]):
		return false
	if c.has("require_not_flag") and GameState.has_flag(c["require_not_flag"]):
		return false
	return true


func _run_actions(d: Dictionary) -> void:
	if d.has("set_flag"):
		GameState.set_flag(d["set_flag"], true)
	if d.has("give"):
		Inventory.add(d["give"])
	if d.has("take"):
		Inventory.remove(d["take"])


func _input(event: InputEvent) -> void:
	if not active:
		return
	if not _choices.is_empty():
		if event.is_action_pressed("move_up"):
			_sel = (_sel - 1 + _choices.size()) % _choices.size()
			if hud:
				hud.highlight_choice(_sel)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_down"):
			_sel = (_sel + 1) % _choices.size()
			if hud:
				hud.highlight_choice(_sel)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	var node: Dictionary = _tree[_node_id]
	if not _choices.is_empty():
		var choice: Dictionary = _choices[_sel]
		_run_actions(choice)
		var goto: String = choice.get("goto", "")
		if goto == "":
			_finish()
		else:
			_goto(goto)
	else:
		var nxt: String = node.get("next", "")
		if nxt == "":
			_finish()
		else:
			_goto(nxt)


func _finish() -> void:
	active = false
	_tree = {}
	_choices = []
	if hud:
		hud.hide_dialogue()
	finished.emit()
