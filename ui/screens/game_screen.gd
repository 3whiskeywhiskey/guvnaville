extends Control
## GameScreen - Main game screen controller
## Contains HUD, map view area, and handles game input

@onready var resource_bar: Control = $HUD/ResourceBar
@onready var turn_indicator: Control = $HUD/TurnIndicator
@onready var minimap: Control = $HUD/Minimap
@onready var notification_container: Control = $HUD/NotificationContainer
@onready var map_view: Control = $MapView
@onready var end_turn_button: Button = $HUD/EndTurnButton

var input_handler: InputHandler = null

func _ready() -> void:
	# Register HUD components with UIManager
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager:
		ui_manager.resource_bar = resource_bar
		ui_manager.turn_indicator = turn_indicator
		ui_manager.minimap = minimap
		if notification_container and notification_container.has_method("show_notification"):
			ui_manager.notification_manager = notification_container

	# Create and setup input handler
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.set_input_mode(InputHandler.InputMode.GAME)

	# Connect end turn button
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect input handler signals
	if input_handler:
		input_handler.end_turn_requested.connect(_on_end_turn_requested)
		input_handler.action_requested.connect(_on_action_requested)

func _on_end_turn_pressed() -> void:
	_on_end_turn_requested()

func _on_end_turn_requested() -> void:
	# Emit signal to game systems via EventBus (if available)
	# For now, just show a notification
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager and ui_manager.has_method("show_notification"):
		ui_manager.show_notification("Turn ended", "info")

func _on_action_requested(action_type: String, params: Dictionary) -> void:
	# Handle various action requests
	match action_type:
		"select":
			# Handle tile selection
			pass
		"cancel":
			# Show pause menu or cancel current action
			_show_pause_menu()
		_:
			pass

func _show_pause_menu() -> void:
	# TODO: Implement pause menu
	var ui_manager = get_node("/root/UIManager") if has_node("/root/UIManager") else get_parent()
	if ui_manager and ui_manager.has_method("show_settings"):
		ui_manager.show_settings("game")
