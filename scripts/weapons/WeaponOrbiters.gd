extends WeaponBase

var orb_count: int = 2
var orbit_radius: float = 2.4
var rotation_speed: float = 4.0
var current_rotation: float = 0.0

var active_orbs: Array[Area3D] = []

func _init() -> void:
	weapon_name = "Kitsune Orbiters"
	description = "Summons spinning plasma motes that shield you and incinerate encroaching enemies."
	base_cooldown = 0.5
	base_damage = 14.0

func _ready() -> void:
	super._ready()
	_rebuild_orbs()

func _on_level_up() -> void:
	match level:
		2: orb_count = 3
		3:
			orb_count = 4
			base_damage += 4.0
		4:
			orb_count = 5
			rotation_speed = 5.5
		5:
			orb_count = 6
			base_damage += 8.0
	_rebuild_orbs()

func get_upgrade_description() -> String:
	match level + 1:
		2: return "Level 2: +1 Orb (3 Total)"
		3: return "Level 3: +1 Orb & +4 Damage (4 Total)"
		4: return "Level 4: +1 Orb & Faster Orbit Speed (5 Total)"
		5: return "Level 5: +1 Orb & +8 Damage (6 Total)"
		_: return "Max Level reached"

func _process(delta: float) -> void:
	current_rotation += rotation_speed * delta
	if current_rotation > TAU:
		current_rotation -= TAU
	
	for i in range(active_orbs.size()):
		var orb = active_orbs[i]
		if is_instance_valid(orb):
			var angle = current_rotation + (i * TAU / active_orbs.size())
			var target_pos = global_position + Vector3(cos(angle) * orbit_radius, 1.0, sin(angle) * orbit_radius)
			orb.global_position = target_pos

func _rebuild_orbs() -> void:
	for orb in active_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbs.clear()
	
	for i in range(orb_count):
		var orb = Area3D.new()
		orb.collision_layer = 0
		orb.collision_mask = 2 # Enemy layer
		
		# Visual sphere
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		var mat = StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.4, 0.05) # Neon Amber / Fire
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.05)
		mat.emission_energy_multiplier = 6.0
		mesh_inst.mesh = sphere
		mesh_inst.material_override = mat
		orb.add_child(mesh_inst)
		
		# Collision
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.35
		col.shape = shape
		orb.add_child(col)
		
		orb.body_entered.connect(func(b): _on_orb_hit(b))
		orb.area_entered.connect(func(a): _on_orb_area_hit(a))
		
		get_tree().current_scene.add_child(orb)
		active_orbs.append(orb)

func _on_orb_hit(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var dmg_mult = player.damage_multiplier if "damage_multiplier" in player else 1.0
		body.take_damage(base_damage * dmg_mult, (body.global_position - global_position).normalized() * 0.5)
		AudioManager.play_sfx("enemy_hit", 1.4)

func _on_orb_area_hit(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		var dmg_mult = player.damage_multiplier if "damage_multiplier" in player else 1.0
		parent.take_damage(base_damage * dmg_mult, (parent.global_position - global_position).normalized() * 0.5)
		AudioManager.play_sfx("enemy_hit", 1.4)

func _exit_tree() -> void:
	for orb in active_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbs.clear()
