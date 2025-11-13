class_name MoraleCheckResult
extends Resource

## Result of a morale check on a unit
##
## This class represents the outcome of a morale check, including
## the unit's morale state, whether it will retreat, and rally chances.

enum MoraleState {
	HOLDING,           ## Unit maintains position and morale
	SHAKEN,           ## -10% attack, may retreat soon
	RETREATING,       ## Unit is fleeing
	BROKEN,           ## Complete rout, unit destroyed or disbanded
	RALLIED           ## Previously shaken but recovered
}

## Unit identifier
var unit_id: String = ""

## Previous morale value
var previous_morale: int = 50

## Current morale value
var current_morale: int = 50

## Change in morale
var morale_change: int = 0

## Current morale state
var state: MoraleState = MoraleState.HOLDING

## Whether unit will retreat
var will_retreat: bool = false

## Direction of retreat
var retreat_direction: Vector3i = Vector3i.ZERO

## Chance to rally if retreating (0.0 - 1.0)
var rally_chance: float = 0.0


func _init():
	pass


## Determines morale state based on current morale value
func update_state_from_morale() -> void:
	if current_morale >= 80:
		if state == MoraleState.SHAKEN or state == MoraleState.RETREATING:
			state = MoraleState.RALLIED
		else:
			state = MoraleState.HOLDING
		will_retreat = false
	elif current_morale >= 30:
		if state == MoraleState.RETREATING:
			# Keep retreating until rallied
			will_retreat = true
		else:
			state = MoraleState.HOLDING
			will_retreat = false
	elif current_morale >= 10:
		state = MoraleState.SHAKEN
		# 50% chance to retreat when shaken
		will_retreat = randf() < 0.5
	else:
		state = MoraleState.BROKEN
		will_retreat = true


## Creates a string representation
func to_string() -> String:
	var state_str = MoraleState.keys()[state]
	return "MoraleCheckResult(unit=%s, morale=%d→%d, state=%s, retreat=%s)" % [
		unit_id, previous_morale, current_morale, state_str, will_retreat
	]


## Serializes to dictionary
func to_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"previous_morale": previous_morale,
		"current_morale": current_morale,
		"morale_change": morale_change,
		"state": state,
		"will_retreat": will_retreat,
		"retreat_direction": {"x": retreat_direction.x, "y": retreat_direction.y, "z": retreat_direction.z},
		"rally_chance": rally_chance
	}
