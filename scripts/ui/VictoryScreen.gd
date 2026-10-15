extends CanvasLayer

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var track_label: Label = $CenterContainer/VBoxContainer/TrackNameLabel
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var next_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/NextBtn
@onready var select_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/SelectBtn
@onready var replay_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/ReplayBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	next_btn.pressed.connect(_on_next_pressed)
	select_btn.pressed.connect(_on_select_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	UIThemeHelper.apply_synthwave_button_style(next_btn, UIThemeHelper.COLOR_EMERALD)
	UIThemeHelper.apply_synthwave_button_style(replay_btn, UIThemeHelper.COLOR_GOLD)
	UIThemeHelper.apply_synthwave_button_style(select_btn, UIThemeHelper.COLOR_CYAN)

func show_victory(track_title: String, survival_time: float, kills: int) -> void:
	get_tree().paused = true
	visible = true
	
	GameManager.mark_level_cleared(track_title, survival_time, kills)
	
	track_label.text = "TRACK CLEARED: " + track_title.to_upper()
	stats_label.text = "SURVIVAL TIME: %s\nYOKAI PURGED: %d" % [_format_time(survival_time), kills]
	AudioManager.play_sfx("level_up", 1.2)

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func _on_next_pressed() -> void:
	var cur_title = GameManager.current_track_info.get("title", "")
	var next_track = GameManager.get_next_track(cur_title)
	if not next_track.is_empty():
		GameManager.start_run(next_track)

func _on_select_pressed() -> void:
	GameManager.return_to_level_select()

func _on_replay_pressed() -> void:
	GameManager.start_run(GameManager.current_track_info)
