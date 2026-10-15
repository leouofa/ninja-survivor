class_name UIThemeHelper
extends RefCounted

const COLOR_CYAN = Color(0.0, 1.0, 1.0)
const COLOR_MAGENTA = Color(1.0, 0.1, 0.55)
const COLOR_PURPLE = Color(0.75, 0.25, 1.0)
const COLOR_GOLD = Color(1.0, 0.82, 0.2)
const COLOR_EMERALD = Color(0.1, 1.0, 0.65)

static func apply_synthwave_button_style(btn: Button, accent_color: Color = COLOR_CYAN, play_sound: bool = true) -> void:
	if not is_instance_valid(btn):
		return
	
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Normal state: dark cyber indigo fill with subtle neon edge
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.05, 0.12, 0.92)
	normal_style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.55)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal_style)
	
	# Hover state: vibrant neon border glow with deep purple fill & shadow
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.09, 0.25, 0.98)
	hover_style.border_color = accent_color
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	hover_style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.4)
	hover_style.shadow_size = 5
	btn.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed state: active neon flash
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.22, 0.12, 0.36, 1.0)
	pressed_style.border_color = Color.WHITE
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	# Focus state: clean outline
	var focus_style = StyleBoxFlat.new()
	focus_style.draw_center = false
	focus_style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.7)
	focus_style.set_border_width_all(1)
	focus_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("focus", focus_style)
	
	# Disabled state
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.04, 0.04, 0.07, 0.6)
	disabled_style.border_color = Color(0.25, 0.25, 0.3, 0.4)
	disabled_style.set_border_width_all(1)
	disabled_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	
	# Typography styling
	btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", accent_color)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.42, 0.5, 0.65))
	btn.add_theme_color_override("font_hover_shadow_color", Color(accent_color.r, accent_color.g, accent_color.b, 0.8))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)
	
	if play_sound:
		if not btn.mouse_entered.is_connected(_on_button_hovered):
			btn.mouse_entered.connect(_on_button_hovered)

static func _on_button_hovered() -> void:
	var main_loop = Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.root:
		var audio_node = main_loop.root.get_node_or_null("AudioManager")
		if audio_node and audio_node.has_method("play_sfx"):
			audio_node.play_sfx("ui_hover", 1.0, -8.0)
