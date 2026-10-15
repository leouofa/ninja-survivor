extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Camera3D
@onready var spawner: Node3D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var level_up_screen: CanvasLayer = $LevelUpScreen
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var pause_menu: CanvasLayer = $PauseMenu

var run_time: float = 0.0

func _ready() -> void:
	# Ensure game is unpaused
	get_tree().paused = false
	
	# Connect player signals
	if player:
		player.leveled_up.connect(_on_player_leveled_up)
		player.player_died.connect(_on_player_died)
	
	# Connect spawner signals
	if spawner:
		spawner.player = player
		spawner.boss_spawned.connect(_on_boss_spawned)
		spawner.stage_cleared.connect(_on_stage_cleared)
	
	# Play current track
	if not GameManager.current_track_info.is_empty():
		var path = GameManager.current_track_info.get("path", "")
		AudioManager.play_track(path)
	elif not GameManager.tracks_list.is_empty():
		GameManager.current_track_info = GameManager.tracks_list[0]
		AudioManager.play_track(GameManager.current_track_info["path"])

func _process(delta: float) -> void:
	if not get_tree().paused:
		run_time += delta
		GameManager.run_elapsed_time = run_time
	
	# Escape / Pause
	if Input.is_action_just_pressed("pause") and not level_up_screen.visible and not victory_screen.visible and not game_over_screen.visible:
		var title = GameManager.current_track_info.get("title", "Mission")
		pause_menu.open_pause_menu(title, run_time, GameManager.player_kills)

func _on_player_leveled_up(_new_lvl: int) -> void:
	level_up_screen.show_level_up(player)

func _on_player_died() -> void:
	var title = GameManager.current_track_info.get("title", "Mission")
	game_over_screen.show_game_over(title, run_time, GameManager.player_kills)

func _on_boss_spawned() -> void:
	hud.show_boss_alert()
	camera.add_shake(1.2)

func _on_stage_cleared() -> void:
	var title = GameManager.current_track_info.get("title", "Mission")
	victory_screen.show_victory(title, run_time, GameManager.player_kills)
