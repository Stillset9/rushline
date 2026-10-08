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
	direction = Vector3(0.2, -1.0, 0.15)
	spread = 6.0
	gravity = Vector3(0.0, -18.0, 0.0)
	initial_velocity_min = 22.0
	initial_velocity_max = 30.0
	var drop := BoxMesh.new()
	drop.size = Vector3(0.025, 0.85, 0.025)
	mesh = drop
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.78, 0.86, 0.94, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = material
	set_active(false)


func set_active(enabled: bool) -> void:
	visible = enabled
	emitting = enabled
