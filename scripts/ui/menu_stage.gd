class_name MenuStage
extends Node3D

var _car: Node3D
var _camera: Camera3D
var _spin := 0.0
var _sway := 0.0


func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.07, 0.12)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.adjustment_enabled = false
	environment.fog_enabled = true
	environment.fog_density = 0.012
	environment.fog_light_color = Color(0.1, 0.14, 0.22)
	environment.fog_aerial_perspective = 0.08
	if DisplayServer.get_name() != "headless":
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.07, 0.11, 0.22)
		sky_mat.sky_horizon_color = Color(0.22, 0.32, 0.48)
		sky_mat.ground_horizon_color = Color(0.16, 0.2, 0.3)
		sky_mat.ground_bottom_color = Color(0.08, 0.1, 0.14)
		sky_mat.sky_curve = 0.22
		sky_mat.energy_multiplier = 0.85
		var sky := Sky.new()
		sky.sky_material = sky_mat
		environment.sky = sky
		environment.background_mode = Environment.BG_SKY
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	_garage()
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.light_color = Color(0.78, 0.86, 1.0)
	sun.rotation_degrees = Vector3(-28, -36, 0)
	sun.shadow_enabled = false
	add_child(sun)
	var key := OmniLight3D.new()
	key.light_color = Color(0.7, 0.86, 1.0)
	key.light_energy = 1.6
	key.omni_range = 9.0
	key.position = Vector3(1.2, 2.4, 3.2)
	key.shadow_enabled = false
	add_child(key)
	var rim := OmniLight3D.new()
	rim.light_color = Color(1.0, 0.45, 0.62)
	rim.light_energy = 1.1
	rim.omni_range = 7.0
	rim.position = Vector3(4.6, 1.4, -1.6)
	rim.shadow_enabled = false
	add_child(rim)
	_car = preload("res://assets/vehicles/sports-car.glb").instantiate() as Node3D
	add_child(_car)
	_fit_car()
	_camera = Camera3D.new()
	_camera.fov = 32.0
	_camera.current = true
	add_child(_camera)
	_frame_camera(0.0)


func _process(delta: float) -> void:
	if _car == null:
		return
	_spin += delta * 0.22
	_sway += delta * 0.45
	_car.rotation.y = _spin
	_frame_camera(_sway)


func _frame_camera(sway: float) -> void:
	if _camera == null:
		return
	_camera.position = Vector3(-1.55 + sin(sway) * 0.12, 1.15, 6.4)
	_camera.look_at(Vector3(2.15, 0.62, 0.1), Vector3.UP)


func _garage() -> void:
	_slab(Vector3(2.2, -0.04, 0.4), Vector3(28.0, 0.08, 18.0), Color(0.07, 0.08, 0.1))
	_slab(Vector3(2.4, 2.4, -6.2), Vector3(22.0, 5.2, 0.4), Color(0.09, 0.11, 0.16))
	_slab(Vector3(8.6, 2.2, 0.2), Vector3(0.4, 4.8, 14.0), Color(0.08, 0.1, 0.14))
	var strip := _slab(Vector3(2.2, 0.02, 0.4), Vector3(2.4, 0.02, 7.5), Color(0.2, 0.55, 0.7))
	var paint := strip.material_override as StandardMaterial3D
	paint.emission_enabled = true
	paint.emission = Color(0.25, 0.7, 0.9)
	paint.emission_energy_multiplier = 0.45


func _slab(at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	material.metallic = 0.08
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance


func _fit_car() -> void:
	var box := AABB()
	var first := true
	for node in _car.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var piece := mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	if first or box.size.length() < 0.01:
		return
	var factor := 3.6 / box.size.z
	_car.scale = Vector3.ONE * factor
	_car.position = Vector3(2.35, -box.position.y * factor, 0.2)
