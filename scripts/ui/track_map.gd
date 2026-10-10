class_name TrackMap
extends Control

var distance_m: float = 0.0
var lateral_x: float = 0.0
var stage_m: float = Course.STAGE_M
var remain_text: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_run(0.0, 0.0)
	call_deferred("queue_redraw")


func set_run(next_distance_m: float, next_lateral_x: float) -> void:
	distance_m = next_distance_m
	lateral_x = next_lateral_x
	remain_text = format_remaining(distance_m, stage_m)
	queue_redraw()


static func format_remaining(run_m: float, stage_m: float) -> String:
	var left := int(ceil(stage_m - run_m))
	if left <= 0:
		return "Meta"
	return "Faltan %d m" % left


func _draw() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08, 0.78))
	draw_string(font, Vector2(16, 32), "Pista", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.74, 0.96, 1))
	var area := Rect2(18.0, 52.0, size.x - 36.0, size.y - 128.0)
	var path := CoursePath.samples(25.0, stage_m)
	var fit := _fit(path, area)
	var screen := fit.points as PackedVector2Array
	draw_polyline(screen, Color(0.1, 0.11, 0.12, 1.0), 16.0, true)
	var run := clampf(distance_m, 0.0, stage_m)
	var split := int(clampf(run / 25.0, 0.0, float(screen.size() - 1)))
	if split > 0:
		draw_polyline(screen.slice(0, split + 1), Color(0.74, 0.96, 1, 0.95), 8.0, true)
	if split < screen.size() - 2:
		draw_polyline(screen.slice(split), Color(0.55, 0.56, 0.58, 0.9), 8.0, true)
	draw_circle(screen[screen.size() - 1], 5.0, Color(0.95, 0.94, 0.9, 1))
	var framed := CoursePath.pose(run, lateral_x)
	var world: Vector3 = framed.position
	var marker := _map_point(Vector2(world.x, world.z), fit)
	draw_circle(marker, 7.0, Color(0.74, 0.96, 1, 1))
	draw_string(font, Vector2(16, size.y - 28.0), remain_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, 20, Color(0.95, 0.94, 0.9))


func _fit(points: PackedVector2Array, area: Rect2) -> Dictionary:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.y)
		max_z = maxf(max_z, point.y)
	var span := maxf(maxf(max_x - min_x, max_z - min_z), 1.0)
	var scale := minf(area.size.x, area.size.y) / span
	var mid := Vector2((min_x + max_x) * 0.5, (min_z + max_z) * 0.5)
	var center := area.position + area.size * 0.5
	var fit := {"mid": mid, "scale": scale, "center": center}
	var screen := PackedVector2Array()
	for point in points:
		screen.append(_map_point(point, fit))
	fit.points = screen
	return fit


func _map_point(point: Vector2, fit: Dictionary) -> Vector2:
	var mid: Vector2 = fit.mid
	var center: Vector2 = fit.center
	var scale := float(fit.scale)
	return center + Vector2((point.x - mid.x) * scale, -(point.y - mid.y) * scale)
