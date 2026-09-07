extends SceneTree
## Real phase boundaries, irreversible-action safeguards and non-omniscient NPCs.

var checks = 0
var failures = 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)


func collect(game, role: String, id: String) -> String:
	game.state.positions[role] = CaseData.object_data(id).pos
	return game.act(role, "collect", {"id": id})


func task(game, role: String, id: String) -> String:
	game.state.positions[role] = CaseData.TASKS[id].pos
	return game.act(role, "task", {"id": id, "answer": CaseData.TASKS[id].solution})


func next_investigation(game) -> void:
	game.state.remaining = 0.01
	game.tick(0.02)
	expect(game.state.phase == "seance", "clock opens sitting")
	game.state.remaining = 0.01
	game.tick(0.02)
	expect(game.state.phase == "investigation", "clock opens next investigation")


func chapters() -> void:
	var game = GameRules.new()
	game.reset(CaseData.ROLES)
	var forecast = game.view_for("medium").chapter
	expect(forecast.schedule.size() == 3, "all three chapters visible from arrival")
	expect(
		forecast.dependencies.birth.contains("year"), "future register dependency disclosed upfront"
	)
	for id in CaseProgression.UNLOCKS:
		var before = game.state.duplicate(true)
		var result = (
			task(game, "medium", id) if CaseData.TASKS.has(id) else collect(game, "medium", id)
		)
		expect(result.contains("Sealed until investigation"), "early attempt refused: " + id)
		expect(
			game.state.evidence == before.evidence and game.state.tasks == before.tasks,
			"early attempt changes no ownership or completion: " + id
		)
	for id in ["vial", "letter", "flowers", "clock", "rite", "ring", "key", "locket"]:
		expect(collect(game, "medium", id) == "", "initial chapter opportunity: " + id)
	expect(task(game, "medium", "candles") == "", "initial candles can be prepared")
	# Earlier irreversible acts cannot remove an as-yet-unknown audit opportunity.
	game.act("medium", "destroy", {"id": "flowers"})
	game.act("medium", "give", {"id": "key", "target": "keeper"})
	next_investigation(game)
	expect(game.state.round == 2, "second chapter reached naturally")
	for id in ["will", "birth"]:
		expect(collect(game, "medium", id) == "", "lineage chapter unseals " + id)
	expect(task(game, "medium", "radio") == "", "radio unseals for living guest")
	expect(task(game, "medium", "safe") != "", "final apparatus stays sealed in chapter two")
	expect(collect(game, "medium", "audit") != "", "final audit stays sealed in chapter two")
	next_investigation(game)
	expect(game.state.round == 3, "third chapter reached naturally")
	expect(game.view_for("medium").chapter.locked.is_empty(), "all final opportunities open")
	expect(collect(game, "doctor", "ledger") == "", "doctor can now pursue ledger")
	expect(game.act("doctor", "destroy", {"id": "ledger"}) == "", "doctor can conceal original")
	expect(not game.completed_goals("ghost")[0], "no unearned ghost objective")
	expect(
		collect(game, "medium", "audit") == "",
		"independent audit survives original destruction and lost key"
	)
	expect(
		game.state.evidence.audit.public and game.state.evidence.audit.holder == "",
		"audit is fixed public reference"
	)
	game.act("medium", "reveal", {"id": "vial"})
	expect(game.completed_goals("ghost")[0], "audit plus tonic satisfy advertised ghost objective")
	expect(
		not game.completed_goals("doctor")[1],
		"public audit defeats concealment goal advertised at arrival"
	)
	for role in CaseData.ROLES:
		expect(game.view_for(role).evidence.audit.public, "audit reaches " + role)
	for action in ["destroy", "give", "reveal"]:
		expect(
			game.act("medium", action, {"id": "audit", "target": "doctor"}) != "",
			"fixed reference rejects " + action
		)
	var revealed = game.state.activity.medium.revealed
	expect(collect(game, "medium", "audit") != "", "audit cannot be repeatedly published")
	expect(game.state.activity.medium.revealed == revealed, "audit awards cannot be farmed")
	expect(task(game, "medium", "safe") == "", "final reliquary now prepares")
	game.advance()
	game.advance()
	expect(game.state.phase == "judgment", "final sitting leads to judgment, not a fourth loop")
	game.advance()
	expect(game.state.scores.size() == 6, "all six outcomes scored")


func npc_stages() -> void:
	var game = GameRules.new()
	game.reset(["ghost"])
	game.state.interactive_guests = true
	for round_id in range(1, 4):
		var intents = {}
		for npc in NpcDirector.PLANS:
			intents[npc] = NpcDirector.stage_intent(game, npc)
		for tick in range(2800):
			NpcDirector.tick(game, 0.05)
		# Measure movement after the original one-shot plans would have stopped.
		var traveled = {}
		var positions = game.state.positions.duplicate()
		for npc in NpcDirector.PLANS:
			traveled[npc] = 0.0
		for tick in range(600):
			NpcDirector.tick(game, 0.05)
			for npc in NpcDirector.PLANS:
				traveled[npc] += positions[npc].distance_to(game.state.positions[npc])
				positions[npc] = game.state.positions[npc]
		for npc in NpcDirector.PLANS:
			expect(traveled[npc] > 1.0, "continued late movement chapter %d: %s" % [round_id, npc])
			expect(CaseData.is_walkable(game.state.positions[npc]), "NPC remains in estate: " + npc)
		if round_id == 1:
			expect(
				game.state.evidence.birth.holder == "" and game.state.evidence.ledger.holder == "",
				"NPCs respect sealed evidence"
			)
			expect(game.state.items.locket == "widow", "Lenore initially keeps locket")
		if round_id == 2:
			expect(
				game.state.evidence.birth.holder == "keeper", "Iris pursues newly unsealed lineage"
			)
			expect(game.state.evidence.will.holder == "heir", "Julian pursues newly unsealed will")
			expect(
				game.state.items.locket == "keeper",
				"Lenore acts on new inheritance-stage gift objective"
			)
			expect(game.state.tasks.radio == "medium", "medium pursues new radio preparation")
		if round_id == 3:
			expect(
				game.state.evidence.ledger.holder == "doctor",
				"doctor pursues newly unsealed ledger"
			)
			expect(
				not game.state.evidence.audit.public,
				"NPC patrol does not automatically solve final audit for player"
			)
		game.advance()
		var seated = game.state.positions.duplicate()
		NpcDirector.tick(game, 1)
		expect(game.state.positions == seated, "NPC investigation movement stops at sitting")
		if round_id < 3:
			game.advance()
			for npc in NpcDirector.PLANS:
				expect(
					NpcDirector.stage_intent(game, npc) != intents[npc],
					"new priorities each chapter: " + npc
				)


func privacy_and_discussion() -> void:
	var game = GameRules.new()
	game.reset(["medium"])
	game.state.round = 2
	collect(game, "heir", "will")
	expect(
		not NpcRules.available(game, "medium", "heir", "request:will"),
		"menu does not disclose secret will holder"
	)
	NpcRules.interact(game, "medium", "heir", "topic:possessions")
	expect(
		NpcRules.available(game, "medium", "heir", "request:will"),
		"explicit statement permits specific request"
	)
	expect(
		not NpcRules.available(game, "widow", "heir", "request:will"),
		"one listener's disclosure is not broadcast"
	)
	game.act("heir", "give", {"id": "will", "target": "keeper"})
	expect(
		NpcRules.available(game, "medium", "heir", "request:will"),
		"hidden transfer does not silently change a known inventory menu"
	)
	NpcRules.interact(game, "medium", "heir", "request:will")
	expect(
		not NpcRules.available(game, "medium", "heir", "request:will"),
		"spoken correction updates ownership belief"
	)
	collect(game, "keeper", "birth")
	NpcRules.interact(game, "medium", "keeper", "hint:safe")
	var reply: String = game.state.npc.conversations["medium:keeper"].back().text
	expect(
		reply.contains("I have the register") and not reply.contains("Iris"),
		"Iris doesn't refer to herself in third person"
	)
	collect(game, "medium", "clock")
	NpcRules.interact(game, "medium", "heir", "show:clock")
	reply = game.state.npc.conversations["medium:heir"].back().text
	expect(not reply.contains("read it"), "physical watch gets appropriate non-reading response")
	expect(NpcRules.knows(game, "heir", "clock"), "discussion actually changes NPC knowledge")
	game.state.round = 3
	collect(game, "doctor", "ledger")
	NpcRules.interact(game, "medium", "doctor", "topic:possessions")
	expect(
		not NpcRules.available(game, "medium", "doctor", "request:ledger"),
		"doctor protects his own concealed motive"
	)


func ghost_audit_route() -> void:
	var game = GameRules.new()
	game.reset(["ghost"])
	game.state.interactive_guests = true
	game.state.round = 2
	expect(
		NpcRules.interact(game, "ghost", "medium", "investigate:audit") != "",
		"ghost cannot request audit outside a listening channel"
	)
	game.state.phase = "seance"
	expect(
		NpcRules.interact(game, "ghost", "medium", "investigate:audit") == "",
		"ghost requests living help at second sitting"
	)
	expect(not game.public_clue("audit"), "request is a plan, not instant public knowledge")
	expect(
		not NpcRules.available(game, "medium", "doctor", "investigate:audit"),
		"doctor will not volunteer to expose his own audit"
	)
	game.advance()
	for tick in range(1600):
		NpcDirector.tick(game, 0.05)
		if game.public_clue("audit"):
			break
	expect(
		game.public_clue("audit"),
		"medium physically publishes audit when final investigation opens"
	)
	expect(
		(
			CaseData.room_at(game.state.positions.medium) == "Conservatory"
			and game.nearby("medium", "audit")
		),
		"audit request completes through physical director"
	)
	expect(game.state.activity.medium.revealed == 1, "audit request records one actual publication")
	game.humans.append("keeper")
	game.state.evidence.audit.public = false
	expect(
		NpcRules.interact(game, "medium", "keeper", "investigate:audit") != "",
		"request cannot drive a human guest"
	)
	game.state.phase = "seance"
	expect(
		not NpcRules.available(game, "ghost", "medium", "investigate:audit"),
		"last sitting cannot offer an errand after the final investigation"
	)


func concealment_policy() -> void:
	var game = GameRules.new()
	game.reset(["medium"])
	game.state.round = 3
	for id in ["ledger", "clock", "flowers"]:
		collect(game, "doctor", id)
	NpcRules.interact(game, "medium", "doctor", "topic:possessions")
	var statement: String = game.state.npc.conversations["medium:doctor"].back().text
	for id in ["ledger", "clock", "flowers"]:
		expect(
			not statement.contains(CaseData.CLUES[id].name),
			"doctor does not volunteer concealed " + id
		)
		expect(
			not NpcRules.available(game, "medium", "doctor", "request:" + id),
			"concealment policy also gates request " + id
		)
	collect(game, "doctor", "vial")
	NpcRules.interact(game, "medium", "doctor", "topic:possessions")
	expect(
		NpcRules.available(game, "medium", "doctor", "reveal:vial"),
		"doctor can still pursue his cooperative public medicine goal"
	)
	game.humans = ["ghost"]
	var progress = NpcDirector.fresh_progress(3)
	progress.index = 3  # The medium's reliquary step, without knowledge of the year.
	progress.path = [Vector3(0, 0, -10)]
	game.state.npc_routes.medium = progress
	NpcDirector.tick(game, 0.05)
	expect(
		progress.index == 4 and progress.path.is_empty(),
		"skipped unknown reliquary discards old route"
	)


func run() -> void:
	chapters()
	npc_stages()
	privacy_and_discussion()
	ghost_audit_route()
	concealment_policy()
	print("PROGRESSION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
