extends Node
class_name TutorialManager

## Manages the tutorial flow and state
## Loads tutorial steps, tracks progress, and coordinates with the game

signal tutorial_started()
signal tutorial_step_changed(step: TutorialStep)
signal tutorial_completed()
signal tutorial_skipped()

const TUTORIAL_DATA_PATH := "res://data/tutorial/tutorial_steps.json"
const SAVE_KEY := "tutorial_completed"

var tutorial_steps: Array[TutorialStep] = []
var current_step_index: int = -1
var is_active: bool = false
var is_paused: bool = false
var tutorial_overlay: Control = null

@onready var game_state: Node = get_node("/root/GameState") if has_node("/root/GameState") else null

func _ready() -> void:
	load_tutorial_data()

func load_tutorial_data() -> void:
	"""Load tutorial steps from JSON file"""
	var file := FileAccess.open(TUTORIAL_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load tutorial data from: " + TUTORIAL_DATA_PATH)
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("Failed to parse tutorial JSON: " + json.get_error_message())
		return

	var data: Dictionary = json.data
	if not data.has("steps"):
		push_error("Tutorial JSON missing 'steps' array")
		return

	tutorial_steps.clear()
	for step_data in data["steps"]:
		tutorial_steps.append(TutorialStep.new(step_data))

	print("Loaded %d tutorial steps" % tutorial_steps.size())

func should_start_tutorial() -> bool:
	"""Check if tutorial should start (first time player)"""
	if has_completed_tutorial():
		return false

	# Check if this is a new game
	if game_state and game_state.has_method("is_new_game"):
		return game_state.is_new_game()

	return true

func has_completed_tutorial() -> bool:
	"""Check if player has completed tutorial before"""
	var config := ConfigFile.new()
	var err := config.load("user://settings.cfg")
	if err != OK:
		return false

	return config.get_value("tutorial", SAVE_KEY, false)

func mark_tutorial_completed() -> void:
	"""Save that tutorial has been completed"""
	var config := ConfigFile.new()
	config.load("user://settings.cfg")  # Load existing settings
	config.set_value("tutorial", SAVE_KEY, true)
	config.save("user://settings.cfg")

func start_tutorial() -> void:
	"""Start the tutorial from the beginning"""
	if tutorial_steps.is_empty():
		push_error("Cannot start tutorial: no steps loaded")
		return

	is_active = true
	current_step_index = -1
	tutorial_started.emit()
	next_step()

func next_step() -> void:
	"""Move to the next tutorial step"""
	if not is_active:
		return

	current_step_index += 1

	if current_step_index >= tutorial_steps.size():
		complete_tutorial()
		return

	var step := tutorial_steps[current_step_index]

	# Check conditions
	var current_game_state := get_game_state()
	if not step.check_conditions(current_game_state):
		# Skip this step if conditions aren't met
		next_step()
		return

	# Pause game if needed
	if step.pause_game:
		pause_game()

	tutorial_step_changed.emit(step)

func previous_step() -> void:
	"""Go back to the previous tutorial step"""
	if not is_active or current_step_index <= 0:
		return

	current_step_index -= 1
	var step := tutorial_steps[current_step_index]
	tutorial_step_changed.emit(step)

func skip_tutorial() -> void:
	"""Skip the entire tutorial"""
	if not is_active:
		return

	is_active = false
	current_step_index = -1
	resume_game()
	mark_tutorial_completed()
	tutorial_skipped.emit()

func complete_tutorial() -> void:
	"""Complete the tutorial"""
	is_active = false
	current_step_index = -1
	resume_game()
	mark_tutorial_completed()
	tutorial_completed.emit()

func replay_tutorial() -> void:
	"""Replay the tutorial from the beginning"""
	start_tutorial()

func get_current_step() -> TutorialStep:
	"""Get the current tutorial step"""
	if current_step_index >= 0 and current_step_index < tutorial_steps.size():
		return tutorial_steps[current_step_index]
	return null

func pause_game() -> void:
	"""Pause the game during tutorial"""
	if game_state and game_state.has_method("pause_game"):
		game_state.pause_game()
	is_paused = true

func resume_game() -> void:
	"""Resume the game after tutorial pause"""
	if game_state and game_state.has_method("resume_game"):
		game_state.resume_game()
	is_paused = false

func get_game_state() -> Dictionary:
	"""Get relevant game state for condition checking"""
	var state := {}

	if game_state:
		if game_state.has_method("get_turn_number"):
			state["turn"] = game_state.get_turn_number()
		if game_state.has_method("get_current_player"):
			state["player"] = game_state.get_current_player()

	return state

func on_action_completed(action: String) -> void:
	"""Called when player completes an action"""
	var step := get_current_step()
	if step and step.wait_for_action == action:
		next_step()

func set_overlay(overlay: Control) -> void:
	"""Set the tutorial overlay UI"""
	tutorial_overlay = overlay
