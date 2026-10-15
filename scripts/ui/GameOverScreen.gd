extends CanvasLayer

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var track_label: Label = $CenterContainer/VBoxContainer/TrackNameLabel
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var high_score_label: Label = $CenterContainer/VBoxContainer/HighScoreLabel
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
	
	var result = GameManager.record_run_result(track_title, survival_time, kills, false)
	
	track_label.text = "TRACK: " + track_title.to_upper()
	stats_label.text = "SURVIVED: %s\nYOKAI PURGED: %d" % [_format_time(survival_time), kills]
	
	_update_high_score_comparison(result, kills)
	AudioManager.play_sfx("enemy_hit", 0.5)

func _update_high_score_comparison(result: Dictionary, kills: int) -> void:
	if result.get("is_first_record", false):
		high_score_label.text = "★ FIRST RUN RECORD: %d YOKAI ★" % kills
		high_score_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN)
	elif result.get("is_new_record", false):
		var diff = result.get("diff", 0)
		var prev = result.get("previous_kills", 0)
		high_score_label.text = "★ NEW RECORD: %d YOKAI (+%d OVER PREV: %d) ★" % [kills, diff, prev]
		high_score_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD)
	elif result.get("is_tie", false):
		high_score_label.text = "★ RECORD TIED: %d YOKAI ★" % kills
		high_score_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN)
	else:
		var prev = result.get("previous_kills", 0)
		var diff = result.get("diff", 0)
		high_score_label.text = "TRACK HIGH SCORE: %d YOKAI (%d)" % [prev, diff]
		high_score_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))

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
