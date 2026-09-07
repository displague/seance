extends Node3D
## Composition root: presentation follows Session snapshots, never owns outcomes.

var manor: AshwoodManor
var player: SeancePlayer
var characters: SeanceCharacters
var ui: SeanceUI
var menu_camera: Camera3D
var time = 0.0
var last_phase = ""
var last_manifest = 0
var capture_clock = 0.0
var capture_stage = 0
var capture_mode = false
var qa_mode = false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	manor = AshwoodManor.new()
	add_child(manor)
	characters = SeanceCharacters.new()
	add_child(characters)
	player = SeancePlayer.new()
	add_child(player)
	player.position = Vector3(0, 0.1, 6.0)
	menu_camera = Camera3D.new()
	menu_camera.position = Vector3(-3.8, 3.15, 7.8)
	menu_camera.fov = 65
	add_child(menu_camera)
	menu_camera.look_at(Vector3(0.7, 1.4, -2))
	menu_camera.make_current()
	ui = SeanceUI.new()
	add_child(ui)
	ui.blocked.connect(_set_blocked)
	ui.return_to_menu.connect(_menu)
	player.interacted.connect(func(id): ui.journal.inspect(id, true))
	player.target_changed.connect(ui.set_target)
	Session.started.connect(_start)
	Session.changed.connect(_sync)
	get_window().focus_exited.connect(_focus_lost)
	if Session.settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	qa_mode = OS.get_cmdline_user_args().has("--qa")
	if capture_mode:
		DisplayServer.window_set_size(Vector2i(1440, 810))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Sound.request_quit()


func _start() -> void:
	player.configure_role(Session.local_role)
	player.camera.make_current()
	player.place(Session.view.positions[Session.local_role])
	last_phase = Session.view.phase
	last_manifest = 0
	_set_blocked(ui.modal != "")
	_sync()


func _menu() -> void:
	last_phase = ""
	menu_camera.make_current()
	player.set_control(false)
	Session.suspended = false
	characters.sync({})
	for role in characters.figures:
		characters.figures[role].target = CaseData.SEATS[role] * 1.22
	var temporary = GameRules.new()
	temporary.reset()
	manor.sync(temporary.view_for("medium"))


func _set_blocked(value: bool) -> void:
	player.set_control(Session.active and not value)
	Session.suspended = value and not Session.online


func _sync() -> void:
	if not Session.active:
		return
	var view = Session.view
	if Wardrobe.award(view, Session.local_role):
		ui.toast("+%d REMEMBRANCE · Choose earned cosmetics in the wardrobe." % Wardrobe.last_award)
	manor.sync(view)
	characters.sync(view)
	if view.phase != last_phase:
		last_phase = view.phase
		if view.phase in ["seance", "judgment"]:
			player.place(view.positions[Session.local_role])
	if view.manifest != last_manifest:
		last_manifest = view.manifest
		Sound.play("knock", -3)
		ui.toast("THE SPIRIT ANSWERS:  " + view.manifest_word)
	ui.journal.refresh_transcript()
	ui.rituals.refresh_ballot()


func _focus_lost() -> void:
	if Session.active and ui.modal == "" and not capture_mode and not qa_mode:
		ui.pause_menu()


func _process(delta: float) -> void:
	time += delta
	if not Session.active and Session.settings.motion:
		menu_camera.position.x = -3.8 + sin(time * 0.08) * 0.24
		menu_camera.look_at(Vector3(0.7, 1.4, -2))
	if Session.active:
		ui.update_room(player.position)
	if capture_mode:
		_capture_run(delta)


func _capture_run(delta: float) -> void:
	# A reproducible native-render smoke tour, never part of ordinary gameplay.
	# Captures the actual viewport; it does not fabricate screenshots.
	capture_clock += delta
	if capture_clock < 4:
		return
	capture_clock = 0
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var path = "res://artifacts/capture_%02d.png" % capture_stage
	image.save_png(path)
	print("CAPTURE: " + path)
	capture_stage += 1
	match capture_stage:
		1:
			ui.menu.choose_role("solo")
		2:
			ui.close()
			Session.solo("medium")
		3:
			ui.close()
			player.set_control(false)
			Session.suspended = true
		4:
			player.place(Vector3(-11.8, 0, -0.5), false)
			player.rotation.y = 0
			player.camera.rotation.x = -0.2
		5:
			ui.journal.inspect("will", true)
		6:
			ui.close()
			Session.rules.state.positions.medium = CaseData.CLUES.clock.pos
			Session.command("collect", {"id": "clock"})
			ui.journal.inspect("clock")
		7:
			ui.close()
			Session.advance()
		8:
			ui.close()
			player.set_control(false)
			Session.suspended = true
		9:
			ui.journal.open()
		10:
			get_tree().quit()
