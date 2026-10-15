extends Control

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var start_btn: Button = $CenterContainer/VBoxContainer/VBoxButtons/StartBtn
@onready var select_btn: Button = $CenterContainer/VBoxContainer/VBoxButtons/SelectBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/VBoxButtons/QuitBtn

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	select_btn.pressed.connect(_on_select_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	UIThemeHelper.apply_synthwave_button_style(start_btn, UIThemeHelper.COLOR_CYAN)
	UIThemeHelper.apply_synthwave_button_style(select_btn, UIThemeHelper.COLOR_MAGENTA)
	UIThemeHelper.apply_synthwave_button_style(quit_btn, UIThemeHelper.COLOR_PURPLE)
	
	# Start ambient title synth music if not playing
	if not AudioManager.music_player.playing:
		if not GameManager.tracks_list.is_empty():
			# Play Olympus Mainframe or first track
			AudioManager.play_track(GameManager.tracks_list[0]["path"])

func _on_start_pressed() -> void:
	# Find first uncleared track or first track
	var target_track = GameManager.tracks_list[0] if not GameManager.tracks_list.is_empty() else {}
	for t in GameManager.tracks_list:
		if GameManager.is_track_unlocked(t["title"]):
			var stats = GameManager.high_scores.get(t["title"], {})
			if not stats.get("cleared", false):
				target_track = t
				break
	if not target_track.is_empty():
		GameManager.start_run(target_track)

func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
