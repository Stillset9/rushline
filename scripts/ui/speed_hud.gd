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
@onready var _track_map: TrackMap = %TrackMap

var _fuel_label: Label
var _fuel_fill: ColorRect
var _gear_label: Label
var _lines_material: ShaderMaterial
var _blur_material: ShaderMaterial
var _card: Control
var _banner: Label
var _shade: ColorRect
var _controls_s := 0.0
var _banner_s := 0.0
var _paused_ui := false


func _ready() -> void:
	var font_theme: Theme = preload("res://ui/rushline_theme.tres")
	_apply_font(self, font_theme)
	_build_fuel()
	_build_pace()
	_build_chrome()


func _process(delta: float) -> void:
	if _banner != null and _banner_s > 0.0:
		_banner_s = maxf(0.0, _banner_s - delta)
		var life := clampf(_banner_s / 0.35, 0.0, 1.0)
		var intro := clampf((2.3 - _banner_s) / 0.28, 0.0, 1.0)
		_banner.modulate.a = minf(life, intro)
		_banner.scale = Vector2.ONE * lerpf(1.08, 1.0, intro)
		_banner.visible = _banner_s > 0.0
	if _card == null or _paused_ui:
		return
	if _controls_s > 0.0:
		_controls_s = maxf(0.0, _controls_s - delta)
	_card.visible = _controls_s > 0.0


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


func show_track(distance_m: float, lateral_x: float, stage_m: float = -1.0) -> void:
	if stage_m > 0.0:
		_track_map.stage_m = stage_m
	_track_map.set_run(distance_m, lateral_x)


func show_score(score: int, multiplier: int) -> void:
	_score_label.text = format_score(score)
	_multiplier_label.text = format_multiplier(multiplier)


func show_finish(score: int, reason: String = "") -> void:
	_finish_label.visible = true
	var title := "Fin"
	if reason == "meta":
		title = "Meta"
	elif reason == "sin_combustible":
		title = "Sin combustible"
	_finish_label.text = "%s\n%s" % [title, format_score(score)]
	_restart_hint.visible = true
	if _shade != null:
		_shade.visible = true


func show_fuel(fraction: float) -> void:
	if _fuel_label == null:
		return
	var clamped := clampf(fraction, 0.0, 1.0)
	_fuel_label.text = "Combustible %d%%" % int(round(clamped * 100.0))
	_fuel_label.modulate = Color(0.95, 0.35, 0.22) if clamped < 0.25 else Color(0.95, 0.78, 0.28)
	if _fuel_fill != null:
		_fuel_fill.size.x = 208.0 * clamped
		_fuel_fill.color = Color(0.95, 0.35, 0.22) if clamped < 0.25 else Color(0.95, 0.72, 0.18)


func show_gear(high: bool) -> void:
	if _gear_label == null:
		return
	_gear_label.text = "Alta" if high else "Baja"


func show_pace(speed_mps: float, boosting: bool) -> void:
	var lines := GraphicsProfile.pace_lines(speed_mps, boosting)
	if _lines_material != null:
		_lines_material.set_shader_parameter("strength", lines * 0.8)
	if _blur_material != null:
		_blur_material.set_shader_parameter("strength", GraphicsProfile.pace_blur(speed_mps, boosting))


func show_nitro(tank: float) -> void:
	_nitro_label.text = "Nitro %d%%" % int(round(clampf(tank, 0.0, 1.0) * 100.0))


func show_course(label: String) -> void:
	_course_label.text = label


func show_pause(active: bool, row: int = 0) -> void:
	_paused_ui = active
	_pause_label.visible = active
	if _card != null:
		_card.visible = active or _controls_s > 0.0
	if not active:
		return
	_pause_label.add_theme_font_size_override("font_size", 40)
	var follow := "> Seguir" if row == 0 else "  Seguir"
	var home := "> Inicio" if row == 1 else "  Inicio"
	_pause_label.text = "Pausa\n\n%s\n%s\n\nArriba y abajo · Enter o clic" % [follow, home]


func show_hint(text: String) -> void:
	_hint_label.visible = text != ""
	_hint_label.text = text


func show_standing(best: int, money: int, record: bool, distance_m: float = 0.0, elapsed_s: float = 0.0, crashes: int = 0) -> void:
	_standing_label.visible = true
	var headline := "Nuevo récord" if record else "Récord %d" % best
	var minutes := int(elapsed_s) / 60
	var seconds := int(elapsed_s) % 60
	_standing_label.text = "Distancia  %d m\nTiempo  %d:%02d\nChoques  %d\n%s\nDinero  %d cr" % [int(distance_m), minutes, seconds, crashes, headline, money]


func show_banner(text: String) -> void:
	if _banner == null:
		return
	_banner.text = text
	_banner_s = 2.3
	_banner.visible = true
	_banner.modulate.a = 0.0


func present_controls(seconds: float) -> void:
	_controls_s = seconds
	if _card != null:
		_card.visible = true


func _build_fuel() -> void:
	var panel := $Panel as Control
	panel.offset_bottom = 330.0
	_track_map.offset_top = 292.0
	_track_map.offset_bottom = 560.0
	_gear_label = Label.new()
	_gear_label.position = Vector2(168.0, 176.0)
	_gear_label.size = Vector2(90.0, 32.0)
	_gear_label.add_theme_font_size_override("font_size", 22)
	_gear_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9))
	_gear_label.text = "Alta"
	panel.add_child(_gear_label)
	_fuel_label = Label.new()
	_fuel_label.position = Vector2(16.0, 214.0)
	_fuel_label.size = Vector2(240.0, 28.0)
	_fuel_label.add_theme_font_size_override("font_size", 22)
	_fuel_label.text = "Combustible 100%"
	panel.add_child(_fuel_label)
	var track := ColorRect.new()
	track.position = Vector2(16.0, 248.0)
	track.size = Vector2(208.0, 12.0)
	track.color = Color(0.12, 0.12, 0.14, 0.9)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(track)
	_fuel_fill = ColorRect.new()
	_fuel_fill.position = Vector2(16.0, 248.0)
	_fuel_fill.size = Vector2(208.0, 12.0)
	_fuel_fill.color = Color(0.95, 0.72, 0.18)
	_fuel_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_fuel_fill)
	var font_theme: Theme = preload("res://ui/rushline_theme.tres")
	_gear_label.theme = font_theme
	_fuel_label.theme = font_theme


func _build_chrome() -> void:
	_card = get_node_or_null("ControlCard")
	if _card != null:
		_card.visible = false
	_shade = ColorRect.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.01, 0.015, 0.03, 0.62)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.visible = false
	add_child(_shade)
	move_child(_shade, 0)
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -520.0
	_banner.offset_top = 150.0
	_banner.offset_right = 520.0
	_banner.offset_bottom = 230.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 54)
	_banner.add_theme_color_override("font_color", Color(0.74, 0.96, 1))
	_banner.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05))
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.theme = preload("res://ui/rushline_theme.tres")
	_banner.pivot_offset = Vector2(520, 40)
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


func _build_pace() -> void:
	var lines := ColorRect.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.color = Color(1, 1, 1, 1)
	_lines_material = ShaderMaterial.new()
	_lines_material.shader = preload("res://shaders/speed_lines.gdshader")
	_lines_material.set_shader_parameter("strength", 0.0)
	lines.material = _lines_material
	add_child(lines)
	move_child(lines, 0)
	if DisplayServer.get_name() == "headless" or not GraphicsProfile.fancy():
		return
	var blur := ColorRect.new()
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur_material = ShaderMaterial.new()
	_blur_material.shader = preload("res://shaders/radial_blur.gdshader")
	_blur_material.set_shader_parameter("strength", 0.0)
	blur.material = _blur_material
	add_child(blur)
	move_child(blur, 0)
