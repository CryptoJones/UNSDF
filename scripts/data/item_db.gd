class_name ItemDB
extends RefCounted
## Static catalogue of the level's key items.

static var ITEMS := {
	&"access_keycard": {
		"name": "Access Keycard",
		"color": Color("e8c84a"),
		"desc": "A maintenance keycard. Unlocks the Cargo Bay (D2) keypad.",
	},
	&"power_core": {
		"name": "Power Core",
		"color": Color("4ad6e8"),
		"desc": "Salvaged reactor cell. The Technician wants this.",
	},
}


static func get_item(id: StringName) -> Dictionary:
	return ITEMS.get(id, {})


static func item_name(id: StringName) -> String:
	return ITEMS.get(id, {}).get("name", str(id))


static func item_color(id: StringName) -> Color:
	return ITEMS.get(id, {}).get("color", Color.WHITE)
