class_name HazardField
extends Node3D

const POOL := 5
const AHEAD := 170.0
const SPACING := 520.0
const FIRST := 280.0

var _pool: Array[Node3D] = []
var _active: Array[bool] = []
var _along: Array[float] = []
var _lateral: Array[float] = []
var _touching: Array[bool] = []
var _next := FIRST


func _ready() -> void:
	for _i in POOL:
		var block := _barrier()
		add_child(block)
		_pool.append(block)
		_active.append(false)
		_along.append(0.0)
		_lateral.append(0.0)
		_touching.append(false)


func tick(delta: float, player_z: float, run_m: float) -> void:
	for index in _pool.size():
		if not _active[index]:
			continue
		if _along[index] < player_z - 24.0 or _along[index] > player_z + 340.0:
			_active[index] = false
			_touching[index] = false
			_pool[index].visible = false
	if run_m + AHEAD < _next:
		return
	var slot := -1
	for index in _active.size():
		if not _active[index]:
			slot = index
			break
	if slot < 0:
		return
	var lane := 1 if int(_next / SPACING) % 2 == 0 else 0
	_active[slot] = true
	_touching[slot] = false
	_along[slot] = player_z + AHEAD
	_lateral[slot] = TrafficManager.lane_center(lane)
	var block := _pool[slot]
	block.visible = true
	block.position.y = 0.45
	CoursePath.present(block, _along[slot], _lateral[slot])
	_next += SPACING


func collect(player_position: Vector3, player_from: Vector3) -> int:
	var hits := 0
	var body := Contact.half_extents(1.0)
	var end := Vector2(player_position.x, player_position.z)
	var start := Vector2(player_from.x, player_from.z)
	for index in _pool.size():
		if not _active[index]:
			continue
		var center := Vector2(_lateral[index], _along[index])
		var overlapping := Contact.segment_overlaps(start, end, body, center, Vector2(0.85, 1.15))
		if overlapping and not _touching[index]:
			hits += 1
		_touching[index] = overlapping
	return hits


func _barrier() -> Node3D:
	var root := Node3D.new()
	root.visible = false
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 0.85, 0.7)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.42, 0.08)
	material.roughness = 0.55
	material.metallic = 0.08
	material.emission_enabled = true
	material.emission = Color(0.85, 0.28, 0.04)
	material.emission_energy_multiplier = 0.45
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(1.52, 0.16, 0.72)
	stripe.mesh = stripe_mesh
	stripe.position.y = 0.12
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.95, 0.92, 0.82)
	paint.emission_enabled = true
	paint.emission = Color(0.95, 0.9, 0.7)
	paint.emission_energy_multiplier = 0.4
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stripe.material_override = paint
	root.add_child(stripe)
	return root
