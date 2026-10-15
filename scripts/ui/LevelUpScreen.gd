extends CanvasLayer

signal upgrade_selected()

@onready var cards_container: HBoxContainer = $CenterContainer/VBoxContainer/CardsContainer

var player: CharacterBody3D

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

func show_level_up(p_player: CharacterBody3D) -> void:
	player = p_player
	get_tree().paused = true
	visible = true
	
	for child in cards_container.get_children():
		child.queue_free()
	
	var options = _generate_options()
	for opt in options:
		var card = _create_card(opt)
		cards_container.add_child(card)

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

func _create_card(data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(250, 320)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	style_normal.border_color = data.get("color", Color(0, 1, 1))
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.14, 0.14, 0.24, 0.98)
	style_hover.border_color = Color.WHITE
	style_hover.set_border_width_all(3)
	style_hover.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", style_hover)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)
	
	var title = Label.new()
	title.text = data["name"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", data.get("color", Color(0, 1, 1)))
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var desc = Label.new()
	desc.text = data["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(desc)
	
	btn.pressed.connect(func(): _on_card_selected(data))
	return btn

func _on_card_selected(data: Dictionary) -> void:
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
	get_tree().paused = false
	upgrade_selected.emit()
