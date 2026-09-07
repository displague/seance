class_name HauntRules
extends RefCounted
## Public environmental events. No entitlement, voice, possession or scoring changes.

const ROOMS = ["Séance Parlour", "Library", "Conservatory", "Memorial Chapel"]
const COST = 20.0
const DURATION = 16.0


static func initial() -> Dictionary:
	return {
		"id": 0,
		"kind": "",
		"room": "",
		"remaining": 0.0,
		"cooldown": 0.0,
		"clock": 0.0,
		"storm_id": 0,
		"storm_age": 20.0,
		"next_storm": 32.0
	}


static func tick(state: Dictionary, delta: float) -> void:
	var haunt: Dictionary = state.haunt
	haunt.clock += delta
	haunt.storm_age += delta
	haunt.remaining = maxf(0, haunt.remaining - delta)
	haunt.cooldown = maxf(0, haunt.cooldown - delta)
	if haunt.remaining <= 0:
		haunt.kind = ""
		haunt.room = ""
	if haunt.clock >= haunt.next_storm:
		haunt.storm_id += 1
		haunt.storm_age = 0.0
		haunt.next_storm = haunt.clock + 43.0 + (haunt.storm_id % 3) * 7.0


static func act(state: Dictionary, role: String, action: String, room: String) -> String:
	if not ROOMS.has(room) or state.phase not in ["investigation", "seance"]:
		return "Choose a room before the final judgment."
	if action == "calm":
		if role == "ghost" or state.haunt.room != room or state.haunt.kind == "":
			return "Only a living guest can steady an active cold spot."
		if CaseData.room_at(state.positions[role]) != room:
			return "Enter the affected room first."
		state.haunt.remaining = 0.0
		state.haunt.kind = ""
		state.haunt.room = ""
		return ""
	if action not in ["breeze", "weep"] or role != "ghost":
		return "Only the Ghost can chill the house."
	if state.energy < COST or state.haunt.cooldown > 0:
		return "A cold spot needs 20 energy and a 20-second recovery."
	state.energy -= COST
	state.haunt.id += 1
	state.haunt.kind = action
	state.haunt.room = room
	state.haunt.remaining = DURATION
	state.haunt.cooldown = 20.0
	return ""
