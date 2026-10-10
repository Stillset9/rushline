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
var _reveal := 1.0
var _accent: ColorRect

@onready var _options: Array[Label] = []
var _page_label: Label
var _shade: ColorRect


func _ready() -> void:
	theme = preload("res://ui/rushline_theme.tres")
	GameSettings.load_state()
	_mount_stage()
	_reveal = 0.0
	_options = [%PlayLabel, %GarageLabel, %RecordsLabel, %OptionsLabel, %CreditsLabel, %QuitLabel]
	_outline(%TitleLabel)
	_outline(%StatusLabel)
	_outline(get_node("HintLabel") as Label)
	for option in _options:
		_outline(option)
	_compose_menu()
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
	_page_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_page_label.gui_input.connect(_on_page_click)
	add_child(_page_label)
	for index in _options.size():
		var option := _options[index]
		option.mouse_filter = Control.MOUSE_FILTER_STOP
		option.pivot_offset = Vector2(320, 23)
		option.gui_input.connect(_on_menu_click.bind(index))
		option.mouse_entered.connect(_on_menu_hover.bind(index))
	_paint()


func _process(delta: float) -> void:
	if _reveal < 1.0:
		_reveal = minf(1.0, _reveal + delta * 1.8)
		_paint()
	if page != "":
		_process_page()
		return
	if Input.is_action_just_pressed("ui_up"):
		selection = posmod(selection - 1, OPTIONS.size())
		UiAudio.blip()
		_paint()
	elif Input.is_action_just_pressed("ui_down"):
		selection = posmod(selection + 1, OPTIONS.size())
		UiAudio.blip()
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
		SceneFade.to(RACE_SCENE)


func request_garage() -> void:
	if opened_garage:
		return
	opened_garage = true
	if auto_change_scene:
		SceneFade.to(GARAGE_SCENE)


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
		page_row = posmod(page_row - 1, 5)
	elif Input.is_action_just_pressed("ui_down"):
		page_row = posmod(page_row + 1, 5)
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
		3:
			GameSettings.cycle_quality(1 if step > 0.0 else -1)
		4:
			GameSettings.toggle_skip()
	GameSettings.save()
	UiAudio.blip()


func _refresh_page() -> void:
	var state := Progress.load_state()
	match page:
		"records":
			_page_label.text = "Récords\n\nMejor puntaje  %d\nCarreras  %d\nEtapa  %d/%d\nDinero  %d cr\n\nEsc vuelve" % [state.best_score, state.races, state.best_stage, StageRun.count(), state.money]
		"creditos":
			_page_label.text = "RUSHLINE\nHJgames\n\nLlega a la meta de cada etapa sin quedarte sin combustible.\nLos bidones amarillos recargan y suman puntos.\n\nAutos de Grab3D, licencia CC0\nCiudad y naturaleza de Kenney, CC0\nMúsica: Pure Raceway, MintoDog, CC0\nTipografía: Orbitron y Noto Sans, OFL\nBidones, vallas, efectos y sonido de intro originales\n\nEsc vuelve"
		"opciones":
			var mute := "Sí" if GameSettings.muted else "No"
			var rows := [
				"Música  %d%%" % GameSettings.music_percent(),
				"Efectos  %d%%" % GameSettings.sfx_percent(),
				"Silencio  %s" % mute,
				"Gráficos  %s" % GameSettings.quality_name(),
				"Saltar intro  %s" % GameSettings.skip_name(),
			]
			rows[page_row] = "> " + rows[page_row]
			_page_label.text = "Opciones\n\n%s\n\nA y D ajustan · clic también · Esc vuelve" % "\n".join(rows)


func _on_menu_hover(index: int) -> void:
	if selection == index:
		return
	selection = index
	UiAudio.blip()
	_paint()


func _on_menu_click(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selection = index
		_paint()
		_confirm()


func _on_page_click(event: InputEvent) -> void:
	if page != "opciones":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mid := _page_label.size.x * 0.5
		_adjust_option(-0.1 if event.position.x < mid else 0.1)
		_refresh_page()


func _compose_menu() -> void:
	var panel := ColorRect.new()
	panel.name = "MenuPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.color = Color(0.015, 0.02, 0.035, 0.78)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 28.0
	panel.offset_top = 36.0
	panel.offset_right = 560.0
	panel.offset_bottom = 980.0
	add_child(panel)
	var accent := ColorRect.new()
	accent.name = "MenuAccent"
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.color = Color(0.35, 0.82, 0.95, 0.92)
	accent.set_anchors_preset(Control.PRESET_TOP_LEFT)
	accent.offset_left = 28.0
	accent.offset_top = 36.0
	accent.offset_right = 34.0
	accent.offset_bottom = 980.0
	add_child(accent)
	var title := get_node_or_null("TitleLabel")
	if title != null:
		move_child(panel, title.get_index())
		move_child(accent, title.get_index())
	_column(%TitleLabel, 64.0, 92.0, 58)
	_column(%StatusLabel, 156.0, 40.0, 20)
	var top := 250.0
	for option in _options:
		_column(option, top, 52.0, 30)
		option.pivot_offset = Vector2(0.0, 26.0)
		top += 62.0
	_column(get_node("HintLabel") as Label, 860.0, 36.0, 16)
	%QuitLabel.text = "Salir"


func _column(label: Label, top: float, height: float, font_size: int) -> void:
	if label == null:
		return
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.offset_left = 64.0
	label.offset_top = top
	label.offset_right = 520.0
	label.offset_bottom = top + height
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 8)


func _outline(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.03, 0.95))
	label.add_theme_constant_override("outline_size", 6)


func _mount_stage() -> void:
	if DisplayServer.get_name() == "headless":
		return
	GraphicsProfile.apply_viewport(get_viewport())
	var stage := MenuStage.new()
	stage.name = "MenuStage"
	add_child(stage)
	var wash := get_node_or_null("Background") as ColorRect
	if wash != null:
		wash.visible = false


func _paint() -> void:
	for index in _options.size():
		var lit := index == selection
		var color := Color(0.74, 0.96, 1) if lit else Color(0.95, 0.94, 0.9)
		color.a = _reveal
		_options[index].modulate = color
		_options[index].scale = Vector2.ONE * (1.04 if lit else 1.0)
	if _accent == null and not _options.is_empty():
		_accent = ColorRect.new()
		_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_accent.color = Color(0.74, 0.96, 1, 0.9)
		_accent.size = Vector2(8, 28)
		add_child(_accent)
	if _accent != null and selection < _options.size():
		var row := _options[selection]
		_accent.global_position = row.global_position + Vector2(-28, 6)
		_accent.modulate.a = _reveal
