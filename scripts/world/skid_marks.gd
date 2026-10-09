class_name SkidMarks
extends Node3D

const POOL := 10
const LIFE_S := 0.38
const STAMP_GAP_S := 0.08

var _marks: Array[MeshInstance3D] = []
var _life: Array[float] = []
var _cursor := 0
var _wait := 0.0


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.02, 1.35)
	for _index in POOL:
		var mark := MeshInstance3D.new()
		mark.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.12, 0.13, 0.0)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.material_override = material
		mark.visible = false
		add_child(mark)
		_marks.append(mark)
		_life.append(0.0)


func follow_drift(drifting: bool, along: float, lateral: float, delta: float) -> void:
	for index in _marks.size():
		if _life[index] <= 0.0:
			continue
		_life[index] = maxf(0.0, _life[index] - delta)
		var material := _marks[index].material_override as StandardMaterial3D
		var color := material.albedo_color
		color.a = 0.62 * (_life[index] / LIFE_S)
		material.albedo_color = color
		_marks[index].visible = _life[index] > 0.0
	if not drifting:
		_wait = 0.0
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = STAMP_GAP_S
	var mark := _marks[_cursor]
	var framed := CoursePath.pose(along - 1.1, lateral)
	var point: Vector3 = framed.position
	mark.position = Vector3(point.x, 0.08, point.z)
	mark.rotation.y = float(framed.yaw)
	mark.visible = true
	var paint := mark.material_override as StandardMaterial3D
	paint.albedo_color = Color(0.12, 0.12, 0.13, 0.62)
	_life[_cursor] = LIFE_S
	_cursor = (_cursor + 1) % _marks.size()
