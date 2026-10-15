extends Control

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var tracks_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/TracksVBox
@onready var back_btn: Button = $MarginContainer/VBoxContainer/TopBar/BackBtn
@onready var now_playing_label: Label = $MarginContainer/VBoxContainer/BottomBar/NowPlayingLabel

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	UIThemeHelper.apply_synthwave_button_style(back_btn, UIThemeHelper.COLOR_CYAN)
	_populate_tracks()

func _populate_tracks() -> void:
	for child in tracks_container.get_children():
		child.queue_free()
	
	for i in range(GameManager.tracks_list.size()):
		var track = GameManager.tracks_list[i]
		var title = track["title"]
		var is_unlocked = GameManager.is_track_unlocked(title)
		var stats = GameManager.high_scores.get(title, {"best_time": 0.0, "cleared": false, "kills": 0})
		
		var card = _create_track_row(i + 1, track, is_unlocked, stats)
		tracks_container.add_child(card)

func _create_track_row(index: int, track: Dictionary, unlocked: bool, stats: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.12, 0.9) if unlocked else Color(0.03, 0.03, 0.06, 0.7)
	style.border_color = Color(0, 0.8, 1, 0.6) if unlocked else Color(0.3, 0.3, 0.4, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	
	# Number label
	var num_label = Label.new()
	num_label.text = "%02d." % index
	num_label.custom_minimum_size = Vector2(40, 0)
	num_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	num_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(num_label)
	
	# Track title & stats vbox
	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = track["title"]
	title_lbl.add_theme_font_size_override("font_size", 18)
	if unlocked:
		title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		title_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	title_vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	if unlocked:
		if stats.get("cleared", false):
			sub_lbl.text = "✓ CLEARED | Best Time: %s | Max Kills: %d" % [_format_time(stats.get("best_time", 0.0)), stats.get("kills", 0)]
			sub_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
		elif stats.get("best_time", 0.0) > 0.0:
			sub_lbl.text = "Best Survived: %s | Max Kills: %d" % [_format_time(stats.get("best_time", 0.0)), stats.get("kills", 0)]
			sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			sub_lbl.text = "Uncompleted"
			sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	else:
		sub_lbl.text = "🔒 LOCKED (Clear previous stage to unlock)"
		sub_lbl.add_theme_color_override("font_color", Color(0.5, 0.2, 0.2))
	sub_lbl.add_theme_font_size_override("font_size", 12)
	title_vbox.add_child(sub_lbl)
	
	# Preview button
	if unlocked:
		var preview_btn = Button.new()
		preview_btn.text = "♫ PREVIEW"
		preview_btn.custom_minimum_size = Vector2(100, 36)
		UIThemeHelper.apply_synthwave_button_style(preview_btn, UIThemeHelper.COLOR_MAGENTA)
		preview_btn.pressed.connect(func():
			AudioManager.play_track(track["path"])
			now_playing_label.text = "PREVIEWING: " + track["title"]
		)
		hbox.add_child(preview_btn)
		
		# Play Launch button
		var play_btn = Button.new()
		play_btn.text = "LAUNCH RUN"
		play_btn.custom_minimum_size = Vector2(140, 36)
		UIThemeHelper.apply_synthwave_button_style(play_btn, UIThemeHelper.COLOR_CYAN)
		play_btn.pressed.connect(func():
			GameManager.start_run(track)
		)
		hbox.add_child(play_btn)
	else:
		var lock_lbl = Label.new()
		lock_lbl.text = "LOCKED"
		lock_lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		hbox.add_child(lock_lbl)
		
	return panel

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func _on_back_pressed() -> void:
	AudioManager.stop_music()
	GameManager.return_to_main_menu()
