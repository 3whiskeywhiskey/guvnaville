class_name EntrenchAbility
extends Ability

## Entrench Ability - Defensive fortification
## +50% defense, -50% movement until next turn
## Part of Workstream 2.3: Unit System

func _init():
	id = "entrench"
	name = "Entrench"
	description = "Dig in for +50% defense, -50% movement until next turn"
	cooldown = 0  # Can use every turn
	cost_type = CostType.ACTION_POINT
	cost_amount = 1
	range = -1  # Self only
	target_type = TargetType.SELF

## Check if target is valid (self only)
func is_valid_target(unit: Unit, target) -> bool:
	return target == null or (target is Unit and target == unit)

## Apply entrenchment effect
func apply_effect(unit: Unit, target) -> bool:
	if not unit:
		return false

	# Create entrenchment status effect
	var effect = {
		"id": "entrenched",
		"name": "Entrenched",
		"duration": 1,  # Lasts until next turn
		"is_buff": true,
		"stat_modifiers": {
			"defense": 1.5,  # +50% defense
			"movement": 0.5   # -50% movement
		},
		"immobilized": false
	}

	# Add status effect to unit
	unit.status_effects.append(effect)

	return true

## Get valid targets (always returns self)
func get_valid_targets(unit: Unit) -> Array:
	return [unit]
