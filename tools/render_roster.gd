extends SceneTree
## Render equipped assets using the same portrait factory as the game.


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var kit = load("res://ui/ui_kit.gd")
	var portraits = load("res://ui/avatar_portrait.gd")
	root.size = Vector2i(1600, 900)
	var layout = Control.new()
	layout.theme = kit.make_theme()
	root.add_child(layout)
	for i in range(CaseData.ROLES.size()):
		var role = CaseData.ROLES[i]
		var column = VBoxContainer.new()
		column.position = Vector2(14 + i * 264, 20)
		layout.add_child(column)
		column.add_child(kit.label(CaseData.person(role).title, 22, kit.GOLD))
		var choice = {"outfit": "ashwood", "brooch": "silver"}
		portraits.add(column, role, choice, Vector2(250, 475), true)
		portraits.add(column, role, choice, Vector2(250, 265))
	for i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/roster-sheet.png")
	print("ROSTER RENDER: complete")
	for device in Input.get_connected_joypads():
		print(
			"CONTROLLER: ",
			device,
			" ",
			Input.get_joy_name(device),
			" mapped=",
			Input.is_joy_known(device)
		)
	layout.free()
	await process_frame
	quit()
