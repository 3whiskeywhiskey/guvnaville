extends GutTest

## Unit Tests for Unit and UnitStats classes
## Tests core unit functionality, stats, serialization, and progression

var unit: Unit
var stats: UnitStats

func before_each():
	unit = Unit.new()
	stats = UnitStats.new()

func after_each():
	unit = null
	stats = null

# Unit Creation and Initialization Tests

func test_unit_initialization():
	assert_not_null(unit, "Unit should be initialized")
	assert_not_null(unit.stats, "Unit stats should be initialized")
	assert_eq(unit.id, -1, "Unit ID should default to -1")
	assert_eq(unit.faction_id, -1, "Faction ID should default to -1")

func test_unit_stats_initialization():
	assert_eq(stats.attack, 10, "Default attack should be 10")
	assert_eq(stats.defense, 5, "Default defense should be 5")
	assert_eq(stats.movement, 3, "Default movement should be 3")
	assert_eq(stats.vision_range, 5, "Default vision range should be 5")

# Serialization Tests

func test_unit_serialization_roundtrip():
	unit.id = 100
	unit.type = "soldier"
	unit.faction_id = 1
	unit.position = Vector3i(5, 10, 0)
	unit.current_hp = 75
	unit.max_hp = 100
	unit.morale = 60
	unit.experience = 150

	var dict = unit.to_dict()

	var new_unit = Unit.new()
	new_unit.from_dict(dict)

	assert_eq(new_unit.id, 100, "ID should be preserved")
	assert_eq(new_unit.type, "soldier", "Type should be preserved")
	assert_eq(new_unit.faction_id, 1, "Faction ID should be preserved")
	assert_eq(new_unit.position, Vector3i(5, 10, 0), "Position should be preserved")
	assert_eq(new_unit.current_hp, 75, "Current HP should be preserved")
	assert_eq(new_unit.max_hp, 100, "Max HP should be preserved")
	assert_eq(new_unit.morale, 60, "Morale should be preserved")
	assert_eq(new_unit.experience, 150, "Experience should be preserved")

func test_unit_stats_serialization():
	stats.attack = 20
	stats.defense = 15
	stats.movement = 4
	stats.vision_range = 6

	var dict = stats.to_dict()

	var new_stats = UnitStats.new()
	new_stats.from_dict(dict)

	assert_eq(new_stats.attack, 20, "Attack should be preserved")
	assert_eq(new_stats.defense, 15, "Defense should be preserved")
	assert_eq(new_stats.movement, 4, "Movement should be preserved")
	assert_eq(new_stats.vision_range, 6, "Vision range should be preserved")

# Combat Tests

func test_take_damage():
	unit.current_hp = 100
	var damage = unit.take_damage(30)

	assert_eq(damage, 30, "Should take 30 damage")
	assert_eq(unit.current_hp, 70, "HP should be 70")

func test_take_damage_overkill():
	unit.current_hp = 20
	var damage = unit.take_damage(50)

	assert_eq(damage, 50, "Should take 50 damage")
	assert_eq(unit.current_hp, 0, "HP should not go below 0")

func test_take_damage_negative():
	unit.current_hp = 100
	var damage = unit.take_damage(-10)

	assert_eq(damage, 0, "Negative damage should be 0")
	assert_eq(unit.current_hp, 100, "HP should not change")

func test_heal():
	unit.current_hp = 50
	unit.max_hp = 100
	var healed = unit.heal(30)

	assert_eq(healed, 30, "Should heal 30 HP")
	assert_eq(unit.current_hp, 80, "HP should be 80")

func test_heal_over_max():
	unit.current_hp = 90
	unit.max_hp = 100
	var healed = unit.heal(30)

	assert_eq(healed, 10, "Should only heal 10 HP")
	assert_eq(unit.current_hp, 100, "HP should not exceed max")

func test_morale_modification():
	unit.morale = 50
	unit.modify_morale(20)

	assert_eq(unit.morale, 70, "Morale should increase to 70")

	unit.modify_morale(-30)
	assert_eq(unit.morale, 40, "Morale should decrease to 40")

func test_morale_clamping():
	unit.morale = 50

	unit.modify_morale(100)
	assert_eq(unit.morale, 100, "Morale should be clamped to 100")

	unit.modify_morale(-150)
	assert_eq(unit.morale, 0, "Morale should be clamped to 0")

# Status Check Tests

func test_is_alive():
	unit.current_hp = 50
	assert_true(unit.is_alive(), "Unit with HP > 0 should be alive")

	unit.current_hp = 0
	assert_false(unit.is_alive(), "Unit with HP = 0 should not be alive")

	unit.current_hp = -10
	assert_false(unit.is_alive(), "Unit with HP < 0 should not be alive")

func test_is_routed():
	unit.morale = 50
	assert_false(unit.is_routed(), "Unit with morale > 0 should not be routed")

	unit.morale = 0
	assert_true(unit.is_routed(), "Unit with morale = 0 should be routed")

	unit.morale = -10
	assert_true(unit.is_routed(), "Unit with morale < 0 should be routed")

func test_can_act():
	unit.actions_remaining = 1
	unit.current_hp = 50
	unit.morale = 50

	assert_true(unit.can_act(), "Unit should be able to act")

	unit.actions_remaining = 0
	assert_false(unit.can_act(), "Unit with no actions should not be able to act")

	unit.actions_remaining = 1
	unit.current_hp = 0
	assert_false(unit.can_act(), "Dead unit should not be able to act")

	unit.current_hp = 50
	unit.morale = 0
	assert_false(unit.can_act(), "Routed unit should not be able to act")

func test_can_move():
	unit.movement_remaining = 3
	unit.current_hp = 50
	unit.morale = 50

	assert_true(unit.can_move(), "Unit should be able to move")

	unit.movement_remaining = 0
	assert_false(unit.can_move(), "Unit with no movement should not be able to move")

# Experience and Promotion Tests

func test_add_experience():
	unit.experience = 0
	unit.rank = Unit.UnitRank.ROOKIE

	var promoted = unit.add_experience(50)
	assert_false(promoted, "Should not be promoted at 50 XP")
	assert_eq(unit.experience, 50, "Experience should be 50")
	assert_eq(unit.rank, Unit.UnitRank.ROOKIE, "Should still be ROOKIE")

func test_promotion_to_trained():
	unit.experience = 0
	unit.rank = Unit.UnitRank.ROOKIE
	unit.stats.morale_base = 50

	var promoted = unit.add_experience(100)
	assert_true(promoted, "Should be promoted at 100 XP")
	assert_eq(unit.rank, Unit.UnitRank.TRAINED, "Should be promoted to TRAINED")

func test_promotion_to_veteran():
	unit.experience = 200
	unit.rank = Unit.UnitRank.TRAINED
	unit.stats.morale_base = 50

	var promoted = unit.add_experience(100)
	assert_true(promoted, "Should be promoted at 300 XP")
	assert_eq(unit.rank, Unit.UnitRank.VETERAN, "Should be promoted to VETERAN")

func test_promotion_to_elite():
	unit.experience = 600
	unit.rank = Unit.UnitRank.VETERAN
	unit.stats.morale_base = 50

	var promoted = unit.add_experience(100)
	assert_true(promoted, "Should be promoted at 700 XP")
	assert_eq(unit.rank, Unit.UnitRank.ELITE, "Should be promoted to ELITE")

func test_promotion_to_legendary():
	unit.experience = 1400
	unit.rank = Unit.UnitRank.ELITE
	unit.stats.morale_base = 50

	var promoted = unit.add_experience(100)
	assert_true(promoted, "Should be promoted at 1500 XP")
	assert_eq(unit.rank, Unit.UnitRank.LEGENDARY, "Should be promoted to LEGENDARY")

func test_multiple_promotions():
	unit.experience = 0
	unit.rank = Unit.UnitRank.ROOKIE
	unit.stats.morale_base = 50

	# Jump from ROOKIE to VETERAN
	var promoted = unit.add_experience(350)
	assert_true(promoted, "Should be promoted")
	assert_eq(unit.rank, Unit.UnitRank.VETERAN, "Should skip to VETERAN")

func test_rank_bonuses():
	unit.stats.morale_base = 50

	unit.rank = Unit.UnitRank.ROOKIE
	var bonuses = unit.get_rank_bonuses()
	assert_eq(bonuses["stat_multiplier"], 1.0, "ROOKIE should have 1.0x multiplier")
	assert_eq(bonuses["morale_bonus"], 0, "ROOKIE should have 0 morale bonus")

	unit.rank = Unit.UnitRank.LEGENDARY
	bonuses = unit.get_rank_bonuses()
	assert_eq(bonuses["stat_multiplier"], 1.6, "LEGENDARY should have 1.6x multiplier")
	assert_eq(bonuses["morale_bonus"], 50, "LEGENDARY should have 50 morale bonus")

func test_effective_stats_with_rank():
	unit.stats.attack = 10
	unit.stats.defense = 10
	unit.rank = Unit.UnitRank.ROOKIE

	assert_eq(unit.get_effective_attack(), 10, "ROOKIE attack should be 10")
	assert_eq(unit.get_effective_defense(), 10, "ROOKIE defense should be 10")

	unit.rank = Unit.UnitRank.VETERAN
	assert_eq(unit.get_effective_attack(), 12, "VETERAN attack should be 12 (10 * 1.25)")
	assert_eq(unit.get_effective_defense(), 12, "VETERAN defense should be 12 (10 * 1.25)")

# Turn State Tests

func test_reset_turn_state():
	unit.stats.movement = 3
	unit.movement_remaining = 0
	unit.actions_remaining = 0
	unit.has_moved = true
	unit.has_attacked = true

	unit.reset_turn_state()

	assert_eq(unit.movement_remaining, 3, "Movement should be reset")
	assert_eq(unit.actions_remaining, 1, "Actions should be reset")
	assert_false(unit.has_moved, "has_moved should be reset")
	assert_false(unit.has_attacked, "has_attacked should be reset")

# Status Effect Tests

func test_status_effect_modifiers():
	unit.stats.attack = 10
	unit.stats.defense = 10

	# Add attack buff
	var buff = {
		"id": "attack_buff",
		"stat_modifiers": {"attack": 1.5, "defense": 0.8}
	}
	unit.status_effects.append(buff)

	assert_eq(unit.get_effective_attack(), 15, "Attack should be buffed to 15")
	assert_eq(unit.get_effective_defense(), 8, "Defense should be reduced to 8")

func test_tick_status_effects():
	var effect1 = {"id": "buff1", "duration": 2}
	var effect2 = {"id": "buff2", "duration": 1}
	var effect3 = {"id": "buff3", "duration": 0}

	unit.status_effects.append(effect1)
	unit.status_effects.append(effect2)
	unit.status_effects.append(effect3)

	unit._tick_status_effects()

	assert_eq(unit.status_effects.size(), 2, "Expired effect should be removed")
	assert_eq(unit.status_effects[0]["duration"], 1, "Effect 1 duration should be 1")
	assert_eq(unit.status_effects[1]["duration"], 0, "Effect 2 duration should be 0")
