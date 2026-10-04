shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.1, 0.4, 0.6, 0.4);
uniform vec4 tint : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float metallic = 0.0;
uniform float roughness = 0.5;
uniform float fx_time = 0.0;
uniform float intensity = 0.6;
uniform float phase = 0.0;
uniform bool unstable = false;
uniform bool scan = true;
uniform int state = -1;

void fragment() {
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	float lines = 0.65 + 0.35 * sin(UV.y * 100.0 - fx_time * 2.0);
	float scan_band = 1.0 - smoothstep(0.0, 0.10, abs(UV.y - fract(fx_time * 0.13 + phase)));
	float pulse = 0.8 + 0.2 * sin(fx_time * 1.2 + phase);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * intensity * (0.5 + rim + scan_band * 0.4);
	ALPHA = clamp((base_color.a + 0.1) * lines * pulse * (0.35 + rim * 0.65), 0.0, 0.65);
}
