class_name SeanceRituals
extends RefCounted

var ui
var sequence: Array = []
var sequence_label: Label
var ballot_status: Label
var ballot_submitted = false


func _init(owner_ui) -> void:
	ui = owner_ui


func task(id: String) -> void:
	var data = CaseData.TASKS[id]
	var body = ui.dialog(data.name, "PREPARE THE THRESHOLD", "task")
	body.add_child(UIK.paragraph(data.description, 27, UIK.CREAM))
	if Session.view.tasks[id] != "":
		body.add_child(UIK.label("✓  The apparatus is ready.", 27, UIK.TEAL))
		return
	if Session.local_role == "ghost":
		body.add_child(
			UIK.paragraph(
				"Your hands pass through it. Lead a living guest to this apparatus.", 23, UIK.TEAL
			)
		)
		return
	body.add_child(UIK.spacer(25))
	match id:
		"radio":
			var frequency = UIK.label("83.0 MHz", 73, UIK.GOLD, true)
			frequency.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			body.add_child(frequency)
			var tuner = HSlider.new()
			tuner.min_value = 80.0
			tuner.max_value = 100.0
			tuner.step = 0.1
			tuner.value = 83.0
			tuner.custom_minimum_size.y = 65
			tuner.value_changed.connect(
				func(value):
					frequency.text = "%.1f MHz" % value
					frequency.modulate = UIK.TEAL if absf(value - 88.7) < 0.06 else UIK.GOLD
					Sound.play("click", -22)
			)
			body.add_child(tuner)
			body.add_child(
				UIK.paragraph(
					"Use the mouse, or focus the dial and press the arrow keys for fine tuning.", 17
				)
			)
			body.add_child(
				UIK.button("HOLD THE FREQUENCY", func(): solve(id, "%.1f" % tuner.value), true)
			)
		"candles":
			sequence = []
			sequence_label = UIK.label("—      —      —", 49, UIK.GOLD, true)
			sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			body.add_child(sequence_label)
			body.add_child(UIK.spacer(20))
			var symbols = UIK.hbox(body, 12)
			for symbol in ["MOON", "THORN", "KEY", "SUN", "ASH"]:
				var button = UIK.button(symbol, _append_symbol.bind(symbol))
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				symbols.add_child(button)
			body.add_child(UIK.spacer(25))
			body.add_child(
				UIK.button("LIGHT THE CIRCLE", func(): solve(id, ",".join(sequence)), true)
			)
			body.add_child(UIK.button("Reset the symbols", _reset_sequence))
		"safe":
			body.add_child(UIK.label("What year changed everything?", 37, UIK.GOLD, true))
			var code = LineEdit.new()
			code.placeholder_text = "— — — —"
			code.max_length = 4
			code.alignment = HORIZONTAL_ALIGNMENT_CENTER
			code.add_theme_font_size_override("font_size", 45)
			code.custom_minimum_size.y = 92
			code.text_submitted.connect(func(answer): solve(id, answer))
			body.add_child(code)
			body.add_child(UIK.button("OPEN THE RELIQUARY", func(): solve(id, code.text), true))
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"A successful preparation earns 1 point and brings the release ritual closer. Two preparations are needed to open the threshold.",
					17
				)
			)
		)
	)


func solve(id: String, answer: String) -> void:
	Session.command("task", {"id": id, "answer": answer})
	ui.close()


func circle() -> void:
	var view = Session.view
	if view.phase == "judgment":
		judgment()
		return
	if view.phase == "ended":
		results()
		return
	var sitting = view.phase == "seance"
	var body = ui.dialog(
		"The veil is open" if sitting else "Return to the circle",
		"SITTING " + ["I", "II", "III"][view.round - 1],
		"circle"
	)
	var row = UIK.hbox(body, 30)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board_image = TextureRect.new()
	board_image.texture = load("res://assets/spirit_board.svg")
	board_image.custom_minimum_size = Vector2(330, 330)
	board_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(board_image)
	var text = UIK.vbox(row, 18)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if sitting:
		text.add_child(UIK.label("“Is there someone with us?”", 39, UIK.GOLD, true))
		(
			text
			. add_child(
				(
					UIK
					. paragraph(
						"The living hear one another. The Medium hears Edmund. Whether the circle hears the truth is another matter.",
						24,
						UIK.CREAM
					)
				)
			)
		)
		text.add_child(UIK.label("THE LAST SIGN", 12, UIK.MUTED))
		text.add_child(
			UIK.label(view.manifest_word if view.manifest_word else "Silence", 38, UIK.TEAL, true)
		)
		if Session.local_role == "medium":
			for question in [
				["death", "Ask how he died"],
				["heir", "Ask about his heir"],
				["ritual", "Ask what he wants"]
			]:
				text.add_child(UIK.button(question[1], _question.bind(question[0])))
		elif Session.local_role == "ghost":
			text.add_child(UIK.button("Speak through the board", spirit, true))
		else:
			(
				text
				. add_child(
					(
						UIK
						. paragraph(
							"Listen to the Medium. They have their own reasons for what they choose to tell you.",
							21
						)
					)
				)
			)
	else:
		text.add_child(UIK.label("The house is not finished with you.", 34, UIK.GOLD, true))
		(
			text
			. add_child(
				(
					UIK
					. paragraph(
						"Search the rooms, speak to the guests, and decide which evidence belongs to everyone. Convening a séance gathers all human guests around the table.",
						24,
						UIK.CREAM
					)
				)
			)
		)
		text.add_child(UIK.label(str(view.prepared) + " / 3  PREPARATIONS COMPLETE", 15, UIK.TEAL))
		(
			text
			. add_child(
				(
					UIK
					. paragraph(
						"Three sittings lead to the final testament. The host may advance a phase early, or let the clock do it.",
						20
					)
				)
			)
		)
	var buttons = UIK.hbox(body)
	buttons.add_child(UIK.button("Review evidence", ui.journal.open))
	buttons.add_child(UIK.button("Open transcript", ui.journal.transcript))
	if Session.hosting:
		buttons.add_child(
			UIK.button("BREAK THE CIRCLE" if sitting else "CONVENE THE SÉANCE", _advance, true)
		)
	else:
		buttons.add_child(UIK.label("The host leads the sitting.", 17, UIK.MUTED))


func spirit() -> void:
	if Session.local_role != "ghost":
		ui.toast("Only the Ghost can bend the veil. Your own motives are in the journal.")
		return
	var body = ui.dialog(
		"Make them listen",
		"BEYOND THE VEIL  /  " + str(int(Session.view.energy)) + " SPIRIT ENERGY",
		"spirit"
	)
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"A manifestation costs 15 energy. Living guests see its result. Your voice is private to the Medium during the sitting, unless you open another channel.",
					22
				)
			)
		)
	)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)
	for word in [
		"YES", "NO", "DANGER", "BLOOD", "BETRAYAL", "MINE", "NOT THEM", "RELEASE", "KNOCK"
	]:
		var button = UIK.button(word, _manifest.bind(word))
		button.custom_minimum_size = Vector2(395, 60)
		grid.add_child(button)
	body.add_child(UIK.spacer(12))
	body.add_child(UIK.label("A SECOND INTERPRETER", 13, UIK.GOLD))
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Possession costs 40 energy after sitting I. For sixty seconds the vessel hears you, but keeps control. Silence costs 25; only you hear that guest for twenty-five seconds.",
					18
				)
			)
		)
	)
	var row = UIK.hbox(body)
	var targets = OptionButton.new()
	for role in ["heir", "widow", "doctor", "keeper"]:
		targets.add_item(CaseData.person(role).name)
		targets.set_item_metadata(targets.item_count - 1, role)
	targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(targets)
	row.add_child(UIK.button("Invite possession  ·  40", _target_action.bind("possess", targets)))
	row.add_child(UIK.button("Speak no evil  ·  25", _target_action.bind("silence", targets)))


func judgment() -> void:
	ballot_submitted = Session.view.votes.get("submitted", false)
	var body = ui.dialog("What will the living believe?", "THE FINAL TESTAMENT", "judgment")
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Three decisions. One version of the truth. The circle's majority decides each independently; your personal objectives decide what victory means.",
					24,
					UIK.CREAM
				)
			)
		)
	)
	ballot_status = UIK.label("", 16, UIK.TEAL)
	body.add_child(ballot_status)
	refresh_ballot()
	if ballot_submitted:
		body.add_child(UIK.label("Your testament is sealed.", 40, UIK.GOLD, true))
		(
			body
			. add_child(
				(
					UIK
					. paragraph(
						"Waiting for the other guests, or for dawn. The host may close the vote when the circle is ready.",
						23
					)
				)
			)
		)
		if Session.hosting:
			body.add_child(UIK.button("Close the vote now", Session.advance))
		return
	var picks = {}
	var questions = [
		["culprit", "01   Name the guilty", ["none", "doctor", "widow", "heir", "keeper"]],
		["heir", "02   Name the heir", ["heir", "keeper", "widow", "doctor"]],
		[
			"ending",
			"03   Decide the spirit's fate",
			["release", "bind", "banish"] if Session.view.prepared >= 2 else ["bind", "banish"]
		]
	]
	for question in questions:
		var card = UIK.panel(body, UIK.INK, Color("445146"), 19)
		var row = UIK.hbox(card, 22)
		var title = UIK.label(question[1], 28, UIK.GOLD, true)
		title.custom_minimum_size.x = 525
		row.add_child(title)
		var selector = OptionButton.new()
		selector.custom_minimum_size.y = 50
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for option in question[2]:
			var name = (
				{
					"none": "No conviction",
					"release": "Release — open the threshold",
					"bind": "Bind — imprison the spirit",
					"banish": "Banish — sever the connection"
				}
				. get(option, CaseData.person(option).name)
			)
			selector.add_item(name)
			selector.set_item_metadata(selector.item_count - 1, option)
		row.add_child(selector)
		picks[question[0]] = selector
	if Session.view.prepared < 2:
		body.add_child(
			UIK.paragraph(
				"Release is unavailable: fewer than two ritual preparations were completed.",
				17,
				UIK.GOLD
			)
		)
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Ties: no conviction · Julian inherits · the spirit is banished. Every guest, including Edmund, has one ballot. A missed ballot follows the public evidence.",
					16
				)
			)
		)
	)
	var actions = UIK.hbox(body)
	actions.add_child(UIK.button("Review the journal", ui.journal.open))
	actions.add_child(UIK.button("SEAL MY TESTAMENT", _seal.bind(picks), true))


func _append_symbol(symbol: String) -> void:
	if sequence.size() < 3:
		sequence.append(symbol)
		sequence_label.text = "   ·   ".join(sequence)


func _reset_sequence() -> void:
	sequence.clear()
	sequence_label.text = "—      —      —"


func _question(id: String) -> void:
	Session.command("question", {"id": id})
	ui.journal.transcript()


func _advance() -> void:
	ui.close()
	Session.advance()


func _manifest(word: String) -> void:
	Session.command("manifest", {"word": word})
	ui.close()


func _target_action(action: String, targets: OptionButton) -> void:
	Session.command(action, {"target": targets.get_item_metadata(targets.selected)})
	ui.close()


func _seal(picks: Dictionary) -> void:
	var vote = {}
	for key in picks:
		vote[key] = picks[key].get_item_metadata(picks[key].selected)
	Session.command("vote", vote)


func refresh_ballot() -> void:
	if ui.modal == "judgment" and is_instance_valid(ballot_status):
		if ballot_submitted != Session.view.votes.get("submitted", false):
			judgment()
			return
		ballot_status.text = str(Session.view.votes.get("count", 0)) + " TESTAMENTS SEALED"


func results() -> void:
	var view = Session.view
	if view.ending.is_empty():
		return
	var ending = view.ending
	var names = {
		"release": "At last, a little peace.",
		"bind": "The house keeps its dead.",
		"banish": "Silence is not forgiveness."
	}
	var body = ui.dialog(names[ending.ending], "DAWN  /  THE UNQUIET WILL", "results")
	ui.close_button.hide()
	var rows = UIK.hbox(body, 28)
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var story = UIK.vbox(rows, 18)
	story.custom_minimum_size.x = 470
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_child(UIK.label("THE STORY YOU LEFT BEHIND", 12, UIK.GOLD))
	var fate = {
		"release":
		"Edmund crossed the threshold. The candles steadied. For the first time in years, the house felt empty.",
		"bind":
		"The circle closed around Edmund. Every future owner will be able to call him back. Forever is a very long inheritance.",
		"banish":
		"The voice vanished. No one could say whether Edmund found peace, or simply lost the means to ask for it."
	}
	story.add_child(UIK.paragraph(fate[ending.ending], 25, UIK.CREAM))
	story.add_child(UIK.line())
	story.add_child(
		UIK.paragraph(CaseData.person(ending.heir).name + " inherited Ashwood Manor.", 22, UIK.GOLD)
	)
	var verdict = (
		"No one was convicted."
		if ending.culprit == "none"
		else CaseData.person(ending.culprit).name + " was named the murderer."
	)
	story.add_child(UIK.paragraph(verdict, 21, UIK.CREAM))
	(
		story
		. add_child(
			(
				UIK
				. paragraph(
					"THE TRUTH: Blackwell poisoned the tonic to conceal his theft. Iris was Edmund's firstborn daughter. Whether the circle accepted those facts was up to you.",
					16
				)
			)
		)
	)
	var scores = UIK.vbox(rows, 10)
	scores.custom_minimum_size.x = 660
	var top_score = view.scores[0].points
	for score in view.scores:
		var card = UIK.panel(
			scores,
			Color("25362f") if score.points == top_score else UIK.INK,
			UIK.GOLD if score.points == top_score else Color("35433c"),
			14
		)
		var row = UIK.hbox(card, 14)
		var name = UIK.vbox(row, 4)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.add_child(
			UIK.label(
				(
					CaseData.person(score.role).name
					+ ("  ·  YOU" if score.role == Session.local_role else "")
				),
				24,
				UIK.CREAM,
				true
			)
		)
		var checked = []
		for i in range(3):
			checked.append(("✓ " if score.goals[i] else "— ") + str([2, 3, 5][i]))
		name.add_child(
			UIK.label(
				" / ".join(checked) + "   ·   PREPARATIONS +" + str(score.bonus), 12, UIK.MUTED
			)
		)
		row.add_child(UIK.label(str(score.points) + " pts", 30, UIK.GOLD, true))
	body.add_child(UIK.button("LEAVE ASHWOOD     →", ui.show_menu, true))
