class_name OilManager
extends Node3D

const POOL_SIZE := 6
const SPAWN_INTERVAL := 3.2
const SPAWN_AHEAD := 110.0
const DESPAWN_BEHIND := 30.0
const DESPAWN_AHEAD := 300.0
const SLIP_S := 0.85

var _pool: Array[OilSlick] = []
var _spawn_timer: float = 0.0


func _ready() -> void:
	for _i in POOL_SIZE:
		var slick := OilSlick.new()
		add_child(slick)
		_pool.append(slick)


func tick(delta: float, player_z: float) -> void:
	for slick in _pool:
		if not slick.active:
			continue
		var ahead := slick.along() - player_z
		if ahead < -DESPAWN_BEHIND or ahead > DESPAWN_AHEAD:
			slick.deactivate()
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer -= SPAWN_INTERVAL
		_try_spawn(player_z)


func touching(point: Vector3) -> bool:
	var body := Contact.half_extents(1.0)
	for slick in _pool:
		if slick.overlaps(point, body):
			return true
	return false


func _try_spawn(player_z: float) -> void:
	var slick := _inactive()
	if slick == null:
		return
	var spawn_z := player_z + SPAWN_AHEAD
	var occupants: Array = []
	for other in _pool:
		if other.active:
			var lane := _lane_of(other.lateral())
			occupants.append({"lane": lane, "z": other.along()})
	var lane := TrafficManager.choose_lane(spawn_z, occupants)
	if lane == -1:
		return
	slick.activate(Vector3(TrafficManager.lane_center(lane), 0.08, spawn_z))


func _inactive() -> OilSlick:
	for slick in _pool:
		if not slick.active:
			return slick
	return null


func _lane_of(x: float) -> int:
	var best := 0
	var best_distance := INF
	for lane in range(TrafficManager.LANE_CENTERS.size()):
		var distance := absf(TrafficManager.lane_center(lane) - x)
		if distance < best_distance:
			best_distance = distance
			best = lane
	return best
