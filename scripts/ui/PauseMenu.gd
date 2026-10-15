extends CanvasLayer

const UIThemeHelper = preload("res://scripts/ui/UIThemeHelper.gd")

@onready var track_label: Label = $CenterContainer/VBoxContainer/TrackNameLabel
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel

@onready var main_buttons_vbox: VBoxContainer = $CenterContainer/VBoxContainer/MainButtonsVBox
@onready var resume_btn: Button = $CenterContainer/VBoxContainer/MainButtonsVBox/ResumeBtn
@onready var restart_btn: Button = $CenterContainer/VBoxContainer/MainButtonsVBox/RestartBtn
@onready var main_menu_btn: Button = $CenterContainer/VBoxContainer/MainButtonsVBox/MainMenuBtn

@onready var confirm_vbox: VBoxContainer = $CenterContainer/VBoxContainer/ConfirmVBox
@onready var confirm_prompt_label: Label = $CenterContainer/VBoxContainer/ConfirmVBox/ConfirmPromptLabel
@onready var confirm_btn: Button = $CenterContainer/VBoxContainer/ConfirmVBox/ConfirmButtonsHBox/ConfirmBtn
@onready var cancel_btn: Button = $CenterContainer/VBoxContainer/ConfirmVBox/ConfirmButtonsHBox/CancelBtn

enum PendingAction {
	NONE,
	RESTART,
	MAIN_MENU
}

var pending_action: PendingAction = PendingAction.NONE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	
	UIThemeHelper.apply_synthwave_button_style(resume_btn, UIThemeHelper.COLOR_CYAN)
	UIThemeHelper.apply_synthwave_button_style(restart_btn, UIThemeHelper.COLOR_MAGENTA)
	UIThemeHelper.apply_synthwave_button_style(main_menu_btn, UIThemeHelper.COLOR_PURPLE)
	UIThemeHelper.apply_synthwave_button_style(confirm_btn, UIThemeHelper.COLOR_MAGENTA)
	UIThemeHelper.apply_synthwave_button_style(cancel_btn, UIThemeHelper.COLOR_CYAN)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		if pending_action != PendingAction.NONE:
			_show_main_buttons()
		else:
			close_pause_menu()
		if get_viewport():
			get_viewport().set_input_as_handled()

func open_pause_menu(track_title: String, run_time: float, kills: int) -> void:
	track_label.text = "TRACK: " + track_title.to_upper()
	stats_label.text = "SURVIVED: %s | YOKAI PURGED: %d" % [_format_time(run_time), kills]
	_show_main_buttons()
	visible = true
	get_tree().paused = true
	AudioManager.pause_music()
	resume_btn.grab_focus()

func close_pause_menu() -> void:
	visible = false
	get_tree().paused = false
	AudioManager.resume_music()

func _show_main_buttons() -> void:
	pending_action = PendingAction.NONE
	confirm_vbox.visible = false
	main_buttons_vbox.visible = true
	resume_btn.grab_focus()

func _show_confirmation(action: PendingAction, prompt_text: String) -> void:
	pending_action = action
	confirm_prompt_label.text = prompt_text
	main_buttons_vbox.visible = false
	confirm_vbox.visible = true
	cancel_btn.grab_focus()

func _on_resume_pressed() -> void:
	close_pause_menu()

func _on_restart_pressed() -> void:
	_show_confirmation(PendingAction.RESTART, "Restart level?\nCurrent run progress will be lost.")

func _on_main_menu_pressed() -> void:
	_show_confirmation(PendingAction.MAIN_MENU, "Exit to Main Menu?\nCurrent run progress will be lost.")

func _on_confirm_pressed() -> void:
	var action = pending_action
	close_pause_menu()
	if action == PendingAction.RESTART:
		GameManager.start_run(GameManager.current_track_info)
	elif action == PendingAction.MAIN_MENU:
		GameManager.return_to_main_menu()

func _on_cancel_pressed() -> void:
	_show_main_buttons()

func _format_time(seconds: float) -> String:
	var total_sec = int(seconds)
	@warning_ignore("integer_division")
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]
