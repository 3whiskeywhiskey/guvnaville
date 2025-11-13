class_name CombatModifiers
extends Resource

## Encapsulates all combat modifiers for a specific engagement
##
## This class stores all modifiers that affect combat calculations including
## terrain, elevation, cover, cultural bonuses, and special conditions.

## Terrain type modifier (typically 0.75 - 1.25)
var terrain_modifier: float = 1.0

## Defense bonus from cover (0-15)
var cover_bonus: int = 0

## Elevation modifier: +25% higher, -15% lower, 1.0 same
var elevation_modifier: float = 1.0

## Flanking bonus: +15% if flanking
var flanking_bonus: float = 0.0

## Fortification bonus: +5 to +15 defense
var fortification_bonus: int = 0

## Culture-specific bonuses (Dictionary)
var cultural_bonuses: Dictionary = {}

## Weather effects (future feature, default 1.0)
var weather_modifier: float = 1.0

## Reduced if unsupplied (0.5 if unsupplied, 1.0 if supplied)
var supply_penalty: float = 1.0

## Morale effects on effectiveness
var morale_modifier: float = 1.0

## Veteran/Elite bonuses (1.0 + experience_level * 0.1)
var unit_experience_bonus: float = 1.0

## Active special abilities
var special_abilities: Array = []

## Combined attack multiplier (calculated)
var total_attack_multiplier: float = 1.0

## Combined defense bonus (calculated)
var total_defense_bonus: int = 0


func _init():
	pass


## Calculates and updates the total modifiers
func calculate_totals() -> void:
	# Calculate total attack multiplier
	total_attack_multiplier = (
		terrain_modifier *
		elevation_modifier *
		weather_modifier *
		supply_penalty *
		morale_modifier *
		unit_experience_bonus *
		(1.0 + flanking_bonus)
	)

	# Add cultural attack bonuses
	for bonus_key in cultural_bonuses:
		if bonus_key.ends_with("_attack_bonus"):
			total_attack_multiplier *= (1.0 + cultural_bonuses[bonus_key])

	# Calculate total defense bonus
	total_defense_bonus = cover_bonus + fortification_bonus

	# Add cultural defense bonuses
	for bonus_key in cultural_bonuses:
		if bonus_key.ends_with("_defense_bonus"):
			total_defense_bonus += int(cultural_bonuses[bonus_key])


## Creates a string representation of the modifiers
func to_string() -> String:
	return "CombatModifiers(atk_mult=%.2f, def_bonus=%d, terrain=%.2f, elev=%.2f, cover=%d)" % [
		total_attack_multiplier, total_defense_bonus, terrain_modifier,
		elevation_modifier, cover_bonus
	]


## Serializes modifiers to dictionary
func to_dict() -> Dictionary:
	return {
		"terrain_modifier": terrain_modifier,
		"cover_bonus": cover_bonus,
		"elevation_modifier": elevation_modifier,
		"flanking_bonus": flanking_bonus,
		"fortification_bonus": fortification_bonus,
		"cultural_bonuses": cultural_bonuses,
		"weather_modifier": weather_modifier,
		"supply_penalty": supply_penalty,
		"morale_modifier": morale_modifier,
		"unit_experience_bonus": unit_experience_bonus,
		"total_attack_multiplier": total_attack_multiplier,
		"total_defense_bonus": total_defense_bonus
	}
