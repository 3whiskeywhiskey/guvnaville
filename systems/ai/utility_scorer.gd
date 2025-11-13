## UtilityScorer - Utility-based AI action scoring system
##
## Evaluates and scores possible actions for AI factions using utility theory.
## Considers immediate benefits, risks, strategic alignment, and personality
## preferences to generate action scores.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name UtilityScorer
extends RefCounted

# Preload dependencies for Godot 4.5.1 compatibility
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIThreatAssessment = preload("res://systems/ai/ai_threat_assessment.gd")

## Reference to game state for evaluation (mock-friendly)
var _game_state: Variant = null

## Personality weights for scoring modifiers
var _personality_weights: Dictionary = {}


## Constructor
func _init(game_state: Variant = null) -> void:
	_game_state = game_state
	_load_default_weights()


## Loads default personality weights
func _load_default_weights() -> void:
	_personality_weights = {
		"military": 1.0,
		"economic": 1.0,
		"expansion": 1.0,
		"defense": 1.0,
		"trade": 1.0,
		"culture": 1.0,
		"risk_tolerance": 0.5
	}


## Sets personality weights for scoring
func set_personality_weights(weights: Dictionary) -> void:
	for key in weights:
		if _personality_weights.has(key):
			_personality_weights[key] = weights[key]


## Scores the value of expanding to a tile
##
## Scoring Factors:
## - Resources on tile (+10 per resource type)
## - Unique locations (+30 for valuable sites)
## - Strategic position (+15 if borders enemies)
## - Defensibility (+10 for good terrain)
## - Distance from borders (-5 per tile distance)
##
## @param target_tile: Position to evaluate
## @param faction_id: ID of evaluating faction
## @param game_state: Current game state (optional, uses stored if not provided)
## @returns: Float score (0.0 to 100.0)
func score_expansion(target_tile: Vector3i, faction_id: int, game_state: Variant = null) -> float:
	var state = game_state if game_state != null else _game_state

	# Basic validation
	if state == null or faction_id < 0:
		return 0.0

	var score: float = 30.0  # Base expansion value

	# Mock scoring for MVP (would use real tile data in production)
	# Resource value
	var resource_score = randf_range(0.0, 20.0) * _personality_weights.get("economic", 1.0)
	score += resource_score

	# Strategic position (proximity to enemies)
	var strategic_score = randf_range(0.0, 15.0) * _personality_weights.get("military", 1.0)
	score += strategic_score

	# Defensibility
	var defense_score = randf_range(0.0, 10.0) * _personality_weights.get("defense", 1.0)
	score += defense_score

	# Distance penalty (simplified - would use real pathfinding)
	var distance = target_tile.length()
	var distance_penalty = min(distance * 2.0, 25.0)
	score -= distance_penalty

	return clampf(score, 0.0, 100.0)


## Scores combat viability (chance of success)
##
## Uses combat strength ratio to determine expected outcome.
##
## @param attacker_units: Array of attacking units (mocked for MVP)
## @param defender_units: Array of defending units (mocked for MVP)
## @param terrain: Tile where combat occurs (mocked for MVP)
## @returns: Float score (-100 to +100)
##   - Positive: Attacker favored
##   - Negative: Defender favored
##   - Magnitude indicates confidence
func score_combat(attacker_units: Array, defender_units: Array, terrain: Variant = null) -> float:
	if attacker_units.is_empty() or defender_units.is_empty():
		return 0.0

	# Calculate relative strength (simplified for MVP)
	var attacker_strength: float = 0.0
	var defender_strength: float = 0.0

	# Mock strength calculation
	for _unit in attacker_units:
		attacker_strength += randf_range(10.0, 30.0)

	for _unit in defender_units:
		defender_strength += randf_range(10.0, 30.0)

	# Terrain defense bonus
	if terrain != null:
		defender_strength *= 1.2

	# Calculate strength ratio
	var ratio = attacker_strength / max(defender_strength, 1.0)

	# Convert to score (-100 to +100)
	var score: float = 0.0
	if ratio > 1.5:
		score = 75.0  # Strong advantage
	elif ratio > 1.2:
		score = 50.0  # Moderate advantage
	elif ratio > 1.0:
		score = 25.0  # Slight advantage
	elif ratio > 0.8:
		score = -25.0  # Slight disadvantage
	elif ratio > 0.6:
		score = -50.0  # Moderate disadvantage
	else:
		score = -75.0  # Strong disadvantage

	# Apply risk tolerance
	score *= _personality_weights.get("risk_tolerance", 0.5)

	return clampf(score, -100.0, 100.0)


## Scores production choice value
##
## Evaluates how valuable producing a specific unit/building is.
##
## @param production_type: Type of unit/building to produce
## @param faction_id: ID of faction considering production
## @param current_needs: Dictionary of current strategic needs
## @returns: Float score (0.0 to 100.0)
func score_production(production_type: String, faction_id: int, current_needs: Dictionary = {}) -> float:
	if production_type.is_empty() or faction_id < 0:
		return 0.0

	var score: float = 50.0  # Base value

	# Military units
	if production_type in ["militia", "soldier", "heavy", "sniper"]:
		score += 20.0 * _personality_weights.get("military", 1.0)

		# Bonus if under military pressure
		if current_needs.get("military_pressure", 0.0) > 0.5:
			score += 30.0

	# Economic buildings
	elif production_type in ["market", "farm", "factory", "mine"]:
		score += 25.0 * _personality_weights.get("economic", 1.0)

		# Bonus if resources are low
		if current_needs.get("resource_shortage", false):
			score += 35.0

	# Support units
	elif production_type in ["scout", "engineer", "medic", "trader"]:
		score += 15.0 * _personality_weights.get("expansion", 1.0)

	# Defensive structures
	elif production_type in ["fortification", "wall", "bunker"]:
		score += 20.0 * _personality_weights.get("defense", 1.0)

	return clampf(score, 0.0, 100.0)


## Scores culture node selection
##
## Evaluates how valuable unlocking a culture node is for current strategy.
##
## @param node_id: Culture node identifier
## @param faction_id: ID of faction evaluating node
## @param active_goals: Current faction goals
## @returns: Float score (0.0 to 100.0)
func score_culture_node(node_id: String, faction_id: int, active_goals: Array = []) -> float:
	if node_id.is_empty() or faction_id < 0:
		return 0.0

	var score: float = 40.0  # Base culture value

	# Military culture nodes
	if "military" in node_id or "combat" in node_id or "weapon" in node_id:
		score += 25.0 * _personality_weights.get("military", 1.0)

	# Economic culture nodes
	elif "trade" in node_id or "economic" in node_id or "resource" in node_id:
		score += 30.0 * _personality_weights.get("economic", 1.0)

	# Expansion culture nodes
	elif "expansion" in node_id or "scout" in node_id:
		score += 20.0 * _personality_weights.get("expansion", 1.0)

	# Defensive culture nodes
	elif "defense" in node_id or "fortification" in node_id:
		score += 20.0 * _personality_weights.get("defense", 1.0)

	# Synergy bonus for active goals
	for goal in active_goals:
		if goal is AIGoal:
			match goal.type:
				AIGoal.GoalType.MILITARY_CONQUEST:
					if "military" in node_id:
						score += 15.0
				AIGoal.GoalType.ECONOMIC_GROWTH:
					if "economic" in node_id or "trade" in node_id:
						score += 15.0
				AIGoal.GoalType.EXPAND_TERRITORY:
					if "expansion" in node_id:
						score += 15.0
				AIGoal.GoalType.DEFEND_TERRITORY:
					if "defense" in node_id:
						score += 15.0

	return clampf(score, 0.0, 100.0)


## Scores trade route value
##
## Evaluates potential benefit of establishing trade with another faction.
##
## @param target_faction: ID of faction to trade with
## @param faction_id: ID of faction evaluating trade
## @param relationship: Current diplomatic relationship
## @returns: Float score (0.0 to 100.0)
func score_trade(target_faction: int, faction_id: int, relationship: int = 1) -> float:
	if target_faction == faction_id or target_faction < 0:
		return 0.0

	var score: float = 40.0 * _personality_weights.get("trade", 1.0)

	# Relationship bonus
	match relationship:
		AIThreatAssessment.Relationship.ALLY:
			score += 40.0
		AIThreatAssessment.Relationship.FRIENDLY:
			score += 25.0
		AIThreatAssessment.Relationship.NEUTRAL:
			score += 10.0
		AIThreatAssessment.Relationship.HOSTILE:
			score -= 50.0

	# Economic personality bonus
	score += 20.0 * _personality_weights.get("economic", 1.0)

	return clampf(score, 0.0, 100.0)


## Scores defensive action value
##
## Evaluates how valuable a defensive action (fortify, entrench, etc.) is.
##
## @param location: Position to defend
## @param threat_level: Current threat level at location (0-100)
## @returns: Float score (0.0 to 100.0)
func score_defense(location: Vector3i, threat_level: float = 50.0) -> float:
	var score: float = threat_level * _personality_weights.get("defense", 1.0)

	# Higher value if location is strategic
	# (simplified - would check for resources, borders, etc.)
	if location.length() < 20:  # Near core territory
		score += 20.0

	return clampf(score, 0.0, 100.0)
