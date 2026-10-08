extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var camera_script: GDScript = load("res://scripts/camera/race_camera.gd")
	var hud_script: GDScript = load("res://scripts/ui/speed_hud.gd")
	var target: Vector3 = camera_script.target_position(Vector3(2.0, 0.0, 10.0))
	if not target.is_equal_approx(Vector3(2.0, 18.0, -2.0)):
		failed.append("target %s" % target)
	var look: Vector3 = camera_script.look_target(Vector3(2.0, 0.0, 10.0))
	if not look.is_equal_approx(Vector3(2.0, 1.0, 14.0)):
		failed.append("look %s" % look)
	if not is_equal_approx(camera_script.fov_for_speed(0.0), 60.0):
		failed.append("fov low")
	if not is_equal_approx(camera_script.fov_for_speed(35.0), 66.0):
		failed.append("fov mid")
	if not is_equal_approx(camera_script.fov_for_speed(100.0), 72.0):
		failed.append("fov high")
	var stayed: Vector3 = camera_script.smooth_position(Vector3(1.0, 2.0, 3.0), Vector3(9.0, 9.0, 9.0), 0.0)
	if not stayed.is_equal_approx(Vector3(1.0, 2.0, 3.0)):
		failed.append("smooth zero")
	var moved: Vector3 = camera_script.smooth_position(Vector3.ZERO, Vector3(10.0, 0.0, 0.0), 0.2)
	var expected_x := 10.0 * (1.0 - exp(-1.0))
	if not is_equal_approx(moved.x, expected_x):
		failed.append("smooth step %s" % moved.x)
	var camera: Camera3D = camera_script.new()
	tree.root.add_child(camera)
	camera.snap_to(Vector3(0.0, 0.0, 0.0))
	var speed := 70.0
	var delta := 1.0 / 60.0
	var t := 0.0
	for _frame in 120:
		t += delta
		camera.tick(delta, Vector3(4.0, 0.0, speed * t))
	if absf(camera.global_position.z - (speed * t - 12.0)) >= 1.0:
		failed.append("forward lag %s" % camera.global_position.z)
	if camera.global_position.x <= 0.0:
		failed.append("lateral %s" % camera.global_position.x)
	camera.queue_free()
	if hud_script.format_speed(8.0) != "029 km/h":
		failed.append("format 8")
	if hud_script.format_speed(30.0) != "108 km/h":
		failed.append("format 30")
	var hud: CanvasLayer = load("res://scenes/ui/speed_hud.tscn").instantiate()
	tree.root.add_child(hud)
	hud.show_speed(30.0)
	var label := hud.get_node("%SpeedLabel") as Label
	if label == null or label.text != "108 km/h":
		failed.append("label %s" % (label.text if label != null else "missing"))
	hud.queue_free()
	return failed
