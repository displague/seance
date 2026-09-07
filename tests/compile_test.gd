extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var failed = false
	for path in [
		"scripts/npc_data.gd",
		"scripts/npc_rules.gd",
		"scripts/solo_ai.gd",
		"scripts/npc_speech.gd",
		"scripts/round_summary.gd",
		"ui/results.gd",
		"scripts/playtest_tools.gd",
		"scripts/playtest_bridge.gd",
		"tools/playtest_cast.gd",
		"tools/playtest_model.gd",
		"tools/playtest_report.gd",
		"tools/agent_playtest.gd",
		"tests/playtest_host.gd",
		"ui/npc_conversation.gd",
		"ui/solo_ai_menu.gd",
		"world/character_motion.gd",
		"ui/ui_kit.gd",
		"ui/menu.gd",
		"ui/journal.gd",
		"ui/rituals.gd",
		"ui/game_ui.gd",
		"scripts/main.gd"
	]:
		print("COMPILING: ", path)
		var script = load("res://" + path) as GDScript
		if not script or not script.can_instantiate():
			failed = true
	print("COMPILE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
