class_name RaceDirector
extends Node3D

signal speed_changed(speed_mps: float)
signal distance_changed(distance_m: float)
signal score_changed(score: int, multiplier: int)

const INITIAL_MAX_SPEED_MPS := 30.0
const SPEED_CAP_MPS := 70.0
const MAX_SPEED_RAMP := 0.15

var max_speed_mps: float = INITIAL_MAX_SPEED_MPS
var distance_m: float = 0.0
var elapsed_s: float = 0.0
var score_keeper := ScoreKeeper.new()

var _shown_kmh: int = -1
var _shown_distance_m: int = -1
var _shown_score: int = -1
var _shown_multiplier: int = 0

@onready var player: PlayerController = $PlayerVehicle
@onready var road: RoadStreamer = $RoadStreamer
@onready var traffic: TrafficManager = $TrafficManager
@onready var race_camera: RaceCamera = $RaceCamera
@onready var hud: SpeedHud = $SpeedHud

static func planned_max_speed(time_s: float) -> float:
	return minf(SPEED_CAP_MPS, INITIAL_MAX_SPEED_MPS + MAX_SPEED_RAMP * time_s)


static func displayed_kmh(speed_mps: float) -> int:
	return int(round(speed_mps * 3.6))


static func displayed_score(score: float) -> int:
	return int(score)


func begin_frame(delta: float) -> void:
	elapsed_s += delta
	max_speed_mps = planned_max_speed(elapsed_s)


# Atajo de tiempo y distancia. No resuelve choques ni puntos.
func advance_race(delta: float, speed_mps: float) -> void:
	begin_frame(delta)
	_commit_motion(speed_mps, delta)


func _ready() -> void:
	player.max_speed_mps = max_speed_mps
	road.setup(player.global_position.z)
	race_camera.snap_to(player.global_position)
	speed_changed.connect(hud.show_speed)
	speed_changed.connect(race_camera.apply_speed)
	distance_changed.connect(hud.show_distance)
	score_changed.connect(hud.show_score)
	_emit_speed_if_changed(player.speed_mps)
	_emit_distance_if_changed()
	_emit_score_if_changed()


func _process(delta: float) -> void:
	simulate(delta)


func simulate(delta: float) -> void:
	begin_frame(delta)
	player.max_speed_mps = max_speed_mps
	player.tick(delta)
	traffic.tick(delta, player.global_position.z)
	var travel_speed := player.speed_mps
	var hits := Contact.collect_new_hits(player.global_position, traffic.vehicles())
	if hits > 0:
		player.speed_mps = Contact.speed_after_hits(travel_speed, hits)
		score_keeper.register_hit()
		score_keeper.add_hit_distance(travel_speed * delta)
	else:
		score_keeper.add_clean_distance(travel_speed * delta)
	# La distancia usa la velocidad de este frame. La señal de velocidad usa
	# la velocidad ya penalizada, que es la que vale a partir de ahora.
	_add_distance(travel_speed, delta)
	_emit_speed_if_changed(player.speed_mps)
	_emit_score_if_changed()
	road.tick(player.global_position.z)
	race_camera.tick(delta, player.global_position)


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
