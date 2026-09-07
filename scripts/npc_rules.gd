class_name NpcRules
extends RefCounted
## Authoritative social actions, shared by menus and optional model interpretation.
## A model may ask for an offered action; it never assigns inventory or evidence state.


static func initial() -> Dictionary:
	return {
		"heard": {},
		"shown": {},
		"offers": {},
		"conversations": {},
		"pledges": {},
		"audit_requests": [],
		"disclosed_ownership": {}
	}


static func disclose_ownership(game, listener: String, npc: String, id: String) -> void:
	var key = listener + ":" + npc
	var disclosed: Array = game.state.npc.disclosed_ownership.get(key, [])
	if not disclosed.has(id):
		disclosed.append(id)
	game.state.npc.disclosed_ownership[key] = disclosed


static func ownership_known(game, listener: String, npc: String, id: String) -> bool:
	# Inheritance claims and revealed evidence have a public register. Private
	# holdings require an actual statement to this listener, not a menu oracle.
	if game.state.items.has(id) or game.public_clue(id):
		return owns(game, npc, id)
	return game.state.npc.disclosed_ownership.get(listener + ":" + npc, []).has(id)


static func willing_to_offer(npc: String, id: String) -> bool:
	return not NpcData.PROFILES[npc].get("conceals", []).has(id)


static func inventory_statement(game, listener: String, npc: String) -> void:
	var names = []
	for id in CaseData.CLUES.keys() + CaseData.ITEMS.keys():
		if not owns(game, npc, id) or not willing_to_offer(npc, id):
			continue
		disclose_ownership(game, listener, npc, id)
		names.append(CaseData.object_data(id).name)
	var text = "I have nothing I am willing to offer just now."
	if not names.is_empty():
		text = (
			"I have "
			+ ", ".join(names)
			+ ". You may ask about them, but I may choose to keep them."
		)
	record(game, listener, npc, text)


static func give_hint(game, listener: String, npc: String, id: String) -> void:
	var text: String = NpcData.HINTS[id]
	if id == "safe":
		if owns(game, npc, "birth"):
			disclose_ownership(game, listener, npc, "birth")
			text += " I have the register. Ask me to reveal it, and you can examine the entry."
		elif game.public_clue("birth"):
			text += " The register has been shared with the circle; it is in your journal."
		elif owns(game, listener, "birth"):
			text += " You already have the register in your keeping."
		else:
			text += " If it has been moved, ask the other guests what they have found."
	if CaseProgression.locked(game.state, id):
		text += " " + CaseProgression.lock_message(id) + "."
	record(game, listener, npc, text)


static func permission(game, listener: String, npc: String) -> String:
	if not CaseData.ROLES.has(npc) or not CaseData.ROLES.has(listener) or npc == listener:
		return "Choose another guest."
	if game.humans.has(npc):
		return "This guest is a human player. They decide what to say and give."
	if game.state.phase == "ended":
		return "The séance is over."
	if not game.can_hear(listener, npc) or not game.can_hear(npc, listener):
		return "You cannot hear one another through the veil just now."
	return ""


static func owns(game, role: String, id: String) -> bool:
	if game.state.items.has(id):
		return game.state.items[id] == role
	var clue: Dictionary = game.state.evidence.get(id, {})
	return clue.get("holder", "") == role and not clue.get("destroyed", true)


static func knows(game, role: String, id: String) -> bool:
	return (
		game.public_clue(id) or owns(game, role, id) or game.state.npc.shown.get(role, []).has(id)
	)


static func record(game, listener: String, npc: String, text: String, speaker: String = "") -> void:
	var key = listener + ":" + npc
	var history: Array = game.state.npc.conversations.get(key, [])
	history.append({"speaker": npc if speaker == "" else speaker, "text": text.left(700)})
	if history.size() > 24:
		history.pop_front()
	game.state.npc.conversations[key] = history
	game.private_event(
		listener,
		CaseData.person(npc if speaker == "" else speaker).name + ": “" + text.left(700) + "”"
	)


static func options(game, listener: String, npc: String) -> Array:
	if permission(game, listener, npc) != "":
		return []
	var result = []
	if (
		game.state.interactive_guests
		and game.state.round >= 2
		and game.state.phase in ["investigation", "seance"]
		and not (game.state.round == 3 and game.state.phase == "seance")
		and npc not in ["doctor", "ghost"]
		and not game.public_clue("audit")
	):
		result.append(
			{
				"id": "investigate:audit",
				"label": "Ask them to examine and publish the final audit when available"
			}
		)
	result.append(
		{"id": "topic:possessions", "label": "Ask what they have found or are willing to offer"}
	)
	result.append(
		{"id": "topic:chapter", "label": "Ask what they want to do in this investigation"}
	)
	for topic in ["history", "death", "inheritance", "ritual"]:
		result.append(
			{
				"id": "topic:" + topic,
				"label": "Ask about " + ("their past" if topic == "history" else "the " + topic)
			}
		)
	for task in CaseData.TASKS:
		if game.state.tasks[task] == "":
			result.append(
				{"id": "hint:" + task, "label": "Help with: " + CaseData.TASKS[task].name}
			)
	for id in CaseData.CLUES:
		if knows(game, listener, id):
			result.append({"id": "show:" + id, "label": "Discuss: " + CaseData.CLUES[id].name})
		if ownership_known(game, listener, npc, id) and willing_to_offer(npc, id):
			if not game.public_clue(id):
				result.append(
					{
						"id": "reveal:" + id,
						"label": "Ask them to reveal: " + CaseData.CLUES[id].name
					}
				)
			result.append({"id": "request:" + id, "label": "Ask for: " + CaseData.CLUES[id].name})
	for id in CaseData.ITEMS:
		if owns(game, npc, id):
			result.append({"id": "request:" + id, "label": "Ask for: " + CaseData.ITEMS[id].name})
		if owns(game, listener, id) and npc != "ghost":
			result.append({"id": "gift:" + id, "label": "Give: " + CaseData.ITEMS[id].name})
	if npc == "widow" and owns(game, npc, "locket"):
		result.append(
			{
				"id": "deliver:locket",
				"label":
				"Ask Lenore to give the locket to " + ("you" if listener == "keeper" else "Iris")
			}
		)
	var key = listener + ":" + npc
	if game.state.npc.offers.has(key):
		var offer: Dictionary = game.state.npc.offers[key]
		result.append(
			{
				"id": "accept:trade",
				"label":
				(
					"Accept trade: your "
					+ CaseData.object_data(offer.want).name
					+ " for their "
					+ CaseData.object_data(offer.give).name
				)
			}
		)
	if npc == "doctor" and listener not in ["medium", "ghost"] and owns(game, listener, "ledger"):
		result.append(
			{
				"id": "deal:ledger",
				"label": "Give Blackwell the ledger for his pledge to support you as heir"
			}
		)
	result.sort_custom(func(a, b): return _option_priority(a.id) < _option_priority(b.id))
	return result


static func _option_priority(choice: String) -> int:
	if choice == "topic:possessions":
		return 1
	match choice.get_slice(":", 0):
		"accept":
			return 0
		"reveal", "deliver", "request", "deal":
			return 2
		"show", "gift":
			return 3
	return 4


static func available(game, listener: String, npc: String, choice: String) -> bool:
	for option in options(game, listener, npc):
		if option.id == choice:
			return true
	return false


static func interact(game, listener: String, npc: String, choice: String) -> String:
	var error = permission(game, listener, npc)
	if error != "":
		return error
	if not available(game, listener, npc, choice):
		return "That conversation option is no longer available. Nothing was exchanged."
	var kind = choice.get_slice(":", 0)
	var id = choice.get_slice(":", 1)
	var profile: Dictionary = NpcData.PROFILES[npc]
	match kind:
		"investigate":
			if not game.state.npc.audit_requests.has(npc):
				game.state.npc.audit_requests.append(npc)
				game.state.npc_routes.erase(npc)
			record(
				game,
				listener,
				npc,
				"I will examine the bank's copy during the final investigation and put it in the public record. Give me time to reach the Conservatory once the circle breaks."
			)
		"topic":
			if id == "chapter":
				record(
					game,
					listener,
					npc,
					(
						NpcDirector.stage_intent(game, npc)
						if npc != "ghost"
						else CaseProgression.view_for(game.state).focus
					)
				)
				return ""
			if id == "possessions":
				inventory_statement(game, listener, npc)
				return ""
			record(game, listener, npc, profile[id])
			game.state.discussed[listener + ":" + npc + ":" + id] = true
		"hint":
			give_hint(game, listener, npc, id)
		"show":
			var shown: Array = game.state.npc.shown.get(npc, [])
			if not shown.has(id):
				shown.append(id)
			game.state.npc.shown[npc] = shown
			record(game, listener, npc, "I showed you “" + CaseData.CLUES[id].name + "”.", listener)
			var replies: Dictionary = NpcData.RESPONSES.get(id, {})
			record(
				game,
				listener,
				npc,
				(
					replies
					. get(
						npc,
						"That is worth considering. I will take it into account when the circle decides."
					)
				)
			)
			# Evidence changes decisions. Flattery and repeat clicks do not farm trust.
			if (npc == "widow" and id == "vial") or (npc == "keeper" and id == "will"):
				var reveal_id: String = profile.clue
				if owns(game, npc, reveal_id) and not game.public_clue(reveal_id):
					game.act(npc, "reveal", {"id": reveal_id})
		"reveal":
			error = game.act(npc, "reveal", {"id": id})
			if error != "":
				return error
			record(
				game,
				listener,
				npc,
				(
					"Let everyone examine it. I have revealed “"
					+ CaseData.CLUES[id].name
					+ "” to the circle."
				)
			)
		"request":
			return request_object(game, listener, npc, id)
		"accept":
			return accept_offer(game, listener, npc)
		"gift":
			error = game.act(listener, "give", {"id": id, "target": npc})
			if error != "":
				return error
			record(
				game, listener, npc, "Thank you. I am keeping the " + CaseData.ITEMS[id].name + "."
			)
		"deliver":
			error = game.act(npc, "give", {"id": "locket", "target": "keeper"})
			if error != "":
				return error
			record(
				game,
				listener,
				npc,
				(
					"You should have it. I have given you the locket; there is nothing left for me inside it."
					if listener == "keeper"
					else "Iris should have it. I have given her the locket; there is nothing left for me inside it."
				)
			)
		"deal":
			if listener == "ghost" or listener == "medium":
				return "Only a living beneficiary can make that bargain."
			error = game.act(listener, "give", {"id": "ledger", "target": npc})
			if error != "":
				return error
			game.state.npc.pledges[npc] = listener
			record(
				game,
				listener,
				npc,
				"A bargain. You have my vote for the manor. My vote on the death remains my own."
			)
	return ""


static func request_object(game, listener: String, npc: String, id: String) -> String:
	if not owns(game, npc, id):
		var key = listener + ":" + npc
		game.state.npc.disclosed_ownership.get(key, []).erase(id)
		record(game, listener, npc, "I no longer have the " + CaseData.object_data(id).name + ".")
		return ""
	if listener == "ghost":
		record(
			game, listener, npc, "You cannot carry it. Tell me which living guest should have it."
		)
		return ""
	var desired: String = NpcData.PROFILES[npc].item
	if id == desired:
		record(
			game,
			listener,
			npc,
			"No. The " + CaseData.object_data(id).name + " matters to me. I intend to keep it."
		)
		return ""
	if desired != "" and owns(game, listener, desired):
		game.state.npc.offers[listener + ":" + npc] = {"give": id, "want": desired}
		record(
			game,
			listener,
			npc,
			(
				"I can offer “"
				+ CaseData.object_data(id).name
				+ "” for your “"
				+ CaseData.object_data(desired).name
				+ "”. You must accept before either of us parts with anything."
			)
		)
		return ""
	var error: String = game.act(npc, "give", {"id": id, "target": listener})
	if error == "":
		record(
			game,
			listener,
			npc,
			(
				"Take the "
				+ CaseData.object_data(id).name
				+ ". What you do with it now is your responsibility."
			)
		)
	return error


static func accept_offer(game, listener: String, npc: String) -> String:
	var key = listener + ":" + npc
	var offer: Dictionary = game.state.npc.offers.get(key, {})
	if offer.is_empty() or not owns(game, npc, offer.give) or not owns(game, listener, offer.want):
		game.state.npc.offers.erase(key)
		return "The offered objects have changed hands. Nothing was exchanged."
	if listener == "ghost" or npc == "ghost":
		return "The dead cannot exchange possessions."
	# Both preconditions checked before either mutation; both transfers use normal rules.
	game.act(listener, "give", {"id": offer.want, "target": npc})
	game.act(npc, "give", {"id": offer.give, "target": listener})
	game.state.npc.offers.erase(key)
	record(game, listener, npc, "Agreed. The exchange is complete.")
	return ""


static func view_for(game, listener: String) -> Dictionary:
	var view = {}
	for npc in CaseData.ROLES:
		if npc == listener:
			continue
		var key = listener + ":" + npc
		view[npc] = {
			"blocked": permission(game, listener, npc),
			"options": options(game, listener, npc),
			"history": game.state.npc.conversations.get(key, []).duplicate(true)
		}
	return view


static func context(game, listener: String, npc: String) -> Dictionary:
	if permission(game, listener, npc) != "":
		return {}
	var profile: Dictionary = NpcData.PROFILES[npc]
	var facts = []
	# Only what BOTH parties already know is exposed to the text model. New
	# disclosures and exchanges must select a legal option, then run through rules.
	for id in CaseData.CLUES:
		if knows(game, listener, id) and knows(game, npc, id):
			facts.append({"id": id, "text": CaseData.CLUES[id].text})
	var choices = []
	for option in options(game, listener, npc):
		# A model cannot spend the player's property or consent to an offer.
		if (
			option.id.get_slice(":", 0)
			in ["topic", "hint", "request", "reveal", "deliver", "investigate"]
		):
			choices.append(option)
	return {
		"name": CaseData.person(npc).name,
		"listener": CaseData.person(listener).name,
		"history": profile.history,
		"manner": profile.manner,
		"motivation": profile.desire,
		"ready_testimony":
		{
			"topic:chapter":
			(
				NpcDirector.stage_intent(game, npc)
				if npc != "ghost"
				else CaseProgression.view_for(game.state).focus
			),
			"topic:possessions":
			"I may name things I am willing to discuss or offer; this does not reveal their contents or promise a transfer.",
			"topic:history": profile.history,
			"topic:death": profile.death,
			"topic:inheritance": profile.inheritance,
			"topic:ritual": profile.ritual,
			"hint:safe": NpcData.HINTS.safe,
			"hint:radio": NpcData.HINTS.radio,
			"hint:candles": NpcData.HINTS.candles
		},
		"phase": game.state.phase,
		"round": game.state.round,
		"chapter": CaseProgression.view_for(game.state),
		"conversation": game.state.npc.conversations.get(listener + ":" + npc, []).slice(-12),
		"facts": facts,
		"options": choices
	}


static func explicit_puzzle(question: String) -> String:
	# Ground named-apparatus questions before model selection. This is an authored
	# help route, not a guessed code or a model deciding what evidence exists.
	var text = question.to_lower()
	var asking = false
	for word in ["?", "help", "where", "how", "stuck", "cannot", "can't"]:
		asking = asking or text.contains(word)
	if not asking:
		return ""
	if text.contains("reliquary") or text.contains("safe") or text.contains("year that changed"):
		return "hint:safe"
	if text.contains("radio") or text.contains("frequency"):
		return "hint:radio"
	if text.contains("candle") or text.contains("symbols"):
		return "hint:candles"
	return ""
