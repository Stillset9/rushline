class_name TitleScreen
extends Control

const RACE_SCENE := "res://scenes/race/race.tscn"
const GARAGE_SCENE := "res://scenes/menu/garage.tscn"
const OPTIONS: Array[String] = ["jugar", "garaje", "salir"]

var auto_change_scene := true
var started := false
var quit_requested := false
var opened_garage := false
var selection := 0

@onready var _options: Array[Label] = []


func _ready() -> void:
	_options = [%PlayLabel, %GarageLabel, %QuitLabel]
	var state := Progress.load_state()
	%StatusLabel.text = "Dinero %d cr · Récord %d" % [state.money, state.best_score]
	_paint()


func _process(_delta: float) -> void:
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
		"salir":
			request_quit()


func _paint() -> void:
	for index in _options.size():
		_options[index].modulate = Color(0.74, 0.96, 1) if index == selection else Color(0.95, 0.94, 0.9)
