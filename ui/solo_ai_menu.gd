class_name SoloAiMenu
extends RefCounted


static func show(ui) -> void:
	var body = ui.dialog(
		"Give the house a voice", "SOLO WITH LOCAL AI  /  EXPERIMENTAL", "ai_setup"
	)
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Live, character-specific conversation using your local LM Studio model. The same evidence, trade, possession and voting rules apply. No cloud service or Python runtime.",
					22,
					UIK.CREAM
				)
			)
		)
	)
	var row = UIK.hbox(body)
	var endpoint = LineEdit.new()
	endpoint.text = SoloAi.base_url
	endpoint.placeholder_text = "http://127.0.0.1:1234/v1"
	endpoint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(endpoint)
	row.add_child(UIK.button("Check local models", _probe.bind(endpoint)))
	var models = OptionButton.new()
	models.custom_minimum_size.y = 52
	body.add_child(models)
	var status = UIK.paragraph(SoloAi.status, 18, UIK.TEAL)
	body.add_child(status)
	var refresh = func():
		if not is_instance_valid(models) or not is_instance_valid(status):
			return
		models.clear()
		for id in SoloAi.models:
			models.add_item(id)
		if not SoloAi.models.is_empty():
			models.select(maxi(0, SoloAi.models.find(SoloAi.model)))
		status.text = SoloAi.status
	SoloAi.status_changed.connect(refresh)
	models.tree_exiting.connect(_disconnect.bind(refresh))
	models.item_selected.connect(func(index): SoloAi.model = SoloAi.models[index])
	var out_toggle = CheckButton.new()
	out_toggle.text = "Speak NPC replies · six native Piper voices (optional helper files)"
	out_toggle.button_pressed = NpcSpeech.voice_out
	out_toggle.toggled.connect(NpcSpeech.set_voice_out)
	body.add_child(out_toggle)
	var in_toggle = CheckButton.new()
	in_toggle.text = "Enable push-to-talk · local whisper.cpp · review transcript before sending"
	in_toggle.button_pressed = NpcSpeech.voice_in
	in_toggle.toggled.connect(NpcSpeech.set_voice_in)
	body.add_child(in_toggle)
	var devices = OptionButton.new()
	var inputs = AudioServer.get_input_device_list()
	for device in inputs:
		devices.add_item(device)
	if not inputs.is_empty():
		devices.select(maxi(0, inputs.find(AudioServer.input_device)))
	devices.item_selected.connect(func(index): AudioServer.input_device = inputs[index])
	body.add_child(UIK.label("Microphone device · no capture until you hold Record / V / LB", 16))
	body.add_child(devices)
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Recommended here: LFM2.5-2.6B or Granite 4.1-3B. Voice setup: tools/setup-solo-ai.ps1 -InstallVoice -Start. Models and voice helpers are not bundled with the game. AI dialogue is fallible; recovered documents remain the evidence.",
					17
				)
			)
		)
	)
	body.add_child(
		UIK.button(
			"CHOOSE YOUR CHARACTER     →",
			func():
				SoloAi.base_url = endpoint.text.strip_edges().trim_suffix("/")
				if not SoloAi.local_url(SoloAi.base_url) or not SoloAi.models.has(SoloAi.model):
					ui.toast("Check the local server, then select an available model first.")
					return
				SoloAi.save()
				ui.menu.choose_role("ai"),
			true
		)
	)
	refresh.call()
	SoloAi.probe()


static func _probe(endpoint: LineEdit) -> void:
	SoloAi.base_url = endpoint.text.strip_edges().trim_suffix("/")
	SoloAi.probe()


static func _disconnect(callback: Callable) -> void:
	if SoloAi.status_changed.is_connected(callback):
		SoloAi.status_changed.disconnect(callback)
