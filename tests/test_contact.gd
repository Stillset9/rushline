extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var body := Contact.half_extents(1.0)
	if not body.is_equal_approx(Vector2(0.9, 2.0)):
		failed.append("body half %s" % body)
	var grown := Contact.half_extents(1.05)
	if not grown.is_equal_approx(Vector2(0.945, 2.1)):
		failed.append("scaled half %s" % grown)
	if Contact.overlaps(Vector2(0, 0), body, Vector2(3, 0), body):
		failed.append("separated x")
	if Contact.overlaps(Vector2(0, 0), body, Vector2(0, 5), body):
		failed.append("separated z")
	if not Contact.overlaps(Vector2(0.5, 0.5), body, Vector2(0, 0), body):
		failed.append("overlap")
	if Contact.overlaps(Vector2(body.x * 2.0, 0), body, Vector2.ZERO, body):
		failed.append("edge touch")
	var high := Vector2(Vector3(0, 10, 0).x, Vector3(0, 10, 0).z)
	var low := Vector2(Vector3(0, -4, 0).x, Vector3(0, -4, 0).z)
	if not Contact.overlaps(high, body, low, body):
		failed.append("height")
	if not is_equal_approx(Contact.speed_after_hits(30.0, 1), 15.0):
		failed.append("drop 30")
	if not is_equal_approx(Contact.speed_after_hits(70.0, 1), 55.0):
		failed.append("drop 70")
	if not is_equal_approx(Contact.speed_after_hits(8.0, 1), 8.0):
		failed.append("floor")
	if not is_equal_approx(Contact.speed_after_hits(20.0, 2), 8.0):
		failed.append("two hits")
	if not is_equal_approx(Contact.speed_after_hits(30.0, 0), 30.0):
		failed.append("zero hits")
	failed.append_array(_episodes(tree))
	return failed


func _episodes(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var first := _vehicle(tree, Vector3(0, 0, 0), 1.0, true)
	var second := _vehicle(tree, Vector3(0, 0, 0), 1.0, true)
	var asleep := _vehicle(tree, Vector3(0, 0, 0), 1.0, false)
	var vehicles: Array[TrafficVehicle] = [first, second, asleep]
	var hits := Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 2 or not first.in_contact or not second.in_contact or asleep.in_contact:
		failed.append("first sweep %s" % hits)
	hits = Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 0:
		failed.append("held %s" % hits)
	first.global_position = Vector3(0, 0, 20)
	hits = Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 0 or first.in_contact:
		failed.append("separate %s" % hits)
	first.global_position = Vector3.ZERO
	hits = Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 1 or not first.in_contact:
		failed.append("return %s" % hits)
	var grazes := _vehicle(tree, Vector3(1.84, 5, 0), 1.0, true)
	var wide := _vehicle(tree, Vector3(1.84, 5, 0), 1.05, true)
	var miss: Array[TrafficVehicle] = [grazes]
	if Contact.collect_new_hits(Vector3.ZERO, miss) != 0:
		failed.append("scale 1 should miss")
	var hit_scale: Array[TrafficVehicle] = [wide]
	if Contact.collect_new_hits(Vector3.ZERO, hit_scale) != 1:
		failed.append("scale 1.05 should hit")
	first.in_contact = true
	first.deactivate()
	if first.in_contact or first.active:
		failed.append("deactivate flag")
	second.in_contact = true
	second.activate(1, Vector3(4, 0, 9), StandardMaterial3D.new(), 1.0)
	if second.in_contact or not second.active:
		failed.append("activate flag")
	for vehicle in [first, second, asleep, grazes, wide]:
		vehicle.queue_free()
	return failed


func _vehicle(tree: SceneTree, at: Vector3, scale_factor: float, is_active: bool) -> TrafficVehicle:
	var vehicle := TrafficVehicle.new()
	tree.root.add_child(vehicle)
	vehicle.active = is_active
	vehicle.global_position = at
	vehicle.scale = Vector3.ONE * scale_factor
	vehicle.in_contact = false
	return vehicle
