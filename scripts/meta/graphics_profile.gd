class_name GraphicsProfile
extends RefCounted


static func rank() -> int:
	match GameSettings.quality:
		"bajo":
			return 0
		"alto":
			return 2
		_:
			return 1


static func fancy() -> bool:
	if DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return false
	return RenderingServer.get_current_rendering_method() == "forward_plus"


static func allow_sky() -> bool:
	return DisplayServer.get_name() != "headless"


static func rain_amount() -> int:
	if OS.has_feature("web") or rank() == 0:
		return 48
	if rank() == 1:
		return 110
	return 180


static func headlight_spots(night: bool) -> bool:
	return night and fancy() and rank() >= 1


static func wet_strength(weather_id: String) -> float:
	if weather_id != "lluvia":
		return 0.0
	if rank() == 0:
		return 0.45
	return 1.0


static func pace_lines(speed_mps: float, boosting: bool) -> float:
	var lines := clampf((speed_mps - 18.0) / 52.0, 0.0, 1.0)
	if boosting:
		lines = minf(1.0, lines + 0.5)
	if rank() == 0:
		lines *= 0.2
	if OS.has_feature("web"):
		lines *= 0.55
	return lines


static func pace_blur(speed_mps: float, boosting: bool) -> float:
	if not fancy() or rank() == 0:
		return 0.0
	var lines := pace_lines(speed_mps, boosting)
	return lines * (0.05 if rank() >= 2 else 0.028)


static func decorate(environment: Environment, night: bool, weather_id: String, sky_color: Color) -> void:
	var tier := rank()
	var forward := fancy()
	var wet := weather_id == "lluvia"
	var foggy := weather_id == "niebla"
	if allow_sky():
		var material := ProceduralSkyMaterial.new()
		if night:
			material.sky_top_color = Color(0.01, 0.015, 0.04)
			material.sky_horizon_color = Color(0.08, 0.1, 0.18)
			material.ground_horizon_color = Color(0.04, 0.045, 0.06)
			material.ground_bottom_color = Color(0.01, 0.012, 0.02)
			material.energy_multiplier = 0.28
			material.sun_angle_max = 12.0
		else:
			material.sky_top_color = sky_color.lerp(Color(0.28, 0.48, 0.82), 0.55)
			material.sky_horizon_color = sky_color.lerp(Color(0.95, 0.72, 0.48), 0.35)
			material.ground_horizon_color = sky_color.darkened(0.35)
			material.ground_bottom_color = Color(0.08, 0.08, 0.07)
			material.energy_multiplier = 1.05
			material.sun_angle_max = 28.0
		material.sky_curve = 0.12
		var sky := Sky.new()
		sky.sky_material = material
		environment.sky = sky
		environment.background_mode = Environment.BG_SKY
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = forward and tier >= 1
	environment.glow_intensity = 0.32 if tier == 1 else 0.5
	environment.glow_strength = 0.68
	environment.glow_bloom = 0.1
	environment.glow_hdr_threshold = 1.08
	environment.ssao_enabled = forward and tier >= 1
	environment.ssao_radius = 1.5
	environment.ssao_intensity = 1.05 if tier == 1 else 1.45
	environment.ssao_power = 1.35
	environment.ssil_enabled = forward and tier >= 2
	environment.ssil_radius = 3.5
	environment.ssil_intensity = 0.85
	environment.ssr_enabled = forward and tier >= 1 and (wet or tier >= 2)
	environment.ssr_max_steps = 48 if tier >= 2 else 24
	environment.ssr_fade_in = 0.12
	environment.ssr_fade_out = 1.8
	environment.sdfgi_enabled = forward and tier >= 2
	if environment.sdfgi_enabled:
		environment.sdfgi_use_occlusion = true
		environment.sdfgi_cascades = 4
		environment.sdfgi_min_cell_size = 0.45
		environment.sdfgi_energy = 0.75
		environment.sdfgi_bounce_feedback = 0.35
	var volumetric := forward and tier >= 1 and (foggy or (wet and tier >= 2))
	environment.volumetric_fog_enabled = volumetric
	if volumetric:
		environment.volumetric_fog_density = 0.018 if foggy else 0.006
		environment.volumetric_fog_albedo = sky_color.lerp(Color(0.75, 0.78, 0.82), 0.5)
		environment.volumetric_fog_length = 96.0 if foggy else 64.0
		environment.volumetric_fog_emission = Color(0, 0, 0)
	var base_fog := 0.016 if foggy else (0.004 if wet else 0.0009)
	environment.fog_enabled = true
	environment.fog_density = base_fog
	environment.fog_aerial_perspective = 0.22 if tier >= 1 else 0.12
	environment.fog_light_color = sky_color


static func apply_viewport(viewport: Viewport) -> void:
	if viewport == null:
		return
	var tier := rank()
	var web := OS.has_feature("web")
	var scale := 0.72
	if tier == 1:
		scale = 0.85
	elif tier >= 2:
		scale = 1.0
	if web:
		scale = minf(scale, 0.75)
	viewport.scaling_3d_scale = scale
	if web or tier == 0 or not fancy():
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	else:
		viewport.msaa_3d = Viewport.MSAA_2X if tier >= 2 else Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA


static func tune_sun(sun: DirectionalLight3D) -> void:
	if sun == null:
		return
	sun.shadow_enabled = rank() > 0 or fancy()
	sun.shadow_blur = 0.85 if rank() == 0 else 1.35
	sun.directional_shadow_max_distance = 70.0 if rank() == 0 else (120.0 if rank() == 1 else 180.0)
	sun.light_angular_distance = 0.35 if rank() >= 2 else 0.6
