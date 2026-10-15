shader_type canvas_item;
render_mode blend_mix;

// Procedural Synthwave Outrun Background Shader
// Features: Infinite rolling perspective grid, segmented neon sunset,
// silhouette mountain range, twinkling cyber starfield, and audio-reactive bloom.

// --- PALETTE UNIFORMS ---
uniform vec4 sky_top_color : source_color = vec4(0.04, 0.01, 0.14, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.24, 0.04, 0.32, 1.0);
uniform vec4 sun_top_color : source_color = vec4(1.0, 0.08, 0.58, 1.0);       // Hot neon magenta
uniform vec4 sun_bottom_color : source_color = vec4(1.0, 0.82, 0.12, 1.0);    // Radiant cyber yellow-gold
uniform vec4 grid_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);            // Electric cyan
uniform vec4 grid_glow_color : source_color = vec4(0.85, 0.05, 0.65, 1.0);     // Magenta horizon glow
uniform vec4 mountain_color : source_color = vec4(0.06, 0.02, 0.12, 1.0);     // Deep silhouette
uniform vec4 mountain_rim_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);    // Cyan rim highlight

// --- LAYOUT & SHAPES ---
uniform float horizon_y : hint_range(0.2, 0.8) = 0.52;
uniform vec2 sun_center = vec2(0.5, 0.35);
uniform float sun_radius : hint_range(0.05, 0.4) = 0.22;
uniform float sun_slat_frequency : hint_range(20.0, 150.0) = 75.0;

// --- ANIMATION & DYNAMICS ---
uniform float grid_speed : hint_range(0.0, 5.0) = 0.85;
uniform float live_amplitude : hint_range(0.0, 1.0) = 0.0;

// --- READABILITY & VIGNETTE ---
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.45;
uniform float center_dim : hint_range(0.0, 1.0) = 0.35;

// Pseudo-random hash for stars
float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;

	// Calculate aspect ratio so circular elements stay perfectly round
	float aspect = 1.7777778; // Default 16:9 fallback
	if (SCREEN_PIXEL_SIZE.x > 0.0 && SCREEN_PIXEL_SIZE.y > 0.0) {
		aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	}

	vec3 final_color = vec3(0.0);
	float pulse = live_amplitude * 1.2;

	// ==========================================
	// 1. SKY GRADIENT (Upper Section)
	// ==========================================
	float sky_factor = clamp(uv.y / horizon_y, 0.0, 1.0);
	vec3 sky = mix(sky_top_color.rgb, sky_horizon_color.rgb, pow(sky_factor, 1.5));

	// Starfield (in deep upper sky)
	if (uv.y < horizon_y - 0.04) {
		vec2 star_uv = uv * vec2(160.0 * aspect, 160.0);
		vec2 star_id = floor(star_uv);
		float star_val = hash21(star_id);

		if (star_val > 0.982) {
			vec2 star_fract = fract(star_uv) - 0.5;
			float star_dist = length(star_fract);
			float twinkle = sin(TIME * (3.0 + star_val * 7.0) + star_val * 6.28) * 0.5 + 0.5;
			float star_brightness = smoothstep(0.3, 0.0, star_dist) * (0.4 + 0.6 * twinkle);
			
			// Color variation for stars (cyan & magenta hints)
			vec3 star_col = (star_val > 0.99) ? vec3(0.6, 0.9, 1.0) : vec3(1.0, 0.7, 0.9);
			sky += star_col * star_brightness * (1.0 - sky_factor * 0.7);
		}
	}

	// ==========================================
	// 2. RETRO SYNTHWAVE SUN (Segmented Outrun Disc)
	// ==========================================
	vec2 sun_aspect_diff = vec2((uv.x - sun_center.x) * aspect, uv.y - sun_center.y);
	float sun_dist = length(sun_aspect_diff);

	// Outward neon sun glow halo (visible beyond the disc)
	float halo = exp(-sun_dist * 4.5) * (0.6 + pulse * 0.5);
	vec3 halo_col = mix(sun_bottom_color.rgb, sun_top_color.rgb, clamp((uv.y - sun_center.y) / sun_radius + 0.5, 0.0, 1.0));
	sky += halo_col * halo * 0.7;

	// Sun Disc interior
	if (sun_dist < sun_radius) {
		float sun_y_norm = (uv.y - (sun_center.y - sun_radius)) / (2.0 * sun_radius);
		sun_y_norm = clamp(sun_y_norm, 0.0, 1.0);

		// Vertical gradient across the sun disc
		vec3 disc_col = mix(sun_top_color.rgb, sun_bottom_color.rgb, pow(sun_y_norm, 1.2));
		disc_col *= (1.1 + pulse * 0.4);

		// Horizontal Venetian blind slats (expanding gap toward the bottom)
		float slat_band = sin((uv.y - sun_center.y) * sun_slat_frequency);
		float gap_threshold = smoothstep(0.30, 0.95, sun_y_norm) * 0.72;

		if (slat_band > gap_threshold || sun_y_norm < 0.32) {
			// Sharp antialiased circular edge
			float disc_alpha = smoothstep(sun_radius, sun_radius - 0.005, sun_dist);
			sky = mix(sky, disc_col, disc_alpha);
		}
	}

	// ==========================================
	// 3. HORIZON SILHOUETTE MOUNTAIN RANGE
	// ==========================================
	if (uv.y < horizon_y + 0.01) {
		// Layer 1: Distant jagged ridges
		float m1_x = uv.x * 9.0;
		float m1_height = sin(m1_x) * 0.035 + sin(m1_x * 2.3 + 1.2) * 0.02 + sin(m1_x * 5.1) * 0.01;
		float m1_y = horizon_y - 0.03 - abs(m1_height);

		// Layer 2: Nearer sweeping peaks
		float m2_x = (uv.x + 0.25) * 6.5;
		float m2_height = sin(m2_x) * 0.055 + sin(m2_x * 2.7 + 2.8) * 0.025 + sin(m2_x * 6.2) * 0.008;
		float m2_y = horizon_y - abs(m2_height);

		// Distant mountain
		if (uv.y >= m1_y) {
			float rim1 = smoothstep(0.008, 0.0, uv.y - m1_y);
			vec3 m1_col = mix(mountain_color.rgb * 1.5, mountain_rim_color.rgb * 0.5, rim1);
			sky = mix(sky, m1_col, 0.85);
		}

		// Foreground mountain
		if (uv.y >= m2_y) {
			float rim2 = smoothstep(0.006, 0.0, uv.y - m2_y);
			vec3 m2_col = mix(mountain_color.rgb, mountain_rim_color.rgb * 0.9, rim2 * (1.0 + pulse * 0.3));
			sky = m2_col;
		}
	}

	// ==========================================
	// 4. PERSPECTIVE NEON GRID FLOOR (Lower Section)
	// ==========================================
	if (uv.y >= horizon_y) {
		float dy = uv.y - horizon_y;
		dy = max(dy, 0.0015); // Prevent divide by zero

		// 3D perspective mapping
		float depth = 0.12 / dy;
		float x_proj = (uv.x - 0.5) * depth * 3.2;
		float z_proj = depth + TIME * grid_speed * (1.0 + live_amplitude * 0.08);

		// Grid lines
		vec2 grid_uv = abs(fract(vec2(x_proj, z_proj)) - 0.5);
		
		// Antialiased line rendering adapted to depth
		float line_thickness = 0.045 + 0.01 * min(depth, 4.0);
		vec2 lines = 1.0 - smoothstep(vec2(0.0), vec2(line_thickness), grid_uv);
		float grid_pattern = max(lines.x, lines.y);

		// Horizon atmospheric blend & fog
		float depth_fade = clamp(dy / 0.35, 0.0, 1.0);
		float horizon_haze = exp(-dy * 24.0) * (0.85 + pulse * 0.5);

		// Dark reflective floor ground
		vec3 floor_col = mix(vec3(0.02, 0.01, 0.05), grid_glow_color.rgb * 0.18, pow(depth_fade, 2.0));

		// Cyan grid lines with pulse
		vec3 neon_lines = grid_color.rgb * grid_pattern * (1.2 + pulse * 0.6);

		// Combine floor base, grid lines, and horizon haze
		vec3 ground = floor_col + neon_lines;
		ground = mix(ground, grid_glow_color.rgb * 1.1, horizon_haze);

		final_color = ground;
	} else {
		final_color = sky;
	}

	// ==========================================
	// 5. HORIZON GLOW SEAM
	// ==========================================
	float horizon_dist = abs(uv.y - horizon_y);
	float horizon_strip = exp(-horizon_dist * 55.0) * (0.9 + pulse * 0.4);
	final_color += grid_glow_color.rgb * horizon_strip * 0.75;

	// ==========================================
	// 6. CENTER UI CONTRAST VIGNETTE & POLISH
	// ==========================================
	// Subtle center dimming so menu text ("NINJA SURVIVOR") and buttons stay crisp
	float center_dist = length((uv - vec2(0.5, 0.52)) * vec2(aspect, 1.0));
	float ui_vignette = smoothstep(0.2, 0.95, center_dist);
	final_color = mix(final_color * (1.0 - center_dim), final_color, ui_vignette);

	// Edge screen vignette
	float edge_vignette = smoothstep(1.3, 0.65, center_dist);
	final_color *= mix(1.0 - vignette_intensity, 1.0, edge_vignette);

	COLOR = vec4(final_color, 1.0);
}
