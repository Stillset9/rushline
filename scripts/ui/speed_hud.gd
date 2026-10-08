class_name SpeedHud
extends CanvasLayer

@onready var _label: Label = %SpeedLabel


static func format_speed(speed_mps: float) -> String:
	return "%03d km/h" % int(round(speed_mps * 3.6))


func show_speed(speed_mps: float) -> void:
	_label.text = format_speed(speed_mps)
