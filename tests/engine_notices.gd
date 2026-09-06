extends SceneTree
## Generates redistributable engine notices directly from the bundled binary.


func _initialize() -> void:
	var file = FileAccess.open("res://build/GODOT-NOTICES.txt", FileAccess.WRITE)
	if not file:
		quit(1)
		return
	file.store_line(Engine.get_license_text())
	file.store_line("\nTHIRD-PARTY COPYRIGHTS\n")
	file.store_line(JSON.stringify(Engine.get_copyright_info(), "  "))
	for name in Engine.get_license_info():
		file.store_line("\n" + name + "\n" + Engine.get_license_info()[name])
	file.close()
	quit()
