extends SceneTree
## Timer boundaries, privacy, derived scoring and real persistent recap/results widgets.

var checks = 0
var failures = 0
var game: Node
var session: Node


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func pure_rules() -> void:
	var rules = GameRules.new()
	rules.reset(CaseData.ROLES)
	expect(
		rules.view_for("medium").phase_info.countdown == "UNTIL SÉANCE 1",
		"first timer names the next phase"
	)
	rules.state.positions.doctor = CaseData.CLUES.flowers.pos
	expect(rules.act("doctor", "collect", {"id": "flowers"}) == "", "private recovery succeeds")
	expect(rules.act("doctor", "destroy", {"id": "flowers"}) == "", "private destruction succeeds")
	rules.state.positions.medium = CaseData.CLUES.vial.pos
	rules.act("medium", "collect", {"id": "vial"})
	rules.act("medium", "reveal", {"id": "vial"})
	rules.act("medium", "reveal", {"id": "vial"})
	rules.state.positions.medium = Vector3(0, 0, -2.9)
	rules.act("medium", "task", {"id": "candles", "answer": CaseData.TASKS.candles.solution})
	expect(rules.state.activity.medium.revealed == 1, "failed action does not earn another award")
	var expected_phases = [
		"seance", "investigation", "seance", "investigation", "seance", "judgment", "ended"
	]
	for index in range(expected_phases.size()):
		rules.state.remaining = 0.01
		expect(rules.tick(0.02), "natural timer reports boundary %d" % index)
		expect(
			rules.state.phase == expected_phases[index],
			"timer follows three-sitting sequence %d" % index
		)
		var view = rules.view_for("keeper")
		expect(
			not view.has("activity") and not view.has("activity_baseline"),
			"activity counters not exposed %d" % index
		)
		if index == 0:
			expect(view.recap.rows.size() == 6, "phase recap includes every guest")
			expect(
				view.recap.rows[0].public_points == 2, "public objective progress comes from rules"
			)
			expect(
				view.recap.rows[0].preparation_points == 1, "preparation progress comes from rules"
			)
			expect(
				view.recap.rows[0].awards.size() == 2,
				"public reveal and preparation are recognized"
			)
			expect(
				view.recap.rows[3].awards.is_empty(),
				"secret recovery and destruction remain hidden"
			)
			expect(
				not str(view.recap).contains(CaseData.PEOPLE.doctor.goals[1]),
				"no hidden objective in recap"
			)
			expect(view.final_summary.is_empty(), "full scores withheld before dawn")
		if index == 1:
			expect(
				view.recap.rows[0].awards.is_empty(),
				"awards refer to this phase, not repeated cumulative activity"
			)
			expect(
				view.recap.rows[0].public_points == 2, "public progress persists across the case"
			)
	expect(rules.state.recaps.size() == 6, "exactly six completed phase recaps")
	expect(rules.state.final_summary.rows.size() == 6, "final ranking includes all guests")
	for row in rules.state.final_summary.rows:
		var total = row.bonus
		for goal in row.objectives:
			total += goal.earned
		expect(total == row.points, "breakdown exactly reconciles for " + row.role)
		expect(
			row.objectives.size() == 3, "all three objectives disclosed at ending for " + row.role
		)
		if row.role == "doctor":
			expect(row.awards.size() == 2, "secret achievements disclosed only at ending")
	var snapshot = rules.state.duplicate(true)
	expect(not rules.tick(10000), "ended game has no automatic timer transition")
	rules.advance()
	rules.resolve()
	expect(snapshot == rules.state, "ended scores and awards are stable on tick advance resolve")
	# Tied players share rank; ranking must not invent a unique winner.
	rules.state.scores = [
		{"role": "medium", "points": 5, "goals": [true, true, false], "bonus": 0},
		{"role": "heir", "points": 5, "goals": [true, true, false], "bonus": 0}
	]
	RoundSummary.final(rules)
	expect(
		rules.state.final_summary.rows[0].rank == 1 and rules.state.final_summary.rows[1].rank == 1,
		"tied winners share rank one"
	)


func settle() -> void:
	await process_frame
	await process_frame


func press(prefix: String) -> void:
	for button in game.ui.overlay.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text.begins_with(prefix):
			button.pressed.emit()
			await settle()
			return
	expect(false, "button found: " + prefix)


func text_visible() -> String:
	var text = ""
	for node in game.ui.overlay.find_children("*", "Label", true, false):
		if node.is_visible_in_tree():
			text += node.text + "\n"
	return text


func escape() -> void:
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/round-" + label + ".png")


func score_layout() -> void:
	var count = 0
	for button in game.ui.overlay.find_children("*", "Button", true, false):
		if not button.text.begins_with("#"):
			continue
		count += 1
		var parent = button.get_parent()
		while parent != null and not parent is ScrollContainer:
			parent = parent.get_parent()
		expect(
			parent != null and parent.get_global_rect().encloses(button.get_global_rect()),
			"score visible without scrolling: " + button.text
		)
	expect(count == 6, "six ranked score buttons rendered")
	var focused = root.gui_get_focus_owner()
	expect(focused != null and focused.is_visible_in_tree(), "final controller focus is visible")


func recap_layout() -> void:
	for role in CaseData.ROLES:
		var found = false
		for label in game.ui.overlay.find_children("*", "Label", true, false):
			if label.text != CaseData.person(role).name:
				continue
			var parent = label.get_parent()
			while parent != null and not parent is ScrollContainer:
				parent = parent.get_parent()
			found = parent != null and parent.get_global_rect().encloses(label.get_global_rect())
		expect(found, "public progress visible without scrolling: " + role)


func expire_phase() -> void:
	game.ui.close()
	session.rules.state.remaining = 0.01
	session.rules.tick(0.02)
	session.publish()
	await settle()


func rendered_ui() -> void:
	session = root.get_node("Session")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.qa_mode = true
	await settle()
	session.solo("medium")
	game.ui.close()
	session.rules.state.positions.medium = CaseData.CLUES.vial.pos
	session.command("collect", {"id": "vial"})
	session.command("reveal", {"id": "vial"})
	await expire_phase()
	expect(game.ui.modal == "recap", "first natural timer visibly opens a recap")
	expect(
		text_visible().contains("Investigation 1 of 3 complete"), "recap identifies finished phase"
	)
	expect(text_visible().contains("same case"), "recap explains this is not another game")
	expect(session.suspended, "solo recap pauses the next phase until ready")
	recap_layout()
	await capture("investigation")
	await press("JOIN SÉANCE 1")
	expect(game.ui.modal == "circle", "explicit continue opens sitting")
	expect(
		(
			game.ui.close_button.is_visible_in_tree()
			and game.ui.root.get_global_rect().encloses(game.ui.close_button.get_global_rect())
		),
		"circle close control stays on screen"
	)
	await capture("circle")
	await expire_phase()
	expect(
		game.ui.modal == "recap" and session.view.round == 2,
		"sitting end shows recap before investigation two"
	)
	await capture("sitting")
	await press("CONTINUE INVESTIGATION 2")
	expect(game.ui.modal == "" and not session.suspended, "continue restores exploration and timer")
	for index in range(4):
		await expire_phase()
	expect(
		session.view.phase == "judgment" and game.ui.modal == "recap",
		"last sitting explains final judgment before ballot"
	)
	await press("OPEN THE FINAL TESTAMENT")
	expect(game.ui.modal == "judgment", "explicit final testament action reaches ballot")
	await capture("judgment")
	await expire_phase()
	expect(
		session.view.phase == "ended" and game.ui.modal == "results",
		"natural dawn opens final results"
	)
	expect(
		text_visible().contains("No new game starts automatically"),
		"final screen explains persistence"
	)
	score_layout()
	await capture("results")
	await escape()
	expect(
		session.active and game.ui.modal == "results", "Escape cannot accidentally discard results"
	)
	game.ui.close()
	expect(game.ui.modal == "results", "generic close cannot discard results")
	session.rules.tick(10000)
	session.publish()
	await settle()
	expect(game.ui.modal == "results", "late snapshots leave the final screen visible")
	game.ui.results.details("medium")
	await settle()
	expect(text_visible().contains("ULTERIOR MOTIVE"), "full objective breakdown is readable")
	expect(
		text_visible().contains("Release Edmund's spirit"), "full scoring names the actual motive"
	)
	await capture("details")
	await escape()
	expect(
		session.active and game.ui.modal == "results", "Escape from details returns to all scores"
	)
	await press("LEAVE ASHWOOD")
	expect(
		not session.active and game.ui.menu_root.visible, "only explicit leave returns to main menu"
	)
	game.queue_free()


func run() -> void:
	pure_rules()
	await rendered_ui()
	root.get_node("Sound").shutdown()
	root.get_node("Music").shutdown()
	await create_timer(0.2).timeout
	print("ROUND SUMMARY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
