extends RefCounted
class_name TurnState

## TurnState - Current turn state
##
## Manages the current turn number, phase, active faction,
## and actions taken during the turn.

# ============================================================================
# TURN PHASES
# ============================================================================

enum TurnPhase {
	MOVEMENT,       ## Units can move
	COMBAT,         ## Combat resolution
	ECONOMY,        ## Resource collection and production
	CULTURE,        ## Culture point accumulation
	EVENTS,         ## Event processing
	END_TURN        ## Cleanup and preparation for next turn
}

# ============================================================================
# PROPERTIES
# ============================================================================

## Current turn number
var current_turn: int = 1

## Current turn phase
var current_phase: int = TurnPhase.MOVEMENT

## Currently active faction ID
var active_faction: int = 0

## Actions taken this turn (for logging and replay)
var actions_this_turn: Array = []

## Real-time elapsed this turn (in seconds)
var time_elapsed: float = 0.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	pass

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize turn state to dictionary
func to_dict() -> Dictionary:
	return {
		"current_turn": current_turn,
		"current_phase": current_phase,
		"active_faction": active_faction,
		"actions_this_turn": actions_this_turn.duplicate(),
		"time_elapsed": time_elapsed
	}

## Deserialize turn state from dictionary
func from_dict(data: Dictionary) -> void:
	current_turn = data.get("current_turn", 1)
	current_phase = data.get("current_phase", TurnPhase.MOVEMENT)
	active_faction = data.get("active_faction", 0)
	actions_this_turn = data.get("actions_this_turn", []).duplicate()
	time_elapsed = data.get("time_elapsed", 0.0)

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

## Reset state for a new turn
func reset_for_new_turn() -> void:
	actions_this_turn.clear()
	time_elapsed = 0.0
	current_phase = TurnPhase.MOVEMENT

## Advance to next phase
func advance_phase() -> void:
	if current_phase < TurnPhase.END_TURN:
		current_phase += 1
	else:
		current_phase = TurnPhase.MOVEMENT

## Log an action
func log_action(action: Dictionary) -> void:
	actions_this_turn.append(action)

## Get phase name as string
func get_phase_name() -> String:
	match current_phase:
		TurnPhase.MOVEMENT:
			return "Movement"
		TurnPhase.COMBAT:
			return "Combat"
		TurnPhase.ECONOMY:
			return "Economy"
		TurnPhase.CULTURE:
			return "Culture"
		TurnPhase.EVENTS:
			return "Events"
		TurnPhase.END_TURN:
			return "End Turn"
		_:
			return "Unknown"
