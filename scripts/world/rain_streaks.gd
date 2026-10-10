class_name RainStreaks
extends CPUParticles3D


func _ready() -> void:
	amount = 80
	lifetime = 0.4
	preprocess = 0.35
	randomness = 0.35
	local_coords = true
	emission_shape = EMISSION_SHAPE_BOX
	emission_box_extents = Vector3(9.0, 0.4, 16.0)
	direction = Vector3(0.08, -0.75, -0.55)
	spread = 8.0
	gravity = Vector3(0.0, -22.0, -8.0)
	initial_velocity_min = 26.0
	initial_velocity_max = 36.0
	lifetime = 0.28
	initial_velocity_min = 16.0
	initial_velocity_max = 22.0
	var drop := BoxMesh.new()
	drop.size = Vector3(0.008, 0.36, 0.008)
	mesh = drop
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.82, 0.92, 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = material
	_splashes = CPUParticles3D.new()
	_splashes.name = "Splashes"
	_splashes.amount = 16
	_splashes.lifetime = 0.32
	_splashes.local_coords = true
	_splashes.position = Vector3(0.0, -6.6, 2.4)
	_splashes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_splashes.emission_box_extents = Vector3(7.0, 0.05, 8.0)
	_splashes.direction = Vector3(0.0, 1.0, 0.0)
	_splashes.spread = 28.0
	_splashes.gravity = Vector3(0.0, -8.0, 0.0)
	_splashes.initial_velocity_min = 0.8
	_splashes.initial_velocity_max = 1.8
	var disc := QuadMesh.new()
	disc.size = Vector2(0.16, 0.16)
	_splashes.mesh = disc
	var splash_mat := StandardMaterial3D.new()
	splash_mat.albedo_color = Color(0.8, 0.88, 0.95, 0.28)
	splash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	splash_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_splashes.material_override = splash_mat
	add_child(_splashes)
	set_active(false)


var _splashes: CPUParticles3D


func set_active(enabled: bool) -> void:
	visible = enabled
	emitting = enabled
	if _splashes != null:
		_splashes.visible = enabled
		_splashes.emitting = enabled


func set_density(next_amount: int) -> void:
	amount = maxi(12, next_amount)
	if _splashes != null:
		_splashes.amount = maxi(8, int(amount * 0.28))
