class_name SeanceCharacters
extends Node3D
## Presentation only. Host positions drive humans and active solo guests;
## authored rehearsal guests use stage marks.

var figures: Dictionary = {}
var props: ManorProps
var time = 0.0
var ghost_material: ShaderMaterial
var animations: Dictionary = {}
var last_stage = ""
var equipped: Dictionary = {}


func _ready() -> void:
	props = ManorProps.new(self)
	ghost_material = ShaderMaterial.new()
	ghost_material.shader = load("res://shaders/ghost.gdshader")
	for role in CaseData.ROLES:
		var figure = Node3D.new()
		figure.name = role
		add_child(figure)
		var rig = _load_character(role, figure)
		if rig == null:
			_build_figure(role, figure)
		figure.position = CaseData.SEATS[role] * 1.22
		figure.rotation.y = atan2(figure.position.x, figure.position.z)
		var title = Label3D.new()
		title.text = CaseData.person(role).name
		title.font_size = 36
		title.pixel_size = 0.0025
		title.position.y = 2.2
		title.modulate = Color(CaseData.person(role).color)
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.no_depth_test = false
		title.outline_size = 5
		title.visible = false
		figure.add_child(title)
		var area = Area3D.new()
		area.position.y = 1.0
		area.collision_layer = 2
		area.collision_mask = 0
		area.set_meta("interact_id", "person:" + role)
		var shape = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.35
		capsule.height = 1.8
		shape.shape = capsule
		area.add_child(shape)
		figure.add_child(area)
		figures[role] = {
			"root": figure, "target": figure.position, "rig": rig, "title": title, "area": area
		}
		if role == "ghost":
			var glow = OmniLight3D.new()
			glow.name = "SpiritGlow"
			glow.position.y = 1.2
			glow.light_color = Color("86dccf")
			glow.light_energy = 1.6
			glow.omni_range = 5
			figure.add_child(glow)


func _load_character(role: String, parent: Node3D) -> Node3D:
	var choice = AppearanceData.normalize(role, equipped.get(role, {}))
	equipped[role] = choice
	var instance = AvatarFactory.create(role, choice)
	if instance == null:
		return null
	parent.add_child(instance)
	animations[role] = AvatarFactory.finish(instance, role, choice)
	return instance


func _build_figure(role: String, parent: Node3D) -> void:
	var ghost = role == "ghost"
	var suit = props.material("172124", 0, 0.83)
	var accent = props.material(CaseData.person(role).color, 0, 0.86)
	var skin = props.material("b59c83", 0, 0.93)
	var hair = props.material("262220", 0, 0.9)
	if ghost:
		suit = ghost_material
		accent = ghost_material
		skin = ghost_material
		hair = ghost_material
	# Tailored, faceted stand-ins are retained as a safe missing-asset fallback.
	props.cylinder(Vector3(0, 1.13, 0), 0.2, 0.63, suit, 0.27, parent)
	props.box(Vector3(0, 1.18, -0.171), Vector3(0.18, 0.42, 0.06), accent, false, parent)
	props.cylinder(Vector3(0, 1.51, 0), 0.064, 0.15, skin, -1, parent)
	props.sphere(Vector3(0, 1.69, 0), 0.14, skin, 1.27, parent)
	props.sphere(Vector3(0, 1.78, 0.014), 0.142, hair, 0.8, parent)
	props.sphere(Vector3(0, 1.67, -0.14), 0.025, skin, 1.4, parent)
	for x in [-0.075, 0.075]:
		props.sphere(Vector3(x, 1.73, -0.123), 0.012, props.mats.iron, 0.55, parent)
	for side in [-1, 1]:
		props.cylinder(Vector3(side * 0.11, 0.49, 0), 0.079, 0.79, suit, 0.091, parent)
		props.box(
			Vector3(side * 0.11, 0.085, -0.06), Vector3(0.16, 0.14, 0.31), suit, false, parent
		)
		var arm = props.cylinder(Vector3(side * 0.3, 1.1, 0), 0.069, 0.57, suit, 0.086, parent)
		arm.rotation.z = side * 0.13
		props.sphere(Vector3(side * 0.337, 0.78, -0.01), 0.064, skin, 1.3, parent)
	for y in [1.05, 1.17, 1.29]:
		props.sphere(Vector3(0, y, -0.208), 0.016, props.mats.brass, 1, parent)


func sync(view: Dictionary) -> void:
	var stage = str(view.get("phase", "")) + str(view.get("round", 0))
	var stage_changed = stage != last_stage
	last_stage = stage
	for role in figures:
		var figure = figures[role]
		var appearance = AppearanceData.normalize(role, view.get("appearances", {}).get(role, {}))
		if appearance != equipped.get(role, {}):
			equipped[role] = appearance
			if is_instance_valid(figure.rig):
				figure.rig.free()
			figure.rig = _load_character(role, figure.root)
		figure.root.visible = not Session.active or role != Session.local_role
		figure.area.collision_layer = 2 if figure.root.visible else 0
		figure.title.visible = Session.active
		if view.is_empty():
			continue
		var human = view.get("humans", []).has(role)
		if human or view.get("interactive_guests", false):
			figure.target = view.positions.get(role, CaseData.SEATS[role])
		elif view.phase in ["seance", "judgment", "ended"]:
			figure.target = CaseData.SEATS[role] * 1.22
		else:
			var spots = {
				"medium": Vector3(2.7, 0, 4.8),
				"heir": Vector3(-10.2, 0, 1.7),
				"widow": Vector3(11, 0, 2),
				"doctor": Vector3(5, 0, -3),
				"keeper": Vector3(-1.8, 0, -10.5),
				"ghost": Vector3(0, 0, -3.4)
			}
			figure.target = spots[role]
		if not human and stage_changed:
			# Scripted guests take stage marks during the phase transition.
			# They do not slide through the walls pretending to navigate.
			figure.root.position = figure.target
			figure.root.rotation.y = atan2(figure.target.x, figure.target.z)


func _process(delta: float) -> void:
	time += delta
	for role in figures:
		var figure = figures[role]
		var target: Vector3 = figure.target
		if role == "ghost":
			target.y = 0.28 + sin(time * 1.2) * 0.09
		var current: Vector3 = figure.root.position
		figure.root.position = current.lerp(target, minf(1, delta * 3))
		var displacement: Vector3 = figure.root.position - current
		displacement.y = 0
		CharacterMotion.update(animations.get(role), displacement.length() / maxf(delta, 0.001))
		# Bots move between stage marks only on phase transitions; no pretend AI.
		if Vector2(target.x - current.x, target.z - current.z).length() > 0.1:
			var direction = target - current
			figure.root.rotation.y = lerp_angle(
				figure.root.rotation.y, atan2(-direction.x, -direction.z), delta * 3
			)
