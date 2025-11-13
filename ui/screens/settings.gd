extends Control
## Settings - Settings screen controller
## Provides options for audio, graphics, and controls

@onready var back_button: Button = $VBoxContainer/BackButton
@onready var audio_slider: HSlider = $VBoxContainer/AudioSettings/VolumeSlider
@onready var fullscreen_check: CheckButton = $VBoxContainer/DisplaySettings/FullscreenCheck

var return_to: String = "main_menu"

func _ready() -> void:
	# Load current settings
	_load_settings()

	# Connect button signals
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	if audio_slider:
		audio_slider.value_changed.connect(_on_audio_changed)

	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Set initial focus
	if back_button:
		back_button.grab_focus()

func _load_settings() -> void:
	# Load settings from config
	# For now, use default values
	if audio_slider:
		audio_slider.value = 70

	if fullscreen_check:
		fullscreen_check.button_pressed = false

func _save_settings() -> void:
	# Save settings to config
	# TODO: Implement proper settings persistence
	pass

func _on_back_pressed() -> void:
	_save_settings()

	# Return to previous screen
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager and ui_manager.has_method("transition_to_screen"):
		if ui_manager.return_to_screen == "game":
			ui_manager.show_game_screen()
		else:
			ui_manager.show_main_menu()

func _on_audio_changed(value: float) -> void:
	# Update audio volume
	# TODO: Apply to AudioServer
	pass

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	# Toggle fullscreen
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
