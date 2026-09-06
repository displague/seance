class_name SeanceMenu
extends RefCounted

var ui
var chosen = "medium"
var room_mode = "solo"
var role_buttons: Dictionary = {}
var name_input: LineEdit
var address_input: LineEdit


func _init(owner_ui) -> void:
	ui = owner_ui


func build() -> void:
	UIK.clear(ui.menu_root)
	var shade = TextureRect.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.015, 0.028, 0.031, 0.97))
	gradient.set_color(1, Color(0.015, 0.028, 0.031, 0.05))
	gradient.add_point(0.43, Color(0.015, 0.028, 0.031, 0.72))
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0.9, 0)
	shade.texture = texture
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.menu_root.add_child(shade)
	UIK.fill(shade)
	var column = UIK.vbox(ui.menu_root, 8)
	column.position = Vector2(105, 95)
	column.size = Vector2(470, 710)
	var crest = TextureRect.new()
	crest.texture = load("res://assets/icon.svg")
	crest.custom_minimum_size = Vector2(54, 54)
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	crest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(crest)
	column.add_child(UIK.spacer(10))
	column.add_child(UIK.label("A N   A S H W O O D   M Y S T E R Y", 14, UIK.GOLD))
	column.add_child(UIK.label("SÉANCE", 112, UIK.CREAM, true))
	column.add_child(UIK.label("T H E   U N Q U I E T   W I L L", 17, UIK.GOLD))
	column.add_child(UIK.spacer(20))
	column.add_child(
		UIK.paragraph("The dead have a story.\nThe living have their reasons.", 23, UIK.CREAM)
	)
	column.add_child(UIK.spacer(22))
	column.add_child(UIK.button("ENTER ASHWOOD     →", func(): choose_role("solo"), true))
	column.add_child(UIK.spacer(3))
	column.add_child(UIK.button("Host a private circle", func(): choose_role("host")))
	column.add_child(UIK.button("Join a circle", func(): choose_role("join")))
	var extras = UIK.hbox(column, 10)
	var how = UIK.button("How to play", instructions)
	how.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extras.add_child(how)
	var settings = UIK.button("Settings", options)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extras.add_child(settings)
	column.add_child(UIK.spacer(10))
	column.add_child(UIK.label("SOLO REHEARSAL  /  PRIVATE MULTIPLAYER", 12, UIK.MUTED))
	var location = UIK.vbox(ui.menu_root, 5)
	location.position = Vector2(1240, 65)
	location.add_child(UIK.label("ASHWOOD MANOR", 16, UIK.GOLD))
	location.add_child(UIK.label("17 NOVEMBER 1937   ·   23:17", 12, UIK.MUTED))
	var quote = UIK.vbox(ui.menu_root, 10)
	quote.position = Vector2(1160, 714)
	quote.add_child(UIK.label("“Not everyone wants\nthe truth to come out.”", 27, UIK.CREAM, true))
	quote.add_child(UIK.label("CHAPTER I   /   THE INHERITANCE", 12, UIK.GOLD))
	var version = UIK.label("PROTOTYPE 0.1     •     HEADPHONES RECOMMENDED", 12, UIK.MUTED)
	version.position = Vector2(105, 859)
	ui.menu_root.add_child(version)
	var quit = UIK.button("Quit", func(): ui.get_tree().quit())
	quit.position = Vector2(1420, 830)
	quit.size = Vector2(90, 42)
	ui.menu_root.add_child(quit)


func choose_role(mode: String) -> void:
	room_mode = mode
	var body = ui.dialog("A place at the table", "CHOOSE YOUR CHARACTER", "role")
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Every guest has something to gain. And something to hide. Choose the Medium for your first visit.",
					19
				)
			)
		)
	)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	role_buttons.clear()
	for role in CaseData.ROLES:
		var data = CaseData.person(role)
		var card = UIK.button("", func(): _select(role))
		card.custom_minimum_size = Vector2(385, 185)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column = UIK.vbox(card, 8)
		column.position = Vector2(22, 16)
		column.size = Vector2(335, 154)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(UIK.label(data.title.to_upper(), 12, Color(data.color)))
		column.add_child(UIK.label(data.name, 28, UIK.CREAM, true))
		column.add_child(UIK.paragraph(data.bio, 16))
		grid.add_child(card)
		role_buttons[role] = card
	_select(chosen)
	if mode != "solo":
		var inputs = UIK.hbox(body)
		name_input = LineEdit.new()
		name_input.placeholder_text = "Your name"
		name_input.text = "Guest"
		name_input.max_length = 24
		name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inputs.add_child(name_input)
		if mode == "join":
			address_input = LineEdit.new()
			address_input.placeholder_text = "Host address (for example 192.168.1.20)"
			address_input.text = "127.0.0.1"
			address_input.max_length = 128
			address_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inputs.add_child(address_input)
		(
			body
			. add_child(
				(
					UIK
					. paragraph(
						"Six seats. Empty seats are filled by scripted characters. If your role is taken, the host assigns an available one. Direct connection • UDP 27877.",
						15
					)
				)
			)
		)
	else:
		(
			body
			. add_child(
				(
					UIK
					. paragraph(
						"A complete solo rehearsal with five scripted guests. No microphone required. An authored case; their loyalties will not change, but your choices can.",
						16
					)
				)
			)
		)
	body.add_child(
		(
			UIK
			. button(
				{
					"solo": "BEGIN THE REHEARSAL",
					"host": "OPEN THE CIRCLE",
					"join": "JOIN THE CIRCLE"
				}[mode],
				_enter,
				true
			)
		)
	)


func _select(role: String) -> void:
	chosen = role
	for key in role_buttons:
		role_buttons[key].add_theme_stylebox_override(
			"normal",
			UIK.style(
				Color("263632") if key == role else UIK.INK,
				UIK.GOLD if key == role else Color("34433e"),
				1
			)
		)


func _enter() -> void:
	if room_mode == "solo":
		ui.close()
		Session.solo(chosen)
	elif room_mode == "host":
		var error = Session.host(chosen, name_input.text)
		if error != OK:
			ui.toast("Could not open the circle. UDP port 27877 may already be in use.")
	else:
		var error = Session.join_room(address_input.text, chosen, name_input.text)
		if error != OK:
			ui.toast("The host address could not be reached.")
		else:
			var body = ui.dialog("Reaching beyond the veil…", "CONNECTING", "connecting")
			body.add_child(
				UIK.paragraph("Waiting for the host. This attempt will end after ten seconds.", 22)
			)
			body.add_child(UIK.button("Cancel", _cancel_connection))


func lobby() -> void:
	if Session.active:
		return
	var body = ui.dialog("The circle is gathering", "PRIVATE SITTING", "lobby")
	body.add_child(
		UIK.paragraph(
			"The host begins when everyone is ready. Unoccupied seats will be played by the house.",
			20
		)
	)
	for role in CaseData.ROLES:
		var occupant = "The house · scripted guest"
		for guest in Session.lobby.values():
			if guest.role == role:
				occupant = guest.name + (" · you" if role == Session.local_role else " · connected")
		var row = UIK.hbox(UIK.panel(body, UIK.INK, Color("33433d"), 15))
		var name = UIK.label(CaseData.person(role).title, 24, UIK.GOLD, true)
		name.custom_minimum_size.x = 330
		row.add_child(name)
		row.add_child(UIK.label(occupant, 18))
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Microphones start off. Enable voice after entering, then hold V to speak. Ghost speech is heard only through the game's permitted channels.",
					17
				)
			)
		)
	)
	if Session.hosting:
		body.add_child(UIK.button("BEGIN THE SITTING", _begin_host, true))
	else:
		body.add_child(UIK.label("Waiting for the host to begin…", 20, UIK.TEAL))
	body.add_child(UIK.button("Leave the circle", _cancel_connection))


func instructions() -> void:
	var body = ui.dialog("The living have their reasons", "HOW TO PLAY", "help")
	var scroller = UIK.scroll(body)
	var instructions_list = [
		[
			"01   Investigate",
			"Move with W A S D and look with the mouse. Hold Shift to walk faster. Aim at an object or guest and press E. F switches your lantern. Each clue belongs to its finder until they reveal, give, or destroy it."
		],
		[
			"02   Follow your motives",
			"Press J for your journal. Everyone has three objectives, worth 2, 3, and 5 points. Ritual preparations earn an additional point each, up to three. You can agree on the facts and still want different endings."
		],
		[
			"03   Speak for the dead",
			"C opens the circle. At a séance, the Medium hears the Ghost. Other guests hear the Medium's interpretation. Ghost players use G for signs and possession. A possessed guest keeps control, but can hear the Ghost for sixty seconds."
		],
		[
			"04   Prepare the threshold",
			"Tune the library radio, align the candles, and open the chapel reliquary. These are real puzzles with clues nearby. Complete at least two to make a peaceful release possible."
		],
		[
			"05   Seal a version of the truth",
			"After three sittings, every guest votes for a culprit, an heir, and a final rite. Majority decides each independently. Ties mean no conviction, Julian inherits, or banishment. The Ghost also votes. Individual scores decide the winner."
		],
		[
			"Voice and transcripts",
			"M enables or disables the microphone. Hold V to speak while enabled. T opens a text transcript with the same listening rules. No audio is recorded. In solo, conversations are authored dialogue, not live AI. Escape releases the mouse and opens the pause menu."
		]
	]
	for entry in instructions_list:
		scroller.add_child(UIK.label(entry[0], 28, UIK.GOLD, true))
		scroller.add_child(UIK.paragraph(entry[1], 19, UIK.CREAM))
		scroller.add_child(UIK.spacer(10))
	body.add_child(UIK.button("I understand", ui.close, true))


func options() -> void:
	var body = ui.dialog("Make yourself comfortable", "SETTINGS", "settings")
	body.add_child(UIK.label("Master volume", 23, UIK.GOLD, true))
	var volume = HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.01
	volume.value = Session.settings.volume
	volume.custom_minimum_size.y = 38
	volume.value_changed.connect(
		func(value):
			Session.settings.volume = value
			AudioServer.set_bus_volume_db(0, linear_to_db(value))
	)
	body.add_child(volume)
	body.add_child(UIK.label("Mouse sensitivity", 23, UIK.GOLD, true))
	var sensitivity = HSlider.new()
	sensitivity.min_value = 0.0008
	sensitivity.max_value = 0.005
	sensitivity.step = 0.0001
	sensitivity.value = Session.settings.sensitivity
	sensitivity.custom_minimum_size.y = 38
	sensitivity.value_changed.connect(func(value): Session.settings.sensitivity = value)
	body.add_child(sensitivity)
	var fullscreen = CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = Session.settings.fullscreen
	fullscreen.toggled.connect(
		func(value):
			Session.settings.fullscreen = value
			DisplayServer.window_set_mode(
				(
					DisplayServer.WINDOW_MODE_FULLSCREEN
					if value
					else DisplayServer.WINDOW_MODE_WINDOWED
				)
			)
	)
	body.add_child(fullscreen)
	var motion = CheckButton.new()
	motion.text = "Camera movement and head bob"
	motion.button_pressed = Session.settings.motion
	motion.toggled.connect(func(value): Session.settings.motion = value)
	body.add_child(motion)
	body.add_child(UIK.spacer(15))
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Microphone access is opt-in for every session. No speech is saved or sent to a cloud service. Local volume affects all sound, including other players.",
					18
				)
			)
		)
	)
	body.add_child(UIK.button("Save settings", _save_options, true))


func _cancel_connection() -> void:
	Session.leave()
	ui.close()


func _begin_host() -> void:
	ui.modal = ""
	ui.close()
	Session.start_host_game()


func _save_options() -> void:
	Session.save_settings()
	ui.close()
