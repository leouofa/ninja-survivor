extends CanvasLayer

signal upgrade_selected()

@onready var cards_container: HBoxContainer = $CenterContainer/VBoxContainer/CardsContainer

var player: CharacterBody3D

const SHORTCUT_KEYS = ["U", "I", "O"]
const BORDER_SHADER = preload("res://shaders/card_border.gdshader")

var current_cards: Array[Dictionary] = []
var card_buttons: Array[Button] = []

const ALL_WEAPONS = [
	{"id": "shuriken", "name": "Cyber Shurikens", "path": "res://scripts/weapons/WeaponShuriken.gd", "desc": "Throws spinning neon shurikens."},
	{"id": "katana", "name": "Plasma Katana", "path": "res://scripts/weapons/WeaponKatana.gd", "desc": "360-degree cleaving energy slash."},
	{"id": "orbiters", "name": "Kitsune Orbiters", "path": "res://scripts/weapons/WeaponOrbiters.gd", "desc": "Circling plasma fireballs."},
	{"id": "kunai", "name": "EMP Kunai", "path": "res://scripts/weapons/WeaponKunai.gd", "desc": "Piercing targeted cyber blades."},
	{"id": "raijin", "name": "Raijin Coil", "path": "res://scripts/weapons/WeaponRaijin.gd", "desc": "Strikes enemies with violet lightning."}
]

const ALL_PASSIVES = [
	{"id": "speed", "name": "Chrono Thrusters", "desc": "+12% Movement Speed"},
	{"id": "damage", "name": "Overcharged Cores", "desc": "+20% Attack Damage"},
	{"id": "cooldown", "name": "Overclock Module", "desc": "-10% Weapon Cooldowns"},
	{"id": "magnet", "name": "Magnetic Field", "desc": "+35% Datacube Collection Radius"},
	{"id": "regen", "name": "Titanium Nanites", "desc": "+1.5 HP/s Armor Regeneration"}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var kc = event.keycode
		if kc == 0:
			kc = event.physical_keycode
		match kc:
			KEY_U:
				_select_card_by_index(0)
				if get_viewport():
					get_viewport().set_input_as_handled()
			KEY_I:
				_select_card_by_index(1)
				if get_viewport():
					get_viewport().set_input_as_handled()
			KEY_O:
				_select_card_by_index(2)
				if get_viewport():
					get_viewport().set_input_as_handled()

func _select_card_by_index(idx: int) -> void:
	if idx >= 0 and idx < current_cards.size():
		_on_card_selected(current_cards[idx])

func show_level_up(p_player: CharacterBody3D) -> void:
	player = p_player
	if is_inside_tree():
		get_tree().paused = true
	visible = true
	
	if not cards_container:
		cards_container = get_node_or_null("CenterContainer/VBoxContainer/CardsContainer")
	
	if cards_container:
		for child in cards_container.get_children():
			child.queue_free()
	
	current_cards = _generate_options()
	card_buttons.clear()
	for i in range(current_cards.size()):
		var card = _create_card(current_cards[i], i)
		cards_container.add_child(card)
		card_buttons.append(card)

func _generate_options() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	
	# Check weapon upgrades
	for w in player.active_weapons:
		if w.level < w.max_level:
			pool.append({
				"type": "weapon_upgrade",
				"id": w.weapon_name,
				"name": w.weapon_name,
				"desc": w.get_upgrade_description(),
				"weapon_ref": w,
				"color": Color(0.0, 1.0, 1.0)
			})
	
	# Check new weapons if player has under 4
	if player.active_weapons.size() < 4:
		for w_data in ALL_WEAPONS:
			var already_has = false
			for active_w in player.active_weapons:
				if active_w.weapon_name == w_data["name"]:
					already_has = true
					break
			if not already_has:
				pool.append({
					"type": "new_weapon",
					"id": w_data["id"],
					"name": "[NEW] " + w_data["name"],
					"desc": w_data["desc"],
					"path": w_data["path"],
					"color": Color(1.0, 0.1, 0.45)
				})
	
	# Passives
	for p in ALL_PASSIVES:
		var cur_lvl = player.active_passives.get(p["id"], 0)
		if cur_lvl < 5:
			pool.append({
				"type": "passive",
				"id": p["id"],
				"name": p["name"] + (" (Rank %d)" % (cur_lvl + 1)),
				"desc": p["desc"],
				"color": Color(0.8, 0.2, 1.0)
			})
	
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

func _create_card(data: Dictionary, index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(280, 340)
	
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)
	
	var card_color: Color = data.get("color", Color(0, 1, 1))
	
	# Animated border & cyberpunk background shader
	var bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	mat.shader = BORDER_SHADER
	mat.set_shader_parameter("border_color", card_color)
	mat.set_shader_parameter("background_color", Color(0.08, 0.08, 0.14, 0.95))
	mat.set_shader_parameter("border_width", 2.5)
	mat.set_shader_parameter("corner_radius", 10.0)
	mat.set_shader_parameter("speed", 2.5)
	mat.set_shader_parameter("beam_length", 0.28)
	mat.set_shader_parameter("pulse_intensity", 0.35)
	mat.set_shader_parameter("is_hovered", 0.0)
	mat.set_shader_parameter("rect_size", Vector2(280, 340))
	bg_rect.material = mat
	btn.add_child(bg_rect)
	
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pivot_offset = Vector2(140, 170)
	
	btn.mouse_entered.connect(func():
		mat.set_shader_parameter("is_hovered", 1.0)
		var tween = btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.15)
		var audio_node = btn.get_node_or_null("/root/AudioManager")
		if audio_node and audio_node.has_method("play_sfx"):
			audio_node.play_sfx("ui_hover", 1.1, -6.0)
	)
	btn.mouse_exited.connect(func():
		mat.set_shader_parameter("is_hovered", 0.0)
		var tween = btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	)
	
	# Margin container ensuring text has generous padding and never touches the border
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Top row with shortcut key badge on the top right
	var top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)
	
	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(top_spacer)
	
	if index < SHORTCUT_KEYS.size():
		var badge_panel = PanelContainer.new()
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_style = StyleBoxFlat.new()
		badge_style.bg_color = Color(0.12, 0.12, 0.22, 0.9)
		badge_style.border_color = card_color
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(6)
		badge_style.content_margin_left = 8
		badge_style.content_margin_right = 8
		badge_style.content_margin_top = 2
		badge_style.content_margin_bottom = 2
		badge_panel.add_theme_stylebox_override("panel", badge_style)
		
		var badge_label = Label.new()
		badge_label.text = SHORTCUT_KEYS[index]
		badge_label.add_theme_font_size_override("font_size", 13)
		badge_label.add_theme_color_override("font_color", card_color)
		badge_panel.add_child(badge_label)
		top_row.add_child(badge_panel)
	
	# Content container for title and description
	var content_vbox = VBoxContainer.new()
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_theme_constant_override("separation", 16)
	vbox.add_child(content_vbox)
	
	var title = Label.new()
	title.text = data["name"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", card_color)
	content_vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = data["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	content_vbox.add_child(desc)
	
	btn.pressed.connect(func(): _on_card_selected(data))
	return btn

func _on_card_selected(data: Dictionary) -> void:
	current_cards.clear()
	card_buttons.clear()
	
	match data["type"]:
		"weapon_upgrade":
			var w = data["weapon_ref"]
			if is_instance_valid(w) and w.has_method("upgrade"):
				w.upgrade()
		"new_weapon":
			player.add_weapon(data["path"])
		"passive":
			player.upgrade_passive(data["id"])
	
	visible = false
	if is_inside_tree():
		get_tree().paused = false
	upgrade_selected.emit()
