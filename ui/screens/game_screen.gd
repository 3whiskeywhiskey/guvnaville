extends Control
## GameScreen - Main game screen controller
## Contains HUD, map view area, and handles game input

# Preload dependencies for Godot 4.5.1 compatibility
const InputHandler = preload("res://ui/input_handler.gd")
const TooltipHelper = preload("res://ui/common/tooltip_helper.gd")
const MapView = preload("res://ui/map/map_view.gd")

@onready var resource_bar: Control = $HUD/ResourceBar
@onready var turn_indicator: Control = $HUD/TurnIndicator
@onready var minimap: Control = $HUD/Minimap
@onready var notification_container: Control = $HUD/NotificationContainer
@onready var map_view_container: Control = $MapView
@onready var end_turn_button: Button = $HUD/EndTurnButton
@onready var hud: Control = $HUD

var input_handler = null  # InputHandler type removed for 4.5.1 compatibility
var map_view = null  # MapView instance (Node2D)
var sub_viewport: SubViewport = null  # Viewport to host Node2D content
var viewport_container: SubViewportContainer = null  # Container for SubViewport
var game_camera: Camera2D = null  # Camera at root level to control viewport

func _ready() -> void:
	# Set GameScreen to process input first (lower priority = earlier)
	process_priority = 0

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
	# Set InputHandler to process input after GameScreen
	input_handler.process_priority = 1

	# Connect end turn button
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect input handler signals
	if input_handler:
		input_handler.end_turn_requested.connect(_on_end_turn_requested)
		input_handler.action_requested.connect(_on_action_requested)

	# Setup tooltips
	_setup_tooltips()

	# Initialize map view
	_initialize_map_view()

	# Connect to game state signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.turn_started.connect(_on_turn_started)

	# If game already started before we connected, render now
	if GameManager.is_game_active and GameManager.current_state:
		print("[GameScreen] Game already active, rendering map now")
		_on_game_started(GameManager.current_state)

func _input(event: InputEvent) -> void:
	"""Forward mouse input to SubViewport BEFORE InputHandler consumes it"""
	if not sub_viewport or not viewport_container:
		return

	# Debug all mouse button events
	if event is InputEventMouseButton:
		print("[GameScreen] Received mouse button event: button=%d, pressed=%s" % [event.button_index, event.pressed])

	# Only forward mouse events that are over the viewport container
	if event is InputEventMouse:
		var local_pos = viewport_container.get_local_mouse_position()
		var rect = viewport_container.get_rect()

		# Check if mouse is within viewport container bounds
		if rect.has_point(local_pos):
			# Clone the event and adjust position for SubViewport
			var viewport_event = event.duplicate()
			if viewport_event is InputEventMouse:
				viewport_event.position = local_pos
				viewport_event.global_position = local_pos

			# Forward to SubViewport BEFORE InputHandler marks it as handled
			sub_viewport.push_input(viewport_event, true)

			# Log click forwarding
			if event is InputEventMouseButton:
				print("[GameScreen] Forwarded button=%d pressed=%s to SubViewport at %s" % [event.button_index, event.pressed, local_pos])

func _setup_tooltips() -> void:
	"""Add tooltips to HUD elements"""
	if end_turn_button:
		TooltipHelper.add_tooltip(end_turn_button,
			TooltipHelper.format_tooltip_with_shortcut("End Turn",
				TooltipHelper.TooltipTexts.END_TURN, "Space or Enter"))
	if turn_indicator:
		TooltipHelper.add_tooltip(turn_indicator, TooltipHelper.TooltipTexts.TURN_INDICATOR)
	if minimap:
		TooltipHelper.add_tooltip(minimap, TooltipHelper.TooltipTexts.MINIMAP)

func _on_end_turn_pressed() -> void:
	_on_end_turn_requested()

func _on_end_turn_requested() -> void:
	# Process end of turn through TurnManager
	if GameManager.is_game_active and not GameManager.is_paused:
		print("[GameScreen] End turn requested")

		# End turn through TurnManager
		TurnManager.process_turn()

		# Show notification
		UIManager.show_notification("Turn ended", "info")
	else:
		print("[GameScreen] Cannot end turn - game not active or paused")

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

func _initialize_map_view() -> void:
	"""Create and initialize the MapView"""
	print("[GameScreen] Initializing MapView...")

	if not map_view_container:
		push_error("[GameScreen] MapView container not found!")
		return

	# Clear placeholder
	for child in map_view_container.get_children():
		child.queue_free()

	# Create SubViewportContainer to host Node2D content properly
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.stretch_shrink = 1
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP  # Stop to handle input

	# Create SubViewport
	sub_viewport = SubViewport.new()
	sub_viewport.size = get_viewport().size
	sub_viewport.transparent_bg = true
	sub_viewport.handle_input_locally = true  # Process mouse input internally
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.gui_disable_input = false  # Enable GUI input

	# Create MapView (Node2D with Camera2D)
	map_view = MapView.new()

	# Build hierarchy: Container -> SubViewport -> MapView
	sub_viewport.add_child(map_view)
	viewport_container.add_child(sub_viewport)
	map_view_container.add_child(viewport_container)

	# Get camera reference
	if map_view.camera_controller:
		game_camera = map_view.camera_controller
		game_camera.enabled = true
		game_camera.make_current()

		print("[GameScreen] MapView in SubViewport - camera enabled: %s, current: %s, viewport size: %s" % [
			game_camera.enabled,
			game_camera.is_current(),
			sub_viewport.size
		])

	# Connect viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	print("[GameScreen] MapView created in SubViewport")

func _on_viewport_size_changed() -> void:
	"""Update SubViewport size when main viewport changes"""
	if sub_viewport:
		sub_viewport.size = get_viewport().size
		print("[GameScreen] SubViewport resized to: %s" % sub_viewport.size)

func _on_game_started(game_state) -> void:
	"""Called when a new game starts - render the map"""
	print("[GameScreen] Game started, rendering map...")

	if not map_view:
		push_error("[GameScreen] MapView not initialized!")
		return

	# Get world state from game manager
	if not GameManager.current_state:
		push_error("[GameScreen] No active game state!")
		return

	var world_state = GameManager.current_state.world_state
	if not world_state:
		push_error("[GameScreen] World state not found!")
		return

	# Render the map
	print("[GameScreen] Rendering map with %d tiles" % world_state.tiles.size())
	map_view.render_map(world_state)

	# Render units (if any)
	var units = []
	for faction in GameManager.current_state.factions:
		units.append_array(faction.units)

	if units.size() > 0:
		print("[GameScreen] Rendering %d units" % units.size())
		map_view.render_units(units)

	# Render fog of war for player faction
	var player_faction = GameManager.current_state.get_player_faction()
	if player_faction:
		var visible_tiles = world_state.get_visible_tiles(player_faction.faction_id)
		print("[GameScreen] Rendering fog of war with %d visible tiles" % visible_tiles.size())
		map_view.render_fog_of_war(player_faction.faction_id, visible_tiles)

		# Center camera on player's visible area
		if visible_tiles.size() > 0 and visible_tiles[0] is Vector3i:
			var center_tile = visible_tiles[visible_tiles.size() / 2]
			print("[GameScreen] Centering camera on tile: %s" % center_tile)
			map_view.center_camera_on(center_tile)

	print("[GameScreen] Map rendering complete!")
	print("[GameScreen] Try using WASD/Arrow keys to move camera, mouse wheel to zoom, click tiles to select")

func _on_turn_started(turn_number: int, faction_id: int) -> void:
	"""Called when a turn starts - update fog of war if it's player's turn"""
	if not map_view or not GameManager.current_state:
		return

	var player_faction = GameManager.current_state.get_player_faction()
	if player_faction and faction_id == player_faction.faction_id:
		# Update fog of war for player
		var visible_tiles = GameManager.current_state.world_state.get_visible_tiles(player_faction.faction_id)
		map_view.render_fog_of_war(player_faction.faction_id, visible_tiles)
