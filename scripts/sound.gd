extends Node
## Original procedural ambience and interaction sounds. Generated locally.

var ambient: AudioStreamPlayer
var elapsed = 0.0
var next_note = 4.0
var tones: Dictionary = {}


func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	tones.clear()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	AudioServer.set_bus_volume_db(0, linear_to_db(float(Session.settings.volume)))
	for kind in ["click", "clue", "knock", "step", "ritual", "chime"]:
		tones[kind] = _make_sound(kind)
	ambient = AudioStreamPlayer.new()
	ambient.stream = _make_sound("ambience")
	ambient.volume_db = -18
	add_child(ambient)
	ambient.play()


func play(kind: String, gain: float = 0.0) -> void:
	if not tones.has(kind):
		return
	var player = AudioStreamPlayer.new()
	player.stream = tones[kind]
	player.volume_db = gain
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > next_note:
		next_note = elapsed + randf_range(9, 17)
		if Session.active and Session.view.get("phase") == "seance":
			play("chime", -16)


func _make_sound(kind: String) -> AudioStreamWAV:
	var duration = (
		{
			"click": 0.1,
			"clue": 1.5,
			"knock": 0.45,
			"step": 0.16,
			"ritual": 2.4,
			"chime": 3.5,
			"ambience": 12.0
		}
		. get(kind, 1.0)
	)
	var rate = 22050
	var size = int(duration * rate)
	var data = PackedByteArray()
	data.resize(size * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 1913
	var filtered = 0.0
	for i in range(size):
		var t = i / float(rate)
		var sample = 0.0
		var noise = rng.randf_range(-1, 1)
		filtered = filtered * 0.985 + noise * 0.015
		match kind:
			"click":
				sample = sin(t * TAU * 740) * exp(-t * 65) * 0.15
			"knock":
				sample = (sin(t * TAU * 96) + noise * 0.25) * exp(-t * 18) * 0.42
			"step":
				sample = (noise * 0.1 + sin(t * TAU * 65) * 0.25) * exp(-t * 27)
			"clue":
				sample = (
					(sin(t * TAU * 523.25) + sin(t * TAU * 783.99) * 0.3)
					* exp(-t * 4)
					* sin(minf(1, t * 15) * PI / 2)
					* 0.18
				)
			"ritual":
				sample = (
					(sin(t * TAU * 146.83) + sin(t * TAU * 220) + sin(t * TAU * 293.66) * 0.5)
					* sin(PI * t / duration)
					* 0.12
				)
			"chime":
				sample = (
					(sin(t * TAU * 440) + sin(t * TAU * 659.25) * 0.4 + sin(t * TAU * 1046.5) * 0.2)
					* exp(-t * 2.3)
					* 0.13
				)
			"ambience":
				var envelope = pow(sin(PI * t / duration), 0.5)
				sample = (
					((sin(TAU * 55 * t) + sin(TAU * 82.5 * t) * 0.45) * 0.065 + filtered * 0.5)
					* envelope
				)
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	if kind == "ambience":
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = size
	return wav
