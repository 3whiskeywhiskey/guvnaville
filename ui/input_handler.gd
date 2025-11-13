class_name InputHandler
extends Node
## InputHandler - Handles all player input and translates to game commands
## Processes input events and dispatches actions via signals

signal action_requested(action_type: String, params: Dictionary)
signal tile_selected(position: Vector3i)
signal unit_move_requested(unit_id: String, destination: Vector3i)
signal unit_attack_requested(attacker_id: String, target_id: String)
signal end_turn_requested()

enum InputMode {
	MENU,      # Menu navigation
	GAME,      # In-game controls
	DIALOG,    # Dialog interaction
	DISABLED   # Input disabled
}

var current_mode: InputMode = InputMode.MENU
var enabled_actions: Dictionary = {}

func _ready() -> void:
	set_process_input(true)
	_update_enabled_actions()

## Process input event and dispatch actions
func _input(event: InputEvent) -> void:
	if current_mode == InputMode.DISABLED:
		return

	# Camera controls (only in game mode)
	if current_mode == InputMode.GAME:
		if event.is_action_pressed("camera_zoom_in"):
			action_requested.emit("camera_zoom_in", {})
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("camera_zoom_out"):
			action_requested.emit("camera_zoom_out", {})
			get_viewport().set_input_as_handled()

		# End turn
		if event.is_action_pressed("end_turn"):
			end_turn_requested.emit()
			get_viewport().set_input_as_handled()

		# Mouse selection
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_action_enabled("select_tile"):
				# Will emit tile_selected signal when tile position is determined
				action_requested.emit("select", {"position": event.position})
				get_viewport().set_input_as_handled()

	# UI navigation (all modes except disabled)
	if event.is_action_pressed("ui_cancel"):
		action_requested.emit("cancel", {})
		get_viewport().set_input_as_handled()

## Check if input action is currently enabled
func is_action_enabled(action: String) -> bool:
	return enabled_actions.get(action, false)

## Set input mode (affects which actions are active)
func set_input_mode(mode: InputMode) -> void:
	current_mode = mode
	_update_enabled_actions()

## Update enabled actions based on current mode
func _update_enabled_actions() -> void:
	enabled_actions.clear()

	match current_mode:
		InputMode.MENU:
			enabled_actions["ui_up"] = true
			enabled_actions["ui_down"] = true
			enabled_actions["ui_left"] = true
			enabled_actions["ui_right"] = true
			enabled_actions["ui_accept"] = true
			enabled_actions["ui_cancel"] = true

		InputMode.GAME:
			enabled_actions["camera_pan_up"] = true
			enabled_actions["camera_pan_down"] = true
			enabled_actions["camera_pan_left"] = true
			enabled_actions["camera_pan_right"] = true
			enabled_actions["camera_zoom_in"] = true
			enabled_actions["camera_zoom_out"] = true
			enabled_actions["select_tile"] = true
			enabled_actions["end_turn"] = true
			enabled_actions["ui_cancel"] = true

		InputMode.DIALOG:
			enabled_actions["ui_up"] = true
			enabled_actions["ui_down"] = true
			enabled_actions["ui_accept"] = true
			enabled_actions["ui_cancel"] = true

		InputMode.DISABLED:
			pass  # No actions enabled

## Enable specific action
func enable_action(action: String) -> void:
	enabled_actions[action] = true

## Disable specific action
func disable_action(action: String) -> void:
	enabled_actions[action] = false
