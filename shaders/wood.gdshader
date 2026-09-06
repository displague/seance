shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.12, 0.066, 0.038, 1.0);
uniform float grain_scale = 1.0;
varying vec3 local_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { local_pos=VERTEX; }
void fragment() {
	vec2 p=vec2(local_pos.x,local_pos.z+local_pos.y*0.3)*grain_scale;
	float n=noise(p*vec2(38.0,2.0));
	float grain=sin(p.x*190.0+noise(p*2.0)*15.0)*0.015;
	ALBEDO=base_color.rgb*(0.88+n*0.22+grain);
	ROUGHNESS=0.58+n*0.14;
}
