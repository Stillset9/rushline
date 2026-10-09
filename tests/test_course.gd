extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if Course.theme_count() != 7:
		failed.append("themes %s" % Course.theme_count())
	if Course.weather_count() != 3:
		failed.append("weathers %s" % Course.weather_count())
	var city: Dictionary = Course.theme(0)
	if str(city["name"]) != "Ciudad":
		failed.append("city")
	if city["asphalt"] != RoadChunk.ASPHALT or city["paint"] != RoadChunk.PAINT:
		failed.append("city colors")
	if float(Course.weather(0)["grip"]) != 1.0:
		failed.append("clear grip")
	if float(Course.weather(1)["grip"]) >= 1.0:
		failed.append("rain grip")
	var seen: Dictionary = {}
	for index in Course.theme_count():
		seen[str(Course.theme(index)["id"])] = true
	if seen.size() != 7:
		failed.append("unique %s" % seen.keys())
	var chunk := RoadChunk.new()
	tree.root.add_child(chunk)
	chunk.apply_palette(Color(1, 0, 0), Color(0, 1, 0))
	var wide := _wide_color(chunk)
	var thin := _thin_color(chunk)
	if wide != Color(1, 0, 0) or thin != Color(0, 1, 0):
		failed.append("palette %s %s" % [wide, thin])
	chunk.free()
	var forward := Basis(Vector3.UP, PI * 0.5) * Vector3(0.0, 0.0, 1.0)
	if absf(forward.x - 1.0) > 0.01 or absf(forward.z) > 0.01:
		failed.append("forward %s" % forward)
	var straight: Dictionary = CoursePath.pose(100.0, 4.0)
	var straight_point: Vector3 = straight.position
	if absf(straight_point.x - 4.0) > 0.01 or absf(straight_point.z - 100.0) > 0.01 or absf(float(straight.yaw)) > 0.001:
		failed.append("straight %s" % straight_point)
	var behind: Dictionary = CoursePath.pose(-10.5, 2.0)
	var behind_point: Vector3 = behind.position
	if absf(behind_point.z + 10.5) > 0.01 or absf(behind_point.x - 2.0) > 0.01:
		failed.append("behind %s" % behind_point)
	var bent: Dictionary = CoursePath.pose(CoursePath.STRAIGHT_M + CoursePath.ARC_M, 0.0)
	var bent_point: Vector3 = bent.position
	if absf(bent_point.x) < 5.0 or absf(float(bent.yaw)) < 0.2 or bent_point.z < CoursePath.STRAIGHT_M + 50.0:
		failed.append("bend %s yaw %s" % [bent_point, bent.yaw])
	var span := 0.0
	for point in CoursePath.samples(40.0, Course.STAGE_M):
		span = maxf(span, absf(point.x))
	if span < 20.0:
		failed.append("map span %s" % span)
	return failed


func _wide_color(chunk: Node) -> Color:
	for child in chunk.get_children():
		var box := child.mesh as BoxMesh
		if box != null and box.size.x > 1.0:
			return child.material_override.albedo_color
	return Color(0, 0, 0)


func _thin_color(chunk: Node) -> Color:
	for child in chunk.get_children():
		var box := child.mesh as BoxMesh
		if box != null and box.size.x < 1.0:
			return child.material_override.albedo_color
	return Color(0, 0, 0)
