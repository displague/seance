extends SceneTree
## Offline extraction: keep only animation tracks, not duplicate 4K characters.


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	for role in CaseData.ROLES:
		var model = "roster/" + role
		var instance = load("res://assets/models/" + model + "/character.glb").instantiate()
		root.add_child(instance)
		var player = CharacterMotion.attach(instance, model, false)
		if player == null:
			printerr("BAKE: missing animation for ", role)
			quit(1)
			return
		var error = ResourceSaver.save(
			player.get_animation_library("seance"),
			"res://assets/models/" + model + "/locomotion.res"
		)
		instance.free()
		if error != OK:
			quit(1)
			return
		print("BAKE: ", role)
		await process_frame
	print("BAKE: PASS")
	quit()
