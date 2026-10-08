extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if not InputMap.has_action("steer_left") or InputMap.action_get_events("steer_left").size() < 3:
		failed.append("steer_left")
	if not InputMap.has_action("steer_right") or InputMap.action_get_events("steer_right").size() < 3:
		failed.append("steer_right")
	if not InputMap.has_action("brake") or InputMap.action_get_events("brake").size() < 4:
		failed.append("brake")
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	if main_scene != "res://scenes/race/race.tscn":
		failed.append("main scene %s" % main_scene)
	return failed
