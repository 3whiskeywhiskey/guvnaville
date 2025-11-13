extends RefCounted
class_name TutorialStep

## Represents a single step in the tutorial
## Each step can highlight UI elements, show messages, and pause the game

var id: String
var title: String
var message: String
var highlight_element: String  # NodePath as string to highlight
var pause_game: bool
var allow_skip: bool
var wait_for_action: String  # Action to wait for before proceeding (e.g., "end_turn", "move_unit")
var show_arrow: bool
var arrow_position: Vector2
var conditions: Dictionary  # Conditions that must be met to show this step

func _init(data: Dictionary = {}) -> void:
	id = data.get("id", "")
	title = data.get("title", "")
	message = data.get("message", "")
	highlight_element = data.get("highlight_element", "")
	pause_game = data.get("pause_game", false)
	allow_skip = data.get("allow_skip", true)
	wait_for_action = data.get("wait_for_action", "")
	show_arrow = data.get("show_arrow", false)
	arrow_position = Vector2(data.get("arrow_x", 0), data.get("arrow_y", 0))
	conditions = data.get("conditions", {})

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"message": message,
		"highlight_element": highlight_element,
		"pause_game": pause_game,
		"allow_skip": allow_skip,
		"wait_for_action": wait_for_action,
		"show_arrow": show_arrow,
		"arrow_x": arrow_position.x,
		"arrow_y": arrow_position.y,
		"conditions": conditions
	}

func check_conditions(game_state: Dictionary) -> bool:
	"""Check if conditions are met to show this step"""
	if conditions.is_empty():
		return true

	for key in conditions:
		var expected_value = conditions[key]
		var actual_value = game_state.get(key)

		if actual_value != expected_value:
			return false

	return true
