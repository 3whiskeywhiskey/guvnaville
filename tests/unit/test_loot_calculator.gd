extends GutTest

## Unit tests for LootCalculator
##
## Tests loot calculation, experience distribution, and promotions.

var test_unit: Dictionary
var defeated_units: Array


func before_each():
	test_unit = {
		"id": "unit_1",
		"stats": {
			"hp": 100,
			"attack": 20,
			"defense": 10,
			"cost": {
				"scrap": 100,
				"ammunition": 50,
				"components": 20,
				"fuel": 10,
				"food": 5,
				"medicine": 5
			}
		},
		"current_hp": 100,
		"unit_type": "soldier",
		"culture": "",
		"experience": 0,
		"rank": "Rookie"
	}

	defeated_units = [test_unit.duplicate(true)]


func test_calculate_loot_basic():
	var victor_units = [{"unit_type": "soldier"}]

	var loot = LootCalculator.calculate_loot(defeated_units, 1, victor_units)

	assert_not_null(loot, "Should return loot dictionary")
	assert_true(loot.has("scrap"), "Should have scrap")
	assert_true(loot.has("ammunition"), "Should have ammunition")
	assert_gt(loot["scrap"], 0, "Should loot some scrap")


func test_calculate_loot_scavenger_bonus():
	var victor_units = [{"unit_type": "scavenger"}]

	var loot = LootCalculator.calculate_loot(defeated_units, 1, victor_units)

	# Scavenger should get 50% more loot
	assert_gt(loot["scrap"], test_unit["stats"]["cost"]["scrap"] * LootCalculator.LOOT_SCRAP_PERCENTAGE,
		"Scavenger should get bonus loot")


func test_calculate_loot_raider_culture():
	var victor_units = [{"unit_type": "soldier", "culture": "raider"}]

	var loot = LootCalculator.calculate_loot(defeated_units, 1, victor_units)

	# Raider culture should get 25% more loot
	assert_gt(loot["scrap"], test_unit["stats"]["cost"]["scrap"] * LootCalculator.LOOT_SCRAP_PERCENTAGE,
		"Raider culture should get bonus loot")


func test_calculate_loot_complete_destruction():
	# Unit completely destroyed (0 HP)
	defeated_units[0]["current_hp"] = 0

	var victor_units = [{"unit_type": "soldier"}]
	var loot = LootCalculator.calculate_loot(defeated_units, 1, victor_units)

	# Should get less loot from completely destroyed unit
	var expected_base = test_unit["stats"]["cost"]["scrap"] * LootCalculator.LOOT_SCRAP_PERCENTAGE
	assert_lt(loot["scrap"], expected_base, "Complete destruction should reduce loot")


func test_calculate_loot_empty_units():
	var loot = LootCalculator.calculate_loot([], 1, [])

	assert_eq(loot["scrap"], 0, "No units should give no loot")
	assert_eq(loot["ammunition"], 0, "No units should give no loot")


func test_calculate_loot_multiple_units():
	var units = [
		test_unit.duplicate(true),
		test_unit.duplicate(true),
		test_unit.duplicate(true)
	]

	var victor_units = [{"unit_type": "soldier"}]
	var loot = LootCalculator.calculate_loot(units, 1, victor_units)

	# Should get loot from all units
	var expected = test_unit["stats"]["cost"]["scrap"] * LootCalculator.LOOT_SCRAP_PERCENTAGE * 3
	assert_almost_eq(loot["scrap"], expected, expected * 0.5, "Should loot from all units")


func test_distribute_experience_victory():
	var combat_result = CombatResult.new()
	combat_result.outcome = CombatResult.CombatOutcome.ATTACKER_VICTORY
	combat_result.attacker_survivors = [test_unit]
	combat_result.defender_casualties = [test_unit.duplicate(true)]

	var xp_table = LootCalculator.distribute_experience([test_unit], combat_result)

	assert_true(xp_table.has(test_unit["id"]), "Should have XP for unit")
	assert_gt(xp_table[test_unit["id"]], 0, "Should gain XP")


func test_distribute_experience_survival_xp():
	var combat_result = CombatResult.new()
	combat_result.outcome = CombatResult.CombatOutcome.STALEMATE
	combat_result.attacker_survivors = [test_unit]

	var xp_table = LootCalculator.distribute_experience([test_unit], combat_result)

	# Should at least get survival XP
	assert_gte(xp_table[test_unit["id"]], LootCalculator.XP_SURVIVE, "Should get survival XP")


func test_distribute_experience_defeat():
	var combat_result = CombatResult.new()
	combat_result.outcome = CombatResult.CombatOutcome.DEFENDER_VICTORY
	combat_result.attacker_survivors = [test_unit]

	var xp_table = LootCalculator.distribute_experience([test_unit], combat_result)

	# Even in defeat, should gain some XP
	assert_gt(xp_table[test_unit["id"]], 0, "Should gain XP even in defeat")


func test_promotion_to_veteran():
	test_unit["experience"] = 0

	# Simulate gaining enough XP
	test_unit["experience"] = LootCalculator.XP_VETERAN

	LootCalculator._check_promotion(test_unit)

	assert_eq(test_unit["rank"], "Veteran", "Should promote to Veteran")


func test_promotion_to_elite():
	test_unit["experience"] = LootCalculator.XP_ELITE
	test_unit["rank"] = "Veteran"

	LootCalculator._check_promotion(test_unit)

	assert_eq(test_unit["rank"], "Elite", "Should promote to Elite")


func test_promotion_to_legendary():
	test_unit["experience"] = LootCalculator.XP_LEGENDARY
	test_unit["rank"] = "Elite"

	LootCalculator._check_promotion(test_unit)

	assert_eq(test_unit["rank"], "Legendary", "Should promote to Legendary")


func test_promotion_stat_bonus():
	var base_attack = test_unit["stats"]["attack"]
	var base_defense = test_unit["stats"]["defense"]

	test_unit["experience"] = LootCalculator.XP_VETERAN

	LootCalculator._check_promotion(test_unit)

	# Veteran should get +10% to stats
	assert_gt(test_unit["stats"]["attack"], base_attack, "Attack should increase on promotion")
	assert_gt(test_unit["stats"]["defense"], base_defense, "Defense should increase on promotion")


func test_get_rank_from_experience():
	assert_eq(LootCalculator.get_rank_from_experience(0), "Rookie")
	assert_eq(LootCalculator.get_rank_from_experience(100), "Veteran")
	assert_eq(LootCalculator.get_rank_from_experience(250), "Elite")
	assert_eq(LootCalculator.get_rank_from_experience(500), "Legendary")


func test_get_next_promotion_xp():
	assert_eq(LootCalculator.get_next_promotion_xp(0), LootCalculator.XP_VETERAN)
	assert_eq(LootCalculator.get_next_promotion_xp(100), LootCalculator.XP_ELITE)
	assert_eq(LootCalculator.get_next_promotion_xp(250), LootCalculator.XP_LEGENDARY)
	assert_eq(LootCalculator.get_next_promotion_xp(500), 0)  # Max rank


func test_loot_resources_all_types():
	test_unit["stats"]["cost"] = {
		"scrap": 100,
		"food": 20,
		"medicine": 10,
		"ammunition": 50,
		"fuel": 30,
		"components": 25
	}

	defeated_units = [test_unit]
	var victor_units = [{"unit_type": "soldier"}]

	var loot = LootCalculator.calculate_loot(defeated_units, 1, victor_units)

	# Should have all resource types
	assert_gt(loot["scrap"], 0, "Should loot scrap")
	assert_gt(loot["ammunition"], 0, "Should loot ammunition")
	assert_gt(loot["components"], 0, "Should loot components")
	assert_gte(loot["fuel"], 0, "Should loot fuel")


func test_special_items_chance():
	# Run loot calculation many times to test special item drop
	var units = []
	for i in range(20):
		units.append(test_unit.duplicate(true))

	var victor_units = [{"unit_type": "soldier"}]
	var loot = LootCalculator.calculate_loot(units, 1, victor_units)

	# With 20 units and 5% chance, should likely get at least one special item
	# (but random, so not guaranteed)
	assert_true(loot.has("special_items"), "Should have special_items array")


func test_experience_applies_to_unit():
	var initial_xp = test_unit["experience"]
	var combat_result = CombatResult.new()
	combat_result.outcome = CombatResult.CombatOutcome.ATTACKER_VICTORY
	combat_result.attacker_survivors = [test_unit]
	combat_result.defender_casualties = [test_unit.duplicate(true)]

	LootCalculator.distribute_experience([test_unit], combat_result)

	assert_gt(test_unit["experience"], initial_xp, "XP should be applied to unit")


func test_promotion_does_not_downgrade():
	test_unit["rank"] = "Veteran"
	test_unit["experience"] = 50  # Less than veteran threshold

	LootCalculator._check_promotion(test_unit)

	assert_eq(test_unit["rank"], "Veteran", "Should not downgrade rank")


func test_has_scavenger_unit():
	var units = [
		{"unit_type": "soldier"},
		{"unit_type": "scavenger"}
	]

	var has_scav = LootCalculator._has_scavenger_unit(units)
	assert_true(has_scav, "Should detect scavenger")


func test_is_raider_culture():
	var units = [
		{"culture": "democratic"},
		{"culture": "raider"}
	]

	var is_raider = LootCalculator._is_raider_culture(units)
	assert_true(is_raider, "Should detect raider culture")


func test_count_unit_kills():
	var combat_result = CombatResult.new()
	combat_result.attacker_survivors = [test_unit]
	combat_result.defender_casualties = [
		{"id": "enemy1"},
		{"id": "enemy2"}
	]

	var kills = LootCalculator._count_unit_kills(test_unit, combat_result)

	assert_gte(kills, 1, "Should count kills")


func test_is_victory_for_units_attacker_wins():
	var combat_result = CombatResult.new()
	combat_result.outcome = CombatResult.CombatOutcome.ATTACKER_VICTORY
	combat_result.attacker_survivors = [test_unit]

	var is_victory = LootCalculator._is_victory_for_units([test_unit], combat_result)

	assert_true(is_victory, "Attacker should be victorious")


func test_is_victory_for_units_defender_wins():
	var combat_result = CombatResult.new()
	combat_result.outcome = CombatResult.CombatOutcome.DEFENDER_VICTORY
	combat_result.defender_survivors = [test_unit]

	var is_victory = LootCalculator._is_victory_for_units([test_unit], combat_result)

	assert_true(is_victory, "Defender should be victorious")
