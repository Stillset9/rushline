shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float strength = 1.0;

void fragment() {
	float band = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = pow(clamp(band, 0.0, 1.0), 1.7);
	float fade = pow(clamp(1.0 - abs(UV.x - 0.5) * 2.0, 0.0, 1.0), 0.45);
	float glow = core * fade * strength;
	ALBEDO = vec3(0.45, 0.75, 1.0) * glow;
	ALPHA = clamp(glow, 0.0, 1.0);
}
