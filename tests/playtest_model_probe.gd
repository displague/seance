extends SceneTree
## Explicit provider/schema compatibility probe with a toy object, no case spoilers.

const Cast = preload("res://tools/playtest_cast.gd")
const Model = preload("res://tools/playtest_model.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if not OS.get_cmdline_user_args().has("--live-local"):
		printerr("Pass -- --live-local for the local model schema probe.")
		quit(2)
		return
	var tools = [{"name": "inspect", "inputSchema": Cast.object_schema({"id": {"type": "string"}})}]
	var client = Model.new(root)
	var result = await (
		client
		. complete(
			[
				{
					"role": "user",
					"content":
					"This is only a schema transport test. Select inspect with arguments id sample_object. Keep speech empty and commentary and notes brief. No case or scoring is involved."
				}
			],
			Cast.decision_schema(false, tools)
		)
	)
	var good = result.get("ok", false)
	if good:
		good = (
			result.data.get("tool") == "inspect"
			and result.data.get("arguments", {}).get("id") == "sample_object"
		)
	print("MODEL SCHEMA PROBE: ", "PASS" if good else "FAIL", " ", JSON.stringify(result))
	root.get_node("Sound").shutdown()
	root.get_node("Music").shutdown()
	await create_timer(0.2).timeout
	quit(0 if good else 1)
