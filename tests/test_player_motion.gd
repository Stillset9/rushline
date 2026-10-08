extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var player: GDScript = load("res://scripts/vehicles/player_controller.gd")
	var accelerated: float = player.step_longitudinal(8.0, 30.0, false, 1.0)
	if not is_equal_approx(accelerated, 16.0):
		failed.append("accel %s" % accelerated)
	var braked: float = player.step_longitudinal(20.0, 30.0, true, 1.0)
	if not is_equal_approx(braked, 8.0):
		failed.append("brake floor %s" % braked)
	var held: float = player.step_longitudinal(8.0, 30.0, true, 1.0)
	if not is_equal_approx(held, 8.0):
		failed.append("brake hold %s" % held)
	var steered: float = player.step_lateral(0.0, 1.0, 0.1)
	if not is_equal_approx(steered, 2.8):
		failed.append("steer %s" % steered)
	var gripped: float = player.step_lateral(12.0, 0.0, 0.5)
	if not is_equal_approx(gripped, 3.0):
		failed.append("grip %s" % gripped)
	var slid: Vector2 = player.step_x(0.0, 2.0, 0.5)
	if not is_equal_approx(slid.x, 1.0) or not is_equal_approx(slid.y, 2.0):
		failed.append("slide %s" % slid)
	var clamped: Vector2 = player.step_x(5.5, 12.0, 0.1)
	if not is_equal_approx(clamped.x, 6.0) or not is_equal_approx(clamped.y, 0.0):
		failed.append("clamp %s" % clamped)
	return failed
