extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	for model in ["medium", "physician"]:
		for file in ["character", "walking", "running"]:
			var path = "res://assets/models/" + model + "/" + file + ".glb"
			var instance = load(path).instantiate()
			root.add_child(instance)
			print("ASSET ", model, "/", file)
			for skeleton in instance.find_children("*", "Skeleton3D", true, false):
				print("BONES ", skeleton.get_bone_count())
				for index in range(skeleton.get_bone_count()):
					var bone_name = skeleton.get_bone_name(index)
					if "arm" in bone_name.to_lower() or "shoulder" in bone_name.to_lower():
						print(index, " ", bone_name, " rest=", skeleton.get_bone_rest(index))
			for animation_player in instance.find_children("*", "AnimationPlayer", true, false):
				print("ANIMATIONS ", animation_player.get_animation_list())
				for anim_name in animation_player.get_animation_list():
					var animation = animation_player.get_animation(anim_name)
					if animation.get_track_count() > 0:
						print("TRACK ", animation.track_get_path(0), " LENGTH ", animation.length)
			instance.free()
	quit()
