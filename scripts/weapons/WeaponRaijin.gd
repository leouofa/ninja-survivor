extends WeaponBase

var strike_count: int = 1

func _init() -> void:
	weapon_name = "Raijin Coil"
	description = "Calls down violet lightning bolts from the synthwave clouds onto random enemies."
	base_cooldown = 2.2
	base_damage = 50.0

func _on_level_up() -> void:
	match level:
		2: strike_count = 2
		3:
			base_damage += 20.0
			base_cooldown = max(1.2, base_cooldown - 0.3)
		4: strike_count = 3
		5:
			strike_count = 4
			base_damage += 25.0

func get_upgrade_description() -> String:
	match level + 1:
		2: return "Level 2: +1 Lightning Strike (2 Total)"
		3: return "Level 3: +20 Damage & Faster Cooldown"
		4: return "Level 4: +1 Lightning Strike (3 Total)"
		5: return "Level 5: +1 Lightning Strike & +25 Damage"
		_: return "Max Level reached"

func fire() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	
	enemies = enemies.duplicate()
	enemies.shuffle()
	
	var strikes = min(strike_count, enemies.size())
	for i in range(strikes):
		var target = enemies[i]
		if is_instance_valid(target):
			_strike_at(target.global_position)

func _strike_at(pos: Vector3) -> void:
	AudioManager.play_sfx("shuriken", 0.6)
	
	# Visual lightning beam
	var beam = Node3D.new()
	get_tree().current_scene.add_child(beam)
	beam.global_position = Vector3(pos.x, 5.0, pos.z)
	
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 10.0
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.1, 1.0, 0.9) # Bright violet
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.1, 1.0)
	mat.emission_energy_multiplier = 10.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	beam.add_child(mesh_inst)
	
	# Damage targets in strike impact radius
	var blast_radius = 2.5
	var r2 = blast_radius * blast_radius
	var dmg_mult = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var final_damage = base_damage * dmg_mult
	
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for e in all_enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if pos.distance_squared_to(e.global_position) <= r2:
				e.take_damage(final_damage, Vector3.UP * 0.5)
	
	# Tween fade
	var tween = beam.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(beam.queue_free)
