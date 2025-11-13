class_name HealAbility
extends Ability

## Heal Ability - Medical healing ability
## Restores HP to friendly unit
## Part of Workstream 2.3: Unit System

# Heal amount
var heal_base: int = 30
var heal_percent: float = 0.1  # 10% of target's max HP

func _init():
	id = "heal"
	name = "Medical Treatment"
	description = "Restore 30 HP + 10% of target's max HP to adjacent friendly unit"
	cooldown = 0  # Can use every turn (limited by resources in full game)
	cost_type = CostType.RESOURCE  # Would cost medicine in full game
	cost_amount = 1
	range = 1  # Adjacent tiles only
	target_type = TargetType.FRIENDLY_UNIT

## Check if target is valid
func is_valid_target(unit: Unit, target) -> bool:
	if not unit or not target:
		return false

	if not target is Unit:
		return false

	var target_unit = target as Unit

	# Must be friendly
	if target_unit.faction_id != unit.faction_id:
		return false

	# Must be damaged
	if target_unit.current_hp >= target_unit.max_hp:
		return false

	# Must be in range
	if not is_target_in_range(unit, target_unit.position):
		return false

	return true

## Apply healing effect
func apply_effect(unit: Unit, target) -> bool:
	if not target is Unit:
		return false

	var target_unit = target as Unit

	# Calculate heal amount
	var heal_amount = heal_base + int(target_unit.max_hp * heal_percent)

	# Apply healing
	var actual_heal = target_unit.heal(heal_amount)

	return actual_heal > 0

## Get valid targets
func get_valid_targets(unit: Unit) -> Array:
	var targets = []

	# Would query UnitManager for friendly units in range
	# For now, return empty array (needs UnitManager reference)

	return targets
