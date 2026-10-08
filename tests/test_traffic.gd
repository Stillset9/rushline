extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var manager_script: GDScript = load("res://scripts/traffic/traffic_manager.gd")
	if not is_equal_approx(manager_script.lane_center(0), -4.0):
		failed.append("lane 0")
	if manager_script.choose_lane(90.0, []) != 0:
		failed.append("empty lanes")
	var blocked: Array = [
		{"lane": 0, "z": 90.0},
		{"lane": 1, "z": 90.0},
		{"lane": 2, "z": 90.0},
	]
	if manager_script.choose_lane(90.0, blocked) != -1:
		failed.append("all blocked")
	var edge: Array = [
		{"lane": 0, "z": 108.0},
		{"lane": 1, "z": 90.0},
		{"lane": 2, "z": 100.0},
	]
	if manager_script.choose_lane(90.0, edge) != 0:
		failed.append("gap of 18 should be free")
	var inside: Array = [{"lane": 0, "z": 107.9}]
	if manager_script.choose_lane(90.0, inside) != 1:
		failed.append("gap under 18")
	var manager: Node3D = manager_script.new()
	tree.root.add_child(manager)
	if manager.get_child_count() != 12:
		failed.append("pool %s" % manager.get_child_count())
	manager.tick(1.2, 0.0)
	var first := _active(manager)
	if first.size() != 1:
		failed.append("first spawn %s" % first.size())
	elif not is_equal_approx(first[0].global_position.x, -4.0) or not is_equal_approx(first[0].global_position.z, 90.0) or not is_equal_approx(first[0].scale.x, 0.95):
		failed.append("first pose %s %s" % [first[0].global_position, first[0].scale.x])
	elif first[0].get_node("Body").material_override.albedo_color != Color("c4513a"):
		failed.append("first color")
	manager.tick(1.2, 0.0)
	var second := _active(manager)
	if second.size() != 2:
		failed.append("second spawn %s" % second.size())
	manager.tick(0.0, 400.0)
	if not _active(manager).is_empty():
		failed.append("despawn")
	if manager.get_child_count() != 12:
		failed.append("pool changed")
	manager.queue_free()
	return failed


func _active(manager: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child in manager.get_children():
		if child.active:
			found.append(child)
	return found
