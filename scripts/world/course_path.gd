class_name CoursePath
extends RefCounted

const STRAIGHT_M := 100000.0


static func on_straight(_along: float) -> bool:
	return true


static func pose(along: float, lateral: float) -> Dictionary:
	return {
		"position": Vector3(lateral, 0.0, along),
		"yaw": 0.0,
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
