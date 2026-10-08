class_name TitleScreen
extends Control

const RACE_SCENE := "res://scenes/race/race.tscn"
const GARAGE_SCENE := "res://scenes/menu/garage.tscn"
const OPTIONS: Array[String] = ["jugar", "garaje", "records", "opciones", "creditos", "salir"]

var auto_change_scene := true
var started := false
var quit_requested := false
var opened_garage := false
var selection := 0
var page := ""
var page_row := 0

@onready var _options: Array[Label] = []
var _page_label: Label
var _shade: ColorRect


func _ready() -> void:
	theme = preload("res://ui/rushline_theme.tres")
	GameSettings.load_state()
	_options = [%PlayLabel, %GarageLabel, %RecordsLabel, %OptionsLabel, %CreditsLabel, %QuitLabel]
	var state := Progress.load_state()
	%StatusLabel.text = "Dinero %d cr · Récord %d" % [state.money, state.best_score]
	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.03, 0.05, 1)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.visible = false
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)
	_page_label = Label.new()
	_page_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_size_override("font_size", 28)
	_page_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9))
	_page_label.visible = false
	add_child(_page_label)
	_paint()


func _process(_delta: float) -> void:
	if page != "":
		_process_page()
		return
	if Input.is_action_just_pressed("ui_up"):
		selection = posmod(selection - 1, OPTIONS.size())
		_paint()
	elif Input.is_action_just_pressed("ui_down"):
		selection = posmod(selection + 1, OPTIONS.size())
		_paint()
	elif Input.is_action_just_pressed("ui_accept"):
		_confirm()
	elif Input.is_action_just_pressed("ui_cancel"):
		request_quit()


func request_play() -> void:
	if started:
		return
	started = true
	if auto_change_scene:
		get_tree().change_scene_to_file(RACE_SCENE)


func request_garage() -> void:
	if opened_garage:
		return
	opened_garage = true
	if auto_change_scene:
		get_tree().change_scene_to_file(GARAGE_SCENE)


func request_quit() -> void:
	if quit_requested:
		return
	quit_requested = true
	if auto_change_scene:
		get_tree().quit()


func _confirm() -> void:
	match OPTIONS[selection]:
		"jugar":
			request_play()
		"garaje":
			request_garage()
		"records", "opciones", "creditos":
			_open_page(OPTIONS[selection])
		"salir":
			request_quit()


func _open_page(next: String) -> void:
	page = next
	page_row = 0
	_shade.visible = true
	_page_label.visible = true
	_refresh_page()


func _close_page() -> void:
	page = ""
	_shade.visible = false
	_page_label.visible = false


func _process_page() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_close_page()
		return
	if page != "opciones":
		return
	if Input.is_action_just_pressed("ui_up"):
		page_row = posmod(page_row - 1, 3)
	elif Input.is_action_just_pressed("ui_down"):
		page_row = posmod(page_row + 1, 3)
	elif Input.is_action_just_pressed("steer_left"):
		_adjust_option(-0.1)
	elif Input.is_action_just_pressed("steer_right") or Input.is_action_just_pressed("ui_accept"):
		_adjust_option(0.1)
	_refresh_page()


func _adjust_option(step: float) -> void:
	match page_row:
		0:
			GameSettings.music = clampf(GameSettings.music + step, 0.0, 1.0)
		1:
			GameSettings.sfx = clampf(GameSettings.sfx + step, 0.0, 1.0)
		2:
			if step > 0.0:
				GameSettings.muted = not GameSettings.muted
	GameSettings.save()


func _refresh_page() -> void:
	var state := Progress.load_state()
	match page:
		"records":
			_page_label.text = "Récords\n\nMejor puntaje  %d\nCarreras  %d\nDinero  %d cr\n\nEsc vuelve" % [state.best_score, state.races, state.money]
		"creditos":
			_page_label.text = "RUSHLINE\nHJgames\n\nModelos de Kenney, licencia CC0\nMúsica y efectos originales\n\nEsc vuelve"
		"opciones":
			var mute := "Sí" if GameSettings.muted else "No"
			var rows := [
				"Música  %d%%" % GameSettings.music_percent(),
				"Efectos  %d%%" % GameSettings.sfx_percent(),
				"Silencio  %s" % mute,
			]
			rows[page_row] = "> " + rows[page_row]
			_page_label.text = "Opciones\n\n%s\n\nA y D ajustan · Esc vuelve" % "\n".join(rows)


func _paint() -> void:
	for index in _options.size():
		_options[index].modulate = Color(0.74, 0.96, 1) if index == selection else Color(0.95, 0.94, 0.9)
