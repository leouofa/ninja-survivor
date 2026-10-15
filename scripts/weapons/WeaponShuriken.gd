extends WeaponBase

var shuriken_mesh_scene = preload("res://assets/models/weapon_shuriken.glb")
var projectile_script = preload("res://scripts/weapons/Projectile.gd")

func _init() -> void:
	weapon_name = "Cyber Shurikens"
	description = "Throws spinning neon shurikens towards nearby enemies."
	base_cooldown = 0.8
	base_damage = 18.0
	projectile_count = 1

func _on_level_up() -> void:
	match level:
		2:
			projectile_count = 2
		3:
			projectile_count = 3
			base_damage += 5.0
		4:
			projectile_count = 4
		5:
			projectile_count = 5
			base_damage += 10.0

func get_upgrade_description() -> String:
	match level + 1:
		2: return "Level 2: Fire +1 additional Shuriken"
		3: return "Level 3: Fire +1 additional Shuriken & +5 Damage"
		4: return "Level 4: Fire +1 additional Shuriken"
		5: return "Level 5: Fire +1 additional Shuriken & +10 Damage"
		_: return "Max Level reached"

func fire() -> void:
	var target = find_nearest_enemy()
	var base_dir = Vector3.FORWARD
	if target and is_instance_valid(target):
		base_dir = (target.global_position - global_position).normalized()
		base_dir.y = 0.0
		base_dir = base_dir.normalized()
	elif player:
		# Use player movement or facing
		base_dir = player.last_movement_dir if player.last_movement_dir.length_squared() > 0.01 else Vector3.FORWARD
	
	var count = projectile_count
	var spread_angle = deg_to_rad(15.0)
	var start_angle = - (count - 1) * spread_angle * 0.5
	
	AudioManager.play_sfx("shuriken", 1.0)
	
	for i in range(count):
		var angle = start_angle + i * spread_angle
		var dir = base_dir.rotated(Vector3.UP, angle)
		_spawn_shuriken(dir)

func _spawn_shuriken(dir: Vector3) -> void:
	var proj = Area3D.new()
	proj.set_script(projectile_script)
	proj.direction = dir
	proj.speed = 22.0
	var dmg_mult = player.damage_multiplier if "damage_multiplier" in player else 1.0
	proj.damage = base_damage * dmg_mult
	proj.pierce = 1 + (1 if level >= 4 else 0)
	proj.lifetime = 2.5
	proj.spin_speed = 20.0
	
	# Visual model
	var model = shuriken_mesh_scene.instantiate()
	model.name = "Visuals"
	model.scale = Vector3(1.2, 1.2, 1.2)
	proj.add_child(model)
	
	# Collision shape
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	proj.add_child(col)
	
	proj.collision_layer = 0
	proj.collision_mask = 2 # Enemy layer
	
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0)
