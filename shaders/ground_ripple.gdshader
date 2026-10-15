shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 ripple_color : source_color = vec4(0.0, 1.0, 0.45, 0.85);
uniform float speed : hint_range(0.1, 5.0) = 1.6;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	if (dist > 1.0) {
		discard;
	}
	float pulse = fract(TIME * speed);
	float ring_dist = abs(dist - pulse);
	float ring = smoothstep(0.18, 0.0, ring_dist) * (1.0 - pulse);
	float core = smoothstep(0.35, 0.0, dist) * 0.35;
	ALBEDO = ripple_color.rgb;
	ALPHA = clamp((ring + core) * ripple_color.a, 0.0, 1.0);
}
