extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var profile: Resource = load("res://traffic/profiles/normal.tres")
	if profile == null:
		failed.append("missing normal.tres")
		return failed
	if str(profile.get("id")) != "normal":
		failed.append("id %s" % profile.get("id"))
	if not is_equal_approx(float(profile.get("speed_mps")), 22.0):
		failed.append("speed %s" % profile.get("speed_mps"))
	if not is_equal_approx(float(profile.get("lane_change_interval")), 0.0):
		failed.append("interval %s" % profile.get("lane_change_interval"))
	if not is_equal_approx(float(profile.get("aggression")), 0.0):
		failed.append("aggression %s" % profile.get("aggression"))
	return failed
