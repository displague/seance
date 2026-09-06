class_name SeancePlayer
extends CharacterBody3D

signal interacted(id: String)
signal target_changed(id: String)

var camera: Camera3D
var lantern: SpotLight3D
var enabled = false
var target_id = ""
var move_clock = 0.0
var foot_clock = 0.0
var bob = 0.0
var pitch = 0.0


func _ready() -> void:
	name = "LocalPlayer"
	collision_layer = 4
	collision_mask = 1
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.72
	shape.shape = capsule
	shape.position.y = 0.86
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 74
	camera.near = 0.05
	camera.far = 70
	add_child(camera)
	lantern = SpotLight3D.new()
	lantern.position = Vector3(0.2, -0.18, -0.25)
	lantern.light_color = Color("eac393")
	lantern.light_energy = 2.8
	lantern.spot_range = 9.0
	lantern.spot_angle = 44
	lantern.spot_angle_attenuation = 0.55
	lantern.visible = true
	camera.add_child(lantern)


func set_control(value: bool) -> void:
	enabled = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	if not value:
		velocity = Vector3.ZERO


func place(pos: Vector3, face_table: bool = true) -> void:
	position = pos
	position.y = 0.06
	velocity = Vector3.ZERO
	if face_table:
		rotation.y = atan2(pos.x, pos.z)
		pitch = -0.07
		camera.rotation.x = pitch


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * float(Session.settings.sensitivity)
		pitch = clampf(pitch - event.relative.y * float(Session.settings.sensitivity), -1.25, 1.2)
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and target_id != "":
			interacted.emit(target_id)
		if event.physical_keycode == KEY_F:
			lantern.visible = not lantern.visible


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var input = Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	input = input.normalized()
	var speed = 5.3 if Input.is_physical_key_pressed(KEY_SHIFT) else 3.2
	var direction = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 20)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 20)
	velocity.y -= 16 * delta
	if is_on_floor():
		velocity.y = -0.5
	move_and_slide()
	if position.y < -3:
		# Recover to the last server-accepted ground position, not an unrelated
		# teleport that the host movement budget would reject indefinitely.
		place(Session.view.positions.get(Session.local_role, CaseData.spawn_at(Session.local_role)))
	var moving = Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		bob += delta * (10 if speed > 4 else 7)
		foot_clock += delta
		if foot_clock > (0.36 if speed > 4 else 0.5):
			foot_clock = 0
			Sound.play("step", -11)
	var bob_amount = 0.022 if Session.settings.motion and moving else 0.0
	camera.position.y = lerpf(camera.position.y, 1.65 + sin(bob) * bob_amount, delta * 12)
	move_clock += delta
	if move_clock >= 0.08:
		move_clock = 0
		Session.move_local(Vector3(position.x, 0, position.z))
	_find_target()


func _find_target() -> void:
	var origin = camera.global_position
	var end = origin - camera.global_basis.z * 3.8
	var query = PhysicsRayQueryParameters3D.create(origin, end, 3)
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	var id = ""
	if hit.has("collider") and hit.collider.has_meta("interact_id"):
		id = hit.collider.get_meta("interact_id")
	if id != target_id:
		target_id = id
		target_changed.emit(id)
