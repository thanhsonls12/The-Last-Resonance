shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec3 tint : source_color = vec3(0.055, 0.13, 0.22);
uniform float clock = 0.0;
uniform float pulse = -1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float edge = 1.0 - smoothstep(0.35, 1.0, radius);
	float wisps = 0.55 + 0.22 * sin(p.x * 9.0 + p.y * 5.0 + clock * 0.13)
		+ 0.18 * sin(p.y * 13.0 - p.x * 4.0 - clock * 0.09);
	float ring = exp(-pow((radius - pulse) * 48.0, 2.0))
		* smoothstep(0.0, 0.12, pulse) * (1.0 - smoothstep(0.65, 1.0, pulse));
	ALBEDO = tint;
	ALPHA = edge * wisps * 0.30 + ring * 0.42;
}
