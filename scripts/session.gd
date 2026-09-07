extends Node
## Network boundary: only the host mutates GameRules; snapshots are per recipient.

signal changed
signal notice(text: String)
signal started
signal lobby_changed
signal connection_lost
signal command_finished(action: String, payload: Dictionary, error: String)

const PORT = 27877
var rules: GameRules
var view: Dictionary = {}
var lobby: Dictionary = {}
var local_role = "medium"
var preferred_role = "medium"
var player_name = "Guest"
var online = false
var active = false
var hosting = false
var snapshot_clock = 0.0
var connection_clock = 0.0
var connecting = false
var suspended = false
var rate: Dictionary = {}
var movement_time: Dictionary = {}
var settings = {
	"volume": 0.65,
	"sensitivity": 0.0024,
	"fullscreen": false,
	"quality": 1,
	"subtitles": true,
	"motion": true,
	"music_volume": 0.45,
	"pad_deadzone": 0.2,
	"pad_sensitivity": 2.2,
	"rumble": true,
	"reduced_flashes": false,
	"blood_effects": false,
	"audio_output": "Default"
}


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(_failed)
	multiplayer.server_disconnected.connect(_disconnected)
	var cfg = ConfigFile.new()
	if cfg.load("user://preferences.cfg") == OK:
		for key in settings:
			settings[key] = cfg.get_value("settings", key, settings[key])


func save_settings() -> void:
	var cfg = ConfigFile.new()
	for key in settings:
		cfg.set_value("settings", key, settings[key])
	cfg.save("user://preferences.cfg")


func solo(role: String, use_ai: bool = false) -> void:
	var speech_in = NpcSpeech.voice_in
	var speech_out = NpcSpeech.voice_out
	leave()
	local_role = role if CaseData.ROLES.has(role) else "medium"
	rules = GameRules.new()
	rules.reset([local_role])
	rules.state.interactive_guests = use_ai
	_set_appearances()
	active = true
	hosting = true
	view = rules.view_for(local_role)
	SoloAi.set_enabled(use_ai)
	if use_ai:
		NpcSpeech.set_voice_in(speech_in)
		NpcSpeech.set_voice_out(speech_out)
	started.emit()
	changed.emit()


func host(role: String, guest_name: String) -> Error:
	leave()
	var peer = ENetMultiplayerPeer.new()
	# Leave channel negotiation unlimited on the host. Godot 4.7's explicit
	# max_channels argument is accidentally forwarded as incoming bandwidth.
	# Clients still negotiate three application channels (commands/movement/voice).
	var error = peer.create_server(PORT, 5)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	local_role = role if CaseData.ROLES.has(role) else "medium"
	player_name = guest_name.strip_edges().left(24)
	online = true
	hosting = true
	lobby = {
		1:
		{
			"name": player_name,
			"role": local_role,
			"appearance": AppearanceData.normalize(local_role, Wardrobe.choices.get(local_role, {}))
		}
	}
	lobby_changed.emit()
	return OK


func join_room(address: String, role: String, guest_name: String) -> Error:
	leave()
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address.strip_edges(), PORT, 3)
	if error != OK:
		return error
	preferred_role = role
	player_name = guest_name.strip_edges().left(24)
	multiplayer.multiplayer_peer = peer
	online = true
	connecting = true
	connection_clock = 0
	return OK


func _connected() -> void:
	_register.rpc_id(1, player_name, preferred_role, Wardrobe.choices)


func _failed() -> void:
	leave()
	notice.emit("Could not reach the host. Check the address and UDP port 27877.")
	connection_lost.emit()


func _disconnected() -> void:
	leave()
	notice.emit("The host closed the circle. Your connection has ended.")
	connection_lost.emit()


@rpc("any_peer", "call_remote", "reliable", 0)
func _register(guest_name: String, wanted: String, appearances: Dictionary = {}) -> void:
	if not hosting or not online:
		return
	var sender = multiplayer.get_remote_sender_id()
	if active or lobby.has(sender) or lobby.size() >= 6:
		return
	if appearances.size() > 6 or var_to_bytes(appearances).size() > 2048:
		return
	var taken = []
	for guest in lobby.values():
		taken.append(guest.role)
	var selected = wanted
	if not CaseData.ROLES.has(wanted) or taken.has(wanted):
		for role in CaseData.ROLES:
			if not taken.has(role):
				selected = role
				break
	lobby[sender] = {
		"name": guest_name.strip_edges().left(24),
		"role": selected,
		"appearance": AppearanceData.normalize(selected, appearances.get(selected, {}))
	}
	_publish_lobby()


func _publish_lobby() -> void:
	_receive_lobby.rpc(lobby)
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable", 0)
func _receive_lobby(guests: Dictionary) -> void:
	lobby = guests
	connecting = false
	var own_id = multiplayer.get_unique_id()
	if lobby.has(own_id):
		local_role = lobby[own_id].role
	lobby_changed.emit()


func start_host_game() -> void:
	if not hosting or active:
		return
	var human_roles = []
	for guest in lobby.values():
		human_roles.append(guest.role)
	rules = GameRules.new()
	rules.reset(human_roles)
	_set_appearances()
	active = true
	view = rules.view_for(local_role)
	for peer_id in lobby:
		if peer_id != 1:
			_begin.rpc_id(peer_id, rules.view_for(lobby[peer_id].role))
	started.emit()
	changed.emit()


@rpc("authority", "call_remote", "reliable", 0)
func _begin(snapshot: Dictionary) -> void:
	view = snapshot
	active = true
	started.emit()
	changed.emit()


func _set_appearances() -> void:
	rules.state["appearances"] = AppearanceData.preferences({})
	rules.state["sitting_id"] = "%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	rules.state.appearances[local_role] = AppearanceData.normalize(
		local_role, Wardrobe.choices.get(local_role, {})
	)
	for guest in lobby.values():
		rules.state.appearances[guest.role] = AppearanceData.normalize(
			guest.role, guest.get("appearance", {})
		)


func _peer_left(peer_id: int) -> void:
	if not hosting:
		return
	if lobby.has(peer_id):
		var role = lobby[peer_id].role
		lobby.erase(peer_id)
		rate.erase(peer_id)
		movement_time.erase(peer_id)
		if active:
			rules.humans.erase(role)
			rules.log_event(
				CaseData.person(role).name + " lost connection. The house will speak for them."
			)
			if rules.state.phase == "judgment" and rules.all_humans_voted():
				rules.resolve()
			publish()
		_publish_lobby()


func leave() -> void:
	Voice.stop()
	SoloAi.cancel()
	NpcSpeech.shutdown()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online = false
	active = false
	hosting = false
	connecting = false
	suspended = false
	view = {}
	lobby = {}
	rules = null
	rate.clear()
	movement_time.clear()


func command(action: String, payload: Dictionary = {}) -> void:
	if not active:
		return
	if hosting:
		_apply(local_role, action, payload)
	else:
		_request.rpc_id(1, action, payload)


func _apply(role: String, action: String, payload: Dictionary, peer_id: int = 1) -> void:
	var error = rules.act(role, action, payload)
	if error != "":
		if peer_id == 1:
			notice.emit(error)
		else:
			_feedback.rpc_id(peer_id, error)
	publish()
	if peer_id == 1:
		command_finished.emit(action, payload, error)
	else:
		_command_finished.rpc_id(peer_id, action, payload, error)


@rpc("authority", "call_remote", "reliable", 0)
func _command_finished(action: String, payload: Dictionary, error: String) -> void:
	command_finished.emit(action, payload, error)


@rpc("any_peer", "call_remote", "reliable", 0)
func _request(action: String, payload: Dictionary) -> void:
	var sender = multiplayer.get_remote_sender_id()
	if not hosting or not active or not lobby.has(sender) or not allow_packet(sender):
		return
	if payload.size() > 6 or var_to_bytes(payload).size() > 2048:
		return
	_apply(lobby[sender].role, action, payload, sender)


func allow_packet(peer_id: int) -> bool:
	var second = Time.get_ticks_msec() / 1000
	var entry = rate.get(peer_id, {"second": second, "count": 0})
	if entry.second != second:
		entry = {"second": second, "count": 0}
	entry.count += 1
	rate[peer_id] = entry
	return entry.count <= 12


@rpc("authority", "call_remote", "reliable", 0)
func _feedback(message: String) -> void:
	notice.emit(message)


func publish() -> void:
	if not hosting or not active:
		return
	view = rules.view_for(local_role)
	changed.emit()
	if online:
		for peer_id in lobby:
			if peer_id != 1:
				_snapshot.rpc_id(peer_id, rules.view_for(lobby[peer_id].role))


@rpc("authority", "call_remote", "reliable", 0)
func _snapshot(snapshot: Dictionary) -> void:
	view = snapshot
	changed.emit()


func move_local(pos: Vector3) -> void:
	if not active or not CaseData.is_walkable(pos):
		return
	if hosting:
		rules.state.positions[local_role] = pos
	elif online:
		_position.rpc_id(1, pos)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _position(pos: Vector3) -> void:
	var sender = multiplayer.get_remote_sender_id()
	if not hosting or not active or not lobby.has(sender) or not CaseData.is_walkable(pos):
		return
	var role = lobby[sender].role
	var now = Time.get_ticks_msec()
	var elapsed = clampf((now - movement_time.get(sender, now - 1000)) / 1000.0, 0.0, 1.0)
	var last: Vector3 = rules.state.positions[role]
	if last.distance_to(pos) > 7.0 * elapsed + 0.45:
		return
	movement_time[sender] = now
	pos.y = 0
	rules.state.positions[role] = pos


func advance() -> void:
	if hosting and active and rules.state.phase != "ended":
		rules.advance()
		publish()


func _process(delta: float) -> void:
	if connecting:
		connection_clock += delta
		if connection_clock > 10:
			_failed()
	if not hosting or not active or suspended:
		return
	rules.tick(delta)
	snapshot_clock += delta
	if snapshot_clock >= 0.25:
		snapshot_clock = 0
		publish()
