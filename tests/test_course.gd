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
