extends SceneTree
## Synthetic SDL-standard events against real widgets, not physical pad certification.

var game: Node
var session: Node
var controls: Node
var checks = 0
var failures = 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)


func settle() -> void:
	await process_frame
	await process_frame


func button(index: int, down: bool) -> void:
	var event = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = down
	Input.parse_input_event(event)


func pad(index: int) -> void:
	button(index, true)
	await settle()
	button(index, false)
	await settle()


func axis(index: int, value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.device = 0
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)


func first_action() -> String:
	for node in game.ui.overlay.find_children("*", "Button", true, false):
		if node != game.ui.close_button and node.is_visible_in_tree():
			return node.text
	return ""


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/navigation-" + label + ".png")


func run() -> void:
	session = root.get_node("Session")
	controls = root.get_node("Controls")
	for name in [
		"Stadia Controller",
		"Google Stadia",
		"Xbox Wireless Controller",
		"DualSense Wireless Controller"
	]:
		var stadia = name.to_lower().contains("stadia")
		expect(
			controls.menu_action(JOY_BUTTON_START, name) == ("journal" if stadia else "pause"),
			"menu mapping: " + name
		)
		expect(
			controls.menu_action(JOY_BUTTON_BACK, name) == ("pause" if stadia else "journal"),
			"secondary menu mapping: " + name
		)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.qa_mode = true
	await settle()
	session.solo("medium")
	expect(
		session.rules.state.interactive_guests,
		"ordinary rehearsal enables physical goal-driven NPCs"
	)
	expect(not root.get_node("SoloAi").enabled, "physical NPCs do not require model opt-in")
	game.ui.journal.open()
	await settle()
	for page in ["inheritance", "dossier", "people", "estate", "transcript", "journal"]:
		await pad(JOY_BUTTON_RIGHT_SHOULDER)
		expect(game.ui.modal == page, "RB next journal tab: " + page)
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	expect(game.ui.modal == "transcript", "LB wraps evidence to transcript")
	await pad(JOY_BUTTON_B)
	expect(game.ui.modal == "", "B leaves top-level journal")
	var stadia = Input.get_joy_name(0).to_lower().contains("stadia")
	var journal_button = JOY_BUTTON_START if stadia else JOY_BUTTON_BACK
	var pause_button = JOY_BUTTON_BACK if stadia else JOY_BUTTON_START
	await pad(journal_button)
	expect(game.ui.modal == "journal", "actual device menu shortcut opens journal")
	await pad(pause_button)
	expect(game.ui.modal == "pause", "actual device secondary shortcut opens pause from journal")
	await pad(journal_button)
	expect(game.ui.modal == "journal", "journal shortcut goes directly from pause to evidence")
	game.ui.journal.inspect("clock", true)
	await settle()
	expect(first_action() == "Back to journal", "uncollected evidence back action first")
	await pad(JOY_BUTTON_B)
	expect(game.ui.modal == "journal", "B returns from world evidence to journal")
	session.rules.state.positions.medium = CaseData.CLUES.clock.pos
	session.command("collect", {"id": "clock"})
	game.ui.journal.inspect("clock")
	await settle()
	expect(first_action() == "Back to journal", "private evidence back action first")
	game.ui.journal._evidence_action("reveal", "clock")
	await settle()
	expect(
		game.ui.modal == "clue" and session.view.evidence.clock.public,
		"reveal preserves inspected evidence"
	)
	expect(first_action() == "Back to journal", "public evidence back action still first")
	await pad(JOY_BUTTON_B)
	expect(game.ui.modal == "journal", "B returns public evidence to journal")
	game.ui.journal.inspect_item("key")
	await settle()
	expect(first_action() == "Back to journal", "inheritance back action first")
	await pad(JOY_BUTTON_B)
	expect(game.ui.modal == "inheritance", "B returns item to inheritance tab")
	game.ui.conversation.open("keeper")
	await settle()
	var options: ScrollContainer = game.ui.conversation.options_box.get_parent()
	axis(JOY_AXIS_RIGHT_Y, 1.0)
	await create_timer(0.35).timeout
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	expect(options.scroll_vertical > 30, "right stick scrolls conversation actions")
	expect(
		root.gui_get_focus_owner() == options, "scrolled-away action cannot remain confirm target"
	)
	var motion_before = game.player.rotation.y
	axis(JOY_AXIS_RIGHT_X, -1.0)
	await settle()
	axis(JOY_AXIS_RIGHT_X, 0.0)
	await settle()
	var history: ScrollContainer = game.ui.conversation.history_box.get_parent()
	expect(
		root.gui_get_focus_owner() == history, "right-stick horizontal selects other reading panel"
	)
	expect(game.player.rotation.y == motion_before, "modal scrolling does not turn camera")
	for index in range(8):
		session.command("interact", {"target": "keeper", "choice": "topic:history"})
	await settle()
	history.scroll_vertical = 0
	history.grab_focus()
	axis(JOY_AXIS_RIGHT_Y, 1.0)
	await create_timer(0.35).timeout
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	expect(history.scroll_vertical > 30, "right stick scrolls long conversation history")
	axis(JOY_AXIS_RIGHT_Y, 1.0)
	history.scroll_vertical = 0
	game.ui.navigation.scroll_fraction = 0.0
	for step in range(100):
		game.ui.navigation.scroll(0.001)
	var high_refresh = history.scroll_vertical
	expect(absi(high_refresh - 90) <= 1, "subpixel scrolling survives 1000 FPS")
	history.scroll_vertical = 0
	game.ui.navigation.scroll_fraction = 0.0
	for step in range(6):
		game.ui.navigation.scroll(1.0 / 60.0)
	expect(
		absi(history.scroll_vertical - high_refresh) <= 1,
		"equal duration gives equal scroll at 60 and 1000 FPS"
	)
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	await capture("conversation")
	await pad(JOY_BUTTON_B)
	expect(game.ui.modal == "people", "B returns conversation to guest journal")
	game.ui.journal.estate()
	await settle()
	axis(JOY_AXIS_RIGHT_Y, 1.0)
	await create_timer(0.35).timeout
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	expect(game.ui.navigation.scroller.scroll_vertical > 30, "right stick scrolls estate schedule")
	await capture("schedule")
	game.ui.journal.open()
	var talk_key = InputEventKey.new()
	talk_key.physical_keycode = KEY_V
	talk_key.keycode = KEY_V
	talk_key.pressed = true
	Input.parse_input_event(talk_key)
	await settle()
	expect(controls.talk_allowed(), "keyboard V remains usable in the journal")
	talk_key.pressed = false
	Input.parse_input_event(talk_key)
	button(JOY_BUTTON_LEFT_SHOULDER, true)
	await settle()
	expect(not controls.talk_allowed(), "journal LB cannot start push-to-talk")
	game.ui.close()
	expect(not controls.talk_allowed(), "held journal LB remains suppressed after close")
	button(JOY_BUTTON_LEFT_SHOULDER, false)
	await settle()
	button(JOY_BUTTON_LEFT_SHOULDER, true)
	await settle()
	expect(controls.talk_allowed(), "fresh LB can speak outside journal")
	button(JOY_BUTTON_LEFT_SHOULDER, false)
	var voice = root.get_node("Voice")
	expect(
		not voice.enabled and voice.microphone.stream == null,
		"navigation never enables or captures microphone"
	)
	session.leave()
	game.queue_free()
	root.get_node("Music").shutdown()
	root.get_node("Sound").shutdown()
	await create_timer(0.2).timeout
	print("NAVIGATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
