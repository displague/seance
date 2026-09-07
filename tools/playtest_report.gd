class_name PlaytestReport
extends RefCounted
## Append-only machine receipts first; derived Markdown is a separate artifact.

const PlaytestCast = preload("res://tools/playtest_cast.gd")

var directory = ""
var ledger: FileAccess
var event_number = 0
var ratings: Array = []
var matches: Array = []
var errors = 0
var storage_error = ""
var ledger_bytes = 0
var ledger_digest = HashingContext.new()
var last_event_line = ""


func open(path: String, configuration: Dictionary) -> bool:
	if ledger != null or storage_error != "":
		return _storage_failed("A receipt writer cannot be reopened or reused.")
	directory = path
	for name in ["events.jsonl", "report.md"]:
		if (
			FileAccess.file_exists(path.path_join(name))
			or DirAccess.dir_exists_absolute(path.path_join(name))
		):
			return _storage_failed("Existing receipt target cannot be overwritten: " + name)
	var ancestor = path.simplify_path()
	while ancestor != "":
		if FileAccess.file_exists(ancestor):
			return _storage_failed("A file blocks the receipt directory path.")
		var parent = ancestor.get_base_dir()
		if parent == ancestor:
			break
		ancestor = parent
	if DirAccess.make_dir_recursive_absolute(path) != OK:
		return _storage_failed("Cannot create receipt directory.")
	ledger = FileAccess.open(path.path_join("events.jsonl"), FileAccess.WRITE)
	if ledger == null:
		return _storage_failed("Cannot open a fresh ledger: " + str(FileAccess.get_open_error()))
	ledger_digest.start(HashingContext.HASH_SHA256)
	return event("configuration", configuration) > 0


func event(kind: String, data: Dictionary) -> int:
	if storage_error != "":
		return 0
	if ledger == null or not ledger.is_open():
		_storage_failed("Ledger is not open; receipt was not recorded.")
		return 0
	if ledger.get_position() != ledger_bytes or ledger.get_length() != ledger_bytes:
		_storage_failed("Ledger length or append position changed unexpectedly.")
		return 0
	var line = (
		JSON.stringify(
			{
				"event": event_number + 1,
				"kind": kind,
				"utc": Time.get_datetime_string_from_system(true),
				"data": data
			}
		)
		+ "\n"
	)
	if not _write_checked(ledger, line, "ledger"):
		return 0
	ledger_bytes += line.to_utf8_buffer().size()
	ledger_digest.update(line.to_utf8_buffer())
	last_event_line = line
	event_number += 1
	if kind == "model_error":
		errors += 1
	return event_number


func add_rating(game_number: int, actor: Dictionary, reply: Dictionary) -> bool:
	var record = {
		"game": game_number,
		"actor": actor.id,
		"viewer": actor.viewer,
		"stream": actor.get("stream", ""),
		"reply": reply
	}
	var valid = valid_rating(reply.get("data", {})) if reply.get("ok", false) else false
	record["valid"] = valid
	record["receipt"] = event("rating", record)
	if record.receipt == 0:
		return false
	ratings.append(record)
	return true


static func valid_rating(data: Variant) -> bool:
	if not data is Dictionary or not data.get("ratings") is Dictionary:
		return false
	for id in PlaytestCast.DIMENSIONS:
		var entry = data.ratings.get(id, {})
		if not entry is Dictionary:
			return false
		var score = entry.get("score", 0)
		if not (score is int or score is float) or not is_finite(float(score)):
			return false
		if score != int(score) or score < 1 or score > 5:
			return false
		if not nonempty_text(entry.get("reason")) or not nonempty_text(entry.get("example")):
			return false
	if not nonempty_text(data.get("lessons")) or not nonempty_text(data.get("memorable_moment")):
		return false
	if not data.get("friction") is Array:
		return false
	for friction in data.friction:
		if not nonempty_text(friction):
			return false
	return true


func finish(configuration: Dictionary, complete: bool) -> bool:
	if (
		event(
			"run_end",
			{
				"complete": complete,
				"receipt_status": "pending",
				"model_errors": errors,
				"matches": matches
			}
		)
		== 0
	):
		close_ledger()
		return false
	var prefix_bytes = ledger_bytes
	var prefix_hash = ledger_digest.finish().hex_encode()
	if FileAccess.get_sha256(directory.path_join("events.jsonl")) != prefix_hash:
		close_ledger()
		return _storage_failed("Ledger readback does not match the recorded events.")
	# The verified raw prefix is checked before any report or success marker exists.
	ledger_digest.start(HashingContext.HASH_SHA256)
	var text = "# Independent local-model first-play exercise\n\n"
	text += (
		"Protocol: `%s`; model: `%s`; requested games: %s.\n\n"
		% [configuration.protocol, configuration.model, configuration.games]
	)
	text += (
		"Run status: **%s**. Model errors: **%s** (retained, not replaced with scripted turns).\n\n"
		% ["complete" if complete else "incomplete", errors]
	)
	text += "This status is valid only with the final `receipt_finalized` ledger event, matching this report's SHA-256. Missing finalization means incomplete receipts.\n\n"
	text += "Six isolated model conversation sessions played the real authoritative rules. "
	text += "They used a turn-stepped text tool interface, not rendered windows or physical controllers. "
	text += "These are synthetic first impressions, not human satisfaction ratings, six ENet clients, or proof of stream entertainment. "
	text += (
		"Only `%s` could read the manual. Viewers saw only their assigned stream and could message only that player.\n\n"
		% configuration.teacher
	)
	text += "Repeat games reuse the same authored case: improvement may reflect spoilers/memorization, not better onboarding. "
	text += "No source code or host-only case data was fed to actors. The operator ledger contains private observations and spoilers.\n\n"
	text += "## Match outcomes\n\n"
	for match_data in matches:
		text += (
			"- Game %s: %s; actor-submitted ballots %s/6; timeout/default ballots %s.\n"
			% [
				match_data.game,
				JSON.stringify(match_data.ending),
				match_data.submitted_ballots,
				JSON.stringify(match_data.defaulted_roles)
			]
		)
	text += "\n## Ratings: 1 very poor, 5 excellent\n\n"
	text += "| Game | Persona | Clarity | Agency | Social tension | Pacing | Return interest | Receipt |\n"
	text += "| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |\n"
	for entry in ratings:
		text += "| %s | %s%s |" % [entry.game, entry.actor, " (viewer)" if entry.viewer else ""]
		for id in PlaytestCast.DIMENSIONS:
			text += (
				" %s |"
				% (str(entry.reply.data.ratings[id].score) if entry.valid else "unavailable")
			)
		text += " %s |\n" % entry.receipt
	text += "\n## Individual explanations and learning\n\n"
	for entry in ratings:
		text += "### Game %s · %s\n\n" % [entry.game, entry.actor]
		if not entry.valid:
			text += (
				"No valid rating returned. See event %s; no substitute score was invented.\n\n"
				% entry.receipt
			)
			continue
		for id in PlaytestCast.DIMENSIONS:
			var rating: Dictionary = entry.reply.data.ratings[id]
			text += (
				"- %s (%s/5): %s Example: %s\n"
				% [id, rating.score, clean(rating.reason), clean(rating.example)]
			)
		text += "\nFriction: %s\n\n" % clean(JSON.stringify(entry.reply.data.friction))
		text += (
			"Memorable moment: %s\n\n" % clean(str(entry.reply.data.get("memorable_moment", "")))
		)
		text += "Carried learning: %s\n\n" % clean(entry.reply.data.lessons)
	text += "## Method limits\n\n"
	text += "Ratings and memories are untrusted model claims. Validate cited examples against `events.jsonl`; "
	text += "a model may misremember, flatter, misread a tool, or describe an imagined outcome. "
	text += "API affordances differ from the rendered UI. Navigation validates a native route but does not assess visual discoverability. "
	text += "The clock advances equally between seat cycles, excluding model latency; real-time pacing is not measured. "
	text += "Public commentary is recorded without requesting or publishing private reasoning. "
	text += "No averages are used to hide missing ratings or low-scoring personas.\n"
	var report_path = directory.path_join("report.md")
	if FileAccess.file_exists(report_path) or DirAccess.dir_exists_absolute(report_path):
		close_ledger()
		return _storage_failed("Derived report target already exists; it was not overwritten.")
	var output = FileAccess.open(report_path, FileAccess.WRITE)
	if output == null:
		close_ledger()
		return _storage_failed("Cannot open derived report: " + str(FileAccess.get_open_error()))
	var written = _write_checked(output, text, "derived report")
	output.close()
	if not written:
		close_ledger()
		return false
	var report_hash = text.sha256_text()
	if FileAccess.get_sha256(report_path) != report_hash:
		close_ledger()
		return _storage_failed("Derived report readback does not match the written text.")
	if (
		event(
			"receipt_finalized",
			{
				"complete": complete,
				"report_sha256": report_hash,
				"ledger_prefix_sha256": prefix_hash
			}
		)
		== 0
	):
		close_ledger()
		return false
	close_ledger()
	var verified = FileAccess.open(directory.path_join("events.jsonl"), FileAccess.READ)
	if verified == null:
		return _storage_failed("Cannot reopen the finalized ledger.")
	var correct_length = verified.get_length() == ledger_bytes
	verified.seek(prefix_bytes)
	var tail = verified.get_buffer(last_event_line.to_utf8_buffer().size())
	var correct_tail = tail == last_event_line.to_utf8_buffer()
	verified.close()
	if not correct_length or not correct_tail:
		return _storage_failed("Final ledger receipt is missing or truncated.")
	return true


func _write_checked(file: FileAccess, text: String, label: String) -> bool:
	if file == null or not file.is_open():
		return _storage_failed(label + " is closed.")
	var expected = file.get_position() + text.to_utf8_buffer().size()
	if not file.store_string(text):
		return _storage_failed("Writing " + label + " failed.")
	file.flush()
	if file.get_error() != OK or file.get_position() != expected or file.get_length() != expected:
		return _storage_failed("Flushing or byte-count verification failed for " + label + ".")
	return true


func close_ledger() -> void:
	if ledger != null and ledger.is_open():
		ledger.close()


func _storage_failed(message: String) -> bool:
	if storage_error == "":
		storage_error = message
		printerr("RECEIPT FAILURE: ", message)
	return false


static func nonempty_text(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()


static func clean(value: String) -> String:
	return value.replace("\n", " ").replace("\r", " ").strip_edges()
