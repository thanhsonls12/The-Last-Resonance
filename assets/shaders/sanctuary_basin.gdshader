shader_type spatial;
render_mode cull_back;

uniform float water_time = 0.0;
uniform vec2 basin_size = vec2(20.0);
uniform float wave_height = 0.018;
uniform vec4 ripple_0 = vec4(0.0, 0.0, -10.0, 0.0);
uniform vec4 ripple_1 = vec4(0.0, 0.0, -10.0, 0.0);
uniform vec4 ripple_2 = vec4(0.0, 0.0, -10.0, 0.0);
varying vec2 water_position;

float step_ripple(vec2 p, vec4 event) {
	float age = water_time - event.z;
	float distance = length(p - event.xy);
	return (1.0 - smoothstep(0.025, 0.13, abs(distance - age * 0.85))) *
		max(0.0, 1.0 - age / 1.8) * event.w;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

void vertex() {
	water_position = VERTEX.xz;
	VERTEX.y += wave_height * (sin(VERTEX.x * 1.8 + water_time * 0.55)
		+ cos(VERTEX.z * 2.1 - water_time * 0.40));
}

void fragment() {
	vec2 p = water_position;
	float drift = noise(p * 0.48 + vec2(water_time * 0.025, -water_time * 0.018));
	float ripple = p.y * 9.0 + sin(p.x * 1.4 + water_time * 0.2) * 1.5 + drift * 6.0 - water_time * 0.65;
	float crests = pow(0.5 + 0.5 * sin(ripple), 24.0) * smoothstep(0.25, 0.70, drift);
	float edge = 1.0 - smoothstep(0.65, 1.0, max(abs(p.x) / (basin_size.x * 0.5), abs(p.y) / (basin_size.y * 0.5)));
	vec3 deep = vec3(0.008, 0.038, 0.052);
	vec3 shallow = vec3(0.045, 0.19, 0.21);
	vec3 water = mix(deep, shallow, drift * 0.65 + crests * 0.25);
	ALBEDO = mix(vec3(0.004, 0.012, 0.019), water, edge);
	ROUGHNESS = 0.50;
	METALLIC = 0.12;
	SPECULAR = 0.14;
	vec2 slope = vec2(cos(p.x * 2.7 + p.y * 1.3 + water_time * 0.65), cos(ripple)) * 0.025;
	NORMAL_MAP = normalize(vec3(-slope, 1.0)) * 0.5 + 0.5;
	EMISSION = (water * 0.24 + vec3(0.09, 0.27, 0.28) * crests * 0.35) * edge;
	EMISSION += vec3(0.06, 0.19, 0.19) * (step_ripple(p, ripple_0) + step_ripple(p, ripple_1) + step_ripple(p, ripple_2));
}
