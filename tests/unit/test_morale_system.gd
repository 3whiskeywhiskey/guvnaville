extends GutTest

## Unit tests for MoraleSystem
##
## Tests morale checks, retreats, rally, and morale restoration.

var test_unit: Dictionary


func before_each():
	test_unit = {
		"id": "unit_1",
		"stats": {
			"hp": 100,
			"attack": 20,
			"defense": 10,
			"movement": 3,
			"morale": 50
		},
		"current_hp": 100,
		"morale": 50,
		"experience": 0,
		"culture": "",
		"position": Vector3i(0, 0, 0)
	}


func test_apply_morale_check_combat_loss():
	var result = MoraleSystem.apply_morale_check(test_unit, "combat_loss")

	assert_not_null(result, "Should return result")
	assert_eq(result.unit_id, "unit_1", "Should track unit ID")
	assert_lt(result.current_morale, result.previous_morale, "Should reduce morale")


func test_apply_morale_check_combat_victory():
	var result = MoraleSystem.apply_morale_check(test_unit, "combat_victory")

	assert_gt(result.current_morale, result.previous_morale, "Should increase morale on victory")


func test_apply_morale_check_hp_critical():
	test_unit["current_hp"] = 40  # Less than 50%

	var result = MoraleSystem.apply_morale_check(test_unit, "hp_critical")

	assert_lt(result.current_morale, result.previous_morale, "Critical HP should reduce morale")


func test_morale_immunity_berserker():
	test_unit["unit_type"] = "berserker"

	var result = MoraleSystem.apply_morale_check(test_unit, "combat_loss")

	assert_eq(result.morale_change, 0, "Berserkers should be immune to morale loss")
	assert_false(result.will_retreat, "Berserkers should not retreat")


func test_morale_thresholds_high():
	test_unit["morale"] = 90

	var result = MoraleSystem.apply_morale_check(test_unit, "ally_killed")

	# Even with morale loss, should still be high
	assert_false(result.will_retreat, "High morale should not retreat")


func test_morale_thresholds_shaken():
	test_unit["morale"] = 25

	var result = MoraleSystem.apply_morale_check(test_unit, "combat_loss")

	# Should be shaken or broken
	assert_true(result.state in [MoraleCheckResult.MoraleState.SHAKEN, MoraleCheckResult.MoraleState.BROKEN],
		"Low morale should be shaken or broken")


func test_morale_thresholds_broken():
	test_unit["morale"] = 5

	var result = MoraleSystem.apply_morale_check(test_unit, "combat_loss")

	assert_eq(result.state, MoraleCheckResult.MoraleState.BROKEN, "Very low morale should be broken")
	assert_true(result.will_retreat, "Broken morale should retreat")


func test_calculate_morale_damage_base():
	var damage = MoraleSystem.calculate_morale_damage(test_unit, "ally_killed", {})

	assert_eq(damage, MoraleSystem.MORALE_DAMAGE["ally_killed"], "Should use base damage")


func test_calculate_morale_damage_with_leader():
	var context = {"leader_present": true}
	var damage = MoraleSystem.calculate_morale_damage(test_unit, "ally_killed", context)

	# Should be reduced by 30%
	assert_lt(damage, MoraleSystem.MORALE_DAMAGE["ally_killed"], "Leader should reduce morale damage")


func test_calculate_morale_damage_veteran():
	test_unit["experience"] = 100  # Veteran

	var damage = MoraleSystem.calculate_morale_damage(test_unit, "combat_loss", {})

	# Veterans take less morale damage
	assert_lt(damage, MoraleSystem.MORALE_DAMAGE["combat_loss"], "Veterans should take less morale damage")


func test_calculate_morale_damage_legendary():
	test_unit["experience"] = 500  # Legendary

	var damage = MoraleSystem.calculate_morale_damage(test_unit, "combat_loss", {})

	# Legendary units take much less morale damage
	assert_lt(damage, MoraleSystem.MORALE_DAMAGE["combat_loss"] * 0.6, "Legendary should take 50% less morale damage")


func test_process_retreat_basic():
	var new_pos = MoraleSystem.process_retreat(test_unit, Vector3i(5, 5, 0), [])

	assert_ne(new_pos, Vector3i(5, 5, 0), "Should move from current position")
	assert_lt(test_unit["current_hp"], 100, "Should take retreat damage")


func test_process_retreat_to_friendly():
	var friendly_positions = [Vector3i(0, 0, 0)]
	var current = Vector3i(5, 5, 0)

	var new_pos = MoraleSystem.process_retreat(test_unit, current, friendly_positions)

	# Should move toward friendly position (0, 0, 0)
	var dist_before = current.distance_to(friendly_positions[0])
	var dist_after = new_pos.distance_to(friendly_positions[0])

	assert_lt(dist_after, dist_before, "Should move toward friendly position")


func test_retreat_damage():
	var initial_hp = test_unit["current_hp"]

	MoraleSystem.apply_retreat_damage(test_unit)

	assert_lt(test_unit["current_hp"], initial_hp, "Retreat should cause damage")
	assert_gte(test_unit["current_hp"], 0, "HP should not go below 0")


func test_calculate_rally_chance_base():
	test_unit["morale"] = 50

	var chance = MoraleSystem.calculate_rally_chance(test_unit)

	assert_gte(chance, 0.0, "Rally chance should be non-negative")
	assert_lte(chance, 0.8, "Rally chance should not exceed 80%")


func test_calculate_rally_chance_high_morale():
	test_unit["morale"] = 80

	var chance = MoraleSystem.calculate_rally_chance(test_unit)

	assert_gt(chance, MoraleSystem.BASE_RALLY_CHANCE, "High morale should increase rally chance")


func test_calculate_rally_chance_veteran():
	test_unit["experience"] = 100
	test_unit["morale"] = 50

	var chance = MoraleSystem.calculate_rally_chance(test_unit)

	assert_gt(chance, MoraleSystem.BASE_RALLY_CHANCE * 0.5, "Veterans should have higher rally chance")


func test_attempt_rally():
	test_unit["morale"] = 80  # High morale for better rally chance

	# Try multiple times to test randomness
	var rallied = false
	for i in range(10):
		if MoraleSystem.attempt_rally(test_unit):
			rallied = true
			break

	# With high morale, should rally at least once in 10 attempts
	assert_true(rallied, "Should be able to rally with high morale")


func test_restore_morale():
	test_unit["morale"] = 30

	MoraleSystem.restore_morale(test_unit, 20, "victory")

	assert_eq(test_unit["morale"], 50, "Morale should be restored")


func test_restore_morale_cap():
	test_unit["morale"] = 90

	MoraleSystem.restore_morale(test_unit, 20, "victory")

	assert_eq(test_unit["morale"], 100, "Morale should be capped at 100")


func test_check_mass_morale_break_heavy_casualties():
	var units = [
		test_unit.duplicate(true),
		test_unit.duplicate(true),
		test_unit.duplicate(true)
	]

	var broken = MoraleSystem.check_mass_morale_break(units, 2)  # 66% casualties

	assert_true(broken, "50%+ casualties should break morale")


func test_check_mass_morale_break_low_average():
	var units = [
		test_unit.duplicate(true),
		test_unit.duplicate(true)
	]

	# Set all units to low morale
	for unit in units:
		unit["morale"] = 15

	var broken = MoraleSystem.check_mass_morale_break(units, 0)

	assert_true(broken, "Average morale below 20 should break")


func test_check_mass_morale_break_stable():
	var units = [
		test_unit.duplicate(true),
		test_unit.duplicate(true)
	]

	var broken = MoraleSystem.check_mass_morale_break(units, 0)

	assert_false(broken, "Normal morale with no casualties should not break")


func test_apply_group_morale_check():
	var units = [
		test_unit.duplicate(true),
		test_unit.duplicate(true),
		test_unit.duplicate(true)
	]

	var results = MoraleSystem.apply_group_morale_check(units, "combat_loss", {})

	assert_eq(results.size(), 3, "Should return result for each unit")
	for result in results:
		assert_true(result is MoraleCheckResult, "Each result should be MoraleCheckResult")


func test_get_morale_description():
	assert_eq(MoraleSystem.get_morale_description(90), "High Morale")
	assert_eq(MoraleSystem.get_morale_description(70), "Good Morale")
	assert_eq(MoraleSystem.get_morale_description(50), "Steady")
	assert_eq(MoraleSystem.get_morale_description(30), "Shaken")
	assert_eq(MoraleSystem.get_morale_description(10), "Broken")


func test_get_morale_color():
	var color_high = MoraleSystem.get_morale_color(90)
	var color_low = MoraleSystem.get_morale_color(10)

	assert_eq(color_high, Color.GREEN, "High morale should be green")
	assert_eq(color_low, Color.RED, "Low morale should be red")


func test_morale_check_result_update_state():
	var result = MoraleCheckResult.new()
	result.current_morale = 85

	result.update_state_from_morale()

	assert_eq(result.state, MoraleCheckResult.MoraleState.HOLDING, "High morale should be holding")
	assert_false(result.will_retreat, "Should not retreat with high morale")


func test_cultural_morale_modifiers():
	test_unit["culture"] = "raider"

	var damage = MoraleSystem.calculate_morale_damage(test_unit, "combat_loss", {})

	# Raiders should take less morale damage
	assert_lt(damage, MoraleSystem.MORALE_DAMAGE["combat_loss"], "Raiders should be fearless")
