extends CharacterBody3D

signal hp_changed(current: float, maximum: float)
signal xp_updated(current: int, needed: int, level: int)
signal leveled_up(new_level: int)
signal player_died()

@export var max_health: float = 100.0
var health: float = 100.0
@export var base_speed: float = 7.5
var current_speed: float = 7.5

var damage_multiplier: float = 1.0
var cooldown_reduction: float = 0.0
var magnet_radius: float = 4.5
var health_regen: float = 0.0

# Dash
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_duration: float = 0.2
var dash_speed: float = 20.0
var dash_cooldown: float = 1.2
var dash_cooldown_timer: float = 0.0
var is_invulnerable: bool = false

# XP
var current_level: int = 1
var current_xp: int = 0
var xp_needed: int = 25

# Movement
var last_movement_dir: Vector3 = Vector3.FORWARD
var visual_node: Node3D
var magnet_area: Area3D
var magnet_shape: SphereShape3D

# Weapons & Passives inventory
var active_weapons: Array[Node] = []
var active_passives: Dictionary = {} # "speed": 1, "damage": 1, etc.

var player_model_scene = preload("res://assets/models/player_ninja.glb")

func _ready() -> void:
	add_to_group("player")
	health = max_health
	current_speed = base_speed
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(55.0)
	collision_mask = collision_mask | 1 | 2
	
	# Visual model
	visual_node = Node3D.new()
	visual_node.name = "Visuals"
	add_child(visual_node)
	
	var model = player_model_scene.instantiate()
	visual_node.add_child(model)
	
	# Magnet Area
	magnet_area = Area3D.new()
	magnet_area.collision_layer = 0
	magnet_area.collision_mask = 4 # Pickup layer
	magnet_shape = SphereShape3D.new()
	magnet_shape.radius = magnet_radius
	var col = CollisionShape3D.new()
	col.shape = magnet_shape
	magnet_area.add_child(col)
	add_child(magnet_area)
	magnet_area.area_entered.connect(_on_magnet_area_entered)
	
	# Default starter weapon
	add_weapon("res://scripts/weapons/WeaponShuriken.gd")
	
	hp_changed.emit(health, max_health)
	xp_updated.emit(current_xp, xp_needed, current_level)

const GRAVITY: float = 24.0

func _physics_process(delta: float) -> void:
	# Passive Regen
	if health_regen > 0.0 and health < max_health:
		health = min(max_health, health + health_regen * delta)
		hp_changed.emit(health, max_health)
	
	# Dash cooldown
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	# Gravity & floor stick
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			is_invulnerable = false
		var y_vel = velocity.y
		velocity = last_movement_dir * dash_speed
		velocity.y = y_vel
		move_and_slide()
		return
	
	# Normal movement
	var input_vec = Vector2.ZERO
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_up", "move_down")
	
	if input_vec.length_squared() > 1.0:
		input_vec = input_vec.normalized()
	
	var move_dir = Vector3(input_vec.x, 0, input_vec.y).normalized()
	var y_vel = velocity.y
	
	if move_dir.length_squared() > 0.01:
		last_movement_dir = move_dir
		velocity = move_dir * current_speed
		velocity.y = y_vel
		
		# Rotate visual model smoothly toward movement
		var target_rot = atan2(move_dir.x, move_dir.z)
		visual_node.rotation.y = lerp_angle(visual_node.rotation.y, target_rot, 14.0 * delta)
		
		# Subtle forward lean
		visual_node.rotation.x = lerp(visual_node.rotation.x, deg_to_rad(12.0), 10.0 * delta)
	else:
		var current_h = Vector3(velocity.x, 0.0, velocity.z)
		current_h = current_h.move_toward(Vector3.ZERO, current_speed * 12.0 * delta)
		velocity.x = current_h.x
		velocity.z = current_h.z
		velocity.y = y_vel
		visual_node.rotation.x = lerp(visual_node.rotation.x, 0.0, 10.0 * delta)
	
	# Dash Trigger
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and move_dir.length_squared() > 0.01:
		_trigger_dash()
	
	move_and_slide()

func _trigger_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	AudioManager.play_sfx("shuriken", 1.8)
	
	# Ghost trail effect
	var tween = visual_node.create_tween()
	tween.tween_property(visual_node, "scale", Vector3(1.3, 0.7, 1.3), 0.1)
	tween.tween_property(visual_node, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func take_damage(amount: float) -> void:
	if is_invulnerable or health <= 0.0:
		return
	
	health = max(0.0, health - amount)
	hp_changed.emit(health, max_health)
	AudioManager.play_sfx("enemy_hit", 0.7)
	
	# Flash red
	_flash_hit()
	
	if health <= 0.0:
		_die()

func _flash_hit() -> void:
	is_invulnerable = true
	var tween = create_tween()
	tween.tween_property(visual_node, "scale", Vector3(1.15, 0.85, 1.15), 0.06)
	tween.tween_property(visual_node, "scale", Vector3(1.0, 1.0, 1.0), 0.06)
	tween.tween_callback(func(): is_invulnerable = false)

func _die() -> void:
	player_died.emit()
	GameManager.game_over_triggered.emit()

func collect_xp(amount: int) -> void:
	current_xp += amount
	if current_xp >= xp_needed:
		current_xp -= xp_needed
		current_level += 1
		xp_needed = int(xp_needed * 1.3) + 10
		leveled_up.emit(current_level)
		GameManager.player_leveled_up.emit(current_level)
		AudioManager.play_sfx("level_up", 1.0)
	
	xp_updated.emit(current_xp, xp_needed, current_level)
	GameManager.xp_changed.emit(current_xp, xp_needed)

func add_weapon(script_path: String) -> Node3D:
	var script = load(script_path)
	var weapon = Node3D.new()
	weapon.set_script(script)
	add_child(weapon)
	active_weapons.append(weapon)
	return weapon

func get_weapon(weapon_name: String) -> Node3D:
	for w in active_weapons:
		if w.weapon_name == weapon_name:
			return w
	return null

func upgrade_passive(passive_id: String) -> void:
	var lvl = active_passives.get(passive_id, 0) + 1
	active_passives[passive_id] = lvl
	
	match passive_id:
		"speed":
			current_speed = base_speed * (1.0 + lvl * 0.12)
		"damage":
			damage_multiplier = 1.0 + lvl * 0.2
		"cooldown":
			cooldown_reduction = min(0.5, lvl * 0.1)
		"magnet":
			magnet_radius = 4.5 * (1.0 + lvl * 0.35)
			if magnet_shape:
				magnet_shape.radius = magnet_radius
		"regen":
			health_regen = float(lvl) * 1.5

func _on_magnet_area_entered(area: Area3D) -> void:
	if area.is_in_group("pickups") and area.has_method("attract_to"):
		area.attract_to(self)
