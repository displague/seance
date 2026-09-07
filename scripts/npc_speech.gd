extends Node
## Optional native Piper voice-out and whisper.cpp voice-in. No Python runtime.
## Microphone opens only for an explicit, enabled push-to-talk take; audio stays local.
signal status_changed
signal transcribed(npc: String, text: String)

const CAST = {
	"medium": "en_US-lessac-medium",
	"heir": "en_US-joe-medium",
	"widow": "en_US-amy-medium",
	"doctor": "en_GB-alan-medium",
	"keeper": "en_US-ljspeech-medium",
	"ghost": "en_US-danny-low"
}
var voice_out = false
var voice_in = false
var focused_npc = ""
var status = "Voice is off."
var helper_dir = ""
var job: Dictionary = {}
var serial = 0
var output: AudioStreamPlayer
var microphone: AudioStreamPlayer
var capture: AudioEffectCapture
var recording = false
var samples = PackedByteArray()
var speech_request: HTTPRequest
var clip_path = ""
var take_began = 0
var captured_npc = ""
var take_serial = 0
var speaking_npc = ""


func _ready() -> void:
	helper_dir = ProjectSettings.globalize_path("res://tools/ai")
	var configured = OS.get_environment("SEANCE_AI_HELPERS")
	if configured != "":
		helper_dir = configured
	elif not FileAccess.file_exists(helper_dir.path_join("piper/piper.exe")):
		# Development bundle beside this source checkout; no helper is bundled.
		var adjacent = (
			OS.get_executable_path().get_base_dir().path_join("../tools/ai").simplify_path()
		)
		if FileAccess.file_exists(adjacent.path_join("piper/piper.exe")):
			helper_dir = adjacent
	output = AudioStreamPlayer.new()
	add_child(output)
	output.finished.connect(_clear_clip)
	microphone = AudioStreamPlayer.new()
	var index = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(index, "NpcCapture")
	AudioServer.set_bus_mute(index, true)
	capture = AudioEffectCapture.new()
	capture.buffer_length = 0.5
	AudioServer.add_bus_effect(index, capture)
	microphone.bus = "NpcCapture"
	add_child(microphone)
	get_window().focus_exited.connect(func(): stop_capture(false))


func focus(npc: String) -> void:
	if focused_npc != npc:
		cancel()
	focused_npc = npc


func permitted(npc: String) -> bool:
	return (
		Session.active
		and not Session.online
		and Session.rules != null
		and NpcRules.permission(Session.rules, Session.local_role, npc) == ""
	)


func set_voice_in(value: bool) -> void:
	voice_in = value
	if not value:
		take_serial += 1
		stop_capture(false)
		if is_instance_valid(speech_request):
			speech_request.cancel_request()
			speech_request.queue_free()
			speech_request = null
	status = "Push-to-talk enabled. Hold V / LB outside the text field, or hold the Record button."
	if not value:
		status = "Microphone is off."
	status_changed.emit()


func set_voice_out(value: bool) -> void:
	voice_out = value
	if not value:
		stop_speaking()
	status = "NPC voices enabled." if value else "NPC voices are off."
	status_changed.emit()


func say(npc: String, text: String) -> bool:
	if not voice_out or not permitted(npc) or not CAST.has(npc) or text.strip_edges() == "":
		return false
	stop_speaking()
	var executable = helper_dir.path_join("piper/piper.exe")
	var model_path = helper_dir.path_join("voices/" + CAST[npc] + ".onnx")
	if not FileAccess.file_exists(executable) or not FileAccess.file_exists(model_path):
		status = "Native voice files are missing. Run tools/setup-solo-ai.ps1 -InstallVoice."
		status_changed.emit()
		return false
	serial += 1
	clip_path = OS.get_cache_dir().path_join("seance-npc-%s-%s.wav" % [OS.get_process_id(), serial])
	var io = OS.execute_with_pipe(
		executable,
		["--model", model_path, "--output_file", clip_path, "--length_scale", "1.05"],
		false
	)
	if io.is_empty():
		status = "Could not start native Piper. Text remains available."
		status_changed.emit()
		return false
	io.stdio.store_string(text.replace("\n", " ").left(700) + "\n")
	io.stdio.close()
	job = {
		"pid": io.pid,
		"stderr": io.stderr,
		"npc": npc,
		"deadline": Time.get_ticks_msec() + 15000,
		"began": Time.get_ticks_msec()
	}
	status = "Preparing " + CaseData.person(npc).name + "'s voice…"
	status_changed.emit()
	return true


func _process(_delta: float) -> void:
	if recording:
		_drain_capture()
		if not permitted(captured_npc) or not get_window().has_focus():
			stop_capture(false)
		elif Time.get_ticks_msec() - take_began >= 20000:
			stop_capture(true)
	if not job.is_empty():
		if not voice_out or not permitted(job.npc):
			stop_speaking()
		elif Time.get_ticks_msec() > job.deadline:
			stop_speaking()
			status = "Voice synthesis timed out. Text remains available."
			status_changed.emit()
		elif not OS.is_process_running(job.pid):
			_finish_voice()
	if output.playing:
		if not voice_out or not permitted(speaking_npc):
			stop_speaking()
		else:
			Voice.receiving_until = Time.get_ticks_msec() + 150


func _finish_voice() -> void:
	var npc: String = job.npc
	var elapsed: float = (Time.get_ticks_msec() - job.began) / 1000.0
	job.stderr.close()
	job = {}
	if not FileAccess.file_exists(clip_path):
		status = "Piper produced no audio. Text remains available."
		status_changed.emit()
		return
	output.stream = AudioStreamWAV.load_from_file(clip_path)
	if output.stream == null:
		_clear_clip()
		return
	output.bus = Voice.ghost_bus if npc == "ghost" else "Master"
	output.volume_db = -3
	speaking_npc = npc
	output.play()
	status = "Speaking · %s · synthesis %.2fs" % [CAST[npc], elapsed]
	status_changed.emit()


func _clear_clip() -> void:
	output.stop()
	output.stream = null
	speaking_npc = ""
	if clip_path != "" and FileAccess.file_exists(clip_path):
		DirAccess.remove_absolute(clip_path)
	clip_path = ""


func stop_speaking() -> void:
	if not job.is_empty():
		if OS.is_process_running(job.pid):
			OS.kill(job.pid)
		job.stderr.close()
		job = {}
	_clear_clip()


func cancel() -> void:
	take_serial += 1
	stop_capture(false)
	if is_instance_valid(speech_request):
		speech_request.cancel_request()
		speech_request.queue_free()
	speech_request = null
	stop_speaking()


func _input(event: InputEvent) -> void:
	if focused_npc == "" or not event.is_action("game_talk"):
		return
	if event.is_action_released("game_talk"):
		stop_capture(true)
		return
	var field = get_viewport().gui_get_focus_owner()
	if event is InputEventKey and (field is LineEdit or field is TextEdit):
		return
	if event.is_action_pressed("game_talk") and not event.is_echo():
		start_capture()


func start_capture() -> void:
	if not voice_in or recording or not permitted(focused_npc) or is_instance_valid(speech_request):
		return
	stop_speaking()
	samples.clear()
	capture.clear_buffer()
	captured_npc = focused_npc
	take_began = Time.get_ticks_msec()
	take_serial += 1
	recording = true
	microphone.stream = AudioStreamMicrophone.new()
	microphone.play()
	status = "LISTENING · release to transcribe locally · maximum 20 seconds"
	status_changed.emit()


func _drain_capture() -> void:
	var step = maxf(1, AudioServer.get_mix_rate() / 16000.0)
	var needed = int(480 * step)
	while capture.can_get_buffer(needed) and samples.size() < 640000:
		var frames = capture.get_buffer(needed)
		var part = PackedByteArray()
		part.resize(960)
		for i in range(480):
			var frame = frames[mini(int(i * step), frames.size() - 1)]
			part.encode_s16(i * 2, int(clampf((frame.x + frame.y) * 0.5, -1, 1) * 32767))
		samples.append_array(part)


func stop_capture(send: bool) -> void:
	if not recording:
		return
	_drain_capture()
	# Close the microphone synchronously, before any HTTP request or model work.
	microphone.stop()
	microphone.stream = null
	recording = false
	capture.clear_buffer()
	if send and voice_in and permitted(captured_npc) and samples.size() >= 9600:
		transcribe_wav(wav_bytes(samples), captured_npc)
	else:
		status = "Recording cancelled or too short. No audio was sent."
		status_changed.emit()
	samples.clear()


func wav_bytes(pcm: PackedByteArray) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(44)
	for entry in [[0, "RIFF"], [8, "WAVEfmt "], [36, "data"]]:
		var marker: PackedByteArray = entry[1].to_ascii_buffer()
		for i in range(marker.size()):
			bytes[entry[0] + i] = marker[i]
	bytes.encode_u32(4, 36 + pcm.size())
	bytes.encode_u32(16, 16)
	bytes.encode_u16(20, 1)
	bytes.encode_u16(22, 1)
	bytes.encode_u32(24, 16000)
	bytes.encode_u32(28, 32000)
	bytes.encode_u16(32, 2)
	bytes.encode_u16(34, 16)
	bytes.encode_u32(40, pcm.size())
	bytes.append_array(pcm)
	return bytes


func transcribe_wav(wav: PackedByteArray, npc: String) -> bool:
	if not voice_in or not permitted(npc) or is_instance_valid(speech_request):
		return false
	var boundary = "SeanceAudio" + str(Time.get_ticks_usec())
	var data = (
		(
			"--"
			+ boundary
			+ '\r\nContent-Disposition: form-data; name="file"; filename="take.wav"\r\nContent-Type: audio/wav\r\n\r\n'
		)
		. to_utf8_buffer()
	)
	data.append_array(wav)
	data.append_array(
		(
			(
				"\r\n--"
				+ boundary
				+ '\r\nContent-Disposition: form-data; name="response_format"\r\n\r\njson\r\n--'
				+ boundary
				+ "--\r\n"
			)
			. to_utf8_buffer()
		)
	)
	speech_request = HTTPRequest.new()
	speech_request.timeout = 30
	speech_request.max_redirects = 0
	speech_request.body_size_limit = 32768
	add_child(speech_request)
	speech_request.request_completed.connect(_transcript.bind(npc, take_serial, Session.rules))
	status = "Transcribing on this machine…"
	status_changed.emit()
	var error = speech_request.request_raw(
		"http://127.0.0.1:8179/inference",
		["Content-Type: multipart/form-data; boundary=" + boundary],
		HTTPClient.METHOD_POST,
		data
	)
	if error != OK:
		speech_request.queue_free()
		speech_request = null
		status = "Could not start local transcription. Type your question instead."
		status_changed.emit()
	return error == OK


func _transcript(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	npc: String,
	ticket: int,
	game
) -> void:
	# A cancelled take may already have queued its completion. Never free the
	# request belonging to a newer recording when that stale callback arrives.
	if ticket != take_serial:
		return
	if is_instance_valid(speech_request):
		speech_request.queue_free()
	speech_request = null
	if not voice_in or Session.rules != game or focused_npc != npc or not permitted(npc):
		return
	var parser = JSON.new()
	var data = parser.data if parser.parse(body.get_string_from_utf8()) == OK else null
	if (
		result != HTTPRequest.RESULT_SUCCESS
		or code != 200
		or not data is Dictionary
		or not data.get("text") is String
	):
		status = "Transcription unavailable. Start tools/setup-solo-ai.ps1 -Start, or type instead."
	else:
		status = "Review the transcript, then press Send. Nothing is sent to the NPC automatically."
		transcribed.emit(npc, data.text.strip_edges().left(400))
	status_changed.emit()


func shutdown() -> void:
	voice_in = false
	voice_out = false
	focused_npc = ""
	cancel()


func _exit_tree() -> void:
	shutdown()
