class_name UIK
extends RefCounted

const INK = Color("10191b")
const PANEL = Color("142022")
const GOLD = Color("c9aa75")
const CREAM = Color("e7e0d0")
const MUTED = Color("97a39e")
const TEAL = Color("87b7ad")


static func serif() -> SystemFont:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Garamond", "Georgia", "Times New Roman"])
	return font


static func sans() -> SystemFont:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	return font


static func style(
	bg: Color, border: Color = Color.TRANSPARENT, width: int = 1, margin: int = 16
) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	return s


static func make_theme() -> Theme:
	var theme = Theme.new()
	theme.default_font = sans()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("67716d"))
	theme.set_stylebox("normal", "Button", style(Color(0.075, 0.12, 0.125, 0.95), Color("40504a")))
	theme.set_stylebox("hover", "Button", style(Color("21312f"), GOLD))
	theme.set_stylebox("focus", "Button", style(Color.TRANSPARENT, GOLD, 2))
	theme.set_stylebox("pressed", "Button", style(GOLD, GOLD))
	theme.set_stylebox("disabled", "Button", style(Color("121b1c"), Color("26322f")))
	theme.set_stylebox("normal", "LineEdit", style(Color("0b1315"), Color("44554e")))
	theme.set_stylebox("focus", "LineEdit", style(Color("122022"), GOLD))
	theme.set_stylebox("panel", "PopupMenu", style(PANEL, GOLD))
	theme.set_color("font_color", "LineEdit", CREAM)
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_color("font_color", "OptionButton", CREAM)
	theme.set_stylebox("normal", "OptionButton", style(INK, Color("44554e")))
	theme.set_stylebox("hover", "OptionButton", style(PANEL, GOLD))
	theme.set_constant("separation", "VBoxContainer", 14)
	theme.set_constant("separation", "HBoxContainer", 14)
	return theme


static func label(
	text: String, size: int = 18, color: Color = CREAM, is_serif: bool = false
) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if is_serif:
		node.add_theme_font_override("font", serif())
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func paragraph(text: String, size: int = 19, color: Color = MUTED) -> Label:
	var node = label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 49
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		node.add_theme_stylebox_override("normal", style(GOLD, GOLD))
		node.add_theme_color_override("font_color", INK)
	node.pressed.connect(
		func():
			Sound.play("click", -5)
			callback.call()
	)
	return node


static func line() -> ColorRect:
	var node = ColorRect.new()
	node.color = Color(0.63, 0.55, 0.39, 0.35)
	node.custom_minimum_size = Vector2(0, 1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func spacer(height: float = 12) -> Control:
	var control = Control.new()
	control.custom_minimum_size.y = height
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


static func panel(
	parent: Node, bg: Color = PANEL, border: Color = Color("3e4a41"), margin: int = 28
) -> PanelContainer:
	var node = PanelContainer.new()
	node.add_theme_stylebox_override("panel", style(bg, border, 1, margin))
	parent.add_child(node)
	return node


static func vbox(parent: Node, separation: int = 14) -> VBoxContainer:
	var node = VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node


static func hbox(parent: Node, separation: int = 14) -> HBoxContainer:
	var node = HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func scroll(parent: Node) -> VBoxContainer:
	var scroller = ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroller)
	var box = vbox(scroller)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box
