class_name FuelDepot
extends Node3D

const POOL := 4
const AHEAD := 150.0
const SPACING := 420.0
const FIRST := 360.0

var _pool: Array[Node3D] = []
var _active: Array[bool] = []
var _along: Array[float] = []
var _lateral: Array[float] = []
var _next := FIRST


func _ready() -> void:
	for _i in POOL:
		var can := _canister()
		add_child(can)
		_pool.append(can)
		_active.append(false)
		_along.append(0.0)
		_lateral.append(0.0)


func reset_run() -> void:
	_next = FIRST
	for index in _pool.size():
		_deactivate(index)


func tick(delta: float, player_z: float, run_m: float) -> void:
	for index in _pool.size():
		if not _active[index]:
			continue
		if _along[index] < player_z - 30.0 or _along[index] > player_z + 320.0:
			_deactivate(index)
	if run_m + AHEAD < _next:
		return
	var slot := _free_slot()
	if slot < 0:
		return
	var lane := int(_next / SPACING) % 3
	_activate(slot, player_z + AHEAD, TrafficManager.lane_center(lane))
	_next += SPACING


func collect(player_position: Vector3, player_from: Vector3) -> int:
	var found := 0
	var body := Contact.half_extents(1.0)
	var end := Vector2(player_position.x, player_position.z)
	var start := Vector2(player_from.x, player_from.z)
	for index in _pool.size():
		if not _active[index]:
			continue
		var center := Vector2(_lateral[index], _along[index])
		if Contact.segment_overlaps(start, end, body, center, Vector2(1.1, 1.4)):
			_deactivate(index)
			found += 1
	return found


func force_at(index: int, at: Vector3) -> void:
	if index < 0 or index >= _pool.size():
		return
	_activate(index, at.z, at.x)


func _activate(index: int, along: float, lateral: float) -> void:
	_active[index] = true
	_along[index] = along
	_lateral[index] = lateral
	var can := _pool[index]
	can.visible = true
	can.position.y = 0.55
	CoursePath.present(can, along, lateral)


func _deactivate(index: int) -> void:
	_active[index] = false
	_pool[index].visible = false


func _free_slot() -> int:
	for index in _active.size():
		if not _active[index]:
			return index
	return -1


func _canister() -> Node3D:
	var root := Node3D.new()
	root.visible = false
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.34
	mesh.bottom_radius = 0.4
	mesh.height = 0.85
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.62, 0.12)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.55, 0.08)
	material.emission_energy_multiplier = 2.4
	material.roughness = 0.35
	material.metallic = 0.45
	body.material_override = material
	root.add_child(body)
	var band := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 0.42
	ring.bottom_radius = 0.42
	ring.height = 0.16
	band.mesh = ring
	band.position.y = 0.12
	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = Color(0.55, 0.95, 1.0)
	band_material.emission_enabled = true
	band_material.emission = Color(0.45, 0.9, 1.0)
	band_material.emission_energy_multiplier = 3.0
	band_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	band.material_override = band_material
	root.add_child(band)
	return root
