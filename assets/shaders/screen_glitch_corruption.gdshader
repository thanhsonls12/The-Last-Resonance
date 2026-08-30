shader_type canvas_item;

// --- Uniforms ---
uniform float glitch_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.05, 0.001) = 0.008;
uniform float scanline_density : hint_range(50.0, 800.0, 10.0) = 300.0;
uniform float scanline_opacity : hint_range(0.0, 1.0, 0.05) = 0.25;
uniform float noise_amount : hint_range(0.0, 1.0, 0.05) = 0.15;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	if (glitch_intensity > 0.001) {
		// Horizontal block displacement
		float block_y = floor(uv.y * 24.0);
		float glitch_trigger = random(vec2(block_y, floor(TIME * 18.0)));
		
		if (glitch_trigger < (glitch_intensity * 0.45)) {
			float shift = (random(vec2(block_y, floor(TIME * 24.0))) - 0.5) * 0.06 * glitch_intensity;
			uv.x += shift;
		}
		
		// Fine line jitter
		float line_jitter = (random(vec2(floor(uv.y * 120.0), floor(TIME * 30.0))) - 0.5) * 0.015 * glitch_intensity;
		uv.x += line_jitter;
	}
	
	// Chromatic Aberration (RGB Split)
	float split = chromatic_aberration * glitch_intensity;
	float r = texture(screen_texture, uv + vec2(split, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(split, 0.0)).b;
	float a = texture(screen_texture, uv).a;
	vec3 color = vec3(r, g, b);
	
	// Digital static noise
	if (glitch_intensity > 0.001) {
		float noise = random(uv + vec2(TIME * 20.0, TIME * 15.0));
		color = mix(color, vec3(noise), noise_amount * glitch_intensity);
	}
	
	// CRT Scanlines
	float scanline = sin(uv.y * scanline_density) * 0.5 + 0.5;
	color *= mix(1.0, scanline, scanline_opacity * clamp(glitch_intensity * 1.5, 0.2, 1.0));
	
	COLOR = vec4(color, a);
}
