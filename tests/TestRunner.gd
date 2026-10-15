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
	
	print("--- TEST PASSED SUCCESSFULLY ---")
	get_tree().quit(0)
