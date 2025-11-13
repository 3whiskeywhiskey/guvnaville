## DefensivePersonality - Territory defense and fortification AI personality
##
## "Secure what you have before seeking more."
##
## Characteristics:
## - Prioritizes fortification and defense
## - Expands cautiously into secure territory
## - Builds strong economy behind defensive lines
## - High emphasis on territory control
## - Low risk tolerance
## - Prefers cultural or diplomatic victory
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name DefensivePersonality
extends RefCounted

## Personality name
const PERSONALITY_NAME: String = "defensive"

## Personality weights for utility scoring
const WEIGHTS: Dictionary = {
	"military": 0.8,           # -20% military focus
	"economic": 1.3,           # +30% economic focus
	"expansion": 0.7,          # -30% expansion focus
	"defense": 1.5,            # +50% defense focus
	"trade": 1.2,              # +20% trade focus
	"culture": 1.1,            # +10% culture focus
	"risk_tolerance": 0.25     # 25% risk tolerance (low)
}

## Goal priorities for defensive AI
const GOAL_PRIORITIES: Dictionary = {
	AIGoal.GoalType.DEFEND_TERRITORY: 95.0,
	AIGoal.GoalType.ECONOMIC_GROWTH: 80.0,
	AIGoal.GoalType.ESTABLISH_TRADE: 70.0,
	AIGoal.GoalType.CULTURAL_VICTORY: 60.0,
	AIGoal.GoalType.TECH_ADVANCEMENT: 55.0,
	AIGoal.GoalType.EXPAND_TERRITORY: 40.0,
	AIGoal.GoalType.SECURE_RESOURCE: 40.0,
	AIGoal.GoalType.MILITARY_CONQUEST: 20.0
}

## Production distribution (percentages)
const PRODUCTION_DISTRIBUTION: Dictionary = {
	"military_units": 0.40,      # 40% defensive military
	"economic_buildings": 0.50,  # 50% economic buildings
	"infrastructure": 0.10       # 10% infrastructure and culture
}

## Combat willingness threshold (only attacks at 90/10 odds or better)
const COMBAT_THRESHOLD: float = 0.9

## Expansion rate
const EXPANSION_RATE: String = "slow"


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


## Modifies action score based on defensive personality
##
## @param base_score: Base score from utility scorer
## @param action_type: Type of action being scored
## @returns: Modified score
static func modify_action_score(base_score: float, action_type: int) -> float:
	var score = base_score

	match action_type:
		AIAction.ActionType.ATTACK:
			# Penalty for attacking (unless very favorable)
			score *= 0.5
		AIAction.ActionType.FORTIFY:
			# Bonus for defensive actions
			score *= 1.6
		AIAction.ActionType.TRADE:
			# Bonus for trade
			score *= 1.3
		AIAction.ActionType.BUILD_BUILDING:
			# Bonus for economic buildings
			score *= 1.2
		AIAction.ActionType.DEFEND_TERRITORY:
			# Strong bonus for defending
			score *= 1.8

	return score


## Selects culture nodes to prioritize
##
## @param available_nodes: Array of available culture node IDs
## @returns: Filtered/sorted array prioritizing defensive/economic nodes
static func prioritize_culture_nodes(available_nodes: Array) -> Array:
	var defensive_nodes: Array = []
	var economic_nodes: Array = []
	var other_nodes: Array = []

	for node_id in available_nodes:
		var node_str = str(node_id).to_lower()
		if "defense" in node_str or "fortification" in node_str or "wall" in node_str:
			defensive_nodes.append(node_id)
		elif "economic" in node_str or "trade" in node_str or "resource" in node_str:
			economic_nodes.append(node_id)
		else:
			other_nodes.append(node_id)

	# Return defensive first, then economic, then others
	defensive_nodes.append_array(economic_nodes)
	defensive_nodes.append_array(other_nodes)
	return defensive_nodes


## Returns preferred production given current situation
##
## @param situation: Dictionary describing current faction state
## @returns: String production type identifier
static func select_production(situation: Dictionary) -> String:
	var military_ratio = situation.get("military_units_ratio", 0.5)
	var under_attack = situation.get("under_attack", false)
	var resources = situation.get("resources", {})
	var has_fortifications = situation.get("has_fortifications", false)

	# If under attack, build defensive military
	if under_attack:
		if not has_fortifications:
			return "fortification"
		return _select_defensive_unit(resources)

	# Maintain minimum military presence (40%)
	if military_ratio < 0.35:
		return _select_defensive_unit(resources)

	# Focus on economic buildings (50% of time)
	if randf() < 0.5:
		return _select_economic_building(resources)

	# Otherwise build defenses or infrastructure
	if not has_fortifications or randf() < 0.3:
		return "fortification"

	return _select_economic_building(resources)


## Selects defensive unit to build
static func _select_defensive_unit(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)

	# Prefer soldiers and defensive units
	if scrap > 70:
		return "engineer"  # Can build fortifications
	elif scrap > 50:
		return "soldier"
	else:
		return "militia"


## Selects economic building to build
static func _select_economic_building(resources: Dictionary) -> String:
	var scrap = resources.get("scrap", 0)
	var food = resources.get("food", 0)

	if food < 50:
		return "farm"
	elif scrap > 80:
		return "factory"
	elif scrap > 60:
		return "market"
	else:
		return "workshop"


## Returns description of this personality
static func get_description() -> String:
	return "Defensive AI: Focuses on territory defense and economic growth. Low risk tolerance, avoids unnecessary combat."
