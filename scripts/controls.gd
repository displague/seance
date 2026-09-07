extends Node
## SDL-standard mappings: Xbox, PlayStation, Stadia Bluetooth and compatible pads.
## No microphone activation or audio-device changes on controller connection.

signal device_changed

var device = -1
var using_pad = false
var tab_navigation = false
var tab_talk_latch = false


func _ready() -> void:
	# Projects created without an InputMap may have keyboard-only UI defaults.
	var back = InputEventJoypadButton.new()
	back.button_index = JOY_BUTTON_B
	if not InputMap.action_has_event("ui_cancel", back):
		InputMap.action_add_event("ui_cancel", back)
	var accept = InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	if not InputMap.action_has_event("ui_accept", accept):
		InputMap.action_add_event("ui_accept", accept)
	for entry in [
		["ui_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0],
		["ui_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0],
		["ui_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0],
		["ui_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0]
	]:
		var button = InputEventJoypadButton.new()
		button.button_index = entry[1]
		if not InputMap.action_has_event(entry[0], button):
			InputMap.action_add_event(entry[0], button)
		var direction = InputEventJoypadMotion.new()
		direction.axis = entry[2]
		direction.axis_value = entry[3]
		if not InputMap.action_has_event(entry[0], direction):
			InputMap.action_add_event(entry[0], direction)
	for binding in [
		["interact", KEY_E, JOY_BUTTON_A],
		["lantern", KEY_F, JOY_BUTTON_DPAD_RIGHT],
		["journal", KEY_J, JOY_BUTTON_X],
		["circle", KEY_C, JOY_BUTTON_Y],
		["spirit", KEY_G, JOY_BUTTON_DPAD_UP],
		["transcript", KEY_T, JOY_BUTTON_DPAD_DOWN],
		["microphone", KEY_M, JOY_BUTTON_DPAD_LEFT],
		["talk", KEY_V, JOY_BUTTON_LEFT_SHOULDER],
		["sprint", KEY_SHIFT, JOY_BUTTON_LEFT_STICK],
		["pause", KEY_ESCAPE, JOY_BUTTON_START]
	]:
		_bind_button(binding[0], binding[1], binding[2])
	for binding in [
		["move_left", KEY_A, JOY_AXIS_LEFT_X, -1.0],
		["move_right", KEY_D, JOY_AXIS_LEFT_X, 1.0],
		["move_forward", KEY_W, JOY_AXIS_LEFT_Y, -1.0],
		["move_back", KEY_S, JOY_AXIS_LEFT_Y, 1.0],
		["look_left", 0, JOY_AXIS_RIGHT_X, -1.0],
		["look_right", 0, JOY_AXIS_RIGHT_X, 1.0],
		["look_up", 0, JOY_AXIS_RIGHT_Y, -1.0],
		["look_down", 0, JOY_AXIS_RIGHT_Y, 1.0]
	]:
		var action = "game_" + str(binding[0])
		InputMap.add_action(action, 0.2)
		if binding[1] != 0:
			var key = InputEventKey.new()
			key.physical_keycode = binding[1]
			InputMap.action_add_event(action, key)
		var axis = InputEventJoypadMotion.new()
		axis.axis = binding[2]
		axis.axis_value = binding[3]
		InputMap.action_add_event(action, axis)
	Input.joy_connection_changed.connect(_connection)
	get_window().focus_exited.connect(stop_rumble)
	var devices = Input.get_connected_joypads()
	if not devices.is_empty():
		device = devices[0]


func _bind_button(short_name: String, keycode: int, button: int) -> void:
	var action = "game_" + short_name
	InputMap.add_action(action)
	var key = InputEventKey.new()
	key.physical_keycode = keycode
	InputMap.action_add_event(action, key)
	var joy = InputEventJoypadButton.new()
	joy.button_index = button
	InputMap.action_add_event(action, joy)


func menu_action(button: int, controller_name: String) -> String:
	var stadia = controller_name.to_lower().contains("stadia")
	if button == JOY_BUTTON_START:
		return "journal" if stadia else "pause"
	if button == JOY_BUTTON_BACK:
		return "pause" if stadia else "journal"
	return ""


func pause_prompt() -> String:
	return "…" if Input.get_joy_name(device).to_lower().contains("stadia") else "START / OPTIONS"


func talk_allowed() -> bool:
	var pad_pressed = device >= 0 and Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER)
	if not pad_pressed:
		tab_talk_latch = false
	elif tab_navigation:
		tab_talk_latch = true
	# Keyboard PTT remains available while LB is reserved for journal tabs.
	return Input.is_physical_key_pressed(KEY_V) or not (tab_navigation or tab_talk_latch)


func _process(_delta: float) -> void:
	# The pad latch must clear independently of whether Voice is processing.
	if device < 0 or not Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER):
		tab_talk_latch = false


func _input(event: InputEvent) -> void:
	note_device(event)


func note_device(event: InputEvent) -> void:
	var was_pad = using_pad
	if (
		event is InputEventJoypadButton
		or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3)
	):
		device = event.device
		using_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_pad = false
	if was_pad != using_pad:
		device_changed.emit()


func _connection(id: int, connected: bool) -> void:
	if connected:
		device = id
	elif device == id:
		stop_rumble()
		device = -1
		using_pad = false
	device_changed.emit()


func stick(look: bool = false) -> Vector2:
	var axes = (
		["look_left", "look_right", "look_up", "look_down"]
		if look
		else ["move_left", "move_right", "move_forward", "move_back"]
	)
	return Input.get_vector(
		"game_" + axes[0],
		"game_" + axes[1],
		"game_" + axes[2],
		"game_" + axes[3],
		clampf(float(Session.settings.pad_deadzone), 0.1, 0.4)
	)


func rumble(weak: float, strong: float, seconds: float) -> void:
	if device < 0 or not Session.settings.rumble or not get_window().has_focus():
		return
	if not Input.get_connected_joypads().has(device):
		return
	Input.start_joy_vibration(
		device, clampf(weak, 0, 1), clampf(strong, 0, 1), clampf(seconds, 0.05, 1)
	)


func stop_rumble() -> void:
	for id in Input.get_connected_joypads():
		Input.stop_joy_vibration(id)


func focus_first(root: Node) -> void:
	for child in root.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled:
			child.grab_focus()
			return
		focus_first(child)
		if get_viewport().gui_get_focus_owner() != null:
			return


func prompt(action: String) -> String:
	var keys = {"interact": "E", "journal": "J", "circle": "C", "talk": "V"}
	if not using_pad:
		return keys.get(action, action)
	var playstation = (
		Input.get_joy_name(device).to_lower().contains("playstation")
		or (Input.get_joy_name(device).to_lower().contains("dual"))
	)
	var labels = {"interact": "A", "journal": "X", "circle": "Y", "talk": "LB"}
	if Input.get_joy_name(device).to_lower().contains("stadia"):
		labels.journal = "≡ / X"
	if playstation:
		labels = {"interact": "Cross", "journal": "Square", "circle": "Triangle", "talk": "L1"}
	return labels.get(action, action)
