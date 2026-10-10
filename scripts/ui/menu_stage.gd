class_name MenuStage
extends SubViewportContainer

var _car: Node3D
var _spin := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.transparent_bg = false
	view.size = Vector2i(1280, 720)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.03, 0.06)
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	if DisplayServer.get_name() != "headless":
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.05, 0.08, 0.16)
		sky_mat.sky_horizon_color = Color(0.18, 0.28, 0.42)
		sky_mat.ground_horizon_color = Color(0.04, 0.04, 0.05)
		sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
		sky_mat.energy_multiplier = 0.7
		var sky := Sky.new()
		sky.sky_material = sky_mat
		environment.sky = sky
		environment.background_mode = Environment.BG_SKY
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	world.environment = environment
	view.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.6
	sun.light_color = Color(0.85, 0.92, 1.0)
	sun.rotation_degrees = Vector3(-38, 30, 0)
	sun.shadow_enabled = false
	view.add_child(sun)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.45, 0.75, 1.0)
	fill.light_energy = 2.2
	fill.omni_range = 12.0
	fill.position = Vector3(-2.2, 1.6, 3.0)
	fill.shadow_enabled = false
	view.add_child(fill)
	var ground := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(24, 0.2, 16)
	ground.mesh = slab
	ground.position = Vector3(1.6, -0.1, 0)
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.08, 0.09, 0.11)
	asphalt.roughness = 0.22
	asphalt.metallic = 0.45
	ground.material_override = asphalt
	view.add_child(ground)
	_car = preload("res://assets/vehicles/sports-car.glb").instantiate() as Node3D
	view.add_child(_car)
	_fit_car()
	var camera := Camera3D.new()
	camera.position = Vector3(-3.4, 1.55, 4.6)
	camera.fov = 38.0
	view.add_child(camera)
	camera.look_at(Vector3(0.4, 0.55, 0.0), Vector3.UP)


func _process(delta: float) -> void:
	if _car == null:
		return
	_spin += delta * 0.35
	_car.rotation.y = _spin


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
	var factor := 4.2 / box.size.z
	_car.scale = Vector3.ONE * factor
	_car.position = Vector3(0.6, -box.position.y * factor, 0.0)
