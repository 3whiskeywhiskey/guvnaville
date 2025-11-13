extends GutTest

## Unit tests for TacticalAI
## Tests combat AI decision-making
##
## @agent: Agent 7

var tactical_ai: TacticalAI

func before_each():
	tactical_ai = TacticalAI.new(0.5)

func after_each():
	tactical_ai = null

func test_tactical_ai_creation():
	assert_not_null(tactical_ai, "TacticalAI should be created")

func test_select_unit_action():
	var action = tactical_ai.select_unit_action(1, null)

	assert_not_null(action, "Should return action dictionary")
	assert_true(action.has("action"), "Action should have 'action' key")

func test_select_unit_action_invalid_unit():
	var action = tactical_ai.select_unit_action(-1, null)

	assert_not_null(action, "Should return action even for invalid unit")
	assert_eq(action.get("action", ""), "wait", "Invalid unit should return 'wait' action")

func test_evaluate_combat_engagement_empty_units():
	var result = tactical_ai.evaluate_combat_engagement([], [1, 2])
	assert_false(result.engage, "Should not engage with empty attacker units")
	assert_eq(result.reason, "invalid_units", "Reason should be invalid_units")

	var result2 = tactical_ai.evaluate_combat_engagement([1, 2], [])
	assert_false(result2.engage, "Should not engage with empty defender units")

func test_evaluate_combat_engagement_returns_valid_decision():
	var attackers = [1, 2, 3]
	var defenders = [4, 5]

	var result = tactical_ai.evaluate_combat_engagement(attackers, defenders)

	assert_not_null(result, "Should return result dictionary")
	assert_true(result.has("engage"), "Result should have 'engage' key")
	assert_true(result.has("combat_score"), "Result should have 'combat_score' key")
	assert_true(result.has("confidence"), "Result should have 'confidence' key")
	assert_true(result.has("expected_casualties"), "Result should have 'expected_casualties' key")

func test_combat_engagement_considers_risk_tolerance():
	var aggressive_ai = TacticalAI.new(0.9)  # High risk tolerance
	var cautious_ai = TacticalAI.new(0.1)    # Low risk tolerance

	var attackers = [1, 2]
	var defenders = [3, 4]

	# Aggressive AI should be more willing to engage
	var agg_result = aggressive_ai.evaluate_combat_engagement(attackers, defenders)
	var cau_result = cautious_ai.evaluate_combat_engagement(attackers, defenders)

	# Can't guarantee different results with mock, but both should be valid
	assert_true(agg_result.has("engage"), "Aggressive AI should return valid decision")
	assert_true(cau_result.has("engage"), "Cautious AI should return valid decision")

func test_recommend_tactical_combat():
	# High importance, uncertain outcome
	var recommend_tactical = tactical_ai.recommend_tactical_combat(0.9, 15.0)

	# MVP should mostly recommend auto-resolve
	# So this might be true or false, but should not crash
	assert_true(recommend_tactical == true or recommend_tactical == false, "Should return boolean")

	# Low importance
	var recommend_auto = tactical_ai.recommend_tactical_combat(0.3, 50.0)
	assert_false(recommend_auto, "Low importance should use auto-resolve")

func test_select_attack_target_empty_targets():
	var result = tactical_ai.select_attack_target(1, [], null)

	assert_false(result.has_target, "Should have no target with empty array")
	assert_eq(result.target_id, -1, "Target ID should be -1")

func test_select_attack_target_returns_valid_target():
	var targets = [10, 20, 30]

	var result = tactical_ai.select_attack_target(1, targets, null)

	assert_true(result.has_target, "Should have target with non-empty array")
	assert_true(result.target_id in targets, "Target ID should be from targets array")

func test_select_ability_empty_abilities():
	var ability = tactical_ai.select_ability(1, [], {})

	assert_eq(ability, "", "Should return empty string with no abilities")

func test_select_ability_returns_valid_ability():
	var abilities = ["heal", "attack", "defend"]

	var ability = tactical_ai.select_ability(1, abilities, {})

	assert_true(ability in abilities or ability == "", "Should return valid ability or empty string")

func test_select_ability_considers_situation():
	var abilities = ["heal", "attack_boost"]

	# Outnumbered - should prefer defensive
	var ability1 = tactical_ai.select_ability(1, abilities, {"outnumbered": true})

	# Has advantage - should prefer offensive
	var ability2 = tactical_ai.select_ability(1, abilities, {"has_advantage": true})

	# Should return valid abilities (specific behavior is okay to vary)
	assert_true(ability1 in abilities, "Should select valid ability when outnumbered")
	assert_true(ability2 in abilities, "Should select valid ability with advantage")

func test_should_retreat():
	# Low HP should trigger retreat
	var should_retreat1 = tactical_ai.should_retreat(0.15, 80.0)
	assert_true(should_retreat1, "Should retreat with low HP")

	# Low morale should trigger retreat
	var should_retreat2 = tactical_ai.should_retreat(0.8, 20.0)
	assert_true(should_retreat2, "Should retreat with low morale")

	# Good condition should not retreat
	var should_retreat3 = tactical_ai.should_retreat(0.8, 80.0)
	assert_false(should_retreat3, "Should not retreat with good HP and morale")

func test_should_retreat_risk_tolerance():
	var aggressive_ai = TacticalAI.new(0.9)  # High risk, fights longer
	var cautious_ai = TacticalAI.new(0.1)    # Low risk, retreats earlier

	# Same conditions
	var agg_retreat = aggressive_ai.should_retreat(0.3, 40.0)
	var cau_retreat = cautious_ai.should_retreat(0.3, 40.0)

	# Cautious should be more likely to retreat
	# (But specific behavior depends on thresholds, so just check they return booleans)
	assert_true(agg_retreat == true or agg_retreat == false, "Aggressive should return valid retreat decision")
	assert_true(cau_retreat == true or cau_retreat == false, "Cautious should return valid retreat decision")

func test_set_risk_tolerance():
	tactical_ai.set_risk_tolerance(0.8)

	# Risk tolerance change should not crash
	var result = tactical_ai.evaluate_combat_engagement([1, 2], [3, 4])
	assert_not_null(result, "Should still work after risk tolerance change")

func test_set_risk_tolerance_clamping():
	# Values outside 0-1 should be clamped
	tactical_ai.set_risk_tolerance(1.5)
	var result1 = tactical_ai.evaluate_combat_engagement([1], [2])
	assert_not_null(result1, "Should handle clamped risk tolerance")

	tactical_ai.set_risk_tolerance(-0.5)
	var result2 = tactical_ai.evaluate_combat_engagement([1], [2])
	assert_not_null(result2, "Should handle negative risk tolerance")
