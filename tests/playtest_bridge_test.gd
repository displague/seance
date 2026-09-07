extends SceneTree
## No LLM, microphone or rendering: native adapter authority plus real HTTP MCP.

var checks = 0
var failures = 0
var game: GameRules
var api: PlaytestTools
var bridge: PlaytestBridge
var tokens: Dictionary = {}
var viewer_token = ""
var stream_token = ""


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func token() -> String:
	return Crypto.new().generate_random_bytes(32).hex_encode()


func call_as(role: String, name: String, arguments: Dictionary = {}) -> Dictionary:
	return api.call_tool(tokens[role], name, arguments)


func run() -> void:
	game = GameRules.new()
	game.reset(CaseData.ROLES)
	api = PlaytestTools.new(game, "medium")
	for role in CaseData.ROLES:
		tokens[role] = token()
		expect(api.grant(tokens[role], role), "unique capability for " + role)
	viewer_token = token()
	stream_token = token()
	expect(api.grant(viewer_token, "audience", true), "grant public viewer")
	expect(api.grant(stream_token, "stream-audience", true, "heir"), "grant one stream viewer")
	expect(not api.grant("short", "medium"), "reject short capability")
	expect(not api.grant(tokens.medium, "doctor"), "capability cannot be rebound")
	expect(not api.grant(token(), "not-a-role"), "invalid seat rejected")
	expect(not api.grant(token(), "audience", true, "invalid"), "invalid stream rejected")
	expect(not api.call_tool("bad", "observe").ok, "authentication required in-process too")
	expect(
		not api.call_tool(viewer_token, "act", {"action": "manifest"}).ok, "viewer cannot mutate"
	)
	expect(
		not api.call_tool(stream_token, "walk", {"destination": "Library"}).ok,
		"stream viewer cannot move"
	)
	expect(not call_as("heir", "read_instructions").ok, "non-teacher has no guide access")
	expect(call_as("medium", "read_instructions").ok, "teacher may read guide")
	expect(api.instruction_reads.get("medium", 0) == 1, "instruction access is auditable")
	expect(
		api.tool_list(tokens.heir).all(func(tool): return tool.name != "read_instructions"),
		"non-teacher guide tool absent"
	)
	expect(
		api.tool_list(tokens.medium).any(func(tool): return tool.name == "read_instructions"),
		"teacher guide discoverable"
	)
	expect(api.tool_list(viewer_token).size() == 2, "viewer tools are read-only")
	var initial = call_as("heir", "observe")
	expect(
		initial.room == "Séance Parlour" and initial.phase == "investigation",
		"initial player scene"
	)
	expect(initial.visible_objects.size() == 2, "only parlour objects visible")
	expect(not JSON.stringify(initial).contains("1913"), "safe solution not in initial observation")
	expect(
		not JSON.stringify(initial).contains(CaseData.PEOPLE.doctor.secret),
		"other private motive absent"
	)
	expect(not JSON.stringify(initial).contains(CaseData.CLUES.will.text), "unread document absent")
	expect(
		not initial.has("positions") and not initial.has("votes"),
		"no raw state or positions leaked"
	)
	expect(not call_as("heir", "inspect", {"id": "will"}).ok, "remote document inspection denied")
	expect(not call_as("heir", "walk", {"destination": "will"}).ok, "unseen object route denied")
	expect(not call_as("heir", "act", {"action": "advance"}).ok, "no debug timer action")
	expect(
		not call_as("heir", "act", {"action": "collect", "payload": {"id": "will"}}).ok,
		"normal distance rule enforced"
	)
	var before = float(game.state.remaining)
	var walked = call_as("heir", "walk", {"destination": "Library"})
	expect(
		walked.ok and walked.travel_seconds > 1 and walked.movement_steps > 50,
		"physical multistep route to library"
	)
	expect(game.state.remaining == before, "coordinator alone advances timer")
	expect(
		not call_as("heir", "walk", {"destination": "Conservatory"}).ok,
		"must use adjoining parlour exit"
	)
	expect(call_as("heir", "walk", {"destination": "will"}).ok, "approach visible will")
	var inspected = call_as("heir", "inspect", {"id": "will"})
	expect(
		inspected.ok and inspected.object.has("summary") and not inspected.object.has("text"),
		"uncollected clue has preview only"
	)
	expect(inspected.object.actions.is_empty(), "sealed will offers no collection")
	expect(
		not call_as("heir", "act", {"action": "collect", "payload": {"id": "will"}}).ok,
		"MCP cannot bypass chapter gate"
	)
	# Advance the real phase state, then return physically to the object.
	game.advance()
	game.advance()
	call_as("heir", "walk", {"destination": "Library"})
	call_as("heir", "walk", {"destination": "will"})
	expect(
		(
			call_as(
				"heir", "act", {"action": "collect", "payload": {"id": "will", "role": "doctor"}}
			)
			. ok
		),
		"legal collection"
	)
	expect(game.state.evidence.will.holder == "heir", "payload cannot spoof actor identity")
	expect(
		call_as("heir", "journal").evidence[0].text == CaseData.CLUES.will.text,
		"collected full text in own journal"
	)
	expect(
		not call_as("doctor", "inspect", {"id": "will"}).ok,
		"another guest cannot inspect owned private document"
	)
	expect(
		not JSON.stringify(api.call_tool(viewer_token, "observe")).contains(
			CaseData.CLUES.will.text
		),
		"public viewer cannot see private document"
	)
	expect(
		(
			api.call_tool(stream_token, "observe").stream_journal.evidence[0].text
			== CaseData.CLUES.will.text
		),
		"assigned stream viewer sees stream journal"
	)
	expect(
		not JSON.stringify(api.call_tool(stream_token, "observe")).contains(
			CaseData.PEOPLE.doctor.secret
		),
		"stream viewer remains isolated from other streams"
	)
	expect(
		call_as("heir", "act", {"action": "reveal", "payload": {"id": "will"}}).ok,
		"reveal uses normal rule"
	)
	expect(
		api.call_tool(viewer_token, "observe").public_evidence[0].text == CaseData.CLUES.will.text,
		"public disclosure reaches spectators"
	)
	expect(
		call_as("heir", "walk", {"destination": "ring"}).ok, "approach inheritance around tables"
	)
	expect(
		call_as("heir", "act", {"action": "collect", "payload": {"id": "ring"}}).ok,
		"collect inheritance"
	)
	expect(
		(
			call_as(
				"heir", "act", {"action": "give", "payload": {"id": "ring", "target": "keeper"}}
			)
			. ok
		),
		"give is consequential"
	)
	expect(game.state.items.ring == "keeper", "gift changed authority")
	expect(
		not (
			call_as(
				"heir", "act", {"action": "give", "payload": {"id": "ring", "target": "doctor"}}
			)
			. ok
		),
		"double-spend fails"
	)
	await _navigation_and_puzzle()
	await _communication_and_http()
	_affordance_fidelity()
	bridge.stop()
	await _standalone_host()
	bridge.queue_free()
	print("PLAYTEST BRIDGE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _affordance_fidelity() -> void:
	var original = game.state.duplicate(true)
	game.reset(CaseData.ROLES)
	for name in ["inspect", "walk", "speak", "act"]:
		expect(not call_as("medium", name).ok, "missing required arguments rejected for " + name)
	for action in PlaytestTools.PAYLOAD_KEYS:
		var payload = {}
		for field in PlaytestTools.PAYLOAD_KEYS[action]:
			payload[field] = "test"
		for field in PlaytestTools.PAYLOAD_KEYS[action]:
			var missing = payload.duplicate()
			missing.erase(field)
			var rejected = call_as("medium", "act", {"action": action, "payload": missing})
			expect(
				not rejected.ok and rejected.error.contains("requires text fields"),
				action + " requires " + field
			)
	for role in ["medium", "ghost"]:
		var schema = (
			api.tool_list(tokens[role]).filter(func(tool): return tool.name == "act")[0].inputSchema
		)
		for branch in schema.anyOf:
			var action = branch.properties.action.enum[0]
			expect(
				branch.required == ["action", "payload"],
				"schema requires action plus payload for " + action
			)
			expect(
				branch.properties.payload.required == PlaytestTools.PAYLOAD_KEYS[action],
				"schema binds exact payload fields for " + action
			)
	var unchanged = game.state.duplicate(true)
	var ghost = call_as("ghost", "observe").available_actions
	expect(game.state == unchanged, "deriving legal controls never mutates authority")
	expect(not ghost.has("possess"), "sitting one never advertises possession as available")
	_exercise_examples("ghost", "sitting one")
	game.state.energy = 14
	expect(
		call_as("ghost", "observe").available_actions.is_empty(),
		"insufficient ghost energy hides unaffordable actions"
	)
	for cost in [15, 20, 25, 40]:
		game.state.energy = cost
		game.state.round = 2
		_exercise_examples("ghost", "energy " + str(cost))
	game.state.energy = 100
	game.state.haunt.cooldown = 10
	ghost = call_as("ghost", "observe").available_actions
	expect(
		not ghost.has("breeze") and not ghost.has("weep"), "active recovery hides both haunt verbs"
	)
	game.state.haunt.cooldown = 0
	game.state.phase = "judgment"
	ghost = call_as("ghost", "observe").available_actions
	expect(
		not ghost.has("breeze") and not ghost.has("weep"), "judgment never advertises room haunting"
	)
	expect(
		ghost.has("manifest") and ghost.has("possess") and ghost.has("silence"),
		"other ghost verbs remain legal at judgment as native rules permit"
	)
	expect(
		not ghost.vote.ending.has("release"), "unprepared release is not an available ballot option"
	)
	_exercise_examples("ghost", "judgment")
	game.state.tasks.radio = "medium"
	game.state.tasks.candles = "medium"
	expect(
		call_as("medium", "observe").available_actions.vote.ending.has("release"),
		"prepared release becomes an available ballot option"
	)
	_exercise_examples("medium", "prepared judgment")
	game.state.votes.medium = {"culprit": "none", "heir": "heir", "ending": "banish"}
	expect(
		not call_as("medium", "observe").available_actions.has("vote"),
		"sealed ballot cannot be advertised again"
	)
	game.reset(CaseData.ROLES)
	game.state.round = 3  # Exercise all unsealed-object variants, not just chapter one.
	game.state.positions.medium = Vector3(-12, 0, -1.5)
	_exercise_examples("medium", "nearby library objects")
	game.state.evidence.will.holder = "medium"
	game.state.items.ring = "medium"
	_exercise_examples("medium", "owned clue and item")
	game.state.evidence.will.public = true
	var living = call_as("medium", "observe").available_actions
	expect(
		not living.has("reveal") and not living.has("destroy"),
		"public clue cannot be revealed or destroyed again"
	)
	_exercise_examples("medium", "public clue can still be given")
	game.state.phase = "seance"
	living = call_as("medium", "observe").available_actions
	expect(
		not living.has("collect") and not living.has("task"),
		"seance hides investigation-only actions"
	)
	game.state.positions.medium = Vector3(-13.5, 0, 1.5)
	expect(
		call_as("medium", "inspect", {"id": "ledger"}).object.actions.is_empty(),
		"inspection does not offer collection during seance"
	)
	game.state.positions.medium = Vector3(-13.5, 0, -1.5)
	expect(
		call_as("medium", "inspect", {"id": "radio"}).object.actions.is_empty(),
		"inspection does not offer a task during seance"
	)
	game.state.phase = "investigation"
	game.state.haunt.kind = "weep"
	game.state.haunt.room = "Library"
	game.state.haunt.remaining = 16
	living = call_as("medium", "observe").available_actions
	expect(
		living.calm.payload_example == {"target": "Library"},
		"calm wire field is target, matching GameRules"
	)
	_exercise_examples("medium", "standing inside cold room")
	expect(
		not call_as("keeper", "observe").available_actions.has("calm"),
		"guest outside cold room cannot calm it"
	)
	game.state.positions.ghost = game.state.positions.medium
	expect(
		call_as("ghost", "inspect", {"id": "radio"}).object.actions.is_empty(),
		"ghost inspection cannot offer living-only preparation"
	)
	for id in CaseData.TASKS:
		game.state.positions.medium = CaseData.TASKS[id].pos
		_exercise_examples("medium", "apparatus " + id)
	game.state.phase = "ended"
	for role in CaseData.ROLES:
		expect(
			call_as(role, "observe").available_actions.is_empty(),
			"ended controls empty for " + role
		)
	game.state = original


func _exercise_examples(role: String, context: String) -> void:
	var options: Dictionary = call_as(role, "observe").available_actions
	for action in options:
		var option: Dictionary = options[action]
		var payloads: Array = []
		if option.has("payload_example"):
			payloads.append(option.payload_example.duplicate())
		if action == "task":
			for id in option.id:
				# This test fixture knows the authored oracle; player-facing code never
				# reads solution to populate controls, observations or model context.
				payloads.append({"id": id, "answer": CaseData.TASKS[id].solution})
		elif action == "vote":
			for ending in option.ending:
				payloads.append({"culprit": "none", "heir": "heir", "ending": ending})
		elif option.has("word"):
			for word in option.word:
				payloads.append({"word": word})
		elif option.has("target"):
			for target in option.target:
				var payload = {"target": target}
				if action == "give":
					payload.id = option.id[0]
				payloads.append(payload)
		elif option.has("id"):
			for id in option.id:
				payloads.append({"id": id})
		for payload in payloads:
			var before = game.state.duplicate(true)
			var ballots = api.submitted_by_actor.duplicate()
			var result = call_as(role, "act", {"action": action, "payload": payload})
			expect(
				result.ok,
				"advertised " + action + " executable: " + context + " " + JSON.stringify(payload)
			)
			if result.ok and role == "ghost" and option.has("cost"):
				expect(
					is_equal_approx(before.energy - game.state.energy, float(option.cost)),
					"advertised energy cost for " + action
				)
			game.state = before
			api.submitted_by_actor = ballots


func _standalone_host() -> void:
	var host_script = load("res://tests/playtest_host.gd")
	var config = {"seats": tokens.duplicate(), "port": bridge.port, "maximum_seconds": 2}
	expect(host_script.valid_config(config), "standalone config with six scoped tokens accepted")
	expect(not host_script.valid_config({"seats": {}}), "host rejects missing seat assignments")
	for invalid in ["teacher", "port", "maximum_seconds", "viewers"]:
		var candidate = config.duplicate(true)
		candidate[invalid] = {"teacher": "all", "port": 80, "maximum_seconds": -1, "viewers": "bad"}[invalid]
		expect(not host_script.valid_config(candidate), "host rejects invalid " + invalid)
	var path = OS.get_cache_dir().path_join("seance-mcp-test-%d.json" % OS.get_process_id())
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config))
	file.close()
	var args = PackedStringArray(
		[
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"--script",
			"res://tests/playtest_host.gd",
			"--",
			"--serve-mcp",
			"--capabilities=" + path
		]
	)
	var pid = OS.create_process(OS.get_executable_path(), args, false)
	expect(pid > 0, "start native standalone host without visible console")
	var response: Dictionary = {"status": 0}
	var deadline = Time.get_ticks_msec() + 1500
	while response.status != 200 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
		response = await http(tokens.medium, {"jsonrpc": "2.0", "id": 20, "method": "initialize"})
	expect(response.status == 200, "separate-process host serves authenticated MCP")
	deadline = Time.get_ticks_msec() + 3000
	while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
		expect(false, "standalone host honors configured lifetime")
	else:
		expect(true, "standalone host honors configured lifetime")
	DirAccess.remove_absolute(path)


func _navigation_and_puzzle() -> void:
	expect(not PlaytestTools.walkable(Vector3(0, 0, 0)), "central table blocks walking")
	expect(not PlaytestTools.walkable(Vector3(-8, 0, -3)), "partition wall blocks shortcut")
	expect(PlaytestTools.walkable(Vector3(-8, 0, 0)), "door aperture remains open")
	expect(not PlaytestTools.walkable(Vector3(-12, 0, -2.9)), "library desk blocks walking")
	for place in ["Séance Parlour", "Memorial Chapel", "birth"]:
		expect(call_as("heir", "walk", {"destination": place}).ok, "navigates to " + place)
	expect(
		call_as("heir", "act", {"action": "collect", "payload": {"id": "birth"}}).ok,
		"recover birth register physically"
	)
	var birth = call_as("heir", "inspect", {"id": "birth"}).object.text
	var year = RegEx.new()
	year.compile("born [0-9]+ [A-Za-z]+ ([0-9]{4})")
	var found = year.search(birth)
	expect(found != null, "player can derive year from inspected record")
	game.advance()
	game.advance()
	call_as("heir", "walk", {"destination": "Memorial Chapel"})
	expect(call_as("heir", "walk", {"destination": "safe"}).ok, "approach reliquary")
	var safe = call_as("heir", "inspect", {"id": "safe"})
	expect(
		safe.ok and not safe.object.has("solution"), "apparatus doesn't expose solution property"
	)
	expect(
		not (
			call_as("heir", "act", {"action": "task", "payload": {"id": "safe", "answer": "0000"}})
			. ok
		),
		"incorrect code rejected"
	)
	expect(
		(
			call_as(
				"heir",
				"act",
				{"action": "task", "payload": {"id": "safe", "answer": found.get_string(1)}}
			)
			. ok
		),
		"observed year solves reliquary"
	)
	for place in ["Séance Parlour", "candles"]:
		expect(
			call_as("heir", "walk", {"destination": place}).ok,
			"walk to " + place + " without crossing table"
		)
	expect(game.nearby("heir", "candles"), "stop outside table within interaction range")
	expect(
		call_as("heir", "inspect", {"id": "candles"}).object.symbols.size() == 5,
		"candle controls expose choices not answer"
	)
	for place in ["Conservatory", "vial", "letter", "locket", "flowers"]:
		expect(
			call_as("heir", "walk", {"destination": place}).ok,
			"navigate furnished conservatory to " + place
		)
	game.tick(game.state.remaining)
	expect(game.state.phase == "seance", "authoritative timer changes phase")
	expect(
		game.state.evidence.ledger.holder == "",
		"all-six-human match has no scripted NPC collection"
	)
	expect(game.state.evidence.vial.holder == "", "no offscreen NPC knowledge acquisition")
	expect(
		call_as("heir", "walk", {"destination": "Library"}).ok,
		"seance movement remains available as in the native game"
	)


func _communication_and_http() -> void:
	var marker = "private-ghost-test-" + str(Time.get_ticks_msec())
	expect(call_as("ghost", "speak", {"text": marker}).ok, "ghost speaks")
	expect(
		JSON.stringify(call_as("medium", "observe").messages).contains(marker),
		"Medium hears ghost during sitting"
	)
	expect(
		not JSON.stringify(call_as("heir", "observe").messages).contains(marker),
		"other living seat cannot hear ghost"
	)
	expect(
		not JSON.stringify(api.call_tool(viewer_token, "observe")).contains(marker),
		"public spectator cannot hear ghost"
	)
	expect(
		not JSON.stringify(api.call_tool(stream_token, "observe")).contains(marker),
		"non-Medium stream doesn't leak ghost"
	)
	expect(
		call_as("medium", "speak", {"text": "The ghost spoke to me."}).ok,
		"Medium can relay socially"
	)
	expect(
		JSON.stringify(call_as("heir", "observe").messages).contains("The ghost spoke to me."),
		"other guests hear relay"
	)
	bridge = PlaytestBridge.new()
	root.add_child(bridge)
	var opened = false
	for trial_port in range(18781, 18791):
		if bridge.configure(api, trial_port) == OK:
			opened = true
			break
	expect(opened, "native loopback HTTP listener opened")
	if not opened:
		return
	var request = {
		"jsonrpc": "2.0",
		"id": 1,
		"method": "initialize",
		"params":
		{
			"protocolVersion": "2025-11-25",
			"capabilities": {},
			"clientInfo": {"name": "native-test", "version": "1"}
		}
	}
	var response = await http(tokens.medium, request)
	expect(
		response.status == 200 and response.data.result.protocolVersion == "2025-11-25",
		"real HTTP MCP initialize"
	)
	response = await http(tokens.medium, {"jsonrpc": "2.0", "method": "notifications/initialized"})
	expect(response.status == 202, "notification acknowledged without RPC body")
	response = await http(tokens.medium, {"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
	expect(response.data.result.tools.size() == 7, "HTTP teacher tool discovery")
	response = await http(
		tokens.medium,
		{
			"jsonrpc": "2.0",
			"id": 3,
			"method": "tools/call",
			"params": {"name": "observe", "arguments": {}}
		}
	)
	expect(response.data.result.structuredContent.role == "medium", "HTTP bound seat observation")
	expect(not response.data.result.isError, "MCP successful tool result")
	response = await http(tokens.medium, request, ["Origin: https://evil.example"])
	expect(response.status == 403, "cross-origin request rejected")
	response = await http("invalid", request)
	expect(response.status == 401, "HTTP invalid bearer rejected")
	response = await http(tokens.medium, request, ["MCP-Protocol-Version: 1999-01-01"])
	expect(response.status == 400, "unsupported version rejected")
	response = await http(viewer_token, request)
	expect(response.status == 200, "viewer initializes own capability")
	response = await http(
		viewer_token,
		{
			"jsonrpc": "2.0",
			"id": 4,
			"method": "tools/call",
			"params": {"name": "act", "arguments": {"action": "manifest"}}
		}
	)
	expect(response.data.result.isError, "HTTP viewer action denied")
	expect(bridge.dispatch_rpc(tokens.medium, []).error.code == -32600, "JSON-RPC batch refused")
	expect(
		(
			(
				bridge
				. dispatch_rpc(
					tokens.medium, {"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": []}
				)
				. error
				. code
			)
			== -32602
		),
		"malformed params safely rejected"
	)
	api.revoke(viewer_token)
	response = await http(viewer_token, request)
	expect(response.status == 401, "revocation affects active initialized clients")
	response = await raw_http(
		(
			"POST /mcp HTTP/1.1\r\nHost: 127.0.0.1:%d\r\nAuthorization: Bearer %s\r\nContent-Type: application/json\r\nContent-Length: 999999\r\n\r\n"
			% [bridge.port, tokens.medium]
		)
	)
	expect(response.status == 413, "declared oversized body rejected before allocation")
	response = await raw_http(
		(
			"POST /mcp HTTP/1.1\r\nHost: evil.example\r\nAuthorization: Bearer %s\r\nContent-Type: application/json\r\nContent-Length: 0\r\n\r\n"
			% tokens.medium
		)
	)
	expect(response.status == 403, "DNS rebinding host rejected")
	response = await raw_http(
		(
			"POST /mcp HTTP/1.1\r\nHost: 127.0.0.1:%d\r\nAuthorization: Bearer %s\r\nContent-Type: application/json\r\nContent-Length: 0\r\nContent-Length: 1\r\n\r\n"
			% [bridge.port, tokens.medium]
		)
	)
	expect(response.status == 400, "duplicate framing header rejected")
	response = await raw_http(
		(
			"POST /mcp HTTP/1.1\r\nHost: 127.0.0.1:%d\r\nAuthorization: Bearer %s\r\nContent-Type: application/json\r\nContent-Length: 1\r\n\r\n{"
			% [bridge.port, tokens.medium]
		)
	)
	expect(
		response.status == 200 and response.data.error.code == -32700,
		"invalid JSON reported without engine parse error"
	)


func http(capability: String, message: Dictionary, extra: PackedStringArray = []) -> Dictionary:
	var client = HTTPRequest.new()
	root.add_child(client)
	client.timeout = 3
	client.max_redirects = 0
	var headers = PackedStringArray(
		["Content-Type: application/json", "Authorization: Bearer " + capability]
	)
	headers.append_array(extra)
	var error = client.request(
		"http://127.0.0.1:%d/mcp" % bridge.port,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(message)
	)
	if error != OK:
		client.queue_free()
		return {"status": 0, "data": {}}
	var received = await client.request_completed
	client.queue_free()
	var parsed = JSON.new()
	parsed.parse(received[3].get_string_from_utf8())
	return {"status": received[1], "data": parsed.data if parsed.data is Dictionary else {}}


func raw_http(request: String) -> Dictionary:
	var client = StreamPeerTCP.new()
	client.connect_to_host("127.0.0.1", bridge.port)
	var deadline = Time.get_ticks_msec() + 3000
	while (
		client.get_status() == StreamPeerTCP.STATUS_CONNECTING and Time.get_ticks_msec() < deadline
	):
		client.poll()
		await process_frame
	client.put_data(request.to_utf8_buffer())
	var response = PackedByteArray()
	while Time.get_ticks_msec() < deadline:
		client.poll()
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			break
		var available = client.get_available_bytes()
		if available > 0:
			var packet = client.get_data(available)
			response.append_array(packet[1])
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			break
		await process_frame
	client.disconnect_from_host()
	var wire = response.get_string_from_utf8()
	var parsed = JSON.new()
	parsed.parse(wire.get_slice("\r\n\r\n", 1))
	return {
		"status": int(wire.get_slice(" ", 1)),
		"data": parsed.data if parsed.data is Dictionary else {}
	}
