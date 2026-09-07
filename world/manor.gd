class_name AshwoodManor
extends Node3D

var props: ManorProps
var targets: Dictionary = {}
var spirit_light: OmniLight3D
var time = 0.0
var environment: Environment
var dust: GPUParticles3D
var moon: DirectionalLight3D
var atmosphere: ManorAtmosphere


func _ready() -> void:
	props = ManorProps.new(self)
	_build_environment()
	_build_shell()
	_build_parlour()
	_build_library()
	_build_conservatory()
	_build_chapel()
	_build_objects()
	_build_dust()
	atmosphere = ManorAtmosphere.new(self)


func _build_environment() -> void:
	var world = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("081218")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("819795")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.15
	environment.fog_enabled = true
	environment.fog_light_color = Color("0c1a20")
	environment.fog_light_energy = 0.38
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-32, -35, 0)
	moon.light_color = Color("8cbbd1")
	moon.light_energy = 0.65
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40
	add_child(moon)


func _floor(center: Vector3, dimensions: Vector2, ceiling: float) -> void:
	props.box(
		center - Vector3(0, 0.16, 0),
		Vector3(dimensions.x, 0.3, dimensions.y),
		props.mats.trim,
		true
	)
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.295, 0.035, 1.47)
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	var across = int(dimensions.x / 0.3)
	var rows = int(dimensions.y / 1.5)
	multi.instance_count = across * rows
	var rng = RandomNumberGenerator.new()
	rng.seed = int(absf(center.x * 41 + center.z * 19)) + 7
	for x in range(across):
		for z in range(rows):
			var p = (
				center
				+ Vector3(
					(x + 0.5) * 0.3 - dimensions.x / 2, 0.012, (z + 0.5) * 1.5 - dimensions.y / 2
				)
			)
			multi.set_instance_transform(x * rows + z, Transform3D(Basis(), p))
			multi.set_instance_color(x * rows + z, Color.WHITE * rng.randf_range(0.8, 1.1))
	var planks = MultiMeshInstance3D.new()
	planks.multimesh = multi
	planks.material_override = props.mats.floor
	add_child(planks)
	props.box(
		center + Vector3(0, ceiling, 0), Vector3(dimensions.x, 0.18, dimensions.y), props.mats.trim
	)


func _wall(pos: Vector3, length: float, height: float, rotation_y: float = 0) -> void:
	var wall = Node3D.new()
	wall.position = pos
	wall.rotation.y = rotation_y
	add_child(wall)
	props.box(Vector3(0, height / 2, 0), Vector3(length, height, 0.26), props.mats.wall, true, wall)
	for y in [0.13, 1.4, height - 0.15]:
		props.box(
			Vector3(0, y, 0), Vector3(length + 0.08, 0.13, 0.38), props.mats.trim, false, wall
		)
	props.box(Vector3(0, 1.49, 0), Vector3(length, 0.024, 0.36), props.mats.dark_brass, false, wall)
	for i in range(int(length)):
		var x = (i + 0.5) - length / 2
		props.box(Vector3(x, 0.77, 0), Vector3(0.92, 1.1, 0.29), props.mats.wood, false, wall)
		for side in [-0.41, 0.41]:
			props.box(
				Vector3(x + side, 0.77, 0),
				Vector3(0.025, 1, 0.33),
				props.mats.dark_brass,
				false,
				wall
			)
		for y in [0.29, 1.25]:
			props.box(
				Vector3(x, y, 0), Vector3(0.84, 0.025, 0.33), props.mats.dark_brass, false, wall
			)


func _arch(pos: Vector3, angle: float, caption: String) -> void:
	var frame = Node3D.new()
	frame.position = pos
	frame.rotation.y = angle
	add_child(frame)
	for x in [-1.72, 1.72]:
		props.box(Vector3(x, 1.65, 0), Vector3(0.25, 3.3, 0.45), props.mats.wood, true, frame)
		props.box(Vector3(x, 0.12, 0), Vector3(0.38, 0.24, 0.54), props.mats.trim, false, frame)
		props.box(Vector3(x, 3.25, 0), Vector3(0.4, 0.16, 0.58), props.mats.brass, false, frame)
	for i in range(16):
		var a = PI * i / 15
		var p = Vector3(cos(a) * 1.72, 3.3 + sin(a) * 0.9, 0)
		var piece = props.box(p, Vector3(0.37, 0.2, 0.43), props.mats.trim, false, frame)
		piece.rotation.z = atan2(cos(a) * 0.9, -sin(a) * 1.72)
	props.box(Vector3(0, 4.7, 0), Vector3(3.7, 1, 0.3), props.mats.wall, true, frame)
	var plaque = Label3D.new()
	plaque.text = caption.to_upper()
	plaque.position = Vector3(0, 3.78, 0.3)
	plaque.font_size = 34
	plaque.pixel_size = 0.004
	plaque.modulate = Color("c3ac7c")
	plaque.outline_size = 3
	frame.add_child(plaque)


func _build_shell() -> void:
	_floor(Vector3.ZERO, Vector2(16, 18), 5.5)
	_floor(Vector3(-12, 0, 0), Vector2(8, 10), 4.6)
	_floor(Vector3(12, 0, 0), Vector2(8, 10), 4.6)
	_floor(Vector3(0, 0, -12), Vector2(8, 6), 5.2)
	for side in [-1, 1]:
		_wall(Vector3(side * 8, 0, -5.35), 7.3, 5.5, PI / 2)
		_wall(Vector3(side * 8, 0, 5.35), 7.3, 5.5, PI / 2)
		_arch(Vector3(side * 8, 0, 0), -side * PI / 2, "Library" if side == -1 else "Conservatory")
		_wall(Vector3(side * 12, 0, -5), 8, 4.6)
		_wall(Vector3(side * 12, 0, 5), 8, 4.6)
		_wall(Vector3(side * 16, 0, 0), 10, 4.6, PI / 2)
		_wall(Vector3(side * 4.9, 0, -9), 6.2, 5.5)
		_wall(Vector3(side * 4, 0, -12), 6, 5.2, PI / 2)
	_wall(Vector3(0, 0, 9), 16, 5.5)
	_wall(Vector3(0, 0, -15), 8, 5.2)
	_arch(Vector3(0, 0, -9), 0, "Memorial Chapel")
	# Coffered ceiling and pilasters give the large parlour a human scale.
	for x in [-6, -2, 2, 6]:
		props.box(Vector3(x, 5.34, 0), Vector3(0.18, 0.28, 18), props.mats.wood)
	for z in [-7, -3, 1, 5, 8]:
		props.box(Vector3(0, 5.34, z), Vector3(16, 0.28, 0.18), props.mats.wood)
	for side in [-1, 1]:
		for z in [-7.8, -3.0, 3.0, 7.8]:
			props.box(Vector3(side * 7.76, 2.7, z), Vector3(0.34, 5.2, 0.4), props.mats.wood)
			props.box(Vector3(side * 7.71, 4.95, z), Vector3(0.45, 0.25, 0.55), props.mats.brass)
			props.candle(Vector3(side * 7.5, 2.2, z), 0.25, false)
	for x in [3.0, 5.2, 7.1]:
		_window(Vector3(x, 0, -8.8), 0, 1.5, 3.8)
	_window(Vector3(-15.8, 0, 1.0), PI / 2, 2.6, 3.3)
	_window(Vector3(15.8, 0, 0), -PI / 2, 3.5, 3.6)
	_window(Vector3(0, 0, -14.8), 0, 2.2, 4.2)


func _window(pos: Vector3, angle: float, width: float, height: float) -> void:
	var group = Node3D.new()
	group.position = pos
	group.rotation.y = angle
	add_child(group)
	var glass = props.material("31505d", 0.1, 0.3, 0.5)
	props.box(Vector3(0, 2.9, 0), Vector3(width, height - 1, 0.065), glass, false, group)
	for x in [-width / 2, 0, width / 2]:
		props.box(
			Vector3(x, 2.9, 0.07),
			Vector3(0.085, height - 0.85, 0.14),
			props.mats.trim,
			false,
			group
		)
	for y in [1.1 + (4.0 - height) / 2, 2.6, 4.4 - (4.0 - height) / 2]:
		props.box(
			Vector3(0, y, 0.07), Vector3(width + 0.2, 0.08, 0.14), props.mats.trim, false, group
		)
	for x in [-width / 2 - 0.18, width / 2 + 0.18]:
		var curtain = props.box(
			Vector3(x, 2.85, 0.25), Vector3(0.4, height, 0.17), props.mats.velvet, false, group
		)
		curtain.rotation.z = signf(x) * 0.025
		for k in range(4):
			props.cylinder(
				Vector3(x - 0.15 + k * 0.1, 2.85, 0.36), 0.04, height, props.mats.velvet, -1, group
			)
	var p = pos + Vector3(sin(angle) * 1.5, 2.8, cos(angle) * 1.5)
	props.light(p, Color("83bbd4"), 2.3, 8.5)


func _build_parlour() -> void:
	var carpet_mat = StandardMaterial3D.new()
	carpet_mat.albedo_texture = load("res://assets/rug.svg")
	carpet_mat.roughness = 1
	var carpet = PlaneMesh.new()
	carpet.size = Vector2(8.3, 10.0)
	props.mesh_at(carpet, Vector3(0, 0.055, 0), carpet_mat)
	# Round walnut table, brass edging, etched green spirit board.
	props.cylinder(Vector3(0, 0.89, 0), 2.38, 0.19, props.mats.wood)
	props.ring(Vector3(0, 0.94, 0), 2.37, 0.027, props.mats.brass)
	props.cylinder(Vector3(0, 0.45, 0), 0.48, 0.74, props.mats.wood, 0.35)
	props.cylinder(Vector3(0, 0.12, 0), 1.02, 0.12, props.mats.wood, 0.75)
	var board = StandardMaterial3D.new()
	board.albedo_texture = load("res://assets/spirit_board.svg")
	board.roughness = 0.63
	var disk = PlaneMesh.new()
	disk.size = Vector2(4.43, 4.43)
	board.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	props.mesh_at(disk, Vector3(0, 0.991, 0), board)
	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = 2.38
	cylinder_shape.height = 1.05
	shape.shape = cylinder_shape
	body.position.y = 0.48
	body.add_child(shape)
	add_child(body)
	for role in CaseData.ROLES:
		var seat: Vector3 = CaseData.SEATS[role]
		props.chair(seat * 0.9, atan2(seat.x, seat.z))
	for i in range(6):
		var a = i * TAU / 6 + PI / 6
		props.candle(Vector3(cos(a) * 1.82, 1.0, sin(a) * 1.82), 0.21 + (i % 3) * 0.07)
	props.light(Vector3(0, 2.6, 0), Color("f6ba77"), 2.1, 7.5, true)
	spirit_light = props.light(Vector3(0, 2.3, -1), Color("6acac2"), 0.0, 8)
	_build_chandelier()
	_build_fireplace()
	props.table(Vector3(5.8, 0, -5.4), Vector2(2.2, 0.8))
	props.candle(Vector3(6.5, 0.98, -5.4), 0.4, true)
	props.plant(Vector3(-6.5, 0, 6.8), 2.0)
	props.plant(Vector3(6.7, 0, 6.8), 1.7)
	# The locked front door, with long brass handles and an Ashwood crest.
	for x in [-0.68, 0.68]:
		props.box(Vector3(x, 1.65, 8.8), Vector3(1.32, 3.3, 0.12), props.mats.wood)
		props.box(Vector3(x * 0.2, 1.5, 8.69), Vector3(0.035, 0.4, 0.05), props.mats.brass)
		for y in [0.85, 2.35]:
			props.box(Vector3(x, y, 8.71), Vector3(1.1, 1.23, 0.06), props.mats.trim)


func _build_chandelier() -> void:
	props.cylinder(Vector3(0, 4.85, 0), 0.035, 1.2, props.mats.iron)
	props.sphere(Vector3(0, 4.2, 0), 0.14, props.mats.brass, 1.5)
	props.ring(Vector3(0, 3.98, 0), 1.32, 0.035, props.mats.brass)
	props.ring(Vector3(0, 4.04, 0), 1.28, 0.023, props.mats.dark_brass)
	for i in range(8):
		var a = i * TAU / 8
		props.candle(Vector3(cos(a) * 1.31, 3.97, sin(a) * 1.31), 0.28)
		var beam = props.box(
			Vector3(cos(a) * 0.66, 4.02, sin(a) * 0.66),
			Vector3(1.32, 0.035, 0.035),
			props.mats.brass
		)
		beam.rotation.y = -a
		props.sphere(Vector3(cos(a) * 1.29, 3.84, sin(a) * 1.29), 0.04, props.mats.brass, 2.0)
	props.light(Vector3(0, 3.8, 0), Color("ffd7a5"), 2.8, 9)


func _build_fireplace() -> void:
	var p = Vector3(-5.15, 0, -8.4)
	props.box(p + Vector3(0, 0.82, 0), Vector3(3.25, 1.65, 0.7), props.mats.iron)
	for x in [-1.46, 1.46]:
		props.box(p + Vector3(x, 0.9, 0.4), Vector3(0.36, 1.8, 0.55), props.mats.marble, true)
		props.box(p + Vector3(x, 0.12, 0.5), Vector3(0.49, 0.24, 0.7), props.mats.stone)
	props.box(p + Vector3(0, 1.8, 0.42), Vector3(3.7, 0.23, 0.9), props.mats.marble)
	props.box(p + Vector3(0, 0.07, 0.55), Vector3(3.9, 0.12, 1.35), props.mats.marble)
	for i in range(5):
		var log_node = props.cylinder(
			p + Vector3(-0.7 + i * 0.35, 0.23, 0.5), 0.12, 0.9, props.mats.wood
		)
		log_node.rotation.x = PI / 2
		var fire = props.sphere(
			p + Vector3(-0.7 + i * 0.34, 0.47, 0.53), 0.095, props.mats.flame, 2.7
		)
		props.flames.append({"node": fire, "y": fire.position.y, "seed": i})
	props.light(p + Vector3(0, 0.9, 1.0), Color("ff9e4a"), 4.8, 8, true)
	_portrait(p + Vector3(0, 3.5, 0.05), Vector2(1.7, 2.45))
	props.candle(p + Vector3(-1.4, 1.93, 0.4), 0.4)
	props.candle(p + Vector3(1.4, 1.93, 0.4), 0.34)


func _portrait(pos: Vector3, dimensions: Vector2) -> void:
	var painting = StandardMaterial3D.new()
	painting.albedo_texture = load("res://assets/art/lord_ashwood.png")
	painting.roughness = 0.78
	painting.emission_enabled = true
	painting.emission_texture = painting.albedo_texture
	painting.emission = Color.WHITE
	painting.emission_energy_multiplier = 0.12
	var canvas = QuadMesh.new()
	canvas.size = dimensions
	props.mesh_at(canvas, pos + Vector3(0, 0, 0.06), painting)
	for x in [-1, 1]:
		props.box(
			pos + Vector3(x * (dimensions.x / 2 + 0.075), 0, 0.04),
			Vector3(0.16, dimensions.y + 0.29, 0.17),
			props.mats.brass
		)
		props.box(
			pos + Vector3(x * (dimensions.x / 2 + 0.13), 0, 0.11),
			Vector3(0.028, dimensions.y + 0.32, 0.04),
			props.mats.dark_brass
		)
	for y in [-1, 1]:
		props.box(
			pos + Vector3(0, y * (dimensions.y / 2 + 0.075), 0.04),
			Vector3(dimensions.x + 0.3, 0.16, 0.17),
			props.mats.brass
		)


func _build_library() -> void:
	for x in [-10.0, -12.6, -15.0]:
		props.bookshelf(Vector3(x, 0, -4.65), 2.1)
	props.table(Vector3(-12, 0, -2.9), Vector2(3.4, 1.15))
	props.table(Vector3(-13.5, 0, 2.8), Vector2(2.4, 1.0))
	props.table(Vector3(-10.2, 0, 0), Vector2(0.8, 0.8))
	props.candle(Vector3(-12.8, 0.98, -2.9), 0.37, true)
	props.candle(Vector3(-13.7, 0.98, 2.8), 0.24, true)
	props.chair(Vector3(-12, 0, -1.8), 0)
	props.book(Vector3(-11.2, 1.04, -3.0), Vector3(0.35, 0.12, 0.47), "243d34", -0.15)
	props.box(Vector3(-13.7, 1.2, -3), Vector3(0.65, 0.45, 0.35), props.mats.wood)
	for x in [-13.9, -13.5]:
		var knob = props.cylinder(Vector3(x, 1.15, -2.79), 0.065, 0.05, props.mats.brass)
		knob.rotation.x = PI / 2
	props.box(Vector3(-13.7, 1.3, -2.81), Vector3(0.45, 0.065, 0.025), props.mats.blue)
	props.light(Vector3(-11.8, 3.5, 0), Color("e1b784"), 2.3, 8)


func _build_conservatory() -> void:
	props.table(Vector3(12, 0, -2.8), Vector2(3.1, 1.15))
	props.table(Vector3(13.2, -0.18, 2.4), Vector2(2.4, 0.85))
	props.table(Vector3(10.3, 0, 0), Vector2(0.85, 1.2))
	props.table(Vector3(12, 0, -1.5), Vector2(0.7, 0.6))
	for p in [Vector3(15, 0, -3.8), Vector3(15, 0, 3.7), Vector3(9.4, 0, 3.8), Vector3(10, 0, -4)]:
		props.plant(p, 1.8)
	props.candle(Vector3(12.8, 0.99, -2.8), 0.33, true)
	props.candle(Vector3(13.5, 0.8, 2.4), 0.28, true)
	props.light(Vector3(12.5, 3.2, 0), Color("a6c9bc"), 2.1, 7)
	for i in range(6):
		props.cylinder(
			Vector3(11.0 + i * 0.16, 1.1, -3.02),
			0.045,
			0.26,
			props.material(["435951", "756443", "4b364f"][i % 3]),
			0.02
		)


func _build_chapel() -> void:
	props.table(Vector3(-2.7, 0, -12), Vector2(1.2, 1.1))
	props.table(Vector3(2.7, 0, -12), Vector2(1.2, 1.1))
	props.table(Vector3(0, 0, -13.4), Vector2(3.1, 1.1))
	props.box(Vector3(0, 0.65, -11.9), Vector3(0.8, 1.3, 0.75), props.mats.wood, true)
	props.box(Vector3(0, 1.16, -11.9), Vector3(0.83, 0.12, 0.78), props.mats.brass)
	for x in [-2.7, 2.7]:
		props.candle(Vector3(x + 0.25, 0.98, -12), 0.37, true)
	for x in [-1.1, 1.1]:
		props.candle(Vector3(x, 1.0, -13.4), 0.42)
	props.light(Vector3(0, 3.6, -12), Color("a2bac1"), 1.8, 7)


func _build_objects() -> void:
	for id in CaseData.CLUES:
		var data = CaseData.CLUES[id]
		var p: Vector3 = data.pos
		var group = Node3D.new()
		group.name = "Clue_" + id
		add_child(group)
		match data.kind:
			"document":
				var page = props.box(p, Vector3(0.37, 0.009, 0.47), props.mats.paper, false, group)
				page.rotation.y = -0.12
				for i in range(8):
					props.box(
						p + Vector3(0, 0.007, -0.16 + i * 0.037),
						Vector3(0.25 - (i % 3) * 0.025, 0.003, 0.004),
						props.mats.trim,
						false,
						group
					)
			"bottle":
				props.cylinder(
					p + Vector3(0, 0.12, 0), 0.07, 0.22, props.material("576865"), 0.05, group
				)
				props.cylinder(p + Vector3(0, 0.26, 0), 0.026, 0.1, props.mats.brass, -1, group)
			"watch":
				props.cylinder(p, 0.1, 0.035, props.mats.brass, -1, group)
				props.cylinder(p + Vector3(0, 0.021, 0), 0.084, 0.01, props.mats.paper, -1, group)
				props.box(
					p + Vector3(0.025, 0.03, 0),
					Vector3(0.06, 0.005, 0.006),
					props.mats.iron,
					false,
					group
				)
			"flower":
				props.box(p, Vector3(0.3, 0.012, 0.38), props.mats.paper, false, group)
				for k in range(3):
					props.sphere(
						p + Vector3(k * 0.06 - 0.06, 0.03, 0),
						0.045,
						props.material("695775"),
						0.4,
						group
					)
			_:
				props.box(p, Vector3(0.36, 0.065, 0.45), props.mats.paper, false, group)
				props.box(
					p + Vector3(0, 0.04, 0),
					Vector3(0.39, 0.016, 0.47),
					props.mats.velvet,
					false,
					group
				)
		_target(id, p, group)
	for id in CaseData.ITEMS:
		var p: Vector3 = CaseData.ITEMS[id].pos
		var group = Node3D.new()
		add_child(group)
		match id:
			"ring":
				props.box(
					p - Vector3(0, 0.035, 0),
					Vector3(0.22, 0.07, 0.22),
					props.mats.velvet,
					false,
					group
				)
				props.ring(p + Vector3(0, 0.03, 0), 0.055, 0.013, props.mats.brass, group)
				props.box(
					p + Vector3(0, 0.035, -0.05),
					Vector3(0.055, 0.027, 0.03),
					props.mats.brass,
					false,
					group
				)
			"locket":
				props.ring(p, 0.12, 0.006, props.mats.brass, group)
				props.sphere(p + Vector3(0, 0.02, 0.1), 0.043, props.mats.brass, 0.35, group)
			"key":
				props.ring(p, 0.04, 0.008, props.mats.brass, group)
				props.box(
					p + Vector3(0.075, 0, 0),
					Vector3(0.1, 0.017, 0.017),
					props.mats.brass,
					false,
					group
				)
				props.box(
					p + Vector3(0.11, 0, 0.015),
					Vector3(0.019, 0.019, 0.044),
					props.mats.brass,
					false,
					group
				)
		_target(id, p, group)
	for id in CaseData.TASKS:
		_target(id, CaseData.TASKS[id].pos, null, 0.35 if id != "candles" else 2.4)


func _target(id: String, pos: Vector3, visual: Node3D, radius: float = 0.23) -> void:
	var area = Area3D.new()
	area.position = pos + Vector3(0, 0.09, 0)
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("interact_id", id)
	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius
	shape.shape = sphere_shape
	area.add_child(shape)
	add_child(area)
	targets[id] = {"area": area, "visual": visual}


func _build_dust() -> void:
	dust = GPUParticles3D.new()
	dust.amount = 160
	dust.lifetime = 22
	dust.preprocess = 22
	dust.visibility_aabb = AABB(Vector3(-16, 0, -15), Vector3(32, 6, 24))
	var process = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(7, 2.5, 8)
	process.gravity = Vector3(0.008, 0.008, -0.006)
	process.initial_velocity_min = 0.006
	process.initial_velocity_max = 0.02
	process.scale_min = 0.006
	process.scale_max = 0.018
	process.color = Color(0.75, 0.69, 0.51, 0.3)
	dust.process_material = process
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.radial_segments = 4
	mesh.rings = 2
	dust.draw_pass_1 = mesh
	dust.material_override = props.material("c1baa0", 0, 1, 0.25)
	dust.position.y = 2.6
	add_child(dust)


func sync(view: Dictionary) -> void:
	for id in targets:
		var available = true
		if view.get("evidence", {}).has(id):
			available = view.evidence[id].holder == "" and not view.evidence[id].destroyed
		elif view.get("items", {}).has(id):
			available = view.items[id] == ""
		elif view.get("tasks", {}).has(id):
			available = view.tasks[id] == ""
		targets[id].area.collision_layer = 2 if available else 0
		if targets[id].visual:
			targets[id].visual.visible = available


func _process(delta: float) -> void:
	time += delta
	var haunted = Session.active and Session.view.get("phase", "") in ["seance", "judgment"]
	props.tick(time, haunted)
	atmosphere.tick(delta, Session.view)
	spirit_light.light_energy = lerpf(
		spirit_light.light_energy, 3.4 if haunted else 0.15, delta * 1.5
	)
