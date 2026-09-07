shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float age = 0.0;
uniform bool blood = false;

float hash(float p) { return fract(sin(p * 127.1) * 43758.5453); }

void fragment() {
	float column = floor(UV.x * 39.0);
	float variation = hash(column);
	float x = fract(UV.x * 39.0) - (0.2 + variation * 0.6);
	x += sin(UV.y * (7.0 + variation * 16.0) + variation * 4.0) * 0.045;
	float width = 0.028 + variation * 0.13;
	float line = 1.0 - smoothstep(width * 0.35, width, abs(x));
	line *= step(0.32, hash(column + 93.0));
	float tip = clamp((0.06 + variation * variation * 0.36) + age * (0.01 + variation * 0.035), 0.0, 0.96);
	float streak = line * (1.0 - smoothstep(tip, tip + 0.06, UV.y));
	float bead = exp(-pow((UV.y - tip) * 70.0, 2.0)) * line;
	vec3 tint = blood ? vec3(0.22, 0.012, 0.022) : vec3(0.12, 0.24, 0.17);
	ALBEDO = tint * (0.75 + bead * 0.8);
	ROUGHNESS = 0.13;
	METALLIC = 0.1;
	EMISSION = blood ? vec3(0.0) : tint * 0.35 * streak;
	ALPHA = clamp((streak * 0.8 + bead * 0.15) * intensity, 0.0, 0.92);
}
