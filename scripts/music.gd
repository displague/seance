extends Node
## Independent, synchronized layers; no vocals compete with social deduction.

var layers: Dictionary = {}
var gains = {"bed": 0.0, "piano": 0.0, "tension": 0.0}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	for kind in gains:
		var source = load("res://assets/audio/" + kind + ".wav") as AudioStreamWAV
		if source == null:
			continue
		var stream = source.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = -80
		add_child(player)
		layers[kind] = player
	# Starts in the same main-thread frame; no stop/restart when the phase changes.
	for player in layers.values():
		player.play()


func targets(view: Dictionary, active: bool) -> Dictionary:
	var phase = str(view.get("phase", "menu")) if active else "menu"
	var levels = {"bed": 0.32, "piano": 0.22, "tension": 0.0}
	if phase == "investigation":
		levels.piano = 0.1
	elif phase == "seance":
		levels.piano = 0.04
		levels.tension = 0.16
	elif phase == "judgment":
		levels.tension = 0.3
	elif phase == "ended":
		levels.piano = 0.32
	if active and phase != "ended" and view.get("haunt", {}).get("kind", "") != "":
		levels.tension = maxf(levels.tension, 0.3)
	return levels


func _process(delta: float) -> void:
	var goal = targets(Session.view, Session.active)
	var duck = 0.35 if Voice.transmitting or Voice.receiving_until > Time.get_ticks_msec() else 1.0
	for kind in layers:
		gains[kind] = move_toward(gains[kind], goal[kind] * duck, delta * 0.18)
		var gain = gains[kind] * float(Session.settings.music_volume)
		layers[kind].volume_db = linear_to_db(maxf(gain, 0.00001))
		layers[kind].stream_paused = Session.suspended


func _exit_tree() -> void:
	shutdown()


func shutdown() -> void:
	set_process(false)
	for player in layers.values():
		player.stop()
		player.stream = null
