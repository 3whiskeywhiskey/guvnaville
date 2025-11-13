extends GutTest

## Edge case tests for Combat System
##
## Tests edge cases like 0 HP, negative damage, null inputs, etc.

func test_zero_attack_damage():
	var attacker = {
		"id": "weak",
		"stats": {"attack": 0, "defense": 0, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var defender = {
		"id": "defender",
		"stats": {"attack": 10, "defense": 5, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var mods = CombatModifiers.new()
	mods.calculate_totals()

	var damage = CombatCalculator.calculate_damage(attacker, defender, mods)

	# Should still do minimum damage
	assert_eq(damage, CombatCalculator.MIN_DAMAGE, "Zero attack should still do minimum damage")


func test_zero_defense():
	var attacker = {
		"id": "attacker",
		"stats": {"attack": 20, "defense": 10, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var defender = {
		"id": "defender",
		"stats": {"attack": 10, "defense": 0, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var mods = CombatModifiers.new()
	mods.calculate_totals()

	var damage = CombatCalculator.calculate_damage(attacker, defender, mods)

	assert_gte(damage, CombatCalculator.MIN_DAMAGE, "Zero defense should allow damage through")


func test_maximum_armor():
	var attacker = {
		"id": "attacker",
		"stats": {"attack": 50, "defense": 10, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var defender = {
		"id": "tank",
		"stats": {"attack": 10, "defense": 20, "hp": 300, "armor": 100},
		"current_hp": 300
	}

	var mods = CombatModifiers.new()
	mods.calculate_totals()

	var damage = CombatCalculator.calculate_damage(attacker, defender, mods)

	# Even with 100% armor, should do minimum damage
	assert_eq(damage, CombatCalculator.MIN_DAMAGE, "Maximum armor should not prevent minimum damage")


func test_null_attacker():
	var defender = {
		"id": "defender",
		"stats": {"attack": 10, "defense": 5, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var mods = CombatModifiers.new()
	mods.calculate_totals()

	var damage = CombatCalculator.calculate_damage(null, defender, mods)

	assert_eq(damage, CombatCalculator.MIN_DAMAGE, "Null attacker should return minimum damage")


func test_null_defender():
	var attacker = {
		"id": "attacker",
		"stats": {"attack": 20, "defense": 10, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var mods = CombatModifiers.new()
	mods.calculate_totals()

	var damage = CombatCalculator.calculate_damage(attacker, null, mods)

	assert_eq(damage, CombatCalculator.MIN_DAMAGE, "Null defender should return minimum damage")


func test_null_modifiers():
	var attacker = {
		"id": "attacker",
		"stats": {"attack": 20, "defense": 10, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var defender = {
		"id": "defender",
		"stats": {"attack": 10, "defense": 5, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var damage = CombatCalculator.calculate_damage(attacker, defender, null)

	assert_eq(damage, CombatCalculator.MIN_DAMAGE, "Null modifiers should return minimum damage")


func test_negative_hp_unit():
	var unit = {
		"id": "dead",
		"stats": {"hp": 100, "attack": 20, "defense": 10},
		"current_hp": -50
	}

	var is_valid = CombatCalculator.is_valid_combat_unit(unit)

	assert_false(is_valid, "Negative HP unit should not be valid")


func test_morale_below_zero():
	var unit = {
		"id": "broken",
		"stats": {"hp": 100, "morale": 50},
		"current_hp": 100,
		"morale": -10,
		"experience": 0
	}

	var result = MoraleSystem.apply_morale_check(unit, "combat_loss")

	# Morale should be clamped to 0
	assert_gte(result.current_morale, 0, "Morale should not go below 0")


func test_morale_above_100():
	var unit = {
		"id": "heroic",
		"stats": {"hp": 100, "morale": 50},
		"current_hp": 100,
		"morale": 95,
		"experience": 0
	}

	MoraleSystem.restore_morale(unit, 50, "victory")

	assert_lte(unit["morale"], 100, "Morale should not exceed 100")


func test_combat_with_all_units_at_zero_hp():
	var attackers = [{
		"id": "dead_attacker",
		"stats": {"hp": 100, "attack": 20, "defense": 10, "cost": {}},
		"current_hp": 0,
		"morale": 0
	}]

	var defenders = [{
		"id": "dead_defender",
		"stats": {"hp": 100, "attack": 15, "defense": 12, "cost": {}},
		"current_hp": 0,
		"morale": 0
	}]

	var result = CombatResolver.resolve_combat(
		attackers,
		defenders,
		Vector3i(0, 0, 0),
		{}
	)

	# Both sides have no valid units
	assert_eq(result.outcome, CombatResult.CombatOutcome.STALEMATE,
		"All dead units should result in stalemate")


func test_extreme_strength_difference():
	var weak = [{
		"id": "weak",
		"stats": {"hp": 10, "attack": 1, "defense": 1, "cost": {}},
		"current_hp": 10,
		"morale": 10
	}]

	var strong = [{
		"id": "strong",
		"stats": {"hp": 1000, "attack": 100, "defense": 50, "cost": {}},
		"current_hp": 1000,
		"morale": 100,
		"experience": 500
	}]

	var result = CombatResolver.resolve_combat(weak, strong, Vector3i(0, 0, 0), {})

	assert_eq(result.outcome, CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY,
		"Extreme strength difference should be decisive victory")


func test_combat_at_invalid_location():
	var attackers = [{
		"id": "attacker",
		"stats": {"hp": 100, "attack": 20, "defense": 10, "cost": {}},
		"current_hp": 100,
		"morale": 50
	}]

	var defenders = [{
		"id": "defender",
		"stats": {"hp": 100, "attack": 15, "defense": 12, "cost": {}},
		"current_hp": 100,
		"morale": 50
	}]

	var result = CombatResolver.resolve_combat(
		attackers,
		defenders,
		Vector3i(-100, -100, -100),
		{}
	)

	# Should still resolve, just with warning
	assert_not_null(result, "Should handle invalid location")


func test_experience_overflow():
	var unit = {
		"id": "legendary",
		"stats": {"hp": 100, "attack": 20, "defense": 10},
		"experience": 9999,
		"rank": "Legendary"
	}

	var rank = LootCalculator.get_rank_from_experience(unit["experience"])

	assert_eq(rank, "Legendary", "Should handle very high experience")


func test_loot_from_unit_with_no_cost():
	var defeated = [{
		"id": "free_unit",
		"stats": {"hp": 100, "attack": 10, "defense": 5},
		"current_hp": 0
	}]

	var victor = [{"unit_type": "soldier"}]

	var loot = LootCalculator.calculate_loot(defeated, 1, victor)

	# Should not crash, just return 0 loot
	assert_eq(loot["scrap"], 0, "Unit with no cost should give no loot")


func test_retreat_with_no_movement():
	var unit = {
		"id": "immobile",
		"stats": {"hp": 100, "attack": 20, "defense": 10, "movement": 0},
		"current_hp": 50,
		"morale": 10,
		"position": Vector3i(5, 5, 0)
	}

	var new_pos = MoraleSystem.process_retreat(unit, Vector3i(5, 5, 0), [])

	# Even with 0 movement, should attempt to move at least 1 tile
	# (retreat distance is max(1, movement / 2))
	assert_true(new_pos.distance_to(Vector3i(5, 5, 0)) > 0, "Should move even with 0 movement")


func test_massive_modifier_stack():
	var attacker = {
		"id": "buffed",
		"stats": {"attack": 20, "defense": 10, "hp": 100, "armor": 0},
		"current_hp": 100,
		"morale": 100,
		"experience": 500,
		"culture": "military_dictatorship"
	}

	var defender = {
		"id": "defender",
		"stats": {"attack": 15, "defense": 15, "hp": 100, "armor": 0},
		"current_hp": 100
	}

	var context = {
		"elevation_diff": 2,
		"is_flanking": true,
		"has_supply": true
	}

	var mods = CombatModifiersCalculator.get_combat_modifiers(
		attacker, defender, {"terrain_type": "open"}, context
	)

	# With all bonuses, should have very high multiplier
	assert_gt(mods.total_attack_multiplier, 1.5, "Massive modifier stack should compound")


func test_combat_result_serialization():
	var result = CombatResult.new()
	result.outcome = CombatResult.CombatOutcome.ATTACKER_VICTORY
	result.location = Vector3i(10, 20, 1)
	result.attacker_strength = 150.5
	result.defender_strength = 100.0

	var dict = result.to_dict()

	assert_not_null(dict, "Should serialize to dictionary")
	assert_eq(dict["outcome"], CombatResult.CombatOutcome.ATTACKER_VICTORY, "Should preserve outcome")
	assert_eq(dict["location"]["x"], 10, "Should preserve location")


func test_empty_terrain():
	var mods = CombatModifiersCalculator.get_combat_modifiers(
		{"id": "a", "stats": {}, "morale": 50, "experience": 0},
		{"id": "d", "stats": {}, "morale": 50, "experience": 0},
		{},
		{}
	)

	assert_not_null(mods, "Should handle empty terrain")
	assert_eq(mods.terrain_modifier, 1.0, "Empty terrain should be neutral")


func test_unit_with_missing_stats():
	var incomplete_unit = {
		"id": "incomplete",
		"stats": {"hp": 100}  # Missing attack, defense
	}

	var is_valid = CombatCalculator.is_valid_combat_unit(incomplete_unit)

	assert_false(is_valid, "Incomplete stats should fail validation")


func test_multiple_promotions_in_single_battle():
	var unit = {
		"id": "rapid_promoter",
		"stats": {"hp": 100, "attack": 20, "defense": 10},
		"experience": 95,
		"rank": "Rookie"
	}

	# Add enough XP to skip from Rookie to Elite
	unit["experience"] = 250

	LootCalculator._check_promotion(unit)

	assert_eq(unit["rank"], "Elite", "Should promote to Elite from Rookie")


func test_zero_casualty_combat():
	var result = CombatResult.new()
	result.outcome = CombatResult.CombatOutcome.STALEMATE

	var units = [
		{"id": "u1", "stats": {"hp": 100}, "current_hp": 100},
		{"id": "u2", "stats": {"hp": 100}, "current_hp": 100}
	]

	var casualties = CombatCalculator.apply_casualties(units, 0.0, result.outcome)

	assert_eq(casualties.size(), 0, "Zero casualty rate should produce no casualties")
	assert_eq(units[0]["current_hp"], 100, "Units should not be damaged")


func test_100_percent_casualty():
	var units = [
		{"id": "u1", "stats": {"hp": 100}, "current_hp": 100}
	]

	var casualties = CombatCalculator.apply_casualties(units, 1.0, CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY)

	assert_eq(casualties.size(), 1, "100% casualty should destroy all units")
	assert_eq(units[0]["current_hp"], 0, "Unit should be at 0 HP")
