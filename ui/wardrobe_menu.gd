class_name WardrobeMenu
extends RefCounted


static func show(ui, role: String, back: Callable) -> void:
	var body = ui.dialog(CaseData.person(role).name, "WARDROBE · SAVED PER CHARACTER", "wardrobe")
	var row = UIK.hbox(body, 30)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var choice: Dictionary = Wardrobe.choices[role].duplicate()
	var preview = VBoxContainer.new()
	preview.custom_minimum_size.x = 370
	row.add_child(preview)
	AvatarPortrait.add(preview, role, choice, Vector2(370, 450), true)
	var panel = UIK.vbox(row, 16)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(UIK.label("Your face at the table", 31, UIK.GOLD, true))
	(
		panel
		. add_child(
			(
				UIK
				. paragraph(
					"This preference follows you when this character is chosen or assigned. Other players see this exact model and brooch in the manor and in guest portraits. Changes take effect next sitting.",
					20
				)
			)
		)
	)
	panel.add_child(UIK.label("Outfit · free base looks", 19, UIK.GOLD))
	var outfits = OptionButton.new()
	outfits.add_item("Ashwood · original detailed character")
	if role in ["medium", "doctor"]:
		outfits.add_item("Heritage · alternate face and tailored suit")
	outfits.select(1 if choice.outfit == "heritage" else 0)
	panel.add_child(outfits)
	panel.add_child(UIK.label("Lapel brooch · cosmetic only", 19, UIK.GOLD))
	var brooches = OptionButton.new()
	brooches.add_item("None · free")
	brooches.add_item("Silver circle · free")
	brooches.add_item(
		"Gilded circle · earned" if Wardrobe.gold_unlocked else "Gilded circle · 60 Remembrance"
	)
	brooches.set_item_disabled(2, not Wardrobe.gold_unlocked)
	brooches.select(["none", "silver", "gold"].find(choice.brooch))
	panel.add_child(brooches)
	var refresh = func():
		choice.outfit = "heritage" if outfits.selected == 1 else "ashwood"
		choice.brooch = ["none", "silver", "gold"][brooches.selected]
		UIK.clear(preview)
		AvatarPortrait.add(preview, role, choice, Vector2(370, 450), true)
	outfits.item_selected.connect(func(_index): refresh.call())
	brooches.item_selected.connect(func(_index): refresh.call())
	panel.add_child(UIK.label("REMEMBRANCE  %d" % Wardrobe.remembrance, 20, UIK.TEAL))
	if not Wardrobe.gold_unlocked:
		var unlock = UIK.button(
			"Unlock gilded brooch · 60 earned Remembrance",
			func():
				var error = Wardrobe.unlock_gold()
				if error == OK:
					show(ui, role, back)
				else:
					ui.toast("Could not unlock or save this cosmetic.")
		)
		unlock.disabled = Wardrobe.remembrance < AppearanceData.GOLD_COST
		panel.add_child(unlock)
	(
		panel
		. add_child(
			(
				UIK
				. paragraph(
					"Earn 20 Remembrance per completed sitting, plus 2 per score point. Local prototype progression only. No paid store or battle pass is live. Future extras are cosmetics, never abilities or stronger evidence. Skin/hair/eye sliders need authored texture masks and are not yet available.",
					16
				)
			)
		)
	)
	var buttons = UIK.hbox(body)
	buttons.add_child(
		UIK.button(
			"Save this appearance",
			func():
				if Wardrobe.equip(role, choice) == OK:
					back.call()
				else:
					ui.toast("Appearance could not be saved."),
			true
		)
	)
	buttons.add_child(UIK.button("Back", back))
