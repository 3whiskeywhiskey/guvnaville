## TacticalAI - Basic combat AI for MVP
##
## Handles tactical combat decisions for AI units. MVP version focuses on
## auto-resolve recommendations. Full tactical combat AI is post-MVP.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name TacticalAI
extends RefCounted

# Preload dependencies for Godot 4.5.1 compatibility
const UtilityScorer = preload("res://systems/ai/utility_scorer.gd")

## Utility scorer for combat evaluation
var _scorer: UtilityScorer

## Risk tolerance (0.0 = very cautious, 1.0 = very aggressive)
var _risk_tolerance: float = 0.5


## Constructor
func _init(risk_tolerance: float = 0.5) -> void:
	_risk_tolerance = clampf(risk_tolerance, 0.0, 1.0)
	_scorer = UtilityScorer.new()


## Selects action for unit in tactical combat
##
## Note: MVP focuses on auto-resolve. This is a stub for future tactical combat.
##
## @param unit_id: ID of the unit
## @param battle_state: Current tactical battle state (Variant for mock compatibility)
## @returns: Dictionary with action details (format TBD for post-MVP)
func select_unit_action(unit_id: int, battle_state: Variant = null) -> Dictionary:
	if unit_id < 0:
		return {"action": "wait"}

	# MVP implementation: Recommend auto-resolve
	return {
		"action": "auto_resolve",
		"unit_id": unit_id,
		"confidence": 0.8
	}


## Evaluates whether to engage in combat
##
## @param attacker_units: Array of potential attacking units
## @param defender_units: Array of defending units
## @param terrain: Terrain/tile information
## @returns: Dictionary with decision and reasoning
func evaluate_combat_engagement(
	attacker_units: Array,
	defender_units: Array,
	terrain: Variant = null
) -> Dictionary:
	if attacker_units.is_empty() or defender_units.is_empty():
		return {
			"engage": false,
			"reason": "invalid_units",
			"confidence": 0.0
		}

	# Score the combat
	var combat_score = _scorer.score_combat(attacker_units, defender_units, terrain)

	# Determine threshold based on risk tolerance
	var threshold = lerp(-20.0, 40.0, _risk_tolerance)

	var should_engage = combat_score > threshold

	return {
		"engage": should_engage,
		"combat_score": combat_score,
		"threshold": threshold,
		"reason": "favorable" if should_engage else "unfavorable",
		"confidence": abs(combat_score) / 100.0,
		"expected_casualties": _estimate_casualties(combat_score, attacker_units.size())
	}


## Recommends whether to use tactical combat or auto-resolve
##
## @param importance: Strategic importance of battle (0.0-1.0)
## @param combat_score: Expected combat outcome score
## @returns: True if tactical combat recommended, false for auto-resolve
func recommend_tactical_combat(importance: float, combat_score: float) -> bool:
	# MVP: Recommend auto-resolve for most battles
	# Only use tactical combat for very important battles

	# High importance battles (>0.8) with uncertain outcome
	if importance > 0.8 and abs(combat_score) < 30.0:
		return true

	# Otherwise use auto-resolve
	return false


## Selects target for attack
##
## @param attacker_id: ID of attacking unit
## @param potential_targets: Array of potential target unit IDs
## @param game_state: Current game state (for target evaluation)
## @returns: Dictionary with target selection
func select_attack_target(
	attacker_id: int,
	potential_targets: Array,
	game_state: Variant = null
) -> Dictionary:
	if potential_targets.is_empty():
		return {
			"has_target": false,
			"target_id": -1
		}

	# MVP: Simple target selection based on mock priorities
	# Priority: Weakest unit, highest value target, closest

	var best_target = potential_targets[0]
	var best_score = 0.0

	for target in potential_targets:
		var score = randf_range(50.0, 100.0)  # Mock scoring

		if score > best_score:
			best_score = score
			best_target = target

	return {
		"has_target": true,
		"target_id": best_target,
		"priority": best_score,
		"reason": "high_value_target"
	}


## Selects special ability to use in combat
##
## @param unit_id: ID of unit
## @param available_abilities: Array of ability names
## @param situation: Combat situation description
## @returns: String ability name to use, or "" for none
func select_ability(
	unit_id: int,
	available_abilities: Array,
	situation: Dictionary = {}
) -> String:
	if available_abilities.is_empty():
		return ""

	# MVP: Simple ability selection
	# Prefer defensive abilities when outnumbered
	# Prefer offensive abilities when advantaged

	var is_outnumbered = situation.get("outnumbered", false)
	var has_advantage = situation.get("has_advantage", false)

	for ability in available_abilities:
		var ability_name = str(ability).to_lower()

		if is_outnumbered and ("heal" in ability_name or "defend" in ability_name):
			return ability

		if has_advantage and ("attack" in ability_name or "damage" in ability_name):
			return ability

	# Default: Use first available ability
	return available_abilities[0] if available_abilities.size() > 0 else ""


## Estimates casualties from combat
##
## @param combat_score: Expected combat outcome score
## @param unit_count: Number of attacking units
## @returns: Estimated casualties as percentage (0.0-1.0)
func _estimate_casualties(combat_score: float, unit_count: int) -> float:
	# Positive score = attacker advantage, lower casualties
	# Negative score = attacker disadvantage, higher casualties

	var base_casualties = 0.3  # 30% base casualty rate

	if combat_score > 50.0:
		# Strong advantage: low casualties
		return 0.1
	elif combat_score > 0.0:
		# Moderate advantage: below average casualties
		return lerp(0.1, 0.25, 1.0 - (combat_score / 50.0))
	elif combat_score > -50.0:
		# Disadvantage: above average casualties
		return lerp(0.3, 0.6, abs(combat_score) / 50.0)
	else:
		# Severe disadvantage: heavy casualties
		return 0.7

## Plans retreat conditions
##
## @param current_hp_ratio: Current HP as ratio of max (0.0-1.0)
## @param morale: Current morale (0-100)
## @returns: True if should retreat
func should_retreat(current_hp_ratio: float, morale: float) -> bool:
	# Retreat thresholds based on risk tolerance
	var hp_threshold = lerp(0.5, 0.2, _risk_tolerance)
	var morale_threshold = lerp(60.0, 30.0, _risk_tolerance)

	return current_hp_ratio < hp_threshold or morale < morale_threshold


## Sets risk tolerance for combat decisions
func set_risk_tolerance(tolerance: float) -> void:
	_risk_tolerance = clampf(tolerance, 0.0, 1.0)
	if _scorer:
		_scorer.set_personality_weights({"risk_tolerance": _risk_tolerance})
