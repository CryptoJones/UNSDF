extends Node
## Key-item bag. Autoload singleton: "Inventory".

signal changed(item_id: StringName, count: int)

var _items: Dictionary = {}


func add(item_id: StringName, n: int = 1) -> void:
	_items[item_id] = int(_items.get(item_id, 0)) + n
	changed.emit(item_id, _items[item_id])


func remove(item_id: StringName, n: int = 1) -> bool:
	if not has(item_id, n):
		return false
	_items[item_id] = int(_items[item_id]) - n
	changed.emit(item_id, _items[item_id])
	return true


func has(item_id: StringName, n: int = 1) -> bool:
	return int(_items.get(item_id, 0)) >= n


func count(item_id: StringName) -> int:
	return int(_items.get(item_id, 0))


func ids() -> Array:
	return _items.keys()
