class_name PlaytestModel
extends RefCounted
## Stateless HTTP transport. The coordinator owns separate per-person message lists.

var parent: Node
var endpoint = "http://127.0.0.1:1234/v1"
var model = "granite-4.1-3b"
var requests = 0
var maximum_requests = 600
var max_tokens = 2400


func _init(owner_node: Node) -> void:
	parent = owner_node


func complete(messages: Array, schema: Dictionary) -> Dictionary:
	if requests >= maximum_requests:
		return {"ok": false, "error": "Frozen request budget exhausted; no fallback actor."}
	requests += 1
	var request = HTTPRequest.new()
	request.timeout = 50
	request.max_redirects = 0
	request.body_size_limit = 262144
	parent.add_child(request)
	var began = Time.get_ticks_msec()
	var error = request.request(
		endpoint + "/chat/completions",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(
			{
				"model": model,
				"stream": false,
				"temperature": 0.65,
				"max_tokens": max_tokens,
				"messages": messages,
				"response_format":
				{
					"type": "json_schema",
					"json_schema": {"name": "playtest_reply", "strict": true, "schema": schema}
				}
			},
			"",
			false
		)
	)
	if error != OK:
		request.queue_free()
		return {"ok": false, "error": "Local HTTP request could not start.", "code": error}
	var response = await request.request_completed
	request.queue_free()
	var receipt = {
		"ok": false,
		"http": response[1],
		"seconds": (Time.get_ticks_msec() - began) / 1000.0,
		"request_number": requests
	}
	var envelope = parse_json(response[3].get_string_from_utf8())
	if (
		response[0] != HTTPRequest.RESULT_SUCCESS
		or response[1] != 200
		or not envelope is Dictionary
	):
		receipt["error"] = "Local model unavailable or invalid HTTP envelope."
		if envelope is Dictionary:
			receipt["provider_error"] = str(envelope.get("error", "")).left(1000)
		return receipt
	var choices = envelope.get("choices", [])
	if not choices is Array or choices.is_empty() or not choices[0] is Dictionary:
		receipt["error"] = "No model choice returned."
		return receipt
	var message = choices[0].get("message", {})
	if not message is Dictionary:
		receipt["error"] = "Malformed model message."
		return receipt
	# Never publish the model's private reasoning channel as streamer commentary.
	receipt["content"] = str(message.get("content", ""))
	receipt["finish_reason"] = choices[0].get("finish_reason", "")
	receipt["usage"] = envelope.get("usage", {})
	var data = parse_json(receipt.content)
	if receipt.finish_reason == "length" or not data is Dictionary:
		receipt["error"] = "Incomplete or invalid JSON reply; no action was applied."
		return receipt
	receipt["data"] = data
	receipt.ok = true
	return receipt


static func parse_json(value: String):
	var parser = JSON.new()
	return parser.data if parser.parse(value) == OK else null
