extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var failed = false
	for path in [
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
