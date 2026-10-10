class_name SkyDressing
extends Node3D

const SUN_DISTANCE := 320.0
const CLOUD_LIMIT := 220.0

var _sun: MeshInstance3D
var _moon: MeshInstance3D
var _stars: MultiMeshInstance3D
var _clouds: Array[MeshInstance3D] = []
var _night := false


func _ready() -> void:
	_sun = _orb(18.0, Color(1.0, 0.78, 0.22), 1.1)
	_moon = _orb(8.0, Color(0.82, 0.86, 0.95), 0.7)
	_stars = _star_field()
	add_child(_stars)
	var puff_count := 4 if OS.has_feature("web") else 6
	for index in puff_count:
		var cloud := MeshInstance3D.new()
		var puff := SphereMesh.new()
		var radius := 14.0 + float(index % 3) * 4.0
		puff.radius = radius
		puff.height = radius * 1.35
		puff.radial_segments = 10
		puff.rings = 6
		cloud.mesh = puff
		cloud.material_override = _cloud_material()
		cloud.position = Vector3(-140.0 + float(index) * 58.0, 42.0 + float(index % 2) * 8.0, 160.0 + float(index % 3) * 24.0)
		cloud.scale = Vector3(1.8, 0.55, 1.0)
		add_child(cloud)
		_clouds.append(cloud)
	set_night(false)


func set_night(night: bool) -> void:
	_night = night
	_sun.visible = not night
	_moon.visible = night
	_stars.visible = night
	for cloud in _clouds:
		cloud.visible = not night


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		global_position = camera.global_position
		global_rotation = Vector3.ZERO
	var sun_light := get_parent().get_node_or_null("Sun") as DirectionalLight3D
	var direction := Vector3(0.25, 0.86, 0.43).normalized()
	if sun_light != null:
		direction = sun_light.global_transform.basis.z.normalized()
	_sun.position = direction * SUN_DISTANCE
	_moon.position = direction * SUN_DISTANCE
	if _night:
		return
	for index in _clouds.size():
		var cloud := _clouds[index]
		cloud.position.x += (7.0 + float(index % 3) * 3.0) * delta
		if cloud.position.x > CLOUD_LIMIT:
			cloud.position.x = -CLOUD_LIMIT


func _orb(radius: float, color: Color, energy: float) -> MeshInstance3D:
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	orb.mesh = sphere
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.disable_receive_shadows = true
	orb.mesh.surface_set_material(0, material)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(orb)
	return orb


func _star_field() -> MultiMeshInstance3D:
	var field := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	sphere.radial_segments = 6
	sphere.rings = 4
	multi.mesh = sphere
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = 36 if OS.has_feature("web") else 70
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for index in multi.instance_count:
		var yaw := rng.randf_range(-1.05, 1.05)
		var pitch := rng.randf_range(0.03, 0.34)
		var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
		multi.set_instance_transform(index, Transform3D(Basis.IDENTITY, dir * 300.0))
	field.multimesh = multi
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.95, 0.96, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.95, 0.96, 1.0)
	material.emission_energy_multiplier = 0.8
	field.material_override = material
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return field


func _cloud_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.75, 0.8, 0.88, 0.22)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	return material
