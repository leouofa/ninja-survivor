extends Control

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var back_btn: Button = $MarginContainer/VBoxContainer/TopBar/BackBtn
@onready var total_kills_label: Label = $MarginContainer/VBoxContainer/TopBar/TotalKillsLabel
@onready var scores_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ScoresVBox

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	UIThemeHelper.apply_synthwave_button_style(back_btn, UIThemeHelper.COLOR_CYAN)
	_update_header()
	_populate_scores()

func _update_header() -> void:
	var total = GameManager.get_total_kills()
	total_kills_label.text = "TOTAL PURGED: %d YOKAI" % total

func _populate_scores() -> void:
	for child in scores_container.get_children():
		child.queue_free()
	
	var records = GameManager.get_high_scores_sorted()
	
	if records.is_empty():
		var empty_panel = _create_empty_state()
		scores_container.add_child(empty_panel)
		return
	
	for i in range(records.size()):
		var record = records[i]
		var card = _create_score_row(i + 1, record)
		scores_container.add_child(card)

func _create_empty_state() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.8)
	style.border_color = Color(0.4, 0.2, 0.6, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var lbl1 = Label.new()
	lbl1.text = "NO MISSION RECORDS ARCHIVED YET"
	lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl1.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD)
	lbl1.add_theme_font_size_override("font_size", 20)
	vbox.add_child(lbl1)
	
	var lbl2 = Label.new()
	lbl2.text = "Launch missions from Mission Select or Start Campaign to register your kill records."
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	lbl2.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl2)
	
	return panel

func _create_score_row(rank: int, record: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.1, 0.9)
	
	# Accent color by rank
	var rank_color: Color
	match rank:
		1:
			rank_color = UIThemeHelper.COLOR_GOLD
		2:
			rank_color = UIThemeHelper.COLOR_CYAN
		3:
			rank_color = UIThemeHelper.COLOR_MAGENTA
		_:
			rank_color = Color(0.5, 0.4, 0.7)
	
	style.border_color = Color(rank_color.r, rank_color.g, rank_color.b, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Rank badge
	var rank_lbl = Label.new()
	rank_lbl.text = "#%02d" % rank
	rank_lbl.custom_minimum_size = Vector2(50, 0)
	rank_lbl.add_theme_color_override("font_color", rank_color)
	rank_lbl.add_theme_font_size_override("font_size", 22)
	hbox.add_child(rank_lbl)
	
	# Title & details VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = record.get("title", "UNKNOWN MISSION")
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	info_vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	var cleared = record.get("cleared", false)
	var time_str = _format_time(record.get("best_time", 0.0))
	if cleared:
		sub_lbl.text = "✓ STAGE CLEARED | Best Time: %s" % time_str
		sub_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_EMERALD)
	else:
		sub_lbl.text = "CASUALTY AT %s" % time_str
		sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	sub_lbl.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(sub_lbl)
	
	# Kills badge on right
	var kills_vbox = VBoxContainer.new()
	kills_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(kills_vbox)
	
	var kills_lbl = Label.new()
	kills_lbl.text = "%d YOKAI" % record.get("kills", 0)
	kills_lbl.add_theme_color_override("font_color", rank_color)
	kills_lbl.add_theme_font_size_override("font_size", 20)
	kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kills_vbox.add_child(kills_lbl)
	
	var kills_sub = Label.new()
	kills_sub.text = "RECORD KILLS"
	kills_sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	kills_sub.add_theme_font_size_override("font_size", 11)
	kills_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kills_vbox.add_child(kills_sub)
	
	return panel

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()
