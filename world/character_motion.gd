class_name CharacterMotion
extends RefCounted
## Retarget Meshy's included locomotion clips to the matching imported skeleton.
## No runtime Python, animation service, or procedural limb replacement.


static func attach(instance: Node3D, model: String) -> AnimationPlayer:
	var players = instance.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return null
	var player: AnimationPlayer = players[0]
	var library = AnimationLibrary.new()
	var idle: Animation = player.get_animation(player.get_animation_list()[0]).duplicate(true)
	for kind in ["walking", "running"]:
		var scene: PackedScene = load("res://assets/models/" + model + "/" + kind + ".glb")
		var source = scene.instantiate()
		var source_player: AnimationPlayer = (
			source.find_children("*", "AnimationPlayer", true, false)[0]
		)
		var clip: Animation = (
			source_player.get_animation(source_player.get_animation_list()[0]).duplicate(true)
		)
		clip.loop_mode = Animation.LOOP_LINEAR
		# Remove horizontal root motion: replicated world movement owns displacement.
		for track in range(clip.get_track_count()):
			var path = str(clip.track_get_path(track))
			if clip.track_get_type(track) == Animation.TYPE_POSITION_3D and path.ends_with(":Hips"):
				for key in range(clip.track_get_key_count(track)):
					var position: Vector3 = clip.track_get_key_value(track, key)
					position.x = 0
					position.z = 0
					clip.track_set_key_value(track, key, position)
			if kind == "walking" and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				if "Arm" in path or "Hand" in path or "Shoulder" in path:
					var idle_track = idle.find_track(
						clip.track_get_path(track), Animation.TYPE_ROTATION_3D
					)
					if idle_track >= 0:
						var pose = clip.rotation_track_interpolate(track, 0.0)
						for key in range(idle.track_get_key_count(idle_track)):
							idle.track_set_key_value(idle_track, key, pose)
		library.add_animation(kind, clip)
		source.free()
	idle.loop_mode = Animation.LOOP_LINEAR
	library.add_animation("idle", idle)
	player.add_animation_library("seance", library)
	player.play("seance/idle")
	player.advance(0)
	return player


static func update(player: AnimationPlayer, speed: float) -> void:
	if not is_instance_valid(player):
		return
	var clip = "idle" if speed < 0.12 else ("running" if speed > 4.1 else "walking")
	if player.current_animation != "seance/" + clip:
		player.play("seance/" + clip, 0.22)
	player.speed_scale = clampf(speed / 2.2, 0.6, 1.6) if clip == "walking" else 1.0
