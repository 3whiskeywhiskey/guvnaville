extends GutTest

## Unit tests for AI Personalities
## Tests Aggressive, Defensive, and Economic personality behaviors
##
## @agent: Agent 7

func test_aggressive_personality_weights():
	var weights = AggressivePersonality.get_weights()

	assert_not_null(weights, "Aggressive weights should exist")
	assert_gt(weights.military, 1.0, "Aggressive should prioritize military")
	assert_lt(weights.economic, 1.0, "Aggressive should deprioritize economy")
	assert_gt(weights.risk_tolerance, 0.7, "Aggressive should have high risk tolerance")

func test_defensive_personality_weights():
	var weights = DefensivePersonality.get_weights()

	assert_not_null(weights, "Defensive weights should exist")
	assert_gt(weights.defense, 1.0, "Defensive should prioritize defense")
	assert_lt(weights.military, 1.0, "Defensive should deprioritize military")
	assert_lt(weights.risk_tolerance, 0.5, "Defensive should have low risk tolerance")

func test_economic_personality_weights():
	var weights = EconomicPersonality.get_weights()

	assert_not_null(weights, "Economic weights should exist")
	assert_gt(weights.economic, 1.0, "Economic should prioritize economy")
	assert_gt(weights.trade, 1.0, "Economic should prioritize trade")
	assert_lt(weights.military, 1.0, "Economic should deprioritize military")

func test_aggressive_goal_priorities():
	var priorities = AggressivePersonality.get_goal_priorities()

	assert_gt(priorities[AIGoal.GoalType.MILITARY_CONQUEST], 80.0, "Military conquest should be high priority")
	assert_gt(priorities[AIGoal.GoalType.MILITARY_CONQUEST], priorities[AIGoal.GoalType.ECONOMIC_GROWTH],
		"Military should be higher priority than economy")

func test_defensive_goal_priorities():
	var priorities = DefensivePersonality.get_goal_priorities()

	assert_gt(priorities[AIGoal.GoalType.DEFEND_TERRITORY], 90.0, "Defend territory should be highest priority")
	assert_gt(priorities[AIGoal.GoalType.DEFEND_TERRITORY], priorities[AIGoal.GoalType.MILITARY_CONQUEST],
		"Defense should be higher priority than conquest")

func test_economic_goal_priorities():
	var priorities = EconomicPersonality.get_goal_priorities()

	assert_gt(priorities[AIGoal.GoalType.ECONOMIC_GROWTH], 90.0, "Economic growth should be highest priority")
	assert_gt(priorities[AIGoal.GoalType.ESTABLISH_TRADE], 80.0, "Trade should be high priority")
	assert_gt(priorities[AIGoal.GoalType.ECONOMIC_GROWTH], priorities[AIGoal.GoalType.MILITARY_CONQUEST],
		"Economy should be higher priority than conquest")

func test_aggressive_production_distribution():
	var dist = AggressivePersonality.get_production_distribution()

	assert_ge(dist.military_units, 0.6, "Aggressive should build 60%+ military")
	assert_lt(dist.economic_buildings, 0.3, "Aggressive should build less than 30% economic")

func test_defensive_production_distribution():
	var dist = DefensivePersonality.get_production_distribution()

	assert_ge(dist.economic_buildings, 0.4, "Defensive should build 40%+ economic")
	assert_le(dist.military_units, 0.5, "Defensive should build 50% or less military")

func test_economic_production_distribution():
	var dist = EconomicPersonality.get_production_distribution()

	assert_ge(dist.economic_buildings, 0.6, "Economic should build 60%+ economic")
	assert_le(dist.military_units, 0.3, "Economic should build 30% or less military")

func test_combat_threshold_differences():
	var agg_threshold = AggressivePersonality.get_combat_threshold()
	var def_threshold = DefensivePersonality.get_combat_threshold()
	var eco_threshold = EconomicPersonality.get_combat_threshold()

	assert_lt(agg_threshold, def_threshold, "Aggressive should have lower combat threshold than defensive")
	assert_lt(agg_threshold, eco_threshold, "Aggressive should have lower combat threshold than economic")
	assert_gt(def_threshold, 0.8, "Defensive should require very favorable odds")

func test_aggressive_modify_action_score():
	var base_score = 50.0

	# Attack should get bonus
	var attack_score = AggressivePersonality.modify_action_score(base_score, AIAction.ActionType.ATTACK)
	assert_gt(attack_score, base_score, "Attack actions should be boosted")

	# Fortify should get penalty
	var fortify_score = AggressivePersonality.modify_action_score(base_score, AIAction.ActionType.FORTIFY)
	assert_lt(fortify_score, base_score, "Fortify actions should be penalized")

	# Trade should get penalty
	var trade_score = AggressivePersonality.modify_action_score(base_score, AIAction.ActionType.TRADE)
	assert_lt(trade_score, base_score, "Trade actions should be penalized")

func test_defensive_modify_action_score():
	var base_score = 50.0

	# Fortify should get bonus
	var fortify_score = DefensivePersonality.modify_action_score(base_score, AIAction.ActionType.FORTIFY)
	assert_gt(fortify_score, base_score, "Fortify actions should be boosted")

	# Attack should get penalty
	var attack_score = DefensivePersonality.modify_action_score(base_score, AIAction.ActionType.ATTACK)
	assert_lt(attack_score, base_score, "Attack actions should be penalized")

	# Trade should get bonus
	var trade_score = DefensivePersonality.modify_action_score(base_score, AIAction.ActionType.TRADE)
	assert_gt(trade_score, base_score, "Trade actions should be boosted")

func test_economic_modify_action_score():
	var base_score = 50.0

	# Trade should get strong bonus
	var trade_score = EconomicPersonality.modify_action_score(base_score, AIAction.ActionType.TRADE)
	assert_gt(trade_score, base_score * 1.5, "Trade should get strong bonus")

	# Build building should get bonus
	var build_score = EconomicPersonality.modify_action_score(base_score, AIAction.ActionType.BUILD_BUILDING)
	assert_gt(build_score, base_score, "Building actions should be boosted")

	# Attack should get penalty
	var attack_score = EconomicPersonality.modify_action_score(base_score, AIAction.ActionType.ATTACK)
	assert_lt(attack_score, base_score, "Attack actions should be penalized")

func test_aggressive_prioritize_culture_nodes():
	var nodes = ["military_doctrine", "trade_networks", "defensive_walls", "weapon_tech"]
	var prioritized = AggressivePersonality.prioritize_culture_nodes(nodes)

	assert_eq(prioritized.size(), nodes.size(), "Should return all nodes")

	# Military/weapon nodes should come first
	var first_node = String(prioritized[0]).to_lower()
	assert_true("military" in first_node or "weapon" in first_node,
		"Military/weapon nodes should be prioritized")

func test_defensive_prioritize_culture_nodes():
	var nodes = ["military_doctrine", "trade_networks", "defensive_walls", "fortification_tech"]
	var prioritized = DefensivePersonality.prioritize_culture_nodes(nodes)

	# Defensive nodes should come first
	var first_node = String(prioritized[0]).to_lower()
	assert_true("defense" in first_node or "fortification" in first_node or "wall" in first_node,
		"Defensive nodes should be prioritized")

func test_economic_prioritize_culture_nodes():
	var nodes = ["military_doctrine", "trade_networks", "economic_boost", "resource_tech"]
	var prioritized = EconomicPersonality.prioritize_culture_nodes(nodes)

	# Economic/trade nodes should come first
	var first_node = String(prioritized[0]).to_lower()
	assert_true("economic" in first_node or "trade" in first_node or "resource" in first_node,
		"Economic/trade nodes should be prioritized")

func test_aggressive_select_production():
	var situation = {
		"military_units_ratio": 0.5,
		"under_attack": false,
		"resources": {"scrap": 100, "fuel": 30},
		"trade_routes": 2,
		"has_fortifications": true
	}

	var production = AggressivePersonality.select_production(situation)

	# Should select some unit type
	assert_ne(production, "", "Should select production")
	assert_true(production in ["militia", "soldier", "heavy", "sniper", "factory", "workshop", "scrap_yard"],
		"Should select valid production type")

func test_defensive_select_production():
	var situation = {
		"military_units_ratio": 0.4,
		"under_attack": false,
		"resources": {"scrap": 80, "food": 40},
		"trade_routes": 2,
		"has_fortifications": true
	}

	var production = DefensivePersonality.select_production(situation)

	assert_ne(production, "", "Should select production")

func test_economic_select_production():
	var situation = {
		"military_units_ratio": 0.25,
		"under_attack": false,
		"resources": {"scrap": 120, "food": 60},
		"trade_routes": 1,
		"has_fortifications": true
	}

	var production = EconomicPersonality.select_production(situation)

	assert_ne(production, "", "Should select production")

func test_production_under_attack():
	var attack_situation = {
		"military_units_ratio": 0.3,
		"under_attack": true,
		"resources": {"scrap": 100},
		"trade_routes": 1,
		"has_fortifications": false
	}

	# All personalities should build military/defense when under attack
	var agg_prod = AggressivePersonality.select_production(attack_situation)
	var def_prod = DefensivePersonality.select_production(attack_situation)
	var eco_prod = EconomicPersonality.select_production(attack_situation)

	assert_ne(agg_prod, "", "Aggressive should produce something when attacked")
	assert_ne(def_prod, "", "Defensive should produce something when attacked")
	assert_ne(eco_prod, "", "Economic should produce something when attacked")
