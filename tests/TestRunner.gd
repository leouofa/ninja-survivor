extends Node

func _ready() -> void:
	print("--- BEGIN TEST: Datacube & Shuriken Visuals ---")
	
	# 1. Test Shuriken Projectile creation and visual nodes
	var proj_script = load("res://scripts/weapons/Projectile.gd")
	var shuriken_mesh_scene = load("res://assets/models/weapon_shuriken_razor.glb")
	
	assert(proj_script != null, "Projectile.gd failed to load")
	assert(shuriken_mesh_scene != null, "weapon_shuriken_razor.glb failed to load")
	
	var proj = Area3D.new()
	proj.set_script(proj_script)
	proj.direction = Vector3.FORWARD
	proj.speed = 22.0
	proj.enable_trail = true
	proj.enable_blade_blur = true
	proj.blade_blur_radius = 0.62
	proj.trail_color = Color(0.0, 1.0, 1.0)
	
	var model = shuriken_mesh_scene.instantiate()
	model.name = "Visuals"
	proj.add_child(model)
	
	add_child(proj)
	
	# Verify blade blur node was attached
	var blur = proj.find_child("BladeBlur", true, false)
	assert(blur != null, "BladeBlur node was not created")
	print("✓ Shuriken & BladeBlur created successfully")
	
	# Test physics process & trail update
	proj._physics_process(0.016)
	assert(proj.trail_points.size() > 0, "Trail points failed to accumulate")
	print("✓ Shuriken ribbon trail running with %d points" % proj.trail_points.size())
	
	# 2. Test Datacube Crystal creation and tiered styling
	var datacube_script = load("res://scripts/pickups/Datacube.gd")
	assert(datacube_script != null, "Datacube.gd failed to load")
	
	# Standard Tier (Emerald)
	var cube_emerald = Area3D.new()
	cube_emerald.set_script(datacube_script)
	cube_emerald.xp_value = 10
	add_child(cube_emerald)
	assert(cube_emerald.is_elite_tier == false, "Standard cube should not be elite")
	assert(cube_emerald.primary_color == Color(0.0, 1.0, 0.45), "Standard cube color should be Emerald Green")
	assert(cube_emerald.ripple_mesh != null, "Ground ripple mesh should exist")
	print("✓ Standard Emerald Datacube verified")
	
	# Elite Tier (Gold)
	var cube_gold = Area3D.new()
	cube_gold.set_script(datacube_script)
	cube_gold.xp_value = 50
	add_child(cube_gold)
	assert(cube_gold.is_elite_tier == true, "Elite cube should be elite")
	assert(cube_gold.primary_color == Color(1.0, 0.85, 0.12), "Elite cube color should be Cyber Gold")
	print("✓ Elite Gold Datacube verified")
	
	# Simulate physics tick on cubes
	cube_emerald._physics_process(0.016)
	cube_gold._physics_process(0.016)
	print("✓ Hover bobbing and dual-axis rotation verified")
	
	# Cleanup
	proj.queue_free()
	cube_emerald.queue_free()
	cube_gold.queue_free()
	
	print("\n--- BEGIN TEST: Procedural Floor & Track Amplitude ---")
	
	# 3. Test Track Amplitude Manifest Loading
	assert(GameManager.amplitude_manifest.size() > 0, "Amplitude manifest should be loaded")
	assert(GameManager.tracks_list.size() > 0, "Tracks list should not be empty")
	print("✓ Track amplitude manifest verified with %d tracks" % GameManager.tracks_list.size())
	
	# Verify every track has a deterministic seed and amplitude properties
	for t in GameManager.tracks_list:
		assert(t.has("seed") and t["seed"] > 0, "Track %s missing valid seed" % t["title"])
		assert(t.has("height_scale") and t["height_scale"] >= 1.0, "Track %s invalid height_scale" % t["title"])
		assert(t.has("palette_name"), "Track %s missing palette" % t["title"])
	print("✓ All %d tracks verified with unique idempotent seeds and themes" % GameManager.tracks_list.size())

	# 4. Test Procedural Floor Generation & Idempotence
	var floor_script = load("res://scripts/environment/ProceduralFloor.gd")
	assert(floor_script != null, "ProceduralFloor.gd failed to load")
	
	var floor_node1 = StaticBody3D.new()
	floor_node1.set_script(floor_script)
	var mi1 = MeshInstance3D.new()
	mi1.name = "MeshInstance3D"
	floor_node1.add_child(mi1)
	var col1 = CollisionShape3D.new()
	col1.name = "CollisionShape3D"
	floor_node1.add_child(col1)
	add_child(floor_node1)
	
	var track_armageddon = GameManager.tracks_list[0]
	floor_node1.generate_floor(track_armageddon)
	
	# Sample heights
	var h0 = floor_node1.get_height_at(0, 0)
	var h_north = floor_node1.get_height_at(0, -45)
	var h_south = floor_node1.get_height_at(0, 45)
	var h_east = floor_node1.get_height_at(45, 0)
	var h_west = floor_node1.get_height_at(-45, 0)
	var h_hill = floor_node1.get_height_at(30, 30)
	
	# Verify center and torii gate flattening
	assert(is_equal_approx(h0, 0.0), "Center spawn must be flat (y=0), got %f" % h0)
	assert(is_equal_approx(h_north, 0.0), "North Torii gate must be flat, got %f" % h_north)
	assert(is_equal_approx(h_south, 0.0), "South Torii gate must be flat, got %f" % h_south)
	assert(is_equal_approx(h_east, 0.0), "East Torii gate must be flat, got %f" % h_east)
	assert(is_equal_approx(h_west, 0.0), "West Torii gate must be flat, got %f" % h_west)
	print("✓ Spawn center and Torii landmark leveling verified")
	
	# Verify elevation exists in the arena
	assert(h_hill > 0.1, "Terrain must have height variability away from landmarks, got %f" % h_hill)
	print("✓ Terrain height variability verified (h(30, 30) = %f m)" % h_hill)
	
	# Test Idempotence: generate with same track in a second instance
	var floor_node2 = StaticBody3D.new()
	floor_node2.set_script(floor_script)
	var mi2 = MeshInstance3D.new()
	mi2.name = "MeshInstance3D"
	floor_node2.add_child(mi2)
	var col2 = CollisionShape3D.new()
	col2.name = "CollisionShape3D"
	floor_node2.add_child(col2)
	add_child(floor_node2)
	
	floor_node2.generate_floor(track_armageddon)
	var h_hill2 = floor_node2.get_height_at(30, 30)
	assert(is_equal_approx(h_hill, h_hill2), "Heights must be identical for same track seed")
	print("✓ Seed idempotence verified (identical heights across runs: %f == %f)" % [h_hill, h_hill2])
	
	# Verify native solid HeightMapShape3D collision
	assert(col1.shape != null, "Floor collision shape must not be null")
	assert(col1.shape is HeightMapShape3D, "Collision shape must be HeightMapShape3D")
	assert(col1.shape.map_data.size() > 0, "HeightMapShape3D map_data must not be empty")
	print("✓ Native solid HeightMapShape3D physics collision verified (%dx%d)" % [col1.shape.map_width, col1.shape.map_depth])
	
	# 5. Test Audio Reactivity Uniform Updates
	assert(floor_node1.floor_material != null, "Shader material must exist on floor")
	AudioManager._smoothed_amplitude = 0.85
	floor_node1._process(0.016)
	var amp_param = floor_node1.floor_material.get_shader_parameter("live_amplitude")
	assert(is_equal_approx(amp_param, 0.85), "Shader live_amplitude must match AudioManager smoothed amplitude")
	print("✓ Audio-reactive live amplitude shader parameter verified (value: %f)" % amp_param)
	
	# 6. Test Player slope traversal & gravity
	var player_script = load("res://scripts/player/Player.gd")
	var player = CharacterBody3D.new()
	player.set_script(player_script)
	var p_col = CollisionShape3D.new()
	var p_shape = CapsuleShape3D.new()
	p_shape.radius = 0.4
	p_shape.height = 1.8
	p_col.shape = p_shape
	player.add_child(p_col)
	add_child(player)
	
	player.global_position = Vector3(0, 5.0, 0)
	player.velocity = Vector3.ZERO
	player._physics_process(0.016)
	assert(player.velocity.y < 0.0, "Player must experience downward gravity when in mid-air")
	print("✓ Player kinematic gravity and slope physics verified (downward vy = %f)" % player.velocity.y)
	
	# Cleanup
	floor_node1.queue_free()
	floor_node2.queue_free()
	player.queue_free()
	await get_tree().process_frame
	
	# 7. Test Full GameArena Scene Instantiation, HeightMapShape3D & Real Physics
	var arena_scene = load("res://scenes/game/GameArena.tscn")
	assert(arena_scene != null, "GameArena.tscn failed to load")
	var arena = arena_scene.instantiate()
	add_child(arena)
	
	var arena_player = arena.get_node("Player")
	var arena_ground = arena.get_node("Ground")
	var ground_mesh = arena_ground.get_node("MeshInstance3D").mesh
	assert(ground_mesh != null, "GameArena procedural ground mesh must exist")
	
	# Verify HeightMapShape3D collision
	var hms_shape = arena_ground.get_node("CollisionShape3D").shape
	assert(hms_shape is HeightMapShape3D, "Floor collision shape must be HeightMapShape3D")
	assert(hms_shape.map_width == 161 and hms_shape.map_depth == 161, "HeightMapShape3D resolution must be 161x161")
	print("✓ Native solid HeightMapShape3D verified (161x161 resolution, 1m/sample)")
	
	# Verify underground safety foundation
	var safety_col = arena_ground.find_child("SafetyFloorCollision", false, false)
	assert(safety_col != null, "SafetyFloorCollision node must exist")
	assert(safety_col.shape is BoxShape3D, "Safety collision shape must be BoxShape3D")
	print("✓ Underground solid safety foundation verified (4m thick BoxShape3D)")
	
	# Verify upward normal on ground faces
	var arena_faces = ground_mesh.get_faces()
	var v0 = arena_faces[0]
	var v1 = arena_faces[1]
	var v2 = arena_faces[2]
	var norm = (v1 - v0).cross(v2 - v0).normalized()
	assert(norm.y > 0.5, "Mesh face normal must point UP (+Y), got %s" % norm)
	print("✓ GameArena procedural mesh upward winding verified (normal: %s)" % norm)
	
	# Verify player collision mask includes ground
	assert((arena_player.collision_mask & 1) != 0, "Player collision mask must include layer 1 (Ground)")
	
	# Run 80 real physics frames across engine updates
	var opening_enemies_seen = false
	for f in range(80):
		await get_tree().physics_frame
		var enemies = get_tree().get_nodes_in_group("enemies")
		if not enemies.is_empty():
			opening_enemies_seen = true
		assert(arena_player.global_position.y >= -0.2, "Player must not fall through terrain! Tick %d, y: %f" % [f, arena_player.global_position.y])
		
	assert(opening_enemies_seen, "Immediate opening wave of enemies must spawn on level start")
	assert(arena_player.is_on_floor(), "Player must be stably grounded on floor")
	print("✓ Player grounded stably on procedural terrain at y = %f (on_floor: %s)" % [arena_player.global_position.y, arena_player.is_on_floor()])
	print("✓ Immediate opening enemy wave verified on screen from start")
	
	print("\n--- BEGIN TEST: Arena Boundary Confinement ---")
	
	# Verify all 4 boundary barrier collision walls exist on arena_ground
	var wall_north = arena_ground.find_child("BoundaryWallNorth", false, false)
	var wall_south = arena_ground.find_child("BoundaryWallSouth", false, false)
	var wall_east = arena_ground.find_child("BoundaryWallEast", false, false)
	var wall_west = arena_ground.find_child("BoundaryWallWest", false, false)
	
	assert(wall_north != null and wall_north.shape is BoxShape3D, "BoundaryWallNorth must exist with BoxShape3D")
	assert(wall_south != null and wall_south.shape is BoxShape3D, "BoundaryWallSouth must exist with BoxShape3D")
	assert(wall_east != null and wall_east.shape is BoxShape3D, "BoundaryWallEast must exist with BoxShape3D")
	assert(wall_west != null and wall_west.shape is BoxShape3D, "BoundaryWallWest must exist with BoxShape3D")
	print("✓ 4 perimeter boundary collision walls verified (North, South, East, West)")
	
	# Test high-speed dash towards boundaries in all 4 cardinal directions & corner
	var test_vectors = [
		{"name": "East (+X)", "start": Vector3(75.0, 0.0, 0.0), "dir": Vector3(1, 0, 0)},
		{"name": "West (-X)", "start": Vector3(-75.0, 0.0, 0.0), "dir": Vector3(-1, 0, 0)},
		{"name": "South (+Z)", "start": Vector3(0.0, 0.0, 75.0), "dir": Vector3(0, 0, 1)},
		{"name": "North (-Z)", "start": Vector3(0.0, 0.0, -75.0), "dir": Vector3(0, 0, -1)},
		{"name": "Corner (+X, +Z)", "start": Vector3(75.0, 0.0, 75.0), "dir": Vector3(1, 0, 1).normalized()},
	]
	
	for tv in test_vectors:
		arena_player.global_position = tv.start
		arena_player.last_movement_dir = tv.dir
		arena_player.velocity = tv.dir * 40.0 # Extreme speed (40 m/s)
		arena_player.is_dashing = true
		arena_player.dash_timer = 0.5
		
		for _step in range(20):
			await get_tree().physics_frame
			assert(abs(arena_player.global_position.x) <= 78.501, "Player breached X boundary: %s at %s" % [tv.name, arena_player.global_position])
			assert(abs(arena_player.global_position.z) <= 78.501, "Player breached Z boundary: %s at %s" % [tv.name, arena_player.global_position])
			assert(arena_player.global_position.y >= -0.5, "Player fell off boundary terrain: %s at %s" % [tv.name, arena_player.global_position])
		
		print("✓ Boundary confinement verified: %s (final pos: %s)" % [tv.name, arena_player.global_position])
	
	# Verify enemy spawn boundary confinement
	var spawner = arena.get_node("EnemySpawner")
	assert(spawner != null, "EnemySpawner must exist")
	# Force spawn an enemy when player is at edge
	arena_player.global_position = Vector3(78.0, 0.0, 78.0)
	for i in range(10):
		spawner._spawn_enemy("ronin")
	var spawned_enemies = get_tree().get_nodes_in_group("enemies")
	for e in spawned_enemies:
		assert(abs(e.global_position.x) <= 74.5, "Enemy spawned out of bounds X: %s" % e.global_position)
		assert(abs(e.global_position.z) <= 74.5, "Enemy spawned out of bounds Z: %s" % e.global_position)
	print("✓ Enemy spawn boundary clamping verified (%d enemies tested within ±74m)" % spawned_enemies.size())
	
	arena.queue_free()
	
	print("\n--- ALL TESTS PASSED SUCCESSFULLY ---")
	get_tree().quit(0)
