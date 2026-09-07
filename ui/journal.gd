class_name SeanceJournal
extends RefCounted

var ui
var transcript_box: VBoxContainer
var transcript_input: LineEdit
var last_message_signature = ""
var pending_collect = ""


func _init(owner_ui) -> void:
	ui = owner_ui
	Session.command_finished.connect(_command_finished)


func _tabs(body: VBoxContainer, selected: String) -> void:
	var row = UIK.hbox(body, 10)
	for entry in [
		["Evidence", open],
		["Inheritance", inheritance],
		["Your motives", dossier],
		["The guests", people],
		["Estate guide", estate],
		["Transcript", transcript]
	]:
		var button = UIK.button(entry[0], entry[1], entry[0] == selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)


func dossier() -> void:
	var role = Session.local_role
	var data = CaseData.person(role)
	var body = ui.dialog(data.name, "PRIVATE DOSSIER  /  " + data.title.to_upper(), "dossier")
	_tabs(body, "Your motives")
	var columns = UIK.hbox(body, 35)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left = UIK.vbox(columns, 18)
	left.custom_minimum_size.x = 425
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(UIK.label("You were invited for a reason.", 29, UIK.GOLD, true))
	left.add_child(UIK.paragraph(data.bio, 22, UIK.CREAM))
	left.add_child(UIK.line())
	left.add_child(UIK.label("WHAT YOU HAVE NOT TOLD THEM", 12, UIK.GOLD))
	left.add_child(UIK.paragraph(data.secret, 20))
	left.add_child(UIK.label("A RUMOR YOU HEARD", 12, UIK.GOLD))
	left.add_child(UIK.paragraph(data.rumor, 19, UIK.CREAM))
	var right = UIK.vbox(columns, 14)
	right.custom_minimum_size.x = 600
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(3):
		var card = UIK.panel(right, UIK.INK, Color("455147"), 20)
		var content = UIK.vbox(card, 8)
		var complete = Session.view.get("goals", [false, false, false])[i]
		content.add_child(
			UIK.label(
				(
					["PUBLIC OBJECTIVE", "PRIVATE OBJECTIVE", "ULTERIOR MOTIVE"][i]
					+ "   ·   "
					+ str([2, 3, 5][i])
					+ " POINTS"
				),
				12,
				UIK.TEAL if complete else UIK.GOLD
			)
		)
		content.add_child(UIK.paragraph(("✓  " if complete else "") + data.goals[i], 24, UIK.CREAM))
	(
		right
		. add_child(
			(
				UIK
				. paragraph(
					"A completed preparation earns 1 additional point, up to 3. Inheritance and ending objectives are scored from the final outcome.",
					16
				)
			)
		)
	)
	body.add_child(UIK.button("STEP INSIDE     →", ui.close, true))


func open() -> void:
	var body = ui.dialog("What the house remembers", "YOUR JOURNAL", "journal")
	_tabs(body, "Evidence")
	var list = UIK.scroll(body)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	list.add_child(grid)
	for id in CaseData.CLUES:
		var data = CaseData.CLUES[id]
		var evidence = Session.view.evidence[id]
		var known = evidence.public or evidence.holder == Session.local_role
		var text = data.name if known else "Unexamined · " + data.room
		var state_text = (
			"PUBLIC TESTIMONY"
			if evidence.public
			else (
				"IN YOUR KEEPING" if evidence.holder == Session.local_role else "SEARCH THE ESTATE"
			)
		)
		if evidence.destroyed and known:
			state_text = "DESTROYED"
		var button = UIK.button("", func(): inspect(id))
		button.custom_minimum_size = Vector2(590, 110)
		var content = UIK.vbox(button, 7)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.position = Vector2(20, 13)
		content.size = Vector2(550, 84)
		content.add_child(UIK.label(state_text, 11, UIK.TEAL if evidence.public else UIK.GOLD))
		content.add_child(UIK.label(text, 26, UIK.CREAM, true))
		content.add_child(
			UIK.label(data.tag if known else "A piece of someone else's story.", 13, UIK.MUTED)
		)
		grid.add_child(button)
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Evidence stays private until you reveal it. Public evidence influences the house's final votes. Hidden evidence may be given away or destroyed.",
					16
				)
			)
		)
	)


func inspect(id: String, in_world: bool = false) -> void:
	if id.begins_with("haunt:"):
		var room = id.trim_prefix("haunt:")
		var body = ui.dialog("The house is weeping", room.to_upper(), "cold_spot")
		(
			body
			. add_child(
				(
					UIK
					. paragraph(
						"A cold spot has smothered the lamps. It is a sign, not proof of guilt. A living guest in this room can steady the lamps; the cold also fades on its own.",
						24
					)
				)
			)
		)
		body.add_child(
			UIK.button(
				"Steady the lamps",
				func():
					Session.command("calm", {"target": room})
					ui.close(),
				true
			)
		)
		return
	if CaseData.TASKS.has(id):
		ui.rituals.task(id)
		return
	if CaseData.ITEMS.has(id):
		inspect_item(id, in_world)
		return
	if id.begins_with("person:"):
		talk(id.trim_prefix("person:"))
		return
	if not CaseData.CLUES.has(id):
		return
	ui.selected_clue = id
	var data = CaseData.CLUES[id]
	var evidence = Session.view.evidence[id]
	var known = evidence.public or evidence.holder == Session.local_role
	var body = ui.dialog(
		data.name if known or in_world else "An unfinished page",
		data.room.to_upper() + "  /  " + data.tag,
		"clue"
	)
	body.add_child(UIK.label("THE EVIDENCE" if known else "SOMETHING LEFT BEHIND", 12, UIK.GOLD))
	var paper = UIK.panel(body, Color("c9bfa7"), Color("8d7c5d"), 32)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var page = UIK.vbox(paper, 18)
	var passage = UIK.paragraph(data.text if known else data.summary, 26, Color("2c302b"))
	passage.add_theme_font_override("font", UIK.serif())
	page.add_child(passage)
	if not known:
		page.add_child(
			UIK.paragraph(
				(
					"Find this evidence in the "
					+ data.room
					+ ". Take it into your keeping to read it."
				),
				20,
				Color("55584b")
			)
		)
	var actions = UIK.hbox(body)
	if not evidence.destroyed and evidence.holder == Session.local_role:
		if not evidence.public:
			actions.add_child(
				UIK.button("REVEAL TO THE CIRCLE", func(): _evidence_action("reveal", id), true)
			)
			actions.add_child(UIK.button("Destroy evidence", func(): confirm_destroy(id)))
		else:
			actions.add_child(UIK.label("✓  This evidence is public.", 20, UIK.TEAL))
		actions.add_child(UIK.button("Give privately…", func(): give(id)))
	elif in_world and evidence.holder == "" and not evidence.destroyed:
		if Session.local_role != "ghost":
			actions.add_child(
				UIK.button("TAKE INTO YOUR KEEPING", _evidence_action.bind("collect", id), true)
			)
		else:
			actions.add_child(
				UIK.label("The dead cannot hold it. Guide a living guest here.", 19, UIK.TEAL)
			)
	elif evidence.destroyed:
		actions.add_child(UIK.label("The original has been destroyed.", 19, UIK.MUTED))
	actions.add_child(UIK.button("Back to journal", open))


func _evidence_action(action: String, id: String) -> void:
	if action == "collect":
		pending_collect = id
	Session.command(action, {"id": id})
	if action != "collect":
		ui.close()


func _command_finished(action: String, payload: Dictionary, error: String) -> void:
	if action != "collect" or str(payload.get("id", "")) != pending_collect:
		return
	var id = pending_collect
	pending_collect = ""
	if error == "" and ui.modal in ["clue", "item"]:
		Sound.play("clue", -5)
		inspect(id)


func confirm_destroy(id: String) -> void:
	var body = ui.dialog("Some truths do not survive", "DESTROY EVIDENCE", "confirm")
	body.add_child(
		UIK.paragraph(
			(
				"Destroy “"
				+ CaseData.CLUES[id].name
				+ "”? It cannot be recovered or revealed after this. The act stays private."
			),
			26,
			UIK.CREAM
		)
	)
	body.add_child(UIK.button("Keep the evidence", func(): inspect(id), true))
	body.add_child(UIK.button("Destroy it", func(): _evidence_action("destroy", id)))


func inheritance() -> void:
	var body = ui.dialog("What the dead leave behind", "INHERITANCE", "inheritance")
	_tabs(body, "Inheritance")
	for id in CaseData.ITEMS:
		var data = CaseData.ITEMS[id]
		var holder = Session.view.items[id]
		var card = UIK.panel(body, UIK.INK, Color("455147"), 18)
		var row = UIK.hbox(card, 25)
		var content = UIK.vbox(row, 6)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(UIK.label(data.name, 28, UIK.GOLD, true))
		content.add_child(UIK.paragraph(data.description, 18))
		content.add_child(
			UIK.label(
				(
					"UNCLAIMED · " + data.room
					if holder == ""
					else "HELD BY " + CaseData.person(holder).name.to_upper()
				),
				12,
				UIK.MUTED
			)
		)
		row.add_child(UIK.button("Inspect", func(): inspect_item(id)))
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"The manor itself is awarded in the final testament. These personal possessions can be claimed during investigation and gifted to another living guest.",
					17
				)
			)
		)
	)


func inspect_item(id: String, in_world: bool = false) -> void:
	var data = CaseData.ITEMS[id]
	var holder = Session.view.items[id]
	var body = ui.dialog(data.name, "AN OBJECT WITH A HISTORY", "item")
	body.add_child(UIK.paragraph(data.description, 29, UIK.CREAM))
	body.add_child(UIK.spacer(25))
	if data.cursed:
		body.add_child(UIK.label("SPIRITUALLY ACTIVE", 15, UIK.TEAL))
		body.add_child(UIK.paragraph("The dead seem very close when this is in your keeping.", 23))
	if holder == "" and in_world and Session.local_role != "ghost":
		body.add_child(
			UIK.button("CLAIM THIS INHERITANCE", _evidence_action.bind("collect", id), true)
		)
	elif holder == Session.local_role:
		body.add_child(UIK.label("This object is in your keeping.", 21, UIK.GOLD))
		body.add_child(UIK.button("Give to another guest", func(): give(id), true))
	else:
		body.add_child(
			UIK.label(
				(
					"Search the " + data.room
					if holder == ""
					else "Held by " + CaseData.person(holder).name
				),
				21,
				UIK.GOLD
			)
		)
	body.add_child(UIK.button("Back to inheritance", inheritance))


func give(id: String) -> void:
	var body = ui.dialog("A gift is never just a gift", "TRANSFER OWNERSHIP", "give")
	body.add_child(
		UIK.paragraph(
			(
				"Choose who receives “"
				+ CaseData.object_data(id).name
				+ "”. They will be free to keep it, reveal it, or pass it on."
			),
			25
		)
	)
	for role in CaseData.ROLES:
		if role != "ghost" and role != Session.local_role:
			body.add_child(
				UIK.button(
					CaseData.person(role).name + "  /  " + CaseData.person(role).title,
					_give_to.bind(id, role)
				)
			)


func people() -> void:
	var body = ui.dialog("Everyone wants something", "THE GUESTS", "people")
	_tabs(body, "The guests")
	var list = UIK.scroll(body)
	for role in CaseData.ROLES:
		if role == Session.local_role:
			continue
		var row = UIK.hbox(UIK.panel(list, UIK.INK, Color("3a493f"), 14))
		AvatarPortrait.add(
			row, role, Session.view.get("appearances", {}).get(role, {}), Vector2(112, 112)
		)
		var text = UIK.vbox(row, 3)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UIK.label(CaseData.person(role).name, 26, UIK.GOLD, true))
		text.add_child(
			UIK.label(
				(
					CaseData.person(role).title
					+ (
						" · human guest"
						if Session.view.humans.has(role)
						else " · played by the house"
					)
				),
				15,
				UIK.MUTED
			)
		)
		row.add_child(UIK.button("Speak", func(): talk(role)))


func talk(role: String) -> void:
	ui.conversation.open(role)


func estate() -> void:
	var body = ui.dialog("A house full of unfinished business", "ESTATE GUIDE", "estate")
	_tabs(body, "Estate guide")
	var rows = [
		[
			"CENTRE",
			"Séance Parlour",
			"The spirit board, ritual candles, and the stopped watch. C opens the circle; the host can convene a sitting early."
		],
		[
			"WEST WING",
			"Library",
			"The last testament, Blackwell's ledger, the family signet, and a radio that catches voices between stations."
		],
		[
			"EAST WING",
			"Conservatory",
			"The evening tonic, pressed belladonna, Lenore's letter, and a mourning locket that is warm to the touch."
		],
		[
			"NORTH",
			"Memorial Chapel",
			"The nursery register, a book of rites, a brass key, and a reliquary sealed with a four-digit year."
		]
	]
	for entry in rows:
		var box = UIK.vbox(UIK.panel(body, UIK.INK, Color("33483f"), 15), 4)
		box.add_child(UIK.label(entry[0] + "   /   " + entry[1].to_upper(), 13, UIK.GOLD))
		box.add_child(UIK.paragraph(entry[2], 19, UIK.CREAM))


func transcript() -> void:
	var body = ui.dialog("Words carry further in the dark", "TRANSCRIPT", "transcript")
	_tabs(body, "Transcript")
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Messages follow voice permissions. A ghost's words reach only the Medium during a sitting, or a possessed vessel. Silenced guests speak only to the Ghost.",
					16
				)
			)
		)
	)
	transcript_box = UIK.scroll(body)
	last_message_signature = ""
	refresh_transcript()
	var input_row = UIK.hbox(body)
	transcript_input = LineEdit.new()
	transcript_input.placeholder_text = "Say something to those who can hear you…"
	transcript_input.max_length = 240
	transcript_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transcript_input.text_submitted.connect(func(_text): _send())
	input_row.add_child(transcript_input)
	input_row.add_child(UIK.button("Speak", _send, true))
	transcript_input.grab_focus()


func _send() -> void:
	if transcript_input.text.strip_edges() == "":
		return
	Session.command("chat", {"text": transcript_input.text})
	transcript_input.clear()
	refresh_transcript()


func refresh_transcript() -> void:
	if ui.modal != "transcript" or not is_instance_valid(transcript_box):
		return
	var messages = Session.view.get("messages", [])
	var events = Session.view.get("journal", [])
	var signature = str(messages) + str(events)
	if signature == last_message_signature:
		return
	last_message_signature = signature
	UIK.clear(transcript_box)
	transcript_box.add_child(UIK.label("THE CIRCLE", 12, UIK.GOLD))
	for message in events.slice(maxi(0, events.size() - 8)):
		transcript_box.add_child(UIK.paragraph(message, 18))
	transcript_box.add_child(UIK.line())
	transcript_box.add_child(UIK.label("WHAT YOU HEARD · PRIVATE TO YOU", 12, UIK.TEAL))
	for message in messages.slice(maxi(0, messages.size() - 16)):
		transcript_box.add_child(UIK.paragraph(message, 21, UIK.CREAM))
	if messages.is_empty():
		transcript_box.add_child(
			UIK.paragraph("No private words yet. Speak to a guest, or listen at a séance.", 20)
		)
	var scroller = transcript_box.get_parent() as ScrollContainer
	scroller.set_deferred("scroll_vertical", 100000)


func _give_to(id: String, role: String) -> void:
	Session.command("give", {"id": id, "target": role})
	ui.close()


func _ask(role: String, topic: String) -> void:
	Session.command("talk", {"target": role, "topic": topic})
	talk(role)
