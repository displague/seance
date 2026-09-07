extends SceneTree
## Six real ENet peers pursuing role-specific objectives. Scripted policy, not
## a human entertainment verdict or six independent language-model players.
var session: Node
var role = ""
var checks = 0
var failures = 0
var barrier: Node


class PartyBarrier:
	extends Node
	var reports: Dictionary = {}
	@rpc("any_peer", "call_remote", "reliable", 0)
	func report(stage: int) -> void:
		reports[multiplayer.get_remote_sender_id()] = stage


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", role, " ", label)


func until(condition: Callable, seconds: float = 50) -> bool:
	var end = Time.get_ticks_msec() + int(seconds * 1000)
	while not condition.call() and Time.get_ticks_msec() < end:
		await create_timer(0.05).timeout
	return condition.call()


func act(action: String, payload: Dictionary) -> void:
	session.command(action, payload)
	await create_timer(0.35).timeout


func go(id: String) -> void:
	var here: Vector3 = session.view.positions[role]
	for waypoint in NpcDirector.route(here, CaseData.object_data(id).pos):
		while here.distance_to(waypoint) > 0.1:
			here = here.move_toward(waypoint, 0.24)
			session.move_local(here)
			await create_timer(0.05).timeout
	await create_timer(0.35).timeout
	expect(session.view.positions[role].distance_to(here) < 0.7, "movement accepted at " + id)


func collect(id: String) -> void:
	await go(id)
	await act("collect", {"id": id})
	var holder: String = (
		session.view.items[id] if CaseData.ITEMS.has(id) else session.view.evidence[id].holder
	)
	expect(holder == role, "collected " + id)


func run() -> void:
	role = OS.get_cmdline_user_args()[0]
	session = root.get_node("Session")
	barrier = PartyBarrier.new()
	barrier.name = "SixSeatBarrier"
	root.add_child(barrier)
	if role == "medium":
		expect(session.host(role, "Party " + role) == OK, "host binds")
		expect(await until(func(): return session.lobby.size() == 6, 15), "all six seats connected")
		session.start_host_game()
	else:
		expect(session.join_room("127.0.0.1", role, "Party " + role) == OK, "client connects")
		expect(await until(func(): return session.active, 15), "game started")
	if not session.active:
		quit(1)
		return
	expect(session.view.humans.size() == 6, "six actual peers, no house replacements")
	match role:
		"medium":
			await collect("vial")
			await act("reveal", {"id": "vial"})
			await collect("flowers")
			await act("reveal", {"id": "flowers"})
			for id in ["candles"]:
				await go(id)
				await act("task", {"id": id, "answer": CaseData.TASKS[id].solution})
				expect(session.view.tasks[id] == role, "prepared " + id)
		"heir":
			await collect("ring")
			await act(
				"chat",
				{
					"text":
					"I have the seal. Vote for binding: a father should not abandon his family."
				}
			)
		"widow":
			await collect("letter")
			await collect("locket")
			await act("reveal", {"id": "letter"})
			await act("give", {"id": "locket", "target": "keeper"})
			expect(session.view.items.locket == "keeper", "third-party gift landed")
		"keeper":
			await collect("key")
			await act(
				"chat",
				{"text": "The register and the will are my claim. I want my home, not revenge."}
			)
		"doctor":
			await act(
				"chat",
				{
					"text":
					"Lenore carried the glass. Do not confuse a substance with the hand that delivered it."
				}
			)
		"ghost":
			await act("manifest", {"word": "BETRAYAL"})
			await act("chat", {"text": "PARTY_PRIVATE_BEFORE_SITTING"})
	if role == "medium":
		expect(
			await until(func(): return barrier.reports.values().count(1) == 5),
			"all five clients finished investigation"
		)
		expect(
			not str(session.view.messages).contains("PARTY_PRIVATE_BEFORE_SITTING"),
			"ghost privacy before sitting"
		)
		session.advance()
	else:
		barrier.report.rpc_id(1, 1)
	expect(await until(func(): return session.view.phase == "seance"), "circle convened")
	if role == "ghost":
		await act(
			"chat", {"text": "PARTY_PRIVATE_AT_SITTING: Please let Iris inherit. Release me."}
		)
	await create_timer(0.7).timeout
	expect(
		(
			str(session.view.messages).contains("PARTY_PRIVATE_AT_SITTING")
			== (role in ["medium", "ghost"])
		),
		"asymmetric ghost channel"
	)
	if role == "medium":
		expect(
			await until(func(): return barrier.reports.values().count(2) == 5),
			"all peers heard legal channels"
		)
		session.advance()
	else:
		barrier.report.rpc_id(1, 2)
	for chapter in [2, 3]:
		expect(await until(in_chapter.bind(chapter)), "new investigation replicated")
		await chapter_actions(chapter)
		if role == "medium":
			expect(
				await until(func(): return barrier.reports.values().count(chapter + 1) == 5),
				"peers complete chapter %d opportunities" % chapter
			)
			session.advance()
			await create_timer(0.4).timeout
			session.advance()
		else:
			barrier.report.rpc_id(1, chapter + 1)
	expect(await until(func(): return session.view.phase == "judgment"), "judgment reached")
	var culprit = "widow" if role in ["heir", "doctor"] else "doctor"
	await act(
		"vote",
		{
			"culprit": culprit,
			"heir": "heir" if role in ["heir", "doctor"] else "keeper",
			"ending": "bind" if role == "heir" else "banish" if role == "doctor" else "release"
		}
	)
	expect(await until(func(): return session.view.phase == "ended"), "six ballots resolve")
	expect(session.view.scores.size() == 6, "all six scored")
	print(
		"PARTY OUTCOME ",
		role,
		" ",
		JSON.stringify(session.view.ending),
		" ",
		JSON.stringify(session.view.scores)
	)
	# Let every client receive the final reliable snapshot before the host closes.
	await create_timer(1).timeout
	session.leave()
	await create_timer(0.2).timeout
	print("SIX SEAT ", role, ": ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)


func in_chapter(chapter: int) -> bool:
	return session.view.phase == "investigation" and session.view.round == chapter


func chapter_actions(chapter: int) -> void:
	if chapter == 2:
		if role == "medium":
			await go("radio")
			await act("task", {"id": "radio", "answer": CaseData.TASKS.radio.solution})
			expect(session.view.tasks.radio == role, "prepared newly unsealed radio")
		elif role == "heir":
			await collect("will")
			await act("reveal", {"id": "will"})
		elif role == "keeper":
			await collect("birth")
			await act("reveal", {"id": "birth"})
	else:
		if role == "doctor":
			await collect("ledger")
			await act("destroy", {"id": "ledger"})
			expect(
				session.view.evidence.ledger.destroyed,
				"doctor conceals original financial evidence"
			)
		elif role == "medium":
			await go("audit")
			await act("collect", {"id": "audit"})
			expect(
				session.view.evidence.audit.public,
				"final audit entered as public reference over network"
			)
