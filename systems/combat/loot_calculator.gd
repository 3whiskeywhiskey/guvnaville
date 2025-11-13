class_name LootCalculator
extends Node

## Calculates and distributes loot after combat
##
## This singleton handles loot calculation from defeated units and
## experience distribution to victorious units.

## Loot percentages from defeated units
const LOOT_SCRAP_PERCENTAGE: float = 0.3
const LOOT_AMMO_PERCENTAGE: float = 0.5
const LOOT_COMPONENTS_PERCENTAGE: float = 0.4
const LOOT_FUEL_PERCENTAGE: float = 0.3
const LOOT_FOOD_PERCENTAGE: float = 0.2
const LOOT_MEDICINE_PERCENTAGE: float = 0.2

## Loot modifier bonuses
const SCAVENGER_BONUS: float = 0.5
const RAIDER_CULTURE_BONUS: float = 0.25
const COMPLETE_DESTRUCTION_PENALTY: float = -0.3

## Experience awards
const XP_KILL: int = 50
const XP_SURVIVE: int = 10
const XP_VICTORY: int = 20
const XP_DEFEAT: int = 5

## Experience thresholds for ranks
const XP_VETERAN: int = 100
const XP_ELITE: int = 250
const XP_LEGENDARY: int = 500


## Calculates resources looted from defeated units
##
## Loot Formula:
## Base loot per unit:
## - Scrap: unit_cost * 0.3
## - Ammunition: unit_ammo * 0.5
## - Components: unit_components * 0.4
## - Equipment: random chance for special items
##
## Modifiers:
## - Scavenger units: +50% loot
## - Raider culture: +25% loot
## - Complete destruction: -30% loot
##
## @param defeated_units: Units that were defeated
## @param victor_faction: Faction ID that won
## @param victor_units: Winning units (for scavenger bonus)
## @return: Dictionary of resources
static func calculate_loot(
	defeated_units: Array,
	victor_faction: int,
	victor_units: Array
) -> Dictionary:
	var loot: Dictionary = {
		"scrap": 0,
		"food": 0,
		"medicine": 0,
		"ammunition": 0,
		"fuel": 0,
		"components": 0,
		"special_items": []
	}

	if defeated_units.is_empty():
		return loot

	# Check for scavenger units
	var has_scavenger: bool = _has_scavenger_unit(victor_units)

	# Check for raider culture
	var is_raider_culture: bool = _is_raider_culture(victor_units)

	# Calculate loot modifier
	var loot_modifier: float = 1.0
	if has_scavenger:
		loot_modifier += SCAVENGER_BONUS
	if is_raider_culture:
		loot_modifier += RAIDER_CULTURE_BONUS

	# Calculate loot from each defeated unit
	for unit in defeated_units:
		if not unit is Dictionary:
			continue

		var unit_loot = _calculate_unit_loot(unit, loot_modifier)

		# Add to total loot
		for resource in loot:
			if resource != "special_items":
				loot[resource] += unit_loot.get(resource, 0)
			else:
				loot[resource].append_array(unit_loot.get(resource, []))

	return loot


## Calculates loot from a single defeated unit
##
## @param unit: Defeated unit
## @param loot_modifier: Global loot modifier
## @return: Dictionary of resources from this unit
static func _calculate_unit_loot(unit: Dictionary, loot_modifier: float) -> Dictionary:
	var unit_loot: Dictionary = {
		"scrap": 0,
		"food": 0,
		"medicine": 0,
		"ammunition": 0,
		"fuel": 0,
		"components": 0,
		"special_items": []
	}

	var stats = unit.get("stats", {})
	var cost = stats.get("cost", {})

	# Check if unit was completely destroyed (0 HP)
	var current_hp: int = unit.get("current_hp", stats.get("hp", 100))
	var destruction_modifier: float = 1.0
	if current_hp <= 0:
		destruction_modifier = 1.0 + COMPLETE_DESTRUCTION_PENALTY  # -30% loot

	# Calculate base loot
	unit_loot["scrap"] = int(cost.get("scrap", 0) * LOOT_SCRAP_PERCENTAGE * loot_modifier * destruction_modifier)
	unit_loot["ammunition"] = int(cost.get("ammunition", 0) * LOOT_AMMO_PERCENTAGE * loot_modifier * destruction_modifier)
	unit_loot["components"] = int(cost.get("components", 0) * LOOT_COMPONENTS_PERCENTAGE * loot_modifier * destruction_modifier)
	unit_loot["fuel"] = int(cost.get("fuel", 0) * LOOT_FUEL_PERCENTAGE * loot_modifier * destruction_modifier)
	unit_loot["food"] = int(cost.get("food", 0) * LOOT_FOOD_PERCENTAGE * loot_modifier * destruction_modifier)
	unit_loot["medicine"] = int(cost.get("medicine", 0) * LOOT_MEDICINE_PERCENTAGE * loot_modifier * destruction_modifier)

	# Chance for special items (5% per unit)
	if randf() < 0.05:
		unit_loot["special_items"].append(_generate_special_item(unit))

	return unit_loot


## Checks if any victor unit is a scavenger
##
## @param units: Array of units
## @return: True if has scavenger
static func _has_scavenger_unit(units: Array) -> bool:
	for unit in units:
		if unit is Dictionary:
			var unit_type: String = unit.get("unit_type", "")
			if unit_type == "scavenger":
				return true
	return false


## Checks if victor uses raider culture
##
## @param units: Array of units
## @return: True if raider culture
static func _is_raider_culture(units: Array) -> bool:
	for unit in units:
		if unit is Dictionary:
			var culture: String = unit.get("culture", "")
			if culture == "raider":
				return true
	return false


## Generates a random special item
##
## @param unit: Unit that dropped the item
## @return: Item ID string
static func _generate_special_item(unit: Dictionary) -> String:
	var items: Array = [
		"combat_stims",
		"advanced_scope",
		"reinforced_armor",
		"emergency_rations",
		"medical_kit",
		"ammunition_cache"
	]
	return items[randi() % items.size()]


## Calculates and distributes experience to units after combat
##
## Experience Awards:
## - Kill enemy unit: +50 XP
## - Survive battle: +10 XP
## - Victory: +20 XP
## - Defeat: +5 XP (learning from mistakes)
##
## @param units: Units that participated in combat
## @param combat_result: Combat result for context
## @return: Dictionary mapping unit_id to XP gained
static func distribute_experience(
	units: Array,
	combat_result: CombatResult
) -> Dictionary:
	var xp_table: Dictionary = {}

	if units.is_empty():
		return xp_table

	# Determine if units were victorious
	var is_victory: bool = _is_victory_for_units(units, combat_result)

	# Distribute experience
	for unit in units:
		if not unit is Dictionary:
			continue

		var unit_id: String = unit.get("id", "")
		var xp_gained: int = 0

		# Survival XP
		xp_gained += XP_SURVIVE

		# Victory/Defeat XP
		if is_victory:
			xp_gained += XP_VICTORY
		else:
			xp_gained += XP_DEFEAT

		# Kill XP (check if unit participated in kills)
		var kills: int = _count_unit_kills(unit, combat_result)
		xp_gained += kills * XP_KILL

		# Store XP
		xp_table[unit_id] = xp_gained

		# Apply XP to unit
		var current_xp: int = unit.get("experience", 0)
		unit["experience"] = current_xp + xp_gained

		# Check for promotion
		_check_promotion(unit)

	return xp_table


## Checks if units were on the victorious side
##
## @param units: Units to check
## @param combat_result: Combat result
## @return: True if victorious
static func _is_victory_for_units(units: Array, combat_result: CombatResult) -> bool:
	if units.is_empty():
		return false

	# Check if units are in attacker or defender survivors
	var first_unit = units[0]
	if not first_unit is Dictionary:
		return false

	var unit_id: String = first_unit.get("id", "")

	# Check if in attacker survivors
	for survivor in combat_result.attacker_survivors:
		if survivor is Dictionary and survivor.get("id", "") == unit_id:
			# Unit was on attacker side
			return combat_result.outcome in [
				CombatResult.CombatOutcome.ATTACKER_VICTORY,
				CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
			]

	# Check if in defender survivors
	for survivor in combat_result.defender_survivors:
		if survivor is Dictionary and survivor.get("id", "") == unit_id:
			# Unit was on defender side
			return combat_result.outcome in [
				CombatResult.CombatOutcome.DEFENDER_VICTORY,
				CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY
			]

	return false


## Counts kills attributed to a unit
##
## @param unit: Unit to check
## @param combat_result: Combat result
## @return: Number of kills
static func _count_unit_kills(unit: Dictionary, combat_result: CombatResult) -> int:
	# Simplified for MVP - distribute kills evenly among survivors
	var unit_id: String = unit.get("id", "")

	# Check which side unit is on
	var is_attacker: bool = false
	for survivor in combat_result.attacker_survivors:
		if survivor is Dictionary and survivor.get("id", "") == unit_id:
			is_attacker = true
			break

	# Count casualties on opposite side
	var enemy_casualties: Array = combat_result.defender_casualties if is_attacker else combat_result.attacker_casualties
	var friendly_survivors: Array = combat_result.attacker_survivors if is_attacker else combat_result.defender_survivors

	if friendly_survivors.is_empty():
		return 0

	# Distribute kills evenly (simplified)
	var kills_per_unit: int = max(1, enemy_casualties.size() / friendly_survivors.size())
	return kills_per_unit


## Checks and applies promotion if unit reached threshold
##
## @param unit: Unit to check
static func _check_promotion(unit: Dictionary) -> void:
	if not unit:
		return

	var experience: int = unit.get("experience", 0)
	var current_rank: String = unit.get("rank", "Rookie")

	var new_rank: String = ""

	if experience >= XP_LEGENDARY and current_rank != "Legendary":
		new_rank = "Legendary"
		_apply_promotion_bonus(unit, new_rank)
	elif experience >= XP_ELITE and current_rank in ["Rookie", "Veteran"]:
		new_rank = "Elite"
		_apply_promotion_bonus(unit, new_rank)
	elif experience >= XP_VETERAN and current_rank == "Rookie":
		new_rank = "Veteran"
		_apply_promotion_bonus(unit, new_rank)

	if new_rank:
		unit["rank"] = new_rank


## Applies stat bonuses from promotion
##
## @param unit: Unit to promote
## @param rank: New rank
static func _apply_promotion_bonus(unit: Dictionary, rank: String) -> void:
	var stats = unit.get("stats", {})
	if stats.is_empty():
		return

	var bonus_multiplier: float = 1.0
	match rank:
		"Veteran":
			bonus_multiplier = 1.10  # +10%
		"Elite":
			bonus_multiplier = 1.20  # +20%
		"Legendary":
			bonus_multiplier = 1.30  # +30%

	# Apply bonus to attack and defense (if not already applied)
	var base_attack: int = stats.get("base_attack", stats.get("attack", 0))
	var base_defense: int = stats.get("base_defense", stats.get("defense", 0))

	# Store base stats if not already stored
	if not stats.has("base_attack"):
		stats["base_attack"] = base_attack
	if not stats.has("base_defense"):
		stats["base_defense"] = base_defense

	# Calculate new stats
	stats["attack"] = int(stats["base_attack"] * bonus_multiplier)
	stats["defense"] = int(stats["base_defense"] * bonus_multiplier)


## Gets rank name from experience
##
## @param experience: Total experience points
## @return: Rank name
static func get_rank_from_experience(experience: int) -> String:
	if experience >= XP_LEGENDARY:
		return "Legendary"
	elif experience >= XP_ELITE:
		return "Elite"
	elif experience >= XP_VETERAN:
		return "Veteran"
	else:
		return "Rookie"


## Gets next promotion threshold
##
## @param current_experience: Current XP
## @return: XP needed for next promotion (0 if max rank)
static func get_next_promotion_xp(current_experience: int) -> int:
	if current_experience >= XP_LEGENDARY:
		return 0  # Max rank
	elif current_experience >= XP_ELITE:
		return XP_LEGENDARY
	elif current_experience >= XP_VETERAN:
		return XP_ELITE
	else:
		return XP_VETERAN
