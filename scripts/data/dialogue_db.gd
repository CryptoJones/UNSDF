class_name DialogueDB
extends RefCounted
## All NPC dialogue, as plain data. The DialogueManager interprets it.
##
## A tree is { node_id: node, ... } plus optional "_start_if".
## node  = { "text": String, "next": id?, "choices": [choice]?, plus node actions }
## choice= { "text": String, "goto": id?, plus actions and requirements }
##
## Actions (run when a node is entered / a choice is taken):
##   "set_flag": StringName, "give": StringName, "take": StringName
## Requirements (a choice is hidden unless all pass):
##   "require_item": StringName, "require_flag": StringName, "require_not_flag": StringName
## "_start_if" = [[flag, node_id], ...] picks the opening node by world state.

static var TREES := {
	&"recruiter": {
		"root": {
			"set_flag": &"met_recruiter",
			"text": "Next! ...Oh. It's you again. I told you, recruit: the UNSDF doesn't take 'volunteers' with your disciplinary history. Leave the port before Security tags you a vagrant.",
			"choices": [
				{"text": "\"I have nowhere else to go.\"", "goto": "stuck"},
				{"text": "\"Is there anyone else hiring?\"", "goto": "docks"},
			],
		},
		"stuck": {
			"set_flag": &"quest_started",
			"text": "That sounds like a personal logistics failure. Not my problem.",
		},
		"docks": {
			"set_flag": &"quest_started",
			"text": "Check the lower docks. Sometimes the 'freelancers' need extra hands for high-risk cargo. Don't mention my name.",
		},
	},

	&"janitor": {
		"root": {
			"set_flag": &"heard_keycard_hint",
			"text": "Looking for a way out? Don't bother with the main gate; security's tighter than a vacuum seal. I saw a grease-monkey drop an Access Keycard near the Maintenance Corridor. If you're smart, you'll crawl the vents in B3 to get there. Don't let the cameras in A2 catch you.",
		},
	},

	&"traveler": {
		"root": {
			"set_flag": &"heard_camera_hint",
			"text": "The UNSDF locked down Gate 4 — 'authorized personnel only.' But those cameras in A2 run a simple patrol loop. If you're going to try it, wait for the red light to blink twice. That's the reset interval.",
		},
	},

	&"dock_worker": {
		"root": {
			"set_flag": &"heard_technician_hint",
			"text": "You look like the UNSDF just crushed your dreams. Welcome to the club. Want off this rock? Quit loitering and find the Technician in the Engine Room. She's been trying to bypass the security grid for days.",
		},
	},

	&"technician": {
		"_start_if": [[&"gate_unlocked", "done"]],
		"root": {
			"text": "UNSDF won't let you board, huh? Figures — they only protect their own. Listen: bring me a Power Core from the Cargo Bay and I'll slice the security gate to the Smuggler's Hangar. Deal?",
			"choices": [
				{"text": "\"Here's your Power Core.\"", "require_item": &"power_core", "goto": "give"},
				{"text": "\"Deal. I'll find your core.\"", "require_not_flag": &"gate_unlocked", "goto": "accept"},
				{"text": "\"Why help me?\"", "goto": "why"},
			],
		},
		"give": {
			"take": &"power_core",
			"set_flag": &"gate_unlocked",
			"text": "...The real thing. Hold still — (sparks) — there. The Restricted Gate's open. B4, then through the Fuel Depot. Patrol drones reset their sweep every few minutes. Move.",
		},
		"accept": {
			"set_flag": &"quest_core_active",
			"text": "Hurry. The Power Core's in the Cargo Bay, behind a keypad. And don't trip the cameras in A2.",
		},
		"why": {
			"text": "I don't like the UNSDF any more than you do. Watching a kid sneak past them? That's entertainment.",
			"goto": "root",
		},
		"done": {
			"text": "Gate's already open. What are you still doing here? Go — before the next sweep.",
		},
	},

	&"smuggler": {
		"root": {
			"text": "You're not on the manifest. And you're not UNSDF. Which means you're either a spy or you're desperate. Which one is it?",
			"choices": [
				{"text": "\"I'm desperate. I need a seat on that ship.\"", "goto": "yes"},
				{"text": "\"I'm just passing through.\"", "goto": "no"},
			],
		},
		"yes": {
			"set_flag": &"demo_clear",
			"text": "Desperate is good. Desperate is cheap. Throw your bags in the hold — we launch in five minutes, with or without clearance.",
		},
		"no": {
			"text": "Then pass through quickly, before I decide to turn you over to the station guards for the bounty.",
		},
	},
}


static func get_tree(id: StringName) -> Dictionary:
	return TREES.get(id, {})
