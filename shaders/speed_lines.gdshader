shader_type canvas_item;

uniform float strength = 0.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);
	float angle = atan(centered.y, centered.x);
	float spokes = abs(fract(angle * 7.0) - 0.5);
	float line = smoothstep(0.07, 0.0, spokes);
	float ring = smoothstep(0.18, 0.62, dist);
	float edge = 1.0 - smoothstep(0.78, 1.05, dist);
	COLOR = vec4(0.82, 0.92, 1.0, line * ring * edge * strength);
}
