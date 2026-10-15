extends CanvasLayer

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var track_label: Label = $CenterContainer/VBoxContainer/TrackNameLabel
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var retry_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/RetryBtn
@onready var select_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/SelectBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_btn.pressed.connect(_on_retry_pressed)
	select_btn.pressed.connect(_on_select_pressed)
	UIThemeHelper.apply_synthwave_button_style(retry_btn, UIThemeHelper.COLOR_MAGENTA)
	UIThemeHelper.apply_synthwave_button_style(select_btn, UIThemeHelper.COLOR_CYAN)

func show_game_over(track_title: String, survival_time: float, kills: int) -> void:
	get_tree().paused = true
	visible = true
	
	GameManager.record_run_stats(survival_time, kills)
	
	track_label.text = "TRACK: " + track_title.to_upper()
	stats_label.text = "SURVIVED: %s\nYOKAI PURGED: %d" % [_format_time(survival_time), kills]
	AudioManager.play_sfx("enemy_hit", 0.5)

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func _on_retry_pressed() -> void:
	GameManager.start_run(GameManager.current_track_info)

func _on_select_pressed() -> void:
	GameManager.return_to_level_select()
