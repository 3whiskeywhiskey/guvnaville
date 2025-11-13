## AggressivePersonality - Military-focused aggressive AI personality
##
## "The best defense is a good offense."
##
## Characteristics:
## - Prioritizes military production (+40% weight)
## - Seeks early combat opportunities
## - Expands aggressively into contested territory
## - Less concerned with economic development
## - High risk tolerance
## - Prefers military victory condition
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name AggressivePersonality
extends RefCounted

# Preload dependencies for Godot 4.5.1 compatibility
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")

## Personality name
const PERSONALITY_NAME: String = "aggressive"

## Personality weights for utility scoring
const WEIGHTS: Dictionary = {
	"military": 1.4,           # +40% military focus
	"economic": 0.7,           # -30% economic focus
	"expansion": 1.3,          # +30% expansion focus
	"defense": 0.6,            # -40% defense focus
	"trade": 0.4,              # -60% trade focus
	"culture": 0.8,            # -20% culture focus
	"risk_tolerance": 0.85     # 85% risk tolerance (high)
}

## Goal priorities for aggressive AI
const GOAL_PRIORITIES: Dictionary = {
	AIGoal.GoalType.MILITARY_CONQUEST: 90.0,
	AIGoal.GoalType.EXPAND_TERRITORY: 70.0,
	AIGoal.GoalType.SECURE_RESOURCE: 60.0,
	AIGoal.GoalType.ECONOMIC_GROWTH: 40.0,
	AIGoal.GoalType.DEFEND_TERRITORY: 30.0,
	AIGoal.GoalType.ESTABLISH_TRADE: 20.0,
	AIGoal.GoalType.CULTURAL_VICTORY: 20.0,
	AIGoal.GoalType.TECH_ADVANCEMENT: 40.0
}

## Production distribution (percentages)
const PRODUCTION_DISTRIBUTION: Dictionary = {
	"military_units": 0.70,      # 70% military units
	"economic_buildings": 0.20,  # 20% economic (to sustain war)
	"infrastructure": 0.10       # 10% infrastructure
}

## Combat willingness threshold (attacks at 60/40 odds vs 80/20 for defensive)
const COMBAT_THRESHOLD: float = 0.6

## Expansion rate
const EXPANSION_RATE: String = "fast"


## Returns personality weights for utility scorer
static func get_weights() -> Dictionary:
	return WEIGHTS


## Returns goal priorities
static func get_goal_priorities() -> Dictionary:
	return GOAL_PRIORITIES


## Returns production distribution preferences
static func get_production_distribution() -> Dictionary:
	return PRODUCTION_DISTRIBUTION


## Returns combat willingness threshold
static func get_combat_threshold() -> float:
	return COMBAT_THRESHOLD


## Modifies action score based on aggressive personality
##
## @param base_score: Base score from utility scorer
## @param action_type: Type of action being scored
## @returns: Modified score
static func modify_action_score(base_score: float, action_type: int) -> float:
	var score = base_score

	match action_type:
		AIAction.ActionType.ATTACK:
			# Bonus for attacking
			score *= 1.5
		AIAction.ActionType.BUILD_UNIT:
			# Bonus for military production
			score *= 1.2
		AIAction.ActionType.FORTIFY:
			# Penalty for defensive actions
			score *= 0.6
		AIAction.ActionType.TRADE:
			# Penalty for trade
			score *= 0.4
		AIAction.ActionType.EXPAND_TERRITORY:
			# Bonus for expansion
			score *= 1.3

	return score


## Selects culture nodes to prioritize
##
## @param available_nodes: Array of available culture node IDs
## @returns: Filtered/sorted array prioritizing military nodes
static func prioritize_culture_nodes(available_nodes: Array) -> Array:
	var military_nodes: Array = []
	var other_nodes: Array = []

	for node_id in available_nodes:
		var node_str = str(node_id).to_lower()
		if "military" in node_str or "combat" in node_str or "weapon" in node_str or "attack" in node_str:
			military_nodes.append(node_id)
		else:
			other_nodes.append(node_id)

	# Return military nodes first, then others
	military_nodes.append_array(other_nodes)
	return military_nodes


## Returns preferred production given current situation
##
## @param situation: Dictionary describing current faction state
## @returns: String production type identifier
static func select_production(situation: Dictionary) -> String:
	var military_ratio = situation.get("military_units_ratio", 0.5)
	var under_attack = situation.get("under_attack", false)
	var resources = situation.get("resources", {})

	# If under attack, build military
	if under_attack:
		return _select_military_unit(resources)

	# If military ratio below target (70%), build military
	if military_ratio < 0.65:
		return _select_military_unit(resources)

	# Otherwise, build economic support (20% of time)
	if randf() < 0.2:
		return _select_economic_building(resources)

	# Default to military
	return _select_military_unit(resources)


## Selects military unit to build
static func _select_military_unit(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)
	var fuel = resources.get("fuel", 0)

	# Prefer heavy units if we can afford them
	if scrap > 100 and fuel > 20:
		return "heavy"
	elif scrap > 70:
		return "sniper"
	elif scrap > 50:
		return "soldier"
	else:
		return "militia"


## Selects economic building to build
static func _select_economic_building(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)

	if scrap > 80:
		return "factory"
	elif scrap > 50:
		return "workshop"
	else:
		return "scrap_yard"


## Returns description of this personality
static func get_description() -> String:
	return "Aggressive AI: Prioritizes military conquest and rapid expansion. High risk tolerance, seeks combat opportunities."
