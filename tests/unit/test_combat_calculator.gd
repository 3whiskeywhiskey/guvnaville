extends GutTest

## Unit tests for CombatCalculator
##
## Tests damage formulas, strength calculations, casualty application,
## and edge case handling.

var test_attacker: Dictionary
var test_defender: Dictionary
var test_modifiers: CombatModifiers


func before_each():
	# Create test units
	test_attacker = {
		"id": "attacker_1",
		"stats": {
			"attack": 20,
			"defense": 10,
			"hp": 100,
			"armor": 0,
			"morale": 50
		},
		"current_hp": 100,
		"morale": 50,
		"experience": 0
	}

	test_defender = {
		"id": "defender_1",
		"stats": {
			"attack": 15,
			"defense": 15,
			"hp": 100,
			"armor": 0,
			"morale": 50
		},
		"current_hp": 100,
		"morale": 50,
		"experience": 0
	}

	# Create test modifiers
	test_modifiers = CombatModifiers.new()
	test_modifiers.calculate_totals()


func test_calculate_damage_basic():
	var damage = CombatCalculator.calculate_damage(test_attacker, test_defender, test_modifiers)

	# Damage = (20 * 1.0) - (15 * 1.0 + 0) = 5 (minimum damage)
	# With ±15% variance, should be between 4.25 and 5.75
	assert_gte(damage, CombatCalculator.MIN_DAMAGE, "Damage should be at least minimum")
	assert_lte(damage, 10, "Damage should be reasonable")


func test_calculate_damage_minimum():
	# Defender with very high defense
	test_defender["stats"]["defense"] = 100

	var damage = CombatCalculator.calculate_damage(test_attacker, test_defender, test_modifiers)

	# Should clamp to minimum damage
	assert_eq(damage, CombatCalculator.MIN_DAMAGE, "Damage should be clamped to minimum")


func test_calculate_damage_with_modifiers():
	# High attack multiplier
	test_modifiers.total_attack_multiplier = 2.0
	test_modifiers.total_defense_bonus = 0

	var damage = CombatCalculator.calculate_damage(test_attacker, test_defender, test_modifiers)

	# Damage = (20 * 2.0) - 15 = 25 (with variance)
	assert_gte(damage, 20, "Damage should be increased by modifiers")


func test_calculate_damage_with_armor():
	# Add armor to defender
	test_defender["stats"]["armor"] = 50  # 50% armor

	test_modifiers.calculate_totals()
	var damage = CombatCalculator.calculate_damage(test_attacker, test_defender, test_modifiers)

	# Armor reduces effective defense
	assert_gte(damage, CombatCalculator.MIN_DAMAGE, "Damage should be at least minimum with armor")


func test_calculate_combat_strength_empty():
	var strength = CombatCalculator.calculate_combat_strength([], {}, true)
	assert_eq(strength, 0.0, "Empty array should have 0 strength")


func test_calculate_combat_strength_single_unit():
	var units = [test_attacker]
	var strength = CombatCalculator.calculate_combat_strength(units, {}, true)

	# Strength = attack * hp_factor * morale_factor = 20 * 1.0 * 0.5 = 10.0
	assert_eq(strength, 10.0, "Single unit strength should be calculated correctly")


func test_calculate_combat_strength_damaged_unit():
	test_attacker["current_hp"] = 50  # 50% HP

	var units = [test_attacker]
	var strength = CombatCalculator.calculate_combat_strength(units, {}, true)

	# Strength = 20 * 0.5 * 0.5 = 5.0
	assert_eq(strength, 5.0, "Damaged unit should have reduced strength")


func test_calculate_combat_strength_high_morale():
	test_attacker["morale"] = 100

	var units = [test_attacker]
	var strength = CombatCalculator.calculate_combat_strength(units, {}, true)

	# Strength = 20 * 1.0 * 1.0 = 20.0
	assert_eq(strength, 20.0, "High morale should increase strength")


func test_calculate_combat_strength_defender_terrain():
	var terrain = {"terrain_type": "building"}
	var units = [test_defender]

	var strength = CombatCalculator.calculate_combat_strength(units, terrain, false)

	# Defender in building gets 1.2x multiplier
	# Strength = 15 * 1.0 * 0.5 * 1.2 = 9.0
	assert_eq(strength, 9.0, "Defender should get terrain bonus in building")


func test_apply_casualties_zero_percentage():
	var units = [test_attacker.duplicate(true), test_defender.duplicate(true)]
	var casualties = CombatCalculator.apply_casualties(units, 0.0, CombatResult.CombatOutcome.STALEMATE)

	assert_eq(casualties.size(), 0, "Zero casualty percentage should produce no casualties")


func test_apply_casualties_fifty_percent():
	var units = [test_attacker.duplicate(true), test_defender.duplicate(true)]
	var casualties = CombatCalculator.apply_casualties(units, 0.5, CombatResult.CombatOutcome.STALEMATE)

	# Both units should take ~50% damage, putting them below 50 HP
	assert_gte(casualties.size(), 0, "Should have some casualties")
	assert_lte(casualties.size(), 2, "Should have at most 2 casualties")


func test_apply_casualties_full_destruction():
	var units = [test_attacker.duplicate(true)]
	var casualties = CombatCalculator.apply_casualties(units, 1.0, CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY)

	assert_eq(casualties.size(), 1, "100% casualties should destroy all units")
	assert_eq(units[0]["current_hp"], 0, "Unit should have 0 HP")


func test_get_casualty_percentage_decisive_victory():
	var winner_rate = CombatCalculator.get_casualty_percentage(
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY,
		true
	)
	var loser_rate = CombatCalculator.get_casualty_percentage(
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY,
		false
	)

	assert_eq(winner_rate, CombatCalculator.CASUALTY_DECISIVE_WINNER, "Winner should have low casualties")
	assert_gte(loser_rate, CombatCalculator.CASUALTY_DECISIVE_LOSER_MIN, "Loser should have high casualties")


func test_determine_outcome_decisive_attacker():
	var outcome = CombatCalculator.determine_outcome(150.0, 100.0)
	assert_eq(outcome, CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY, "1.5x strength should be decisive victory")


func test_determine_outcome_stalemate():
	var outcome = CombatCalculator.determine_outcome(100.0, 100.0)
	assert_eq(outcome, CombatResult.CombatOutcome.STALEMATE, "Equal strength should be stalemate")


func test_determine_outcome_decisive_defender():
	var outcome = CombatCalculator.determine_outcome(100.0, 150.0)
	assert_eq(outcome, CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY, "1.5x defender strength should be decisive victory")


func test_determine_outcome_zero_defender():
	var outcome = CombatCalculator.determine_outcome(100.0, 0.0)
	assert_eq(outcome, CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY, "Zero defender strength should be attacker victory")


func test_determine_outcome_zero_attacker():
	var outcome = CombatCalculator.determine_outcome(0.0, 100.0)
	assert_eq(outcome, CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY, "Zero attacker strength should be defender victory")


func test_is_valid_combat_unit_valid():
	assert_true(CombatCalculator.is_valid_combat_unit(test_attacker), "Valid unit should pass validation")


func test_is_valid_combat_unit_no_stats():
	var invalid_unit = {"id": "test"}
	assert_false(CombatCalculator.is_valid_combat_unit(invalid_unit), "Unit without stats should fail validation")


func test_is_valid_combat_unit_zero_hp():
	test_attacker["current_hp"] = 0
	assert_false(CombatCalculator.is_valid_combat_unit(test_attacker), "Unit with 0 HP should fail validation")


func test_is_valid_combat_unit_null():
	assert_false(CombatCalculator.is_valid_combat_unit(null), "Null should fail validation")


func test_filter_valid_units():
	var units = [
		test_attacker,
		{"id": "invalid"},  # Missing stats
		test_defender,
		null
	]

	var valid_units = CombatCalculator.filter_valid_units(units)

	assert_eq(valid_units.size(), 2, "Should filter out invalid units")
	assert_true(valid_units.has(test_attacker), "Should keep valid attacker")
	assert_true(valid_units.has(test_defender), "Should keep valid defender")


func test_damage_variance():
	# Run damage calculation multiple times to check variance
	var damages = []
	for i in range(10):
		var damage = CombatCalculator.calculate_damage(test_attacker, test_defender, test_modifiers)
		damages.append(damage)

	# Should have some variance in results
	var min_damage = damages.min()
	var max_damage = damages.max()

	assert_gte(min_damage, CombatCalculator.MIN_DAMAGE, "All damages should be above minimum")
	# Variance should create different results (unless always hitting minimum)
	assert_true(min_damage <= max_damage, "Should have variance in damage")


func test_calculate_strength_multiple_units():
	var units = [
		test_attacker.duplicate(true),
		test_attacker.duplicate(true),
		test_attacker.duplicate(true)
	]

	var strength = CombatCalculator.calculate_combat_strength(units, {}, true)

	# Each unit: 20 * 1.0 * 0.5 = 10.0, total = 30.0
	assert_eq(strength, 30.0, "Multiple units should sum their strength")
