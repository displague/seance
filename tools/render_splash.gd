extends SceneTree
## Offline, deterministic branding render. Run with a graphical Godot renderer.
## Reuses the original eye mark and installed fonts; no paid generation or runtime dependency.

const OUTPUT = "res://assets/art/boot_splash.png"


class SplashArt:
	extends Node2D

	var serif = SystemFont.new()
	var sans = SystemFont.new()
	var mark: Texture2D

	func _ready() -> void:
		serif.font_names = PackedStringArray(["Garamond", "Georgia", "Times New Roman"])
		sans.font_names = PackedStringArray(["Segoe UI", "Arial"])
		mark = load("res://assets/icon.svg")
		queue_redraw()

	func centered(text: String, baseline: float, size: int, color: Color, font: Font) -> void:
		var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(
			font,
			Vector2((1600 - width) / 2, baseline),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			size,
			color
		)

	func _draw() -> void:
		var gold = Color("c9aa75")
		draw_rect(Rect2(0, 0, 1600, 900), Color("0a1315"))
		draw_rect(Rect2(85, 60, 1430, 780), Color("293630"), false, 1)
		for corner in [Vector2(85, 60), Vector2(1515, 60), Vector2(85, 840), Vector2(1515, 840)]:
			var direction = Vector2(1 if corner.x < 800 else -1, 1 if corner.y < 450 else -1)
			draw_line(corner, corner + Vector2(direction.x * 42, 0), gold, 1, true)
			draw_line(corner, corner + Vector2(0, direction.y * 42), gold, 1, true)
		draw_texture_rect(mark, Rect2(708, 164, 184, 184), false)
		centered("A N   A S H W O O D   M Y S T E R Y", 403, 15, gold, sans)
		centered("SÉANCE", 543, 142, Color("e7e0d0"), serif)
		centered("T H E   U N Q U I E T   W I L L", 594, 21, gold, sans)
		draw_line(Vector2(580, 650), Vector2(752, 650), Color("526050"), 1, true)
		draw_line(Vector2(848, 650), Vector2(1020, 650), Color("526050"), 1, true)
		draw_colored_polygon(
			PackedVector2Array(
				[Vector2(800, 643), Vector2(805, 650), Vector2(800, 657), Vector2(795, 650)]
			),
			gold
		)
		centered(
			"The dead have a story. The living have their reasons.", 715, 23, Color("a0aea5"), serif
		)


func _initialize() -> void:
	call_deferred("render")


func render() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Splash rendering requires the graphical renderer; omit --headless.")
		quit(1)
		return
	var canvas = SubViewport.new()
	canvas.size = Vector2i(1600, 900)
	canvas.disable_3d = true
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	canvas.add_child(SplashArt.new())
	await process_frame
	await RenderingServer.frame_post_draw
	var image = canvas.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var error = image.save_png(OUTPUT)
	print("SPLASH: ", OUTPUT, " ", image.get_size(), " ", "PASS" if error == OK else "FAIL")
	quit(0 if error == OK else 1)
