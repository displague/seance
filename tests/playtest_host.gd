extends SceneTree
## Explicit external-controller host. Six human seats, native timers, no NPC policy.
## Input capabilities are read from one caller-provided local JSON file, never logged.

var rules: GameRules
var adapter: PlaytestTools
var bridge: PlaytestBridge
var remaining = 1800.0
var running = false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if not OS.get_cmdline_user_args().has("--serve-mcp"):
		printerr("Explicit --serve-mcp and --capabilities=<local JSON file> are required.")
		quit(2)
		return
	var path = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capabilities="):
			path = argument.trim_prefix("--capabilities=")
	var file = FileAccess.open(path, FileAccess.READ) if path != "" else null
	if file == null or file.get_length() > 16384:
		printerr("Missing or oversized local capability configuration.")
		quit(2)
		return
	var parsed = JSON.new()
	var error = parsed.parse(file.get_as_text())
	file.close()
	if error != OK or not valid_config(parsed.data):
		printerr("Invalid capability configuration; no listener was started.")
		quit(2)
		return
	var config: Dictionary = parsed.data
	rules = GameRules.new()
	rules.reset(CaseData.ROLES)
	adapter = PlaytestTools.new(rules, config.get("teacher", "medium"))
	for role in CaseData.ROLES:
		if not adapter.grant(config.seats[role], role):
			printerr("Seat capabilities must be distinct.")
			quit(2)
			return
	for viewer in config.get("viewers", []):
		if not adapter.grant(viewer.token, "audience", true, viewer.get("stream_role", "")):
			printerr("Invalid or duplicate viewer capability.")
			quit(2)
			return
	remaining = float(config.get("maximum_seconds", 1800))
	bridge = PlaytestBridge.new()
	root.add_child(bridge)
	if bridge.configure(adapter, int(config.get("port", 8178))) != OK:
		printerr("The requested local MCP port is unavailable.")
		quit(2)
		return
	running = true
	print(
		(
			"PLAYTEST MCP: http://127.0.0.1:%d/mcp; capability required; native timers; six human seats"
			% bridge.port
		)
	)


func _process(delta: float) -> bool:
	if running:
		rules.tick(delta)
		remaining -= delta
		if remaining <= 0:
			running = false
			bridge.stop()
			root.get_node("Sound").shutdown()
			root.get_node("Music").shutdown()
			print("PLAYTEST MCP: configured host lifetime complete")
			quit()
	return false


static func valid_config(value: Variant) -> bool:
	if not value is Dictionary or not value.get("seats") is Dictionary:
		return false
	if value.seats.size() != 6 or not CaseData.ROLES.has(value.get("teacher", "medium")):
		return false
	for key in value:
		if key not in ["seats", "teacher", "viewers", "port", "maximum_seconds"]:
			return false
	for role in CaseData.ROLES:
		if not value.seats.get(role) is String or value.seats[role].length() < 24:
			return false
	if not value.get("viewers", []) is Array or value.get("viewers", []).size() > 12:
		return false
	for viewer in value.get("viewers", []):
		if not viewer is Dictionary or not viewer.get("token") is String:
			return false
		if viewer.token.length() < 24:
			return false
		for key in viewer:
			if key not in ["token", "stream_role"]:
				return false
		if viewer.get("stream_role", "") != "" and not CaseData.ROLES.has(viewer.stream_role):
			return false
	return (
		_integer_in(value.get("port", 8178), 1024, 65535)
		and _integer_in(value.get("maximum_seconds", 1800), 1, 7200)
	)


static func _integer_in(value: Variant, low: int, high: int) -> bool:
	return (
		(value is int or value is float)
		and is_finite(value)
		and float(value) == floor(float(value))
		and value >= low
		and value <= high
	)
