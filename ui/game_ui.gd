class_name SeanceUI
extends CanvasLayer

signal blocked(value: bool)
signal return_to_menu

var root: Control
var menu_root: Control
var hud_root: Control
var overlay: Control
var toast_label: Label
var toast_time = 0.0
var modal = ""
var menu
var journal
var rituals
var conversation
var results
var room_label: Label
var phase_label: Label
var time_label: Label
var role_label: Label
var prompt_label: Label
var objective_label: Label
var mic_label: Label
var status_label: Label
var feed_label: Label
var screen_film: ColorRect
var last_log_signature = ""
var selected_clue = ""
var phase_seen = ""
var close_button: Button
var bottom_hint: Label
var target_id = ""
var navigation: ModalNavigation


func _ready() -> void:
	root = Control.new()
	root.theme = UIK.make_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	UIK.fill(root)
	screen_film = ColorRect.new()
	screen_film.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var film = ShaderMaterial.new()
	film.shader = load("res://shaders/film.gdshader")
	screen_film.material = film
	root.add_child(screen_film)
	UIK.fill(screen_film)
	menu_root = Control.new()
	root.add_child(menu_root)
	UIK.fill(menu_root)
	hud_root = Control.new()
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_root)
	UIK.fill(hud_root)
	hud_root.hide()
	overlay = Control.new()
	root.add_child(overlay)
	UIK.fill(overlay)
	overlay.hide()
	toast_label = UIK.label("", 19, UIK.CREAM)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.position = Vector2(430, 835)
	toast_label.size = Vector2(740, 52)
	toast_label.add_theme_stylebox_override(
		"normal", UIK.style(Color(0.035, 0.065, 0.068, 0.96), UIK.GOLD)
	)
	root.add_child(toast_label)
	toast_label.hide()
	menu = SeanceMenu.new(self)
	journal = SeanceJournal.new(self)
	rituals = SeanceRituals.new(self)
	conversation = NpcConversation.new(self)
	results = SeanceResults.new(self)
	navigation = ModalNavigation.new(self)
	menu.build()
	_build_hud()
	Controls.device_changed.connect(_controller_focus)
	Controls.focus_first.call_deferred(menu_root)
	Session.notice.connect(toast)
	Session.lobby_changed.connect(menu.lobby)
	Session.changed.connect(_sync)
	Session.started.connect(_start)
	Session.connection_lost.connect(
		func():
			close()
			show_menu()
	)


func dialog(
	title: String, eyebrow: String = "ASHWOOD MANOR", kind: String = "dialog"
) -> VBoxContainer:
	navigation.reset()
	if kind != "talk":
		SoloAi.cancel()
		NpcSpeech.focus("")
	UIK.clear(overlay)
	modal = kind
	overlay.show()
	blocked.emit(true)
	var shade = ColorRect.new()
	shade.color = Color(0.01, 0.018, 0.022, 0.82)
	overlay.add_child(shade)
	UIK.fill(shade)
	var panel = UIK.panel(overlay, Color(0.054, 0.088, 0.096, 0.99), Color("736449"), 34)
	panel.position = Vector2(145, 73)
	panel.size = Vector2(1310, 754)
	var outer = UIK.vbox(panel, 13)
	var top = UIK.hbox(outer)
	var titles = UIK.vbox(top, 5)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UIK.label(eyebrow, 12, UIK.GOLD))
	titles.add_child(UIK.label(title, 43, UIK.CREAM, true))
	close_button = UIK.button("×  CLOSE", navigation.back)
	close_button.custom_minimum_size = Vector2(118, 42)
	top.add_child(close_button)
	_focus_close.call_deferred()
	outer.add_child(UIK.line())
	var body = UIK.vbox(outer, 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return body


func close() -> void:
	if Session.active and Session.view.get("phase", "") == "ended":
		if modal != "results":
			results.summary()
		return
	SoloAi.cancel()
	NpcSpeech.focus("")
	navigation.reset()
	if modal == "lobby" or modal == "connecting":
		Session.leave()
	modal = ""
	overlay.hide()
	UIK.clear(overlay)
	if not Session.active:
		Controls.focus_first.call_deferred(menu_root)
	blocked.emit(not Session.active or Session.view.get("phase", "") == "ended")


func _focus_close() -> void:
	if modal != "" and is_instance_valid(close_button) and close_button.is_visible_in_tree():
		close_button.grab_focus()


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.show()
	toast_time = 5


func show_menu() -> void:
	navigation.reset()
	Voice.stop()
	Session.leave()
	modal = ""
	overlay.hide()
	menu_root.show()
	hud_root.hide()
	phase_seen = ""
	toast_time = 0
	toast_label.hide()
	screen_film.material.set_shader_parameter("ghost_view", 0.0)
	blocked.emit(true)
	return_to_menu.emit()
	Controls.focus_first.call_deferred(menu_root)


func _start() -> void:
	toast_time = 0
	toast_label.hide()
	menu_root.hide()
	hud_root.show()
	phase_seen = "investigation"
	_sync()
	journal.dossier()


func _build_hud() -> void:
	var left = UIK.vbox(hud_root, 2)
	left.position = Vector2(42, 30)
	left.add_child(UIK.label("A S H W O O D   M A N O R", 12, UIK.GOLD))
	room_label = UIK.label("Séance Parlour", 34, UIK.CREAM, true)
	left.add_child(room_label)
	var center = UIK.vbox(hud_root, 3)
	center.position = Vector2(555, 25)
	center.size.x = 490
	phase_label = UIK.label("I   ·   INVESTIGATION", 14, UIK.GOLD)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(phase_label)
	time_label = UIK.label("05:00", 30, UIK.CREAM, true)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(time_label)
	var right = UIK.vbox(hud_root, 3)
	right.position = Vector2(1195, 30)
	right.size.x = 360
	role_label = UIK.label("VIVIENNE CROSS", 16, UIK.CREAM)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(role_label)
	mic_label = UIK.label("MICROPHONE OFF  ·  M TO ENABLE", 12, UIK.MUTED)
	mic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(mic_label)
	objective_label = UIK.paragraph("", 16, UIK.CREAM)
	objective_label.position = Vector2(1240, 150)
	objective_label.size = Vector2(300, 125)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_root.add_child(objective_label)
	var crosshair = UIK.label("·", 34, Color(0.93, 0.91, 0.81, 0.75))
	crosshair.position = Vector2(792, 429)
	hud_root.add_child(crosshair)
	prompt_label = UIK.label("", 20, UIK.CREAM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(420, 655)
	prompt_label.size = Vector2(760, 80)
	hud_root.add_child(prompt_label)
	feed_label = UIK.paragraph("", 15, UIK.MUTED)
	feed_label.position = Vector2(42, 675)
	feed_label.size = Vector2(340, 113)
	hud_root.add_child(feed_label)
	bottom_hint = UIK.label(
		"W A S D  MOVE     E  INTERACT     J  JOURNAL     C  CIRCLE     T  TRANSCRIPT",
		13,
		UIK.MUTED
	)
	bottom_hint.position = Vector2(42, 850)
	hud_root.add_child(bottom_hint)
	status_label = UIK.label("F  LANTERN    ESC  PAUSE", 13, UIK.GOLD)
	status_label.position = Vector2(1175, 850)
	hud_root.add_child(status_label)


func update_room(pos: Vector3) -> void:
	room_label.text = CaseData.room_at(pos)


func set_target(id: String) -> void:
	target_id = id
	var key = "[ " + Controls.prompt("interact") + " ]  "
	if id == "":
		prompt_label.text = ""
	elif id.begins_with("haunt:"):
		prompt_label.text = key + "EXAMINE THE COLD SPOT"
	elif id.begins_with("person:"):
		prompt_label.text = key + "SPEAK TO\n" + CaseData.person(id.trim_prefix("person:")).name
	else:
		var data = CaseData.object_data(id)
		var status = "PREPARE" if CaseData.TASKS.has(id) else "INSPECT"
		if Session.view.get("chapter", {}).get("locked", {}).has(id):
			status = "SEALED · SEE SCHEDULE"
		elif CaseData.TASKS.has(id) and Session.view.get("tasks", {}).get(id, "") != "":
			status = "PREPARATION COMPLETE"
		prompt_label.text = (key + status + "\n" + str(data.get("name", "")))


func _sync() -> void:
	if not Session.active or Session.view.is_empty():
		return
	var view = Session.view
	var role = Session.local_role
	phase_label.text = view.phase_info.label
	var seconds = int(ceil(view.remaining))
	time_label.text = "%02d:%02d\n%s" % [seconds / 60, seconds % 60, view.phase_info.countdown]
	time_label.add_theme_font_size_override("font_size", 21)
	role_label.text = CaseData.person(role).name.to_upper() + "  /  " + CaseData.person(role).title
	objective_label.text = (
		"YOUR PUBLIC OBJECTIVE\n"
		+ CaseData.person(role).goals[0]
		+ "\n\n"
		+ str(view.prepared)
		+ " / 3  RITUAL PREPARATIONS"
	)
	if role == "ghost":
		objective_label.text = (
			"SPIRIT ENERGY  "
			+ str(int(view.energy))
			+ "\n\nG  MANIFEST & POSSESS\nOnly the Medium hears your voice during a sitting."
		)
	if view.possessed:
		objective_label.text += "\n\nPOSSESSED · You can hear Edmund."
	if view.silenced == role:
		objective_label.text += "\n\nSILENCED · Only Edmund hears you."
	screen_film.material.set_shader_parameter(
		"ghost_view", 1.0 if role == "ghost" or view.possessed else 0.0
	)
	if str(view.journal) != last_log_signature:
		last_log_signature = str(view.journal)
		feed_label.text = "\n\n".join(view.journal.slice(maxi(0, view.journal.size() - 2)))
	if view.phase != phase_seen:
		phase_seen = view.phase
		Sound.play("ritual", -4)
		match view.phase:
			"seance", "judgment", "investigation":
				results.recap()
			"ended":
				rituals.results()


func _process(delta: float) -> void:
	if navigation != null:
		navigation.scroll(delta)
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0:
			toast_label.hide()
	if Session.active:
		if Session.view.phase == "ended":
			bottom_hint.text = "CASE COMPLETE  ·  SELECT A GUEST TO REVIEW THEIR OBJECTIVES"
			status_label.text = "FINAL SCORES & AWARDS"
			return
		status_label.text = (
			"SPIRIT GLOW    ESC  PAUSE"
			if Session.local_role == "ghost"
			else "F  LANTERN    ESC  PAUSE"
		)
		bottom_hint.text = "W A S D  MOVE     E  INTERACT     J  JOURNAL     C  CIRCLE     T  TRANSCRIPT"
		if Controls.using_pad:
			bottom_hint.text = (
				"LS MOVE   RS LOOK   %s INTERACT   %s JOURNAL   %s CIRCLE"
				% [
					Controls.prompt("interact"),
					Controls.prompt("journal"),
					Controls.prompt("circle")
				]
			)
			status_label.text = "DPAD: ABILITIES    " + Controls.pause_prompt() + ": PAUSE"
		if not Session.online and SoloAi.enabled:
			mic_label.text = (
				"SOLO MIC READY · TALK TO A GUEST"
				if NpcSpeech.voice_in
				else "SOLO MIC OFF · M TO ENABLE"
			)
			mic_label.modulate = UIK.TEAL if NpcSpeech.voice_in else UIK.MUTED
		elif Voice.enabled:
			mic_label.text = (
				"● TRANSMITTING"
				if Voice.transmitting
				else "VOICE READY  ·  HOLD " + Controls.prompt("talk") + " TO SPEAK"
			)
			mic_label.modulate = UIK.TEAL
			if Controls.tab_navigation and Controls.using_pad and not Voice.transmitting:
				mic_label.text = "LB / L1: JOURNAL TABS  ·  V: VOICE"
		else:
			mic_label.text = "MICROPHONE OFF  ·  M TO ENABLE"
			if Controls.using_pad:
				mic_label.text = "MIC OFF  ·  DPAD LEFT TO ENABLE"
			mic_label.modulate = UIK.MUTED


func _input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton or not event.pressed:
		return
	# These reserved events may be consumed before the autoload sees _input.
	Controls.note_device(event)
	var shortcut = Controls.menu_action(event.button_index, Input.get_joy_name(event.device))
	if shortcut != "":
		# Reserve menu buttons before a focused widget can interpret ui_accept.
		if Session.active and Session.view.phase != "ended":
			if shortcut == "journal":
				journal.open()
			elif modal == "pause":
				close()
			else:
				pause_menu()
		get_viewport().set_input_as_handled()
	elif event.button_index == JOY_BUTTON_B:
		_unhandled_input(event)
	elif event.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		var direction = -1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1
		if navigation.shift_tab(direction):
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause") or event.is_action_pressed("ui_cancel"):
		if modal != "":
			if Session.active and Session.view.phase == "ended":
				if modal == "results_detail":
					results.summary()
				else:
					toast("The case is complete. Choose Leave Ashwood when you are ready.")
			else:
				navigation.back()
		elif Session.active:
			pause_menu()
		get_viewport().set_input_as_handled()
		return
	if not Session.active or modal != "":
		return
	if event.is_action_pressed("game_journal"):
		journal.open()
	elif event.is_action_pressed("game_circle"):
		rituals.circle()
	elif event.is_action_pressed("game_spirit"):
		rituals.spirit()
	elif event.is_action_pressed("game_transcript"):
		journal.transcript()
	elif event.is_action_pressed("game_microphone"):
		if not Session.online and SoloAi.enabled:
			NpcSpeech.set_voice_in(not NpcSpeech.voice_in)
			toast(NpcSpeech.status)
			return
		Voice.set_enabled(not Voice.enabled)
		toast(
			(
				"Microphone enabled. Hold " + Controls.prompt("talk") + " to speak."
				if Voice.enabled
				else "Microphone disabled."
			)
		)


func _controller_focus() -> void:
	set_target(target_id)
	if Controls.using_pad and get_viewport().gui_get_focus_owner() == null:
		Controls.focus_first(overlay if modal != "" else menu_root)


func _exit_tree() -> void:
	Controls.tab_navigation = false


func pause_menu() -> void:
	var body = dialog(
		"A moment of silence", "PAUSED" if not Session.online else "THE CIRCLE CONTINUES", "pause"
	)
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					(
						"Review your notes. Take a breath. The house can wait."
						if not Session.online
						else "Other guests remain in the sitting. The host's clock continues while this menu is open."
					),
					23
				)
			)
		)
	)
	body.add_child(UIK.spacer(20))
	body.add_child(UIK.button("Return to the manor", close, true))
	body.add_child(UIK.button("Your journal", journal.open))
	body.add_child(UIK.button("Settings", menu.options))
	body.add_child(UIK.button("How to play", menu.instructions))
	body.add_child(UIK.button("Leave this sitting", confirm_leave))


func confirm_leave() -> void:
	var body = dialog("Leave the house?", "END THIS SITTING", "confirm")
	body.add_child(
		UIK.paragraph(
			"This sitting is not saved. Leaving as host will disconnect the other guests.", 25
		)
	)
	body.add_child(UIK.button("Stay", close, true))
	body.add_child(UIK.button("Leave the sitting", show_menu))
