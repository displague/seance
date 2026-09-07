class_name ModalNavigation
extends RefCounted
## Presentation-only back routes, journal tabs and focused-panel pad scrolling.

var ui
var back_action = Callable()
var tab_actions: Array = []
var tab_index = 0
var scroller: ScrollContainer
var pane_axis_held = false
var panes: Array[ScrollContainer] = []
var scroll_fraction = 0.0


func _init(owner_ui) -> void:
	ui = owner_ui


func reset() -> void:
	back_action = Callable()
	tab_actions.clear()
	scroller = null
	pane_axis_held = false
	panes.clear()
	scroll_fraction = 0.0
	Controls.tab_navigation = false


func set_back(label: String, action: Callable) -> void:
	back_action = action
	ui.close_button.text = "←  " + label.to_upper()
	ui.close_button.custom_minimum_size.x = 190


func back() -> void:
	if back_action.is_valid():
		back_action.call()
	else:
		ui.close()


func tabs(actions: Array, selected: int) -> void:
	tab_actions = actions
	tab_index = selected
	Controls.tab_navigation = true


func shift_tab(direction: int) -> bool:
	if tab_actions.is_empty():
		return false
	if direction < 0:
		Controls.tab_talk_latch = true
	var action: Callable = tab_actions[posmod(tab_index + direction, tab_actions.size())]
	action.call()
	return true


func scroll(delta: float) -> void:
	if ui.modal == "" or not Controls.using_pad or not ui.get_window().has_focus():
		return
	var axes = Controls.stick(true)
	if axes.length() < 0.18:
		pane_axis_held = false
		scroll_fraction = 0.0
		return
	if panes.is_empty():
		for node in ui.overlay.find_children("*", "ScrollContainer", true, false):
			if node.is_visible_in_tree():
				panes.append(node)
	if panes.is_empty():
		return
	var focused = ui.get_viewport().gui_get_focus_owner()
	for pane in panes:
		if focused == pane or (focused != null and pane.is_ancestor_of(focused)):
			scroller = pane
	if not is_instance_valid(scroller) or not panes.has(scroller):
		scroller = panes[0]
		for pane in panes:
			if pane.has_meta("controller_primary_scroll"):
				scroller = pane
	if absf(axes.x) > 0.55 and not pane_axis_held:
		var index = posmod(panes.find(scroller) + (1 if axes.x > 0 else -1), panes.size())
		scroller = panes[index]
		scroller.grab_focus()
	pane_axis_held = absf(axes.x) > 0.3
	if absf(axes.y) > 0.18:
		# Carry subpixel motion instead of truncating it away on high-refresh systems.
		scroll_fraction += axes.y * 900 * delta
		var pixels = int(scroll_fraction)
		scroll_fraction -= pixels
		var before = scroller.scroll_vertical
		scroller.scroll_vertical += pixels
		# Do not let minor stick noise or pushing against an edge steal A/confirm.
		if before != scroller.scroll_vertical and focused != scroller:
			scroller.grab_focus()
