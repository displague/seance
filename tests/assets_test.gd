extends SceneTree

var checks = 0
var failures: Array = []


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func run() -> void:
	test_splash()
	var models = ["medium", "physician"]
	for role in CaseData.ROLES:
		models.append("roster/" + role)
	for model in models:
		var path = "res://assets/models/" + model + "/character.glb"
		expect(ResourceLoader.exists(path), "rig exists " + model)
		var instance = load(path).instantiate()
		root.add_child(instance)
		var skeletons = instance.find_children("*", "Skeleton3D", true, false)
		expect(
			skeletons.size() == 1 and skeletons[0].get_bone_count() == 24,
			"24-bone skeleton " + model
		)
		var player = CharacterMotion.attach(instance, model)
		await process_frame
		await process_frame
		expect(player != null, "motion attached " + model)
		for clip in ["idle", "walking", "running"]:
			expect(player.has_animation("seance/" + clip), "clip exists " + model + " " + clip)
		var bounds = AABB()
		for mesh in instance.find_children("*", "MeshInstance3D", true, false):
			bounds = bounds.merge(mesh.global_transform * mesh.get_aabb())
		for skeleton in skeletons:
			# A skinned GLB's static source mesh bounds omit its bind transforms.
			# Measure the evaluated rig in world metres, including its end bones.
			for index in range(skeleton.get_bone_count()):
				bounds = bounds.expand(
					skeleton.global_transform * skeleton.get_bone_global_pose(index).origin
				)
		expect(bounds.size.y > 1.4 and bounds.size.y < 2.1, "human-scale rig " + model)
		print("ASSET: ", model, " evaluated rig bounds ", bounds.size)
		CharacterMotion.update(player, 2.2)
		expect(player.current_animation == "seance/walking", "walking transition " + model)
		CharacterMotion.update(player, 5.3)
		expect(player.current_animation == "seance/running", "running transition " + model)
		CharacterMotion.update(player, 0)
		expect(player.current_animation == "seance/idle", "idle transition " + model)
		instance.free()
	print("ASSETS: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func test_splash() -> void:
	var path = str(ProjectSettings.get_setting("application/boot_splash/image", ""))
	expect(path == "res://assets/art/boot_splash.png", "custom PNG boot splash configured")
	var splash = Image.load_from_file(path)
	expect(splash != null and not splash.is_empty(), "boot splash decodes without texture import")
	if splash:
		expect(splash.get_size() == Vector2i(1600, 900), "boot splash native aspect ratio")
		var background: Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
		expect(
			splash.get_pixel(0, 0).is_equal_approx(background), "splash edges match letterbox color"
		)
	expect(ProjectSettings.get_setting("application/boot_splash/show_image"), "boot image enabled")
	expect(
		ProjectSettings.get_setting("application/boot_splash/stretch_mode") == 1,
		"boot splash requests KEEP aspect mode (configuration, not rendered proof)"
	)
	expect(
		ProjectSettings.get_setting("application/boot_splash/minimum_display_time") <= 1000,
		"boot splash has no long forced delay"
	)
