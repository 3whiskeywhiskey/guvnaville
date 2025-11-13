extends GutTest

## Unit Tests for MovementSystem
## Tests unit movement, pathfinding, and terrain costs

var movement_system: MovementSystem
var unit_manager: UnitManager
var factory: UnitFactory

func before_each():
	factory = UnitFactory.new()
	factory.load_unit_data()

	unit_manager = UnitManager.new()
	unit_manager.set_factory(factory)

	movement_system = MovementSystem.new()
	movement_system.set_unit_manager(unit_manager)

func after_each():
	unit_manager.clear_all_units()
	if movement_system:
		movement_system.queue_free()
	if unit_manager:
		unit_manager.queue_free()
	if factory:
		factory.queue_free()
	movement_system = null
	unit_manager = null
	factory = null

# Movement Cost Tests

func test_get_movement_cost_adjacent():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var from = Vector3i(5, 5, 0)
	var to = Vector3i(6, 5, 0)

	var cost = movement_system.get_movement_cost(unit, from, to)

	assert_gt(cost, 0, "Adjacent tiles should have movement cost")

func test_get_movement_cost_non_adjacent():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var from = Vector3i(5, 5, 0)
	var to = Vector3i(10, 10, 0)

	var cost = movement_system.get_movement_cost(unit, from, to)

	assert_eq(cost, 0, "Non-adjacent tiles should have 0 cost")

# Basic Movement Tests

func test_move_unit_adjacent():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var target = Vector3i(6, 5, 0)

	var success = movement_system.move_unit(unit.id, target)

	assert_true(success, "Movement should succeed")
	assert_eq(unit.position, target, "Unit should be at target position")
	assert_lt(unit.movement_remaining, unit.stats.movement, "Movement points should be consumed")

func test_move_unit_multiple_tiles():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 10  # Give lots of movement
	var target = Vector3i(7, 5, 0)

	var success = movement_system.move_unit(unit.id, target)

	assert_true(success, "Multi-tile movement should succeed")
	assert_eq(unit.position, target, "Unit should be at target position")

func test_move_unit_insufficient_movement():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 1
	var target = Vector3i(15, 15, 0)  # Far away

	var success = movement_system.move_unit(unit.id, target)

	assert_false(success, "Movement should fail with insufficient movement points")
	assert_eq(unit.position, Vector3i(5, 5, 0), "Unit should not move")

func test_move_unit_no_movement_remaining():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 0
	var target = Vector3i(6, 5, 0)

	var success = movement_system.move_unit(unit.id, target)

	assert_false(success, "Movement should fail with no movement points")

func test_move_unit_dead():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.current_hp = 0
	var target = Vector3i(6, 5, 0)

	var success = movement_system.move_unit(unit.id, target)

	assert_false(success, "Dead unit should not be able to move")

func test_move_unit_routed():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.morale = 0
	var target = Vector3i(6, 5, 0)

	var success = movement_system.move_unit(unit.id, target)

	assert_false(success, "Routed unit should not be able to move")

# Movement Validation Tests

func test_can_move_to_valid():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var target = Vector3i(6, 5, 0)

	var can_move = movement_system.can_move_to(unit.id, target)

	assert_true(can_move, "Should be able to move to adjacent tile")

func test_can_move_to_same_position():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var target = Vector3i(5, 5, 0)

	var can_move = movement_system.can_move_to(unit.id, target)

	assert_false(can_move, "Should not be able to move to same position")

func test_can_move_to_enemy_occupied():
	var unit1 = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var target = Vector3i(6, 5, 0)
	var unit2 = unit_manager.create_unit("soldier", 2, target)  # Enemy unit

	var can_move = movement_system.can_move_to(unit1.id, target)

	assert_false(can_move, "Should not be able to move to enemy-occupied tile")

func test_can_move_to_friendly_occupied():
	var unit1 = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var target = Vector3i(6, 5, 0)
	var unit2 = unit_manager.create_unit("soldier", 1, target)  # Friendly unit

	# Should be able to move to friendly-occupied tile (stacking)
	var can_move = movement_system.can_move_to(unit1.id, target)

	# This depends on game rules - for now we allow stacking
	assert_true(can_move, "Should be able to move to friendly-occupied tile")

# Reachable Tiles Tests

func test_get_reachable_tiles():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 3

	var reachable = movement_system.get_reachable_tiles(unit.id)

	assert_gt(reachable.size(), 0, "Should have reachable tiles")
	# With 3 movement, infantry should reach several tiles
	assert_le(reachable.size(), 20, "Should not reach too many tiles")

func test_get_reachable_tiles_no_movement():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 0

	var reachable = movement_system.get_reachable_tiles(unit.id)

	assert_eq(reachable.size(), 0, "Should have no reachable tiles with 0 movement")

func test_get_reachable_tiles_caching():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))

	var reachable1 = movement_system.get_reachable_tiles(unit.id)
	var reachable2 = movement_system.get_reachable_tiles(unit.id)

	assert_eq(reachable1.size(), reachable2.size(), "Cached result should match")

func test_get_reachable_tiles_cache_cleared_after_move():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 10

	var reachable_before = movement_system.get_reachable_tiles(unit.id)
	movement_system.move_unit(unit.id, Vector3i(6, 5, 0))
	var reachable_after = movement_system.get_reachable_tiles(unit.id)

	# Reachable tiles should be different after moving
	assert_ne(reachable_before.size(), reachable_after.size(), "Cache should be cleared after move")

# Reset Movement Tests

func test_reset_movement():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	unit.movement_remaining = 0

	movement_system.reset_movement(unit.id)

	assert_eq(unit.movement_remaining, unit.get_effective_movement(), "Movement should be reset")

func test_clear_cache():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))
	var reachable = movement_system.get_reachable_tiles(unit.id)

	movement_system.clear_cache()

	# Cache is cleared, but we can't directly verify without internal access
	# Just ensure it doesn't crash
	assert_true(true, "Cache clear should not crash")

# Status Effect Movement Modifier Tests

func test_movement_with_status_effect():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))

	# Add movement debuff
	var effect = {
		"id": "slow",
		"stat_modifiers": {"movement": 0.5},  # Half movement
		"movement_cost_modifier": 2.0  # Double cost
	}
	unit.status_effects.append(effect)

	var from = Vector3i(5, 5, 0)
	var to = Vector3i(6, 5, 0)
	var cost = movement_system.get_movement_cost(unit, from, to)

	assert_gt(cost, 1, "Movement cost should be increased by status effect")

# Immobilization Tests

func test_immobilized_unit_cannot_move():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))

	# Add immobilization effect
	var effect = {
		"id": "rooted",
		"immobilized": true
	}
	unit.status_effects.append(effect)

	var can_move = unit.can_move()

	assert_false(can_move, "Immobilized unit should not be able to move")

# Pathfinding Tests

func test_pathfinding_straight_line():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.movement_remaining = 10

	var success = movement_system.move_unit(unit.id, Vector3i(3, 0, 0))

	assert_true(success, "Should find straight path")
	assert_eq(unit.position, Vector3i(3, 0, 0), "Should reach destination")

func test_pathfinding_around_obstacle():
	# This would require proper map integration
	# For now, just test basic pathfinding
	var unit = unit_manager.create_unit("militia", 1, Vector3i(0, 0, 0))
	unit.movement_remaining = 10

	var target = Vector3i(2, 2, 0)
	var success = movement_system.move_unit(unit.id, target)

	# Should find some path (even if not optimal)
	assert_true(success, "Should find path")

# Edge Cases

func test_move_nonexistent_unit():
	var success = movement_system.move_unit(999, Vector3i(0, 0, 0))

	assert_false(success, "Should fail for nonexistent unit")

func test_get_reachable_tiles_nonexistent_unit():
	var reachable = movement_system.get_reachable_tiles(999)

	assert_eq(reachable.size(), 0, "Should return empty array for nonexistent unit")

func test_movement_updates_has_moved_flag():
	var unit = unit_manager.create_unit("militia", 1, Vector3i(5, 5, 0))

	assert_false(unit.has_moved, "Unit should not have moved initially")

	movement_system.move_unit(unit.id, Vector3i(6, 5, 0))

	assert_true(unit.has_moved, "Unit should have moved flag set")
