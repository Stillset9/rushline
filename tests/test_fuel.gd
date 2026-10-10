extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var tank := FuelTank.new()
	if tank.drain(1000.0, false) or tank.amount > 60.0:
		failed.append("drain %s" % tank.amount)
	tank.amount = FuelTank.CRASH_COST
	if not tank.spend(FuelTank.CRASH_COST) or not tank.empty():
		failed.append("crash empty %s" % tank.amount)
	tank.amount = 40.0
	tank.add(FuelTank.PICKUP)
	if tank.amount < 60.0:
		failed.append("pickup %s" % tank.amount)
	tank.amount = 90.0
	tank.add(50.0)
	if not is_equal_approx(tank.amount, FuelTank.CAPACITY):
		failed.append("cap %s" % tank.amount)
	var car := TrafficVehicle.new()
	tree.root.add_child(car)
	car.active = true
	car.global_position = Vector3(0, 0, 10)
	var tunnel: Array[TrafficVehicle] = [car]
	if Contact.collect_new_hits(Vector3(0, 0, 20), tunnel, Vector3(0, 0, 0), true) != 1:
		failed.append("sweep missed a car the line crossed")
	car.queue_free()
	var race: RaceDirector = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	race.fuel.amount = 40.0
	var player: PlayerController = race.get_node("PlayerVehicle")
	race.get_node("FuelDepot").force_at(0, player.global_position)
	race.simulate(0.05)
	if race.fuel.amount < 60.0:
		failed.append("collected %s" % race.fuel.amount)
	if race.score_keeper.score < FuelTank.BONUS:
		failed.append("bonus %s" % race.score_keeper.score)
	if race.finished:
		failed.append("pickup ended the run")
	var quiet: RaceDirector = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(quiet)
	quiet.set_process(false)
	quiet._process(1.0)
	if quiet.get_node("PlayerVehicle").position.z > 2.0:
		failed.append("hitch moved %s" % quiet.get_node("PlayerVehicle").position.z)
	var dry: RaceDirector = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(dry)
	dry.set_process(false)
	dry.fuel.amount = 0.01
	dry.simulate(0.05)
	if not dry.finished or dry.finish_reason != "sin_combustible":
		failed.append("empty %s %s" % [dry.finished, dry.finish_reason])
	var geared := PlayerController.new()
	geared.read_input_devices = false
	tree.root.add_child(geared)
	geared.gear_high = false
	geared.speed_mps = 8.0
	geared.max_speed_mps = 30.0
	geared.tick(1.0)
	if absf(geared.speed_mps - 18.8) > 0.2:
		failed.append("low gear %s" % geared.speed_mps)
	race.queue_free()
	quiet.queue_free()
	dry.queue_free()
	geared.queue_free()
	return failed
