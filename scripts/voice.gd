extends Node
## Opt-in 16 kHz PCM voice. Server routes packets only to eligible listeners.
## No cloud service, recording, persistence, or microphone use before opt-in.

signal status_changed
const RATE = 16000
const FRAMES = 480
var enabled = false
var transmitting = false
var receiving_until = 0
var level = 0.0
var microphone: AudioStreamPlayer
var capture: AudioEffectCapture
var speakers: Dictionary = {}
var last_packet: Dictionary = {}
var ghost_bus = "GhostVoice"


func _ready() -> void:
	var input_bus = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(input_bus, "VoiceCapture")
	capture = AudioEffectCapture.new()
	capture.buffer_length = 0.2
	AudioServer.add_bus_effect(input_bus, capture)
	AudioServer.set_bus_mute(input_bus, true)
	var output_bus = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(output_bus, ghost_bus)
	var filter = AudioEffectLowPassFilter.new()
	filter.cutoff_hz = 3100
	AudioServer.add_bus_effect(output_bus, filter)
	var echo = AudioEffectDelay.new()
	echo.tap1_delay_ms = 155
	echo.tap1_level_db = -12
	echo.tap2_active = false
	AudioServer.add_bus_effect(output_bus, echo)
	var reverb = AudioEffectReverb.new()
	reverb.room_size = 0.8
	reverb.wet = 0.3
	reverb.dry = 0.85
	AudioServer.add_bus_effect(output_bus, reverb)
	microphone = AudioStreamPlayer.new()
	microphone.bus = "VoiceCapture"
	add_child(microphone)
	Session.connection_lost.connect(stop)


func set_enabled(value: bool) -> void:
	enabled = value
	if enabled:
		microphone.stream = AudioStreamMicrophone.new()
		microphone.play()
	else:
		microphone.stop()
		microphone.stream = null
		transmitting = false
		level = 0
	capture.clear_buffer()
	status_changed.emit()


func stop() -> void:
	set_enabled(false)
	for output in speakers.values():
		output.queue_free()
	speakers.clear()
	last_packet.clear()


func _process(_delta: float) -> void:
	# Clear the navigation latch on release even when PTT is up or mic is off.
	var talk_allowed = Controls.talk_allowed()
	if not enabled:
		return
	transmitting = (
		Input.is_action_pressed("game_talk") and Session.online and Session.active and talk_allowed
	)
	var focused = get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit or not get_window().has_focus():
		transmitting = false
	var step = maxf(1.0, AudioServer.get_mix_rate() / float(RATE))
	var needed = int(FRAMES * step)
	while capture.can_get_buffer(needed):
		var frames = capture.get_buffer(needed)
		if not transmitting:
			level = 0
			continue
		var packet = PackedByteArray()
		packet.resize(FRAMES * 2)
		var peak = 0.0
		for i in range(FRAMES):
			var sample: Vector2 = frames[mini(int(i * step), frames.size() - 1)]
			var mono = clampf((sample.x + sample.y) * 0.5, -1.0, 1.0)
			peak = maxf(peak, absf(mono))
			packet.encode_s16(i * 2, int(mono * 32767))
		level = peak
		if Session.hosting:
			_relay(1, packet)
		else:
			_upload.rpc_id(1, packet)


@rpc("any_peer", "call_remote", "unreliable_ordered", 2)
func _upload(packet: PackedByteArray) -> void:
	if not Session.hosting or not Session.active:
		return
	var sender = multiplayer.get_remote_sender_id()
	if not Session.lobby.has(sender) or packet.size() != FRAMES * 2:
		return
	var now = Time.get_ticks_msec()
	if now - last_packet.get(sender, -100) < 15:
		return
	last_packet[sender] = now
	_relay(sender, packet)


func _relay(sender: int, packet: PackedByteArray) -> void:
	if not Session.active or not Session.lobby.has(sender):
		return
	var role = Session.lobby[sender].role
	for peer_id in Session.lobby:
		if not Session.rules.can_hear(role, Session.lobby[peer_id].role):
			continue
		if peer_id == 1:
			_play(role, packet)
		else:
			_deliver.rpc_id(peer_id, role, packet)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _deliver(role: String, packet: PackedByteArray) -> void:
	if Session.active and CaseData.ROLES.has(role) and packet.size() == FRAMES * 2:
		_play(role, packet)


func _play(role: String, packet: PackedByteArray) -> void:
	receiving_until = Time.get_ticks_msec() + 450
	if not speakers.has(role):
		var output = AudioStreamPlayer.new()
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = RATE
		stream.buffer_length = 0.16
		output.stream = stream
		if role == "ghost":
			output.bus = ghost_bus
		add_child(output)
		output.play()
		speakers[role] = output
	var playback: AudioStreamGeneratorPlayback = speakers[role].get_stream_playback()
	if playback.get_frames_available() < FRAMES:
		return
	var buffer = PackedVector2Array()
	buffer.resize(FRAMES)
	for i in range(FRAMES):
		var sample = packet.decode_s16(i * 2) / 32768.0
		buffer[i] = Vector2(sample, sample)
	playback.push_buffer(buffer)
