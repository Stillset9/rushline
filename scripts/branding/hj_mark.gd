class_name HJMark
extends Control

const CORE := Color(0.74, 0.96, 1.0, 1.0)
const GLOW := Color(0.28, 0.82, 0.94, 0.35)

var line := 0.0
var reveal := 0.0
var energy := 0.0


func set_state(next_line: float, next_reveal: float, next_energy: float) -> void:
	line = next_line
	reveal = next_reveal
	energy = next_energy
	queue_redraw()


func _draw() -> void:
	var width := maxf(7.0, minf(size.x, size.y) * 0.018)
	_brackets(width)
	if energy > 0.0:
		var radius := _span() * 0.86
		draw_arc(_origin(), radius, -0.5, TAU * energy - 0.5, 72, Color(CORE, 0.42), maxf(1.5, width * 0.16), true)
	_crossbar(width)
	_stem(_at(30.0, 18.0), _at(30.0, 82.0), 0.0, 0.34, width)
	_stem(_at(70.0, 18.0), _at(70.0, 82.0), 0.34, 0.68, width)
	_hook(width)


func _crossbar(width: float) -> void:
	if line <= 0.0:
		return
	var mid := _at(50.0, 50.0)
	var reach := _span() * 0.4 * line
	_glow(mid + Vector2(-reach, 0.0), mid + Vector2(reach, 0.0), width)


func _stem(a: Vector2, b: Vector2, from: float, to: float, width: float) -> void:
	var local := clampf((reveal - from) / (to - from), 0.0, 1.0)
	if local <= 0.0:
		return
	_glow(a, a.lerp(b, local), width)


func _hook(width: float) -> void:
	var keys: Array[Vector2] = [Vector2(70, 82), Vector2(64, 92), Vector2(48, 96), Vector2(40, 90)]
	var marks: Array[float] = [0.68, 0.8, 0.92, 1.0]
	if reveal <= marks[0]:
		return
	var points := PackedVector2Array([_at(keys[0].x, keys[0].y)])
	for index in range(1, keys.size()):
		var local := clampf((reveal - marks[index - 1]) / (marks[index] - marks[index - 1]), 0.0, 1.0)
		var start := _at(keys[index - 1].x, keys[index - 1].y)
		var finish := _at(keys[index].x, keys[index].y)
		points.append(start.lerp(finish, local))
		if local < 1.0:
			break
	if points.size() < 2:
		return
	var hook_width := width * 0.7
	draw_polyline(points, Color(GLOW.r, GLOW.g, GLOW.b, 0.4), hook_width * 2.2, true)
	draw_polyline(points, CORE, hook_width, true)
	draw_polyline(points, Color(1, 1, 1, 0.9), maxf(1.5, hook_width * 0.18), true)


func _brackets(width: float) -> void:
	var alpha := clampf(reveal, 0.0, 1.0) * 0.7
	if alpha <= 0.0:
		return
	var inset := minf(size.x, size.y) * 0.075
	var arm := minf(size.x, size.y) * 0.04
	var color := Color(CORE, alpha * 0.45)
	var stroke := maxf(1.5, width * 0.16)
	var corners: Array[Vector2] = [
		Vector2(inset, inset),
		Vector2(size.x - inset, inset),
		Vector2(inset, size.y - inset),
		Vector2(size.x - inset, size.y - inset),
	]
	var signs: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for index in corners.size():
		var corner := corners[index]
		var sign := signs[index]
		draw_line(corner, corner + Vector2(sign.x * arm, 0.0), color, stroke, true)
		draw_line(corner, corner + Vector2(0.0, sign.y * arm), color, stroke, true)


func _glow(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, GLOW, width * 2.6, true)
	draw_line(a, b, CORE, width, true)
	draw_line(a, b, Color(1.0, 1.0, 1.0, 0.92), maxf(1.5, width * 0.18), true)


static func origin_for(view: Vector2) -> Vector2:
	return view * 0.5 + Vector2(0.0, -view.y * 0.1)


func _origin() -> Vector2:
	return origin_for(size)


func _span() -> float:
	return minf(size.x, size.y) * 0.2


func _at(x: float, y: float) -> Vector2:
	return _origin() + Vector2((x - 50.0) / 50.0, (y - 50.0) / 50.0) * _span()
