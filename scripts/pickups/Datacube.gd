extends Area3D

var xp_value: int = 10
var magnet_speed: float = 0.0
var max_magnet_speed: float = 24.0
var target_player: CharacterBody3D = null
var being_collected: bool = false

var cube_mesh_scene = preload("res://assets/models/pickup_datacube.glb")

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	
	# Instantiate visual model
	var model = cube_mesh_scene.instantiate()
	model.name = "Visuals"
	add_child(model)
	
	# Collision
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	add_child(col)

func _physics_process(delta: float) -> void:
	# Idle float and spin
	rotate_y(3.0 * delta)
	
	if is_instance_valid(target_player):
		magnet_speed = min(max_magnet_speed, magnet_speed + 35.0 * delta)
		var dir = (target_player.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
		global_position += dir * magnet_speed * delta

func attract_to(player_node: CharacterBody3D) -> void:
	target_player = player_node

func _on_body_entered(body: Node) -> void:
	if being_collected:
		return
	if body.is_in_group("player") and body.has_method("collect_xp"):
		being_collected = true
		body.collect_xp(xp_value)
		AudioManager.play_sfx("pickup_xp", randf_range(0.9, 1.2))
		
		# Quick shrink and delete
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.1)
		tween.tween_callback(queue_free)
