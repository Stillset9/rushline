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
	var paused_z := player.position.z
	race.paused = true
	race._process(1.0)
	if not is_equal_approx(player.position.z, paused_z):
		failed.append("pause moved")
	race.set_paused(true)
	var pause_label: Label = race.get_node("SpeedHud/PauseLabel")
	if not pause_label.visible or not pause_label.text.contains("Inicio"):
		failed.append("pause menu %s" % pause_label.text)
	race.restart_scene = false
	race.pause_row = 1
	race.confirm_pause()
	race.restart_scene = true
	if not race.returned_home:
		failed.append("home")
	race.paused = false
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
	var finish_label: Label = race.get_node("SpeedHud/FinishLabel")
	if finish_label.visible:
		failed.append("finish early")
	race.queue_free()
	failed.append_array(_hit_episode(tree))
	failed.append_array(_finish_episode(tree))
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
	if race.finished:
		failed.append("ended too soon")
	race.stage_index = StageRun.count() - 1
	race.stage_distance = float(StageRun.stage(race.stage_index)["length"])
	race.close_if_done()
	if not race.finished:
		failed.append("stage open")
	var stage_label: Label = race.get_node("SpeedHud/FinishLabel")
	if not stage_label.visible:
		failed.append("stage finish")
	race.queue_free()
	return failed


func _finish_episode(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var race: Node = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	var player: PlayerController = race.get_node("PlayerVehicle")
	player.speed_mps = 30.0
	race.fuel.amount = FuelTank.CRASH_COST
	var traffic: TrafficManager = race.get_node("TrafficManager")
	var vehicle: TrafficVehicle = traffic.vehicles()[0]
	vehicle.activate(1, player.global_position, StandardMaterial3D.new(), 1.0)
	race.simulate(0.05)
	if not race.finished or race.finish_reason != "sin_combustible":
		failed.append("not finished %s %s" % [race.finished, race.finish_reason])
	var frozen_z := player.position.z
	var frozen_score: float = race.score_keeper.score
	var frozen_distance: float = race.distance_m
	var finish_label: Label = race.get_node("SpeedHud/FinishLabel")
	if not finish_label.visible or not finish_label.text.begins_with("Sin combustible"):
		failed.append("finish label %s" % finish_label.text)
	if not finish_label.text.ends_with(SpeedHud.format_score(RaceDirector.displayed_score(frozen_score))):
		failed.append("finish score %s" % finish_label.text)
	var hint: Label = race.get_node("SpeedHud/RestartHint")
	if not hint.visible or hint.text != "Enter, Start o A para otra vez":
		failed.append("restart hint %s" % hint.text)
	race.restart_scene = false
	race.request_restart()
	if not race.restarted:
		failed.append("restart")
	race.simulate(0.05)
	if not is_equal_approx(player.position.z, frozen_z):
		failed.append("moved after finish")
	if not is_equal_approx(race.score_keeper.score, frozen_score) or not is_equal_approx(race.distance_m, frozen_distance):
		failed.append("score moved after finish")
	race.queue_free()
	return failed
