extends Area3D

var xp_value: int = 10
var magnet_speed: float = 0.0
var max_magnet_speed: float = 24.0
var target_player: CharacterBody3D = null
var being_collected: bool = false

var crystal_scene = preload("res://assets/models/pickup_datacube_crystal.glb")
var ripple_shader = preload("res://shaders/ground_ripple.gdshader")

var visual_container: Node3D
var crystal_mesh: Node3D
var orbit_ring: Node3D
var ripple_mesh: MeshInstance3D

var time_passed: float = 0.0
var primary_color: Color = Color(0.0, 1.0, 0.45) # Vibrant Emerald Green default
var is_elite_tier: bool = false

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	time_passed = randf() * TAU # Desynchronize hover cycles
	
	# Determine tier based on xp value (normal vs elite/boss)
	if xp_value > 20:
		is_elite_tier = true
		primary_color = Color(1.0, 0.85, 0.12) # Radiant Cyber Gold
	else:
		primary_color = Color(0.0, 1.0, 0.45) # Vibrant Emerald Green
	
	# Visual Container for hover bobbing
	visual_container = Node3D.new()
	visual_container.name = "Visuals"
	add_child(visual_container)
	
	# Instantiate visual model
	var model = crystal_scene.instantiate()
	visual_container.add_child(model)
	
	if is_elite_tier:
		visual_container.scale = Vector3(1.25, 1.25, 1.25)
	
	# Cache sub-meshes and apply glowing material
	_setup_materials_and_nodes(model)
	
	# Ground Ripple Beacon
	_setup_ground_ripple()
	
	# Collision Shape
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.65
	col.shape = shape
	add_child(col)

func _setup_materials_and_nodes(root_model: Node3D) -> void:
	crystal_mesh = root_model.find_child("CrystalOuter", true, false)
	orbit_ring = root_model.find_child("OrbitRing", true, false)
	var crystal_inner = root_model.find_child("CrystalInner", true, false)
	
	# Outer crystal material
	var outer_mat = StandardMaterial3D.new()
	outer_mat.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
	outer_mat.albedo_color = Color(primary_color.r * 0.2, primary_color.g * 0.2, primary_color.b * 0.2, 0.9)
	outer_mat.emission_enabled = true
	outer_mat.emission = primary_color
	outer_mat.emission_energy_multiplier = 9.0
	outer_mat.metallic = 0.85
	outer_mat.roughness = 0.15
	
	if crystal_mesh and crystal_mesh is MeshInstance3D:
		crystal_mesh.material_override = outer_mat
	
	# Inner core material
	if crystal_inner and crystal_inner is MeshInstance3D:
		var inner_mat = StandardMaterial3D.new()
		inner_mat.albedo_color = Color(0.03, 0.05, 0.04, 1.0)
		inner_mat.metallic = 0.95
		inner_mat.roughness = 0.1
		crystal_inner.material_override = inner_mat
	
	# Orbit ring material
	if orbit_ring and orbit_ring is MeshInstance3D:
		var ring_mat = StandardMaterial3D.new()
		ring_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		ring_mat.albedo_color = primary_color
		ring_mat.emission_enabled = true
		ring_mat.emission = primary_color
		ring_mat.emission_energy_multiplier = 7.0
		orbit_ring.material_override = ring_mat

func _setup_ground_ripple() -> void:
	ripple_mesh = MeshInstance3D.new()
	var plane = QuadMesh.new()
	plane.size = Vector2(1.6, 1.6)
	plane.orientation = PlaneMesh.FACE_Y
	ripple_mesh.mesh = plane
	
	var mat = ShaderMaterial.new()
	mat.shader = ripple_shader
	mat.set_shader_parameter("ripple_color", Color(primary_color.r, primary_color.g, primary_color.b, 0.75))
	mat.set_shader_parameter("speed", 1.8)
	ripple_mesh.material_override = mat
	
	# Place slightly above floor to prevent z-fighting
	ripple_mesh.position = Vector3(0, -0.45, 0)
	add_child(ripple_mesh)

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# Sinusoidal hover bob on visual container
	if visual_container:
		visual_container.position.y = sin(time_passed * 3.6) * 0.12
	
	# Dual-axis rotation: crystal spins around Y, ring spins along its tilted axis
	if crystal_mesh:
		crystal_mesh.rotate_y(2.6 * delta)
	if orbit_ring:
		orbit_ring.rotate_object_local(Vector3(0.3, 1.0, 0.4).normalized(), -4.5 * delta)
	
	# Magnet collection physics
	if is_instance_valid(target_player):
		magnet_speed = min(max_magnet_speed, magnet_speed + 38.0 * delta)
		var target_pos = target_player.global_position + Vector3(0, 0.8, 0)
		var dir = (target_pos - global_position).normalized()
		global_position += dir * magnet_speed * delta
		
		# Fade ground ripple while flying toward player
		if ripple_mesh and is_instance_valid(ripple_mesh):
			ripple_mesh.visible = false

func attract_to(player_node: CharacterBody3D) -> void:
	target_player = player_node

func _on_body_entered(body: Node) -> void:
	if being_collected:
		return
	if body.is_in_group("player") and body.has_method("collect_xp"):
		being_collected = true
		body.collect_xp(xp_value)
		AudioManager.play_sfx("pickup_xp", randf_range(0.95, 1.25))
		
		# Spawn sparkling collection burst
		_spawn_collection_burst()
		
		# Quick pop and shrink
		var tween = create_tween()
		tween.tween_property(visual_container, "scale", visual_container.scale * 1.3, 0.05)
		tween.tween_property(visual_container, "scale", Vector3(0.01, 0.01, 0.01), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)

func _spawn_collection_burst() -> void:
	var particles = GPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 16
	particles.lifetime = 0.45
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3.UP
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 2.5
	p_mat.initial_velocity_max = 5.5
	p_mat.gravity = Vector3(0, -7.0, 0)
	p_mat.scale_min = 0.06
	p_mat.scale_max = 0.14
	p_mat.color = primary_color
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 0.08, 0.08)
	var box_mat = StandardMaterial3D.new()
	box_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	box_mat.albedo_color = primary_color
	box_mat.emission_enabled = true
	box_mat.emission = primary_color
	box_mat.emission_energy_multiplier = 8.0
	mesh.material = box_mat
	
	particles.process_material = p_mat
	particles.draw_pass_1 = mesh
	
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position + Vector3(0, 0.4, 0)
	particles.restart()
	
	get_tree().create_timer(0.6).timeout.connect(particles.queue_free)
