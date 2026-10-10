extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if StageRun.count() != 6:
		failed.append("count %s" % StageRun.count())
	var previous := 0.0
	for index in StageRun.count():
		var length := float(StageRun.stage(index)["length"])
		if length <= previous:
			failed.append("length %s" % length)
		previous = length
	if str(Course.theme(int(StageRun.stage(0)["theme"]))["id"]) != "ciudad":
		failed.append("first theme")
	if str(Course.theme(int(StageRun.stage(5)["theme"]))["id"]) != "noche":
		failed.append("last theme")
	var open := StageRun.playable_half(10.0, 0.8)
	var narrow := StageRun.playable_half(100.0, 0.8)
	var wide := StageRun.playable_half(280.0, 0.8)
	if narrow >= open or wide <= open:
		failed.append("width open %s narrow %s wide %s" % [open, narrow, wide])
	if TrafficManager.lane_toward(1, -5.0) != 0:
		failed.append("swerve")
	if TrafficManager.cruise_speed(22.0, 0.0, 0.0, false) != 22.0:
		failed.append("cruise parked")
	if TrafficManager.cruise_speed(22.0, 70.0, 1.0, false) <= TrafficManager.cruise_speed(12.0, 70.0, 0.0, true):
		failed.append("cruise threat")
	var before := GameSettings.quality
	GameSettings.quality = "medio"
	GameSettings.cycle_quality(1)
	if GameSettings.quality != "alto" or GameSettings.quality_name() != "Alto":
		failed.append("quality up %s" % GameSettings.quality)
	GameSettings.cycle_quality(1)
	if GameSettings.quality != "bajo":
		failed.append("quality wrap %s" % GameSettings.quality)
	GameSettings.quality = before
	var race: RaceDirector = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	race.fuel.amount = 50.0
	var player: PlayerController = race.get_node("PlayerVehicle")
	player.speed_mps = 40.0
	race.stage_distance = float(StageRun.stage(0)["length"]) - 0.2
	race.simulate(0.05)
	if race.stage_index != 1:
		failed.append("checkpoint %s" % race.stage_index)
	if race.fuel.amount <= 50.0:
		failed.append("refill %s" % race.fuel.amount)
	if not str(race.get_node("SpeedHud/CourseLabel").text).contains("Costa"):
		failed.append("place %s" % race.get_node("SpeedHud/CourseLabel").text)
	if race.finished:
		failed.append("stage one ended the run")
	race.stage_index = StageRun.count() - 1
	race.stage_distance = float(StageRun.stage(race.stage_index)["length"])
	race.close_if_done()
	if not race.finished or race.finish_reason != "meta":
		failed.append("final %s %s" % [race.finished, race.finish_reason])
	var graded := race.world.environment
	if graded.adjustment_enabled:
		failed.append("grade blackout")
	if race.get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR and not GraphicsProfile.fancy():
		failed.append("fsr on compatibility")
	race.queue_free()
	return failed
