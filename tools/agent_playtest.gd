extends SceneTree
## Explicit opt-in local-model evaluation. Never loaded by the normal game scene.

const PlaytestCast = preload("res://tools/playtest_cast.gd")
const PlaytestModel = preload("res://tools/playtest_model.gd")
const PlaytestReport = preload("res://tools/playtest_report.gd")

var config = {
	"protocol": PlaytestCast.VERSION,
	"model": "granite-4.1-3b",
	"games": 2,
	"cycles_per_phase": 4,
	"viewers": 2,
	"teacher": "medium",
	"max_calls": 600
}
var actors: Dictionary = {}
var audiences: Array = []
var model_client: PlaytestModel
var report = PlaytestReport.new()
var api
var game: GameRules
var submitted: Dictionary = {}
var failed_calls = 0
var current_game = 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if not OS.get_cmdline_user_args().has("--live-local"):
		printerr("Explicit --live-local is required to run independent local model players.")
		quit(2)
		return
	var directory = ""
	for argument in OS.get_cmdline_user_args():
		var key = argument.get_slice("=", 0).trim_prefix("--").replace("-", "_")
		var value = argument.get_slice("=", 1)
		if key == "output":
			directory = value
		elif key in ["model", "teacher"]:
			config[key] = value
		elif key in ["games", "cycles_per_phase", "viewers", "max_calls"]:
			config[key] = int(value)
	if not valid_config() or directory == "":
		printerr("Invalid configuration or missing unique --output directory.")
		quit(2)
		return
	config["engine"] = Engine.get_version_info()
	config["clock"] = "turn-stepped; equal six-seat opportunities; model latency excluded"
	config["fingerprints"] = fingerprints()
	if not report.open(directory, config):
		printerr("Cannot create fresh ledger: ", report.storage_error)
		quit(2)
		return
	model_client = PlaytestModel.new(root)
	model_client.model = config.model
	model_client.maximum_requests = config.max_calls
	for role in CaseData.ROLES:
		actors[role] = make_actor(
			role, false, PlaytestCast.player_prompt(role, role == config.teacher)
		)
	for index in range(config.viewers):
		var profile: Dictionary = PlaytestCast.VIEWERS[index]
		var audience = make_actor(profile.id, true, PlaytestCast.viewer_prompt(profile))
		audience["stream"] = profile.stream
		audiences.append(audience)
	var complete = true
	for number in range(1, config.games + 1):
		current_game = number
		if not await play_match():
			complete = false
			break
	var valid_ratings = report.ratings.filter(func(entry): return entry.valid).size()
	var same_source = JSON.stringify(config.fingerprints) == JSON.stringify(fingerprints())
	var integrity_receipt = report.event(
		"integrity", {"source_unchanged": same_source, "valid_ratings": valid_ratings}
	)
	complete = complete and same_source and valid_ratings == config.games * (6 + config.viewers)
	complete = complete and integrity_receipt > 0
	var receipts_written = report.finish(config, complete)
	complete = complete and receipts_written
	if not receipts_written:
		printerr("Trial receipts are incomplete: ", report.storage_error)
	root.get_node("Sound").shutdown()
	root.get_node("Music").shutdown()
	await create_timer(0.2).timeout
	print(
		(
			"AGENT PARTY: %s; %d model requests; receipt directory %s"
			% ["COMPLETE" if complete else "INCOMPLETE", model_client.requests, directory]
		)
	)
	quit(0 if complete else 1)


func valid_config() -> bool:
	return (
		config.games in range(1, 21)
		and config.cycles_per_phase in range(1, 13)
		and config.viewers in range(0, 5)
		and config.max_calls in range(1, 10001)
		and CaseData.ROLES.has(config.teacher)
		and config.model.length() in range(1, 150)
	)


func make_actor(id: String, viewer: bool, instruction: String) -> Dictionary:
	return PlaytestCast.create_session(id, viewer, instruction)


func play_match() -> bool:
	game = GameRules.new()
	game.reset(CaseData.ROLES)
	api = PlaytestTools.new(game, config.teacher)
	submitted.clear()
	for role in actors:
		var actor: Dictionary = actors[role]
		api.grant(actor.token, role)
		reset_actor(actor)
	for audience in audiences:
		api.grant(audience.token, "", true, audience.stream)
		reset_actor(audience)
	if report.event("match_start", {"game": current_game, "teacher": config.teacher}) == 0:
		return false
	var phase_count = 0
	while game.state.phase != "ended":
		phase_count += 1
		if phase_count > 7 or failed_calls >= 6 or model_client.requests >= config.max_calls:
			report.event(
				"aborted",
				{"game": current_game, "phase": game.state.phase, "failures": failed_calls}
			)
			return false
		var phase: String = game.state.phase
		var sitting: int = game.state.round
		if (
			report.event("phase_start", {"game": current_game, "phase": phase, "sitting": sitting})
			== 0
		):
			return false
		print("AGENT GAME %s / sitting %s / %s" % [current_game, sitting, phase])
		for cycle in range(config.cycles_per_phase):
			# Rotate initiative. Never give one role every first chance at an object.
			for offset in range(6):
				if failed_calls >= 6 or model_client.requests >= config.max_calls:
					report.event(
						"aborted",
						{"game": current_game, "reason": "Error or request budget reached"}
					)
					return false
				if game.state.phase == "ended":
					break
				var index = (offset + cycle + current_game - 1) % 6
				if not await player_turn(actors[CaseData.ROLES[index]]):
					return false
			if game.state.phase == "ended":
				break
			var remaining_cycles = config.cycles_per_phase - cycle
			# Exercise the same timer path as native gameplay, with an explicit test clock.
			game.tick(
				game.state.remaining / remaining_cycles + (0.01 if remaining_cycles == 1 else 0.0)
			)
			if game.state.phase != phase:
				break
		for audience in audiences:
			if not await viewer_turn(audience):
				return false
	var defaults = []
	for role in CaseData.ROLES:
		if not submitted.has(role):
			defaults.append(role)
	var outcome = {
		"game": current_game,
		"ending": game.state.ending,
		"scores": game.state.scores,
		"submitted_ballots": submitted.size(),
		"defaulted_roles": defaults
	}
	if report.event("match_end", outcome) == 0:
		return false
	report.matches.append(outcome)
	for actor in actors.values() + audiences:
		if not await rate(actor):
			return false
	return true


func reset_actor(actor: Dictionary) -> void:
	actor.messages.clear()
	actor.feedback = {}
	actor.commentary.clear()
	actor.inbox.clear()
	actor.notes = actor.lessons


func player_turn(actor: Dictionary) -> bool:
	var observation = api.call_tool(actor.token, "observe", {})
	var available: Array = api.tool_list(actor.token)
	var context = {
		"game_number": current_game,
		"observation": observation,
		"controls": available,
		"last_result": actor.feedback,
		"your_notes": actor.notes,
		"lessons_from_previous_game": actor.lessons,
		"your_stream_chat": actor.inbox
	}
	actor.inbox.clear()
	var response = await query(actor, context, PlaytestCast.decision_schema(false, available))
	if not response.get("ok", false):
		actor.feedback = {"error": response.get("error", "Invalid model reply")}
		return report.storage_error == ""
	var data: Dictionary = response.data
	var args = data.get("arguments")
	if not data.get("tool") is String or not args is Dictionary:
		report.event(
			"model_error",
			{"actor": actor.id, "error": "Invalid tool/argument types", "reply": response}
		)
		failed_calls += 1
		return report.storage_error == ""
	var result = {"ok": true, "message": "Waited; no automatic action."}
	if data.tool != "wait":
		result = api.call_tool(actor.token, data.tool, args)
	actor.feedback = result
	if data.tool == "act" and args.get("action") == "vote" and result.get("ok", false):
		submitted[actor.id] = true
	var said = str(data.get("say", "")).strip_edges().left(240)
	var speech = {}
	if said != "" and game.state.phase != "ended":
		speech = api.call_tool(actor.token, "speak", {"text": said})
	store_expression(actor, data)
	report.event(
		"player_action",
		{
			"game": current_game,
			"actor": actor.id,
			"phase": game.state.phase,
			"tool": data.tool,
			"arguments": args,
			"result": result,
			"say": said,
			"speech_result": speech,
			"commentary": data.get("commentary", "")
		}
	)
	print(
		(
			"  %s: %s · %s"
			% [
				actor.id,
				data.tool,
				"ok" if result.get("ok", false) else str(result.get("error", "refused"))
			]
		)
	)
	return report.storage_error == ""


func viewer_turn(actor: Dictionary) -> bool:
	var context = {
		"game_number": current_game,
		"stream_observation": api.call_tool(actor.token, "observe", {}),
		"streamer_commentary": actors[actor.stream].commentary,
		"your_notes": actor.notes,
		"lessons_from_previous_game": actor.lessons
	}
	var response = await query(actor, context, PlaytestCast.decision_schema(true))
	if not response.get("ok", false):
		return report.storage_error == ""
	store_expression(actor, response.data)
	# No free-form viewer text is relayed, even if a model ignores its instructions.
	var reaction = str(response.data.get("reaction", ""))
	var chat = PlaytestCast.forwarded_reaction(response.data)
	if chat != "":
		actors[actor.stream].inbox.append({"viewer": actor.id, "text": chat})
	report.event(
		"viewer_reaction",
		{
			"game": current_game,
			"actor": actor.id,
			"stream": actor.stream,
			"commentary": response.data.get("commentary", ""),
			"reaction": reaction,
			"chat": chat
		}
	)
	return report.storage_error == ""


func store_expression(actor: Dictionary, data: Dictionary) -> void:
	actor.notes = str(data.get("notes", actor.notes)).left(1500)
	actor.commentary.append(str(data.get("commentary", "")).left(600))
	if actor.commentary.size() > 8:
		actor.commentary.pop_front()


func query(actor: Dictionary, context: Dictionary, schema: Dictionary) -> Dictionary:
	actor.messages.append({"role": "user", "content": JSON.stringify(context)})
	# Current channel transcript + personal notes carry knowledge; do not replay
	# four near-identical full snapshots for every seat on every request.
	while actor.messages.size() > 3:
		actor.messages.pop_front()
		actor.messages.pop_front()
	var messages = [{"role": "system", "content": actor.system}]
	messages.append_array(actor.messages)
	var receipt = report.event(
		"model_input",
		{"game": current_game, "actor": actor.id, "messages": messages, "schema": schema}
	)
	if receipt == 0:
		return {"ok": false, "error": report.storage_error}
	var response = await model_client.complete(messages, schema)
	if (
		report.event(
			"model_output", {"input_receipt": receipt, "actor": actor.id, "reply": response}
		)
		== 0
	):
		return {"ok": false, "error": report.storage_error}
	if not response.get("ok", false):
		failed_calls += 1
		report.event("model_error", {"actor": actor.id, "reply": response})
		actor.messages.append({"role": "assistant", "content": "[No valid reply was produced.]"})
	else:
		actor.messages.append({"role": "assistant", "content": response.content})
	return response


func rate(actor: Dictionary) -> bool:
	var context = {
		"request": PlaytestCast.rating_prompt(),
		"your_notes": actor.notes,
		"final_observation": api.call_tool(actor.token, "observe", {}),
		"your_stream_commentary": actor.commentary,
		"game_number": current_game
	}
	var response = await query(actor, context, PlaytestCast.rating_schema())
	if not report.add_rating(current_game, actor, response):
		return false
	if response.get("ok", false) and PlaytestReport.valid_rating(response.data):
		actor.lessons = response.data.lessons.left(1500)
	return true


func fingerprints() -> Dictionary:
	var result = {}
	for file in [
		"project.godot",
		"scripts/game_rules.gd",
		"scripts/case_data.gd",
		"scripts/haunt_rules.gd",
		"scripts/npc_rules.gd",
		"scripts/playtest_tools.gd",
		"scripts/playtest_bridge.gd",
		"scripts/round_summary.gd",
		"tools/agent_playtest.gd",
		"tools/playtest_cast.gd",
		"tools/playtest_model.gd",
		"tools/playtest_report.gd"
	]:
		result[file] = FileAccess.get_sha256("res://" + file)
	return result
