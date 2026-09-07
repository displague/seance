class_name AvatarFactory
extends RefCounted
## One factory for world, wardrobe and portraits: never a mismatched stock face.


static func create(role: String, appearance: Dictionary) -> Node3D:
	var model = AppearanceData.model(role, appearance)
	var path = "res://assets/models/" + model + "/character.glb"
	if model == "" or not ResourceLoader.exists(path):
		return null
	var scene = load(path) as PackedScene
	if scene == null:
		return null
	var instance = scene.instantiate() as Node3D
	instance.set_meta("appearance", AppearanceData.normalize(role, appearance))
	instance.set_meta("model", model)
	return instance


static func finish(instance: Node3D, role: String, appearance: Dictionary) -> AnimationPlayer:
	var player = CharacterMotion.attach(instance, str(instance.get_meta("model")))
	# This generated ghost has the opposite source facing to the living meshes.
	instance.rotation.y = 0.0 if role == "ghost" else PI
	if role == "ghost":
		for mesh in instance.find_children("*", "MeshInstance3D", true, false):
			var material = ShaderMaterial.new()
			material.shader = load("res://shaders/ghost.gdshader")
			var original = mesh.get_active_material(0)
			if original is StandardMaterial3D and original.albedo_texture != null:
				material.set_shader_parameter("albedo_texture", original.albedo_texture)
				material.set_shader_parameter("has_albedo", true)
			mesh.material_override = material
	_add_brooch(instance, role, AppearanceData.normalize(role, appearance).brooch)
	return player


static func _add_brooch(instance: Node3D, role: String, finish: String) -> void:
	if finish == "none":
		return
	var skeletons = instance.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var skeleton: Skeleton3D = skeletons[0]
	var bone = skeleton.find_bone("Spine2")
	if bone < 0:
		bone = skeleton.find_bone("Spine")
	if bone < 0:
		return
	var attachment = BoneAttachment3D.new()
	attachment.name = "CosmeticBrooch"
	attachment.bone_idx = bone
	skeleton.add_child(attachment)
	# Meshy rigs use metres with a transformed skeleton; convert a world-sized pin.
	var pin = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	sphere.radial_segments = 24
	sphere.rings = 12
	pin.mesh = sphere
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("d4ab58") if finish == "gold" else Color("c2d1d5")
	material.metallic = 0.85
	material.roughness = 0.24
	pin.material_override = material
	attachment.add_child(pin)
	var scale_factor = maxf(0.001, skeleton.global_basis.get_scale().x)
	pin.scale = Vector3.ONE / scale_factor
	pin.global_position = (
		instance.get_parent().global_transform
		* Vector3(0.13, float(AppearanceData.HEIGHTS[role]) * 0.76, -0.19)
	)
