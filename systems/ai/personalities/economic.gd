## EconomicPersonality - Resource and growth focused AI personality
##
## "Wealth is power."
##
## Characteristics:
## - Maximizes resource production and trade
## - Avoids military conflict when possible
## - Pursues diplomatic and economic victories
## - High trade engagement
## - Moderate risk tolerance
## - Flexible victory condition (adapts to opportunities)
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name EconomicPersonality
extends RefCounted

# Preload dependencies for Godot 4.5.1 compatibility
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")

## Personality name
const PERSONALITY_NAME: String = "economic"

## Personality weights for utility scoring
const WEIGHTS: Dictionary = {
	"military": 0.6,           # -40% military focus
	"economic": 1.5,           # +50% economic focus
	"expansion": 1.1,          # +10% expansion (for resources)
	"defense": 0.9,            # -10% defense focus
	"trade": 1.6,              # +60% trade focus
	"culture": 1.2,            # +20% culture focus
	"risk_tolerance": 0.55     # 55% risk tolerance (moderate)
}

## Goal priorities for economic AI
const GOAL_PRIORITIES: Dictionary = {
	AIGoal.GoalType.ECONOMIC_GROWTH: 95.0,
	AIGoal.GoalType.ESTABLISH_TRADE: 85.0,
	AIGoal.GoalType.SECURE_RESOURCE: 70.0,
	AIGoal.GoalType.CULTURAL_VICTORY: 60.0,
	AIGoal.GoalType.TECH_ADVANCEMENT: 60.0,
	AIGoal.GoalType.EXPAND_TERRITORY: 50.0,
	AIGoal.GoalType.DEFEND_TERRITORY: 50.0,
	AIGoal.GoalType.MILITARY_CONQUEST: 10.0
}

## Production distribution (percentages)
const PRODUCTION_DISTRIBUTION: Dictionary = {
	"military_units": 0.25,      # 25% military (minimal defense)
	"economic_buildings": 0.65,  # 65% economic buildings
	"infrastructure": 0.10       # 10% cultural/infrastructure
}

## Combat willingness threshold (avoids combat unless favorable)
const COMBAT_THRESHOLD: float = 0.75

## Expansion rate
const EXPANSION_RATE: String = "opportunistic"


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


## Modifies action score based on economic personality
##
## @param base_score: Base score from utility scorer
## @param action_type: Type of action being scored
## @returns: Modified score
static func modify_action_score(base_score: float, action_type: int) -> float:
	var score = base_score

	match action_type:
		AIAction.ActionType.TRADE:
			# Strong bonus for trade
			score *= 1.8
		AIAction.ActionType.BUILD_BUILDING:
			# Bonus for economic buildings
			score *= 1.4
		AIAction.ActionType.SCAVENGE:
			# Bonus for resource gathering
			score *= 1.3
		AIAction.ActionType.ATTACK:
			# Penalty for attacking
			score *= 0.6
		AIAction.ActionType.EXPAND_TERRITORY:
			# Moderate bonus for expansion (resources)
			score *= 1.1
		AIAction.ActionType.RESEARCH:
			# Bonus for research/culture
			score *= 1.2

	return score


## Selects culture nodes to prioritize
##
## @param available_nodes: Array of available culture node IDs
## @returns: Filtered/sorted array prioritizing economic/trade nodes
static func prioritize_culture_nodes(available_nodes: Array) -> Array:
	var economic_nodes: Array = []
	var trade_nodes: Array = []
	var other_nodes: Array = []

	for node_id in available_nodes:
		var node_str = str(node_id).to_lower()
		if "economic" in node_str or "resource" in node_str or "production" in node_str:
			economic_nodes.append(node_id)
		elif "trade" in node_str or "market" in node_str or "commerce" in node_str:
			trade_nodes.append(node_id)
		else:
			other_nodes.append(node_id)

	# Return economic first, then trade, then others
	economic_nodes.append_array(trade_nodes)
	economic_nodes.append_array(other_nodes)
	return economic_nodes


## Returns preferred production given current situation
##
## @param situation: Dictionary describing current faction state
## @returns: String production type identifier
static func select_production(situation: Dictionary) -> String:
	var military_ratio = situation.get("military_units_ratio", 0.5)
	var under_attack = situation.get("under_attack", false)
	var resources = situation.get("resources", {})
	var trade_routes = situation.get("trade_routes", 0)

	# If under attack, build minimal defense
	if under_attack:
		return _select_defensive_unit(resources)

	# Maintain minimum military (25%)
	if military_ratio < 0.20:
		return _select_defensive_unit(resources)

	# Prioritize traders if lacking trade routes
	if trade_routes < 3 and resources.get("scrap", 0) > 40:
		return "trader"

	# Focus on economic buildings (65% of time)
	if randf() < 0.65:
		return _select_economic_building(resources)

	# Otherwise build supporting infrastructure
	return _select_infrastructure(resources)


## Selects defensive unit to build (minimal military)
static func _select_defensive_unit(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)

	if scrap > 50:
		return "soldier"
	else:
		return "militia"


## Selects economic building to build
static func _select_economic_building(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)
	var food = resources.get("food", 0)

	# Prioritize based on resource needs
	if food < 100:
		return "farm"
	elif scrap > 100:
		return "factory"
	elif scrap > 70:
		return "market"
	elif scrap > 50:
		return "workshop"
	else:
		return "scrap_yard"


## Selects infrastructure to build
static func _select_infrastructure(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)

	if scrap > 80:
		return "lab"
	elif scrap > 50:
		return "library"
	else:
		return "monument"


## Returns description of this personality
static func get_description() -> String:
	return "Economic AI: Maximizes resource production and trade. Avoids conflict, pursues economic/diplomatic victory."
