class_name NpcDirector
extends RefCounted
## Goal-driven physical play for solo. Movement follows authored safe corridors;
## all collection, disclosures, preparations and transfers pass through GameRules.act.

const PLANS = {
	"medium": ["collect:vial", "task:candles", "task:radio", "task:safe", "collect:flowers"],
	"heir": ["collect:ring", "collect:will"],
	"widow": ["collect:locket", "collect:letter"],
	"doctor": ["collect:ledger", "collect:vial"],
	"keeper": ["collect:birth", "collect:key"]
}
const CIRCUITS = {
	"medium": [Vector3(0, 0, -10), Vector3(-10, 0, -1.5), Vector3(10, 0, 1.5)],
	"heir": [Vector3(-10, 0, 1.5), Vector3(0, 0, -10), Vector3(5, 0, -6)],
	"widow": [Vector3(10, 0, 1.5), Vector3(0, 0, -10), Vector3(-5, 0, -6)],
	"doctor": [Vector3(-10, 0, 1.5), Vector3(10, 0, 1.5), Vector3(-5, 0, -6)],
	"keeper": [Vector3(0, 0, -10), Vector3(-10, 0, -1.5), Vector3(5, 0, -6)]
}


static func tick(game, delta: float) -> void:
	if game.state.phase != "investigation":
		return
	for npc in PLANS:
		if game.humans.has(npc):
			continue
		var progress: Dictionary = game.state.npc_routes.get(npc, fresh_progress(game.state.round))
		if progress.round != game.state.round:
			progress = fresh_progress(game.state.round)
		game.state.npc_routes[npc] = progress
		if requested_audit(game, npc, progress, delta):
			continue
		if progress.pause > 0:
			progress.pause = maxf(0, progress.pause - delta)
			continue
		if progress.index >= PLANS[npc].size():
			patrol(game, npc, progress, delta)
			continue
		var entry: String = PLANS[npc][progress.index]
		var action = entry.get_slice(":", 0)
		var id = entry.get_slice(":", 1)
		var unavailable: bool = (
			game.state.tasks[id] != ""
			if action == "task"
			else (
				game.state.items[id] != ""
				if game.state.items.has(id)
				else game.state.evidence[id].holder != "" or game.state.evidence[id].destroyed
			)
		)
		if unavailable or CaseProgression.locked(game.state, id):
			progress.index += 1
			progress.path.clear()
			continue
		if id == "safe" and not NpcRules.knows(game, npc, "birth"):
			progress.index += 1
			progress.path.clear()
			continue
		if (
			game.nearby(npc, id)
			and CaseData.room_at(game.state.positions[npc]) == CaseData.object_data(id).room
		):
			var payload = {"id": id}
			if action == "task":
				# The safe is attempted only after this NPC has learned the register.
				payload.answer = {"radio": "88.7", "candles": "MOON,THORN,KEY", "safe": "1913"}[id]
			if game.act(npc, action, payload) == "":
				game.log_event(
					(
						CaseData.person(npc).name
						+ " finished examining something in the "
						+ CaseData.object_data(id).room
						+ "."
					)
				)
			progress.index += 1
			progress.path.clear()
			progress.pause = 4.0
			continue
		if progress.path.is_empty():
			progress.path = route(game.state.positions[npc], CaseData.object_data(id).pos)
		move(game, npc, progress, delta)


static func requested_audit(game, npc: String, progress: Dictionary, delta: float) -> bool:
	if not game.state.npc.audit_requests.has(npc):
		return false
	if game.public_clue("audit"):
		game.state.npc.audit_requests.erase(npc)
		progress.path.clear()
		return false
	if CaseProgression.locked(game.state, "audit"):
		return false
	if game.nearby(npc, "audit") and CaseData.room_at(game.state.positions[npc]) == "Conservatory":
		game.act(npc, "collect", {"id": "audit"})
		game.state.npc.audit_requests.erase(npc)
		progress.path.clear()
	elif progress.path.is_empty():
		progress.path = route(game.state.positions[npc], CaseData.CLUES.audit.pos)
	else:
		move(game, npc, progress, delta)
	return true


static func fresh_progress(round_id: int) -> Dictionary:
	return {
		"index": 0, "path": [], "round": round_id, "patrol": 0, "pause": 0.0, "announced": false
	}


static func patrol(game, npc: String, progress: Dictionary, delta: float) -> void:
	if not progress.announced:
		progress.announced = true
		game.log_event(CaseData.person(npc).name + ": “" + stage_intent(game, npc) + "”")
	# Lenore acts on her own gift objective after the inheritance chapter opens.
	# Never transfer anything held by a human or accept a bargain on their behalf.
	if npc == "widow" and game.state.round >= 2 and game.state.items.locket == npc:
		game.act(npc, "give", {"id": "locket", "target": "keeper"})
	if progress.path.is_empty():
		var circuit: Array = CIRCUITS[npc]
		progress.path = route(game.state.positions[npc], circuit[progress.patrol % circuit.size()])
		progress.patrol += 1
	move(game, npc, progress, delta)
	if progress.path.is_empty():
		progress.pause = 6.0
		# Revisit objectives: another guest may have taught us a safe clue since
		# the first pass. Completed/claimed objects are skipped by the same rules.
		progress.index = 0


static func stage_intent(game, npc: String) -> String:
	var lines = {
		"medium":
		[
			"I will examine the tonic and prepare the candles.",
			"The radio is awake. We need a second preparation.",
			"The reliquary is ready for its year. Who can share the register?"
		],
		"heir":
		[
			"The signet belongs with the family. We can discuss terms.",
			"The will is unsealed. Hear its wording before choosing an heir.",
			"A Binding preserves my father's presence here. Consider it before dawn."
		],
		"widow":
		[
			"Find out who mixed the tonic, not merely who carried it.",
			"I want Iris to have the locket. There is more to inheritance than land.",
			"An independent audit is now in the Conservatory. Don't let one account settle this."
		],
		"doctor":
		[
			"A bitter plant alone proves nothing. Lenore carried the glass.",
			"A changed will does not tell us who delivered the fatal dose.",
			"Bank figures cannot tell you who held the glass. Consider Lenore's opportunity."
		],
		"keeper":
		[
			"Compare the watch with the doctor's account. The key is a keepsake, not a door to search.",
			"The register can settle my place in this family. Ask what I have found.",
			"Before you seal the will, consider the register and the final testament together."
		]
	}
	return lines[npc][clampi(int(game.state.round) - 1, 0, 2)]


static func move(game, npc: String, progress: Dictionary, delta: float) -> void:
	if progress.path.is_empty():
		return
	var here: Vector3 = game.state.positions[npc]
	var next: Vector3 = progress.path[0]
	var moved = here.move_toward(next, minf(delta, 0.1) * 1.65)
	if CaseData.is_walkable(moved):
		game.state.positions[npc] = moved
	if moved.distance_to(next) < 0.15:
		progress.path.pop_front()


static func route(start: Vector3, destination: Vector3) -> Array:
	var points: Array = []
	var start_room = CaseData.room_at(start)
	var end_room = CaseData.room_at(destination)
	if start_room != end_room or start_room == "Séance Parlour":
		match start_room:
			"Library":
				points.append_array([Vector3(-10, 0, 0), Vector3(-6, 0, 0), Vector3(-6, 0, -6)])
			"Conservatory":
				points.append_array([Vector3(10, 0, 0), Vector3(6, 0, 0), Vector3(6, 0, -6)])
			"Memorial Chapel":
				points.append_array([Vector3(0, 0, -10.5), Vector3(0, 0, -6)])
			_:
				var side = -6.0 if start.x <= 0 else 6.0
				if start.z < -8:
					points.append(Vector3(0, 0, -6))
				else:
					points.append_array([Vector3(side, 0, start.z), Vector3(side, 0, -6)])
		match end_room:
			"Library":
				points.append_array([Vector3(-6, 0, -6), Vector3(-6, 0, 0), Vector3(-10, 0, 0)])
			"Conservatory":
				points.append_array([Vector3(6, 0, -6), Vector3(6, 0, 0), Vector3(10, 0, 0)])
			"Memorial Chapel":
				points.append_array([Vector3(0, 0, -6), Vector3(0, 0, -10.5)])
			_:
				if Vector2(destination.x, destination.z).length() < 3:
					points.append(Vector3(0, 0, -6))
				else:
					var side = -6.0 if destination.x < 0 else 6.0
					points.append_array([Vector3(side, 0, -6), Vector3(side, 0, destination.z)])
	var end = destination
	end.y = 0
	if end_room == "Séance Parlour" and Vector2(end.x, end.z).length() < 3:
		end = Vector3(0, 0, -2.9)
	points.append(end)
	return points
