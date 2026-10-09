class_name OilSlick
extends Node3D

const HALF_X := 1.6
const HALF_Z := 3.5

var active: bool = false
var road_x: float = 0.0
var road_z: float = 0.0
var _road_live: bool = false


func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(HALF_X * 2.0, 0.04, HALF_Z * 2.0)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.05, 0.12, 0.1, 0.82)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.16, 0.12)
	material.emission_energy_multiplier = 0.35
	mesh_instance.material_override = material
	add_child(mesh_instance)
	visible = false


func activate(at: Vector3) -> void:
	active = true
	visible = true
	road_x = at.x
	road_z = at.z
	_road_live = true
	position.y = at.y
	CoursePath.present(self, road_z, road_x)


func deactivate() -> void:
	active = false
	visible = false
	_road_live = false


func along() -> float:
	return road_z if _road_live else global_position.z


func lateral() -> float:
	return road_x if _road_live else global_position.x


func overlaps(point: Vector3, body_half: Vector2) -> bool:
	if not active:
		return false
	var center_x := road_x if _road_live else global_position.x
	var center_z := road_z if _road_live else global_position.z
	var separated_x := absf(point.x - center_x) >= HALF_X + body_half.x
	var separated_z := absf(point.z - center_z) >= HALF_Z + body_half.y
	return not separated_x and not separated_z
