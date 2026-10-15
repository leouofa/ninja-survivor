extends Node3D

signal boss_spawned()
signal stage_cleared()

var enemy_base_script = preload("res://scripts/enemies/BaseEnemy.gd")

var spawn_timer: float = 0.0
var base_spawn_interval: float = 1.4
var spawn_radius: float = 24.0

var boss_has_spawned: bool = false
var stage_finished: bool = false

var player: CharacterBody3D

func _ready() -> void:
	AudioManager.music_finished.connect(_on_music_finished)
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _process(delta: float) -> void:
	if stage_finished:
		return
	
	var progress = AudioManager.get_progress_ratio()
	
	# Spawn boss at 75% track progress
	if progress >= 0.75 and not boss_has_spawned:
		_spawn_boss()
	
	# Adjust spawn rate based on track intensity
	var current_interval = base_spawn_interval
	if progress > 0.5:
		current_interval *= 0.65 # Faster in second half
	if progress > 0.75:
		current_interval *= 0.8
		
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = current_interval
		_spawn_wave(progress)

func _spawn_wave(progress: float) -> void:
	if not is_instance_valid(player):
		return
	
	var spawn_count = 1
	if progress > 0.3:
		spawn_count = 2
	if progress > 0.6:
		spawn_count = 3
	
	for i in range(spawn_count):
		var enemy_type = _select_enemy_type(progress)
		_spawn_enemy(enemy_type)

func _select_enemy_type(progress: float) -> String:
	var roll = randf()
	if progress < 0.25:
		return "chochin" if roll < 0.35 else "ronin"
	elif progress < 0.50:
		if roll < 0.35: return "tengu"
		elif roll < 0.70: return "kitsune"
		else: return "ronin"
	else:
		if roll < 0.3: return "oni"
		elif roll < 0.55: return "tengu"
		elif roll < 0.8: return "kitsune"
		else: return "ronin"

func _spawn_enemy(type: String) -> void:
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector3(cos(angle), 0, sin(angle)) * spawn_radius
	spawn_pos.y = 0.0
	
	var enemy = CharacterBody3D.new()
	enemy.set_script(enemy_base_script)
	enemy.enemy_type = type
	
	# Set stats based on archetype
	match type:
		"ronin":
			enemy.max_hp = 30.0
			enemy.speed = 4.2
			enemy.damage = 12.0
			enemy.xp_drop = 10
		"chochin":
			enemy.max_hp = 18.0
			enemy.speed = 5.2
			enemy.damage = 18.0
			enemy.xp_drop = 8
		"kitsune":
			enemy.max_hp = 40.0
			enemy.speed = 4.6
			enemy.damage = 14.0
			enemy.xp_drop = 15
		"tengu":
			enemy.max_hp = 32.0
			enemy.speed = 5.8
			enemy.damage = 15.0
			enemy.xp_drop = 14
		"oni":
			enemy.max_hp = 120.0
			enemy.speed = 2.8
			enemy.damage = 25.0
			enemy.xp_drop = 40
			enemy.scale = Vector3(1.3, 1.3, 1.3)
	
	# Collision shape
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	enemy.add_child(col)
	
	enemy.collision_layer = 2
	enemy.collision_mask = 1 | 2 # Player and enemies
	
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos

func _spawn_boss() -> void:
	boss_has_spawned = true
	boss_spawned.emit()
	AudioManager.play_sfx("boss_spawn", 1.0)
	
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector3(cos(angle), 0, sin(angle)) * (spawn_radius * 0.9)
	spawn_pos.y = 0.0
	
	var boss = CharacterBody3D.new()
	boss.set_script(enemy_base_script)
	boss.enemy_type = "boss"
	boss.is_boss = true
	boss.max_hp = 750.0
	boss.speed = 2.4
	boss.damage = 35.0
	boss.xp_drop = 200
	boss.scale = Vector3(1.8, 1.8, 1.8)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.0, 4.0, 3.0)
	col.shape = shape
	col.position = Vector3(0, 2.0, 0)
	boss.add_child(col)
	
	boss.collision_layer = 2
	boss.collision_mask = 1
	
	get_tree().current_scene.add_child(boss)
	boss.global_position = spawn_pos

func _on_music_finished() -> void:
	if not stage_finished:
		stage_finished = true
		stage_cleared.emit()
