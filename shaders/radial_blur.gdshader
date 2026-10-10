shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pull = (uv - vec2(0.5)) * strength;
	vec4 color = texture(screen_texture, uv) * 0.42;
	color += texture(screen_texture, uv - pull * 0.35) * 0.22;
	color += texture(screen_texture, uv - pull * 0.7) * 0.2;
	color += texture(screen_texture, uv - pull) * 0.16;
	COLOR = color;
}
