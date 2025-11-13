extends GutTest

## Unit Tests for Ability System
## Tests ability execution, cooldowns, and effects

var unit: Unit
var target_unit: Unit

func before_each():
	unit = Unit.new()
	unit.id = 1
	unit.faction_id = 1
	unit.position = Vector3i(5, 5, 0)
	unit.current_hp = 100
	unit.max_hp = 100
	unit.actions_remaining = 1
	unit.stats = UnitStats.new()

	target_unit = Unit.new()
	target_unit.id = 2
	target_unit.faction_id = 1
	target_unit.position = Vector3i(6, 5, 0)
	target_unit.current_hp = 50
	target_unit.max_hp = 100
	target_unit.stats = UnitStats.new()

func after_each():
	unit = null
	target_unit = null

# Ability Base Tests

func test_ability_initialization():
	var ability = Ability.new()

	assert_not_null(ability, "Ability should initialize")
	assert_eq(ability.current_cooldown, 0, "Cooldown should start at 0")

func test_ability_can_use_basic():
	var ability = Ability.new()
	ability.cooldown = 0
	ability.cost_type = Ability.CostType.ACTION_POINT
	ability.cost_amount = 1

	assert_true(ability.can_use(unit, null), "Should be able to use ability")

func test_ability_cannot_use_on_cooldown():
	var ability = Ability.new()
	ability.cooldown = 2
	ability.current_cooldown = 1
	ability.cost_type = Ability.CostType.ACTION_POINT
	ability.cost_amount = 1

	assert_false(ability.can_use(unit, null), "Should not be able to use ability on cooldown")

func test_ability_cannot_use_without_action_points():
	var ability = Ability.new()
	ability.cost_type = Ability.CostType.ACTION_POINT
	ability.cost_amount = 1

	unit.actions_remaining = 0

	assert_false(ability.can_use(unit, null), "Should not be able to use without action points")

func test_ability_cannot_use_without_movement_points():
	var ability = Ability.new()
	ability.cost_type = Ability.CostType.MOVEMENT_POINT
	ability.cost_amount = 2

	unit.movement_remaining = 1

	assert_false(ability.can_use(unit, null), "Should not be able to use without movement points")

func test_ability_tick_cooldown():
	var ability = Ability.new()
	ability.current_cooldown = 3

	ability.tick_cooldown()
	assert_eq(ability.current_cooldown, 2, "Cooldown should decrease")

	ability.tick_cooldown()
	assert_eq(ability.current_cooldown, 1, "Cooldown should decrease")

	ability.tick_cooldown()
	assert_eq(ability.current_cooldown, 0, "Cooldown should reach 0")

	ability.tick_cooldown()
	assert_eq(ability.current_cooldown, 0, "Cooldown should not go negative")

# Entrench Ability Tests

func test_entrench_ability_creation():
	var entrench = EntrenchAbility.new()

	assert_eq(entrench.id, "entrench", "ID should be 'entrench'")
	assert_eq(entrench.name, "Entrench", "Name should be 'Entrench'")
	assert_eq(entrench.cooldown, 0, "Cooldown should be 0")
	assert_eq(entrench.target_type, Ability.TargetType.SELF, "Should target self")

func test_entrench_is_valid_target():
	var entrench = EntrenchAbility.new()

	assert_true(entrench.is_valid_target(unit, null), "Null target should be valid")
	assert_true(entrench.is_valid_target(unit, unit), "Self should be valid target")
	assert_false(entrench.is_valid_target(unit, target_unit), "Other unit should not be valid")

func test_entrench_apply_effect():
	var entrench = EntrenchAbility.new()

	var success = entrench.apply_effect(unit, null)

	assert_true(success, "Effect should apply successfully")
	assert_eq(unit.status_effects.size(), 1, "Should have 1 status effect")
	assert_eq(unit.status_effects[0]["id"], "entrenched", "Should be entrenched effect")

func test_entrench_effect_stats():
	var entrench = EntrenchAbility.new()
	entrench.apply_effect(unit, null)

	var effect = unit.status_effects[0]

	assert_eq(effect["stat_modifiers"]["defense"], 1.5, "Defense should be +50%")
	assert_eq(effect["stat_modifiers"]["movement"], 0.5, "Movement should be -50%")
	assert_eq(effect["duration"], 1, "Duration should be 1 turn")

# Overwatch Ability Tests

func test_overwatch_ability_creation():
	var overwatch = OverwatchAbility.new()

	assert_eq(overwatch.id, "overwatch", "ID should be 'overwatch'")
	assert_eq(overwatch.cooldown, 1, "Cooldown should be 1")

func test_overwatch_apply_effect():
	var overwatch = OverwatchAbility.new()

	var success = overwatch.apply_effect(unit, null)

	assert_true(success, "Effect should apply successfully")
	assert_eq(unit.status_effects.size(), 1, "Should have 1 status effect")
	assert_eq(unit.status_effects[0]["id"], "overwatch", "Should be overwatch effect")

func test_overwatch_effect_properties():
	var overwatch = OverwatchAbility.new()
	overwatch.apply_effect(unit, null)

	var effect = unit.status_effects[0]

	assert_true(effect["reaction_fire"], "Should have reaction fire flag")
	assert_eq(effect["duration"], 1, "Duration should be 1 turn")
	assert_false(effect["triggered"], "Should not be triggered initially")

# Heal Ability Tests

func test_heal_ability_creation():
	var heal = HealAbility.new()

	assert_eq(heal.id, "heal", "ID should be 'heal'")
	assert_eq(heal.range, 1, "Range should be 1")
	assert_eq(heal.target_type, Ability.TargetType.FRIENDLY_UNIT, "Should target friendly units")

func test_heal_is_valid_target_friendly():
	var heal = HealAbility.new()
	target_unit.faction_id = 1  # Same faction
	target_unit.current_hp = 50  # Damaged

	assert_true(heal.is_valid_target(unit, target_unit), "Should be valid friendly target")

func test_heal_is_not_valid_target_enemy():
	var heal = HealAbility.new()
	target_unit.faction_id = 2  # Different faction
	target_unit.current_hp = 50

	assert_false(heal.is_valid_target(unit, target_unit), "Enemy should not be valid target")

func test_heal_is_not_valid_target_full_hp():
	var heal = HealAbility.new()
	target_unit.faction_id = 1
	target_unit.current_hp = 100  # Full HP

	assert_false(heal.is_valid_target(unit, target_unit), "Full HP unit should not be valid target")

func test_heal_is_not_valid_target_out_of_range():
	var heal = HealAbility.new()
	target_unit.faction_id = 1
	target_unit.current_hp = 50
	target_unit.position = Vector3i(15, 15, 0)  # Far away

	assert_false(heal.is_valid_target(unit, target_unit), "Out of range unit should not be valid")

func test_heal_apply_effect():
	var heal = HealAbility.new()
	target_unit.current_hp = 50
	target_unit.max_hp = 100

	var success = heal.apply_effect(unit, target_unit)

	assert_true(success, "Heal should succeed")
	assert_gt(target_unit.current_hp, 50, "Target HP should increase")

func test_heal_amount_calculation():
	var heal = HealAbility.new()
	target_unit.current_hp = 20
	target_unit.max_hp = 100

	heal.apply_effect(unit, target_unit)

	# Should heal 30 + 10% of 100 = 40 HP
	assert_eq(target_unit.current_hp, 60, "Should heal 40 HP (30 + 10%)")

# Scout Ability Tests

func test_scout_ability_creation():
	var scout = ScoutAbility.new()

	assert_eq(scout.id, "scout", "ID should be 'scout'")
	assert_eq(scout.cooldown, 2, "Cooldown should be 2")

func test_scout_apply_effect():
	var scout = ScoutAbility.new()
	unit.stats.vision_range = 5

	var success = scout.apply_effect(unit, null)

	assert_true(success, "Effect should apply successfully")
	assert_eq(unit.status_effects.size(), 1, "Should have 1 status effect")
	assert_eq(unit.stats.vision_range, 8, "Vision range should increase by 3")

func test_scout_effect_properties():
	var scout = ScoutAbility.new()
	scout.apply_effect(unit, null)

	var effect = unit.status_effects[0]

	assert_eq(effect["id"], "scouting", "Should be scouting effect")
	assert_eq(effect["duration"], 2, "Duration should be 2 turns")
	assert_eq(effect["vision_bonus"], 3, "Vision bonus should be 3")

# Suppress Ability Tests

func test_suppress_ability_creation():
	var suppress = SuppressAbility.new()

	assert_eq(suppress.id, "suppress", "ID should be 'suppress'")
	assert_eq(suppress.target_type, Ability.TargetType.ENEMY_UNIT, "Should target enemy units")

func test_suppress_is_valid_target_enemy():
	var suppress = SuppressAbility.new()
	unit.stats.range = 3
	target_unit.faction_id = 2  # Enemy

	assert_true(suppress.is_valid_target(unit, target_unit), "Should be valid enemy target")

func test_suppress_is_not_valid_target_friendly():
	var suppress = SuppressAbility.new()
	target_unit.faction_id = 1  # Same faction

	assert_false(suppress.is_valid_target(unit, target_unit), "Friendly should not be valid target")

func test_suppress_is_not_valid_target_dead():
	var suppress = SuppressAbility.new()
	target_unit.faction_id = 2
	target_unit.current_hp = 0  # Dead

	assert_false(suppress.is_valid_target(unit, target_unit), "Dead unit should not be valid target")

func test_suppress_apply_effect():
	var suppress = SuppressAbility.new()
	target_unit.faction_id = 2

	var success = suppress.apply_effect(unit, target_unit)

	assert_true(success, "Suppress should succeed")
	assert_eq(target_unit.status_effects.size(), 1, "Should have 1 status effect")
	assert_eq(target_unit.status_effects[0]["id"], "suppressed", "Should be suppressed effect")

func test_suppress_effect_stats():
	var suppress = SuppressAbility.new()
	suppress.apply_effect(unit, target_unit)

	var effect = target_unit.status_effects[0]

	assert_eq(effect["stat_modifiers"]["attack"], 0.5, "Attack should be -50%")
	assert_eq(effect["stat_modifiers"]["movement"], 0.5, "Movement should be -50%")
	assert_eq(effect["duration"], 1, "Duration should be 1 turn")
	assert_false(effect["is_buff"], "Should be a debuff")

# Ability Execution Tests

func test_ability_execute_applies_cost():
	var ability = EntrenchAbility.new()
	unit.actions_remaining = 1

	var success = ability.execute(unit, null)

	assert_true(success, "Execution should succeed")
	assert_eq(unit.actions_remaining, 0, "Action point should be consumed")

func test_ability_execute_starts_cooldown():
	var ability = OverwatchAbility.new()  # Has 1 turn cooldown
	ability.current_cooldown = 0

	var success = ability.execute(unit, null)

	assert_true(success, "Execution should succeed")
	assert_eq(ability.current_cooldown, 1, "Cooldown should start")

func test_ability_execute_fails_on_cooldown():
	var ability = OverwatchAbility.new()
	ability.current_cooldown = 1

	var success = ability.execute(unit, null)

	assert_false(success, "Execution should fail on cooldown")

func test_ability_execute_fails_without_cost():
	var ability = EntrenchAbility.new()
	unit.actions_remaining = 0

	var success = ability.execute(unit, null)

	assert_false(success, "Execution should fail without action points")

# Ability Serialization Tests

func test_ability_serialization():
	var ability = EntrenchAbility.new()
	ability.current_cooldown = 2

	var dict = ability.to_dict()

	assert_eq(dict["id"], "entrench", "ID should be preserved")
	assert_eq(dict["name"], "Entrench", "Name should be preserved")
	assert_eq(dict["current_cooldown"], 2, "Cooldown should be preserved")

func test_ability_deserialization():
	var ability = Ability.new()
	var data = {
		"id": "test_ability",
		"name": "Test",
		"cooldown": 3,
		"current_cooldown": 1,
		"range": 5
	}

	ability.from_dict(data)

	assert_eq(ability.id, "test_ability", "ID should be restored")
	assert_eq(ability.name, "Test", "Name should be restored")
	assert_eq(ability.cooldown, 3, "Cooldown should be restored")
	assert_eq(ability.current_cooldown, 1, "Current cooldown should be restored")
	assert_eq(ability.range, 5, "Range should be restored")

# Range Tests

func test_ability_range_check_self():
	var ability = EntrenchAbility.new()
	ability.range = -1  # Self only

	assert_true(ability.is_target_in_range(unit, unit.position), "Self should be in range")
	assert_false(ability.is_target_in_range(unit, Vector3i(10, 10, 0)), "Other position should not be in range")

func test_ability_range_check_distance():
	var ability = HealAbility.new()
	ability.range = 2

	assert_true(ability.is_target_in_range(unit, Vector3i(6, 5, 0)), "Distance 1 should be in range")
	assert_true(ability.is_target_in_range(unit, Vector3i(7, 5, 0)), "Distance 2 should be in range")
	assert_false(ability.is_target_in_range(unit, Vector3i(10, 10, 0)), "Distance >2 should not be in range")
