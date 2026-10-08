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
const DEFAULT_PROFILE: AiProfile = preload("res://traffic/profiles/normal.tres")

var profile: AiProfile
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
	for _i in POOL_SIZE:
		var vehicle: TrafficVehicle = VEHICLE_SCENE.instantiate()
		vehicle.profile = profile
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


func tick(delta: float, player_z: float) -> void:
	for vehicle in _pool:
		if not vehicle.active:
			continue
		vehicle.tick(delta)
		var ahead := vehicle.global_position.z - player_z
		if ahead < -DESPAWN_BEHIND or ahead > DESPAWN_AHEAD:
			vehicle.deactivate()
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer -= SPAWN_INTERVAL
		_try_spawn(player_z)


func _try_spawn(player_z: float) -> void:
	var vehicle := _inactive_vehicle()
	if vehicle == null:
		return
	var spawn_z := player_z + SPAWN_AHEAD
	var occupants: Array = []
	for other in _pool:
		if other.active:
			occupants.append({"lane": other.lane, "z": other.global_position.z})
	var lane := choose_lane(spawn_z, occupants)
	if lane == -1:
		return
	var style := _style_index
	_style_index += 1
	vehicle.activate(
		lane,
		Vector3(lane_center(lane), 0.0, spawn_z),
		_materials[style % COLORS.size()],
		SCALES[style % SCALES.size()]
	)


func _inactive_vehicle() -> TrafficVehicle:
	for vehicle in _pool:
		if not vehicle.active:
			return vehicle
	return null
