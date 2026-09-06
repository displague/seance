extends SceneTree
## Three real ENet processes. Synthetic PCM only; no microphone capture.

var session: Node
var voice: Node
var mode = ""
var checks = 0
var failures: Array = []
var lost = false
var barrier: Node


class PhaseBarrier:
	extends Node
	var reports: Dictionary = {}

	@rpc("any_peer", "call_remote", "reliable", 0)
	func complete(stage_number: int) -> void:
		reports[multiplayer.get_remote_sender_id()] = stage_number


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", mode, " ", message)


func until(condition: Callable, timeout: float = 8) -> bool:
	var deadline = Time.get_ticks_msec() + int(timeout * 1000)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	return condition.call()


func heard(text: String) -> bool:
	return str(session.view.get("messages", [])).contains(text)


func received_voice(role: String) -> bool:
	return voice.speakers.has(role)


func send_pcm() -> void:
	var packet = PackedByteArray()
	packet.resize(960)
	# Very quiet generated tone; no audio input stream is started.
	for i in range(480):
		packet.encode_s16(i * 2, int(sin(i * TAU * 220 / 16000.0) * 100))
	for i in range(4):
		voice.rpc_id(1, "_upload", packet)
		await create_timer(0.05).timeout


func stage(number: int) -> void:
	voice.stop()
	barrier.reports.clear()
	session.command("chat", {"text": "TEST_STAGE " + str(number)})
	expect(
		await until(func(): return barrier.reports.values().count(number) == 2),
		"both clients completed stage " + str(number)
	)
	# Reliable stage completion is separate from unreliable PCM. Allow a short
	# drain interval before changing permissions, without weakening delivery checks.
	await create_timer(0.15).timeout


func run() -> void:
	session = root.get_node("Session")
	voice = root.get_node("Voice")
	barrier = PhaseBarrier.new()
	barrier.name = "QABarrier"
	root.add_child(barrier)
	mode = OS.get_cmdline_user_args()[0]
	session.connection_lost.connect(func(): lost = true)
	if mode == "--net-host":
		await host_case()
	else:
		await client_case("ghost" if mode == "--net-ghost" else "heir")
	expect(not voice.enabled, "microphone was never enabled")
	session.leave()
	await create_timer(0.15).timeout
	print("NETWORK ", mode, ": ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func host_case() -> void:
	expect(session.host("medium", "QA host") == OK, "host binds port")
	if not await until(func(): return session.lobby.size() == 3):
		expect(false, "two clients registered")
		return
	var roles = []
	for guest in session.lobby.values():
		roles.append(guest.role)
	expect(roles.has("ghost") and roles.has("heir"), "roles assigned uniquely")
	session.start_host_game()
	await create_timer(0.5).timeout
	await stage(1)
	expect(not heard("secret_investigation"), "ghost text withheld outside sitting")
	expect(not received_voice("ghost"), "ghost audio withheld outside sitting")
	session.advance()
	await stage(2)
	await until(func(): return heard("secret_seance") and received_voice("ghost"), 2)
	expect(heard("secret_seance"), "medium receives ghost text in sitting")
	expect(received_voice("ghost"), "medium receives ghost audio in sitting")
	expect(session.rules.state.manifest == 0, "living guest cannot forge manifestation")
	session.advance()
	await stage(3)
	expect(session.rules.state.possession == "heir", "possession accepted over RPC")
	expect(not heard("secret_possession"), "medium cannot hear vessel channel outside sitting")
	expect(not received_voice("ghost"), "private vessel voice not relayed to medium")
	await stage(4)
	expect(session.rules.state.silenced == "heir", "silence accepted over RPC")
	expect(not heard("secret_silenced"), "silenced text not relayed to medium")
	expect(not received_voice("heir"), "silenced audio not relayed to medium")
	session.rules.state.silence_time = 0.01
	await create_timer(0.1).timeout
	for id in ["radio", "candles"]:
		session.move_local(CaseData.TASKS[id].pos)
		session.command("task", {"id": id, "answer": CaseData.TASKS[id].solution})
	expect(session.view.prepared == 2, "preparations replicate")
	for i in range(4):
		if session.view.phase != "judgment":
			if session.view.phase == "seance" and session.view.round == 3:
				for role in CaseData.ROLES:
					session.rules.state.positions[role] = CaseData.TASKS.radio.pos
			session.advance()
	await until(func(): return session.rules.state.votes.size() == 2)
	expect(session.rules.state.votes.size() == 2, "both client ballots arrive")
	session.command("vote", {"culprit": "doctor", "heir": "keeper", "ending": "release"})
	expect(session.view.phase == "ended", "final human ballot resolves case")
	expect(session.view.ending.ending == "release", "majority release computed")
	expect(session.view.scores.size() == 6, "all roles scored")
	expect(await until(func(): return session.lobby.size() == 2), "guest disconnect detected")
	expect(not session.rules.humans.has("heir"), "disconnected guest returns to house")
	await create_timer(0.3).timeout
	session.leave()
	await create_timer(0.4).timeout
	expect(session.host("doctor", "second circle") == OK, "port reusable after leaving")
	session.leave()
	session.solo("keeper")
	expect(
		session.active and not session.online and session.local_role == "keeper",
		"solo after online cleanup"
	)


func client_case(role: String) -> void:
	var args = OS.get_cmdline_user_args()
	var address = args[1] if args.size() > 1 else "127.0.0.1"
	expect(session.join_room(address, role, "QA " + role) == OK, "join initiated")
	if not await until(func(): return session.active):
		expect(false, "received start snapshot")
		return
	expect(session.local_role == role, "requested role received")
	expect(session.view.humans.size() == 3, "human roster replicated")
	expect(not session.view.has("private_log"), "no complete private logs in snapshot")
	var origin: Vector3 = session.view.positions[role]
	session.move_local(origin + Vector3(0.1, 0, 0))
	await create_timer(0.35).timeout
	expect(
		session.view.positions[role].distance_to(origin + Vector3(0.1, 0, 0)) < 0.05,
		"spawn movement accepted"
	)
	for number in range(1, 5):
		if not await until(func(): return heard("TEST_STAGE " + str(number))):
			expect(false, "stage received " + str(number))
			return
		voice.stop()
		if number == 1:
			var server_peer = session.multiplayer.multiplayer_peer.get_peer(1)
			expect(
				server_peer.get_statistic(ENetPacketPeer.PEER_PACKET_THROTTLE_LIMIT) == 32,
				"host does not accidentally advertise a tiny incoming bandwidth cap"
			)
		if role == "ghost":
			await ghost_stage(number)
		else:
			await guest_stage(number)
		barrier.complete.rpc_id(1, number)
	if not await until(func(): return session.view.get("phase", "") == "judgment"):
		expect(false, "judgment replicated")
		return
	expect(session.view.prepared == 2, "release prerequisites visible")
	expect(
		session.view.positions[role] == CaseData.spawn_at(role),
		"judgment teleport is replicated from the host"
	)
	session.command("vote", {"culprit": "doctor", "heir": "keeper", "ending": "release"})
	expect(
		await until(func(): return session.view.get("phase", "") == "ended"), "ending replicated"
	)
	expect(session.view.get("scores", []).size() == 6, "scores replicated")
	if role == "ghost":
		expect(await until(func(): return lost), "host shutdown notifies client")
		expect(
			not session.active and not session.online, "client lifecycle cleaned after host loss"
		)
	else:
		session.leave()


func ghost_stage(number: int) -> void:
	if number == 3:
		session.command("possess", {"target": "heir"})
	if number == 4:
		session.command("silence", {"target": "heir"})
	await create_timer(0.15).timeout
	var text = ["", "secret_investigation", "secret_seance", "secret_possession", "ghost_four"][number]
	session.command("chat", {"text": text})
	await send_pcm()
	if number == 4:
		await until(func(): return heard("secret_silenced") and received_voice("heir"), 2)
		expect(heard("secret_silenced"), "ghost receives silenced text")
		expect(received_voice("heir"), "ghost receives silenced audio")


func guest_stage(number: int) -> void:
	if number == 2:
		session.command("manifest", {"word": "YES", "role": "ghost"})
	if number == 4:
		await create_timer(0.25).timeout
		session.command("chat", {"text": "secret_silenced"})
		await send_pcm()
	await create_timer(0.3).timeout
	match number:
		1:
			expect(not heard("secret_investigation"), "guest cannot read ghost outside sitting")
			expect(not received_voice("ghost"), "guest cannot hear ghost outside sitting")
		2:
			expect(not heard("secret_seance"), "guest cannot read medium's private channel")
			expect(not received_voice("ghost"), "guest cannot hear medium's private channel")
		3:
			await until(func(): return heard("secret_possession") and received_voice("ghost"), 2)
			expect(session.view.possessed, "vessel privately notified")
			expect(heard("secret_possession"), "vessel receives ghost text")
			expect(received_voice("ghost"), "vessel receives ghost audio")
