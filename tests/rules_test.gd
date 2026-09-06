extends SceneTree

var checks = 0
var failures: Array = []


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)


func collect(game: GameRules, role: String, id: String) -> void:
	game.state.positions[role] = CaseData.object_data(id).pos
	expect(game.act(role, "collect", {"id": id}) == "", "collect " + id)


func prepare(game: GameRules, role: String, id: String) -> void:
	game.state.positions[role] = CaseData.TASKS[id].pos
	expect(
		game.act(role, "task", {"id": id, "answer": CaseData.TASKS[id].solution}) == "",
		"prepare " + id
	)


func run() -> void:
	test_evidence_ownership()
	test_voice_matrix()
	test_possession_and_silence()
	test_preparations_and_phase()
	test_final_outcomes()
	test_redaction()
	test_solo_cases()
	test_sealed_ballots()
	print("RULES: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_evidence_ownership() -> void:
	var game = GameRules.new()
	game.reset()
	expect(game.act("medium", "collect", {"id": "will"}) != "", "cannot collect from another room")
	collect(game, "medium", "will")
	expect(
		game.act("doctor", "reveal", {"id": "will"}) != "", "cannot reveal another guest's evidence"
	)
	expect(
		game.act("medium", "give", {"id": "will", "target": "keeper"}) == "",
		"evidence can be gifted"
	)
	expect(game.state.evidence.will.holder == "keeper", "transfer has one owner")
	expect(game.act("medium", "destroy", {"id": "will"}) != "", "old owner loses rights")
	expect(game.act("keeper", "reveal", {"id": "will"}) == "", "new owner can reveal")
	expect(
		game.act("keeper", "destroy", {"id": "will"}) != "", "revealed testimony cannot be erased"
	)
	collect(game, "doctor", "ledger")
	expect(
		game.act("doctor", "destroy", {"id": "ledger"}) == "", "private evidence can be destroyed"
	)
	expect(
		game.act("doctor", "reveal", {"id": "ledger"}) != "",
		"destroyed evidence cannot be revealed"
	)
	collect(game, "heir", "ring")
	expect(
		game.act("heir", "give", {"id": "ring", "target": "ghost"}) != "", "dead cannot own gifts"
	)
	expect(
		game.act("heir", "give", {"id": "ring", "target": "keeper"}) == "",
		"inheritance can be transferred"
	)
	game.state.positions.ghost = CaseData.ITEMS.locket.pos
	expect(game.act("ghost", "collect", {"id": "locket"}) != "", "ghost cannot collect")
	expect(game.act("intruder", "collect", {"id": "ring"}) != "", "unknown role rejected")


func test_voice_matrix() -> void:
	var game = GameRules.new()
	game.reset(CaseData.ROLES)
	for speaker in CaseData.ROLES:
		for listener in CaseData.ROLES:
			var allowed = speaker != listener and speaker != "ghost"
			expect(
				game.can_hear(speaker, listener) == allowed,
				"investigation voice " + speaker + "->" + listener
			)
	game.advance()
	for speaker in CaseData.ROLES:
		for listener in CaseData.ROLES:
			var allowed = speaker != listener and (speaker != "ghost" or listener == "medium")
			expect(
				game.can_hear(speaker, listener) == allowed,
				"seance voice " + speaker + "->" + listener
			)
	expect(not game.can_hear("intruder", "medium"), "unregistered voice rejected")
	game.act("ghost", "chat", {"text": "A private memory."})
	expect(
		str(game.state.private_log.medium).contains("A private memory"),
		"medium receives ghost text"
	)
	expect(
		not str(game.state.private_log.heir).contains("A private memory"),
		"heir never receives ghost text"
	)


func test_possession_and_silence() -> void:
	var game = GameRules.new()
	game.reset(CaseData.ROLES)
	expect(
		game.act("ghost", "possess", {"target": "widow"}) != "",
		"possession unavailable in round one"
	)
	game.state.round = 2
	expect(game.act("ghost", "possess", {"target": "widow"}) == "", "ghost can invite a vessel")
	expect(game.can_hear("ghost", "widow"), "vessel receives ghost channel")
	expect(not game.can_hear("ghost", "heir"), "possession does not leak to all guests")
	expect(
		game.state.positions.widow == CaseData.spawn_at("widow"),
		"possession never moves the vessel"
	)
	game.tick(61)
	expect(not game.can_hear("ghost", "widow"), "possession expires")
	game.state.energy = 100
	expect(game.act("ghost", "silence", {"target": "doctor"}) == "", "silence can be applied")
	expect(game.can_hear("doctor", "ghost"), "silenced guest heard by ghost")
	expect(not game.can_hear("doctor", "medium"), "silenced guest blocked from medium")
	game.tick(26)
	expect(game.can_hear("doctor", "medium"), "silence expires")
	game.state.energy = 14
	expect(game.act("ghost", "manifest", {"word": "YES"}) != "", "energy budget enforced")
	expect(
		game.act("heir", "manifest", {"word": "YES"}) != "",
		"living cannot forge supernatural actions"
	)


func test_preparations_and_phase() -> void:
	var game = GameRules.new()
	game.reset(CaseData.ROLES)
	game.state.positions.medium = CaseData.TASKS.radio.pos
	expect(
		game.act("medium", "task", {"id": "radio", "answer": "88.8"}) != "",
		"wrong radio frequency rejected"
	)
	prepare(game, "medium", "radio")
	expect(
		game.act("medium", "task", {"id": "radio", "answer": "88.7"}) != "",
		"cannot score a task twice"
	)
	expect(game.state.task_points.medium == 1, "task point count is exact")
	game.state.phase = "judgment"
	expect(
		(
			game.act("medium", "vote", {"culprit": "doctor", "heir": "keeper", "ending": "release"})
			!= ""
		),
		"unprepared release rejected"
	)
	game.reset(CaseData.ROLES)
	for expected in [
		"seance", "investigation", "seance", "investigation", "seance", "judgment", "ended"
	]:
		if expected == "judgment":
			for role in CaseData.ROLES:
				game.state.positions[role] = CaseData.TASKS.radio.pos
		game.advance()
		expect(game.state.phase == expected, "phase sequence " + expected)
		if expected == "judgment":
			for role in CaseData.ROLES:
				expect(
					game.state.positions[role] == CaseData.spawn_at(role),
					"judgment authoritatively seats " + role
				)
	var result = game.state.ending.duplicate()
	game.advance()
	expect(game.state.ending == result, "ending cannot advance twice")
	expect(game.act("medium", "chat", {"text": "change"}) != "", "ended state rejects mutations")


func test_final_outcomes() -> void:
	for rite in ["release", "bind", "banish"]:
		var game = GameRules.new()
		game.reset(CaseData.ROLES)
		for id in ["vial", "ledger", "birth", "will"]:
			collect(game, "medium", id)
			game.act("medium", "reveal", {"id": id})
		prepare(game, "medium", "radio")
		prepare(game, "medium", "candles")
		game.state.phase = "judgment"
		for role in CaseData.ROLES:
			expect(
				(
					game.act(role, "vote", {"culprit": "doctor", "heir": "keeper", "ending": rite})
					== ""
				),
				"valid ballot " + role
			)
		expect(game.state.phase == "ended", "all ballots resolve " + rite)
		expect(game.state.ending.ending == rite, "correct selected rite")
		expect(game.state.ending.culprit == "doctor", "correct conviction")
		expect(game.state.ending.heir == "keeper", "correct beneficiary")
		expect(game.state.scores.size() == 6, "all six roles scored")
		for score in game.state.scores:
			if score.role == "medium":
				expect(
					score.points == (12 if rite == "release" else 7), "medium goals score exactly"
				)
	var tied = GameRules.new()
	tied.reset(CaseData.ROLES)
	tied.state.phase = "judgment"
	for i in range(6):
		tied.act(
			CaseData.ROLES[i],
			"vote",
			{
				"culprit": "doctor" if i < 3 else "widow",
				"heir": "keeper" if i < 3 else "widow",
				"ending": "bind" if i < 3 else "banish"
			}
		)
	expect(
		tied.state.ending == {"culprit": "none", "heir": "heir", "ending": "banish"},
		"ties use documented defaults"
	)


func test_redaction() -> void:
	var game = GameRules.new()
	game.reset(CaseData.ROLES)
	collect(game, "doctor", "ledger")
	game.private_event("ghost", "A hidden memory")
	game.state.possession = "heir"
	game.state.possession_time = 60.0
	game.state.evidence.ledger.destroyed = true
	game.state.votes.doctor = {"culprit": "widow", "heir": "heir", "ending": "banish"}
	var view = game.view_for("medium")
	expect(not view.has("private_log"), "all private logs stripped")
	expect(not str(view).contains("A hidden memory"), "other private content absent")
	expect(view.possession == "", "medium is not told the vessel")
	expect(view.possession_time == 0, "medium cannot infer possession from private timer")
	expect(game.view_for("heir").possession_time == 60, "vessel retains their private timer")
	expect(not view.evidence.ledger.destroyed, "private destruction not disclosed")
	expect(view.evidence.ledger.holder == "unknown", "hidden evidence owner redacted")
	expect(not view.votes.has("doctor"), "individual ballot hidden")
	view.evidence.ledger.public = true
	expect(not game.state.evidence.ledger.public, "snapshot mutation cannot change authority")


func test_sealed_ballots() -> void:
	var game = GameRules.new()
	game.reset(CaseData.ROLES)
	game.state.phase = "judgment"
	var original = {"culprit": "doctor", "heir": "keeper", "ending": "banish"}
	expect(game.act("medium", "vote", original) == "", "first sealed vote accepted")
	expect(
		game.act("medium", "vote", {"culprit": "widow", "heir": "heir", "ending": "bind"}) != "",
		"sealed vote cannot be replaced"
	)
	expect(game.state.votes.medium == original, "rejected vote preserves original ballot")
	expect(game.state.phase == "judgment", "one ballot cannot end six-human sitting")


func test_solo_cases() -> void:
	for role in CaseData.ROLES:
		var game = GameRules.new()
		game.reset([role])
		for i in range(7):
			game.tick(1000)
		expect(game.state.phase == "ended", "solo can finish as " + role)
		expect(game.state.scores.size() == 6, "solo has all scores for " + role)
