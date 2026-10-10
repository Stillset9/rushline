class_name RaceDirector
extends Node3D

signal speed_changed(speed_mps: float)
signal distance_changed(distance_m: float)
signal score_changed(score: int, multiplier: int)
signal race_finished(score: int, reason: String)

const INITIAL_MAX_SPEED_MPS := 30.0
const SPEED_CAP_MPS := 70.0
const MAX_SPEED_RAMP := 0.15
const MAX_FRAME_S := 0.05
const WALL_COOLDOWN := 0.85
const RACE_SCENE := "res://scenes/race/race.tscn"
const TITLE_SCENE := "res://scenes/menu/title.tscn"

var max_speed_mps: float = INITIAL_MAX_SPEED_MPS
var initial_max_mps: float = INITIAL_MAX_SPEED_MPS
var speed_cap_mps: float = SPEED_CAP_MPS
var distance_m: float = 0.0
var stage_index: int = 0
var stage_distance: float = 0.0
var elapsed_s: float = 0.0
var crashes: int = 0
var finished: bool = false
var finish_reason: String = ""
var paused: bool = false
var pause_row: int = 0
var returned_home: bool = false
var hint_s: float = 0.0
var wall_cool: float = 0.0
var hit_slow: float = 0.0
var _was_boosting := false
var restart_scene: bool = true
var restarted: bool = false
var score_keeper := ScoreKeeper.new()
var progress := Progress.new()
var fuel := FuelTank.new()

var _shown_kmh: int = -1
var _shown_distance_m: int = -1
var _shown_score: int = -1
var _shown_multiplier: int = 0
var _prev_player := Vector3.ZERO
var _has_prev := false

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
@onready var sun: DirectionalLight3D = $Sun
@onready var fill: DirectionalLight3D = $Fill

var _skids: SkidMarks
var _sky: SkyDressing
var _depot: FuelDepot
var _hazards: HazardField

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
	road.setup(player.track_z())
	street.follow(road.origins())
	_sky = SkyDressing.new()
	_sky.name = "SkyDressing"
	add_child(_sky)
	_depot = FuelDepot.new()
	_depot.name = "FuelDepot"
	add_child(_depot)
	_hazards = HazardField.new()
	_hazards.name = "HazardField"
	add_child(_hazards)
	_apply_world()
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
	_refresh_hud()
	_skids = SkidMarks.new()
	_skids.name = "SkidMarks"
	add_child(_skids)
	var opening: Dictionary = Course.theme(int(StageRun.stage(0)["theme"]))
	hud.show_banner("Etapa 1 · %s" % str(opening["name"]))
	hud.present_controls(4.0)
	_apply_web_shot()


func _process(delta: float) -> void:
	if finished and Input.is_action_just_pressed("ui_accept"):
		request_restart()
		return
	if not finished and Input.is_action_just_pressed("ui_cancel"):
		set_paused(not paused)
		return
	if paused:
		_pause_keys()
		return
	if hint_s > 0.0:
		hint_s = maxf(0.0, hint_s - delta)
		if hint_s == 0.0:
			hud.show_hint("")
	var step := minf(maxf(delta, 0.0), MAX_FRAME_S)
	if hit_slow > 0.0:
		hit_slow = maxf(0.0, hit_slow - delta)
		step *= 0.28
	if step > 0.0:
		simulate(step)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if finished:
			request_restart()
			get_viewport().set_input_as_handled()
			return
		if paused:
			var height := get_viewport().get_visible_rect().size.y
			pause_row = 0 if event.position.y < height * 0.52 else 1
			hud.show_pause(true, pause_row)
			confirm_pause()
			get_viewport().set_input_as_handled()


func _pause_keys() -> void:
	if Input.is_action_just_pressed("ui_up"):
		pause_row = 0
		hud.show_pause(true, pause_row)
	elif Input.is_action_just_pressed("ui_down"):
		pause_row = 1
		hud.show_pause(true, pause_row)
	elif Input.is_action_just_pressed("ui_accept"):
		confirm_pause()


func set_paused(next: bool) -> void:
	paused = next
	if next:
		pause_row = 0
	hud.show_pause(paused, pause_row)


func confirm_pause() -> void:
	if pause_row == 0:
		set_paused(false)
	else:
		return_to_title()


func return_to_title() -> void:
	returned_home = true
	if restart_scene:
		SceneFade.to(TITLE_SCENE)


func close_if_done() -> void:
	if finished:
		return
	var length := float(StageRun.stage(stage_index)["length"])
	if stage_index >= StageRun.count() - 1 and stage_distance >= length:
		_end_race("meta")
	elif fuel.empty():
		_end_race("sin_combustible")


func _end_race(reason: String) -> void:
	if finished:
		return
	finished = true
	finish_reason = reason
	var shown := displayed_score(score_keeper.score)
	var cleared := stage_index + 1 if reason == "meta" else stage_index
	var record := progress.note_finish(shown, cleared)
	race_finished.emit(shown, reason)
	hud.show_hint("")
	hud.show_standing(progress.best_score, progress.money, record, distance_m, elapsed_s, crashes)


func request_restart() -> void:
	if not finished or restarted:
		return
	restarted = true
	if restart_scene:
		SceneFade.to(RACE_SCENE)


func simulate(delta: float) -> void:
	if finished:
		return
	begin_frame(delta)
	var plan := StageRun.stage(stage_index)
	var half := StageRun.playable_half(player.track_z(), float(plan["pressure"]))
	player.road_limit = half
	player.max_speed_mps = max_speed_mps
	road.pressure = float(plan["pressure"])
	traffic.spawn_every = float(plan["spawn"])
	traffic.road_half = half
	var prev := Vector3(player.track_x(), 0.0, player.track_z())
	player.tick(delta)
	var now := Vector3(player.track_x(), 0.0, player.track_z())
	if not _has_prev:
		prev = now
		_has_prev = true
	traffic.tick(delta, player.track_z(), player.track_x(), player.speed_mps)
	oil.tick(delta, player.track_z())
	_depot.tick(delta, player.track_z(), stage_distance)
	_hazards.tick(delta, player.track_z(), stage_distance)
	if oil.touching(Vector3(player.track_x(), 0.0, player.track_z())):
		player.slip_s = OilManager.SLIP_S
	var travel_speed := player.speed_mps
	var hits := Contact.collect_new_hits(now, traffic.vehicles(), prev, true)
	hits += _hazards.collect(now, prev)
	var multiplier_before := score_keeper.multiplier
	fuel.drain(travel_speed * delta, player.boosting)
	wall_cool = maxf(0.0, wall_cool - delta)
	var scraped := false
	if player.scraped and wall_cool <= 0.0:
		wall_cool = WALL_COOLDOWN
		scraped = true
		player.speed_mps = maxf(PlayerController.MIN_SPEED_MPS, player.speed_mps - 6.0)
		fuel.spend(FuelTank.WALL_COST)
		race_audio.play_hit()
		player.show_impact()
		race_camera.kick()
	if hits > 0 or scraped:
		if hits > 0:
			player.speed_mps = Contact.speed_after_hits(travel_speed, hits)
			fuel.spend(FuelTank.CRASH_COST * float(hits))
			race_audio.play_hit()
			player.show_impact()
			race_camera.kick()
			hit_slow = 0.16
			_rumble(0.55, 0.85, 0.18)
		score_keeper.register_hit()
		score_keeper.add_hit_distance(travel_speed * delta)
	else:
		score_keeper.add_clean_distance(travel_speed * delta)
		if score_keeper.multiplier > multiplier_before:
			race_audio.play_rise()
	var picked := _depot.collect(now, prev)
	if picked > 0:
		fuel.add(FuelTank.PICKUP * float(picked))
		score_keeper.add_bonus(FuelTank.BONUS * float(picked))
		race_audio.play_rise()
	_add_distance(travel_speed, delta)
	stage_distance += travel_speed * delta
	_emit_speed_if_changed(player.speed_mps)
	_emit_score_if_changed()
	crashes += hits
	if stage_distance >= float(plan["length"]):
		_checkpoint(float(plan["length"]))
	if not finished and fuel.empty():
		_end_race("sin_combustible")
	if finished:
		return
	road.tick(player.track_z())
	street.follow(road.origins())
	_skids.follow_drift(player.drifting, player.track_z(), player.track_x(), delta)
	if player.boosting and not _was_boosting:
		race_audio.play_whoosh()
		_rumble(0.15, 0.4, 0.12)
	_was_boosting = player.boosting
	race_camera.boosting = player.boosting
	race_camera.follow(delta, player.track_z(), player.track_x())
	race_camera.apply_drive(player.speed_mps, player.boosting)
	_refresh_hud()


func _checkpoint(length: float) -> void:
	var overflow := stage_distance - length
	if stage_index >= StageRun.count() - 1:
		score_keeper.add_bonus(1000.0)
		_emit_score_if_changed()
		_end_race("meta")
		return
	stage_index += 1
	stage_distance = maxf(0.0, overflow)
	fuel.add(FuelTank.CHECKPOINT)
	_depot.reset_run()
	_apply_world()
	var place: Dictionary = Course.theme(int(StageRun.stage(stage_index)["theme"]))
	hint_s = 2.4
	hud.show_banner("Etapa %d · %s" % [stage_index + 1, str(place["name"])])


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


func _refresh_hud() -> void:
	var plan := StageRun.stage(stage_index)
	hud.show_nitro(player.nitro_tank)
	hud.show_fuel(fuel.fraction())
	hud.show_gear(player.gear_high)
	hud.show_pace(player.speed_mps, player.boosting)
	hud.show_track(stage_distance, player.track_x(), float(plan["length"]))


func _aim_celestial(pitch: float) -> void:
	var toward_sky := Vector3(0.0, sin(pitch), cos(pitch)).normalized()
	sun.basis = Basis.looking_at(-toward_sky, Vector3.UP)


func _apply_tune(state: Progress) -> void:
	initial_max_mps = INITIAL_MAX_SPEED_MPS + float(state.tope) * 3.0
	speed_cap_mps = SPEED_CAP_MPS + float(state.tope) * 3.0
	max_speed_mps = initial_max_mps
	player.accel_mps2 = PlayerController.ACCEL_MPS2 + float(state.motor) * 1.5
	player.nitro_boost_mps = PlayerController.NITRO_BOOST_MPS + float(state.nitro) * 2.0
	player.nitro_drain = PlayerController.NITRO_DRAIN * pow(0.82, float(state.nitro))


func _apply_world() -> void:
	var plan := StageRun.stage(stage_index)
	var place := Course.theme(int(plan["theme"]))
	var state_weather := Course.weather(int(plan["weather"]))
	var weather_id := str(state_weather["id"])
	road.pressure = float(plan["pressure"])
	var wet := GraphicsProfile.wet_strength(weather_id)
	if bool(place.get("night", false)):
		wet = maxf(wet, 0.28 if OS.has_feature("web") else 0.48)
	road.wetness = wet
	road.apply_palette(place["asphalt"], place["paint"])
	street.apply_place(str(place["id"]))
	rain.set_density(GraphicsProfile.rain_amount())
	rain.set_active(weather_id == "lluvia")
	player.weather_grip = float(state_weather["grip"])
	traffic.spawn_every = float(plan["spawn"])
	var night := bool(place.get("night", false))
	var sky := Course.sky_color(int(plan["theme"]), int(plan["weather"]))
	if night:
		sky = (place["sky"] as Color).lerp(sky, 0.2)
	if _sky != null:
		_sky.set_night(night)
	street.set_night(night)
	if night:
		sun.light_color = Color(0.72, 0.8, 0.95)
		sun.light_energy = 0.55 if OS.has_feature("web") else 0.85
		fill.light_color = Color(0.55, 0.66, 0.9)
		fill.light_energy = 0.28 if OS.has_feature("web") else 0.4
		_aim_celestial(1.05)
	else:
		sun.light_color = Color(1.0, 0.95, 0.78)
		sun.light_energy = 2.2
		fill.light_color = Color(1.0, 0.94, 0.82)
		fill.light_energy = 0.45
		_aim_celestial(0.2)
	GraphicsProfile.tune_sun(sun)
	var environment := world.environment.duplicate()
	environment.background_color = sky
	environment.ambient_light_energy = 0.7 if night else 0.55
	GraphicsProfile.decorate(environment, night, weather_id, sky, str(place["id"]))
	if not GraphicsProfile.fancy():
		environment.glow_enabled = false
		environment.ssao_enabled = false
		environment.ssr_enabled = false
		environment.sdfgi_enabled = false
		environment.volumetric_fog_enabled = false
	world.environment = environment
	GraphicsProfile.apply_viewport(get_viewport())
	VehicleVisual.set_headlights(player, night, GraphicsProfile.headlight_spots(night))
	hud.show_course("%s · %s · Etapa %d/%d" % [place["name"], state_weather["name"], stage_index + 1, StageRun.count()])


func _apply_web_shot() -> void:
	if not OS.has_feature("web"):
		return
	var search := ""
	if ClassDB.class_exists("JavaScriptBridge"):
		var window: Variant = JavaScriptBridge.get_interface("window")
		if window != null:
			var location: Variant = window.location
			search = str(location.search)
	if "noche" in search:
		stage_index = 5
		stage_distance = 40.0
		_apply_world()
		hud.show_banner("Etapa 6 · Noche")
	if "meta" in search:
		_end_race("meta")


func _rumble(weak: float, strong: float, seconds: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.start_joy_vibration(0, weak, strong, seconds)
