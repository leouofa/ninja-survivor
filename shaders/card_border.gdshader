shader_type canvas_item;

uniform vec4 border_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(0.08, 0.08, 0.14, 0.95);
uniform float border_width : hint_range(1.0, 12.0) = 2.5;
uniform float corner_radius : hint_range(0.0, 50.0) = 10.0;
uniform float speed : hint_range(0.1, 10.0) = 2.5;
uniform float beam_length : hint_range(0.05, 0.8) = 0.28;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float is_hovered : hint_range(0.0, 1.0) = 0.0;
uniform vec2 rect_size = vec2(280.0, 340.0);

float rounded_box_sdf(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

void fragment() {
    vec2 p = (UV - 0.5) * rect_size;
    vec2 half_size = rect_size * 0.5;
    float d = rounded_box_sdf(p, half_size, corner_radius);

    if (d > 1.5) {
        discard;
    }

    // Normalized perimeter parameter [0.0, 1.0]
    float angle = atan(p.y, p.x) / (2.0 * PI) + 0.5;
    float cur_speed = speed * (1.0 + is_hovered * 0.7);
    float beam_pos = fract(angle - TIME * cur_speed * 0.25);
    
    // Smooth comet-like energy beam
    float beam_intensity = smoothstep(beam_length, 0.0, beam_pos) * smoothstep(0.0, 0.03, beam_pos);

    // Antialiased shape and border masks
    float shape_mask = smoothstep(0.5, -0.5, d);
    float inner_mask = smoothstep(-border_width + 0.5, -border_width - 0.5, d);
    float border_mask = clamp(shape_mask - inner_mask, 0.0, 1.0);

    float idle_pulse = 0.75 + pulse_intensity * sin(TIME * 3.0) * 0.25;
    vec4 bg = mix(background_color, background_color + vec4(border_color.rgb * 0.12, 0.0), is_hovered);
    
    // Glowing border color with bright leading beam
    vec4 edge_col = border_color * (idle_pulse + is_hovered * 0.4);
    edge_col = mix(edge_col, vec4(1.0, 1.0, 1.0, 1.0), beam_intensity * 0.85);
    edge_col.a = border_color.a;

    vec4 final_col = mix(bg, edge_col, border_mask);
    final_col.a *= shape_mask;

    COLOR = final_col;
}
