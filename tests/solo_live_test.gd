extends SceneTree
## Explicit opt-in integration probe: real local LM Studio, Piper and whisper.cpp.
## Uses generated test speech, NEVER the user's microphone. Not in the offline gate.
var failures = 0
var checks = 0
var transcript = ""


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func run() -> void:
	if not OS.get_cmdline_user_args().has("--live-local"):
		printerr("Pass -- --live-local to contact your running local services.")
		quit(2)
		return
	var session = root.get_node("Session")
	var ai = root.get_node("SoloAi")
	var speech = root.get_node("NpcSpeech")
	ai.model = "lfm2.5-2.6b"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--model="):
			ai.model = argument.trim_prefix("--model=")
	ai.base_url = "http://127.0.0.1:1234/v1"
	ai.probe()
	await create_timer(2).timeout
	expect(ai.models.has(ai.model), "selected model exists")
	for npc in CaseData.ROLES:
		session.solo("heir" if npc == "medium" else "medium", true)
		session.suspended = true
		if npc == "ghost":
			session.advance()
		speech.focus(npc)
		ai.ask(npc, "I cannot open the reliquary. Where should I look for the year?")
		var deadline = Time.get_ticks_msec() + 40000
		while ai.busy and Time.get_ticks_msec() < deadline:
			await process_frame
		var history: Array = session.view.npc[npc].history
		expect(
			not ai.busy and str(history).contains("Memorial Chapel"),
			"live grounded help from " + npc
		)
		print("LIVE AI ", npc, " ", ai.status, " ", JSON.stringify(history))
		speech.set_voice_out(true)
		expect(
			speech.say(npc, "The nursery register is in the chapel. Read the first page."),
			"native voice launched " + npc
		)
		deadline = Time.get_ticks_msec() + 18000
		while not speech.job.is_empty() and Time.get_ticks_msec() < deadline:
			await process_frame
		expect(
			speech.output.stream != null and speech.output.stream.get_length() > 1,
			"real PCM speech generated " + npc
		)
		print("LIVE VOICE ", npc, " ", speech.status)
		if speech.clip_path != "" and FileAccess.file_exists(speech.clip_path):
			DirAccess.copy_absolute(
				speech.clip_path,
				ProjectSettings.globalize_path("res://artifacts/npc-" + npc + ".wav")
			)
		speech.stop_speaking()
	# Live tool selection must do more than route a puzzle hint.
	session.solo("medium", true)
	session.suspended = true
	session.rules.state.positions.heir = CaseData.CLUES.will.pos
	session.rules.act("heir", "collect", {"id": "will"})
	session.rules.state.positions.medium = CaseData.ITEMS.ring.pos
	session.command("collect", {"id": "ring"})
	(
		ai
		. ask(
			"heir",
			"May I have The Last Testament? I have the Ashwood Signet to offer. Please propose the exchange, not just tell me your history."
		)
	)
	var trade_deadline = Time.get_ticks_msec() + 40000
	while ai.busy and Time.get_ticks_msec() < trade_deadline:
		await process_frame
	expect(
		session.rules.state.npc.offers.has("medium:heir"),
		"live model negotiates a real trade offer"
	)
	expect(session.view.items.ring == "medium", "AI offer requires human consent")
	print("LIVE BARGAIN: ", JSON.stringify(session.view.npc.heir.history))
	session.command("interact", {"target": "heir", "choice": "accept:trade"})
	expect(
		session.view.items.ring == "heir" and session.view.evidence.will.holder == "medium",
		"accepted live-model offer changes ownership"
	)
	(
		ai
		. ask(
			"keeper",
			"Are you more frightened of being forgotten or being remembered? Please answer me personally, rather than reciting your past."
		)
	)
	var free_deadline = Time.get_ticks_msec() + 40000
	while ai.busy and Time.get_ticks_msec() < free_deadline:
		await process_frame
	expect(
		str(session.view.npc.keeper.history).contains("[AI dialogue; not evidence]"),
		"actual generated personal reply, not a canned node"
	)
	print("LIVE PERSONAL: ", JSON.stringify(session.view.npc.keeper.history))
	# A pending answer must not outlive its session.
	ai.ask("keeper", "What do you want to do at dawn?")
	ai.cancel()
	expect(not ai.busy, "in-flight request cancellable")
	# Feed generated speech through real STT; never open a hardware microphone.
	session.solo("medium", true)
	session.suspended = true
	speech.focus("keeper")
	speech.set_voice_in(true)
	speech.transcribed.connect(func(_npc, text): transcript = text)
	var audio_path = "res://artifacts/npc-keeper.wav"
	if FileAccess.file_exists(audio_path):
		expect(
			speech.transcribe_wav(FileAccess.get_file_as_bytes(audio_path), "keeper"),
			"real local STT requested"
		)
		var deadline = Time.get_ticks_msec() + 35000
		while is_instance_valid(speech.speech_request) and Time.get_ticks_msec() < deadline:
			await process_frame
		expect(transcript.to_lower().contains("nursery register"), "actual speech transcribed")
		print("LIVE TRANSCRIPT: ", transcript)
		expect(speech.microphone.stream == null, "live probe never opened microphone")
	session.leave()
	root.get_node("Sound").shutdown()
	root.get_node("Music").shutdown()
	await create_timer(0.2).timeout
	print("SOLO LIVE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
