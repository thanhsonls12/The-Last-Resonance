shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// --- Uniforms ---
uniform vec4 inner_core_color : source_color = vec4(0.2, 1.0, 0.85, 1.0);
uniform vec4 outer_resonance_color : source_color = vec4(0.7, 0.25, 1.0, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float emission_power : hint_range(1.0, 10.0, 0.1) = 3.2;
uniform float heartbeat_speed : hint_range(0.5, 10.0, 0.1) = 2.5;
uniform float swirl_speed : hint_range(0.1, 5.0, 0.1) = 1.2;
uniform float fresnel_exponent : hint_range(0.5, 6.0, 0.1) = 2.8;
uniform float alpha_transparency : hint_range(0.1, 1.0, 0.05) = 0.85;

void vertex() {
	// Gentle organic pulsation / floating breath
	float pulse = sin(TIME * heartbeat_speed) * 0.04 + cos(TIME * heartbeat_speed * 1.5 + VERTEX.y * 3.0) * 0.02;
	VERTEX += NORMAL * pulse;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_exponent);
	
	// Procedural swirling pattern
	float swirl = sin(UV.x * 12.0 + TIME * swirl_speed) * cos(UV.y * 12.0 - TIME * swirl_speed * 0.8);
	swirl = swirl * 0.5 + 0.5;
	
	// Heartbeat wave
	float heartbeat = sin(TIME * heartbeat_speed * 2.0) * 0.5 + 0.5;
	
	// Blend colors
	vec3 base = mix(inner_core_color.rgb, outer_resonance_color.rgb, swirl * 0.7 + fresnel * 0.3);
	vec3 final_color = mix(base, highlight_color.rgb, heartbeat * fresnel * 0.8);
	
	ALBEDO = final_color;
	EMISSION = final_color * emission_power * (0.8 + heartbeat * 0.4);
	ROUGHNESS = 0.15;
	METALLIC = 0.2;
	ALPHA = alpha_transparency * (0.6 + fresnel * 0.4);
}
