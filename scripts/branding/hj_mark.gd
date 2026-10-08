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
	var width := maxf(4.0, minf(size.x, size.y) * 0.012)
	_crossbar(width)
	_stem(_at(30.0, 18.0), _at(30.0, 82.0), 0.0, 0.34, width)
	_stem(_at(70.0, 18.0), _at(70.0, 82.0), 0.34, 0.68, width)
	_stem(_at(70.0, 82.0), _at(64.0, 92.0), 0.68, 0.8, width)
	_stem(_at(64.0, 92.0), _at(48.0, 96.0), 0.8, 0.92, width)
	_stem(_at(48.0, 96.0), _at(40.0, 90.0), 0.92, 1.0, width)
	if energy <= 0.0:
		return
	var radius := _span() * (0.72 + energy * 0.18)
	draw_arc(_origin(), radius, -0.4, TAU * energy - 0.4, 48, Color(CORE, 0.45 * (1.0 - energy * 0.35)), width * 0.45)


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


func _glow(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, GLOW, width * 3.2, true)
	draw_line(a, b, CORE, width, true)


static func origin_for(view: Vector2) -> Vector2:
	return view * 0.5 + Vector2(0.0, -view.y * 0.06)


func _origin() -> Vector2:
	return origin_for(size)


func _span() -> float:
	return minf(size.x, size.y) * 0.22


func _at(x: float, y: float) -> Vector2:
	return _origin() + Vector2((x - 50.0) / 50.0, (y - 50.0) / 50.0) * _span()
