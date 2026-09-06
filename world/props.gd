class_name ManorProps
extends RefCounted
## Small composable geometry functions. All dimensions are in metres.

var root: Node3D
var mats: Dictionary = {}
var flames: Array = []
var lamps: Array = []


func _init(parent: Node3D) -> void:
	root = parent
	mats.wood = ShaderMaterial.new()
	mats.wood.shader = load("res://shaders/wood.gdshader")
	mats.wood.set_shader_parameter("base_color", Color("38251d"))
	mats.floor = ShaderMaterial.new()
	mats.floor.shader = mats.wood.shader
	mats.floor.set_shader_parameter("base_color", Color("594033"))
	mats.brass = material("9c7950", 0.67, 0.3)
	mats.dark_brass = material("59452e", 0.65, 0.45)
	mats.wall = material("27312e", 0.0, 0.86)
	mats.trim = material("33271f", 0.0, 0.56)
	mats.velvet = material("441e25", 0, 0.93)
	mats.teal = material("254d48", 0, 0.8)
	mats.paper = material("c4b99c", 0, 0.9)
	mats.wax = material("dec79e", 0, 0.7)
	mats.iron = material("111416", 0.5, 0.45)
	mats.stone = material("737068", 0, 0.89)
	mats.marble = material("343d3a", 0.1, 0.35)
	mats.flame = material("ffcf75", 0, 0.2, 5.0)
	mats.blue = material("65cbd3", 0.1, 0.25, 2.0)


func material(
	hex: String, metal: float = 0, rough: float = 0.6, glow: float = 0
) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.metallic = metal
	m.roughness = rough
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = glow
	return m


func box(
	pos: Vector3, size: Vector3, mat: Material, collision: bool = false, parent: Node3D = null
) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var node = mesh_at(mesh, pos, mat, parent)
	if collision:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var geometry = BoxShape3D.new()
		geometry.size = size
		shape.shape = geometry
		body.add_child(shape)
		node.add_child(body)
	return node


func mesh_at(mesh: Mesh, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	(parent if parent else root).add_child(node)
	return node


func cylinder(
	pos: Vector3,
	radius: float,
	height: float,
	mat: Material,
	top: float = -1,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 24
	return mesh_at(mesh, pos, mat, parent)


func sphere(
	pos: Vector3, radius: float, mat: Material, scale_y: float = 1.0, parent: Node3D = null
) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 20
	mesh.rings = 12
	var node = mesh_at(mesh, pos, mat, parent)
	node.scale.y = scale_y
	return node


func ring(
	pos: Vector3, radius: float, thickness: float, mat: Material, parent: Node3D = null
) -> MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 48
	mesh.ring_segments = 8
	return mesh_at(mesh, pos, mat, parent)


func light(
	pos: Vector3, color: Color, energy: float, radius: float, shadows: bool = false
) -> OmniLight3D:
	var node = OmniLight3D.new()
	node.position = pos
	node.light_color = color
	node.light_energy = energy
	node.omni_range = radius
	node.omni_attenuation = 1.3
	node.shadow_enabled = shadows
	node.shadow_blur = 2
	root.add_child(node)
	return node


func candle(pos: Vector3, tall: float = 0.3, with_light: bool = false) -> void:
	cylinder(pos + Vector3(0, 0.035, 0), 0.11, 0.07, mats.brass)
	cylinder(pos + Vector3(0, 0.14, 0), 0.035, 0.19, mats.brass, 0.025)
	cylinder(pos + Vector3(0, 0.25, 0), 0.075, 0.04, mats.brass)
	cylinder(pos + Vector3(0, 0.27 + tall / 2, 0), 0.044, tall, mats.wax)
	var flame = sphere(pos + Vector3(0, 0.31 + tall, 0), 0.028, mats.flame, 2.7)
	flames.append({"node": flame, "y": flame.position.y, "seed": pos.x * 3 + pos.z})
	if with_light:
		var lamp = light(pos + Vector3(0, tall + 0.4, 0), Color("ffbb72"), 1.8, 5.2)
		lamps.append({"node": lamp, "energy": 1.8, "seed": pos.x + pos.z})


func table(pos: Vector3, size: Vector2 = Vector2(2.5, 1.2)) -> void:
	box(pos + Vector3(0, 0.9, 0), Vector3(size.x, 0.14, size.y), mats.wood, true)
	box(pos + Vector3(0, 0.76, 0), Vector3(size.x - 0.1, 0.2, size.y - 0.1), mats.trim)
	for x in [-1, 1]:
		for z in [-1, 1]:
			var p = pos + Vector3(x * (size.x / 2 - 0.15), 0.39, z * (size.y / 2 - 0.15))
			cylinder(p, 0.055, 0.72, mats.wood, 0.085)
			cylinder(p + Vector3(0, 0.24, 0), 0.098, 0.12, mats.wood)
			cylinder(p - Vector3(0, 0.3, 0), 0.065, 0.08, mats.brass)


func chair(pos: Vector3, facing: float) -> Node3D:
	var group = Node3D.new()
	group.position = pos
	group.rotation.y = facing
	root.add_child(group)
	box(Vector3(0, 0.47, 0), Vector3(0.64, 0.12, 0.65), mats.wood, false, group)
	box(Vector3(0, 0.55, -0.01), Vector3(0.56, 0.085, 0.55), mats.velvet, false, group)
	for x in [-0.25, 0.25]:
		for z in [-0.25, 0.25]:
			cylinder(Vector3(x, 0.24, z), 0.037, 0.46, mats.wood, 0.047, group)
		box(Vector3(x, 0.94, 0.27), Vector3(0.065, 0.95, 0.075), mats.wood, false, group)
		sphere(Vector3(x, 1.43, 0.27), 0.05, mats.brass, 1, group)
	box(Vector3(0, 1.01, 0.285), Vector3(0.45, 0.59, 0.07), mats.velvet, false, group)
	box(Vector3(0, 1.34, 0.27), Vector3(0.56, 0.09, 0.1), mats.wood, false, group)
	for x in [-0.13, 0, 0.13]:
		sphere(Vector3(x, 1.09, 0.237), 0.012, mats.brass, 1, group)
	return group


func book(pos: Vector3, size: Vector3, color: String = "4b242a", angle: float = 0) -> void:
	var group = Node3D.new()
	group.position = pos
	group.rotation.y = angle
	root.add_child(group)
	var leather = material(color, 0, 0.8)
	box(Vector3.ZERO, size, mats.paper, false, group)
	for y in [-1, 1]:
		box(
			Vector3(0, y * size.y / 2, 0),
			Vector3(size.x + 0.015, 0.014, size.z + 0.012),
			leather,
			false,
			group
		)
	box(Vector3(-size.x / 2, 0, 0), Vector3(0.018, size.y, size.z), leather, false, group)
	for z in [-0.35, 0.35]:
		box(
			Vector3(-size.x / 2 - 0.011, 0, size.z * z),
			Vector3(0.004, size.y + 0.005, 0.016),
			mats.brass,
			false,
			group
		)


func bookshelf(pos: Vector3, width: float = 2.3) -> void:
	box(pos + Vector3(0, 1.5, 0), Vector3(width, 3, 0.42), mats.wood, true)
	box(pos + Vector3(0, 1.5, 0.23), Vector3(width - 0.15, 2.85, 0.025), mats.trim)
	for y in [0.15, 0.8, 1.45, 2.1, 2.75, 3.03]:
		box(pos + Vector3(0, y, 0.12), Vector3(width + 0.05, 0.075, 0.6), mats.wood)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(absf(pos.x * 173 + pos.z * 913))
	var colors = ["48352a", "233b35", "452027", "695338", "26303b", "635c49"]
	for row in range(4):
		var x = -width / 2 + 0.12
		while x < width / 2 - 0.12:
			var w = rng.randf_range(0.07, 0.15)
			var h = rng.randf_range(0.33, 0.51)
			box(
				pos + Vector3(x, 0.23 + row * 0.65 + h / 2, 0.31),
				Vector3(w - 0.01, h, 0.31),
				material(colors[rng.randi_range(0, 5)])
			)
			for off in [-0.3, 0.3]:
				box(
					pos + Vector3(x, 0.23 + row * 0.65 + h / 2 + off * h, 0.469),
					Vector3(w * 0.6, 0.012, 0.005),
					mats.dark_brass
				)
			x += w


func plant(pos: Vector3, height: float = 1.5) -> void:
	cylinder(pos + Vector3(0, 0.25, 0), 0.18, 0.5, mats.stone, 0.28)
	cylinder(pos + Vector3(0, height / 2 + 0.3, 0), 0.023, height, mats.wood, 0.015)
	var leaf_mat = material("263f2b", 0, 0.84)
	for i in range(9):
		var angle = i * 2.4
		var y = 0.65 + i * height / 11
		var leaf = sphere(
			pos + Vector3(cos(angle) * 0.19, y, sin(angle) * 0.19), 0.16, leaf_mat, 2.1
		)
		leaf.rotation.z = -cos(angle) * 0.8
		leaf.rotation.x = sin(angle) * 0.8
		leaf.scale.z = 0.3


func tick(time: float, haunted: bool) -> void:
	for flame in flames:
		flame.node.scale.x = 0.85 + sin(time * 11 + flame.seed) * 0.15
		flame.node.position.y = flame.y + sin(time * 8 + flame.seed) * 0.007
	for lamp in lamps:
		lamp.node.light_energy = lamp.energy * (0.91 + sin(time * 5 + lamp.seed) * 0.07)
		if haunted:
			lamp.node.light_color = Color("77c4b3")
		else:
			lamp.node.light_color = Color("ffbb72")
