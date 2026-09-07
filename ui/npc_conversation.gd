class_name NpcConversation
extends RefCounted

var ui
var npc = ""
var history_box: VBoxContainer
var options_box: VBoxContainer
var input: LineEdit
var status_label: Label
var signature = ""


func _init(owner_ui) -> void:
	ui = owner_ui
	Session.changed.connect(refresh)
	Session.command_finished.connect(_completed)
	SoloAi.status_changed.connect(_status)
	NpcSpeech.status_changed.connect(_status)
	NpcSpeech.transcribed.connect(_transcribed)


func open(role: String) -> void:
	npc = role
	var body = ui.dialog(
		CaseData.person(npc).name,
		"CONVERSATION  /  " + CaseData.person(npc).title.to_upper(),
		"talk"
	)
	NpcSpeech.focus(npc)
	var heading = UIK.hbox(body, 18)
	AvatarPortrait.add(
		heading, npc, Session.view.get("appearances", {}).get(npc, {}), Vector2(100, 100)
	)
	var introduction = UIK.vbox(heading, 8)
	introduction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(
		introduction
		. add_child(
			(
				UIK
				. paragraph(
					"Questions open a conversation. Evidence can change a vote. Gifts and accepted bargains change who holds an object.",
					19,
					UIK.CREAM
				)
			)
		)
	)
	(
		introduction
		. add_child(
			(
				UIK
				. paragraph(
					"Conversations are private in this prototype. Only the Medium at a sitting, or a possessed vessel, can converse with Edmund.",
					15
				)
			)
		)
	)
	var columns = UIK.hbox(body, 20)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left = UIK.vbox(columns, 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size.x = 640
	history_box = UIK.scroll(left)
	var right = UIK.vbox(columns, 8)
	right.custom_minimum_size.x = 510
	right.add_child(UIK.label("WHAT YOU CAN DO", 13, UIK.GOLD))
	options_box = UIK.scroll(right)
	status_label = UIK.label("", 15, UIK.TEAL)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(status_label)
	if SoloAi.enabled and not Session.online:
		var row = UIK.hbox(body)
		input = LineEdit.new()
		input.placeholder_text = "Ask in your own words… or review your voice transcript here"
		input.max_length = 400
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.text_submitted.connect(func(_text): send())
		row.add_child(input)
		row.add_child(UIK.button("Send", send, true))
		var record_button = UIK.button("Hold to record", func(): pass)
		record_button.button_down.connect(NpcSpeech.start_capture)
		record_button.button_up.connect(func(): NpcSpeech.stop_capture(true))
		row.add_child(record_button)
		row.add_child(UIK.button("Cancel reply / voice", _cancel))
	else:
		input = null
		body.add_child(UIK.button("Read your transcript", ui.journal.transcript))
	signature = ""
	refresh()
	_status()


func refresh() -> void:
	if ui.modal != "talk" or not is_instance_valid(history_box) or not Session.active:
		return
	var data: Dictionary = Session.view.get("npc", {}).get(npc, {})
	if str(data) == signature:
		return
	signature = str(data)
	UIK.clear(history_box)
	UIK.clear(options_box)
	if data.get("blocked", "") != "":
		history_box.add_child(UIK.paragraph(data.blocked, 23, UIK.GOLD))
		if Session.view.humans.has(npc):
			options_box.add_child(UIK.button("Speak to the human player", ui.journal.transcript))
		return
	var history: Array = data.get("history", [])
	if history.is_empty():
		history_box.add_child(
			UIK.paragraph("They turn toward you. Where will you begin?", 25, UIK.CREAM)
		)
	for entry in history:
		history_box.add_child(
			UIK.label(CaseData.person(entry.speaker).name.to_upper(), 12, UIK.GOLD)
		)
		history_box.add_child(UIK.paragraph(entry.text, 20, UIK.CREAM))
	for option in data.get("options", []):
		var button = UIK.button(option.label, choose.bind(option.id))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 48
		options_box.add_child(button)
	var scroller = history_box.get_parent() as ScrollContainer
	scroller.set_deferred("scroll_vertical", 100000)


func choose(choice: String) -> void:
	SoloAi.cancel()
	Session.command("interact", {"target": npc, "choice": choice})


func _cancel() -> void:
	SoloAi.cancel()
	NpcSpeech.cancel()


func _completed(action: String, payload: Dictionary, error: String) -> void:
	if action != "interact" or payload.get("target", "") != npc or ui.modal != "talk":
		return
	refresh()
	if error != "":
		return
	var history: Array = Session.view.get("npc", {}).get(npc, {}).get("history", [])
	if not history.is_empty():
		NpcSpeech.say(npc, history.back().text)


func send() -> void:
	if not is_instance_valid(input) or input.text.strip_edges() == "" or SoloAi.busy:
		return
	SoloAi.ask(npc, input.text)
	input.clear()
	refresh()


func _transcribed(role: String, text: String) -> void:
	if role == npc and ui.modal == "talk" and is_instance_valid(input):
		input.text = text
		input.grab_focus()


func _status() -> void:
	if ui.modal != "talk" or not is_instance_valid(status_label):
		return
	status_label.text = (
		SoloAi.status + "\n" + NpcSpeech.status
		if SoloAi.enabled
		else "Authored social play · no language model required"
	)
