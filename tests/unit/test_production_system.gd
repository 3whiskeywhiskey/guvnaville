extends GutTest

## Unit tests for ProductionSystem
## Tests production queue management, progress, completion, and cancellation

var production_system: ProductionSystem
var resource_manager: ResourceManager
var test_faction_id = 1

func before_each():
	resource_manager = ResourceManager.new()
	resource_manager.initialize_faction(test_faction_id)

	production_system = ProductionSystem.new()
	production_system.set_resource_manager(resource_manager)
	production_system.initialize_faction(test_faction_id)

func after_each():
	production_system.free()
	resource_manager.free()

# Test: Initialize faction
func test_initialize_faction():
	var faction_id = 2
	production_system.initialize_faction(faction_id)

	var queue = production_system.get_production_queue(faction_id)
	assert_not_null(queue, "Queue should not be null")
	assert_eq(queue.size(), 0, "Queue should be empty initially")

# Test: Add to production queue
func test_add_to_production_queue():
	var success = production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	assert_true(success, "Should successfully add to queue")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Queue should have 1 item")
	assert_eq(queue[0]["item_type"], "unit", "Item type should be unit")
	assert_eq(queue[0]["item_id"], "militia", "Item ID should be militia")

# Test: Add to production queue emits signal
func test_add_to_production_queue_emits_signal():
	watch_signals(production_system)

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	assert_signal_emitted(production_system, "production_queue_updated")
	var signal_params = get_signal_parameters(production_system, "production_queue_updated")
	assert_eq(signal_params[0], test_faction_id, "Signal should include faction_id")

# Test: Add building to production queue
func test_add_building_to_queue():
	var success = production_system.add_to_production_queue(test_faction_id, "building", "shelter")

	assert_true(success, "Should successfully add building")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Queue should have 1 item")
	assert_eq(queue[0]["item_type"], "building", "Item type should be building")

# Test: Add invalid item fails
func test_add_invalid_item():
	var success = production_system.add_to_production_queue(test_faction_id, "unit", "invalid_unit")

	assert_false(success, "Should fail for invalid item")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 0, "Queue should remain empty")

# Test: Process production without resources
func test_process_production_no_resources():
	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	var completed = production_system.process_production(test_faction_id, 100)

	assert_eq(completed.size(), 0, "Should not complete without resources")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Item should remain in queue")
	assert_eq(queue[0]["progress"], 0, "Progress should be 0 (waiting for resources)")

# Test: Process production with resources
func test_process_production_with_resources():
	# Give faction enough resources for militia
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 50})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	# Process production (militia needs 1 turn = 100 PP)
	var completed = production_system.process_production(test_faction_id, 100)

	assert_eq(completed.size(), 1, "Should complete 1 item")
	assert_eq(completed[0]["type"], "unit", "Completed item should be unit")
	assert_eq(completed[0]["id"], "militia", "Completed item should be militia")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 0, "Queue should be empty after completion")

# Test: Process production partial progress
func test_process_production_partial():
	resource_manager.add_resources(test_faction_id, {"scrap": 100, "food": 100})

	production_system.add_to_production_queue(test_faction_id, "unit", "soldier")  # 2 turns

	# Process with half the required PP
	var completed = production_system.process_production(test_faction_id, 100)

	assert_eq(completed.size(), 0, "Should not complete yet")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Item should still be in queue")
	assert_eq(queue[0]["progress"], 100, "Progress should be 100")

	# Process again to complete
	completed = production_system.process_production(test_faction_id, 100)
	assert_eq(completed.size(), 1, "Should complete now")

# Test: Process production emits signal
func test_process_production_emits_signal():
	watch_signals(production_system)
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 50})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")
	production_system.process_production(test_faction_id, 100)

	assert_signal_emitted(production_system, "production_completed")
	var signal_params = get_signal_parameters(production_system, "production_completed")
	assert_eq(signal_params[0], test_faction_id, "Signal should include faction_id")
	assert_eq(signal_params[1], "unit", "Signal should include item type")
	assert_eq(signal_params[2], "militia", "Signal should include item id")

# Test: Process production consumes resources
func test_process_production_consumes_resources():
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 50})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	var scrap_before = resource_manager.get_resource(test_faction_id, "scrap")
	var food_before = resource_manager.get_resource(test_faction_id, "food")

	production_system.process_production(test_faction_id, 100)

	var scrap_after = resource_manager.get_resource(test_faction_id, "scrap")
	var food_after = resource_manager.get_resource(test_faction_id, "food")

	assert_lt(scrap_after, scrap_before, "Scrap should be consumed")
	assert_lt(food_after, food_before, "Food should be consumed")

# Test: Multiple items in queue
func test_multiple_items_in_queue():
	resource_manager.add_resources(test_faction_id, {"scrap": 200, "food": 100})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")
	production_system.add_to_production_queue(test_faction_id, "unit", "scout")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 2, "Queue should have 2 items")

	# Process first item
	var completed = production_system.process_production(test_faction_id, 100)
	assert_eq(completed.size(), 1, "Should complete first item")
	assert_eq(completed[0]["id"], "militia", "First item should be militia")

	queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Queue should have 1 item remaining")
	assert_eq(queue[0]["item_id"], "scout", "Remaining item should be scout")

# Test: Cancel production
func test_cancel_production():
	watch_signals(production_system)
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 50})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	var success = production_system.cancel_production(test_faction_id, 0)

	assert_true(success, "Cancellation should succeed")
	assert_signal_emitted(production_system, "production_cancelled")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 0, "Queue should be empty")

# Test: Cancel production with invalid index
func test_cancel_production_invalid_index():
	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	var success = production_system.cancel_production(test_faction_id, 5)

	assert_false(success, "Cancellation should fail with invalid index")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Queue should remain unchanged")

# Test: Cancel production refunds resources
func test_cancel_production_refunds():
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 50})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	# Start production to pay resources
	production_system.process_production(test_faction_id, 50)

	var scrap_before = resource_manager.get_resource(test_faction_id, "scrap")
	var food_before = resource_manager.get_resource(test_faction_id, "food")

	production_system.cancel_production(test_faction_id, 0)

	var scrap_after = resource_manager.get_resource(test_faction_id, "scrap")
	var food_after = resource_manager.get_resource(test_faction_id, "food")

	# Resources should be refunded
	assert_gt(scrap_after, scrap_before, "Scrap should be refunded")
	assert_gt(food_after, food_before, "Food should be refunded")

# Test: Rush production
func test_rush_production():
	watch_signals(production_system)
	# Give 2x resources for rush
	resource_manager.add_resources(test_faction_id, {"scrap": 100, "food": 100})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	var success = production_system.rush_production(test_faction_id, 0)

	assert_true(success, "Rush should succeed")
	assert_signal_emitted(production_system, "production_completed")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 0, "Queue should be empty after rush")

# Test: Rush production insufficient resources
func test_rush_production_insufficient():
	resource_manager.add_resources(test_faction_id, {"scrap": 20, "food": 10})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	var success = production_system.rush_production(test_faction_id, 0)

	assert_false(success, "Rush should fail with insufficient resources")

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 1, "Item should remain in queue")

# Test: Get current production progress
func test_get_current_production_progress():
	resource_manager.add_resources(test_faction_id, {"scrap": 100, "food": 100})

	production_system.add_to_production_queue(test_faction_id, "unit", "soldier")  # 2 turns = 200 PP

	# No progress yet
	var progress = production_system.get_current_production_progress(test_faction_id)
	assert_eq(progress, 0.0, "Progress should be 0.0")

	# Process 50%
	production_system.process_production(test_faction_id, 100)
	progress = production_system.get_current_production_progress(test_faction_id)
	assert_almost_eq(progress, 0.5, 0.01, "Progress should be ~0.5")

	# Complete
	production_system.process_production(test_faction_id, 100)
	progress = production_system.get_current_production_progress(test_faction_id)
	assert_eq(progress, -1.0, "Progress should be -1.0 when queue is empty")

# Test: Is producing check
func test_is_producing():
	assert_false(production_system.is_producing(test_faction_id), "Should not be producing initially")

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")

	assert_true(production_system.is_producing(test_faction_id), "Should be producing after adding item")

# Test: Get queue size
func test_get_queue_size():
	assert_eq(production_system.get_queue_size(test_faction_id), 0, "Queue size should be 0")

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")
	assert_eq(production_system.get_queue_size(test_faction_id), 1, "Queue size should be 1")

	production_system.add_to_production_queue(test_faction_id, "unit", "scout")
	assert_eq(production_system.get_queue_size(test_faction_id), 2, "Queue size should be 2")

# Test: Save and load state
func test_save_load_state():
	resource_manager.add_resources(test_faction_id, {"scrap": 100, "food": 100})

	production_system.add_to_production_queue(test_faction_id, "unit", "militia")
	production_system.add_to_production_queue(test_faction_id, "building", "shelter")

	# Make some progress
	production_system.process_production(test_faction_id, 50)

	var state = production_system.save_state()

	# Create new system and load
	var new_system = ProductionSystem.new()
	new_system.load_state(state)

	var queue = new_system.get_production_queue(test_faction_id)
	assert_eq(queue.size(), 2, "Queue should have 2 items")
	assert_eq(queue[0]["item_id"], "militia", "First item should be militia")
	assert_eq(queue[0]["progress"], 50, "Progress should be restored")

	new_system.free()

# Test: Invalid faction ID
func test_invalid_faction_id():
	var queue = production_system.get_production_queue(999)
	assert_eq(queue.size(), 0, "Should return empty queue for invalid faction")

	var success = production_system.add_to_production_queue(999, "unit", "militia")
	assert_false(success, "Should fail for invalid faction")

# Test: Production with settlement ID
func test_production_with_settlement():
	production_system.add_to_production_queue(test_faction_id, "building", "shelter", 5)

	var queue = production_system.get_production_queue(test_faction_id)
	assert_eq(queue[0]["settlement_id"], 5, "Settlement ID should be stored")
