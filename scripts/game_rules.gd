class_name GameRules
extends RefCounted
## Pure, authoritative case state. No scene tree, RPCs, audio or UI dependencies.

var state: Dictionary = {}
var humans: Array = []


func reset(human_roles: Array = ["medium"]) -> void:
	humans = human_roles.duplicate()
	state = {
		"npc": NpcRules.initial(),
		"interactive_guests": false,
		"npc_routes": {},
		"phase": "investigation",
		"haunt": HauntRules.initial(),
		"round": 1,
		"remaining": 300.0,
		"evidence": {},
		"items": {},
		"tasks": {},
		"positions": {},
		"journal": [],
		"private_log": {},
		"energy": 70.0,
		"possession": "",
		"possession_time": 0.0,
		"silenced": "",
		"silence_time": 0.0,
		"votes": {},
		"ending": {},
		"scores": [],
		"manifest": 0,
		"manifest_word": "",
		"task_points": {},
		"discussed": {},
		"question_count": 0
	}
	for id in CaseData.CLUES:
		state.evidence[id] = {"holder": "", "public": false, "destroyed": false}
	for id in CaseData.ITEMS:
		state.items[id] = ""
	for id in CaseData.TASKS:
		state.tasks[id] = ""
	for role in CaseData.ROLES:
		state.positions[role] = CaseData.spawn_at(role)
		state.private_log[role] = []
		state.task_points[role] = 0
	RoundSummary.initialize(state)
	log_event(
		"The doors are locked. Dawn will execute the will. What happens before it belongs to you."
	)


func log_event(text: String) -> void:
	state.journal.append(text)
	if state.journal.size() > 80:
		state.journal.pop_front()


func private_event(role: String, text: String) -> void:
	state.private_log[role].append(text)
	if state.private_log[role].size() > 30:
		state.private_log[role].pop_front()


func tick(delta: float) -> bool:
	if state.is_empty() or state.phase == "ended":
		return false
	state.energy = minf(100, state.energy + delta * 0.7)
	HauntRules.tick(state, delta)
	if state.interactive_guests:
		NpcDirector.tick(self, delta)
	state.possession_time = maxf(0, state.possession_time - delta)
	state.silence_time = maxf(0, state.silence_time - delta)
	if state.possession_time <= 0:
		state.possession = ""
	if state.silence_time <= 0:
		state.silenced = ""
	state.remaining = maxf(0, state.remaining - delta)
	if state.remaining <= 0:
		advance()
		return true
	return false


func nearby(role: String, object_id: String) -> bool:
	var data = CaseData.object_data(object_id)
	if data.is_empty():
		return false
	var p: Vector3 = state.positions.get(role, Vector3(1000, 0, 1000))
	var q: Vector3 = data.pos
	p.y = 0
	q.y = 0
	return p.distance_to(q) <= 3.2


func act(role: String, action: String, payload: Dictionary = {}) -> String:
	if not CaseData.ROLES.has(role) or state.is_empty():
		return "Unknown guest."
	if state.phase == "ended":
		return "The séance is over."
	var id = str(payload.get("id", ""))
	var target = str(payload.get("target", ""))
	match action:
		"breeze", "weep", "calm":
			var error = HauntRules.act(state, role, action, target)
			if error != "":
				return error
			log_event(
				(
					("The cold recedes from " if action == "calm" else "A spirit breeze chills ")
					+ target
					+ "."
				)
			)
		"collect":
			if role == "ghost":
				return "The dead cannot carry objects. Guide the living."
			if state.phase != "investigation" or not nearby(role, id):
				return "Approach this object during investigation."
			if state.evidence.has(id):
				var clue = state.evidence[id]
				if clue.destroyed or clue.holder != "":
					return "Someone has already taken this evidence."
				clue.holder = role
				private_event(role, "Recovered: " + CaseData.CLUES[id].name)
			elif state.items.has(id):
				if state.items[id] != "":
					return "This inheritance has already been claimed."
				state.items[id] = role
				log_event(
					CaseData.person(role).name + " claimed the " + CaseData.ITEMS[id].name + "."
				)
			else:
				return "Nothing to take."
		"reveal", "destroy":
			if (
				not state.evidence.has(id)
				or state.evidence[id].holder != role
				or state.evidence[id].destroyed
			):
				return "That evidence is not yours."
			if state.evidence[id].public:
				return "The circle already knows this evidence."
			if action == "reveal":
				state.evidence[id].public = true
				log_event(
					CaseData.person(role).name + " revealed “" + CaseData.CLUES[id].name + "”."
				)
				state.energy = minf(100, state.energy + 10)
			else:
				state.evidence[id].destroyed = true
				private_event(role, "Destroyed: " + CaseData.CLUES[id].name)
		"give":
			if not CaseData.ROLES.has(target) or target == "ghost" or target == role:
				return "Choose another living guest."
			if state.items.has(id) and state.items[id] == role:
				state.items[id] = target
				log_event(
					(
						CaseData.person(role).name
						+ " gave the "
						+ CaseData.ITEMS[id].name
						+ " to "
						+ CaseData.person(target).name
						+ "."
					)
				)
			elif (
				state.evidence.has(id)
				and state.evidence[id].holder == role
				and not state.evidence[id].destroyed
			):
				state.evidence[id].holder = target
				private_event(
					target,
					CaseData.person(role).name + " passed you “" + CaseData.CLUES[id].name + "”."
				)
			else:
				return "You do not hold that object."
		"task":
			if (
				role == "ghost"
				or state.phase != "investigation"
				or not CaseData.TASKS.has(id)
				or not nearby(role, id)
			):
				return "Approach the apparatus during investigation."
			if state.tasks[id] != "":
				return "This preparation is already complete."
			if str(payload.get("answer", "")) != CaseData.TASKS[id].solution:
				return "The apparatus resists. Study the inscription and try again."
			state.tasks[id] = role
			state.task_points[role] += 1
			state.energy = minf(100, state.energy + 15)
			log_event(CaseData.person(role).name + " completed: " + CaseData.TASKS[id].name + ".")
		"manifest":
			if role != "ghost" or state.energy < 15:
				return "A manifestation needs 15 spirit energy."
			var word = str(payload.get("word", ""))
			if not (
				["YES", "NO", "DANGER", "BLOOD", "BETRAYAL", "MINE", "NOT THEM", "RELEASE", "KNOCK"]
				. has(word)
			):
				return "Choose a sign from the spirit board."
			state.energy -= 15
			state.manifest += 1
			state.manifest_word = word
			log_event("The spirit answered: " + word + ".")
		"possess":
			if role != "ghost" or state.round < 2 or state.energy < 40:
				return "Possession needs round II and 40 spirit energy."
			if not ["heir", "widow", "doctor", "keeper"].has(target):
				return "Choose a living vessel other than the Medium."
			state.energy -= 40
			state.possession = target
			state.possession_time = 60.0
			private_event(
				target,
				"Edmund is beside your thoughts. For sixty seconds, you can hear him. You remain in control."
			)
		"silence":
			if (
				role != "ghost"
				or state.energy < 25
				or not ["heir", "widow", "doctor", "keeper"].has(target)
			):
				return "Choose a living guest. Silence costs 25 spirit energy."
			state.energy -= 25
			state.silenced = target
			state.silence_time = 25.0
			log_event(
				(
					CaseData.person(target).name
					+ " is Silenced. Only the dead can hear them for twenty-five seconds."
				)
			)
		"chat":
			var message = str(payload.get("text", "")).strip_edges().replace("\n", " ").left(240)
			if message.is_empty():
				return ""
			for listener in CaseData.ROLES:
				if can_hear(role, listener) or listener == role:
					private_event(listener, CaseData.person(role).name + ": “" + message + "”")
		"vote":
			if state.phase != "judgment":
				return "The final testament is not yet open."
			if state.votes.has(role):
				return "Your testament is already sealed."
			var culprit = str(payload.get("culprit", ""))
			var heir = str(payload.get("heir", ""))
			var ending = str(payload.get("ending", ""))
			if (
				not ["heir", "widow", "doctor", "keeper", "none"].has(culprit)
				or not ["heir", "widow", "doctor", "keeper"].has(heir)
				or not ["release", "bind", "banish"].has(ending)
			):
				return "Complete all three decisions."
			if ending == "release" and preparations() < 2:
				return "Release requires two ritual preparations."
			state.votes[role] = {"culprit": culprit, "heir": heir, "ending": ending}
			log_event(CaseData.person(role).name + " sealed their final testament.")
			if all_humans_voted():
				resolve()
		"talk":
			return bot_conversation(role, target, str(payload.get("topic", "death")))
		"interact":
			return NpcRules.interact(self, role, target, str(payload.get("choice", "")))
		"question":
			if role != "medium" or state.phase != "seance":
				return "Only the Medium can question Edmund during a séance."
			if humans.has("ghost"):
				return "The ghost is a human player. Ask them using voice or the private transcript."
			if state.question_count >= 3:
				return "The connection is exhausted for this sitting."
			state.question_count += 1
			var words = {
				"death":
				"Bitter flowers. Silas said it would help me sleep. Find the glass, Vivienne.",
				"heir":
				"Iris. My first child. Her name is in the nursery register. I should have told her.",
				"ritual": "Do not bind me. Moon, thorn, key. Prepare the circle, then let me go."
			}
			private_event(role, "Edmund, beyond the veil: “" + words.get(id, words.death) + "”")
		_:
			return "That action is not available."
	RoundSummary.record(state, role, action, id)
	return ""


func bot_conversation(role: String, target: String, topic: String) -> String:
	return NpcRules.interact(self, role, target, "topic:" + topic)


func preparations() -> int:
	var count = 0
	for holder in state.tasks.values():
		if holder != "":
			count += 1
	return count


func public_clue(id: String) -> bool:
	return state.evidence.has(id) and state.evidence[id].public


func can_hear(speaker: String, listener: String) -> bool:
	if not CaseData.ROLES.has(speaker) or not CaseData.ROLES.has(listener) or speaker == listener:
		return false
	if state.get("phase", "") == "ended":
		return true
	if state.get("silenced", "") == speaker:
		return listener == "ghost"
	if speaker == "ghost":
		return (
			(listener == "medium" and state.get("phase", "") == "seance")
			or state.get("possession", "") == listener
		)
	return true


func advance() -> void:
	if state.phase in ["investigation", "seance"]:
		RoundSummary.capture(self)
	match state.phase:
		"investigation":
			state.phase = "seance"
			state.remaining = 150.0
			state.question_count = 0
			for role in CaseData.ROLES:
				state.positions[role] = CaseData.spawn_at(role)
			log_event(
				(
					"The circle convenes. Sitting "
					+ str(state.round)
					+ ". Only the Medium hears the dead."
				)
			)
			bot_sitting()
		"seance":
			if state.round >= 3:
				state.phase = "judgment"
				state.remaining = 180.0
				for role in CaseData.ROLES:
					state.positions[role] = CaseData.spawn_at(role)
				log_event(
					"Dawn approaches. Name the guilty. Choose an heir. Decide the fate of the dead."
				)
			else:
				state.round += 1
				state.phase = "investigation"
				state.remaining = 240.0
				log_event("The circle breaks. Investigation " + str(state.round) + " begins.")
		"judgment":
			resolve()


func bot_sitting() -> void:
	if not humans.has("ghost"):
		var words = ["BETRAYAL", "BLOOD", "RELEASE"]
		state.manifest += 1
		RoundSummary.note(state, "ghost", "signs")
		state.manifest_word = words[state.round - 1]
		log_event("Three knocks. The board spells: " + state.manifest_word + ".")
		private_event(
			"medium",
			(
				"Edmund: “"
				+ [
					"Find the tonic. Something bitter. Someone I trusted.",
					"Iris is my daughter. The register. Please tell her.",
					"A prepared circle. An open door. Do not bind me here."
				][state.round - 1]
				+ "”"
			)
		)
	if not humans.has("medium"):
		log_event("Vivienne: “He remembers bitter flowers. And he is frightened of the Binding.”")
	if not humans.has("doctor"):
		log_event("Blackwell: “Lenore carried the glass. We should not ignore that.”")
	if not humans.has("keeper"):
		log_event("Iris: “The doctor said midnight. The watch says eleven seventeen.”")
	# Bots acquire and reveal assigned untouched clues when the circle convenes.
	# Their authored choices follow their motives, not simulated investigation.
	var assignments = {
		"keeper": "birth", "heir": "will", "widow": "letter", "doctor": "ledger", "medium": "vial"
	}
	for role in assignments:
		if humans.has(role):
			continue
		var id = assignments[role]
		var clue = state.evidence[id]
		if clue.holder == "" and not clue.destroyed:
			if not state.interactive_guests:
				clue.holder = role
		if clue.holder == role and not clue.public and not clue.destroyed and role != "doctor":
			clue.public = true
			RoundSummary.note(state, role, "revealed")
			log_event(CaseData.person(role).name + " revealed “" + CaseData.CLUES[id].name + "”.")
		if role == "doctor" and clue.holder == role and not clue.public and state.round == 3:
			clue.destroyed = true
			RoundSummary.note(state, role, "destroyed")
	if state.round >= 2 and not state.interactive_guests:
		for id in ["radio", "safe"]:
			if state.tasks[id] == "" and not humans.has("medium"):
				state.tasks[id] = "medium"
				state.task_points.medium += 1
				RoundSummary.note(state, "medium", "prepared")
				log_event("Vivienne prepared the " + CaseData.TASKS[id].name + ".")


func all_humans_voted() -> bool:
	for role in humans:
		if not state.votes.has(role):
			return false
	return true


func resolve() -> void:
	if state.phase == "ended":
		return
	var proven = (
		public_clue("vial")
		and (public_clue("ledger") or public_clue("flowers") or public_clue("clock"))
	)
	for role in CaseData.ROLES:
		if state.votes.has(role):
			continue
		var persuaded = (
			NpcRules.knows(self, role, "vial")
			and (
				NpcRules.knows(self, role, "ledger")
				or NpcRules.knows(self, role, "clock")
				or NpcRules.knows(self, role, "flowers")
			)
		)
		var culprit = "doctor" if proven or persuaded else "none"
		var heir = "keeper" if public_clue("birth") and public_clue("will") else "heir"
		var ending = "release" if preparations() >= 2 else "banish"
		if not humans.has(role):
			if role == "doctor":
				culprit = "widow"
				ending = "banish"
				heir = state.npc.pledges.get(role, heir)
			if role == "heir":
				heir = "heir"
				ending = "bind"
		state.votes[role] = {"culprit": culprit, "heir": heir, "ending": ending}
	var final = {}
	for category in ["culprit", "heir", "ending"]:
		var totals = {}
		for ballot in state.votes.values():
			var choice = ballot[category]
			totals[choice] = totals.get(choice, 0) + 1
		var best = 0
		var ties = []
		for choice in totals:
			if totals[choice] > best:
				best = totals[choice]
				ties = [choice]
			elif totals[choice] == best:
				ties.append(choice)
		# A split verdict convicts no one; a split inheritance preserves the old
		# will; a split rite closes the circle. Ghost ballots count like any guest.
		final[category] = (
			ties[0]
			if ties.size() == 1
			else {"culprit": "none", "heir": "heir", "ending": "banish"}[category]
		)
	state.ending = final
	state.phase = "ended"
	state.remaining = 0
	state.possession = ""
	state.silenced = ""
	state.scores = []
	for role in CaseData.ROLES:
		var goals = completed_goals(role)
		var points = 0
		for i in range(3):
			if goals[i]:
				points += [2, 3, 5][i]
		var bonus = mini(3, state.task_points[role])
		state.scores.append(
			{"role": role, "points": points + bonus, "goals": goals, "bonus": bonus}
		)
	state.scores.sort_custom(func(a, b): return a.points > b.points)
	RoundSummary.final(self)
	log_event("The will is sealed. Ashwood remembers what the circle chose to believe.")


func completed_goals(role: String) -> Array:
	var end = state.ending
	if end.is_empty():
		end = {"culprit": "", "heir": "", "ending": ""}
	match role:
		"medium":
			return [public_clue("vial"), state.task_points.medium >= 2, end.ending == "release"]
		"heir":
			return [public_clue("will"), state.items.ring == "heir", end.ending == "bind"]
		"widow":
			return [
				public_clue("letter"),
				state.items.locket == "keeper",
				end.culprit != "widow" and end.culprit != ""
			]
		"doctor":
			return [public_clue("vial"), not public_clue("ledger"), end.culprit == "widow"]
		"keeper":
			return [public_clue("birth"), state.items.key == "keeper", end.heir == "keeper"]
		"ghost":
			return [
				public_clue("vial") and public_clue("ledger"),
				end.heir == "keeper",
				end.ending == "release"
			]
	return [false, false, false]


func view_for(role: String) -> Dictionary:
	var view = state.duplicate(true)
	view["npc"] = NpcRules.view_for(self, role)
	view.erase("npc_routes")
	view.erase("private_log")
	view.erase("discussed")
	view.erase("activity")
	view.erase("activity_baseline")
	view["phase_info"] = RoundSummary.phase_info(state)
	view["messages"] = state.private_log.get(role, []).duplicate()
	view["role"] = role
	view["humans"] = humans.duplicate()
	view["goals"] = completed_goals(role)
	view["prepared"] = preparations()
	view["possessed"] = state.possession == role
	if role != "ghost":
		view["possession"] = ""
		view["energy"] = 0.0
		if state.possession != role:
			view["possession_time"] = 0.0
	# Never disclose other guests' evidence ownership, secret messages, or votes.
	for id in view.evidence:
		var clue = view.evidence[id]
		if not clue.public and clue.holder != role:
			clue.holder = "unknown" if clue.holder != "" else ""
			clue.destroyed = false
	if state.phase != "ended":
		view.votes = {"count": state.votes.size(), "submitted": state.votes.has(role)}
	return view
