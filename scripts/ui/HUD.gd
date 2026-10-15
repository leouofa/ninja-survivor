extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/BottomLeft/VBoxContainer/HPBar
@onready var hp_label: Label = $MarginContainer/BottomLeft/VBoxContainer/HPBar/HPLabel
@onready var xp_bar: ProgressBar = $MarginContainer/BottomLeft/VBoxContainer/XPBar
@onready var level_label: Label = $MarginContainer/BottomLeft/VBoxContainer/HBoxContainer/LevelLabel

@onready var track_label: Label = $MarginContainer/TopCenter/VBoxContainer/TrackTitleLabel
@onready var track_progress_bar: ProgressBar = $MarginContainer/TopCenter/VBoxContainer/TrackProgressBar
@onready var time_label: Label = $MarginContainer/TopCenter/VBoxContainer/HBoxContainer/TimeLabel

@onready var kills_label: Label = $MarginContainer/TopRight/HBoxContainer/KillsLabel
@onready var boss_banner: Label = $CenterContainer/BossBanner

var player: CharacterBody3D

func _ready() -> void:
	boss_banner.visible = false
	
	if not GameManager.current_track_info.is_empty():
		track_label.text = "TRACK: " + GameManager.current_track_info.get("title", "Unknown")
	
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
		player.hp_changed.connect(_on_hp_changed)
		player.xp_updated.connect(_on_xp_updated)
		_on_hp_changed(player.health, player.max_health)
		_on_xp_updated(player.current_xp, player.xp_needed, player.current_level)

func _process(_delta: float) -> void:
	# Update song progress
	var progress = AudioManager.get_progress_ratio()
	track_progress_bar.value = progress * 100.0
	
	var pos = AudioManager.get_playback_position()
	var total = AudioManager.get_track_duration()
	time_label.text = "%s / %s" % [_format_time(pos), _format_time(total)]
	
	kills_label.text = "KILLS: %d" % GameManager.player_kills

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func _on_hp_changed(cur: float, max_val: float) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = cur
	hp_label.text = "%d / %d HP" % [int(cur), int(max_val)]

func _on_xp_updated(cur: int, needed: int, lvl: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = cur
	level_label.text = "LEVEL %d" % lvl

func show_boss_alert() -> void:
	boss_banner.visible = true
	var tween = create_tween()
	boss_banner.modulate = Color(2.0, 0.2, 0.2, 1.0)
	tween.tween_property(boss_banner, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(boss_banner, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.set_loops(4)
	tween.tween_callback(func(): boss_banner.visible = false)
