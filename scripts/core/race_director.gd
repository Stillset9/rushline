class_name RaceDirector
extends Node3D

signal speed_changed(speed_mps: float)
signal distance_changed(distance_m: float)
signal score_changed(score: int, multiplier: int)
signal race_finished(score: int)

const INITIAL_MAX_SPEED_MPS := 30.0
const SPEED_CAP_MPS := 70.0
const MAX_SPEED_RAMP := 0.15
const HITS_TO_END := 3
const RACE_SCENE := "res://scenes/race/race.tscn"

var max_speed_mps: float = INITIAL_MAX_SPEED_MPS
var initial_max_mps: float = INITIAL_MAX_SPEED_MPS
var speed_cap_mps: float = SPEED_CAP_MPS
var distance_m: float = 0.0
var elapsed_s: float = 0.0
var crashes: int = 0
var finished: bool = false
var paused: bool = false
var hint_s: float = 0.0
var restart_scene: bool = true
var restarted: bool = false
var score_keeper := ScoreKeeper.new()
var progress := Progress.new()

var _shown_kmh: int = -1
var _shown_distance_m: int = -1
var _shown_score: int = -1
var _shown_multiplier: int = 0

@onready var player: PlayerController = $PlayerVehicle
@onready var road: RoadStreamer = $RoadStreamer
@onready var street: StreetDressing = $StreetDressing
@onready var rain: RainStreaks = $RaceCamera/Rain
@onready var traffic: TrafficManager = $TrafficManager
@onready var oil: OilManager = $OilManager
@onready var race_audio: RaceAudio = $RaceAudio
@onready var race_camera: RaceCamera = $RaceCamera
@onready var hud: SpeedHud = $SpeedHud
@onready var world: WorldEnvironment = $WorldEnvironment

var _skids: SkidMarks

static func planned_max_speed(time_s: float) -> float:
	return minf(SPEED_CAP_MPS, INITIAL_MAX_SPEED_MPS + MAX_SPEED_RAMP * time_s)


static func displayed_kmh(speed_mps: float) -> int:
	return int(round(speed_mps * 3.6))


static func displayed_score(score: float) -> int:
	return int(score)


func begin_frame(delta: float) -> void:
	elapsed_s += delta
	max_speed_mps = minf(speed_cap_mps, initial_max_mps + MAX_SPEED_RAMP * elapsed_s)


# Atajo de tiempo y distancia. No resuelve choques ni puntos.
func advance_race(delta: float, speed_mps: float) -> void:
	begin_frame(delta)
	_commit_motion(speed_mps, delta)


func _ready() -> void:
	progress = Progress.load_state()
	_apply_tune(progress)
	player.max_speed_mps = max_speed_mps
	road.setup(player.global_position.z)
	street.follow(road.origins())
	_apply_world(progress)
	race_camera.snap_to(player.global_position)
	speed_changed.connect(hud.show_speed)
	speed_changed.connect(race_camera.apply_speed)
	speed_changed.connect(race_audio.apply_speed)
	distance_changed.connect(hud.show_distance)
	score_changed.connect(hud.show_score)
	race_finished.connect(hud.show_finish)
	_emit_speed_if_changed(player.speed_mps)
	_emit_distance_if_changed()
	_emit_score_if_changed()
	hud.show_nitro(player.nitro_tank)
	_skids = SkidMarks.new()
	_skids.name = "SkidMarks"
	add_child(_skids)
	if progress.races == 0:
		hint_s = 8.0
		hud.show_hint("A y D doblan · S frena · Shift nitro")


func _process(delta: float) -> void:
	if finished and Input.is_action_just_pressed("ui_accept"):
		request_restart()
		return
	if not finished and Input.is_action_just_pressed("ui_cancel"):
		set_paused(not paused)
		return
	if paused:
		if Input.is_action_just_pressed("ui_accept"):
			set_paused(false)
		return
	if hint_s > 0.0:
		hint_s = maxf(0.0, hint_s - delta)
		if hint_s == 0.0:
			hud.show_hint("")
	simulate(delta)


func set_paused(next: bool) -> void:
	paused = next
	hud.show_pause(paused)


func request_restart() -> void:
	if not finished or restarted:
		return
	restarted = true
	if restart_scene:
		get_tree().change_scene_to_file(RACE_SCENE)


func simulate(delta: float) -> void:
	if finished:
		return
	begin_frame(delta)
	player.max_speed_mps = max_speed_mps
	player.tick(delta)
	traffic.tick(delta, player.global_position.z)
	oil.tick(delta, player.global_position.z)
	if oil.touching(player.global_position):
		player.slip_s = OilManager.SLIP_S
	var travel_speed := player.speed_mps
	var hits := Contact.collect_new_hits(player.global_position, traffic.vehicles())
	var multiplier_before := score_keeper.multiplier
	if hits > 0:
		player.speed_mps = Contact.speed_after_hits(travel_speed, hits)
		score_keeper.register_hit()
		score_keeper.add_hit_distance(travel_speed * delta)
		race_audio.play_hit()
		player.show_impact()
		race_camera.kick()
	else:
		score_keeper.add_clean_distance(travel_speed * delta)
		if score_keeper.multiplier > multiplier_before:
			race_audio.play_rise()
	# La distancia usa la velocidad de este frame. La señal de velocidad usa
	# la velocidad ya penalizada, que es la que vale a partir de ahora.
	_add_distance(travel_speed, delta)
	_emit_speed_if_changed(player.speed_mps)
	_emit_score_if_changed()
	hud.show_nitro(player.nitro_tank)
	crashes += hits
	if crashes >= HITS_TO_END:
		finished = true
		var shown := displayed_score(score_keeper.score)
		var record := progress.note_finish(shown)
		race_finished.emit(shown)
		hud.show_hint("")
		hud.show_standing(progress.best_score, progress.money, record)
	road.tick(player.global_position.z)
	street.follow(road.origins())
	_skids.follow_drift(player.drifting, player.global_position, delta)
	race_camera.tick(delta, player.global_position)
	race_camera.apply_drive(player.speed_mps, player.boosting)


func _commit_motion(speed_mps: float, delta: float) -> void:
	_add_distance(speed_mps, delta)
	_emit_speed_if_changed(speed_mps)


func _add_distance(speed_mps: float, delta: float) -> void:
	distance_m += speed_mps * delta
	_emit_distance_if_changed()


func _emit_speed_if_changed(speed_mps: float) -> void:
	var kmh := displayed_kmh(speed_mps)
	if kmh == _shown_kmh:
		return
	_shown_kmh = kmh
	speed_changed.emit(speed_mps)


func _emit_distance_if_changed() -> void:
	var meters := int(distance_m)
	if meters == _shown_distance_m:
		return
	_shown_distance_m = meters
	distance_changed.emit(distance_m)


func _emit_score_if_changed() -> void:
	var shown := displayed_score(score_keeper.score)
	if shown == _shown_score and score_keeper.multiplier == _shown_multiplier:
		return
	_shown_score = shown
	_shown_multiplier = score_keeper.multiplier
	score_changed.emit(shown, score_keeper.multiplier)


func _apply_tune(state: Progress) -> void:
	initial_max_mps = INITIAL_MAX_SPEED_MPS + float(state.tope) * 3.0
	speed_cap_mps = SPEED_CAP_MPS + float(state.tope) * 3.0
	max_speed_mps = initial_max_mps
	player.accel_mps2 = PlayerController.ACCEL_MPS2 + float(state.motor) * 1.5
	player.nitro_boost_mps = PlayerController.NITRO_BOOST_MPS + float(state.nitro) * 2.0
	player.nitro_drain = PlayerController.NITRO_DRAIN * pow(0.82, float(state.nitro))


func _apply_world(state: Progress) -> void:
	var place := Course.theme(state.races)
	var state_weather := Course.weather(state.races)
	road.apply_palette(place["asphalt"], place["paint"])
	street.apply_place(str(place["id"]))
	rain.set_active(str(state_weather["id"]) == "lluvia")
	player.weather_grip = float(state_weather["grip"])
	var sky := Course.sky_color(state.races, state.races)
	var environment := world.environment.duplicate()
	environment.background_color = sky
	if OS.has_feature("web"):
		environment.glow_enabled = false
	environment.fog_enabled = float(state_weather["fog"]) > 0.0
	environment.fog_density = float(state_weather["fog"])
	environment.fog_light_color = sky
	world.environment = environment
	hud.show_course("%s · %s" % [place["name"], state_weather["name"]])
