class_name OverwatchAbility
extends Ability

## Overwatch Ability - Reaction fire ability
## React to enemy movement with free attack
## Part of Workstream 2.3: Unit System

func _init():
	id = "overwatch"
	name = "Overwatch"
	description = "Enter overwatch mode - automatically attack first enemy that moves in range"
	cooldown = 1  # 1 turn cooldown
	cost_type = CostType.ACTION_POINT
	cost_amount = 1
	range = -1  # Self only (sets up overwatch mode)
	target_type = TargetType.SELF

## Check if target is valid (self only)
func is_valid_target(unit: Unit, target) -> bool:
	return target == null or (target is Unit and target == unit)

## Apply overwatch effect
func apply_effect(unit: Unit, target) -> bool:
	if not unit:
		return false

	# Create overwatch status effect
	var effect = {
		"id": "overwatch",
		"name": "Overwatch",
		"duration": 1,  # Lasts until next turn or until triggered
		"is_buff": true,
		"reaction_fire": true,  # Flag for combat system to check
		"range": unit.stats.range if unit.stats else 1,
		"triggered": false
	}

	# Add status effect to unit
	unit.status_effects.append(effect)

	return true

## Get valid targets (always returns self)
func get_valid_targets(unit: Unit) -> Array:
	return [unit]
