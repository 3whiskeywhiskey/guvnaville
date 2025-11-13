extends GutTest

## Unit tests for CombatResolver
##
## Tests auto-resolve combat, outcome determination, and integration.

var test_attackers: Array
var test_defenders: Array
var test_terrain: Dictionary


func before_each():
	test_attackers = [
		{
			"id": "attacker_1",
			"stats": {"hp": 100, "attack": 20, "defense": 10, "cost": {"scrap": 50, "ammunition": 20}},
			"current_hp": 100,
			"morale": 50,
			"experience": 0,
			"rank": "Rookie"
		},
		{
			"id": "attacker_2",
			"stats": {"hp": 100, "attack": 20, "defense": 10, "cost": {"scrap": 50, "ammunition": 20}},
			"current_hp": 100,
			"morale": 50,
			"experience": 0,
			"rank": "Rookie"
		}
	]

	test_defenders = [
		{
			"id": "defender_1",
			"stats": {"hp": 80, "attack": 15, "defense": 12, "cost": {"scrap": 40, "ammunition": 15}},
			"current_hp": 80,
			"morale": 50,
			"experience": 0,
			"rank": "Rookie"
		}
	]

	test_terrain = {
		"terrain_type": "open",
		"cover_type": "none",
		"has_fortification": false
	}


func test_resolve_combat_basic():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_not_null(result, "Should return combat result")
	assert_true(result is CombatResult, "Should be CombatResult type")
	assert_gt(result.attacker_strength, 0, "Should calculate attacker strength")
	assert_gt(result.defender_strength, 0, "Should calculate defender strength")


func test_resolve_combat_attacker_victory():
	# Strong attackers vs weak defender
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Attackers have numerical advantage
	assert_true(result.outcome in [
		CombatResult.CombatOutcome.ATTACKER_VICTORY,
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
	], "Attackers should win")


func test_resolve_combat_defender_victory():
	# Weak attackers vs strong defenders
	var weak_attackers = [
		{
			"id": "weak_1",
			"stats": {"hp": 50, "attack": 10, "defense": 5, "cost": {"scrap": 25}},
			"current_hp": 50,
			"morale": 30,
			"experience": 0
		}
	]

	var strong_defenders = [
		{
			"id": "strong_1",
			"stats": {"hp": 150, "attack": 25, "defense": 20, "cost": {"scrap": 100}},
			"current_hp": 150,
			"morale": 80,
			"experience": 100
		},
		{
			"id": "strong_2",
			"stats": {"hp": 150, "attack": 25, "defense": 20, "cost": {"scrap": 100}},
			"current_hp": 150,
			"morale": 80,
			"experience": 100
		}
	]

	var result = CombatResolver.resolve_combat(
		weak_attackers,
		strong_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_true(result.outcome in [
		CombatResult.CombatOutcome.DEFENDER_VICTORY,
		CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY
	], "Defenders should win")


func test_resolve_combat_empty_attackers():
	var result = CombatResolver.resolve_combat(
		[],
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_eq(result.outcome, CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY,
		"Empty attackers should result in defender victory")


func test_resolve_combat_empty_defenders():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		[],
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_eq(result.outcome, CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY,
		"Empty defenders should result in attacker victory")


func test_resolve_combat_both_empty():
	var result = CombatResolver.resolve_combat(
		[],
		[],
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_eq(result.outcome, CombatResult.CombatOutcome.STALEMATE,
		"Both empty should be stalemate")


func test_resolve_combat_casualties_applied():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Check that casualties were calculated
	assert_true(result.attacker_casualties.size() >= 0, "Should have attacker casualties list")
	assert_true(result.defender_casualties.size() >= 0, "Should have defender casualties list")

	# At least one side should have casualties
	var total_casualties = result.attacker_casualties.size() + result.defender_casualties.size()
	assert_gt(total_casualties, 0, "Should have some casualties in combat")


func test_resolve_combat_survivors():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Should have survivors
	var total_survivors = result.attacker_survivors.size() + result.defender_survivors.size()
	assert_gt(total_survivors, 0, "Should have some survivors")


func test_resolve_combat_loot():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Winner should get loot (if not stalemate)
	if result.outcome != CombatResult.CombatOutcome.STALEMATE:
		assert_not_null(result.loot, "Should have loot dictionary")
		assert_true(result.loot.has("scrap"), "Loot should have scrap")


func test_resolve_combat_experience():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_not_null(result.experience_gained, "Should have experience table")
	assert_gt(result.experience_gained.size(), 0, "Should distribute experience")


func test_resolve_combat_morale_effects():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Morale should be affected
	assert_true(result.attacker_morale_loss >= 0, "Should track attacker morale loss")
	assert_true(result.defender_morale_loss >= 0, "Should track defender morale loss")


func test_resolve_combat_duration():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_gte(result.duration, 0.0, "Duration should be non-negative")
	assert_lt(result.duration, 1.0, "Combat should resolve quickly (< 1 second)")


func test_predict_combat_outcome():
	var prediction = CombatResolver.predict_combat_outcome(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_not_null(prediction, "Should return prediction")

	# Original units should not be modified
	assert_eq(test_attackers[0]["current_hp"], 100, "Original units should not be damaged")
	assert_eq(test_defenders[0]["current_hp"], 80, "Original units should not be damaged")


func test_predict_vs_actual():
	# Prediction should roughly match actual combat
	var prediction = CombatResolver.predict_combat_outcome(
		test_attackers.duplicate(true),
		test_defenders.duplicate(true),
		Vector3i(10, 10, 0),
		test_terrain
	)

	var actual = CombatResolver.resolve_combat(
		test_attackers.duplicate(true),
		test_defenders.duplicate(true),
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Outcomes should be similar (within reason due to randomness)
	# Both should predict attacker advantage
	assert_gt(prediction.strength_ratio, 1.0, "Prediction should show attacker advantage")
	assert_gt(actual.strength_ratio, 1.0, "Actual should show attacker advantage")


func test_validate_combat_parameters():
	var valid = CombatResolver.validate_combat_parameters(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0)
	)

	assert_true(valid, "Valid parameters should pass")


func test_validate_combat_parameters_no_attackers():
	var valid = CombatResolver.validate_combat_parameters(
		[],
		test_defenders,
		Vector3i(10, 10, 0)
	)

	assert_false(valid, "Empty attackers should fail validation")


func test_get_combat_summary():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	var summary = CombatResolver.get_combat_summary(result)

	assert_ne(summary, "", "Should generate summary")
	assert_true(summary.contains("Combat at"), "Summary should contain location")
	assert_true(summary.contains("Strength"), "Summary should contain strength info")


func test_strength_ratio_calculation():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Strength ratio should match formula
	var expected_ratio = result.attacker_strength / result.defender_strength if result.defender_strength > 0 else 999.0
	assert_almost_eq(result.strength_ratio, expected_ratio, 0.01, "Strength ratio should be calculated correctly")


func test_terrain_modifiers_stored():
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	assert_not_null(result.terrain_modifiers, "Should store terrain modifiers")
	assert_true(result.terrain_modifiers.has("terrain_type"), "Should have terrain type")


func test_filter_invalid_units():
	var mixed_units = [
		test_attackers[0],
		{"id": "invalid"},  # Invalid unit
		{"id": "dead", "stats": {"hp": 100}, "current_hp": 0}  # Dead unit
	]

	var result = CombatResolver.resolve_combat(
		mixed_units,
		test_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# Should only use valid attacker
	assert_not_null(result, "Should handle invalid units")


func test_location_stored():
	var location = Vector3i(25, 30, 1)
	var result = CombatResolver.resolve_combat(
		test_attackers,
		test_defenders,
		location,
		test_terrain
	)

	assert_eq(result.location, location, "Should store combat location")


func test_stalemate_no_loot():
	# Create evenly matched forces for stalemate
	var equal_attackers = [test_defenders[0].duplicate(true)]
	var equal_defenders = [test_defenders[0].duplicate(true)]

	equal_attackers[0]["id"] = "eq_attacker"
	equal_defenders[0]["id"] = "eq_defender"

	var result = CombatResolver.resolve_combat(
		equal_attackers,
		equal_defenders,
		Vector3i(10, 10, 0),
		test_terrain
	)

	# If stalemate, should have minimal or no loot
	if result.outcome == CombatResult.CombatOutcome.STALEMATE:
		assert_eq(result.loot["scrap"], 0, "Stalemate should have no loot")


func test_consistency_with_same_input():
	# Seed random for consistency
	seed(12345)

	var result1 = CombatResolver.resolve_combat(
		test_attackers.duplicate(true),
		test_defenders.duplicate(true),
		Vector3i(10, 10, 0),
		test_terrain
	)

	seed(12345)

	var result2 = CombatResolver.resolve_combat(
		test_attackers.duplicate(true),
		test_defenders.duplicate(true),
		Vector3i(10, 10, 0),
		test_terrain
	)

	# With same seed, outcomes should be identical
	assert_eq(result1.outcome, result2.outcome, "Same seed should give same outcome")
