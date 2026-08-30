shader_type spatial;
render_mode blend_mix, cull_back;

// --- Uniforms ---
uniform vec4 deep_water_color : source_color = vec4(0.04, 0.22, 0.38, 0.9);
uniform vec4 shallow_water_color : source_color = vec4(0.15, 0.65, 0.78, 0.8);
uniform vec4 frost_rim_color : source_color = vec4(0.85, 0.98, 1.0, 1.0);
uniform float wave_speed : hint_range(0.1, 5.0, 0.1) = 0.8;
uniform float wave_scale : hint_range(1.0, 40.0, 1.0) = 16.0;
uniform float wave_amplitude : hint_range(0.0, 0.1, 0.005) = 0.02;
uniform float metallic : hint_range(0.0, 1.0, 0.05) = 0.15;
uniform float roughness : hint_range(0.0, 1.0, 0.05) = 0.1;
uniform float is_ice_mode : hint_range(0.0, 1.0, 0.1) = 0.0; // 0.0 = Water, 1.0 = Crystalline Ice

void vertex() {
	if (is_ice_mode < 0.5) {
		// Water surface gentle displacement
		float wave1 = sin(VERTEX.x * wave_scale + TIME * wave_speed);
		float wave2 = cos(VERTEX.z * wave_scale * 0.8 + TIME * wave_speed * 1.2);
		VERTEX.y += (wave1 + wave2) * wave_amplitude;
	}
}

void fragment() {
	// Procedural Ripple / Flow pattern
	vec2 uv1 = UV * (wave_scale * 0.5) + vec2(TIME * wave_speed * 0.05, TIME * wave_speed * 0.03);
	vec2 uv2 = UV * (wave_scale * 0.7) - vec2(TIME * wave_speed * 0.04, -TIME * wave_speed * 0.06);
	
	float ripple1 = sin(uv1.x * 6.28) * cos(uv1.y * 6.28);
	float ripple2 = sin(uv2.x * 6.28) * cos(uv2.y * 6.28);
	float ripple = (ripple1 + ripple2) * 0.5 * 0.5 + 0.5;
	
	// Fresnel Sheen
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	
	// Blend water / ice properties
	vec3 water_color = mix(deep_water_color.rgb, shallow_water_color.rgb, ripple * 0.6 + fresnel * 0.4);
	vec3 ice_color = mix(shallow_water_color.rgb, frost_rim_color.rgb, fresnel * 0.8 + ripple * 0.2);
	
	vec3 final_color = mix(water_color, ice_color, is_ice_mode);
	float final_roughness = mix(roughness, 0.05, is_ice_mode);
	float final_alpha = mix(deep_water_color.a, 0.95, is_ice_mode);
	
	ALBEDO = final_color;
	ROUGHNESS = final_roughness;
	METALLIC = metallic;
	SPECULAR = 0.5;
	ALPHA = final_alpha;
	EMISSION = mix(vec3(0.0), frost_rim_color.rgb * 0.3, fresnel * is_ice_mode);
}
