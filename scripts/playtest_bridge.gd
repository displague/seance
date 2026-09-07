class_name PlaytestBridge
extends Node
## Opt-in loopback MCP 2025-11-25 JSON-response subset. No SSE or remote access.
## Tokens are granted by the coordinator; none are generated or published here.

const PROTOCOL = "2025-11-25"
const MAX_REQUEST = 65536
const MAX_HEADER = 8192
const MAX_PEERS = 16
const TIMEOUT_MS = 5000

var api: PlaytestTools
var server = TCPServer.new()
var port = 0
var peers: Array = []
var initialized: Dictionary = {}


func configure(adapter: PlaytestTools, listen_port: int = 8178) -> Error:
	if listen_port < 1024 or listen_port > 65535:
		return ERR_INVALID_PARAMETER
	stop()
	api = adapter
	port = listen_port
	var result = server.listen(port, "127.0.0.1")
	set_process(result == OK)
	return result


func stop() -> void:
	set_process(false)
	server.stop()
	for connection in peers:
		connection.peer.disconnect_from_host()
	peers.clear()
	initialized.clear()


func _exit_tree() -> void:
	stop()


func _process(_delta: float) -> void:
	while server.is_connection_available():
		var peer = server.take_connection()
		if peers.size() >= MAX_PEERS or peer.get_connected_host() != "127.0.0.1":
			peer.disconnect_from_host()
			continue
		peers.append({"peer": peer, "buffer": PackedByteArray(), "started": Time.get_ticks_msec()})
	for connection in peers.duplicate():
		var peer: StreamPeerTCP = connection.peer
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_close(connection)
			continue
		if Time.get_ticks_msec() - int(connection.started) > TIMEOUT_MS:
			_reply(connection, 408, {"error": "Request timed out."})
			continue
		var available = peer.get_available_bytes()
		if available > 0:
			if available + connection.buffer.size() > MAX_REQUEST:
				_reply(connection, 413, {"error": "Request too large."})
				continue
			var packet = peer.get_data(available)
			if packet[0] != OK:
				_close(connection)
				continue
			connection.buffer.append_array(packet[1])
		_read(connection)


func _read(connection: Dictionary) -> void:
	var buffer: PackedByteArray = connection.buffer
	var header_end = -1
	for index in range(mini(buffer.size() - 3, MAX_HEADER + 1)):
		if (
			buffer[index] == 13
			and buffer[index + 1] == 10
			and buffer[index + 2] == 13
			and buffer[index + 3] == 10
		):
			header_end = index
			break
	if header_end < 0:
		if buffer.size() > MAX_HEADER:
			_reply(connection, 431, {"error": "Headers too large."})
		return
	# HTTP headers must be ASCII, so byte and character offsets agree.
	if header_end > MAX_HEADER:
		_reply(connection, 431, {"error": "Headers too large."})
		return
	var header_bytes = buffer.slice(0, header_end)
	for value in header_bytes:
		if value > 127 or value == 0:
			_reply(connection, 400, {"error": "Invalid HTTP headers."})
			return
	var lines = header_bytes.get_string_from_ascii().split("\r\n")
	var first = lines[0].split(" ")
	if first.size() != 3 or first[1] != "/mcp" or first[2] != "HTTP/1.1":
		_reply(connection, 404, {"error": "Use the /mcp endpoint."})
		return
	var headers: Dictionary = {}
	for line in lines.slice(1):
		var colon = line.find(":")
		if colon <= 0:
			_reply(connection, 400, {"error": "Malformed header."})
			return
		var key = line.left(colon).to_lower()
		if headers.has(key):
			_reply(connection, 400, {"error": "Duplicate header."})
			return
		headers[key] = line.substr(colon + 1).strip_edges()
	var host = str(headers.get("host", ""))
	if not ["127.0.0.1:%d" % port, "localhost:%d" % port].has(host):
		_reply(connection, 403, {"error": "Invalid local host."})
		return
	if (
		headers.has("origin")
		and not ["http://127.0.0.1:%d" % port, "http://localhost:%d" % port].has(headers.origin)
	):
		_reply(connection, 403, {"error": "Cross-origin access is disabled."})
		return
	var auth = str(headers.get("authorization", ""))
	if not auth.begins_with("Bearer ") or not api.authorized(auth.substr(7)):
		_reply(connection, 401, {"error": "A valid seat capability is required."})
		return
	if first[0] != "POST":
		_reply(connection, 405, {"error": "JSON POST only; SSE is not provided."})
		return
	if not str(headers.get("content-type", "")).begins_with("application/json"):
		_reply(connection, 415, {"error": "Use application/json."})
		return
	if (
		headers.has("transfer-encoding")
		or not str(headers.get("content-length", "")).is_valid_int()
	):
		_reply(connection, 400, {"error": "A bounded Content-Length is required."})
		return
	var length = int(headers["content-length"])
	if length < 0 or length > MAX_REQUEST - MAX_HEADER:
		_reply(connection, 413, {"error": "Invalid body length."})
		return
	var body_start = header_end + 4
	if buffer.size() < body_start + length:
		return
	if buffer.size() > body_start + length:
		_reply(connection, 400, {"error": "One request is allowed per connection."})
		return
	var version = str(headers.get("mcp-protocol-version", PROTOCOL))
	if version != PROTOCOL:
		_reply(connection, 400, {"error": "Supported MCP protocol: " + PROTOCOL})
		return
	var parsed = JSON.new()
	if parsed.parse(buffer.slice(body_start).get_string_from_utf8()) != OK:
		_reply(connection, 200, _rpc_error(null, -32700, "Invalid JSON."))
		return
	var response = dispatch_rpc(auth.substr(7), parsed.data)
	_reply(connection, 202 if response.is_empty() else 200, response)


func dispatch_rpc(token: String, request: Variant) -> Dictionary:
	if not api.authorized(token):
		return _rpc_error(null, -32001, "Invalid or revoked capability.")
	if (
		not request is Dictionary
		or request.get("jsonrpc", "") != "2.0"
		or not request.get("method") is String
	):
		return _rpc_error(null, -32600, "Expected a JSON-RPC 2.0 request object.")
	var id = request.get("id")
	if id != null and not id is String and not id is float and not id is int:
		return _rpc_error(null, -32600, "Invalid request id.")
	var method: String = request.method
	var params = request.get("params", {})
	if not params is Dictionary:
		return _rpc_error(id, -32602, "Parameters must be an object.")
	if not request.has("id"):
		return {}
	if method == "initialize":
		initialized[token] = true
		return _rpc_result(
			id,
			{
				"protocolVersion": PROTOCOL,
				"capabilities": {"tools": {"listChanged": false}},
				"serverInfo": {"name": "seance-playtest", "version": "0.1.0"}
			}
		)
	if not initialized.has(token):
		return _rpc_error(id, -32002, "Initialize this capability before using tools.")
	if method == "ping":
		return _rpc_result(id, {})
	if method == "tools/list":
		return _rpc_result(id, {"tools": api.tool_list(token)})
	if method == "tools/call":
		if not params.get("name") is String or not params.get("arguments", {}) is Dictionary:
			return _rpc_error(id, -32602, "Tool name and object arguments are required.")
		var result = api.call_tool(token, params.name, params.get("arguments", {}))
		return _rpc_result(
			id,
			{
				"content": [{"type": "text", "text": JSON.stringify(result)}],
				"structuredContent": result,
				"isError": not result.get("ok", false)
			}
		)
	return _rpc_error(id, -32601, "Method not supported by this adapter.")


func _reply(connection: Dictionary, status: int, data: Dictionary) -> void:
	var reasons = {
		200: "OK",
		202: "Accepted",
		400: "Bad Request",
		401: "Unauthorized",
		403: "Forbidden",
		404: "Not Found",
		405: "Method Not Allowed",
		408: "Request Timeout",
		413: "Content Too Large",
		415: "Unsupported Media Type",
		431: "Request Header Fields Too Large"
	}
	var body = PackedByteArray() if status == 202 else JSON.stringify(data).to_utf8_buffer()
	var header = (
		"HTTP/1.1 %d %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\nCache-Control: no-store\r\n"
		% [status, reasons.get(status, "Error"), body.size()]
	)
	if status == 405:
		header += "Allow: POST\r\n"
	header += "\r\n"
	var packet = header.to_utf8_buffer()
	packet.append_array(body)
	connection.peer.put_data(packet)
	_close(connection)


func _close(connection: Dictionary) -> void:
	connection.peer.disconnect_from_host()
	peers.erase(connection)


static func _rpc_result(id: Variant, result: Dictionary) -> Dictionary:
	return {"jsonrpc": "2.0", "id": id, "result": result}


static func _rpc_error(id: Variant, code: int, message: String) -> Dictionary:
	return {"jsonrpc": "2.0", "id": id, "error": {"code": code, "message": message}}
