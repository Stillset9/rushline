extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if not InputMap.has_action("steer_left") or InputMap.action_get_events("steer_left").size() < 3:
		failed.append("steer_left")
	if not InputMap.has_action("steer_right") or InputMap.action_get_events("steer_right").size() < 3:
		failed.append("steer_right")
	if not InputMap.has_action("brake") or InputMap.action_get_events("brake").size() < 4:
		failed.append("brake")
	if not InputMap.has_action("skip_intro") or not _skip_events_ok():
		failed.append("skip_intro")
	if not InputMap.has_action("ui_accept") or not _accept_events_ok():
		failed.append("ui_accept")
	if not InputMap.has_action("ui_cancel") or not _cancel_events_ok():
		failed.append("ui_cancel")
	if not InputMap.has_action("nitro") or not _nitro_events_ok():
		failed.append("nitro")
	if not InputMap.has_action("gear") or InputMap.action_get_events("gear").is_empty():
		failed.append("gear")
	if not InputMap.has_action("ui_up") or not _menu_key("ui_up", KEY_UP):
		failed.append("ui_up")
	if not InputMap.has_action("ui_down") or not _menu_key("ui_down", KEY_DOWN):
		failed.append("ui_down")
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	if main_scene != "res://scenes/branding/HJGamesIntro.tscn":
		failed.append("main scene %s" % main_scene)
	return failed


func _skip_events_ok() -> bool:
	var has_escape := false
	var has_start := false
	var has_confirm := false
	for event in InputMap.action_get_events("skip_intro"):
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
			has_escape = true
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
			has_start = true
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
			has_confirm = true
	return has_escape and has_start and has_confirm


func _accept_events_ok() -> bool:
	var has_enter := false
	var has_start := false
	var has_confirm := false
	for event in InputMap.action_get_events("ui_accept"):
		if event is InputEventKey and event.physical_keycode == KEY_ENTER:
			has_enter = true
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
			has_start = true
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
			has_confirm = true
	return has_enter and has_start and has_confirm


func _cancel_events_ok() -> bool:
	for event in InputMap.action_get_events("ui_cancel"):
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
			return true
	return false


func _nitro_events_ok() -> bool:
	var has_shift := false
	var has_trigger := false
	for event in InputMap.action_get_events("nitro"):
		if event is InputEventKey and event.physical_keycode == KEY_SHIFT:
			has_shift = true
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.0:
			has_trigger = true
	return has_shift and has_trigger


func _menu_key(action: String, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false
