class_name SeanceSettings
extends RefCounted


static func show(ui) -> void:
	var body = ui.dialog("Make yourself comfortable", "SETTINGS", "settings")
	var page = UIK.scroll(body)
	_slider(
		page,
		"Master volume · includes voice",
		"volume",
		0,
		1,
		0.01,
		func(value): AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.00001)))
	)
	_slider(page, "Music volume · adaptive instrumental score", "music_volume", 0, 1, 0.01)
	_slider(page, "Mouse sensitivity", "sensitivity", 0.0008, 0.005, 0.0001)
	_slider(page, "Controller look speed", "pad_sensitivity", 0.5, 4, 0.1)
	_slider(page, "Controller stick deadzone", "pad_deadzone", 0.1, 0.4, 0.01)
	_toggle(page, "Controller rumble", "rumble", func(_value): Controls.stop_rumble())
	_toggle(page, "Camera movement and head bob", "motion")
	_toggle(page, "Reduced flashes · gradual lighting, no lightning pulse", "reduced_flashes")
	_toggle(page, "Blood on weeping walls · off uses spectral slime", "blood_effects")
	_toggle(
		page,
		"Fullscreen",
		"fullscreen",
		func(value):
			DisplayServer.window_set_mode(
				(
					DisplayServer.WINDOW_MODE_FULLSCREEN
					if value
					else DisplayServer.WINDOW_MODE_WINDOWED
				)
			)
	)
	page.add_child(UIK.label("Audio output · entire game mix", 23, UIK.GOLD, true))
	var outputs = AudioServer.get_output_device_list()
	var selector = OptionButton.new()
	for output in outputs:
		selector.add_item(output)
	selector.select(maxi(0, outputs.find(AudioServer.output_device)))
	selector.item_selected.connect(
		func(index):
			Session.settings.audio_output = outputs[index]
			AudioServer.output_device = outputs[index]
	)
	page.add_child(selector)
	var pads = Input.get_connected_joypads()
	var names: Array[String] = []
	for id in pads:
		names.append(Input.get_joy_name(id))
	(
		page
		. add_child(
			(
				UIK
				. paragraph(
					(
						"Detected controllers: "
						+ (", ".join(names) if not names.is_empty() else "none")
						+ "\nXbox / PlayStation / Stadia: left stick move; right stick look; south button interact; west journal; north circle; Start pause; B/Circle back. D-pad: up spirit, down transcript, left opt-in mic, right lantern. Hold LB/L1 to talk; press left stick to sprint."
					),
					17
				)
			)
		)
	)
	(
		page
		. add_child(
			(
				UIK
				. paragraph(
					"Headphones protect private ghost speech. Controller/headset audio is available only if Windows lists an output above. This changes the entire mix; dedicated controller-speaker and adaptive-trigger APIs are not implemented. Rumble depends on the controller and driver. Microphones stay opt-in each session.",
					17
				)
			)
		)
	)
	body.add_child(
		UIK.button(
			"Save settings",
			func():
				Session.save_settings()
				ui.close(),
			true
		)
	)


static func _slider(
	parent: Node,
	title: String,
	key: String,
	minimum: float,
	maximum: float,
	step: float,
	changed: Callable = Callable()
) -> void:
	parent.add_child(UIK.label(title, 23, UIK.GOLD, true))
	var slider = HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(Session.settings[key])
	slider.custom_minimum_size.y = 38
	slider.value_changed.connect(
		func(value):
			Session.settings[key] = value
			if changed.is_valid():
				changed.call(value)
	)
	parent.add_child(slider)


static func _toggle(
	parent: Node, title: String, key: String, changed: Callable = Callable()
) -> void:
	var toggle = CheckButton.new()
	toggle.text = title
	toggle.button_pressed = Session.settings[key]
	toggle.toggled.connect(
		func(value):
			Session.settings[key] = value
			if changed.is_valid():
				changed.call(value)
	)
	parent.add_child(toggle)
