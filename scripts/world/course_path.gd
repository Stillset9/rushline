class_name CoursePath
extends RefCounted

const STRAIGHT_M := 360.0
const RADIUS_M := 90.0
const ARC_M := PI * RADIUS_M * 0.5
const RUN_M := 80.0
const COVER_M := 2100.0

static var _segments: Array[Dictionary] = []


static func on_straight(along: float) -> bool:
	return along < STRAIGHT_M


static func pose(along: float, lateral: float) -> Dictionary:
	var center := _center(along)
	var basis := Basis(Vector3.UP, center.yaw)
	return {
		"position": center.origin + basis * Vector3(lateral, 0.0, 0.0),
		"yaw": center.yaw,
	}


static func present(node: Node3D, along: float, lateral: float) -> void:
	var height := node.position.y
	var framed := pose(along, lateral)
	var point: Vector3 = framed.position
	node.rotation = Vector3(0.0, framed.yaw, 0.0)
	node.position = Vector3(point.x, height, point.z)


static func place_span(node: Node3D, origin: float, length: float) -> void:
	var height := node.position.y
	var mid := pose(origin + length * 0.5, 0.0)
	var basis := Basis(Vector3.UP, mid.yaw)
	var point: Vector3 = mid.position
	var start := point - basis * Vector3(0.0, 0.0, length * 0.5)
	node.rotation = Vector3(0.0, mid.yaw, 0.0)
	node.position = Vector3(start.x, height, start.z)


static func samples(step_m: float, until_m: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var along := 0.0
	while along < until_m:
		var framed := pose(along, 0.0)
		var point: Vector3 = framed.position
		points.append(Vector2(point.x, point.z))
		along += step_m
	var end := pose(until_m, 0.0)
	var end_point: Vector3 = end.position
	points.append(Vector2(end_point.x, end_point.z))
	return points


static func _center(along: float) -> Dictionary:
	if along <= 0.0:
		return {"origin": Vector3(0.0, 0.0, along), "yaw": 0.0}
	var traveled := 0.0
	var x := 0.0
	var z := 0.0
	var yaw := 0.0
	for segment in _layout():
		var length := float(segment.length)
		var take := minf(length, along - traveled)
		if take > 0.0:
			var step := _advance(x, z, yaw, float(segment.curv), take)
			x = float(step.x)
			z = float(step.z)
			yaw = float(step.yaw)
		traveled += length
		if traveled >= along:
			break
	return {"origin": Vector3(x, 0.0, z), "yaw": yaw}


static func _advance(x: float, z: float, yaw: float, curv: float, dist: float) -> Dictionary:
	if absf(curv) < 0.00001:
		var basis := Basis(Vector3.UP, yaw)
		var step := basis * Vector3(0.0, 0.0, dist)
		return {"x": x + step.x, "z": z + step.z, "yaw": yaw}
	var yaw_end := yaw + curv * dist
	return {
		"x": x + (-cos(yaw_end) + cos(yaw)) / curv,
		"z": z + (sin(yaw_end) - sin(yaw)) / curv,
		"yaw": yaw_end,
	}


static func _layout() -> Array[Dictionary]:
	if not _segments.is_empty():
		return _segments
	_segments.append({"length": STRAIGHT_M, "curv": 0.0})
	var covered := STRAIGHT_M
	var turn := 1.0
	while covered < COVER_M:
		var run := minf(RUN_M, COVER_M - covered)
		_segments.append({"length": run, "curv": 0.0})
		covered += run
		if covered >= COVER_M:
			break
		var arc := minf(ARC_M, COVER_M - covered)
		_segments.append({"length": arc, "curv": turn / RADIUS_M})
		covered += arc
		turn = -turn
	return _segments
