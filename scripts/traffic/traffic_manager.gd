class_name TrafficManager
extends Node3D

const POOL_SIZE := 12
const SPAWN_INTERVAL := 1.2
const SPAWN_AHEAD := 90.0
const DESPAWN_BEHIND := 30.0
const DESPAWN_AHEAD := 300.0
const MIN_GAP := 18.0
const LANE_CENTERS: Array[float] = [-4.0, 0.0, 4.0]
const COLORS: Array[Color] = [
	Color("c4513a"),
	Color("3d6b8c"),
	Color("d4a017"),
	Color("4e7d4f"),
]
const SCALES: Array[float] = [0.95, 1.0, 1.05, 0.97]

const VEHICLE_SCENE := preload("res://scenes/vehicles/traffic_vehicle.tscn")
const MODELS: Array[PackedScene] = [
	preload("res://assets/vehicles/sedan.glb"),
	preload("res://assets/vehicles/hatchback.glb"),
	preload("res://assets/vehicles/taxi.glb"),
	preload("res://assets/vehicles/race-car.glb"),
]
const DEFAULT_PROFILE: AiProfile = preload("res://traffic/profiles/normal.tres")
const PROFILES: Array[AiProfile] = [
	preload("res://traffic/profiles/normal.tres"),
	preload("res://traffic/profiles/rapido.tres"),
	preload("res://traffic/profiles/pesado.tres"),
	preload("res://traffic/profiles/agresivo.tres"),
]
const HEAVY_SCALE := 1.28

var profile: AiProfile
var spawn_every := SPAWN_INTERVAL
var road_half := 6.0
var _pool: Array[TrafficVehicle] = []
var _materials: Array[StandardMaterial3D] = []
var _spawn_timer: float = 0.0
var _style_index: int = 0


func _ready() -> void:
	if profile == null:
		profile = DEFAULT_PROFILE
	for color in COLORS:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		_materials.append(material)
	for index in POOL_SIZE:
		var vehicle: TrafficVehicle = VEHICLE_SCENE.instantiate()
		vehicle.profile = profile
		vehicle.visual_model = MODELS[index % MODELS.size()]
		add_child(vehicle)
		_pool.append(vehicle)


static func lane_center(lane: int) -> float:
	return LANE_CENTERS[lane]


static func choose_lane(spawn_z: float, occupants: Array) -> int:
	var best_lane := -1
	var best_distance := -1.0
	for lane in range(3):
		if not _lane_is_free(spawn_z, lane, occupants):
			continue
		var distance := _nearest_distance(spawn_z, lane, occupants)
		# Mayor estricto: un empate se queda con el índice más bajo.
		if distance > best_distance:
			best_distance = distance
			best_lane = lane
	return best_lane


static func choose_lane_change(lane: int, z: float, occupants: Array) -> int:
	var best_lane := -1
	var best_distance := -1.0
	var offsets: Array[int] = [-1, 1]
	for offset in offsets:
		var candidate := lane + offset
		if candidate < 0 or candidate > 2:
			continue
		var nearest := _nearest_distance(z, candidate, occupants)
		if nearest < MIN_GAP:
			continue
		if nearest > best_distance:
			best_distance = nearest
			best_lane = candidate
	return best_lane


static func _lane_is_free(spawn_z: float, lane: int, occupants: Array) -> bool:
	for occupant in occupants:
		if int(occupant["lane"]) == lane and absf(float(occupant["z"]) - spawn_z) < MIN_GAP:
			return false
	return true


static func _nearest_distance(spawn_z: float, lane: int, occupants: Array) -> float:
	var best := INF
	for occupant in occupants:
		if int(occupant["lane"]) == lane:
			best = minf(best, absf(float(occupant["z"]) - spawn_z))
	return best


func vehicles() -> Array[TrafficVehicle]:
	return _pool


static func cruise_speed(base: float, player_speed: float, aggression: float, heavy: bool) -> float:
	if player_speed <= 1.0:
		return base
	var follow := 0.4 if heavy else (0.64 + clampf(aggression, 0.0, 1.0) * 0.26)
	return maxf(base, player_speed * follow)


static func lane_toward(lane: int, player_x: float) -> int:
	var target := 1
	if player_x < -2.0:
		target = 0
	elif player_x > 2.0:
		target = 2
	if target == lane:
		return lane
	return lane + (1 if target > lane else -1)


func tick(delta: float, player_z: float, player_x: float = 0.0, player_speed: float = 0.0) -> void:
	for vehicle in _pool:
		if not vehicle.active:
			continue
		var heavy := vehicle.profile != null and vehicle.profile.id == "pesado"
		var aggression := 0.0 if vehicle.profile == null else vehicle.profile.aggression
		var base := 0.0 if vehicle.profile == null else vehicle.profile.speed_mps
		vehicle.cruise_mps = cruise_speed(base, player_speed, aggression, heavy)
		vehicle.road_half = road_half
		vehicle.hunt = player_speed > 1.0 and aggression >= 0.5
		vehicle.hunt_x = player_x
		vehicle.tick(delta)
		if vehicle.profile != null and vehicle.profile.lane_change_interval > 0.0 and not vehicle.hunt:
			vehicle.lane_timer += delta
			if vehicle.lane_timer >= vehicle.profile.lane_change_interval:
				vehicle.lane_timer = 0.0
				var next := choose_lane_change(vehicle.lane, vehicle.track_z(), _occupants(vehicle))
				if next != -1:
					vehicle.lane = next
					vehicle.lane_x = _fit_lane(lane_center(next))
		elif vehicle.hunt and vehicle.profile != null:
			vehicle.lane_timer += delta
			var gap := maxf(0.7, vehicle.profile.lane_change_interval * 0.55)
			if vehicle.lane_timer >= gap:
				vehicle.lane_timer = 0.0
				vehicle.lane = lane_toward(vehicle.lane, player_x)
				vehicle.lane_x = _fit_lane(lane_center(vehicle.lane))
		var ahead := vehicle.track_z() - player_z
		if ahead < -DESPAWN_BEHIND or ahead > DESPAWN_AHEAD:
			vehicle.deactivate()
	_spawn_timer += delta
	if _spawn_timer >= spawn_every:
		_spawn_timer -= spawn_every
		_try_spawn(player_z)


func _try_spawn(player_z: float) -> void:
	var vehicle := _inactive_vehicle()
	if vehicle == null:
		return
	var spawn_z := player_z + SPAWN_AHEAD
	var occupants: Array = []
	for other in _pool:
		if other.active:
			occupants.append({"lane": other.lane, "z": other.track_z()})
	var lane := choose_lane(spawn_z, occupants)
	if lane == -1:
		return
	var style := _style_index
	_style_index += 1
	var chosen := PROFILES[style % PROFILES.size()]
	var body_scale := SCALES[style % SCALES.size()]
	if chosen.id == "pesado":
		body_scale = HEAVY_SCALE
	vehicle.profile = chosen
	vehicle.activate(
		lane,
		Vector3(_fit_lane(lane_center(lane)), 0.0, spawn_z),
		_materials[style % COLORS.size()],
		body_scale
	)


func _inactive_vehicle() -> TrafficVehicle:
	for vehicle in _pool:
		if not vehicle.active:
			return vehicle
	return null


func _fit_lane(center: float) -> float:
	var margin := 1.15
	return clampf(center, -road_half + margin, road_half - margin)


func _occupants(except: TrafficVehicle) -> Array:
	var occupants: Array = []
	for other in _pool:
		if other.active and other != except:
			occupants.append({"lane": other.lane, "z": other.track_z()})
	return occupants
