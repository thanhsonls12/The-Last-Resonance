shader_type spatial;
render_mode blend_mix, cull_back;

// --- Uniforms ---
uniform vec4 base_color : source_color = vec4(0.08, 0.09, 0.11, 1.0);
uniform vec4 pulse_color : source_color = vec4(0.12, 0.92, 1.0, 1.0);
uniform vec4 core_glow_color : source_color = vec4(0.8, 0.98, 1.0, 1.0);
uniform float flow_speed : hint_range(-10.0, 10.0, 0.1) = 3.0;
uniform float pulse_frequency : hint_range(0.5, 30.0, 0.5) = 8.0;
uniform float pulse_width : hint_range(0.05, 0.95, 0.05) = 0.35;
uniform float emission_strength : hint_range(0.0, 10.0, 0.1) = 3.5;
uniform bool is_active = true;
uniform float activity_progress : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float roughness : hint_range(0.0, 1.0, 0.05) = 0.4;
uniform float metallic : hint_range(0.0, 1.0, 0.05) = 0.8;

void fragment() {
	ALBEDO = base_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	if (is_active && activity_progress > 0.001) {
		// Moving pulse along UV.y (cable length)
		float coord = fract(UV.y * pulse_frequency - TIME * flow_speed);
		
		// Sharp pulse curve
		float pulse = smoothstep(0.0, pulse_width * 0.5, coord) * (1.0 - smoothstep(pulse_width * 0.5, pulse_width, coord));
		
		// Core brightness peak
		float center_stripe = 1.0 - abs(UV.x - 0.5) * 2.0;
		center_stripe = clamp(pow(center_stripe, 3.0), 0.0, 1.0);
		
		float energy = pulse * center_stripe * activity_progress;
		vec3 emission_col = mix(pulse_color.rgb, core_glow_color.rgb, energy * 0.6) * energy * emission_strength;
		
		EMISSION = emission_col;
	} else {
		EMISSION = vec3(0.0);
	}
}
