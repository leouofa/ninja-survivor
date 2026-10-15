shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Cyberpunk Voronoi & Audio-Reactive Terrain Shader
uniform vec4 primary_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(1.0, 0.08, 0.58, 1.0);
uniform vec4 ambient_color : source_color = vec4(0.04, 0.03, 0.08, 1.0);

uniform float voronoi_scale : hint_range(0.01, 0.2) = 0.05;
uniform float live_amplitude : hint_range(0.0, 1.0) = 0.0;
uniform float emission_energy : hint_range(0.1, 5.0) = 1.0;
uniform float panel_metallic : hint_range(0.0, 1.0) = 0.25;
uniform float panel_roughness : hint_range(0.0, 1.0) = 0.45;

// Pseudo-random hash
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

// 2D Voronoi returning vec3(F1, F2, cell_id_hash)
vec3 voronoi(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);

	float f1 = 8.0;
	float f2 = 8.0;
	vec2 min_pt = vec2(0.0);

	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			vec2 r = g - f + o;
			float d = dot(r, r);

			if (d < f1) {
				f2 = f1;
				f1 = d;
				min_pt = n + g + o;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}

	float cell_hash = fract(sin(dot(min_pt, vec2(12.9898, 78.233))) * 43758.5453);
	return vec3(sqrt(f1), sqrt(f2), cell_hash);
}

void fragment() {
	// Reconstruct world space coordinates
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 sample_pos = world_pos.xz * voronoi_scale;

	// Calculate Voronoi pattern
	vec3 v = voronoi(sample_pos);
	float f1 = v.x;
	float f2 = v.y;
	float cell_id = v.z;

	// Cell border seam (where F2 - F1 is small)
	float border_distance = f2 - f1;
	float border = 1.0 - smoothstep(0.02, 0.12, border_distance);

	// Cell interior gradient (darker near center, slightly brighter near seams)
	float cell_interior = smoothstep(0.1, 0.7, f1);

	// Continuous synthwave grid across entire terrain (2.5m spacing)
	vec2 grid_uv = abs(fract(world_pos.xz * 0.4 - 0.5) - 0.5);
	float grid_val = min(grid_uv.x, grid_uv.y);
	float grid_lines = 1.0 - smoothstep(0.0, 0.035, grid_val);

	// Central spawn arena combat ring (radius ~12m)
	float dist_from_center = length(world_pos.xz);
	float center_ring = 1.0 - smoothstep(0.0, 0.4, abs(dist_from_center - 11.5));

	// Topographic elevation contour lines (glowing height rings on hills)
	float elevation_phase = world_pos.y * 10.0;
	float contour = sin(elevation_phase) * 0.5 + 0.5;
	contour = smoothstep(0.82, 0.98, contour) * clamp(world_pos.y * 0.8, 0.0, 1.0);

	// Beat-driven concentric ripple waves from center
	float wave_time = TIME * 3.5;
	float ripple_wave = sin(dist_from_center * 0.35 - wave_time) * 0.5 + 0.5;
	float beat_ripple = smoothstep(0.70, 0.98, ripple_wave) * (0.2 + live_amplitude * 1.5);

	// Audio-reactive emission modulation
	float pulse = live_amplitude * 1.2;

	// Outer boundary warning strip (approaching edge at 70m to 78m)
	float edge_dist = max(abs(world_pos.x), abs(world_pos.z));
	float hazard_zone = smoothstep(70.0, 78.0, edge_dist);
	float hazard_stripes = sin((world_pos.x + world_pos.z) * 1.5 - TIME * 3.0) * 0.5 + 0.5;
	float hazard_border = smoothstep(76.5, 78.0, edge_dist);
	float hazard_intensity = (hazard_border * 0.9 + hazard_zone * hazard_stripes * 0.35) * (0.6 + pulse * 0.8);
	vec3 hazard_emission = secondary_color.rgb * hazard_intensity;

	// Base Albedo: visible cybernetic dark slate / carbon tiles with subtle ambient tone
	vec3 base_tile = ambient_color.rgb * 1.8 + vec3(0.035, 0.035, 0.05);
	vec3 cell_color = mix(base_tile, primary_color.rgb * 0.14, cell_id * 0.6);
	cell_color += primary_color.rgb * 0.08 * cell_interior;

	// Grid tinting on albedo
	vec3 final_albedo = mix(cell_color, primary_color.rgb * 0.45, grid_lines * 0.6);
	final_albedo = mix(final_albedo, secondary_color.rgb * 0.25, hazard_zone * 0.4);
	ALBEDO = final_albedo;
	METALLIC = panel_metallic;
	ROUGHNESS = mix(panel_roughness, 0.15, max(border, grid_lines));

	// 1. Glowing Voronoi Seams
	vec3 seam_emission = primary_color.rgb * border * (0.6 + pulse * 1.0);

	// 2. Subtle Synthwave Grid Glow
	vec3 grid_emission = primary_color.rgb * grid_lines * (0.2 + pulse * 0.4);

	// 3. Central Combat Ring Glow
	vec3 ring_emission = primary_color.rgb * center_ring * (0.7 + pulse * 0.8);

	// 4. Glowing Topographic Contour Lines on Hills
	vec3 contour_emission = secondary_color.rgb * contour * (0.5 + pulse * 0.8);

	// 5. Beat Ripple Waves
	vec3 ripple_emission = secondary_color.rgb * beat_ripple * (0.2 + pulse * 0.6);

	EMISSION = (seam_emission + grid_emission + ring_emission + contour_emission + ripple_emission + hazard_emission) * emission_energy;
}
