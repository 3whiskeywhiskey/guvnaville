extends GutTest

## Unit Tests for UnitManager
## Tests unit lifecycle, registry, and management

var manager: UnitManager
var factory: UnitFactory

func before_each():
	manager = UnitManager.new()
	factory = UnitFactory.new()
	factory.load_unit_data()
	manager.set_factory(factory)

func after_each():
	manager.clear_all_units()
	if manager:
		manager.queue_free()
	if factory:
		factory.queue_free()
	manager = null
	factory = null

# Unit Creation Tests

func test_create_unit():
	var unit = manager.create_unit("militia", 1, Vector3i(5, 5, 0))

	assert_not_null(unit, "Should create unit")
	assert_eq(unit.type, "militia", "Unit type should be militia")
	assert_eq(unit.faction_id, 1, "Faction ID should be 1")
	assert_eq(unit.position, Vector3i(5, 5, 0), "Position should match")

func test_create_unit_invalid_type():
	var unit = manager.create_unit("invalid", 1, Vector3i(0, 0, 0))

	assert_null(unit, "Should return null for invalid type")

func test_create_unit_invalid_faction():
	var unit = manager.create_unit("militia", -1, Vector3i(0, 0, 0))

	assert_null(unit, "Should return null for invalid faction")

func test_create_unit_registers_in_manager():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))

	assert_true(manager.unit_exists(unit.id), "Unit should be registered")
	assert_eq(manager.get_unit_count(), 1, "Manager should have 1 unit")

func test_create_multiple_units():
	var unit1 = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var unit2 = manager.create_unit("soldier", 1, Vector3i(1, 1, 0))
	var unit3 = manager.create_unit("militia", 2, Vector3i(2, 2, 0))

	assert_eq(manager.get_unit_count(), 3, "Manager should have 3 units")

func test_create_unit_with_customization():
	var custom = {"max_hp": 200, "name": "Elite Unit"}
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0), custom)

	assert_eq(unit.max_hp, 200, "Customization should be applied")
	assert_eq(unit.name, "Elite Unit", "Custom name should be applied")

# Unit Query Tests

func test_get_unit():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var retrieved = manager.get_unit(unit.id)

	assert_eq(retrieved, unit, "Should retrieve same unit")

func test_get_nonexistent_unit():
	var retrieved = manager.get_unit(999)

	assert_null(retrieved, "Should return null for nonexistent unit")

func test_unit_exists():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))

	assert_true(manager.unit_exists(unit.id), "Unit should exist")
	assert_false(manager.unit_exists(999), "Nonexistent unit should not exist")

func test_get_units_at_position():
	var pos = Vector3i(5, 5, 0)
	var unit1 = manager.create_unit("militia", 1, pos)
	var unit2 = manager.create_unit("soldier", 1, pos)

	var units = manager.get_units_at_position(pos)

	assert_eq(units.size(), 2, "Should have 2 units at position")
	assert_true(units.has(unit1), "Should include unit1")
	assert_true(units.has(unit2), "Should include unit2")

func test_get_units_at_empty_position():
	var units = manager.get_units_at_position(Vector3i(10, 10, 0))

	assert_eq(units.size(), 0, "Should have no units at empty position")

func test_get_units_by_faction():
	var unit1 = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var unit2 = manager.create_unit("soldier", 1, Vector3i(1, 1, 0))
	var unit3 = manager.create_unit("militia", 2, Vector3i(2, 2, 0))

	var faction1_units = manager.get_units_by_faction(1)
	var faction2_units = manager.get_units_by_faction(2)

	assert_eq(faction1_units.size(), 2, "Faction 1 should have 2 units")
	assert_eq(faction2_units.size(), 1, "Faction 2 should have 1 unit")
	assert_true(faction1_units.has(unit1), "Should include unit1")
	assert_true(faction1_units.has(unit2), "Should include unit2")
	assert_true(faction2_units.has(unit3), "Should include unit3")

func test_get_units_by_nonexistent_faction():
	var units = manager.get_units_by_faction(999)

	assert_eq(units.size(), 0, "Should have no units for nonexistent faction")

func test_get_units_in_radius():
	var center = Vector3i(5, 5, 0)
	var unit1 = manager.create_unit("militia", 1, Vector3i(5, 5, 0))  # Distance 0
	var unit2 = manager.create_unit("soldier", 1, Vector3i(6, 5, 0))  # Distance 1
	var unit3 = manager.create_unit("militia", 1, Vector3i(7, 7, 0))  # Distance 4
	var unit4 = manager.create_unit("soldier", 1, Vector3i(10, 10, 0))  # Distance 10

	var units_r2 = manager.get_units_in_radius(center, 2)
	var units_r5 = manager.get_units_in_radius(center, 5)

	assert_eq(units_r2.size(), 2, "Should have 2 units within radius 2")
	assert_eq(units_r5.size(), 3, "Should have 3 units within radius 5")

func test_get_units_in_radius_faction_filter():
	var center = Vector3i(5, 5, 0)
	var unit1 = manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var unit2 = manager.create_unit("soldier", 2, Vector3i(6, 5, 0))

	var faction1_units = manager.get_units_in_radius(center, 5, 1)

	assert_eq(faction1_units.size(), 1, "Should only include faction 1 units")
	assert_true(faction1_units.has(unit1), "Should include unit1")

func test_get_all_units():
	manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	manager.create_unit("soldier", 1, Vector3i(1, 1, 0))
	manager.create_unit("militia", 2, Vector3i(2, 2, 0))

	var all_units = manager.get_all_units()

	assert_eq(all_units.size(), 3, "Should have 3 units total")

# Unit Modification Tests

func test_damage_unit():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var initial_hp = unit.current_hp

	manager.damage_unit(unit.id, 20)

	assert_eq(unit.current_hp, initial_hp - 20, "HP should decrease by 20")

func test_damage_unit_to_death():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.current_hp = 10

	manager.damage_unit(unit.id, 20)

	assert_false(manager.unit_exists(unit.id), "Unit should be destroyed")

func test_heal_unit():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.current_hp = 20

	manager.heal_unit(unit.id, 30)

	assert_eq(unit.current_hp, 50, "HP should increase by 30")

func test_modify_morale():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.morale = 50

	manager.modify_morale(unit.id, 20)
	assert_eq(unit.morale, 70, "Morale should increase")

	manager.modify_morale(unit.id, -30)
	assert_eq(unit.morale, 40, "Morale should decrease")

func test_modify_morale_to_routing():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.morale = 10

	manager.modify_morale(unit.id, -20)

	assert_eq(unit.morale, 0, "Morale should be 0")
	assert_true(unit.is_routed(), "Unit should be routed")

func test_add_experience():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))

	manager.add_experience(unit.id, 150)

	assert_eq(unit.experience, 150, "Experience should be 150")
	assert_eq(unit.rank, Unit.UnitRank.TRAINED, "Should be promoted to TRAINED")

func test_set_position():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var new_pos = Vector3i(10, 10, 0)

	var success = manager.set_position(unit.id, new_pos)

	assert_true(success, "Position change should succeed")
	assert_eq(unit.position, new_pos, "Position should be updated")

	# Check spatial index
	var units_at_new_pos = manager.get_units_at_position(new_pos)
	assert_eq(units_at_new_pos.size(), 1, "Should have 1 unit at new position")

	var units_at_old_pos = manager.get_units_at_position(Vector3i(0, 0, 0))
	assert_eq(units_at_old_pos.size(), 0, "Should have 0 units at old position")

# Status Effect Tests

func test_add_status_effect():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var effect = {
		"id": "test_buff",
		"name": "Test Buff",
		"duration": 2
	}

	manager.add_status_effect(unit.id, effect)

	assert_eq(unit.status_effects.size(), 1, "Should have 1 status effect")
	assert_eq(unit.status_effects[0]["id"], "test_buff", "Should be correct effect")

func test_remove_status_effect():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var effect = {
		"id": "test_buff",
		"name": "Test Buff",
		"duration": 2
	}

	manager.add_status_effect(unit.id, effect)
	manager.remove_status_effect(unit.id, "test_buff")

	assert_eq(unit.status_effects.size(), 0, "Effect should be removed")

func test_tick_status_effects():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var effect = {
		"id": "test_buff",
		"duration": 2
	}

	manager.add_status_effect(unit.id, effect)
	manager.tick_status_effects(unit.id)

	assert_eq(unit.status_effects[0]["duration"], 1, "Duration should decrease")

# Unit Destruction Tests

func test_destroy_unit():
	var unit = manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var unit_id = unit.id

	manager.destroy_unit(unit_id)

	assert_false(manager.unit_exists(unit_id), "Unit should not exist")
	assert_eq(manager.get_unit_count(), 0, "Manager should have 0 units")

func test_destroy_unit_removes_from_spatial_index():
	var pos = Vector3i(5, 5, 0)
	var unit = manager.create_unit("militia", 1, pos)

	manager.destroy_unit(unit.id)

	var units_at_pos = manager.get_units_at_position(pos)
	assert_eq(units_at_pos.size(), 0, "Should have no units at position")

func test_destroy_unit_removes_from_faction_index():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))

	manager.destroy_unit(unit.id)

	var faction_units = manager.get_units_by_faction(1)
	assert_eq(faction_units.size(), 0, "Should have no faction units")

func test_destroy_nonexistent_unit():
	# Should not crash
	manager.destroy_unit(999)
	assert_true(true, "Should handle gracefully")

# Turn Management Tests

func test_reset_turn_state():
	var unit = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.movement_remaining = 0
	unit.actions_remaining = 0

	manager.reset_turn_state(unit.id)

	assert_eq(unit.movement_remaining, unit.stats.movement, "Movement should be reset")
	assert_eq(unit.actions_remaining, 1, "Actions should be reset")

func test_reset_turn_state_all():
	var unit1 = manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	var unit2 = manager.create_unit("soldier", 1, Vector3i(1, 1, 0))

	unit1.movement_remaining = 0
	unit2.movement_remaining = 0

	manager.reset_turn_state_all()

	assert_eq(unit1.movement_remaining, unit1.stats.movement, "Unit1 movement should be reset")
	assert_eq(unit2.movement_remaining, unit2.stats.movement, "Unit2 movement should be reset")

# Utility Tests

func test_get_unit_count():
	assert_eq(manager.get_unit_count(), 0, "Should start with 0 units")

	manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	assert_eq(manager.get_unit_count(), 1, "Should have 1 unit")

	manager.create_unit("soldier", 1, Vector3i(1, 1, 0))
	assert_eq(manager.get_unit_count(), 2, "Should have 2 units")

func test_get_faction_unit_count():
	manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	manager.create_unit("soldier", 1, Vector3i(1, 1, 0))
	manager.create_unit("militia", 2, Vector3i(2, 2, 0))

	assert_eq(manager.get_faction_unit_count(1), 2, "Faction 1 should have 2 units")
	assert_eq(manager.get_faction_unit_count(2), 1, "Faction 2 should have 1 unit")
	assert_eq(manager.get_faction_unit_count(3), 0, "Faction 3 should have 0 units")

func test_clear_all_units():
	manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	manager.create_unit("soldier", 1, Vector3i(1, 1, 0))

	manager.clear_all_units()

	assert_eq(manager.get_unit_count(), 0, "All units should be cleared")
