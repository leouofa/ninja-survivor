extends CanvasLayer

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var track_label: Label = $CenterContainer/VBoxContainer/TrackNameLabel
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var high_score_label: Label = $CenterContainer/VBoxContainer/HighScoreLabel
@onready var career_label: Label = $CenterContainer/VBoxContainer/CareerLabel
@onready var return_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/ReturnBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if return_btn:
		return_btn.pressed.connect(_on_return_pressed)
		UIThemeHelper.apply_synthwave_button_style(return_btn, UIThemeHelper.COLOR_CYAN)

func show_completion(track_title: String, survival_time: float, kills: int) -> void:
	get_tree().paused = true
	visible = true
	
	var result = GameManager.mark_level_cleared(track_title, survival_time, kills)
	
	track_label.text = "FINAL MISSION: " + track_title.to_upper()
	stats_label.text = "SURVIVAL TIME: %s    |    YOKAI PURGED: %d" % [_format_time(survival_time), kills]
	
	_update_high_score_comparison(result, kills)
	
	var total_kills = GameManager.get_total_kills()
	career_label.text = "TOTAL CAREER YOKAI PURGED: %d" % total_kills
	
	AudioManager.play_sfx("level_up", 1.35)

func _update_high_score_comparison(result: Dictionary, kills: int) -> void:
	if result.get("is_first_record", false):
		high_score_label.text = "★ FIRST CLEAR RECORD: %d YOKAI ★" % kills
		high_score_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN)
	elif result.get("is_new_record", false):
		var diff = result.get("diff", 0)
		var prev = result.get("previous_kills", 0)
		high_score_label.text = "★ NEW HIGH SCORE! +%d YOKAI (PREV: %d) ★" % [diff, prev]
		high_score_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD)
	elif result.get("is_tie", false):
		high_score_label.text = "★ RECORD TIED: %d YOKAI ★" % kills
		high_score_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN)
	else:
		var prev = result.get("previous_kills", 0)
		var diff = result.get("diff", 0)
		high_score_label.text = "TRACK RECORD: %d YOKAI (%d)" % [prev, diff]
		high_score_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func _on_return_pressed() -> void:
	GameManager.return_to_main_menu()
