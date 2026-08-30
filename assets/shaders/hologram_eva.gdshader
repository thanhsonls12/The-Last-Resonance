shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// --- Uniforms ---
uniform vec4 hologram_color : source_color = vec4(0.15, 0.85, 1.0, 0.75);
uniform vec4 rim_color : source_color = vec4(0.5, 0.95, 1.0, 1.0);
uniform float emission_energy : hint_range(0.5, 10.0, 0.1) = 2.5;
uniform float scanline_frequency : hint_range(10.0, 200.0, 1.0) = 80.0;
uniform float scanline_speed : hint_range(-10.0, 10.0, 0.1) = 2.0;
uniform float scanline_intensity : hint_range(0.0, 1.0, 0.05) = 0.35;
uniform float fresnel_power : hint_range(0.5, 8.0, 0.1) = 2.5;
uniform float flicker_speed : hint_range(0.0, 30.0, 0.5) = 12.0;
uniform float flicker_amount : hint_range(0.0, 0.5, 0.01) = 0.08;
uniform float glitch_strength : hint_range(0.0, 1.0, 0.05) = 0.15;
uniform float glitch_frequency : hint_range(0.1, 10.0, 0.1) = 2.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	// Periodic horizontal glitch slice
	float time_block = floor(TIME * glitch_frequency);
	float glitch_rand = random(vec2(time_block, floor(VERTEX.y * 6.0)));
	if (glitch_rand > (1.0 - glitch_strength * 0.4)) {
		float offset = (random(vec2(time_block + 1.0, VERTEX.y)) - 0.5) * glitch_strength * 0.15;
		VERTEX.x += offset;
		VERTEX.z += offset * 0.5;
	}
}

void fragment() {
	// Fresnel Edge Rim Calculation
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);
	
	// Moving Scanlines
	float scanline = sin((UV.y + TIME * scanline_speed * 0.1) * scanline_frequency) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	
	// Flickering alpha
	float flicker = 1.0 - sin(TIME * flicker_speed) * flicker_amount;
	flicker -= random(vec2(TIME * 0.01, UV.y)) * flicker_amount * 0.5;
	
	// Combine Color
	vec3 base = hologram_color.rgb * scanline;
	vec3 final_color = mix(base, rim_color.rgb, fresnel) * emission_energy;
	
	float final_alpha = clamp((hologram_color.a * (0.35 + fresnel * 0.65) * scanline * flicker), 0.0, 1.0);
	
	ALBEDO = final_color;
	ALPHA = final_alpha;
}
