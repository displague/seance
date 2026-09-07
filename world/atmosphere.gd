class_name ManorAtmosphere
extends RefCounted
## Render public host events; reduced-flash/gore preferences never change rules.

var manor: Node3D
var walls: Dictionary = {}
var fades: Dictionary = {}
var last_storm = 0
var last_haunt = 0
var last_manifest = 0
var last_phase = ""
var pulse = 0.0
var thunder_pending = -1.0


func _init(owner_manor: Node3D) -> void:
	manor = owner_manor
	var positions = [
		Vector3(4.7, 2.65, 8.81),
		Vector3(-12, 2.65, 4.81),
		Vector3(12, 2.65, 4.81),
		Vector3(0, 2.9, -14.81)
	]
	for i in range(HauntRules.ROOMS.size()):
		var room = HauntRules.ROOMS[i]
		var wall = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(5.8, 2.7)
		wall.mesh = quad
		wall.position = positions[i]
		wall.rotation.y = PI if i != 3 else 0.0
		var material = ShaderMaterial.new()
		material.shader = load("res://shaders/weeping_wall.gdshader")
		wall.material_override = material
		wall.visible = false
		manor.add_child(wall)
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0
		area.set_meta("interact_id", "haunt:" + room)
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(5.8, 2.7, 0.06)
		shape.shape = box
		area.add_child(shape)
		wall.add_child(area)
		walls[room] = {"mesh": wall, "material": material, "area": area}
		fades[room] = 0.0


func tick(delta: float, view: Dictionary) -> void:
	var haunt: Dictionary = view.get("haunt", HauntRules.initial())
	var playing = Session.active and view.get("phase", "ended") != "ended"
	var room = str(haunt.room) if playing else ""
	var kind = str(haunt.kind) if playing else ""
	if not playing:
		last_storm = 0
		last_haunt = 0
		last_manifest = 0
		last_phase = ""
		thunder_pending = -1
	if playing and int(haunt.storm_id) != last_storm:
		last_storm = haunt.storm_id
		if haunt.storm_age < 2.0:
			thunder_pending = 1.2
	if playing and int(haunt.id) != last_haunt:
		last_haunt = haunt.id
		if kind != "":
			Sound.play("breeze", -12)
			Controls.rumble(0.2, 0.12, 0.6)
	if playing and (int(view.get("manifest", 0)) != last_manifest or str(view.phase) != last_phase):
		last_manifest = int(view.get("manifest", 0))
		last_phase = view.phase
		pulse = 1.0
		Controls.rumble(0.25, 0.15, 0.35)
	pulse = move_toward(pulse, 0, delta * 0.7)
	if thunder_pending >= 0:
		thunder_pending -= delta
		if thunder_pending < 0:
			Sound.play("thunder", -13)
			Controls.rumble(0.12, 0.25, 0.5)
	var flash = 0.0
	if playing and not Session.settings.reduced_flashes:
		flash = maxf(0, 1.0 - float(haunt.storm_age) / 0.65)
	manor.moon.light_energy = 0.65 + flash * 1.2
	manor.environment.ambient_light_energy = (
		0.48 - pulse * (0.03 if Session.settings.reduced_flashes else 0.12)
	)
	for name in walls:
		var active_room = name == room and kind != ""
		fades[name] = move_toward(fades[name], 1.0 if active_room else 0.0, delta * 0.8)
		var wall = walls[name]
		wall.mesh.visible = fades[name] > 0.001
		wall.area.collision_layer = 2 if active_room else 0
		wall.material.set_shader_parameter(
			"intensity", fades[name] * (1.0 if kind == "weep" else 0.35)
		)
		wall.material.set_shader_parameter("age", HauntRules.DURATION - float(haunt.remaining))
		wall.material.set_shader_parameter("blood", Session.settings.blood_effects)
	for lamp in manor.props.lamps:
		var fade = float(fades.get(CaseData.room_at(lamp.node.global_position), 0.0))
		lamp.node.light_energy *= 1.0 - fade * 0.94
	for flame in manor.props.flames:
		var fade = float(fades.get(CaseData.room_at(flame.node.global_position), 0.0))
		flame.node.visible = fade < 0.85
