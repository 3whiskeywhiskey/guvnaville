## AIAction - Represents a single AI decision/action
##
## Main data structure for AI decisions. Each action has a type, priority score,
## and parameters specific to the action type.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name AIAction
extends RefCounted

## Types of actions the AI can take
enum ActionType {
	MOVE_UNIT,           # Move a unit
	ATTACK,              # Attack with unit
	BUILD_UNIT,          # Start building a unit
	BUILD_BUILDING,      # Start building a structure
	RESEARCH,            # Select research/culture node
	TRADE,               # Establish trade route
	RECRUIT,             # Recruit new units
	SCAVENGE,            # Send scavengers to tile
	FORTIFY,             # Build fortifications
	DIPLOMACY,           # Diplomatic action (future)
	END_TURN             # End turn (always last)
}

## Type of action to perform
var type: ActionType

## Priority score (0.0-100.0, higher = more important)
var priority: float

## Action-specific parameters
##
## Examples by type:
## - MOVE_UNIT: {"unit_id": int, "target": Vector3i}
## - ATTACK: {"unit_id": int, "target_id": int, "use_tactical": bool}
## - BUILD_UNIT: {"unit_type": String, "location": Vector3i}
## - BUILD_BUILDING: {"building_type": String, "location": Vector3i}
## - RESEARCH: {"node_id": String}
## - TRADE: {"target_faction": int, "offer": Dictionary, "request": Dictionary}
var parameters: Dictionary


## Constructor
func _init(p_type: ActionType = ActionType.END_TURN, p_priority: float = 0.0, p_parameters: Dictionary = {}) -> void:
	type = p_type
	priority = clampf(p_priority, 0.0, 100.0)
	parameters = p_parameters


## Returns string representation of action for debugging
func to_string() -> String:
	var type_name = ActionType.keys()[type]
	return "AIAction(%s, priority=%.1f, params=%s)" % [type_name, priority, parameters]


## Validates that this action has required parameters for its type
func is_valid() -> bool:
	match type:
		ActionType.MOVE_UNIT:
			return parameters.has("unit_id") and parameters.has("target")
		ActionType.ATTACK:
			return parameters.has("unit_id") and parameters.has("target_id")
		ActionType.BUILD_UNIT:
			return parameters.has("unit_type") and parameters.has("location")
		ActionType.BUILD_BUILDING:
			return parameters.has("building_type") and parameters.has("location")
		ActionType.RESEARCH:
			return parameters.has("node_id")
		ActionType.TRADE:
			return parameters.has("target_faction")
		ActionType.RECRUIT:
			return parameters.has("unit_type")
		ActionType.SCAVENGE:
			return parameters.has("target")
		ActionType.FORTIFY:
			return parameters.has("location")
		ActionType.DIPLOMACY:
			return parameters.has("target_faction") and parameters.has("action")
		ActionType.END_TURN:
			return true  # Always valid

	return false
