class_name IntroStage
extends Node3D

const FONT_PATH := "res://assets/branding/Orbitron-Variable.ttf"
const BEAM_SHADER := preload("res://scripts/branding/intro_beam.gdshader")
const FONT_SIZE := 120
const PIXEL := 0.01

var logo_built := false
var word_face: Font

var _letters: Array[Node3D] = []
var _bases: Array[float] = []
var _holder: Node3D
var _rule: MeshInstance3D
var _camera: Camera3D
var _particles: CPUParticles3D
var _beam_root: Node3D
var _beam_mat: ShaderMaterial
var _soft_mat: ShaderMaterial
var _slash: MeshInstance3D
var _slash_mat: ShaderMaterial
var _halo_mat: ShaderMaterial


func word_font() -> Font:
	return word_face


func logo_count() -> int:
	return _letters.size()


func _ready() -> void:
	_build_world()
	_build_lights()
	_build_atmosphere()
	_build_logo()


func apply(state: Dictionary) -> void:
	var time_s := float(state["time"])
	_aim(float(state["glide"]))
	if _particles != null:
		var dust := float(state["particles"])
		_particles.visible = dust > 0.04
		_particles.color = Color(0.75, 0.88, 1.0, 0.5 * dust)
	var sweep := HJIntro.sweep_at(time_s)
	_place_beam(sweep.x, sweep.y)
	if _halo_mat != null:
		_halo_mat.set_shader_parameter("strength", float(state["formed"]) * 0.42)
	if not logo_built:
		return
	var flash := float(state["flash"])
	for index in _letters.size():
		var reveal := HJIntro.letter_reveal(time_s, index)
		var letter := _letters[index]
		letter.visible = reveal > 0.02
		var eased := reveal * reveal * (3.0 - 2.0 * reveal)
		letter.position = Vector3(_bases[index], lerpf(-0.42, 0.0, eased), lerpf(0.55, 0.0, eased))
		letter.rotation.x = lerpf(0.38, 0.0, eased)
		letter.scale = Vector3.ONE * lerpf(0.9, 1.0, eased)
		var front := letter.get_child(0) as Label3D
		if front == null:
			continue
		var gleam := flash * clampf(1.0 - absf(_bases[index]) / 4.2, 0.25, 1.0)
		front.modulate = Color(0.86, 0.9, 0.96).lerp(Color(1.0, 1.0, 1.0), clampf(gleam + eased * 0.15, 0.0, 1.0))
		front.outline_size = 0
	if _rule != null:
		var formed := float(state["formed"])
		_rule.visible = formed > 0.97
		_rule.scale = Vector3(maxf(formed, 0.001), 1.0, 1.0)
		var rule_mat := _rule.material_override as StandardMaterial3D
		if rule_mat != null:
			rule_mat.emission_energy_multiplier = 0.2 + flash * 1.6


func _aim(glide: float) -> void:
	if _camera == null:
		return
	var eased := glide * glide * (3.0 - 2.0 * glide)
	_camera.position = Vector3(lerpf(0.95, 0.28, eased), lerpf(0.92, 0.4, eased), lerpf(8.5, 6.05, eased))
	_camera.look_at(Vector3(0.0, 0.3, 0.0))


func _place_beam(u: float, alpha: float) -> void:
	if _beam_root == null:
		return
	_beam_root.position.x = lerpf(-6.2, 6.2, u)
	_beam_root.visible = alpha > 0.03
	if _beam_mat != null:
		_beam_mat.set_shader_parameter("strength", alpha * 1.15)
	if _soft_mat != null:
		_soft_mat.set_shader_parameter("strength", alpha * 0.4)
	if _slash != null:
		_slash.visible = false
	if _slash_mat != null:
		_slash_mat.set_shader_parameter("strength", alpha * 1.4)


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.12, 0.16)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_density = 0.011
	env.fog_light_color = Color(0.01, 0.02, 0.04)
	env.fog_aerial_perspective = 0.12
	if not OS.has_feature("web"):
		env.glow_enabled = true
		env.glow_intensity = 0.16
		env.glow_strength = 0.4
		env.glow_bloom = 0.03
		env.glow_hdr_threshold = 1.05
		env.glow_hdr_scale = 1.15
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.current = true
	_camera.near = 0.05
	_camera.far = 40.0
	add_child(_camera)
	var view := get_viewport()
	view.physics_object_picking = false
	view.msaa_3d = Viewport.MSAA_DISABLED if OS.has_feature("web") else Viewport.MSAA_2X


func _build_lights() -> void:
	var key := OmniLight3D.new()
	key.position = Vector3(1.1, 1.8, 4.2)
	key.light_color = Color(0.96, 0.97, 1.0)
	key.light_energy = 2.8
	key.omni_range = 18.0
	key.shadow_enabled = false
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-3.1, 1.5, 1.2)
	rim.light_color = Color(0.22, 0.48, 1.0)
	rim.light_energy = 2.0
	rim.omni_range = 16.0
	rim.shadow_enabled = false
	add_child(rim)
	var kicker := OmniLight3D.new()
	kicker.position = Vector3(3.2, 0.3, -0.8)
	kicker.light_color = Color(0.16, 0.32, 0.85)
	kicker.light_energy = 1.2
	kicker.omni_range = 14.0
	kicker.shadow_enabled = false
	add_child(kicker)


func _build_atmosphere() -> void:
	var halo := MeshInstance3D.new()
	var halo_mesh := QuadMesh.new()
	halo_mesh.size = Vector2(7.2, 2.4)
	halo.mesh = halo_mesh
	halo.position = Vector3(0.0, 0.42, -1.15)
	_halo_mat = _beam_material(0.0)
	halo.material_override = _halo_mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	_beam_root = Node3D.new()
	_beam_root.position = Vector3(0.0, 0.48, 0.85)
	add_child(_beam_root)
	_beam_mat = _beam_material(0.0)
	_soft_mat = _beam_material(0.0)
	_beam_root.rotation.z = -0.03
	_beam_root.add_child(_streak(Vector2(12.0, 0.14), _beam_mat, 0.0))
	_beam_root.add_child(_streak(Vector2(12.0, 0.7), _soft_mat, 0.0))
	_slash = _streak(Vector2(0.07, 3.6), _beam_material(0.0), 0.0)
	_slash.position = Vector3(0.0, 0.35, 1.05)
	_slash.visible = false
	_slash_mat = _slash.material_override as ShaderMaterial
	add_child(_slash)
	_particles = CPUParticles3D.new()
	_particles.amount = 40
	_particles.lifetime = 5.5
	_particles.preprocess = 2.0
	_particles.explosiveness = 0.0
	_particles.mesh = SphereMesh.new()
	(_particles.mesh as SphereMesh).radius = 0.018
	(_particles.mesh as SphereMesh).height = 0.036
	(_particles.mesh as SphereMesh).radial_segments = 6
	(_particles.mesh as SphereMesh).rings = 3
	_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_particles.emission_box_extents = Vector3(5.5, 2.2, 2.4)
	_particles.direction = Vector3(0.15, 1.0, 0.0)
	_particles.spread = 28.0
	_particles.gravity = Vector3(0.0, 0.04, 0.0)
	_particles.initial_velocity_min = 0.04
	_particles.initial_velocity_max = 0.22
	_particles.scale_amount_min = 0.35
	_particles.scale_amount_max = 1.0
	_particles.color = Color(0.75, 0.88, 1.0, 0.0)
	_particles.visible = false
	add_child(_particles)


func _build_logo() -> void:
	word_face = _load_face()
	_holder = Node3D.new()
	_holder.position = Vector3(0.0, 0.46, 0.0)
	add_child(_holder)
	if word_face == null:
		return
	var widths: Array[float] = []
	var total := 0.0
	var gap := 0.045
	for index in HJIntro.WORD.length():
		var glyph := HJIntro.WORD.substr(index, 1)
		var width := word_face.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x * PIXEL
		width = maxf(width, 0.28)
		widths.append(width)
		total += width
	total += gap * float(HJIntro.WORD.length() - 1)
	var cursor := -total * 0.5
	for index in HJIntro.WORD.length():
		var glyph := HJIntro.WORD.substr(index, 1)
		var width: float = widths[index]
		var center := cursor + width * 0.5
		cursor += width + gap
		var letter := _extrude(glyph)
		letter.position = Vector3(center, 0.0, 0.0)
		letter.visible = false
		_holder.add_child(letter)
		_letters.append(letter)
		_bases.append(center)
	if _letters.size() != HJIntro.WORD.length():
		logo_built = false
		return
	var fit := 5.15 / maxf(total, 0.01)
	_holder.scale = Vector3.ONE * minf(fit, 1.0)
	_rule = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(total * 0.62, 0.028, 0.07)
	_rule.mesh = bar
	_rule.position = Vector3(0.0, -0.78, 0.02)
	_rule.material_override = _metal()
	_rule.visible = false
	_rule.scale = Vector3(0.001, 1.0, 1.0)
	_holder.add_child(_rule)
	logo_built = true


func _extrude(glyph: String) -> Node3D:
	var root := Node3D.new()
	var layers := 9
	for index in layers:
		var depth := float(index) / float(layers - 1)
		var plate := Label3D.new()
		plate.text = glyph
		plate.font = word_face
		plate.font_size = FONT_SIZE
		plate.pixel_size = PIXEL
		plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plate.position = Vector3(0.0, 0.0, -depth * 0.22)
		plate.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		plate.shaded = false
		plate.double_sided = true
		plate.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		plate.alpha_scissor_threshold = 0.4
		plate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		plate.modulate = Color(0.8, 0.82, 0.86).lerp(Color(0.22, 0.24, 0.28), depth)
		plate.outline_size = 0
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(plate)
	var front := root.get_child(0) as Label3D
	front.modulate = Color(0.9, 0.92, 0.95)
	front.outline_size = 0
	return root


func _load_face() -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		return null
	var file := load(FONT_PATH) as Font
	if file == null:
		return null
	var variation := FontVariation.new()
	variation.base_font = file
	variation.variation_opentype = {0x77676874: 700.0}
	return variation


func _metal() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.74, 0.8)
	mat.metallic = 0.72
	mat.roughness = 0.24
	mat.metallic_specular = 0.9
	mat.rim_enabled = true
	mat.rim = 0.32
	mat.rim_tint = 0.8
	mat.emission_enabled = true
	mat.emission = Color(0.82, 0.86, 0.92)
	mat.emission_energy_multiplier = 0.0
	if not OS.has_feature("web"):
		mat.clearcoat_enabled = true
		mat.clearcoat = 0.5
		mat.clearcoat_roughness = 0.16
	return mat


func _beam_material(strength: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = BEAM_SHADER
	mat.set_shader_parameter("strength", strength)
	return mat


func _streak(size: Vector2, mat: ShaderMaterial, angle: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = mat
	mesh.rotation.z = angle
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh
