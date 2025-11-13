class_name ScoutAbility
extends Ability

## Scout Ability - Enhanced vision ability
## Temporarily increases vision range
## Part of Workstream 2.3: Unit System

var vision_bonus: int = 3

func _init():
	id = "scout"
	name = "Scout"
	description = "Temporarily increase vision range by 3 tiles for 2 turns"
	cooldown = 2  # 2 turn cooldown
	cost_type = CostType.ACTION_POINT
	cost_amount = 1
	range = -1  # Self only
	target_type = TargetType.SELF

## Check if target is valid (self only)
func is_valid_target(unit: Unit, target) -> bool:
	return target == null or (target is Unit and target == unit)

## Apply scout effect
func apply_effect(unit: Unit, target) -> bool:
	if not unit:
		return false

	# Create scout status effect
	var effect = {
		"id": "scouting",
		"name": "Scouting",
		"duration": 2,  # Lasts 2 turns
		"is_buff": true,
		"vision_bonus": vision_bonus,
		"stat_modifiers": {}
	}

	# Add status effect to unit
	unit.status_effects.append(effect)

	# Immediately increase vision range
	if unit.stats:
		unit.stats.vision_range += vision_bonus

	return true

## Get valid targets (always returns self)
func get_valid_targets(unit: Unit) -> Array:
	return [unit]
