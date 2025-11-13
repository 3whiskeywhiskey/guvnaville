class_name CombatModifiersCalculator
extends Node

# Preload dependencies for Godot 4.5.1 compatibility
const CombatModifiers = preload("res://systems/combat/combat_modifiers.gd")

## Calculates and combines all combat modifiers
##
## This class handles the calculation of terrain, elevation, cover, cultural,
## and all other modifiers that affect combat calculations.

## Cover type definitions
enum CoverType {
	NONE,           ## No cover (+0 defense)
	LIGHT,          ## Light cover like rubble, cars (+5 defense)
	HEAVY,          ## Heavy cover like buildings, walls (+10 defense)
	FORTIFICATION   ## Fortifications (+15 defense)
}

## Terrain type definitions
enum TerrainType {
	OPEN,           ## Open ground (1.0x)
	RUBBLE,         ## Rubble/debris (0.9x movement, +5 def)
	BUILDING,       ## Inside building (+10 def for defenders)
	STREET,         ## Street/road (1.0x neutral)
	ELEVATED,       ## Elevated position (affects elevation modifier)
	UNDERGROUND     ## Underground (no elevation bonuses)
}


## Calculates all combat modifiers for a specific engagement
##
## @param attacker: Attacking unit (Dictionary with stats)
## @param defender: Defending unit (Dictionary with stats)
## @param terrain: Terrain tile (Dictionary)
## @param context: Optional context {elevation_diff: int, is_flanking: bool, etc.}
## @return: CombatModifiers object with all modifiers applied
static func get_combat_modifiers(
	attacker: Dictionary,
	defender: Dictionary,
	terrain: Dictionary,
	context: Dictionary = {}
) -> CombatModifiers:
	var mods = CombatModifiers.new()

	if not attacker or not defender:
		push_warning("CombatModifiersCalculator: Invalid units")
		mods.calculate_totals()
		return mods

	# Terrain modifier
	mods.terrain_modifier = get_terrain_modifier(attacker, terrain, true)

	# Cover bonus (defenders only)
	mods.cover_bonus = get_cover_bonus(terrain, true)

	# Elevation modifier
	var elevation_diff: int = context.get("elevation_diff", 0)
	mods.elevation_modifier = get_elevation_modifier(elevation_diff)

	# Flanking bonus
	var is_flanking: bool = context.get("is_flanking", false)
	mods.flanking_bonus = 0.15 if is_flanking else 0.0

	# Fortification bonus
	mods.fortification_bonus = get_fortification_bonus(terrain)

	# Cultural bonuses
	mods.cultural_bonuses = get_cultural_bonuses(attacker, defender, context)

	# Supply penalty
	var has_supply: bool = context.get("has_supply", true)
	mods.supply_penalty = 1.0 if has_supply else 0.5

	# Morale modifier
	var attacker_morale: int = attacker.get("morale", 50)
	mods.morale_modifier = get_morale_modifier(attacker_morale)

	# Unit experience bonus
	var experience: int = attacker.get("experience", 0)
	mods.unit_experience_bonus = get_experience_modifier(experience)

	# Weather modifier (future feature)
	var weather: String = context.get("weather", "clear")
	mods.weather_modifier = get_weather_modifier(weather)

	# Calculate combined totals
	mods.calculate_totals()

	return mods


## Gets terrain-specific modifier for a unit
##
## @param unit: Unit being evaluated
## @param terrain: Terrain tile
## @param is_attacker: True if attacking, False if defending
## @return: Float multiplier (typically 0.75 - 1.25)
static func get_terrain_modifier(unit: Dictionary, terrain: Dictionary, is_attacker: bool) -> float:
	if not terrain or terrain.is_empty():
		return 1.0

	var terrain_type: String = terrain.get("terrain_type", "open")

	match terrain_type:
		"open":
			return 1.0
		"rubble":
			return 0.9 if is_attacker else 1.0
		"building":
			return 0.95 if is_attacker else 1.1
		"street":
			return 1.0
		"elevated":
			return 1.0  # Handled by elevation modifier
		"underground":
			return 1.0
		_:
			return 1.0


## Calculates defense bonus from cover
##
## @param terrain: Terrain tile
## @param is_defending: Only defenders get cover bonus
## @return: Integer defense bonus (0-15)
static func get_cover_bonus(terrain: Dictionary, is_defending: bool) -> int:
	if not is_defending or not terrain:
		return 0

	var cover_type: String = terrain.get("cover_type", "none")

	match cover_type:
		"none":
			return 0
		"light":
			return 5
		"heavy":
			return 10
		"fortification":
			return 15
		_:
			# Infer from terrain type if no explicit cover
			var terrain_type: String = terrain.get("terrain_type", "open")
			match terrain_type:
				"rubble":
					return 5
				"building":
					return 10
				_:
					return 0


## Calculates elevation modifier
##
## @param elevation_diff: Difference in elevation (attacker.z - defender.z)
## @return: Float modifier (+25% higher, -15% lower, 1.0 same)
static func get_elevation_modifier(elevation_diff: int) -> float:
	if elevation_diff > 0:
		return 1.25  # Attacker higher: +25% attack
	elif elevation_diff < 0:
		return 0.85  # Attacker lower: -15% attack
	else:
		return 1.0   # Same elevation: no modifier


## Gets fortification bonus from terrain
##
## @param terrain: Terrain tile
## @return: Integer fortification defense bonus (0-15)
static func get_fortification_bonus(terrain: Dictionary) -> int:
	if not terrain:
		return 0

	var has_fortification: bool = terrain.get("has_fortification", false)
	if not has_fortification:
		return 0

	var fortification_level: int = terrain.get("fortification_level", 1)
	match fortification_level:
		1:  # Barricades
			return 5
		2:  # Bunkers
			return 10
		3:  # Heavy fortifications
			return 15
		_:
			return 5


## Gets cultural combat bonuses
##
## @param attacker: Attacking unit
## @param defender: Defending unit
## @param context: Optional context
## @return: Dictionary of cultural bonuses
static func get_cultural_bonuses(
	attacker: Dictionary,
	defender: Dictionary,
	context: Dictionary
) -> Dictionary:
	var bonuses: Dictionary = {}

	# Get faction culture types (stub for MVP - return empty)
	# In full implementation, this would query the faction's culture system

	var attacker_culture: String = attacker.get("culture", "")
	var defender_culture: String = defender.get("culture", "")

	# Example culture bonuses (can be expanded post-MVP)
	match attacker_culture:
		"military_dictatorship":
			bonuses["military_attack_bonus"] = 0.15
		"raider":
			bonuses["raider_intimidation_bonus"] = 0.10
		"technocracy":
			bonuses["tech_defense_bonus"] = 10
		_:
			pass

	return bonuses


## Gets morale modifier affecting combat effectiveness
##
## @param morale: Unit's current morale (0-100)
## @return: Float modifier
static func get_morale_modifier(morale: int) -> float:
	if morale >= 80:
		return 1.10  # High morale: +10% attack
	elif morale >= 30:
		return 1.0   # Normal morale: no effect
	elif morale >= 10:
		return 0.90  # Low morale: -10% attack
	else:
		return 0.75  # Broken morale: -25% attack


## Gets experience modifier from unit veterancy
##
## @param experience: Unit's total experience points
## @return: Float modifier
static func get_experience_modifier(experience: int) -> float:
	if experience >= 500:
		return 1.30  # Legendary: +30%
	elif experience >= 250:
		return 1.20  # Elite: +20%
	elif experience >= 100:
		return 1.10  # Veteran: +10%
	else:
		return 1.0   # Rookie: no bonus


## Gets weather modifier (future feature, stub for MVP)
##
## @param weather: Weather type string
## @return: Float modifier
static func get_weather_modifier(weather: String) -> float:
	match weather:
		"clear":
			return 1.0
		"rain":
			return 0.95  # Slight penalty
		"fog":
			return 0.90  # Reduced visibility
		"storm":
			return 0.85  # Major penalty
		_:
			return 1.0


## Applies special unit abilities to modifiers
##
## @param unit: Unit with potential abilities
## @param modifiers: CombatModifiers to modify
## @param context: Combat context
static func apply_special_abilities(
	unit: Dictionary,
	modifiers: CombatModifiers,
	context: Dictionary
) -> void:
	var abilities: Array = unit.get("abilities", [])

	for ability in abilities:
		if not ability is Dictionary:
			continue

		var ability_id: String = ability.get("id", "")

		match ability_id:
			"overwatch":
				# Sniper overwatch ability
				if context.get("is_overwatch", false):
					modifiers.special_abilities.append("overwatch")
					# Overwatch gets bonus to attack
					modifiers.total_attack_multiplier *= 1.15
			"entrench":
				# Soldier entrench ability
				if context.get("is_entrenched", false):
					modifiers.special_abilities.append("entrench")
					modifiers.total_defense_bonus += 5
			"stealth":
				# Scout stealth ability
				if context.get("is_stealthed", false):
					modifiers.special_abilities.append("stealth")
					# Ambush from stealth gets massive bonus
					if context.get("is_ambush", false):
						modifiers.total_attack_multiplier *= 1.5
			_:
				pass


## Checks if unit has immunity to morale loss
##
## @param unit: Unit to check
## @return: True if immune to morale effects
static func is_morale_immune(unit: Dictionary) -> bool:
	var unit_type: String = unit.get("unit_type", "")
	var culture: String = unit.get("culture", "")

	# Berserkers and cybernetic soldiers are immune to morale
	if unit_type in ["berserker", "cybernetic_soldier"]:
		return true

	# Technocracy culture units are immune
	if culture == "technocracy":
		return true

	return false
