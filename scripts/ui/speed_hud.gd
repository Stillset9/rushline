class_name SpeedHud
extends CanvasLayer

@onready var _label: Label = %SpeedLabel
@onready var _distance_label: Label = %DistanceLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _multiplier_label: Label = %MultiplierLabel
@onready var _finish_label: Label = %FinishLabel
@onready var _restart_hint: Label = %RestartHint
@onready var _nitro_label: Label = %NitroLabel
@onready var _course_label: Label = %CourseLabel
@onready var _standing_label: Label = %StandingLabel
@onready var _pause_label: Label = %PauseLabel
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	var font_theme: Theme = preload("res://ui/rushline_theme.tres")
	_apply_font(self, font_theme)


func _apply_font(node: Node, font_theme: Theme) -> void:
	if node is Control:
		(node as Control).theme = font_theme
	for child in node.get_children():
		_apply_font(child, font_theme)


static func format_speed(speed_mps: float) -> String:
	return "%03d km/h" % int(round(speed_mps * 3.6))


static func format_distance(distance_m: float) -> String:
	return "%d m" % int(distance_m)


static func format_score(score: int) -> String:
	return "%d pts" % score


static func format_multiplier(multiplier: int) -> String:
	return "×%d" % multiplier


func show_speed(speed_mps: float) -> void:
	_label.text = format_speed(speed_mps)


func show_distance(distance_m: float) -> void:
	_distance_label.text = format_distance(distance_m)


func show_score(score: int, multiplier: int) -> void:
	_score_label.text = format_score(score)
	_multiplier_label.text = format_multiplier(multiplier)


func show_finish(score: int) -> void:
	_finish_label.visible = true
	_finish_label.text = "Fin\n%s" % format_score(score)
	_restart_hint.visible = true


func show_nitro(tank: float) -> void:
	_nitro_label.text = "Nitro %d%%" % int(round(clampf(tank, 0.0, 1.0) * 100.0))


func show_course(label: String) -> void:
	_course_label.text = label


func show_pause(active: bool, row: int = 0) -> void:
	_pause_label.visible = active
	if not active:
		return
	_pause_label.add_theme_font_size_override("font_size", 40)
	var follow := "> Seguir" if row == 0 else "  Seguir"
	var home := "> Inicio" if row == 1 else "  Inicio"
	_pause_label.text = "Pausa\n\n%s\n%s\n\nArriba y abajo · Enter elige" % [follow, home]


func show_hint(text: String) -> void:
	_hint_label.visible = text != ""
	_hint_label.text = text


func show_standing(best: int, money: int, record: bool) -> void:
	_standing_label.visible = true
	var headline := "Nuevo récord" if record else "Récord %d" % best
	_standing_label.text = "%s\nDinero %d cr" % [headline, money]
