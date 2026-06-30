class_name RoomDB
extends RefCounted
## The whole Tier-9 concourse as data. 4x4 grid of rooms (A1..D4).
## Each room is rebuilt from this table every time it is entered, which is what
## gives us "room-exit reset" for free (crates snap back, the soft-lock guard).
##
## Room schema:
##   name        String
##   floor/wall  Color
##   hazard      bool        -- if true, do NOT set the respawn checkpoint here
##   start_cell  Vector2i    -- only the starting room needs this
##   exits       { side: { to: StringName, lock: {flag|item, msg} } }
##                 side in {north, south, east, west}
##   npcs        [ { cell, name, dialogue, color } ]
##   items       [ { cell, item, require_flag? } ]
##   crates      [ Vector2i ]
##   plates      [ Vector2i ]
##   puzzle      { solve_flag, reward: { item, cell } }
##   cameras     [ { cell, facing, range, on, off, phase } ]

const FLOOR := Color("1b2433")
const WALL := Color("39506e")

static var ROOMS := {
	# ---- Row A ------------------------------------------------------------
	&"A1": {
		"name": "Recruitment Office",
		"floor": Color("232b3b"), "wall": Color("4a5d7a"),
		"start_cell": Vector2i(10, 10),
		"exits": {
			"south": {"to": &"B1"},
			"east": {"to": &"A2"},
		},
		"npcs": [
			{"cell": Vector2i(10, 7), "name": "UNSDF Recruiter", "dialogue": &"recruiter", "color": Color("6e7a8a")},
		],
	},
	&"A2": {
		"name": "Security Hub",
		"floor": Color("2b1f24"), "wall": Color("7a3a3a"),
		"hazard": true,
		"exits": {
			"west": {"to": &"A1"},
			"east": {"to": &"A3"},
			"south": {"to": &"B2"},
		},
		"cameras": [
			{"cell": Vector2i(4, 7), "facing": "east", "range": 9, "on": 1.6, "off": 1.5, "phase": 0.0},
			{"cell": Vector2i(10, 3), "facing": "south", "range": 7, "on": 1.4, "off": 1.7, "phase": 0.9},
		],
	},
	&"A3": {
		"name": "Maintenance Corridor",
		"floor": Color("1d2630"), "wall": Color("3a4a5e"),
		"exits": {
			"west": {"to": &"A2"},
			"east": {"to": &"A4"},
			"south": {"to": &"B3"},
		},
		"items": [
			{"cell": Vector2i(10, 7), "item": &"access_keycard"},
		],
	},
	&"A4": {
		"name": "Locked Storage",
		"floor": Color("14191f"), "wall": Color("2e3a48"),
		"exits": {
			"west": {"to": &"A3"},
		},
	},

	# ---- Row B ------------------------------------------------------------
	&"B1": {
		"name": "Main Concourse",
		"floor": Color("26303f"), "wall": Color("47607e"),
		"exits": {
			"north": {"to": &"A1"},
			"east": {"to": &"B2"},
			"south": {"to": &"C1"},
		},
		"npcs": [
			{"cell": Vector2i(7, 7), "name": "Trevor Flurry", "dialogue": &"janitor", "color": Color("5a6e4a")},
			{"cell": Vector2i(13, 7), "name": "Business Traveler", "dialogue": &"traveler", "color": Color("8a7a5a")},
		],
	},
	&"B2": {
		"name": "Lower Docks",
		"floor": Color("1f2733"), "wall": Color("3e5168"),
		"exits": {
			"north": {"to": &"A2"},
			"west": {"to": &"B1"},
			"east": {"to": &"B3"},
			"south": {"to": &"C2"},
		},
		"npcs": [
			{"cell": Vector2i(10, 7), "name": "Cynical Dock Worker", "dialogue": &"dock_worker", "color": Color("7a5a3a")},
		],
	},
	&"B3": {
		"name": "Ventilation Shaft",
		"floor": Color("161d26"), "wall": Color("2f3e4f"),
		"exits": {
			"north": {"to": &"A3"},
			"west": {"to": &"B2"},
			"east": {"to": &"B4", "lock": {"flag": &"gate_unlocked", "msg": "RESTRICTED GATE -- sealed. Someone needs to slice the security grid."}},
		},
	},
	&"B4": {
		"name": "Restricted Gate",
		"floor": Color("261c1c"), "wall": Color("6e3a3a"),
		"exits": {
			"west": {"to": &"B3"},
			"south": {"to": &"C4"},
		},
	},

	# ---- Row C ------------------------------------------------------------
	&"C1": {
		"name": "Trash Compactor",
		"floor": Color("1a1f1a"), "wall": Color("3a4a3a"),
		"exits": {
			"north": {"to": &"B1"},
			"east": {"to": &"C2"},
			"south": {"to": &"D1"},
		},
	},
	&"C2": {
		"name": "Engine Room",
		"floor": Color("2b241a"), "wall": Color("6e5a3a"),
		"exits": {
			"north": {"to": &"B2"},
			"west": {"to": &"C1"},
			"south": {"to": &"D2", "lock": {"item": &"access_keycard", "msg": "CARGO BAY keypad locked. [Access Keycard required]"}},
		},
		"npcs": [
			{"cell": Vector2i(10, 8), "name": "Station Technician", "dialogue": &"technician", "color": Color("4a7a6e")},
		],
	},
	&"C3": {
		"name": "Smuggler's Hangar",
		"floor": Color("202a32"), "wall": Color("3a5a6e"),
		"exits": {
			"east": {"to": &"C4"},
		},
		"npcs": [
			{"cell": Vector2i(10, 8), "name": "The Smuggler", "dialogue": &"smuggler", "color": Color("8a6a4a")},
		],
	},
	&"C4": {
		"name": "Fuel Depot",
		"floor": Color("2a2620"), "wall": Color("5a4a3a"),
		"exits": {
			"north": {"to": &"B4"},
			"west": {"to": &"C3"},
		},
	},

	# ---- Row D ------------------------------------------------------------
	&"D1": {
		"name": "Life Support",
		"floor": Color("1a2426"), "wall": Color("3a5a5a"),
		"exits": {
			"north": {"to": &"C1"},
			"east": {"to": &"D2"},
		},
	},
	&"D2": {
		"name": "Cargo Bay",
		"floor": Color("222a36"), "wall": Color("44566e"),
		"exits": {
			"north": {"to": &"C2"},
			"west": {"to": &"D1"},
			"east": {"to": &"D3"},
		},
		"crates": [Vector2i(6, 6), Vector2i(8, 9), Vector2i(13, 6), Vector2i(14, 9)],
		"plates": [Vector2i(10, 6), Vector2i(10, 7), Vector2i(10, 8)],
		"puzzle": {
			"solve_flag": &"d2_cache_open",
			"reward": {"item": &"power_core", "cell": Vector2i(10, 2)},
		},
	},
	&"D3": {
		"name": "Comm. Array",
		"floor": Color("1c2230"), "wall": Color("3a4a6e"),
		"exits": {
			"west": {"to": &"D2"},
			"east": {"to": &"D4"},
		},
	},
	&"D4": {
		"name": "Air-Lock",
		"floor": Color("10141c"), "wall": Color("2a3344"),
		"exits": {
			"west": {"to": &"D3"},
		},
	},
}


static func get_room(id: StringName) -> Dictionary:
	return ROOMS.get(id, {})


static func has_room(id: StringName) -> bool:
	return ROOMS.has(id)
