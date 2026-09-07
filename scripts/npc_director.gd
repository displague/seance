class_name NpcDirector
extends RefCounted
## Goal-driven physical play for AI solo. Movement follows authored safe corridors;
## all collection, disclosures, preparations and transfers pass through GameRules.act.

const PLANS = {
	"medium": ["collect:vial", "collect:flowers", "task:radio", "task:candles"],
	"heir": ["collect:ring", "collect:will"],
	"widow": ["collect:locket", "collect:letter"],
	"doctor": ["collect:ledger", "collect:vial"],
	"keeper": ["collect:birth", "collect:key"]
}


static func tick(game, delta: float) -> void:
	if game.state.phase != "investigation":
		return
	for npc in PLANS:
		if game.humans.has(npc):
			continue
		var progress: Dictionary = game.state.npc_routes.get(
			npc, {"index": 0, "path": [], "round": game.state.round}
		)
		if progress.round != game.state.round:
			progress.path.clear()
			progress.round = game.state.round
		game.state.npc_routes[npc] = progress
		if progress.index >= PLANS[npc].size():
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
		if unavailable:
			progress.index += 1
			progress.path.clear()
			continue
		if game.nearby(npc, id):
			var payload = {"id": id}
			if action == "task":
				# This plan uses only the radio's written tuning card and the candle
				# inscription. No locked document or hidden safe answer is consulted.
				payload.answer = "88.7" if id == "radio" else "MOON,THORN,KEY"
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
			continue
		if progress.path.is_empty():
			progress.path = route(game.state.positions[npc], CaseData.object_data(id).pos)
		if not progress.path.is_empty():
			var here: Vector3 = game.state.positions[npc]
			var next: Vector3 = progress.path[0]
			var moved = here.move_toward(next, minf(delta, 0.1) * 1.65)
			if CaseData.is_walkable(moved):
				game.state.positions[npc] = moved
			if here.distance_to(next) < 0.15:
				progress.path.pop_front()


static func route(start: Vector3, destination: Vector3) -> Array:
	var points: Array = []
	var start_room = CaseData.room_at(start)
	var end_room = CaseData.room_at(destination)
	if start_room != end_room:
		match start_room:
			"Library":
				points.append_array([Vector3(-10, 0, 0), Vector3(-6, 0, 0), Vector3(-6, 0, -6)])
			"Conservatory":
				points.append_array([Vector3(10, 0, 0), Vector3(6, 0, 0), Vector3(6, 0, -6)])
			"Memorial Chapel":
				points.append_array([Vector3(0, 0, -10.5), Vector3(0, 0, -6)])
			_:
				var side = -6.0 if start.x <= 0 else 6.0
				points.append_array([Vector3(side, 0, start.z), Vector3(side, 0, -6)])
		match end_room:
			"Library":
				points.append_array([Vector3(-6, 0, -6), Vector3(-6, 0, 0), Vector3(-10, 0, 0)])
			"Conservatory":
				points.append_array([Vector3(6, 0, -6), Vector3(6, 0, 0), Vector3(10, 0, 0)])
			"Memorial Chapel":
				points.append_array([Vector3(0, 0, -6), Vector3(0, 0, -10.5)])
			_:
				points.append(Vector3(0, 0, -6))
	var end = destination
	end.y = 0
	if end_room == "Séance Parlour" and Vector2(end.x, end.z).length() < 3:
		end = Vector3(0, 0, -2.9)
	points.append(end)
	return points
