class_name CombatCalculator
extends Node

## Core calculation engine for damage, strength, and combat math
##
## This singleton provides all mathematical calculations for combat including
## damage formulas, combat strength, and casualty application.

## Minimum damage per attack (prevents 0 damage)
const MIN_DAMAGE: int = 5

## Damage variance range (±15%)
const DAMAGE_VARIANCE_MIN: float = 0.85
const DAMAGE_VARIANCE_MAX: float = 1.15

## Casualty percentages by outcome
const CASUALTY_DECISIVE_WINNER: float = 0.10
const CASUALTY_DECISIVE_LOSER_MIN: float = 0.60
const CASUALTY_DECISIVE_LOSER_MAX: float = 0.80
const CASUALTY_WINNER: float = 0.25
const CASUALTY_LOSER: float = 0.50
const CASUALTY_STALEMATE: float = 0.30


## Calculates raw damage dealt by attacker to defender
##
## Formula:
## effective_attack = attacker.attack * modifiers.total_attack_multiplier
## effective_defense = defender.defense + modifiers.total_defense_bonus + (defender.armor * 0.01 * defender.defense)
## raw_damage = effective_attack - effective_defense
## clamped_damage = max(raw_damage, MIN_DAMAGE)
## final_damage = clamped_damage * randf_range(DAMAGE_VARIANCE_MIN, DAMAGE_VARIANCE_MAX)
##
## @param attacker: Unit dealing damage (must have stats.attack)
## @param defender: Unit receiving damage (must have stats.defense, stats.armor)
## @param modifiers: Combat modifiers to apply
## @return: Integer damage value (always >= MIN_DAMAGE)
static func calculate_damage(attacker: Dictionary, defender: Dictionary, modifiers: CombatModifiers) -> int:
	if not attacker or not defender or not modifiers:
		push_warning("CombatCalculator.calculate_damage: Invalid parameters")
		return MIN_DAMAGE

	# Ensure modifiers are calculated
	if modifiers.total_attack_multiplier == 0.0:
		modifiers.calculate_totals()

	# Get unit stats
	var attacker_stats = attacker.get("stats", {})
	var defender_stats = defender.get("stats", {})

	var base_attack: float = float(attacker_stats.get("attack", 0))
	var base_defense: float = float(defender_stats.get("defense", 0))
	var armor: float = float(defender_stats.get("armor", 0))

	# Calculate effective attack
	var effective_attack: float = base_attack * modifiers.total_attack_multiplier

	# Calculate effective defense (armor reduces effective defense as percentage)
	var armor_multiplier: float = 1.0 - (armor * 0.01)
	var effective_defense: float = (base_defense * armor_multiplier) + modifiers.total_defense_bonus

	# Calculate raw damage
	var raw_damage: float = effective_attack - effective_defense

	# Clamp to minimum damage
	var clamped_damage: float = max(raw_damage, float(MIN_DAMAGE))

	# Apply random variance (±15%)
	var final_damage: float = clamped_damage * randf_range(DAMAGE_VARIANCE_MIN, DAMAGE_VARIANCE_MAX)

	return int(round(final_damage))


## Calculates total combat strength for a group of units
##
## Formula:
## strength = 0
## for each unit:
##     base_stat = unit.attack if is_attacker else unit.defense
##     hp_factor = unit.current_hp / unit.max_hp
##     morale_factor = unit.morale / 100.0
##     terrain_mod = get_terrain_modifier(unit, terrain, is_attacker)
##     strength += base_stat * hp_factor * morale_factor * terrain_mod
##
## @param units: Array of units to evaluate
## @param terrain: Terrain providing modifiers (optional)
## @param is_attacker: True for attacking force, False for defending
## @return: Float representing total combat strength
static func calculate_combat_strength(units: Array, terrain: Dictionary, is_attacker: bool) -> float:
	if units.is_empty():
		return 0.0

	var total_strength: float = 0.0

	for unit in units:
		if not unit or not unit is Dictionary:
			continue

		var stats = unit.get("stats", {})
		var base_stat: float = float(stats.get("attack" if is_attacker else "defense", 0))

		# HP factor (percentage of health remaining)
		var current_hp: float = float(unit.get("current_hp", stats.get("hp", 100)))
		var max_hp: float = float(stats.get("hp", 100))
		var hp_factor: float = clamp(current_hp / max_hp, 0.0, 1.0) if max_hp > 0 else 0.0

		# Morale factor (percentage of morale)
		var morale: float = float(unit.get("morale", stats.get("morale", 50)))
		var morale_factor: float = clamp(morale / 100.0, 0.0, 1.5)  # Can exceed 100% for high morale

		# Terrain modifier
		var terrain_mod: float = 1.0
		if terrain and terrain.has("terrain_type"):
			# Defenders get defensive terrain bonuses
			if not is_attacker:
				var terrain_type = terrain.get("terrain_type", "open")
				if terrain_type == "building":
					terrain_mod = 1.2
				elif terrain_type == "rubble":
					terrain_mod = 1.1

		# Calculate unit strength
		var unit_strength: float = base_stat * hp_factor * morale_factor * terrain_mod
		total_strength += unit_strength

	return total_strength


## Applies casualties to units based on combat outcome
##
## Casualty rates:
## - Decisive Victory (winner): 10% casualties
## - Decisive Victory (loser): 60-80% casualties
## - Victory (winner): 25% casualties
## - Victory (loser): 50% casualties
## - Stalemate: 30% casualties both sides
##
## @param units: Units to apply casualties to
## @param casualty_percentage: Base casualty rate (0.0-1.0)
## @param outcome: Combat outcome affecting distribution
## @return: Array of units that were destroyed/heavily damaged
static func apply_casualties(units: Array, casualty_percentage: float, outcome: int) -> Array:
	var casualties: Array = []

	if units.is_empty():
		return casualties

	casualty_percentage = clamp(casualty_percentage, 0.0, 1.0)

	for unit in units:
		if not unit or not unit is Dictionary:
			continue

		var stats = unit.get("stats", {})
		var max_hp: int = stats.get("hp", 100)
		var current_hp: int = unit.get("current_hp", max_hp)

		# Calculate HP loss
		var hp_loss: int = int(max_hp * casualty_percentage)

		# Apply some randomness (±20%)
		hp_loss = int(hp_loss * randf_range(0.8, 1.2))

		# Apply damage
		current_hp -= hp_loss
		unit["current_hp"] = max(current_hp, 0)

		# Track casualties (units at 0 HP or below 20% HP)
		if current_hp <= 0 or current_hp < max_hp * 0.2:
			casualties.append(unit)

	return casualties


## Determines casualty percentage for a given outcome and side
##
## @param outcome: Combat outcome
## @param is_winner: Whether calculating for winning side
## @return: Casualty percentage (0.0-1.0)
static func get_casualty_percentage(outcome: int, is_winner: bool) -> float:
	match outcome:
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY:
			return CASUALTY_DECISIVE_WINNER if is_winner else randf_range(CASUALTY_DECISIVE_LOSER_MIN, CASUALTY_DECISIVE_LOSER_MAX)
		CombatResult.CombatOutcome.ATTACKER_VICTORY:
			return CASUALTY_WINNER if is_winner else CASUALTY_LOSER
		CombatResult.CombatOutcome.STALEMATE:
			return CASUALTY_STALEMATE
		CombatResult.CombatOutcome.DEFENDER_VICTORY:
			return CASUALTY_LOSER if is_winner else CASUALTY_WINNER
		CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY:
			# Fixed: Winner (defender) gets low casualties, loser (attacker) gets high casualties
			return CASUALTY_DECISIVE_WINNER if is_winner else randf_range(CASUALTY_DECISIVE_LOSER_MIN, CASUALTY_DECISIVE_LOSER_MAX)
		CombatResult.CombatOutcome.RETREAT:
			# Retreating side takes more casualties
			return 0.15 if is_winner else 0.40
		_:
			return CASUALTY_STALEMATE


## Determines combat outcome based on strength ratio
##
## @param attacker_strength: Total attacker strength
## @param defender_strength: Total defender strength
## @return: CombatOutcome enum value
static func determine_outcome(attacker_strength: float, defender_strength: float) -> int:
	if defender_strength <= 0:
		return CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY

	if attacker_strength <= 0:
		return CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY

	var ratio: float = attacker_strength / defender_strength

	# Decisive victory: 1.5x or more strength advantage
	if ratio >= 1.5:
		return CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
	elif ratio >= 1.1:
		return CombatResult.CombatOutcome.ATTACKER_VICTORY
	elif ratio >= 0.9:
		return CombatResult.CombatOutcome.STALEMATE
	elif ratio >= 0.67:  # 1/1.5 = 0.67
		return CombatResult.CombatOutcome.DEFENDER_VICTORY
	else:
		return CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY


## Validates unit has required combat stats
##
## @param unit: Unit to validate
## @return: True if valid, false otherwise
static func is_valid_combat_unit(unit: Dictionary) -> bool:
	if not unit:
		return false

	var stats = unit.get("stats", {})
	if stats.is_empty():
		return false

	# Must have basic combat stats
	if not stats.has("hp") or not stats.has("attack") or not stats.has("defense"):
		return false

	# Must have positive HP
	var current_hp = unit.get("current_hp", stats.get("hp", 0))
	if current_hp <= 0:
		return false

	return true


## Filters out invalid units from combat
##
## @param units: Array of units to filter
## @return: Array of valid units
static func filter_valid_units(units: Array) -> Array:
	var valid_units: Array = []
	for unit in units:
		if is_valid_combat_unit(unit):
			valid_units.append(unit)
		else:
			push_warning("CombatCalculator: Filtered out invalid unit: %s" % str(unit))
	return valid_units
