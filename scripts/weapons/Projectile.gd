extends Area3D

var direction: Vector3 = Vector3.FORWARD
var speed: float = 16.0
var damage: float = 15.0
var pierce: int = 1
var lifetime: float = 3.0
var spin_speed: float = 15.0
var hits: int = 0

var homing: bool = false
var target_enemy: Node3D = null

# VFX Configuration
var enable_trail: bool = false
var enable_blade_blur: bool = false
var blade_blur_radius: float = 0.6
var trail_color: Color = Color(0.0, 1.0, 1.0) # Electric Cyan default
var max_trail_points: int = 14
var trail_width: float = 0.25

var trail_mesh_instance: MeshInstance3D = null
var trail_immediate_mesh: ImmediateMesh = null
var trail_points: Array[Vector3] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if enable_blade_blur:
		_setup_blade_blur()
	
	if enable_trail:
		_setup_ribbon_trail()

func _setup_blade_blur() -> void:
	var blur_disc = MeshInstance3D.new()
	blur_disc.name = "BladeBlur"
	var torus = TorusMesh.new()
	torus.inner_radius = blade_blur_radius * 0.4
	torus.outer_radius = blade_blur_radius
	torus.rings = 24
	torus.ring_segments = 4
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.4)
	mat.emission_enabled = true
	mat.emission = trail_color
	mat.emission_energy_multiplier = 7.0
	blur_disc.mesh = torus
	blur_disc.material_override = mat
	
	var visuals = get_node_or_null("Visuals")
	if visuals:
		visuals.add_child(blur_disc)
	else:
		add_child(blur_disc)

func _setup_ribbon_trail() -> void:
	trail_mesh_instance = MeshInstance3D.new()
	trail_mesh_instance.top_level = true
	trail_immediate_mesh = ImmediateMesh.new()
	trail_mesh_instance.mesh = trail_immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	trail_mesh_instance.material_override = mat
	
	get_tree().current_scene.add_child(trail_mesh_instance)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_cleanup_and_free()
		return
	
	if homing and is_instance_valid(target_enemy):
		var to_target = (target_enemy.global_position - global_position).normalized()
		direction = direction.lerp(to_target, 6.0 * delta).normalized()
		look_at(global_position + direction, Vector3.UP)
	
	global_position += direction * speed * delta
	
	# Rotate visuals if has child mesh
	var mesh = get_node_or_null("Visuals")
	if mesh and spin_speed > 0.0:
		mesh.rotate_y(spin_speed * delta)
	
	# Update ribbon trail
	if enable_trail and is_instance_valid(trail_mesh_instance):
		trail_points.push_front(global_position)
		if trail_points.size() > max_trail_points:
			trail_points.pop_back()
		_render_ribbon()

func _render_ribbon() -> void:
	if trail_points.size() < 2 or not is_instance_valid(trail_immediate_mesh):
		return
	trail_immediate_mesh.clear_surfaces()
	trail_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var count = trail_points.size()
	for i in range(count):
		var t = float(i) / float(count - 1)
		var alpha = (1.0 - t) * 0.75
		var col = Color(trail_color.r, trail_color.g, trail_color.b, alpha)
		trail_immediate_mesh.surface_set_color(col)
		
		var pt = trail_points[i]
		var w = trail_width * (1.0 - t * 0.65)
		var perp = direction.cross(Vector3.UP).normalized() * w
		
		trail_immediate_mesh.surface_add_vertex(pt + perp)
		trail_immediate_mesh.surface_add_vertex(pt - perp)
		
	trail_immediate_mesh.surface_end()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, direction)
		hits += 1
		AudioManager.play_sfx("enemy_hit", 1.2)
		_spawn_hit_sparks(global_position, direction)
		if hits >= pierce:
			_cleanup_and_free()

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage, direction)
		hits += 1
		AudioManager.play_sfx("enemy_hit", 1.2)
		_spawn_hit_sparks(global_position, direction)
		if hits >= pierce:
			_cleanup_and_free()

func _spawn_hit_sparks(pos: Vector3, dir: Vector3) -> void:
	# 1. Spark burst particles
	var sparks = GPUParticles3D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 18
	sparks.lifetime = 0.35
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = -dir + Vector3(0, 0.4, 0)
	p_mat.spread = 70.0
	p_mat.initial_velocity_min = 3.5
	p_mat.initial_velocity_max = 8.0
	p_mat.gravity = Vector3(0, -8.0, 0)
	p_mat.scale_min = 0.05
	p_mat.scale_max = 0.12
	p_mat.color = trail_color
	
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.06, 0.06)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = trail_color
	mat.emission_enabled = true
	mat.emission = trail_color
	mat.emission_energy_multiplier = 8.0
	box.material = mat
	
	sparks.process_material = p_mat
	sparks.draw_pass_1 = box
	
	get_tree().current_scene.add_child(sparks)
	sparks.global_position = pos
	sparks.restart()
	get_tree().create_timer(0.5).timeout.connect(sparks.queue_free)
	
	# 2. Expanding shockwave ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.38
	torus.rings = 16
	torus.ring_segments = 3
	var r_mat = StandardMaterial3D.new()
	r_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.albedo_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.75)
	ring.mesh = torus
	ring.material_override = r_mat
	get_tree().current_scene.add_child(ring)
	ring.global_position = pos
	
	var tween = ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(2.2, 1.0, 2.2), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(r_mat, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(ring.queue_free)

func _cleanup_and_free() -> void:
	if is_instance_valid(trail_mesh_instance):
		trail_mesh_instance.queue_free()
	queue_free()

func _exit_tree() -> void:
	if is_instance_valid(trail_mesh_instance):
		trail_mesh_instance.queue_free()
