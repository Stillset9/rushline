extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var camera_script: GDScript = load("res://scripts/camera/race_camera.gd")
	var hud_script: GDScript = load("res://scripts/ui/speed_hud.gd")
	var target: Vector3 = camera_script.target_position(Vector3(2.0, 0.0, 10.0))
	if not target.is_equal_approx(Vector3(2.0, 7.5, -0.5)):
		failed.append("target %s" % target)
	var look: Vector3 = camera_script.look_target(Vector3(2.0, 0.0, 10.0))
	if not look.is_equal_approx(Vector3(2.0, 1.4, 22.0)):
		failed.append("look %s" % look)
	if not is_equal_approx(camera_script.fov_for_speed(0.0), 60.0):
		failed.append("fov low")
	if not is_equal_approx(camera_script.fov_for_speed(35.0), 66.0):
		failed.append("fov mid")
	if not is_equal_approx(camera_script.fov_for_speed(100.0), 72.0):
		failed.append("fov high")
	if not is_equal_approx(camera_script.fov_for_drive(35.0, false), 66.0):
		failed.append("fov drive")
	if camera_script.fov_for_drive(35.0, true) <= 66.0:
		failed.append("fov nitro")
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
	if absf(camera.global_position.z - (speed * t - 10.5)) >= 1.0:
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
	var card: Control = hud.get_node("ControlCard")
	if card == null or ControlCard.USES.size() != ControlCard.KEYS.size() or not ControlCard.USES.has("nitro"):
		failed.append("controls")
	hud.show_speed(30.0)
	var label := hud.get_node("%SpeedLabel") as Label
	if label == null or label.text != "108 km/h":
		failed.append("label %s" % (label.text if label != null else "missing"))
	if hud_script.format_distance(60.41) != "60 m":
		failed.append("format distance")
	if hud_script.format_score(750) != "750 pts":
		failed.append("format score")
	if hud_script.format_multiplier(3) != "×3":
		failed.append("format multiplier")
	var distance_label := hud.get_node("%DistanceLabel") as Label
	var score_label := hud.get_node("%ScoreLabel") as Label
	var multiplier_label := hud.get_node("%MultiplierLabel") as Label
	if distance_label == null or distance_label.text != "0 m":
		failed.append("distance label")
	if score_label == null or score_label.text != "0 pts":
		failed.append("score label")
	if multiplier_label == null or multiplier_label.text != "×1":
		failed.append("multiplier label")
	hud.show_distance(60.41)
	hud.show_score(750, 3)
	if distance_label.text != "60 m" or score_label.text != "750 pts" or multiplier_label.text != "×3":
		failed.append("shown %s %s %s" % [distance_label.text, score_label.text, multiplier_label.text])
	hud.queue_free()
	return failed
