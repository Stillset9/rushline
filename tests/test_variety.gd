extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var normal: AiProfile = load("res://traffic/profiles/normal.tres")
	var fast: AiProfile = load("res://traffic/profiles/rapido.tres")
	var heavy: AiProfile = load("res://traffic/profiles/pesado.tres")
	var aggressive: AiProfile = load("res://traffic/profiles/agresivo.tres")
	if fast.speed_mps <= normal.speed_mps:
		failed.append("fast %s" % fast.speed_mps)
	if heavy.speed_mps >= normal.speed_mps:
		failed.append("heavy %s" % heavy.speed_mps)
	if aggressive.lane_change_interval <= 0.0:
		failed.append("aggressive interval")
	if TrafficManager.choose_lane_change(1, 90.0, []) != 0:
		failed.append("empty change")
	var blocked: Array = [{"lane": 0, "z": 90.0}, {"lane": 2, "z": 90.0}]
	if TrafficManager.choose_lane_change(1, 90.0, blocked) != -1:
		failed.append("blocked change")
	var one_side: Array = [{"lane": 0, "z": 90.0}]
	if TrafficManager.choose_lane_change(1, 90.0, one_side) != 2:
		failed.append("open side")
	var manager := TrafficManager.new()
	tree.root.add_child(manager)
	for _i in 3:
		manager.tick(1.2, 0.0)
	var ids: Array[String] = []
	var heavy_scale := -1.0
	for vehicle in manager.vehicles():
		if not vehicle.active:
			continue
		ids.append(vehicle.profile.id)
		if vehicle.profile.id == "pesado":
			heavy_scale = vehicle.scale.x
	if ids != ["normal", "rapido", "pesado"]:
		failed.append("spawn order %s" % ids)
	if not is_equal_approx(heavy_scale, TrafficManager.HEAVY_SCALE):
		failed.append("heavy scale %s" % heavy_scale)
	var weaver: TrafficVehicle = manager.vehicles()[3]
	weaver.profile = aggressive
	weaver.activate(1, Vector3(0.0, 0.0, 40.0), StandardMaterial3D.new(), 1.0)
	manager.tick(aggressive.lane_change_interval, 0.0)
	if weaver.lane != 0:
		failed.append("weave %s" % weaver.lane)
	manager.free()
	return failed
