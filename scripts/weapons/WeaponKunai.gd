extends WeaponBase

var kunai_mesh_scene = preload("res://assets/models/weapon_kunai.glb")
var projectile_script = preload("res://scripts/weapons/Projectile.gd")

func _init() -> void:
	weapon_name = "EMP Kunai"
	description = "Launches piercing cyber kunai that puncture straight through rows of enemies."
	base_cooldown = 1.2
	base_damage = 28.0
	projectile_count = 1

func _on_level_up() -> void:
	match level:
		2: projectile_count = 2
		3:
			base_damage += 12.0
			base_cooldown = max(0.6, base_cooldown - 0.2)
		4: projectile_count = 3
		5:
			projectile_count = 4
			base_damage += 15.0

func get_upgrade_description() -> String:
	match level + 1:
		2: return "Level 2: Throw +1 Kunai"
		3: return "Level 3: +12 Damage & Faster Cooldown"
		4: return "Level 4: Throw +1 Kunai (3 Total)"
		5: return "Level 5: Throw +1 Kunai (4 Total) & +15 Damage"
		_: return "Max Level reached"

func fire() -> void:
	var target = find_nearest_enemy(35.0)
	var dir = Vector3.FORWARD
	if target and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
		dir.y = 0.0
		dir = dir.normalized()
	elif player:
		dir = player.last_movement_dir if player.last_movement_dir.length_squared() > 0.01 else Vector3.FORWARD

	AudioManager.play_sfx("shuriken", 0.8)

	for i in range(projectile_count):
		# Slight delayed burst
		var angle_offset = randf_range(-0.1, 0.1)
		var fire_dir = dir.rotated(Vector3.UP, angle_offset)
		_spawn_kunai(fire_dir)

func _spawn_kunai(dir: Vector3) -> void:
	var proj = Area3D.new()
	proj.set_script(projectile_script)
	proj.direction = dir
	proj.speed = 30.0
	var dmg_mult = player.damage_multiplier if "damage_multiplier" in player else 1.0
	proj.damage = base_damage * dmg_mult
	proj.pierce = 3 + (2 if level >= 4 else 0)
	proj.lifetime = 2.0
	proj.spin_speed = 0.0 # Straight missile
	
	var model = kunai_mesh_scene.instantiate()
	model.name = "Visuals"
	model.scale = Vector3(1.3, 1.3, 1.3)
	proj.add_child(model)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.4, 0.4, 1.2)
	col.shape = shape
	proj.add_child(col)
	
	proj.collision_layer = 0
	proj.collision_mask = 2 # Enemy layer
	
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0)
	proj.look_at(proj.global_position + dir, Vector3.UP)
