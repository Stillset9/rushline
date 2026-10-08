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
	if race.score_keeper.multiplier != 1:
		failed.append("clean multiplier %s" % race.score_keeper.multiplier)
	if not is_equal_approx(race.score_keeper.score, race.distance_m):
		failed.append("clean score %s vs %s" % [race.score_keeper.score, race.distance_m])
	if int(race.score_keeper.score) != int(race.distance_m):
		failed.append("shown integers")
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
	failed.append_array(_hit_episode(tree))
	return failed


func _hit_episode(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var race: Node = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	var player: PlayerController = race.get_node("PlayerVehicle")
	player.speed_mps = 30.0
	race.score_keeper.score = 750.0
	race.score_keeper.multiplier = 3
	race.score_keeper.clean_m = 50.0
	var traffic: TrafficManager = race.get_node("TrafficManager")
	var vehicle: TrafficVehicle = traffic.vehicles()[0]
	vehicle.activate(1, player.global_position, StandardMaterial3D.new(), 1.0)
	race.simulate(0.05)
	if absf(player.speed_mps - 15.0) > 0.02:
		failed.append("hit speed %s" % player.speed_mps)
	if absf(race.distance_m - 1.5) > 0.02:
		failed.append("hit distance %s" % race.distance_m)
	if absf(race.score_keeper.score - 751.5) > 0.02 or race.score_keeper.multiplier != 1 or not is_zero_approx(race.score_keeper.clean_m):
		failed.append("hit score %s x%s clean %s" % [race.score_keeper.score, race.score_keeper.multiplier, race.score_keeper.clean_m])
	if not vehicle.active or not vehicle.in_contact:
		failed.append("traffic survived")
	var distance_label: Label = race.get_node("SpeedHud/Panel/DistanceLabel")
	var score_label: Label = race.get_node("SpeedHud/Panel/ScoreLabel")
	if distance_label.text != "1 m" or score_label.text != "751 pts":
		failed.append("hit labels %s %s" % [distance_label.text, score_label.text])
	race.simulate(0.05)
	if absf(player.speed_mps - 15.4) > 0.02:
		failed.append("second speed %s" % player.speed_mps)
	race.queue_free()
	return failed
