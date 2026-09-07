extends SceneTree
## Cosmetic isolation, gamepad events, ghost lighting, haunting and real UI portraits.

var checks = 0
var failures: Array = []
var game: Node
var session: Node
var wardrobe: Node
var controls: Node


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAIL: ", message)


func settle() -> void:
	await process_frame
	await process_frame


func pad(button: int) -> void:
	var event = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/feature_" + label + ".png")


func run() -> void:
	session = root.get_node("Session")
	wardrobe = root.get_node("Wardrobe")
	controls = root.get_node("Controls")
	test_haunting()
	test_cosmetics()
	test_profile_storage()
	test_music()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.qa_mode = true
	await settle()
	game.ui.menu.choose_role("solo")
	await capture("roles")
	var wardrobe_ui = load("res://ui/wardrobe_menu.gd")
	wardrobe_ui.show(game.ui, "widow", game.ui.close)
	await settle()
	expect(game.ui.modal == "wardrobe", "wardrobe opens")
	await capture("wardrobe")
	await pad(JOY_BUTTON_B)
	expect(game.ui.modal == "", "controller back closes wardrobe")
	var focused = root.gui_get_focus_owner()
	await pad(JOY_BUTTON_DPAD_DOWN)
	expect(root.gui_get_focus_owner() != focused, "d-pad navigates menu focus")
	await pad(JOY_BUTTON_A)
	expect(game.ui.modal == "ai_setup", "south button activates newly focused Solo AI entry")
	await pad(JOY_BUTTON_B)
	game.ui.menu.options()
	await settle()
	expect(
		game.ui.overlay.find_children("*", "HSlider", true, false).size() == 5,
		"controller and music settings exposed"
	)
	await capture("settings")
	game.ui.close()
	session.solo("ghost")
	game.ui.close()
	await settle()
	expect(
		not game.player.lantern.visible and game.player.spirit_glow.visible,
		"ghost has glow and no lantern"
	)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	expect(not game.player.lantern.visible, "controller cannot give ghost a lantern")
	var origin: Vector3 = game.player.position
	var axis = InputEventJoypadMotion.new()
	axis.device = 0
	axis.axis = JOY_AXIS_LEFT_Y
	axis.axis_value = -0.7
	Input.parse_input_event(axis)
	await create_timer(0.3).timeout
	axis.axis_value = 0
	Input.parse_input_event(axis)
	expect(game.player.position.distance_to(origin) > 0.2, "analog stick moves character")
	var rotation_before = game.player.rotation.y
	axis = axis.duplicate()
	axis.axis = JOY_AXIS_RIGHT_X
	axis.axis_value = 0.8
	Input.parse_input_event(axis)
	await create_timer(0.2).timeout
	axis.axis_value = 0
	Input.parse_input_event(axis)
	expect(absf(game.player.rotation.y - rotation_before) > 0.1, "right stick turns camera")
	await pad(JOY_BUTTON_X)
	expect(game.ui.modal == "journal", "west button opens journal")
	await pad(JOY_BUTTON_B)
	var pause_button = (
		JOY_BUTTON_BACK if Input.get_joy_name(0).to_lower().contains("stadia") else JOY_BUTTON_START
	)
	await pad(pause_button)
	expect(game.ui.modal == "pause", "start pauses")
	await pad(JOY_BUTTON_B)
	expect(game.player.enabled, "back resumes player")
	session.command("weep", {"target": "Séance Parlour"})
	game.player.place(Vector3(4.5, 0, 5.5), false)
	game.player.camera.look_at(Vector3(4.7, 2.5, 8.81))
	await create_timer(2).timeout
	expect(
		game.manor.atmosphere.walls["Séance Parlour"].mesh.visible,
		"wall event rendered from snapshot"
	)
	await capture("weeping")
	session.settings.reduced_flashes = true
	session.rules.state.haunt.storm_id += 1
	session.rules.state.haunt.storm_age = 0
	session.publish()
	await settle()
	expect(
		is_equal_approx(game.manor.moon.light_energy, 0.65), "reduced flashes suppress lightning"
	)
	game.ui.show_menu()
	wardrobe.choices.doctor = {"outfit": "heritage", "brooch": "silver"}
	session.solo("doctor")
	await settle()
	expect(
		game.player.lantern.visible and not game.player.spirit_glow.visible,
		"living role restores lantern"
	)
	expect(
		game.characters.equipped.doctor == session.view.appearances.doctor,
		"world matches equipped snapshot"
	)
	game.ui.journal.people()
	await settle()
	var portraits = game.ui.overlay.find_children("*", "SubViewportContainer", true, false)
	expect(portraits.size() == 5, "guest list has five rendered avatar portraits")
	await capture("guests")
	game.ui.journal.talk("widow")
	await capture("details")
	expect(not root.get_node("Voice").enabled, "controller never auto-enables microphone")
	print(
		"DEVICES: ",
		Input.get_connected_joypads(),
		" AUDIO OUTPUTS: ",
		AudioServer.get_output_device_list()
	)
	session.leave()
	game.free()
	await settle()
	root.get_node("Music").shutdown()
	root.get_node("Sound").shutdown()
	await create_timer(0.15).timeout
	print("FEATURES: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func test_cosmetics() -> void:
	for role in CaseData.ROLES:
		expect(AppearanceData.model(role, {}) == "roster/" + role, "unique base model " + role)
		expect(
			AppearanceData.normalize(role, {"outfit": "../evil", "speed": 500}).size() == 2,
			"cosmetic fields allowlisted " + role
		)
	expect(
		AppearanceData.normalize("heir", {"outfit": "heritage"}).outfit == "ashwood",
		"outfit restricted to role"
	)
	expect(
		AppearanceData.normalize("medium", {"outfit": "heritage"}).outfit == "heritage",
		"alternate face allowed"
	)
	expect(wardrobe.equip("medium", {"brooch": "gold"}) != OK, "unearned cosmetic not equippable")
	var rules = GameRules.new()
	rules.reset()
	rules.state["sitting_id"] = "feature-test-award"
	rules.resolve()
	expect(
		wardrobe.award(rules.view_for("medium"), "medium"),
		"completed sitting awards story currency"
	)
	var balance = wardrobe.remembrance
	expect(
		not wardrobe.award(rules.view_for("medium"), "medium") and wardrobe.remembrance == balance,
		"duplicate snapshot cannot award twice"
	)
	wardrobe.remembrance = 60
	expect(
		wardrobe.unlock_gold() == OK and wardrobe.remembrance == 0,
		"earned currency unlock consumes exact price"
	)
	expect(
		wardrobe.unlock_gold() != OK and wardrobe.remembrance == 0,
		"cannot repurchase unlocked cosmetic"
	)
	expect(wardrobe.equip("medium", {"brooch": "gold"}) == OK, "earned cosmetic equippable")
	var before = rules.state.scores.duplicate(true)
	rules.state["appearances"] = AppearanceData.preferences(wardrobe.choices)
	expect(before == rules.state.scores, "cosmetics cannot change points")
	expect(not rules.view_for("ghost").has("remembrance"), "currency is not case state")


func test_profile_storage() -> void:
	var previous_path = wardrobe.profile_path
	wardrobe.profile_path = "res://artifacts/wardrobe-test.cfg"
	wardrobe.persistence = true
	expect(
		wardrobe.equip("medium", {"outfit": "heritage", "brooch": "silver"}) == OK,
		"profile saves per-role preference"
	)
	expect(
		wardrobe.equip("doctor", {"brooch": "silver"}) == OK, "profile can replace an existing file"
	)
	wardrobe.choices = AppearanceData.preferences({})
	wardrobe.load_profile()
	expect(
		wardrobe.choices.medium.outfit == "heritage" and wardrobe.choices.doctor.brooch == "silver",
		"profile reload preserves independent character choices"
	)
	wardrobe.profile_path = previous_path
	wardrobe.persistence = false


func test_haunting() -> void:
	var rules = GameRules.new()
	rules.reset(["ghost", "medium"])
	expect(rules.act("medium", "weep", {"target": "Library"}) != "", "living cannot forge haunting")
	expect(rules.act("ghost", "weep", {"target": "Unknown"}) != "", "invalid room rejected")
	expect(rules.act("ghost", "weep", {"target": "Library"}) == "", "ghost can weep walls")
	expect(rules.state.energy == 50, "haunting costs exact energy")
	expect(rules.act("ghost", "breeze", {"target": "Library"}) != "", "haunt cooldown enforced")
	expect(rules.act("medium", "calm", {"target": "Library"}) != "", "remote calming rejected")
	rules.state.positions.medium = Vector3(-12, 0, 0)
	expect(rules.act("medium", "calm", {"target": "Library"}) == "", "living can calm local room")
	expect(rules.state.haunt.kind == "", "calming clears outage")
	rules.tick(21)
	expect(
		rules.act("ghost", "breeze", {"target": "Library"}) == "",
		"haunting recovers after cooldown"
	)
	expect(
		rules.view_for("medium").haunt == rules.view_for("ghost").haunt,
		"public environmental snapshots agree"
	)
	rules.tick(17)
	expect(rules.state.haunt.kind == "", "haunting expires")
	expect(rules.state.haunt.storm_id == 1, "storm driven by authoritative clock")
	expect(not rules.can_hear("ghost", "medium"), "haunting does not unlock ghost audio")
	rules.state.phase = "judgment"
	expect(
		rules.act("ghost", "weep", {"target": "Library"}) != "", "no new haunting during judgment"
	)


func test_music() -> void:
	var music = root.get_node("Music")
	var investigation = music.targets({"phase": "investigation"}, true)
	var sitting = music.targets({"phase": "seance"}, true)
	expect(sitting.piano < investigation.piano, "score makes room for séance discussion")
	expect(sitting.tension > investigation.tension, "score adds séance tension")
	for stem in ["bed", "piano", "tension"]:
		var stream = load("res://assets/audio/" + stem + ".wav") as AudioStreamWAV
		expect(
			stream != null and is_equal_approx(stream.get_length(), 32),
			"aligned original music stem " + stem
		)
