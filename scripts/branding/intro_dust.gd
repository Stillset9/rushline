extends Control

var amount := 0.0
var time_s := 0.0


func set_field(next_amount: float, next_time: float) -> void:
	amount = next_amount
	time_s = next_time
	queue_redraw()


func _draw() -> void:
	if amount <= 0.01 or size.x < 2.0:
		return
	for index in 42:
		var seed_x := sin(float(index) * 12.9898) * 0.5 + 0.5
		var seed_y := cos(float(index) * 78.233) * 0.5 + 0.5
		var drift := time_s * (6.0 + float(index % 5) * 1.8)
		var point := Vector2(
			fposmod(seed_x * size.x + drift, size.x),
			fposmod(seed_y * size.y - drift * 0.28, size.y)
		)
		var twinkle := 0.4 + 0.6 * absf(sin(time_s * 0.75 + float(index) * 0.7))
		var alpha := amount * twinkle * 0.2
		draw_circle(point, 1.05 + float(index % 3) * 0.5, Color(0.74, 0.88, 1.0, alpha))
