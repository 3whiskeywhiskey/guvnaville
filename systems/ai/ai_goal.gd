## AIGoal - Represents a strategic goal for AI factions
##
## Goals drive AI decision-making and action prioritization. The AI maintains
## a stack of goals and evaluates actions based on how well they advance
## active goals.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name AIGoal
extends RefCounted

## Types of strategic goals
enum GoalType {
	EXPAND_TERRITORY,    # Expand controlled area
	MILITARY_CONQUEST,   # Conquer specific faction/location
	ECONOMIC_GROWTH,     # Build economy
	CULTURAL_VICTORY,    # Pursue cultural victory
	TECH_ADVANCEMENT,    # Research focus
	DEFEND_TERRITORY,    # Defensive posture
	ESTABLISH_TRADE,     # Create trade network
	SECURE_RESOURCE      # Control specific resource type
}

## Type of goal
var type: GoalType

## Priority (0.0-100.0, higher = more important)
var priority: float

## Goal-specific target (faction ID, location, resource type, etc.)
var target: Variant

## Completion progress (0.0-1.0)
var progress: float

## How many turns this goal has been active
var turns_active: int


## Constructor
func _init(p_type: GoalType, p_priority: float = 50.0, p_target: Variant = null) -> void:
	type = p_type
	priority = clampf(p_priority, 0.0, 100.0)
	target = p_target
	progress = 0.0
	turns_active = 0


## Updates goal state for a new turn
func advance_turn() -> void:
	turns_active += 1


## Updates progress towards goal completion
func update_progress(new_progress: float) -> void:
	progress = clampf(new_progress, 0.0, 1.0)


## Returns true if goal is completed
func is_complete() -> bool:
	return progress >= 1.0


## Returns string representation for debugging
func to_string() -> String:
	var type_name = GoalType.keys()[type]
	return "AIGoal(%s, priority=%.1f, progress=%.1f%%, turns=%d)" % [
		type_name, priority, progress * 100.0, turns_active
	]


## Returns true if this goal is stale (been active too long without progress)
func is_stale(max_turns: int = 50) -> bool:
	return turns_active > max_turns and progress < 0.1
