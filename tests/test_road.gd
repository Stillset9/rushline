extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var streamer_script: GDScript = load("res://scripts/world/road_streamer.gd")
	var origins: Array = streamer_script.initial_origins(0.0)
	if origins.size() != 8 or not is_equal_approx(float(origins[0]), -40.0) or not is_equal_approx(float(origins[7]), 240.0):
		failed.append("initial %s" % origins)
	var parked: Array = streamer_script.recycle_origins(origins, 0.0)
	if not is_equal_approx(float(parked[0]), -40.0):
		failed.append("recycled too early")
	var moved: Array = streamer_script.recycle_origins(origins, 21.0)
	var sorted: Array[float] = []
	for value in moved:
		sorted.append(float(value))
	sorted.sort()
	if not is_equal_approx(sorted[0], 0.0) or not is_equal_approx(sorted[7], 280.0):
		failed.append("recycle %s" % sorted)
	var chunk: Node3D = load("res://scenes/world/road_chunk.tscn").instantiate()
	tree.root.add_child(chunk)
	if chunk.get_child_count() != 23:
		failed.append("markings %s" % chunk.get_child_count())
	chunk.queue_free()
	return failed
