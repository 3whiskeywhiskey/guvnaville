extends Node
## UIManager - Main UI orchestration singleton
## Manages screen transitions, HUD updates, and dialog display
## Read-only access to game state via signals

signal screen_changed(screen_name: String)
signal notification_shown(message: String, type: String)

var current_screen: Node = null
var current_screen_name: String = ""
var game_state: RefCounted = null  # Reference to GameState (read-only)
var is_initialized: bool = false

# Screen references
var main_menu_scene: PackedScene = null
var game_screen_scene: PackedScene = null
var settings_scene: PackedScene = null

# Return screen for settings
var return_to_screen: String = "main_menu"

# HUD component references (set by game_screen)
var resource_bar: Control = null
var turn_indicator: Control = null
var minimap: Control = null
var notification_manager: Node = null

func _ready() -> void:
	# Load screen scenes
	main_menu_scene = load("res://ui/screens/main_menu.tscn")
	game_screen_scene = load("res://ui/screens/game_screen.tscn")
	settings_scene = load("res://ui/screens/settings.tscn")

## Initialize UI system with game state reference
func initialize(p_game_state: RefCounted) -> void:
	if is_initialized:
		push_error("UIManager already initialized. Call cleanup() first.")
		return

	game_state = p_game_state
	is_initialized = true

## Clean up UI system, disconnect signals
func cleanup() -> void:
	if current_screen:
		current_screen.queue_free()
		current_screen = null

	game_state = null
	is_initialized = false
	resource_bar = null
	turn_indicator = null
	minimap = null
	notification_manager = null

## Display main menu screen
func show_main_menu() -> void:
	_transition_to_screen("main_menu", main_menu_scene)

## Display main game screen with HUD
func show_game_screen() -> void:
	_transition_to_screen("game", game_screen_scene)

## Display settings screen
func show_settings(p_return_to_screen: String = "main_menu") -> void:
	return_to_screen = p_return_to_screen
	_transition_to_screen("settings", settings_scene)

## Transition to a screen with optional animation
func transition_to_screen(screen_name: String, transition_type: String = "fade") -> void:
	# For now, just do instant transitions
	# TODO: Implement fade/slide animations
	match screen_name:
		"main_menu":
			show_main_menu()
		"game":
			show_game_screen()
		"settings":
			show_settings()
		_:
			push_error("Unknown screen: " + screen_name)

## Initialize UI for new game session
func start_new_game(settings: Dictionary) -> void:
	if not settings.has("difficulty") or not settings.has("map_size") or \
	   not settings.has("ai_opponents") or not settings.has("starting_faction"):
		push_error("Invalid game settings: missing required keys")
		return

	show_game_screen()
	screen_changed.emit("game")

## Initialize UI for loaded game
func load_game(save_name: String) -> bool:
	if save_name.is_empty():
		return false

	show_game_screen()
	show_notification("Game loaded: " + save_name, "success")
	return true

## Update all HUD elements with current game state
func update_hud(p_game_state: RefCounted) -> void:
	if not is_initialized:
		return

	# HUD components will update themselves via signals
	# This is a manual update method for edge cases

## Update resource display for specific faction
func update_resources(faction_id: int, resources: Dictionary) -> void:
	if resource_bar and faction_id == 0:  # Player faction
		resource_bar.update_resources(resources)

## Update turn counter and phase indicator
func update_turn_indicator(turn_number: int, phase: String, active_faction: int) -> void:
	if turn_indicator:
		turn_indicator.update_turn(turn_number, phase, active_faction)

## Display event dialog with choices
func show_event_dialog(event: Dictionary) -> void:
	# Event dialog will be instantiated as a popup
	var dialog_scene = load("res://ui/dialogs/event_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	add_child(dialog)
	dialog.show_event(event)

## Display combat result summary
func show_combat_result(result: Dictionary) -> void:
	var dialog_scene = load("res://ui/dialogs/combat_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	add_child(dialog)
	dialog.show_result(result)

## Display production queue dialog
func show_production_queue(faction_id: int) -> void:
	var dialog_scene = load("res://ui/dialogs/production_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	add_child(dialog)
	dialog.show_queue(faction_id)

## Display temporary notification message
func show_notification(message: String, type: String = "info", duration: float = 3.0) -> void:
	if notification_manager:
		notification_manager.show_notification(message, type, duration)
	notification_shown.emit(message, type)

## Display tooltip at mouse position
func show_tooltip(text: String, position: Vector2) -> void:
	# TODO: Implement tooltip system
	pass

## Hide currently displayed tooltip
func hide_tooltip() -> void:
	# TODO: Implement tooltip system
	pass

## Internal: Transition to a new screen
func _transition_to_screen(screen_name: String, scene: PackedScene) -> void:
	# Remove current screen
	if current_screen:
		current_screen.queue_free()
		current_screen = null

	# Load new screen
	if scene:
		current_screen = scene.instantiate()
		add_child(current_screen)
		current_screen_name = screen_name
		screen_changed.emit(screen_name)
