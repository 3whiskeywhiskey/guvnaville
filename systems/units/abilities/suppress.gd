class_name SuppressAbility
extends Ability

## Suppress Ability - Suppression fire ability
## Reduces enemy attack and movement
## Part of Workstream 2.3: Unit System

func _init():
	id = "suppress"
	name = "Suppressive Fire"
	description = "Reduce enemy attack and movement by 50% for 1 turn"
	cooldown = 0  # Can use every turn (would cost ammunition in full game)
	cost_type = CostType.RESOURCE  # Would cost ammunition in full game
	cost_amount = 1
	range = -1  # Will use unit's attack range
	target_type = TargetType.ENEMY_UNIT

## Override can_use to check unit's attack range
func can_use(unit: Unit, target) -> bool:
	if not super.can_use(unit, target):
		return false

	# Set range based on unit's attack range
	if unit and unit.stats:
		range = unit.stats.range

	return true

## Check if target is valid
func is_valid_target(unit: Unit, target) -> bool:
	if not unit or not target:
		return false

	if not target is Unit:
		return false

	var target_unit = target as Unit

	# Must be enemy
	if target_unit.faction_id == unit.faction_id:
		return false

	# Must be alive
	if not target_unit.is_alive():
		return false

	# Set range dynamically
	var effective_range = unit.stats.range if unit.stats else 1

	# Must be in range
	var distance = abs(target_unit.position.x - unit.position.x) + \
				   abs(target_unit.position.y - unit.position.y) + \
				   abs(target_unit.position.z - unit.position.z)

	return distance <= effective_range

## Apply suppression effect
func apply_effect(unit: Unit, target) -> bool:
	if not target is Unit:
		return false

	var target_unit = target as Unit

	# Create suppression status effect
	var effect = {
		"id": "suppressed",
		"name": "Suppressed",
		"duration": 1,  # Lasts 1 turn
		"is_buff": false,  # This is a debuff
		"stat_modifiers": {
			"attack": 0.5,    # -50% attack
			"movement": 0.5   # -50% movement
		}
	}

	# Add status effect to target
	target_unit.status_effects.append(effect)

	return true

## Get valid targets
func get_valid_targets(unit: Unit) -> Array:
	var targets = []

	# Would query UnitManager for enemy units in range
	# For now, return empty array (needs UnitManager reference)

	return targets
