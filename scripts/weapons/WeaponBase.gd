extends Node3D
class_name WeaponBase

@warning_ignore("unused_signal")
signal weapon_fired()

@export var weapon_name: String = "Weapon"
@export var description: String = "Attacks enemies automatically."
@export var level: int = 1
@export var max_level: int = 5

@export var base_cooldown: float = 1.0
@export var base_damage: float = 10.0
@export var projectile_count: int = 1

var cooldown_timer: float = 0.0
var player: CharacterBody3D

func _ready() -> void:
	player = get_parent() as CharacterBody3D

func _process(delta: float) -> void:
	if not player:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		fire()
		var cd_reduction = player.cooldown_reduction if "cooldown_reduction" in player else 0.0
		cooldown_timer = max(0.1, base_cooldown * (1.0 - cd_reduction))

func fire() -> void:
	# Virtual method to be overridden
	pass

func upgrade() -> void:
	if level < max_level:
		level += 1
		base_damage *= 1.25
		base_cooldown = max(0.2, base_cooldown * 0.9)
		_on_level_up()

func _on_level_up() -> void:
	pass

func get_upgrade_description() -> String:
	return "Level %d: +25%% Damage, -10%% Cooldown" % (level + 1)

func find_nearest_enemy(max_dist: float = 30.0) -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var min_dist: float = max_dist * max_dist
	var p_pos = global_position
	
	for e in enemies:
		if is_instance_valid(e) and not (e.is_queued_for_deletion() if e.has_method("is_queued_for_deletion") else false):
			var d = p_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func find_enemies_in_range(radius: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var enemies = get_tree().get_nodes_in_group("enemies")
	var r2 = radius * radius
	var p_pos = global_position
	
	for e in enemies:
		if is_instance_valid(e):
			if p_pos.distance_squared_to(e.global_position) <= r2:
				result.append(e)
	return result
