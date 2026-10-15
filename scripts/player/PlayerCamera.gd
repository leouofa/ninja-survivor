extends Camera3D

@export var follow_offset: Vector3 = Vector3(0.0, 17.0, 14.0)
@export var smooth_speed: float = 6.0

var target: Node3D = null
var shake_amount: float = 0.0

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		target = players[0]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0]
		return
	
	var target_pos = target.global_position + follow_offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	
	# Apply screen shake
	if shake_amount > 0.0:
		shake_amount = max(0.0, shake_amount - 8.0 * delta)
		var shake_offset = Vector3(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-0.5, 0.5) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount
		)
		global_position += shake_offset
	
	# Look at player
	look_at(target.global_position + Vector3(0, 1.0, 0), Vector3.UP)

func add_shake(amount: float) -> void:
	shake_amount = min(1.5, shake_amount + amount)
