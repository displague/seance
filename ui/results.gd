class_name SeanceResults
extends RefCounted
## Renders rules-owned summaries. No scoring or award eligibility lives here.

var ui


func _init(owner_ui) -> void:
	ui = owner_ui


func recap() -> void:
	var view = Session.view
	if view.phase == "ended":
		summary()
		return
	if view.recap.is_empty():
		continue_case()
		return
	var report = view.recap
	var body = ui.dialog(report.title, "THE SAME CASE CONTINUES  /  PHASE RECAP", "recap")
	body.add_child(UIK.paragraph(view.phase_info.next, 22, UIK.CREAM))
	(
		body
		. add_child(
			(
				UIK
				. paragraph(
					"Public progress only — private objectives and ulterior motives are scored at dawn. Awards below recognize actions in the phase just completed; they add no bonus points.",
					16
				)
			)
		)
	)
	var list = UIK.scroll(body)
	list.add_theme_constant_override("separation", 6)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(grid)
	for row in report.rows:
		var card = UIK.panel(grid, UIK.INK, Color("35433c"), 12)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var content = UIK.vbox(card, 2)
		var heading = UIK.hbox(content)
		var name = UIK.label(CaseData.person(row.role).name, 20, UIK.CREAM, true)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name)
		heading.add_child(
			UIK.label(
				"Public %d / 2  ·  Preparations +%d" % [row.public_points, row.preparation_points],
				14,
				UIK.GOLD
			)
		)
		content.add_child(
			UIK.paragraph(("✓ " if row.public_complete else "— ") + row.public_objective, 16)
		)
		if not row.awards.is_empty():
			content.add_child(UIK.paragraph(award_text(row.awards, true), 14, UIK.TEAL))
	body.add_child(
		UIK.label(
			(
				"Online: the shared clock continues while you read."
				if Session.online
				else "Solo: the clock is paused while you read. Continue when you are ready."
			),
			14,
			UIK.GOLD
		)
	)
	body.add_child(UIK.button(view.phase_info.continue, continue_case, true))


func continue_case() -> void:
	match Session.view.phase:
		"seance":
			ui.rituals.circle()
		"judgment":
			ui.rituals.judgment()
		"ended":
			summary()
		_:
			ui.close()


func summary() -> void:
	var view = Session.view
	if view.ending.is_empty():
		return
	var ending = view.ending
	var names = {
		"release": "At last, a little peace.",
		"bind": "The house keeps its dead.",
		"banish": "Silence is not forgiveness."
	}
	var body = ui.dialog(names[ending.ending], "CASE COMPLETE  /  FINAL SCORES & AWARDS", "results")
	ui.close_button.hide()
	var columns = UIK.hbox(body, 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var story = UIK.vbox(columns, 16)
	story.custom_minimum_size.x = 430
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
	story.add_child(UIK.paragraph(fate[ending.ending], 23, UIK.CREAM))
	story.add_child(UIK.line())
	story.add_child(
		UIK.paragraph(CaseData.person(ending.heir).name + " inherited Ashwood Manor.", 22, UIK.GOLD)
	)
	story.add_child(
		UIK.paragraph(
			(
				"No one was convicted."
				if ending.culprit == "none"
				else CaseData.person(ending.culprit).name + " was named the murderer."
			),
			21,
			UIK.CREAM
		)
	)
	story.add_child(UIK.paragraph("THE TRUTH: " + view.final_summary.truth, 16))
	(
		story
		. add_child(
			(
				UIK
				. paragraph(
					"Select any guest for all three objectives, earned points and achievements. Awards are descriptive, not extra points.",
					15
				)
			)
		)
	)
	var score_column = UIK.vbox(columns, 8)
	score_column.custom_minimum_size.x = 720
	score_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list = UIK.scroll(score_column)
	list.add_theme_constant_override("separation", 7)
	for row in view.final_summary.rows:
		var card = UIK.panel(
			list,
			Color("25362f") if row.rank == 1 else UIK.INK,
			UIK.GOLD if row.rank == 1 else Color("35433c"),
			8
		)
		var content = UIK.vbox(card, 0)
		var text = (
			"#%d   %s%s     %d pts"
			% [
				row.rank,
				CaseData.person(row.role).name,
				" · YOU" if row.role == Session.local_role else "",
				row.points
			]
		)
		var button = UIK.button(text, details.bind(row.role), row.rank == 1)
		button.custom_minimum_size.y = 34
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_focus_color", UIK.INK if row.rank == 1 else UIK.CREAM)
		button.add_theme_stylebox_override(
			"normal",
			UIK.style(
				UIK.GOLD if row.rank == 1 else UIK.INK,
				UIK.GOLD if row.rank == 1 else Color("40504a"),
				1,
				6
			)
		)
		button.add_theme_stylebox_override("hover", UIK.style(Color("21312f"), UIK.GOLD, 1, 6))
		button.add_theme_stylebox_override("pressed", UIK.style(UIK.GOLD, UIK.GOLD, 1, 6))
		button.add_theme_stylebox_override("focus", UIK.style(Color.TRANSPARENT, UIK.GOLD, 2, 6))
		content.add_child(button)
		var awards_label = UIK.paragraph(award_text(row.awards), 13, UIK.TEAL)
		awards_label.max_lines_visible = 1
		awards_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		content.add_child(awards_label)
	body.add_child(
		UIK.label(
			"No new game starts automatically. Results remain until you choose to leave.",
			14,
			UIK.GOLD
		)
	)
	body.add_child(UIK.button("LEAVE ASHWOOD     →", ui.show_menu, true))
	Controls.focus_first.call_deferred(body)


func details(role: String) -> void:
	var row = {}
	for entry in Session.view.final_summary.rows:
		if entry.role == role:
			row = entry
	if row.is_empty():
		return
	var body = ui.dialog(
		CaseData.person(role).name,
		"FINAL OBJECTIVES  /  #%d  /  %d POINTS" % [row.rank, row.points],
		"results_detail"
	)
	ui.close_button.hide()
	var list = UIK.scroll(body)
	for objective in row.objectives:
		var card = UIK.panel(list, UIK.INK, Color("35433c"), 15)
		var content = UIK.vbox(card, 7)
		content.add_child(
			UIK.label(
				(
					objective.category.to_upper()
					+ "  ·  %d / %d POINTS" % [objective.earned, objective.available]
				),
				14,
				UIK.TEAL if objective.complete else UIK.GOLD
			)
		)
		content.add_child(
			UIK.paragraph(("✓ " if objective.complete else "— ") + objective.text, 24, UIK.CREAM)
		)
	list.add_child(UIK.label("PREPARATIONS: +%d  (maximum +3)" % row.bonus, 19, UIK.GOLD))
	list.add_child(UIK.paragraph("EARNED AWARDS\n" + award_text(row.awards, true), 19, UIK.TEAL))
	body.add_child(UIK.button("BACK TO ALL SIX GUESTS", summary, true))
	Controls.focus_first.call_deferred(body)


func award_text(earned: Array, include_detail: bool = false) -> String:
	if earned.is_empty():
		return "No recorded action award. Quiet choices may still fulfill a motive."
	var labels = []
	for award in earned:
		labels.append(award.title + (" — " + award.detail if include_detail else ""))
	return "  ·  ".join(labels)
