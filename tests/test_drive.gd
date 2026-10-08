extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var player := PlayerController.new()
	player.read_input_devices = false
	tree.root.add_child(player)
	player.speed_mps = 30.0
	player.max_speed_mps = 30.0
	player.nitro_input = true
	player.tick(1.0)
	if absf(player.speed_mps - 38.0) > 0.02:
		failed.append("nitro speed %s" % player.speed_mps)
	if absf(player.nitro_tank - 0.55) > 0.02:
		failed.append("nitro tank %s" % player.nitro_tank)
	player.nitro_input = false
	player.nitro_tank = 0.5
	player.tick(1.0)
	if player.nitro_tank <= 0.5:
		failed.append("recharge %s" % player.nitro_tank)
	var drifter := PlayerController.new()
	drifter.read_input_devices = false
	tree.root.add_child(drifter)
	drifter.speed_mps = 25.0
	drifter.max_speed_mps = 30.0
	drifter.steer_input = 1.0
	drifter.tick(0.1)
	if absf(drifter.lateral_speed_mps - 1.176) > 0.02:
		failed.append("drift lateral %s" % drifter.lateral_speed_mps)
	if absf(drifter.speed_mps - 25.5) > 0.02:
		failed.append("drift speed %s" % drifter.speed_mps)
	var wet := PlayerController.new()
	wet.read_input_devices = false
	tree.root.add_child(wet)
	wet.weather_grip = 0.5
	wet.speed_mps = 10.0
	wet.max_speed_mps = 30.0
	wet.steer_input = 1.0
	wet.tick(0.1)
	if absf(wet.lateral_speed_mps - 1.4) > 0.02:
		failed.append("rain grip %s" % wet.lateral_speed_mps)
	player.free()
	drifter.free()
	wet.free()
	return failed
