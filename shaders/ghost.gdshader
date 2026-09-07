shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;
uniform vec4 spirit_color : source_color = vec4(0.38,0.8,0.74,0.5);
uniform sampler2D albedo_texture : source_color;
uniform bool has_albedo = false;
void vertex() {
	VERTEX.x += sin(TIME*1.6+VERTEX.y*4.0)*0.018;
	VERTEX.z += cos(TIME*1.2+VERTEX.y*3.0)*0.015;
}
void fragment() {
	float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),1.6);
	float pulse=0.72+sin(TIME*1.8+VERTEX.y*7.0)*0.16;
	vec3 detail = has_albedo ? texture(albedo_texture, UV).rgb : vec3(0.5);
	ALBEDO=mix(detail, spirit_color.rgb, 0.6);
	EMISSION=spirit_color.rgb*(rim+0.2)*0.7;
	ALPHA=(rim*0.3+0.3)*pulse;
}
