extends StaticBody3D
class_name ProceduralFloor

@export var arena_size: float = 160.0
@export var subdivisions: int = 160
@export var default_height_scale: float = 2.0
@export var default_voronoi_scale: float = 0.05

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var noise: FastNoiseLite
var detail_noise: FastNoiseLite

var current_seed: int = 1337
var height_scale: float = 2.0
var voronoi_scale: float = 0.05
var floor_material: ShaderMaterial

# Landmark locations to keep completely flat for gameplay
const TORII_LOCATIONS = [
	Vector2(0.0, -45.0),
	Vector2(0.0, 45.0),
	Vector2(45.0, 0.0),
	Vector2(-45.0, 0.0)
]

func _ready() -> void:
	add_to_group("procedural_floor")
	
	# Fetch track info or fallback
	var track_info = GameManager.current_track_info
	if track_info.is_empty() and not GameManager.tracks_list.is_empty():
		track_info = GameManager.tracks_list[0]
		GameManager.current_track_info = track_info
		
	generate_floor(track_info)

func _process(_delta: float) -> void:
	if floor_material:
		var live_amp = AudioManager.get_live_amplitude()
		floor_material.set_shader_parameter("live_amplitude", live_amp)

func generate_floor(track_info: Dictionary) -> void:
	if mesh_instance == null:
		mesh_instance = $MeshInstance3D
	if collision_shape == null:
		collision_shape = $CollisionShape3D
		
	current_seed = int(track_info.get("seed", 1337))
	height_scale = float(track_info.get("height_scale", default_height_scale))
	voronoi_scale = float(track_info.get("voronoi_scale", default_voronoi_scale))
	
	# Setup cellular Voronoi noise
	noise = FastNoiseLite.new()
	noise.seed = current_seed
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	noise.cellular_jitter = 0.85
	noise.frequency = 0.032
	
	# Setup secondary simplex noise for organic hill modulation
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = (current_seed * 1664525 + 1013904223) & 0x7FFFFFFF
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.frequency = 0.018
	detail_noise.fractal_octaves = 2
	
	# Generate 3D ArrayMesh
	var generated_mesh = _build_terrain_mesh()
	mesh_instance.mesh = generated_mesh
	
	# Generate native solid HeightMapShape3D
	var hms = _build_heightmap_shape()
	collision_shape.shape = hms
	collision_shape.scale = Vector3.ONE
	collision_shape.transform = Transform3D.IDENTITY
	
	# Attach underground safety foundation box
	var safety_node = find_child("SafetyFloorCollision", false, false)
	if safety_node == null:
		safety_node = CollisionShape3D.new()
		safety_node.name = "SafetyFloorCollision"
		var sbox = BoxShape3D.new()
		sbox.size = Vector3(arena_size, 4.0, arena_size)
		safety_node.shape = sbox
		safety_node.position = Vector3(0, -2.0, 0)
		add_child(safety_node)
	
	# Attach perimeter boundary barrier walls
	_build_boundary_walls()
	
	# Setup custom cyber floor shader material
	_setup_shader_material(track_info)

func _build_boundary_walls() -> void:
	var wall_configs = [
		{"name": "BoundaryWallNorth", "pos": Vector3(0.0, 8.0, -80.0), "size": Vector3(168.0, 20.0, 4.0)},
		{"name": "BoundaryWallSouth", "pos": Vector3(0.0, 8.0, 80.0), "size": Vector3(168.0, 20.0, 4.0)},
		{"name": "BoundaryWallEast", "pos": Vector3(80.0, 8.0, 0.0), "size": Vector3(4.0, 20.0, 168.0)},
		{"name": "BoundaryWallWest", "pos": Vector3(-80.0, 8.0, 0.0), "size": Vector3(4.0, 20.0, 168.0)},
	]
	for cfg in wall_configs:
		var wall = find_child(cfg.name, false, false)
		if wall == null:
			wall = CollisionShape3D.new()
			wall.name = cfg.name
			var box = BoxShape3D.new()
			box.size = cfg.size
			wall.shape = box
			wall.position = cfg.pos
			add_child(wall)

func _build_heightmap_shape() -> HeightMapShape3D:
	var hms = HeightMapShape3D.new()
	hms.map_width = subdivisions + 1
	hms.map_depth = subdivisions + 1
	var data = PackedFloat32Array()
	data.resize((subdivisions + 1) * (subdivisions + 1))
	var half_sz = arena_size * 0.5
	var step = arena_size / float(subdivisions)
	for j in range(subdivisions + 1):
		var z = -half_sz + float(j) * step
		for i in range(subdivisions + 1):
			var x = -half_sz + float(i) * step
			data[j * (subdivisions + 1) + i] = get_height_at(x, z)
	hms.map_data = data
	return hms

func get_height_at(x: float, z: float) -> float:
	if noise == null:
		return 0.0
		
	# Cellular Voronoi elevation [0.0, 1.0]
	var v = noise.get_noise_2d(x, z) * 0.5 + 0.5
	var d = detail_noise.get_noise_2d(x, z) * 0.5 + 0.5
	
	# Stepped terrace modulation
	var raw_elevation = (v * 0.65 + d * 0.35)
	# Subtly quantize to create cyberpunk terrace steps
	var stepped_elevation = floor(raw_elevation * 6.0) / 6.0 * 0.4 + raw_elevation * 0.6
	var raw_h = stepped_elevation * height_scale
	
	# 1. Radial flattening around player start (0, 0)
	var dist_center = Vector2(x, z).length()
	var center_mask = clamp((dist_center - 10.0) / 12.0, 0.0, 1.0)
	
	# 2. Flattening around Torii gates
	var landmark_mask = 1.0
	for t in TORII_LOCATIONS:
		var dist_t = Vector2(x - t.x, z - t.y).length()
		var m = clamp((dist_t - 6.0) / 8.0, 0.0, 1.0)
		landmark_mask = min(landmark_mask, m)
		
	var combined_mask = min(center_mask, landmark_mask)
	# Smooth easing
	combined_mask = combined_mask * combined_mask * (3.0 - 2.0 * combined_mask)
	
	return raw_h * combined_mask

func _build_terrain_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size = arena_size * 0.5
	var step = arena_size / float(subdivisions)
	var eps = 0.2
	
	# Build vertices grid
	for j in range(subdivisions):
		var z0 = -half_size + float(j) * step
		var z1 = -half_size + float(j + 1) * step
		
		for i in range(subdivisions):
			var x0 = -half_size + float(i) * step
			var x1 = -half_size + float(i + 1) * step
			
			# 4 quad corners
			var y00 = get_height_at(x0, z0)
			var y10 = get_height_at(x1, z0)
			var y11 = get_height_at(x1, z1)
			var y01 = get_height_at(x0, z1)
			
			var p00 = Vector3(x0, y00, z0)
			var p10 = Vector3(x1, y10, z0)
			var p11 = Vector3(x1, y11, z1)
			var p01 = Vector3(x0, y01, z1)
			
			# UVs
			var uv00 = Vector2(float(i) / subdivisions, float(j) / subdivisions)
			var uv10 = Vector2(float(i + 1) / subdivisions, float(j) / subdivisions)
			var uv11 = Vector2(float(i + 1) / subdivisions, float(j + 1) / subdivisions)
			var uv01 = Vector2(float(i) / subdivisions, float(j + 1) / subdivisions)
			
			# Smooth normals via analytic height gradient
			var n00 = _calc_normal(x0, z0, eps)
			var n10 = _calc_normal(x1, z0, eps)
			var n11 = _calc_normal(x1, z1, eps)
			var n01 = _calc_normal(x0, z1, eps)
			
			# Triangle 1: (p00, p01, p11) - CCW facing up (+Y)
			st.set_normal(n00)
			st.set_uv(uv00)
			st.add_vertex(p00)
			
			st.set_normal(n01)
			st.set_uv(uv01)
			st.add_vertex(p01)
			
			st.set_normal(n11)
			st.set_uv(uv11)
			st.add_vertex(p11)
			
			# Triangle 2: (p00, p11, p10) - CCW facing up (+Y)
			st.set_normal(n00)
			st.set_uv(uv00)
			st.add_vertex(p00)
			
			st.set_normal(n11)
			st.set_uv(uv11)
			st.add_vertex(p11)
			
			st.set_normal(n10)
			st.set_uv(uv10)
			st.add_vertex(p10)
			
	return st.commit()

func _calc_normal(x: float, z: float, eps: float) -> Vector3:
	var hl = get_height_at(x - eps, z)
	var hr = get_height_at(x + eps, z)
	var hd = get_height_at(x, z - eps)
	var hu = get_height_at(x, z + eps)
	var n = Vector3(hl - hr, 2.0 * eps, hd - hu)
	return n.normalized()

func _setup_shader_material(track_info: Dictionary) -> void:
	var shader = load("res://shaders/cyber_floor.gdshader")
	floor_material = ShaderMaterial.new()
	floor_material.shader = shader
	
	# Parse colors from track metadata
	var p_col = track_info.get("primary_color", [0.0, 0.95, 1.0, 1.0])
	var s_col = track_info.get("secondary_color", [1.0, 0.08, 0.58, 1.0])
	var a_col = track_info.get("ambient_color", [0.02, 0.015, 0.05, 1.0])
	
	var col_primary = Color(p_col[0], p_col[1], p_col[2], p_col[3])
	var col_secondary = Color(s_col[0], s_col[1], s_col[2], s_col[3])
	var col_ambient = Color(a_col[0], a_col[1], a_col[2], a_col[3])
	
	floor_material.set_shader_parameter("primary_color", col_primary)
	floor_material.set_shader_parameter("secondary_color", col_secondary)
	floor_material.set_shader_parameter("ambient_color", col_ambient)
	floor_material.set_shader_parameter("voronoi_scale", voronoi_scale)
	floor_material.set_shader_parameter("emission_energy", 1.0)
	floor_material.set_shader_parameter("live_amplitude", 0.0)
	
	mesh_instance.material_override = floor_material
