class_name PlaytestTools
extends RefCounted
## Capability-scoped, JSON-only adapter. The coordinator owns time and match setup.
## Actors never receive GameRules, source files, hidden clue text or debug commands.

const ROOMS = {
	"Séance Parlour": Vector3(0, 0, -6),
	"Library": Vector3(-10, 0, -1.5),
	"Conservatory": Vector3(10, 0, 1.5),
	"Memorial Chapel": Vector3(0, 0, -10)
}
const ACTIONS = [
	"collect",
	"reveal",
	"destroy",
	"give",
	"task",
	"manifest",
	"possess",
	"silence",
	"breeze",
	"weep",
	"calm",
	"vote"
]
const PAYLOAD_KEYS = {
	"collect": ["id"],
	"reveal": ["id"],
	"destroy": ["id"],
	"give": ["id", "target"],
	"task": ["id", "answer"],
	"manifest": ["word"],
	"possess": ["target"],
	"silence": ["target"],
	"breeze": ["target"],
	"weep": ["target"],
	"calm": ["target"],
	"vote": ["culprit", "heir", "ending"]
}
const TABLES = [
	Rect2(4.7, -5.8, 2.2, 0.8),
	Rect2(-13.7, -3.475, 3.4, 1.15),
	Rect2(-14.7, 2.3, 2.4, 1.0),
	Rect2(-10.6, -0.4, 0.8, 0.8),
	Rect2(10.45, -3.375, 3.1, 1.15),
	Rect2(12, 1.975, 2.4, 0.85),
	Rect2(9.875, -0.6, 0.85, 1.2),
	Rect2(11.65, -1.8, 0.7, 0.6),
	Rect2(-3.3, -12.55, 1.2, 1.1),
	Rect2(2.1, -12.55, 1.2, 1.1),
	Rect2(-1.55, -13.95, 3.1, 1.1)
]
const INSTRUCTIONS = """You are one of six guests in The Ashwood Inheritance. You each have three personal objectives worth 2, 3 and 5 points; preparations add one point each, up to three. Cooperation on one objective need not imply cooperation on another.
The match has three investigation/séance cycles, then final judgment. A timer reaching zero ends the current phase, not necessarily the match. Investigation lets living guests explore, collect evidence or inheritance, and solve three ritual apparatuses. Inspect an object close up; collect evidence to read its full text. Your journal preserves owned or publicly revealed evidence. Reveal shares a clue with everyone; destroy removes your unrevealed evidence. Give transfers an object you own to another living guest. A claim or gift of an inheritance object is public; privately recovered evidence need not be disclosed.
Living guests hear each other throughout. Only the Medium hears ghost speech during a séance; a possessed vessel can also hear the ghost temporarily. The ghost can send limited public signs, spend energy on manifestations or curses, and never controls another player's movement. The Medium may faithfully relay, distort or withhold the ghost's testimony.
At judgment, every guest submits one sealed ballot naming a culprit (heir, widow, doctor, keeper, or none), an heir (heir, widow, doctor, keeper), and a fate (release, bind, banish). Release requires two completed preparations. The most votes decide each category; ties acquit, preserve Julian's inheritance, or banish respectively. Scores depend on the accepted result and held objects, not on winning a fixed team vote. The end screen lists all players and completed objectives. No gameplay tools spend money.
Explain only what your friends need next, and answer their questions socially. Do not disclose your private dossier merely because you are teaching."""

var game: GameRules
var teacher: String
var capabilities: Dictionary = {}
var submitted_by_actor: Array = []
var instruction_reads: Dictionary = {}
var navigation = AStarGrid2D.new()


func _init(match_rules: GameRules, teacher_role: String = "medium") -> void:
	game = match_rules
	teacher = teacher_role
	navigation.region = Rect2i(-32, -30, 65, 49)
	navigation.cell_size = Vector2(0.5, 0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in range(-32, 33):
		for z in range(-30, 19):
			navigation.set_point_solid(Vector2i(x, z), not walkable(Vector3(x * 0.5, 0, z * 0.5)))


func grant(token: String, role: String, viewer: bool = false, stream_role: String = "") -> bool:
	if token.length() < 24 or capabilities.has(token):
		return false
	if not viewer and not CaseData.ROLES.has(role):
		return false
	if viewer and stream_role != "" and not CaseData.ROLES.has(stream_role):
		return false
	capabilities[token] = {"role": role, "viewer": viewer, "stream_role": stream_role}
	return true


func revoke(token: String) -> void:
	capabilities.erase(token)


func authorized(token: String) -> bool:
	return capabilities.has(token)


func tool_list(token: String) -> Array:
	if not authorized(token):
		return []
	var scope: Dictionary = capabilities[token]
	var result = [
		_tool(
			"observe", "Look at the current room, visible objects, guests, phase and heard speech."
		),
		_tool("journal", "Read your own dossier and known evidence, or your spectator feed.")
	]
	if scope.viewer:
		return result
	(
		result
		. append_array(
			[
				_tool(
					"inspect",
					"Examine a nearby object or reread evidence you own or that is public.",
					{"id": {"type": "string"}},
					["id"]
				),
				_tool(
					"walk",
					"Walk to a visible object or a connected room named in observe. Returns travel_seconds; the coordinator controls the test clock.",
					{"destination": {"type": "string"}},
					["destination"]
				),
				_tool(
					"speak",
					"Speak in character through the game's current listening channels.",
					{"text": {"type": "string", "maxLength": 240}},
					["text"]
				),
				_action_tool(scope.role)
			]
		)
	)
	if scope.role == teacher:
		result.append(
			_tool(
				"read_instructions",
				"Read the game guide. Only the designated teaching player has this tool."
			)
		)
	return result


func call_tool(token: String, name: String, arguments: Dictionary = {}) -> Dictionary:
	if not authorized(token):
		return _error("Invalid or revoked seat capability.")
	var scope: Dictionary = capabilities[token]
	if scope.viewer:
		if name in ["observe", "journal"]:
			return _viewer(scope)
		return _error("Viewers cannot control players or read the teacher's instructions.")
	var role: String = scope.role
	match name:
		"observe":
			return observe(role)
		"journal":
			return journal(role)
		"inspect":
			if not arguments.get("id") is String or arguments.id == "":
				return _error("inspect requires arguments {id: a visible object id}.")
			return inspect(role, str(arguments.get("id", "")))
		"walk":
			if not arguments.get("destination") is String or arguments.destination == "":
				return _error(
					"walk requires arguments {destination: a visible object id or connected room name}."
				)
			return walk(role, str(arguments.get("destination", "")))
		"speak":
			if not arguments.get("text") is String or arguments.text.strip_edges() == "":
				return _error(
					"speak requires arguments {text: words you want other characters to hear}."
				)
			return _action(role, "chat", {"text": arguments.get("text", "")})
		"act":
			if not arguments.get("payload") is Dictionary:
				return _error(
					"act requires arguments {action: a verb, payload: an object with the verb's required fields}."
				)
			var action = str(arguments.get("action", ""))
			if not ACTIONS.has(action):
				return _error("No such player action.")
			for key in PAYLOAD_KEYS[action]:
				if not arguments.payload.get(key) is String or arguments.payload[key] == "":
					return _error(
						(
							"Action %s requires text fields in payload: %s."
							% [action, ", ".join(PAYLOAD_KEYS[action])]
						)
					)
			return _action(role, action, arguments.get("payload", {}))
		"read_instructions":
			if role != teacher:
				return _error("Ask the designated teaching player how to play.")
			instruction_reads[role] = int(instruction_reads.get(role, 0)) + 1
			return {"ok": true, "instructions": INSTRUCTIONS}
	return _error("Unknown tool.")


func observe(role: String) -> Dictionary:
	var room = CaseData.room_at(game.state.positions[role])
	var guests: Array = []
	for guest in CaseData.ROLES:
		var person = CaseData.person(guest)
		guests.append(
			{
				"role": guest,
				"name": person.name,
				"title": person.title,
				"visible_here": CaseData.room_at(game.state.positions[guest]) == room
			}
		)
	var result = _public()
	result.merge(
		{
			"role": role,
			"room": room,
			"guests": guests,
			"visible_objects": _objects(room),
			"exits": _exits(room),
			"messages": game.state.private_log[role].duplicate(),
			"dossier": _dossier(role),
			"available_actions": _affordances(role),
			"testament_submitted": game.state.votes.has(role),
			"hearable_speakers": _speakers(role),
			"possessed": game.state.possession == role
		}
	)
	if role == "ghost":
		result.energy = snappedf(float(game.state.energy), 0.1)
	return result


func journal(role: String) -> Dictionary:
	var evidence: Array = []
	for id in CaseData.CLUES:
		if _known(role, id):
			evidence.append(_clue(role, id))
	var held: Array = []
	for id in game.state.items:
		if game.state.items[id] == role:
			held.append(
				{
					"id": id,
					"name": CaseData.ITEMS[id].name,
					"description": CaseData.ITEMS[id].description
				}
			)
	return {
		"ok": true,
		"dossier": _dossier(role),
		"chapter": CaseProgression.view_for(game.state),
		"evidence": evidence,
		"held_items": held,
		"messages": game.state.private_log[role].duplicate(),
		"events": game.state.journal.duplicate()
	}


func inspect(role: String, id: String) -> Dictionary:
	var data = CaseData.object_data(id)
	if data.is_empty():
		return _error("No visible object has that id.")
	if game.state.evidence.has(id) and _known(role, id):
		return {"ok": true, "object": _clue(role, id)}
	if not game.nearby(role, id) or CaseData.room_at(game.state.positions[role]) != data.room:
		return _error("Move close to an object in your current room before inspecting it.")
	if game.state.evidence.has(id):
		var clue: Dictionary = game.state.evidence[id]
		if clue.holder != "" or clue.destroyed:
			return _error("The object is no longer here.")
		return {
			"ok": true,
			"object":
			{
				"id": id,
				"name": data.name,
				"summary": data.summary,
				"actions": ["collect"] if _probe(role, "collect", {"id": id}) == "" else [],
				"note":
				(
					CaseProgression.lock_message(id)
					if CaseProgression.locked(game.state, id)
					else (
						"Collect enters this fixed reference in the public record immediately; it cannot be carried, concealed or destroyed."
						if data.get("reference", false)
						else "Collect to examine and keep the full evidence."
					)
				)
			}
		}
	if game.state.items.has(id):
		return {
			"ok": true,
			"object":
			{
				"id": id,
				"name": data.name,
				"description": data.description,
				"holder": game.state.items[id],
				"actions": ["collect"] if _probe(role, "collect", {"id": id}) == "" else []
			}
		}
	var apparatus = {
		"id": id,
		"name": data.name,
		"description": data.description,
		"completed_by": game.state.tasks[id],
		"availability":
		(
			CaseProgression.lock_message(id)
			if CaseProgression.locked(game.state, id)
			else "Unsealed; any living guest may prepare during investigation."
		),
		"actions": ["task"] if _task_ready(role, id) else [],
		"answer_format": "text"
	}
	if id == "candles":
		apparatus.symbols = ["MOON", "THORN", "KEY", "SUN", "ASH"]
		apparatus.answer_format = "Three symbols separated by commas, for example SUN,ASH,MOON."
	elif id == "radio":
		apparatus.answer_format = "Frequency from 80.0 to 100.0 with one decimal place."
	elif id == "safe":
		apparatus.answer_format = "Four digits."
	return {"ok": true, "object": apparatus}


func walk(role: String, destination: String) -> Dictionary:
	if game.state.phase == "ended":
		return _error("The case has ended. Read the final results.")
	var room = CaseData.room_at(game.state.positions[role])
	var target: Vector3
	if ROOMS.has(destination):
		if destination != room and not _exits(room).has(destination):
			return _error("That room is not directly connected. Follow the listed exits.")
		target = ROOMS[destination]
	else:
		var visible: Array = _objects(room).map(func(entry): return entry.id)
		if not visible.has(destination):
			return _error("Choose a room exit or an object visible in your current room.")
		target = CaseData.object_data(destination).pos
	var start: Vector3 = game.state.positions[role]
	var begin = _nearest(start)
	var end = _nearest(target, begin)
	var ids = navigation.get_id_path(begin, end)
	if ids.is_empty():
		return _error("No walkable route reaches that destination.")
	var distance = 0.0
	var steps = 0
	for cell in ids:
		var point = Vector3(cell.x * 0.5, 0, cell.y * 0.5)
		while start.distance_to(point) > 0.001:
			var next = start.move_toward(point, 0.1)
			if not walkable(next):
				return _error("A physical obstruction blocks the route.")
			distance += start.distance_to(next)
			steps += 1
			game.state.positions[role] = next
			start = next
	return {
		"ok": true,
		"room": CaseData.room_at(start),
		"destination": destination,
		"travel_seconds": snappedf(distance / 3.2, 0.01),
		"movement_steps": steps,
		"visible_objects": _objects(CaseData.room_at(start))
	}


static func walkable(point: Vector3) -> bool:
	if not CaseData.is_walkable(point):
		return false
	if Vector2(point.x, point.z).length() < 2.75:
		return false
	# The room footprint alone permits walking through partition walls. Apertures
	# and furniture mirror the current manor, with clearance for the player capsule.
	if absf(absf(point.x) - 8) < 0.48 and absf(point.z) > 1.25:
		return false
	if absf(point.z + 9) < 0.48 and absf(point.x) > 1.25:
		return false
	for table in TABLES:
		if table.grow(0.32).has_point(Vector2(point.x, point.z)):
			return false
	return true


func _nearest(point: Vector3, reachable_from: Vector2i = Vector2i(1000, 1000)) -> Vector2i:
	var best = Vector2i.ZERO
	var distance = INF
	for x in range(-32, 33):
		for z in range(-30, 19):
			var cell = Vector2i(x, z)
			if navigation.is_point_solid(cell):
				continue
			var candidate = Vector3(x * 0.5, 0, z * 0.5).distance_squared_to(
				Vector3(point.x, 0, point.z)
			)
			if candidate < distance:
				if (
					reachable_from != Vector2i(1000, 1000)
					and navigation.get_id_path(reachable_from, cell).is_empty()
				):
					continue
				distance = candidate
				best = cell
	return best


func _action(role: String, action: String, payload: Dictionary) -> Dictionary:
	if JSON.stringify(payload).length() > 2048:
		return _error("Action payload too large.")
	var error = game.act(role, action, payload)
	if error != "":
		return _error(error)
	if action == "vote" and not submitted_by_actor.has(role):
		submitted_by_actor.append(role)
	var result = {
		"ok": true, "action": action, "messages": game.state.private_log[role].duplicate()
	}
	if action == "collect":
		result.journal = journal(role)
	return result


func _public() -> Dictionary:
	var public_evidence: Array = []
	for id in CaseData.CLUES:
		if game.state.evidence[id].public:
			public_evidence.append(
				{"id": id, "name": CaseData.CLUES[id].name, "text": CaseData.CLUES[id].text}
			)
	var result = {
		"ok": true,
		"phase": game.state.phase,
		"sitting": game.state.round,
		"remaining_seconds": int(ceil(game.state.remaining)),
		"events": game.state.journal.duplicate(),
		"public_evidence": public_evidence,
		"preparations": game.preparations(),
		"last_spirit_sign": game.state.manifest_word,
		"inheritance_claims": game.state.items.duplicate()
	}
	result.phase_info = RoundSummary.phase_info(game.state)
	result.chapter = CaseProgression.view_for(game.state)
	result.recap = game.state.get("recap", {}).duplicate(true)
	result.haunt = {
		"kind": game.state.haunt.kind,
		"room": game.state.haunt.room,
		"remaining_seconds": int(ceil(game.state.haunt.remaining))
	}
	if game.state.phase == "ended":
		result.ending = game.state.ending.duplicate(true)
		result.scores = game.state.scores.duplicate(true)
		result.final_summary = game.state.get("final_summary", {}).duplicate(true)
		result.actor_ballots = submitted_by_actor.duplicate()
		result.automatic_ballots = CaseData.ROLES.filter(
			func(role): return not submitted_by_actor.has(role)
		)
	return result


func _viewer(scope: Dictionary) -> Dictionary:
	if scope.stream_role == "":
		var public_view = _public()
		public_view.feed = "public only; no player private messages or motives"
		return public_view
	var stream = observe(scope.stream_role)
	stream.feed = "one consenting stream: " + scope.stream_role
	stream.stream_journal = journal(scope.stream_role)
	return stream


func _dossier(role: String) -> Dictionary:
	var data: Dictionary = CaseData.person(role)
	return {
		"name": data.name,
		"title": data.title,
		"bio": data.bio,
		"secret": data.secret,
		"rumor": data.rumor,
		"objectives": data.goals.duplicate(),
		"objective_points": [2, 3, 5],
		"completed": game.completed_goals(role),
		"task_points": game.state.task_points[role]
	}


func _known(role: String, id: String) -> bool:
	var clue: Dictionary = game.state.evidence[id]
	return clue.public or clue.holder == role


func _clue(role: String, id: String) -> Dictionary:
	var clue: Dictionary = game.state.evidence[id]
	return {
		"id": id,
		"name": CaseData.CLUES[id].name,
		"text": CaseData.CLUES[id].text,
		"public": clue.public,
		"owned": clue.holder == role,
		"destroyed": clue.destroyed
	}


func _objects(room: String) -> Array:
	var result: Array = []
	for id in CaseData.CLUES.keys() + CaseData.ITEMS.keys() + CaseData.TASKS.keys():
		var data = CaseData.object_data(id)
		if data.room != room:
			continue
		if (
			game.state.evidence.has(id)
			and (game.state.evidence[id].holder != "" or game.state.evidence[id].destroyed)
		):
			continue
		if game.state.items.has(id) and game.state.items[id] != "":
			continue
		result.append(
			{
				"id": id,
				"name": data.name,
				"kind": "apparatus" if CaseData.TASKS.has(id) else "object",
				"availability":
				(
					CaseProgression.lock_message(id)
					if CaseProgression.locked(game.state, id)
					else "Unsealed"
				)
			}
		)
	return result


func _exits(room: String) -> Array:
	if room == "Séance Parlour":
		return ["Library", "Conservatory", "Memorial Chapel"]
	return ["Séance Parlour"]


func _speakers(role: String) -> Array:
	return CaseData.ROLES.filter(func(speaker): return game.can_hear(speaker, role))


func _affordances(role: String) -> Dictionary:
	var result: Dictionary = {}
	if game.state.phase == "ended":
		return result
	if _probe(role, "vote", {"culprit": "none", "heir": "heir", "ending": "banish"}) == "":
		var endings = ["bind", "banish"]
		if _probe(role, "vote", {"culprit": "none", "heir": "heir", "ending": "release"}) == "":
			endings.push_front("release")
		result.vote = {
			"culprit": ["heir", "widow", "doctor", "keeper", "none"],
			"heir": ["heir", "widow", "doctor", "keeper"],
			"ending": endings,
			"required_payload": PAYLOAD_KEYS.vote,
			"note": "Choose all three values; no ballot choice is preselected for you."
		}
	if role == "ghost":
		if _probe(role, "manifest", {"word": "KNOCK"}) == "":
			result.manifest = {
				"word":
				[
					"YES",
					"NO",
					"DANGER",
					"BLOOD",
					"BETRAYAL",
					"MINE",
					"NOT THEM",
					"RELEASE",
					"KNOCK"
				],
				"cost": 15,
				"payload_example": {"word": "KNOCK"}
			}
		for action in ["possess", "silence"]:
			if _probe(role, action, {"target": "heir"}) == "":
				result[action] = {
					"target": ["heir", "widow", "doctor", "keeper"],
					"cost": 40 if action == "possess" else 25,
					"payload_example": {"target": "heir"}
				}
		for action in ["breeze", "weep"]:
			if _probe(role, action, {"target": "Library"}) == "":
				result[action] = {
					"target": ROOMS.keys(), "cost": 20, "payload_example": {"target": "Library"}
				}
		return result
	var targets: Array = CaseData.ROLES.filter(
		func(target): return target != role and target != "ghost"
	)
	var room = CaseData.room_at(game.state.positions[role])
	for action in ["collect", "reveal", "destroy", "give"]:
		var ids: Array = []
		for id in CaseData.CLUES.keys() + CaseData.ITEMS.keys():
			if action == "collect" and CaseData.object_data(id).room != room:
				continue
			var payload = {"id": id}
			if action == "give":
				payload.target = targets[0]
			if _probe(role, action, payload) == "":
				ids.append(id)
		if not ids.is_empty():
			result[action] = {"id": ids, "payload_example": {"id": ids[0]}}
			if action == "give":
				result[action].target = targets
				result[action].payload_example.target = targets[0]
	var tasks: Array = []
	for id in CaseData.TASKS:
		if _task_ready(role, id):
			tasks.append(id)
	if not tasks.is_empty():
		result.task = {
			"id": tasks,
			"answer": "Read the apparatus inscription and supply your solution as text.",
			"required_payload": PAYLOAD_KEYS.task
		}
	if _probe(role, "calm", {"target": game.state.haunt.room}) == "":
		result.calm = {
			"target": [game.state.haunt.room], "payload_example": {"target": game.state.haunt.room}
		}
	return result


func _probe(role: String, action: String, payload: Dictionary) -> String:
	# Derive button availability from the actual rules, without changing the match
	# or returning the probe's state. This is not a second set of outcome rules.
	var preview = GameRules.new()
	preview.state = game.state.duplicate(true)
	preview.humans = game.humans.duplicate()
	return preview.act(role, action, payload)


func _task_ready(role: String, id: String) -> bool:
	# A known invalid answer checks whether the apparatus accepts an attempt.
	# Never read or expose CaseData.TASKS[id].solution to construct affordances.
	return (
		_probe(role, "task", {"id": id, "answer": "__no_solution_supplied__"})
		== "The apparatus resists. Study the inscription and try again."
	)


static func _action_tool(role: String) -> Dictionary:
	var actions = (
		["manifest", "possess", "silence", "breeze", "weep", "vote"]
		if role == "ghost"
		else ["collect", "reveal", "destroy", "give", "task", "calm", "vote"]
	)
	var variants: Array = []
	for action in actions:
		var payload = {}
		for key in PAYLOAD_KEYS[action]:
			payload[key] = {"type": "string", "minLength": 1}
		variants.append(
			{
				"type": "object",
				"properties":
				{
					"action": {"type": "string", "enum": [action]},
					"payload":
					{
						"type": "object",
						"properties": payload,
						"required": PAYLOAD_KEYS[action],
						"additionalProperties": false
					}
				},
				"required": ["action", "payload"],
				"additionalProperties": false
			}
		)
	return {
		"name": "act",
		"description":
		"Perform a currently available action. Always provide BOTH action and payload. Use the current observation's action values and payload examples; a task needs your own answer.",
		"inputSchema": {"type": "object", "anyOf": variants}
	}


static func _tool(
	name: String, description: String, properties: Dictionary = {}, required: Array = []
) -> Dictionary:
	return {
		"name": name,
		"description": description,
		"inputSchema":
		{
			"type": "object",
			"properties": properties,
			"required": required,
			"additionalProperties": false
		}
	}


static func _error(message: String) -> Dictionary:
	return {"ok": false, "error": message}
