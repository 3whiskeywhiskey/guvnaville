extends GutTest

## Unit tests for CombatModifiersCalculator
##
## Tests terrain, elevation, cover, and cultural modifiers.

var test_attacker: Dictionary
var test_defender: Dictionary
var test_terrain: Dictionary


func before_each():
	test_attacker = {
		"id": "attacker_1",
		"stats": {"attack": 20, "defense": 10, "hp": 100},
		"culture": "",
		"experience": 0,
		"morale": 50
	}

	test_defender = {
		"id": "defender_1",
		"stats": {"attack": 15, "defense": 15, "hp": 100},
		"culture": "",
		"experience": 0,
		"morale": 50
	}

	test_terrain = {
		"terrain_type": "open",
		"cover_type": "none",
		"has_fortification": false
	}


func test_get_combat_modifiers_default():
	var mods = CombatModifiersCalculator.get_combat_modifiers(
		test_attacker,
		test_defender,
		test_terrain,
		{}
	)

	assert_not_null(mods, "Should return modifiers")
	assert_eq(mods.terrain_modifier, 1.0, "Open terrain should be neutral")
	assert_eq(mods.cover_bonus, 0, "No cover should be 0")
	assert_eq(mods.elevation_modifier, 1.0, "Same elevation should be 1.0")


func test_elevation_modifier_attacker_higher():
	var elevation_mod = CombatModifiersCalculator.get_elevation_modifier(1)
	assert_eq(elevation_mod, 1.25, "Attacker higher should get +25%")


func test_elevation_modifier_attacker_lower():
	var elevation_mod = CombatModifiersCalculator.get_elevation_modifier(-1)
	assert_eq(elevation_mod, 0.85, "Attacker lower should get -15%")


func test_elevation_modifier_same_level():
	var elevation_mod = CombatModifiersCalculator.get_elevation_modifier(0)
	assert_eq(elevation_mod, 1.0, "Same elevation should be 1.0")


func test_cover_bonus_none():
	var cover = CombatModifiersCalculator.get_cover_bonus(test_terrain, true)
	assert_eq(cover, 0, "No cover should be 0")


func test_cover_bonus_light():
	test_terrain["cover_type"] = "light"
	var cover = CombatModifiersCalculator.get_cover_bonus(test_terrain, true)
	assert_eq(cover, 5, "Light cover should be +5")


func test_cover_bonus_heavy():
	test_terrain["cover_type"] = "heavy"
	var cover = CombatModifiersCalculator.get_cover_bonus(test_terrain, true)
	assert_eq(cover, 10, "Heavy cover should be +10")


func test_cover_bonus_fortification():
	test_terrain["cover_type"] = "fortification"
	var cover = CombatModifiersCalculator.get_cover_bonus(test_terrain, true)
	assert_eq(cover, 15, "Fortification should be +15")


func test_cover_bonus_not_defending():
	test_terrain["cover_type"] = "heavy"
	var cover = CombatModifiersCalculator.get_cover_bonus(test_terrain, false)
	assert_eq(cover, 0, "Attackers should not get cover bonus")


func test_cover_bonus_inferred_from_terrain():
	test_terrain["terrain_type"] = "rubble"
	test_terrain["cover_type"] = "none"
	var cover = CombatModifiersCalculator.get_cover_bonus(test_terrain, true)
	assert_eq(cover, 5, "Rubble should infer light cover")


func test_terrain_modifier_open():
	var mod = CombatModifiersCalculator.get_terrain_modifier(test_attacker, {"terrain_type": "open"}, true)
	assert_eq(mod, 1.0, "Open terrain should be neutral")


func test_terrain_modifier_rubble_attacker():
	var mod = CombatModifiersCalculator.get_terrain_modifier(test_attacker, {"terrain_type": "rubble"}, true)
	assert_eq(mod, 0.9, "Rubble should penalize attackers")


func test_terrain_modifier_building_defender():
	var mod = CombatModifiersCalculator.get_terrain_modifier(test_defender, {"terrain_type": "building"}, false)
	assert_eq(mod, 1.1, "Building should bonus defenders")


func test_fortification_bonus_none():
	var bonus = CombatModifiersCalculator.get_fortification_bonus(test_terrain)
	assert_eq(bonus, 0, "No fortification should be 0")


func test_fortification_bonus_level_1():
	test_terrain["has_fortification"] = true
	test_terrain["fortification_level"] = 1
	var bonus = CombatModifiersCalculator.get_fortification_bonus(test_terrain)
	assert_eq(bonus, 5, "Level 1 fortification should be +5")


func test_fortification_bonus_level_2():
	test_terrain["has_fortification"] = true
	test_terrain["fortification_level"] = 2
	var bonus = CombatModifiersCalculator.get_fortification_bonus(test_terrain)
	assert_eq(bonus, 10, "Level 2 fortification should be +10")


func test_fortification_bonus_level_3():
	test_terrain["has_fortification"] = true
	test_terrain["fortification_level"] = 3
	var bonus = CombatModifiersCalculator.get_fortification_bonus(test_terrain)
	assert_eq(bonus, 15, "Level 3 fortification should be +15")


func test_morale_modifier_high():
	var mod = CombatModifiersCalculator.get_morale_modifier(80)
	assert_eq(mod, 1.10, "High morale should be +10%")


func test_morale_modifier_normal():
	var mod = CombatModifiersCalculator.get_morale_modifier(50)
	assert_eq(mod, 1.0, "Normal morale should be 1.0")


func test_morale_modifier_low():
	var mod = CombatModifiersCalculator.get_morale_modifier(20)
	assert_eq(mod, 0.90, "Low morale should be -10%")


func test_morale_modifier_broken():
	var mod = CombatModifiersCalculator.get_morale_modifier(5)
	assert_eq(mod, 0.75, "Broken morale should be -25%")


func test_experience_modifier_rookie():
	var mod = CombatModifiersCalculator.get_experience_modifier(0)
	assert_eq(mod, 1.0, "Rookie should have no bonus")


func test_experience_modifier_veteran():
	var mod = CombatModifiersCalculator.get_experience_modifier(100)
	assert_eq(mod, 1.10, "Veteran should have +10%")


func test_experience_modifier_elite():
	var mod = CombatModifiersCalculator.get_experience_modifier(250)
	assert_eq(mod, 1.20, "Elite should have +20%")


func test_experience_modifier_legendary():
	var mod = CombatModifiersCalculator.get_experience_modifier(500)
	assert_eq(mod, 1.30, "Legendary should have +30%")


func test_weather_modifier_clear():
	var mod = CombatModifiersCalculator.get_weather_modifier("clear")
	assert_eq(mod, 1.0, "Clear weather should be neutral")


func test_weather_modifier_rain():
	var mod = CombatModifiersCalculator.get_weather_modifier("rain")
	assert_eq(mod, 0.95, "Rain should penalize slightly")


func test_weather_modifier_fog():
	var mod = CombatModifiersCalculator.get_weather_modifier("fog")
	assert_eq(mod, 0.90, "Fog should penalize more")


func test_cultural_bonuses_military():
	test_attacker["culture"] = "military_dictatorship"
	var bonuses = CombatModifiersCalculator.get_cultural_bonuses(test_attacker, test_defender, {})
	assert_true(bonuses.has("military_attack_bonus"), "Should have military bonus")


func test_is_morale_immune_berserker():
	test_attacker["unit_type"] = "berserker"
	var immune = CombatModifiersCalculator.is_morale_immune(test_attacker)
	assert_true(immune, "Berserkers should be immune to morale")


func test_is_morale_immune_cybernetic():
	test_attacker["unit_type"] = "cybernetic_soldier"
	var immune = CombatModifiersCalculator.is_morale_immune(test_attacker)
	assert_true(immune, "Cybernetic soldiers should be immune to morale")


func test_is_morale_immune_technocracy():
	test_attacker["culture"] = "technocracy"
	var immune = CombatModifiersCalculator.is_morale_immune(test_attacker)
	assert_true(immune, "Technocracy units should be immune to morale")


func test_is_morale_immune_normal():
	var immune = CombatModifiersCalculator.is_morale_immune(test_attacker)
	assert_false(immune, "Normal units should not be immune to morale")


func test_combat_modifiers_calculate_totals():
	var mods = CombatModifiers.new()
	mods.terrain_modifier = 1.2
	mods.elevation_modifier = 1.25
	mods.flanking_bonus = 0.15
	mods.cover_bonus = 10
	mods.fortification_bonus = 5

	mods.calculate_totals()

	# Total attack = 1.2 * 1.25 * 1.0 * 1.0 * 1.0 * 1.0 * 1.15 = 1.725
	assert_almost_eq(mods.total_attack_multiplier, 1.725, 0.001, "Attack multiplier should be calculated correctly")
	assert_eq(mods.total_defense_bonus, 15, "Defense bonus should be summed correctly")


func test_context_elevation_diff():
	var context = {"elevation_diff": 2}
	var mods = CombatModifiersCalculator.get_combat_modifiers(
		test_attacker,
		test_defender,
		test_terrain,
		context
	)

	assert_eq(mods.elevation_modifier, 1.25, "Should apply elevation from context")


func test_context_flanking():
	var context = {"is_flanking": true}
	var mods = CombatModifiersCalculator.get_combat_modifiers(
		test_attacker,
		test_defender,
		test_terrain,
		context
	)

	assert_eq(mods.flanking_bonus, 0.15, "Should apply flanking bonus")


func test_context_no_supply():
	var context = {"has_supply": false}
	var mods = CombatModifiersCalculator.get_combat_modifiers(
		test_attacker,
		test_defender,
		test_terrain,
		context
	)

	assert_eq(mods.supply_penalty, 0.5, "Unsupplied should be -50%")


func test_modifier_stacking():
	# High elevation, flanking, veteran, high morale
	test_attacker["experience"] = 100
	test_attacker["morale"] = 80

	var context = {
		"elevation_diff": 1,
		"is_flanking": true,
		"has_supply": true
	}

	var mods = CombatModifiersCalculator.get_combat_modifiers(
		test_attacker,
		test_defender,
		test_terrain,
		context
	)

	# Should have multiple bonuses stacked
	assert_gt(mods.total_attack_multiplier, 1.5, "Multiple bonuses should stack")
