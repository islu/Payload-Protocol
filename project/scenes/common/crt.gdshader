// The CRT filter (SPEC Section 4.2): scanlines and a vignette on the full screen.
// It does not bend the image, so that the mouse points at the cell that the player
// sees. A setting turns it off (SPEC Section 23.1).
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_strength = 0.16;
uniform float vignette = 0.35;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	vec3 col = texture(screen_texture, uv).rgb;
	float line = sin(uv.y * 3.14159 * (1.0 / SCREEN_PIXEL_SIZE.y) * 0.5);
	col *= 1.0 - scanline_strength * (0.5 + 0.5 * line);
	float v = 1.0 - vignette * dot(c, c) * 2.0;
	COLOR = vec4(col * v, 1.0);
}
