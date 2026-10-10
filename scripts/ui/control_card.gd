class_name ControlCard
extends Control

const KEYS: PackedStringArray = ["A", "D", "S  espacio", "Shift", "Q", "Esc", "Enter"]
const USES: PackedStringArray = ["izquierda", "derecha", "frena", "nitro", "marcha", "pausa", "reanuda"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("queue_redraw")


func _draw() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08, 0.78))
	draw_string(font, Vector2(18, 34), "Controles", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.74, 0.96, 1))
	var y := 52.0
	for index in KEYS.size():
		var chip := Rect2(16, y, 168, 40)
		draw_rect(chip, Color(0.74, 0.96, 1, 0.16))
		draw_string(font, Vector2(28, y + 28), KEYS[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.74, 0.96, 1))
		draw_string(font, Vector2(196, y + 28), USES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.94, 0.9))
		y += 50.0
