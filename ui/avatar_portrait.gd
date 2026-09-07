class_name AvatarPortrait
extends SubViewportContainer
## A snapshot of the actual equipped rig and accessories, not a generic icon.


static func add(
	parent: Node, role: String, appearance: Dictionary, dimensions: Vector2, full_body: bool = false
) -> AvatarPortrait:
	var portrait = AvatarPortrait.new()
	portrait.custom_minimum_size = dimensions
	portrait.size = dimensions
	portrait.stretch = true
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(portrait)
	var viewport = SubViewport.new()
	viewport.size = Vector2i(dimensions * 1.5)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	portrait.add_child(viewport)
	var world = Node3D.new()
	viewport.add_child(world)
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("152728")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b7c9c6")
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, 145, 0)
	light.light_energy = 1.5
	light.light_color = Color("ffe2bc")
	world.add_child(light)
	var avatar = AvatarFactory.create(role, appearance)
	if avatar != null:
		world.add_child(avatar)
		var motion = AvatarFactory.finish(avatar, role, appearance)
		if motion != null:
			motion.advance(0)
			motion.pause()
	var camera = Camera3D.new()
	world.add_child(camera)
	var height = float(AppearanceData.HEIGHTS[role])
	camera.position = Vector3(
		0, height * (0.57 if full_body else 0.9), -3.4 if full_body else -0.85
	)
	camera.fov = 37
	camera.look_at(Vector3(0, height * (0.52 if full_body else 0.88), 0))
	camera.make_current()
	portrait.set_meta("appearance", AppearanceData.normalize(role, appearance))
	return portrait
