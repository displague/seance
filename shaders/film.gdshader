shader_type canvas_item;
uniform float strength = 0.22;
uniform float ghost_view = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
	vec2 p=UV*2.0-1.0;
	float v=smoothstep(0.25,1.55,length(p));
	float grain=hash(UV*1200.0+mod(TIME,100.0))*0.022;
	COLOR=vec4(mix(vec3(0.0),vec3(0.02,0.13,0.12),ghost_view),v*strength+grain);
}
