extends Control
## MainMenu - Main menu screen controller
## Provides options for New Game, Load, Settings, and Quit

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# Connect button signals
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if load_game_button:
		load_game_button.pressed.connect(_on_load_game_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Set initial focus
	if new_game_button:
		new_game_button.grab_focus()

func _on_new_game_pressed() -> void:
	# For now, start game with default settings
	# TODO: Show new game dialog for settings selection
	var settings = {
		"difficulty": "normal",
		"map_size": "normal",
		"ai_opponents": 3,
		"starting_faction": "survivors"
	}

	# Get UIManager from parent tree
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager and ui_manager.has_method("start_new_game"):
		ui_manager.start_new_game(settings)

func _on_load_game_pressed() -> void:
	# TODO: Show load game dialog
	# For now, try to load a test save
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager and ui_manager.has_method("load_game"):
		ui_manager.load_game("test_save")

func _on_settings_pressed() -> void:
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager and ui_manager.has_method("show_settings"):
		ui_manager.show_settings("main_menu")

func _on_quit_pressed() -> void:
	get_tree().quit()
