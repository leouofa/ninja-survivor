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

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	if homing and is_instance_valid(target_enemy):
		var to_target = (target_enemy.global_position - global_position).normalized()
		direction = direction.lerp(to_target, 6.0 * delta).normalized()
		look_at(global_position + direction, Vector3.UP)
	
	global_position += direction * speed * delta
	
	# Rotate visuals if has child mesh
	var mesh = get_node_or_null("Visuals")
	if mesh:
		mesh.rotate_y(spin_speed * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, direction)
		hits += 1
		AudioManager.play_sfx("enemy_hit", 1.2)
		if hits >= pierce:
			queue_free()

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage, direction)
		hits += 1
		AudioManager.play_sfx("enemy_hit", 1.2)
		if hits >= pierce:
			queue_free()
