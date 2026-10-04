shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.08, 0.18, 0.23, 1.0);
uniform vec4 tint : source_color = vec4(0.1, 0.8, 0.95, 1.0);
uniform float metallic = 0.2;
uniform float roughness = 0.5;
uniform float fx_time = 0.0;
uniform float intensity = 0.5;
uniform float emission_scale = 1.0;
uniform float phase = 0.0;
uniform bool unstable = false;
uniform bool scan = false;
uniform int state = -1;

void fragment() {
	float wave = 0.76 + 0.24 * sin(fx_time * 1.7 + phase);
	float sweep = 1.0 - smoothstep(0.01, 0.09, abs(UV.y - fract(fx_time * 0.16 + phase)));
	float line = 0.90 + 0.10 * sin(UV.y * 150.0);
	float dropout = unstable ? mix(0.25, 1.0, step(0.08, fract(fx_time * 0.73 + phase))) : 1.0;
	vec3 color = tint.rgb;
	float strength = intensity;
	if (state >= 0) {
		color = state == 2 ? vec3(0.15, 1.0, 0.58) : (state == 1 ? vec3(1.0, 0.72, 0.16) : vec3(0.08, 0.34, 0.38));
		strength = state == 2 ? 1.8 : (state == 1 ? 1.25 : 0.18);
	}
	ALBEDO = mix(base_color.rgb, color, scan ? 0.28 : 0.08);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = color * strength * emission_scale * wave * dropout * (scan ? line * (0.65 + sweep * 0.65) : 1.0);
}
