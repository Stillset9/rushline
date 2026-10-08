extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var race: Node = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	var player: Node3D = race.get_node("PlayerVehicle")
	var hud_label: Label = race.get_node("SpeedHud/Panel/SpeedLabel")
	if hud_label.text != "029 km/h":
		failed.append("initial hud %s" % hud_label.text)
	for _i in 60:
		race.simulate(0.05)
	# 60 pasos de 0,05 s: la velocidad termina en 30,45 m/s y Z en 60,41 m.
	if absf(player.speed_mps - 30.45) > 0.05:
		failed.append("speed %s" % player.speed_mps)
	if absf(player.position.z - 60.41) > 0.5:
		failed.append("distance %s" % player.position.z)
	if hud_label.text != SpeedHud.format_speed(player.speed_mps):
		failed.append("hud %s" % hud_label.text)
	var road: Node = race.get_node("RoadStreamer")
	var origins: Array = road.origins()
	var sorted: Array[float] = []
	for value in origins:
		sorted.append(float(value))
	sorted.sort()
	if sorted.size() != 8 or not is_equal_approx(sorted[1] - sorted[0], 40.0):
		failed.append("chunks %s" % sorted)
	if sorted[0] > player.position.z or sorted[7] + 40.0 < player.position.z:
		failed.append("coverage")
	var active := 0
	for child in race.get_node("TrafficManager").get_children():
		if child.active:
			active += 1
	if active != 2:
		failed.append("traffic %s" % active)
	if race.get_node("TrafficManager").get_child_count() != 12:
		failed.append("pool size")
	if race.get_node("RoadStreamer").get_child_count() != 8:
		failed.append("chunk pool")
	if not race.find_children("", "CollisionShape3D", true, false).is_empty():
		failed.append("unexpected collision")
	var camera: Camera3D = race.get_node("RaceCamera")
	if absf(camera.fov - RaceCamera.fov_for_speed(player.speed_mps)) > 0.5:
		failed.append("fov %s" % camera.fov)
	race.queue_free()
	return failed
