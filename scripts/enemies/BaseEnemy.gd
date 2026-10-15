extends CharacterBody3D
class_name BaseEnemy

@export var max_hp: float = 30.0
var hp: float = 30.0
@export var speed: float = 4.0
@export var damage: float = 10.0
@export var xp_drop: int = 10
@export var is_boss: bool = false
@export var enemy_type: String = "ronin"

var player: CharacterBody3D = null
var knockback: Vector3 = Vector3.ZERO
var visual_node: Node3D = null
var datacube_scene = preload("res://scripts/pickups/Datacube.gd")

var is_dying: bool = false
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(55.0)
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
	
	_setup_visuals()

func _setup_visuals() -> void:
	visual_node = Node3D.new()
	visual_node.name = "Visuals"
	add_child(visual_node)
	
	var model_path = "res://assets/models/enemy_" + enemy_type + ".glb"
	if enemy_type == "boss":
		model_path = "res://assets/models/boss_gashadokuro.glb"
		
	if ResourceLoader.exists(model_path):
		var model = load(model_path).instantiate()
		visual_node.add_child(model)

const GRAVITY: float = 24.0

func _physics_process(delta: float) -> void:
	if is_dying:
		return
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	
	# Apply knockback decay
	knockback = knockback.move_toward(Vector3.ZERO, 30.0 * delta)
	
	# Gravity & floor stick
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	
	var y_vel = velocity.y
	
	if is_instance_valid(player):
		var to_player = (player.global_position - global_position)
		to_player.y = 0.0
		var dist = to_player.length()
		var move_dir = to_player.normalized()
		
		# Movement logic depending on archetype
		match enemy_type:
			"chochin":
				# Erratic zigzag rush
				var side_dir = move_dir.cross(Vector3.UP)
				move_dir = (move_dir + side_dir * sin(Time.get_ticks_msec() * 0.008) * 0.8).normalized()
				velocity = move_dir * speed + knockback
			"tengu":
				# Fast swooper
				velocity = move_dir * (speed * 1.3) + knockback
			"kitsune":
				# Circles player if close, rushes if far
				if dist < 6.0:
					var tangent = move_dir.cross(Vector3.UP)
					velocity = (tangent * 0.8 + move_dir * 0.2).normalized() * speed + knockback
				else:
					velocity = move_dir * speed + knockback
			_:
				# Standard ronin / oni / boss charge
				velocity = move_dir * speed + knockback
		
		velocity.y = y_vel
		
		# Rotate visual node toward move direction
		if move_dir.length_squared() > 0.01:
			var target_rot = atan2(move_dir.x, move_dir.z)
			visual_node.rotation.y = lerp_angle(visual_node.rotation.y, target_rot, 10.0 * delta)
		
		# Check contact damage
		if dist < 1.3 and attack_cooldown <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				attack_cooldown = 0.8
	else:
		velocity = knockback
		velocity.y = y_vel
	
	move_and_slide()
	_enforce_map_bounds()
	_enforce_ground_height()

const MAP_BOUNDARY_LIMIT: float = 78.5

func _enforce_map_bounds() -> void:
	global_position.x = clamp(global_position.x, -MAP_BOUNDARY_LIMIT, MAP_BOUNDARY_LIMIT)
	global_position.z = clamp(global_position.z, -MAP_BOUNDARY_LIMIT, MAP_BOUNDARY_LIMIT)

func _enforce_ground_height() -> void:
	var floor_nodes = get_tree().get_nodes_in_group("procedural_floor")
	if not floor_nodes.is_empty():
		var gh = floor_nodes[0].get_height_at(global_position.x, global_position.z)
		if global_position.y < gh - 0.15:
			global_position.y = gh + 0.02
			velocity.y = 0.0

func take_damage(amount: float, knock_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dying:
		return
	
	hp -= amount
	GameManager.player_damage_dealt += amount
	knockback = knock_dir * (6.0 if not is_boss else 1.0)
	
	# White flash
	if visual_node:
		var tween = visual_node.create_tween()
		tween.tween_property(visual_node, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
		tween.tween_property(visual_node, "scale", Vector3(1.0, 1.0, 1.0), 0.05)
	
	if hp <= 0.0:
		die()

func die() -> void:
	is_dying = true
	GameManager.player_kills += 1
	AudioManager.play_sfx("enemy_die", 1.0 if not is_boss else 0.6)
	
	# Drop Datacube XP
	_spawn_drop()
	
	# Shrink and free
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)

func _spawn_drop() -> void:
	var cube = Area3D.new()
	cube.set_script(datacube_scene)
	cube.xp_value = xp_drop
	cube.collision_layer = 4
	cube.collision_mask = 1
	get_tree().current_scene.add_child(cube)
	cube.global_position = global_position + Vector3(0, 0.5, 0)
