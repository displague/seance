extends SceneTree
## Real widgets and scene; deterministic, with microphone and inference disabled.
var game: Node
var session: Node
var checks = 0
var failures = 0


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func settle() -> void:
	await process_frame
	await process_frame


func press(prefix: String) -> void:
	for button in game.ui.root.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text.begins_with(prefix):
			button.pressed.emit()
			await settle()
			return
	expect(false, "button found: " + prefix)


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/social-" + label + ".png")


func visible_text() -> String:
	var text = ""
	for node in game.ui.overlay.find_children("*", "Label", true, false):
		if node.is_visible_in_tree():
			text += node.text + "\n"
	return text


func run() -> void:
	session = root.get_node("Session")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.qa_mode = true
	await settle()
	await capture("menu")
	session.solo("medium")
	# Widget/consent fixtures start with the final chapter unlocked. The separate
	# progression suite verifies the real three-stage availability sequence.
	session.rules.state.round = 3
	session.publish()
	game.ui.close()
	session.rules.state.positions.medium = CaseData.CLUES.birth.pos
	game.ui.journal.inspect("birth", true)
	await settle()
	expect(not visible_text().contains("born 17 November"), "uncollected clue is not read")
	await press("TAKE INTO YOUR KEEPING")
	expect(game.ui.modal == "clue", "pickup stays open")
	expect(visible_text().contains("born 17 November 1913"), "full evidence readable immediately")
	await capture("register")
	game.ui.journal.inspect("safe", true)
	await settle()
	expect(visible_text().contains("first child was born"), "clear puzzle wording")
	expect(not visible_text().contains("changed everything"), "ambiguous heading removed")
	await press("Read the Nursery Register")
	expect(
		visible_text().contains("born 17 November 1913"),
		"puzzle-to-journal breadcrumb opens readable evidence"
	)
	game.ui.journal.inspect("safe", true)
	session.rules.state.positions.medium = CaseData.TASKS.safe.pos
	game.ui.rituals.solve("safe", "0000")
	expect(
		game.ui.modal == "task" and session.view.tasks.safe == "",
		"wrong code preserves puzzle, no points"
	)
	game.ui.rituals.solve("safe", "1913")
	expect(
		game.ui.modal == "task" and session.view.tasks.safe == "medium",
		"successful puzzle shows confirmation"
	)
	session.rules.state.positions.heir = CaseData.CLUES.will.pos
	session.rules.act("heir", "collect", {"id": "will"})
	session.rules.state.positions.medium = CaseData.ITEMS.ring.pos
	session.command("collect", {"id": "ring"})
	game.ui.journal.talk("heir")
	await settle()
	await press("Ask about their past")
	expect(visible_text().contains("sign a cheque"), "history appears in actual conversation")
	await press("Ask what they have found")
	await press("Ask for: The Last Testament")
	expect(session.view.items.ring == "medium", "offer does not spend inventory")
	await capture("trade-offer")
	await press("Accept trade:")
	expect(
		session.view.items.ring == "heir" and session.view.evidence.will.holder == "medium",
		"real trade button exchanges both items"
	)
	await capture("conversation")
	# Exercise free-input layout without a real service or opening a microphone.
	root.get_node("SoloAi").set_enabled(true)
	game.ui.conversation.open("keeper")
	await settle()
	expect(game.ui.conversation.input != null, "AI mode has free input")
	root.get_node("NpcSpeech").transcribed.emit("keeper", "Where is the register?")
	expect(game.ui.conversation.input.text == "Where is the register?", "transcript is editable")
	expect(not root.get_node("SoloAi").busy, "transcript does not auto-send")
	await capture("ai-input")
	game.ui.close()
	expect(root.get_node("NpcSpeech").focused_npc == "", "closing dialog cancels voice target")
	# No helper or captured speech needed: exercise an already playing synthetic
	# clip, independently of the modal UI's normal solo pause protection.
	var speech = root.get_node("NpcSpeech")
	session.rules.state.phase = "seance"
	speech.set_voice_out(true)
	speech.speaking_npc = "ghost"
	var clip = AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = 16000
	var silence = PackedByteArray()
	silence.resize(160000)
	clip.data = silence
	speech.output.stream = clip
	speech.output.play()
	expect(speech.output.playing and speech.permitted("ghost"), "synthetic ghost clip is playing")
	session.rules.state.phase = "investigation"
	speech._process(0)
	expect(
		not speech.output.playing and speech.output.stream == null and speech.speaking_npc == "",
		"playing ghost clip stops when listening permission closes"
	)
	session.leave()
	game.queue_free()
	root.get_node("Sound").shutdown()
	root.get_node("Music").shutdown()
	await create_timer(0.2).timeout
	print("SOCIAL UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
