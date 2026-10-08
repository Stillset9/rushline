extends RefCounted

func run(_tree: SceneTree) -> Array:
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
	return failed
