extends SceneTree
## No model or microphone required: authority, privacy, consent and puzzle routes.
var checks = 0
var failures = 0


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func recover(game, role: String, id: String) -> void:
	game.state.positions[role] = CaseData.object_data(id).pos
	expect(game.act(role, "collect", {"id": id}) == "", role + " recovers " + id)


func talk(game, listener: String, npc: String, choice: String) -> String:
	return game.act(listener, "interact", {"target": npc, "choice": choice})


func run() -> void:
	var ai = root.get_node("SoloAi")
	var speech = root.get_node("NpcSpeech")
	expect(not ai.enabled and not ai.busy, "AI defaults off; startup contacts no model")
	expect(
		not speech.voice_in and not speech.voice_out and not speech.recording, "speech defaults off"
	)
	speech.start_capture()
	expect(speech.microphone.stream == null, "disabled speech cannot open microphone")
	for url in [
		"https://cloud.example/v1",
		"http://127.0.0.1.evil:1234/v1",
		"http://127.0.0.1:0/v1",
		"http://127.0.0.1:65536/v1",
		"http://192.168.1.2:1234/v1"
	]:
		expect(not ai.local_url(url), "refuse non-loopback endpoint " + url)
	expect(ai.local_url("http://127.0.0.1:1234/v1"), "local endpoint allowed")
	# Queued callbacks from cancelled requests must not clear a newer request.
	var pending_speech = HTTPRequest.new()
	speech.add_child(pending_speech)
	speech.speech_request = pending_speech
	speech._transcript(0, 200, [], PackedByteArray(), "keeper", speech.take_serial - 1, null)
	expect(
		speech.speech_request == pending_speech and not pending_speech.is_queued_for_deletion(),
		"stale transcription cannot cancel a newer take"
	)
	speech.cancel()
	var pending_probe = HTTPRequest.new()
	ai.add_child(pending_probe)
	ai.probe_request = pending_probe
	ai._models_received(0, 200, [], PackedByteArray(), ai.probe_generation - 1)
	expect(
		ai.probe_request == pending_probe and not pending_probe.is_queued_for_deletion(),
		"stale model probe cannot cancel a newer probe"
	)
	pending_probe.queue_free()
	ai.probe_request = null
	var game = GameRules.new()
	game.reset(["medium"])
	for role in CaseData.ROLES:
		expect(NpcData.PROFILES.has(role), "persona " + role)
		expect(speech.CAST.has(role), "voice " + role)
		expect(NpcData.PROFILES[role].history.length() > 40, "authored history " + role)
	expect(speech.CAST.values().size() == 6, "six cast slots")
	var distinct = {}
	for model in speech.CAST.values():
		distinct[model] = true
	expect(distinct.size() == 6, "six distinct voice models, not pitch variants of one speaker")
	expect(talk(game, "medium", "keeper", "topic:history") == "", "more than three topics")
	expect(talk(game, "medium", "keeper", "hint:safe") == "", "actionable puzzle help")
	expect(
		str(game.state.private_log.medium).contains("left of the reliquary"),
		"spatial clue breadcrumb"
	)
	expect(
		not str(game.view_for("heir").npc.keeper.history).contains("Eleanor"),
		"private conversations not broadcast"
	)
	expect(talk(game, "medium", "ghost", "topic:death") != "", "ghost blocked outside sitting")
	expect(
		talk(game, "ghost", "keeper", "topic:death") != "",
		"ghost cannot bypass medium with bot menu"
	)
	game.state.phase = "seance"
	expect(talk(game, "medium", "ghost", "topic:death") == "", "medium hears ghost at sitting")
	game.state.silenced = "keeper"
	expect(
		talk(game, "medium", "keeper", "topic:death") != "",
		"silenced NPC cannot bypass voice rules"
	)
	game.state.silenced = ""
	game.humans.append("keeper")
	expect(talk(game, "medium", "keeper", "topic:death") != "", "cannot drive human as NPC")
	game.reset(["medium"])
	recover(game, "heir", "will")
	recover(game, "medium", "ring")
	expect(talk(game, "medium", "heir", "request:will") == "", "NPC makes offer")
	expect(
		game.state.items.ring == "medium" and game.state.evidence.will.holder == "heir",
		"offer changes no ownership"
	)
	expect(
		(
			ai.apply_reply(game, "medium", "heir", {"speech": "Agreed", "choice": "accept:trade"})
			!= ""
		),
		"LLM cannot consent for player"
	)
	expect(talk(game, "medium", "heir", "accept:trade") == "", "explicit trade accepted")
	expect(
		game.state.items.ring == "heir" and game.state.evidence.will.holder == "medium",
		"both objects exchanged"
	)
	expect(talk(game, "medium", "heir", "accept:trade") != "", "no replayed trade")
	expect(
		talk(game, "medium", "heir", "request:ring") == "" and game.state.items.ring == "heir",
		"NPC refuses to surrender own goal"
	)
	game.reset(["medium"])
	recover(game, "heir", "will")
	recover(game, "medium", "ring")
	talk(game, "medium", "heir", "request:will")
	game.act("medium", "give", {"id": "ring", "target": "keeper"})
	expect(talk(game, "medium", "heir", "accept:trade") != "", "stale offer rejected")
	expect(game.state.evidence.will.holder == "heir", "failed exchange is atomic")
	game.reset(["medium"])
	recover(game, "widow", "letter")
	recover(game, "medium", "vial")
	expect(talk(game, "medium", "widow", "show:vial") == "", "show a clue without giving it")
	expect(game.public_clue("letter"), "proof persuades widow to reveal new information")
	expect(
		not game.public_clue("vial") and game.state.evidence.vial.holder == "medium",
		"showing is private and keeps ownership"
	)
	expect(NpcRules.knows(game, "widow", "vial"), "NPC remembers shown evidence")
	expect(
		talk(game, "medium", "keeper", "show:ledger") != "", "cannot show a clue you never obtained"
	)
	expect(
		not str(NpcRules.context(game, "medium", "keeper")).contains(CaseData.CLUES.ledger.text),
		"model never receives whole case answer"
	)
	recover(game, "medium", "clock")
	talk(game, "medium", "widow", "show:clock")
	game.state.phase = "judgment"
	game.resolve()
	expect(game.state.votes.widow.culprit == "doctor", "private evidence changes NPC ballot")
	expect(
		game.state.votes.heir.culprit == "none", "unheard evidence does not change another ballot"
	)
	game.reset(["heir"])
	recover(game, "heir", "ledger")
	game.state.evidence.ledger.holder = "medium"
	expect(
		not NpcRules.available(game, "medium", "doctor", "deal:ledger"),
		"non-beneficiary is not offered an ineligible political bargain"
	)
	game.state.evidence.ledger.holder = "heir"
	expect(talk(game, "heir", "doctor", "deal:ledger") == "", "explicit costly political bargain")
	game.state.phase = "judgment"
	game.resolve()
	expect(game.state.votes.doctor.heir == "heir", "doctor honors heir pledge")
	game.reset(["medium"])
	recover(game, "widow", "locket")
	expect(talk(game, "medium", "widow", "deliver:locket") == "", "NPC can give to third party")
	expect(
		game.state.items.locket == "keeper" and game.completed_goals("widow")[1],
		"NPC transfer completes motive"
	)
	game.reset(["medium"])
	recover(game, "keeper", "birth")
	expect(
		talk(game, "medium", "keeper", "reveal:birth") == "", "request unlocks register in journal"
	)
	expect(game.view_for("medium").evidence.birth.public, "register is actually available")
	var pattern = RegEx.new()
	pattern.compile("born [0-9]+ [A-Za-z]+ ([0-9]{4})")
	var year = pattern.search(CaseData.CLUES.birth.text).get_string(1)
	game.state.positions.medium = CaseData.TASKS.safe.pos
	expect(
		game.act("medium", "task", {"id": "safe", "answer": year}) == "",
		"puzzle solved from actual recovered text, no hardcoded test answer"
	)
	for invalid in [
		null,
		[],
		{"speech": 7, "choice": ""},
		{"speech": "I win", "choice": "set_score:999"},
		{"speech": "", "choice": ""},
		{"speech": " \n ", "choice": ""}
	]:
		expect(
			ai.apply_reply(game, "medium", "keeper", invalid) != "", "invalid model output denied"
		)
	var pcm = PackedByteArray()
	pcm.resize(32000)
	var wav = speech.wav_bytes(pcm)
	expect(wav.size() == 32044 and wav.decode_u32(24) == 16000, "native PCM WAV header")
	expect(not speech.transcribe_wav(wav, "keeper"), "disabled STT cannot upload audio")
	game.reset(["medium"])
	game.state.interactive_guests = true
	for step in range(2400):
		game.tick(0.05)
	expect(game.state.items.ring == "heir", "active heir physically seeks signet")
	expect(game.state.items.key == "keeper", "active keeper physically seeks key")
	expect(game.state.items.locket == "widow", "active widow physically seeks locket")
	expect(game.state.evidence.ledger.holder == "doctor", "doctor competes for ledger")
	expect(game.state.evidence.birth.holder == "keeper", "keeper recovers lineage")
	for npc in NpcDirector.PLANS:
		expect(CaseData.is_walkable(game.state.positions[npc]), "NPC stays in manor " + npc)
	expect(
		talk(game, "medium", "widow", "deliver:locket") == "",
		"active NPC negotiable after physical investigation"
	)
	expect(
		NpcRules.explicit_puzzle("Where is the reliquary year?") == "hint:safe",
		"named puzzle grounds tool selection"
	)
	expect(
		NpcRules.explicit_puzzle("Tell me about your childhood") == "",
		"personal conversation stays open"
	)
	print("NPC: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
