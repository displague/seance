extends SceneTree
## Actual scene, physics raycasts, input events, and UI button signals.
## Run with -- --qa for a rendered test; headless is also supported.

var game: Node3D
var session: Node
var checks = 0
var failures: Array = []


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func settle() -> void:
	await process_frame
	await process_frame


func press(text: String) -> void:
	for button in game.ui.root.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text.begins_with(text):
			expect(not button.disabled, "enabled button " + text)
			button.pressed.emit()
			await settle()
			return
	expect(false, "button exists " + text)


func key(code: Key, down: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func tap(code: Key) -> void:
	key(code, true)
	await settle()
	key(code, false)
	await settle()


func walk(code: Key, duration: float) -> void:
	key(code, true)
	await create_timer(duration).timeout
	key(code, false)
	await create_timer(0.15).timeout


func approach(id: String, offset: Vector3 = Vector3(0, 0, 1.7)) -> void:
	game.ui.close()
	var point: Vector3 = CaseData.object_data(id).pos
	game.player.place(Vector3(point.x, 0, point.z) + offset, false)
	game.player.camera.look_at(point + Vector3(0, 0.09, 0))
	await create_timer(0.2).timeout
	expect(game.player.target_id == id, "physics ray reaches " + id)
	await tap(KEY_E)
	expect(game.ui.modal in ["clue", "item", "task"], "interaction opens " + id)


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/qa_" + label + ".png")
	print(
		"FRAME: ",
		label,
		" FPS ",
		Engine.get_frames_per_second(),
		" DRAW CALLS ",
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	)


func run() -> void:
	session = root.get_node("Session")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.qa_mode = true
	await settle()
	await press("ENTER ASHWOOD")
	expect(game.ui.modal == "role", "role menu opened")
	await press("BEGIN THE REHEARSAL")
	expect(session.active and session.local_role == "medium", "solo medium session started")
	expect(session.suspended, "dossier pauses solo clock")
	await press("STEP INSIDE")
	expect(game.player.enabled and not session.suspended, "enter restores movement and clock")
	game.player.place(Vector3(0, 0, 5.8))
	await walk(KEY_W, 1.8)
	expect(
		game.player.position.z < 3.0 and game.player.position.z > 2.6, "walking collides with table"
	)
	game.player.place(Vector3(-6, 0, 0), false)
	game.player.rotation.y = 0
	await walk(KEY_A, 1.3)
	expect(game.player.position.x < -8.5, "library doorway is traversable")
	expect(game.player.position.y > -0.1, "room floors hold player")
	await approach("will")
	await press("TAKE INTO YOUR KEEPING")
	expect(session.view.evidence.will.holder == "medium", "world pickup changes authority")
	expect(not game.manor.targets.will.visual.visible, "collected object disappears")
	game.ui.journal.inspect("will")
	await settle()
	await press("REVEAL TO THE CIRCLE")
	expect(session.view.evidence.will.public, "reveal publishes evidence")
	await approach("ring")
	await press("CLAIM THIS INHERITANCE")
	game.ui.journal.inspect_item("ring")
	await settle()
	await press("Give to another guest")
	await press("Julian Ashwood")
	expect(session.view.items.ring == "heir", "gift transfers ownership")
	await approach("radio", Vector3(0, 0, 1.5))
	var dial = game.ui.overlay.find_children("*", "HSlider", true, false)[0]
	dial.value = 88.7
	await press("HOLD THE FREQUENCY")
	expect(session.view.tasks.radio == "medium", "radio puzzle completes")
	await approach("candles", Vector3(0, 0, 2.9))
	await press("SUN")
	await press("Reset the symbols")
	expect(game.ui.rituals.sequence.is_empty(), "candle reset handler")
	for symbol in ["MOON", "THORN", "KEY"]:
		await press(symbol)
	await press("LIGHT THE CIRCLE")
	expect(session.view.tasks.candles == "medium", "candle sequence completes")
	await approach("safe", Vector3(0, 0, 1.7))
	var code = game.ui.overlay.find_children("*", "LineEdit", true, false)[0]
	code.text = "1913"
	await press("OPEN THE RELIQUARY")
	expect(
		session.view.prepared == 3 and session.view.task_points.medium == 3,
		"three preparations score once each"
	)
	game.ui.journal.talk("doctor")
	await settle()
	await press("Ask about the death")
	expect(
		str(session.view.messages).contains("heart was failing"), "authored conversation responds"
	)
	await tap(KEY_ESCAPE)
	await tap(KEY_C)
	await press("CONVENE THE SÉANCE")
	expect(session.view.phase == "seance", "circle advances phase")
	await press("Ask how he died")
	expect(game.ui.modal == "transcript", "medium question opens private transcript")
	expect(str(session.view.messages).contains("Bitter flowers"), "ghost response delivered")
	await capture("transcript")
	game.ui.close()
	for i in range(5):
		game.ui.rituals.circle()
		await settle()
		await press("BREAK THE CIRCLE" if session.view.phase == "seance" else "CONVENE THE SÉANCE")
	expect(session.view.phase == "judgment", "three complete sittings lead to judgment")
	await capture("judgment")
	var picks = game.ui.overlay.find_children("*", "OptionButton", true, false)
	if picks.size() == 3:
		picks[0].select(1)
		picks[1].select(1)
		picks[2].select(0)
	await press("SEAL MY TESTAMENT")
	expect(session.view.phase == "ended", "UI ballot resolves solo case")
	expect(game.ui.modal == "results", "ending screen opens")
	expect(session.view.ending.ending == "release", "prepared release selected")
	await capture("results")
	await press("LEAVE ASHWOOD")
	expect(not session.active and game.ui.menu_root.visible, "return to menu cleans session")
	await ballot_snapshot_smoke()
	await role_smoke()
	game.ui.menu.choose_role("host")
	await settle()
	await press("OPEN THE CIRCLE")
	expect(session.online and game.ui.modal == "lobby", "host lobby opens through menu")
	await press("BEGIN THE SITTING")
	expect(session.active and session.online, "starting host from lobby does not disconnect it")
	game.ui.show_menu()
	await settle()
	print("RUNTIME: ", checks, " checks, ", failures.size(), " failures")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)


func ballot_snapshot_smoke() -> void:
	# Exercise the actual incoming-snapshot signal path without a synchronous
	# host command masking the stale non-host ballot panel regression.
	session.solo("medium")
	session.rules.state.phase = "judgment"
	session.publish()
	await settle()
	expect(not game.ui.rituals.ballot_submitted, "initial ballot is editable")
	var snapshot = session.view.duplicate(true)
	snapshot.votes = {"count": 1, "submitted": true}
	session._snapshot(snapshot)
	await settle()
	expect(game.ui.rituals.ballot_submitted, "received snapshot locks the displayed ballot")
	var visible_picks = 0
	for pick in game.ui.overlay.find_children("*", "OptionButton", true, false):
		if pick.is_visible_in_tree():
			visible_picks += 1
	expect(visible_picks == 0, "sealed snapshot removes ballot selectors")
	var label = game.ui.rituals.ballot_status
	session._snapshot(snapshot)
	await settle()
	expect(label == game.ui.rituals.ballot_status, "unchanged ballot snapshot does not rebuild UI")
	game.ui.show_menu()
	await settle()


func role_smoke() -> void:
	for role in CaseData.ROLES:
		game.ui.menu.choose_role("solo")
		await settle()
		game.ui.menu.role_buttons[role].pressed.emit()
		expect(game.ui.menu.chosen == role, "role card selects " + role)
		await press("BEGIN THE REHEARSAL")
		await settle()
		expect(game.ui.modal == "dossier", "dossier builds for " + role)
		for open_page in [
			game.ui.journal.open,
			game.ui.journal.inheritance,
			game.ui.journal.people,
			game.ui.journal.estate
		]:
			open_page.call()
			await settle()
		if role == "ghost":
			game.ui.rituals.spirit()
			await settle()
			await capture("spirit")
			await press("KNOCK")
			expect(session.view.manifest_word == "KNOCK", "ghost board handler works")
		game.ui.show_menu()
		await settle()
