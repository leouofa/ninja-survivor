extends WeaponBase

var slash_radius: float = 3.5

func _init() -> void:
	weapon_name = "Plasma Katana"
	description = "Performs a 360-degree high-impact energy katana slash around you."
	base_cooldown = 1.6
	base_damage = 35.0

func _on_level_up() -> void:
	slash_radius += 0.5
	base_damage += 12.0
	base_cooldown = max(0.8, base_cooldown - 0.15)

func get_upgrade_description() -> String:
	match level + 1:
		2: return "Level 2: +0.5m Radius & +12 Damage"
		3: return "Level 3: +0.5m Radius & Faster Cooldown"
		4: return "Level 4: +0.5m Radius & +15 Damage"
		5: return "Level 5: Max Cleave Range & Heavy Knockback"
		_: return "Max Level reached"

func fire() -> void:
	AudioManager.play_sfx("katana", 1.0)
	
	# Spawn visual slash ring
	_create_visual_slash()
	
	# Damage nearby enemies
	var enemies = find_enemies_in_range(slash_radius)
	var dmg_mult = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var final_damage = base_damage * dmg_mult
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var knock_dir = (enemy.global_position - global_position).normalized()
			knock_dir.y = 0.0
			enemy.take_damage(final_damage, knock_dir * 1.8)

func _create_visual_slash() -> void:
	var slash = Node3D.new()
	get_tree().current_scene.add_child(slash)
	slash.global_position = global_position + Vector3(0, 0.8, 0)
	
	# Create a glowing ring mesh
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = slash_radius * 0.75
	torus.outer_radius = slash_radius
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.05, 0.4, 0.8) # Hot neon magenta
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.05, 0.4)
	mat.emission_energy_multiplier = 8.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.mesh = torus
	mesh_inst.material_override = mat
	slash.add_child(mesh_inst)
	
	# Tween expand and fade
	var tween = slash.create_tween()
	slash.scale = Vector3(0.2, 0.2, 0.2)
	tween.tween_property(slash, "scale", Vector3(1.1, 1.0, 1.1), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.tween_callback(slash.queue_free)
