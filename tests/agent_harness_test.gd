extends SceneTree
## Offline evaluator invariants: no live model request and no microphone.

const PlaytestCast = preload("res://tools/playtest_cast.gd")
const PlaytestModel = preload("res://tools/playtest_model.gd")
const PlaytestReport = preload("res://tools/playtest_report.gd")

var checks = 0
var failures = 0


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func run() -> void:
	var first = PlaytestCast.create_session("medium", false, "one")
	var second = PlaytestCast.create_session("ghost", false, "two")
	first.messages.append({"content": "private speech"})
	first.inbox.append("private viewer reaction")
	first.notes = "my observations"
	expect(second.messages.is_empty(), "no shared per-player message history")
	expect(second.inbox.is_empty() and second.notes == "", "no shared notes or viewer inbox")
	expect(
		first.token != second.token and first.token.length() >= 24,
		"independent random seat capabilities"
	)
	expect(PlaytestCast.DIMENSIONS.size() == 5, "five frozen experience dimensions")
	expect(PlaytestCast.PLAYERS.size() == 6, "six distinct player personas")
	var schema = PlaytestCast.decision_schema(
		false, [{"name": "observe", "inputSchema": {"properties": {}}}]
	)
	expect(
		schema.anyOf[0].properties.arguments.type == "object",
		"native structured tool arguments, no JSON string double-encoding"
	)
	var inspect_schema = {
		"type": "object", "properties": {"id": {"type": "string"}}, "required": ["id"]
	}
	var strict = PlaytestCast.decision_schema(
		false, [{"name": "inspect", "inputSchema": inspect_schema}]
	)
	expect(
		strict.anyOf[1].properties.arguments.required == ["id"],
		"per-tool required id survives schema composition"
	)
	expect(strict.anyOf[1].properties.keys()[0] == "tool", "tool selected before argument decoding")
	for role in PlaytestCast.PLAYERS:
		expect(
			PlaytestCast.player_prompt(role, false).length() > 200,
			"role receives a first-play persona " + role
		)
	expect(
		(
			PlaytestCast.forwarded_reaction(
				{"reaction": "confused_phase", "commentary": "Secret killer clue"}
			)
			== PlaytestCast.REACTIONS.confused_phase
		),
		"only authored meta reaction can be forwarded"
	)
	for unsafe in [
		{"reaction": "the code is 1913"}, {"chat_message": "doctor did it"}, {"reaction": 999}
	]:
		expect(
			PlaytestCast.forwarded_reaction(unsafe) == "",
			"unrecognized or free viewer text not forwarded"
		)
	var transport = PlaytestModel.new(root)
	transport.maximum_requests = 0
	var response = await transport.complete([], {})
	expect(
		not response.ok and transport.requests == 0,
		"budget exhaustion refuses before any HTTP request"
	)
	var rating = {
		"ratings": {},
		"friction": [],
		"memorable_moment": "I heard the first spirit sign.",
		"lessons": "Learned from my own game"
	}
	for id in PlaytestCast.DIMENSIONS:
		rating.ratings[id] = {"score": 3, "reason": "Mixed", "example": "An observed turn"}
	expect(PlaytestReport.valid_rating(rating), "complete five-dimension rating accepted")
	for invalid_score in [0, 6, 2.5, "5", INF, NAN]:
		var invalid = rating.duplicate(true)
		invalid.ratings.clarity.score = invalid_score
		expect(
			not PlaytestReport.valid_rating(invalid), "invalid rating rejected without score repair"
		)
	var missing = rating.duplicate(true)
	missing.ratings.erase("agency")
	expect(not PlaytestReport.valid_rating(missing), "missing dimension never imputed")
	for field in ["reason", "example"]:
		for value in ["", " \n ", 7, null]:
			var invalid = rating.duplicate(true)
			invalid.ratings.clarity[field] = value
			expect(not PlaytestReport.valid_rating(invalid), "rating explanation must contain text")
	for field in ["memorable_moment", "lessons"]:
		for value in ["", " \t ", 7, null]:
			var invalid = rating.duplicate(true)
			invalid[field] = value
			expect(
				not PlaytestReport.valid_rating(invalid), "observed moment and learning required"
			)
		var absent = rating.duplicate(true)
		absent.erase(field)
		expect(
			not PlaytestReport.valid_rating(absent), "required narrative field cannot be missing"
		)
	for value in [[7], [null], [""], ["  "], {}, "friction"]:
		var invalid = rating.duplicate(true)
		invalid.friction = value
		expect(
			not PlaytestReport.valid_rating(invalid), "friction is a list of nonempty text entries"
		)
	expect(not PlaytestReport.valid_rating([]), "non-object rating rejected safely")
	var record = PlaytestReport.new()
	var path = ProjectSettings.globalize_path(
		"res://artifacts/harness-" + str(Time.get_ticks_usec())
	)
	var configuration = {
		"protocol": "offline-test", "model": "none", "games": 1, "teacher": "medium"
	}
	expect(record.open(path, configuration), "fresh append-only receipt created")
	var duplicate = PlaytestReport.new()
	expect(not duplicate.open(path, configuration), "existing receipt cannot be overwritten")
	record.event("model_error", {"error": "intentional fixture failure"})
	record.add_rating(1, first, {"ok": true, "data": rating})
	record.add_rating(1, second, {"ok": false, "error": "fixture unavailable"})
	expect(record.finish(configuration, false), "incomplete trial still produces verified receipts")
	var lines = FileAccess.get_file_as_string(path.path_join("events.jsonl")).strip_edges().split(
		"\n"
	)
	expect(lines.size() == 6, "raw events precede derived report and final receipt confirmation")
	var output = FileAccess.get_file_as_string(path.path_join("report.md"))
	expect(
		output.contains("unavailable") and output.contains("incomplete"),
		"missing ratings and incomplete run visible"
	)
	expect(
		output.contains("not human satisfaction"),
		"report preserves synthetic-observation limitation"
	)
	var finalized: Dictionary = JSON.parse_string(lines[-1])
	expect(
		(
			finalized.kind == "receipt_finalized"
			and not finalized.data.complete
			and finalized.data.report_sha256 == FileAccess.get_sha256(path.path_join("report.md"))
		),
		"final receipt confirms original report hash without changing incomplete status"
	)
	storage_cases(path, configuration, first, rating)
	root.get_node("Sound").shutdown()
	root.get_node("Music").shutdown()
	await create_timer(0.2).timeout
	print("AGENT HARNESS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func storage_cases(
	path: String, configuration: Dictionary, actor: Dictionary, rating: Dictionary
) -> void:
	var closed = PlaytestReport.new()
	expect(closed.open(path + "-closed", configuration), "closed-ledger fixture created")
	closed.close_ledger()
	expect(closed.event("lost", {}) == 0, "closed ledger cannot claim an event receipt")
	expect(
		not closed.add_rating(1, actor, {"ok": true, "data": rating}) and closed.ratings.is_empty(),
		"missing raw rating cannot enter derived ratings"
	)
	expect(not closed.finish(configuration, true), "closed ledger cannot finish successfully")
	expect(
		(
			closed.storage_error != ""
			and not FileAccess.file_exists((path + "-closed").path_join("report.md"))
		),
		"ledger failure is sticky and does not create a success report"
	)
	var truncated = PlaytestReport.new()
	expect(truncated.open(path + "-truncated", configuration), "truncated-ledger fixture created")
	truncated.ledger.resize(1)
	expect(truncated.event("after_truncation", {}) == 0, "truncated ledger fails byte-count check")
	expect(not truncated.finish(configuration, true), "truncation cannot produce successful finish")
	var corrupted = PlaytestReport.new()
	expect(
		corrupted.open(path + "-corrupted", configuration), "same-length corruption fixture created"
	)
	corrupted.ledger.seek(0)
	corrupted.ledger.store_string("X")
	corrupted.ledger.seek_end()
	expect(
		not corrupted.finish(configuration, true),
		"full ledger readback detects same-length corruption"
	)
	expect(
		corrupted.storage_error.contains("readback"), "hash mismatch is retained as storage failure"
	)
	expect(
		(
			not FileAccess.file_exists((path + "-corrupted").path_join("report.md"))
			and not (
				FileAccess
				. get_file_as_string((path + "-corrupted").path_join("events.jsonl"))
				. contains("receipt_finalized")
			)
		),
		"corrupted raw ledger cannot produce a report or final success marker"
	)
	var blocked = PlaytestReport.new()
	expect(blocked.open(path + "-blocked", configuration), "blocked-report fixture created")
	DirAccess.make_dir_absolute((path + "-blocked").path_join("report.md"))
	expect(not blocked.finish(configuration, true), "unwritable report target fails closed")
	var blocked_raw = FileAccess.get_file_as_string((path + "-blocked").path_join("events.jsonl"))
	expect(
		blocked_raw.contains("run_end") and not blocked_raw.contains("receipt_finalized"),
		"raw outcome is retained but failed report is never finalized"
	)
	var preserved = PlaytestReport.new()
	expect(preserved.open(path + "-preserved", configuration), "report-overwrite fixture created")
	var existing_path = (path + "-preserved").path_join("report.md")
	var existing = FileAccess.open(existing_path, FileAccess.WRITE)
	existing.store_string("Existing receipt must survive.")
	existing.close()
	expect(not preserved.finish(configuration, true), "existing report cannot be overwritten")
	expect(
		FileAccess.get_file_as_string(existing_path) == "Existing receipt must survive.",
		"existing report bytes are preserved"
	)
	var unusable = PlaytestReport.new()
	expect(
		not unusable.open(existing_path.path_join("child"), configuration),
		"unwritable ledger parent is rejected before any model request"
	)
	var finished = PlaytestReport.new()
	expect(finished.open(path + "-finished", configuration), "completed receipt fixture created")
	expect(finished.finish(configuration, true), "checked receipt set can finish successfully")
	var digest = FileAccess.get_sha256((path + "-finished").path_join("events.jsonl"))
	expect(not finished.finish(configuration, true), "receipt finalization cannot be repeated")
	expect(
		FileAccess.get_sha256((path + "-finished").path_join("events.jsonl")) == digest,
		"repeated finish leaves previous receipts unchanged"
	)
