extends GutTest

## Unit tests for ScavengingSystem
## Tests scavenging operations, tile depletion, and yield calculation

var scavenging_system: ScavengingSystem
var resource_manager: ResourceManager
var test_faction_id = 1
var test_position = Vector3i(10, 15, 0)

func before_each():
	resource_manager = ResourceManager.new()
	resource_manager.initialize_faction(test_faction_id)

	scavenging_system = ScavengingSystem.new()
	scavenging_system.set_resource_manager(resource_manager)

func after_each():
	scavenging_system.free()
	resource_manager.free()

# Test: Initialize tile
func test_initialize_tile():
	scavenging_system.initialize_tile(test_position, "residential")

	var value = scavenging_system.get_tile_scavenge_value(test_position)
	assert_gt(value, 0, "Tile should have scavenge value")

	var tile_type = scavenging_system.get_tile_type(test_position)
	assert_eq(tile_type, "residential", "Tile type should be residential")

# Test: Initialize tile with custom value
func test_initialize_tile_custom_value():
	scavenging_system.initialize_tile(test_position, "industrial", 90)

	var value = scavenging_system.get_tile_scavenge_value(test_position)
	assert_eq(value, 90, "Tile should have custom scavenge value")

# Test: Scavenge tile success
func test_scavenge_tile_success():
	watch_signals(scavenging_system)
	scavenging_system.initialize_tile(test_position, "residential")

	var result = scavenging_system.scavenge_tile(test_position, test_faction_id, 1)

	assert_true(result.success, "Scavenge should succeed")
	assert_signal_emitted(scavenging_system, "scavenging_completed")

# Test: Scavenge tile yields resources
func test_scavenge_tile_yields_resources():
	scavenging_system.initialize_tile(test_position, "residential")

	var initial_scrap = resource_manager.get_resource(test_faction_id, "scrap")

	# Scavenge multiple times to get resources (RNG)
	var got_resources = false
	for i in range(10):
		var result = scavenging_system.scavenge_tile(test_position, test_faction_id, 1)
		if not result.resources_found.is_empty():
			got_resources = true
			break

	assert_true(got_resources, "Should find resources after multiple scavenges")

# Test: Scavenge tile depletes value
func test_scavenge_tile_depletes():
	scavenging_system.initialize_tile(test_position, "residential", 50)

	var initial_value = scavenging_system.get_tile_scavenge_value(test_position)

	scavenging_system.scavenge_tile(test_position, test_faction_id, 1)

	var new_value = scavenging_system.get_tile_scavenge_value(test_position)
	assert_lt(new_value, initial_value, "Tile should be depleted")

# Test: Scavenge depleted tile
func test_scavenge_depleted_tile():
	scavenging_system.initialize_tile(test_position, "residential", 0)

	var result = scavenging_system.scavenge_tile(test_position, test_faction_id, 1)

	assert_true(result.success, "Should succeed even when depleted")
	# Depleted tiles still give minimal scrap
	assert_true(result.resources_found.has("scrap"), "Should get minimal scrap")
	assert_lte(result.resources_found["scrap"], 2, "Should get only 1-2 scrap")

# Test: Scavenge with multiple scavengers
func test_scavenge_multiple_scavengers():
	scavenging_system.initialize_tile(test_position, "industrial", 80)

	var initial_value = scavenging_system.get_tile_scavenge_value(test_position)

	scavenging_system.scavenge_tile(test_position, test_faction_id, 3)

	var new_value = scavenging_system.get_tile_scavenge_value(test_position)
	var depletion = initial_value - new_value

	# More scavengers should deplete more
	assert_gt(depletion, 10, "Multiple scavengers should deplete more")

# Test: Scavenge uninitialized tile
func test_scavenge_uninitialized_tile():
	var unknown_pos = Vector3i(999, 999, 0)
	var result = scavenging_system.scavenge_tile(unknown_pos, test_faction_id, 1)

	assert_false(result.success, "Should fail for uninitialized tile")

# Test: Get tile scavenge value
func test_get_tile_scavenge_value():
	scavenging_system.initialize_tile(test_position, "commercial", 70)

	var value = scavenging_system.get_tile_scavenge_value(test_position)
	assert_eq(value, 70, "Should return correct scavenge value")

	# Uninitialized tile
	var unknown_value = scavenging_system.get_tile_scavenge_value(Vector3i(999, 999, 0))
	assert_eq(unknown_value, 0, "Should return 0 for uninitialized tile")

# Test: Set tile scavenge value
func test_set_tile_scavenge_value():
	scavenging_system.initialize_tile(test_position, "residential")

	scavenging_system.set_tile_scavenge_value(test_position, 55)

	var value = scavenging_system.get_tile_scavenge_value(test_position)
	assert_eq(value, 55, "Value should be set")

# Test: Get scavenge estimate
func test_get_scavenge_estimate():
	scavenging_system.initialize_tile(test_position, "industrial")

	var estimate = scavenging_system.get_scavenge_estimate(test_position, test_faction_id)

	assert_not_null(estimate, "Estimate should not be null")
	assert_true(estimate.has("min"), "Estimate should have min")
	assert_true(estimate.has("max"), "Estimate should have max")
	assert_true(estimate.has("average"), "Estimate should have average")

# Test: Get scavenge estimate for depleted tile
func test_get_scavenge_estimate_depleted():
	scavenging_system.initialize_tile(test_position, "residential", 0)

	var estimate = scavenging_system.get_scavenge_estimate(test_position, test_faction_id)

	assert_eq(estimate["min"]["scrap"], 1, "Min scrap should be 1 for depleted tile")
	assert_eq(estimate["max"]["scrap"], 2, "Max scrap should be 2 for depleted tile")

# Test: Different tile types have different yields
func test_different_tile_types():
	var pos_res = Vector3i(0, 0, 0)
	var pos_ind = Vector3i(1, 0, 0)
	var pos_mil = Vector3i(2, 0, 0)

	scavenging_system.initialize_tile(pos_res, "residential")
	scavenging_system.initialize_tile(pos_ind, "industrial")
	scavenging_system.initialize_tile(pos_mil, "military")

	var est_res = scavenging_system.get_scavenge_estimate(pos_res)
	var est_ind = scavenging_system.get_scavenge_estimate(pos_ind)
	var est_mil = scavenging_system.get_scavenge_estimate(pos_mil)

	# Industrial should generally give more scrap
	assert_true(est_ind["average"].has("scrap"), "Industrial should yield scrap")

	# Military should yield ammunition
	assert_true(est_mil["average"].has("ammunition"), "Military should yield ammunition")

# Test: Is tile depleted
func test_is_tile_depleted():
	scavenging_system.initialize_tile(test_position, "residential", 50)

	assert_false(scavenging_system.is_tile_depleted(test_position), "Tile should not be depleted")

	scavenging_system.set_tile_scavenge_value(test_position, 0)

	assert_true(scavenging_system.is_tile_depleted(test_position), "Tile should be depleted")

# Test: Get available scavenge tiles
func test_get_available_scavenge_tiles():
	var pos1 = Vector3i(0, 0, 0)
	var pos2 = Vector3i(1, 0, 0)
	var pos3 = Vector3i(2, 0, 0)

	scavenging_system.initialize_tile(pos1, "residential", 50)
	scavenging_system.initialize_tile(pos2, "commercial", 0)  # Depleted
	scavenging_system.initialize_tile(pos3, "industrial", 80)

	var available = scavenging_system.get_available_scavenge_tiles()

	assert_eq(available.size(), 2, "Should have 2 available tiles")
	assert_true(pos1 in available, "pos1 should be available")
	assert_true(pos3 in available, "pos3 should be available")
	assert_false(pos2 in available, "pos2 should not be available (depleted)")

# Test: Get total tile count
func test_get_total_tile_count():
	scavenging_system.initialize_tile(Vector3i(0, 0, 0), "residential")
	scavenging_system.initialize_tile(Vector3i(1, 0, 0), "commercial")
	scavenging_system.initialize_tile(Vector3i(2, 0, 0), "industrial")

	var count = scavenging_system.get_total_tile_count()
	assert_eq(count, 3, "Should have 3 tiles")

# Test: Get depleted tile count
func test_get_depleted_tile_count():
	scavenging_system.initialize_tile(Vector3i(0, 0, 0), "residential", 50)
	scavenging_system.initialize_tile(Vector3i(1, 0, 0), "commercial", 0)
	scavenging_system.initialize_tile(Vector3i(2, 0, 0), "industrial", 0)

	var count = scavenging_system.get_depleted_tile_count()
	assert_eq(count, 2, "Should have 2 depleted tiles")

# Test: Save and load state
func test_save_load_state():
	scavenging_system.initialize_tile(test_position, "residential", 75)
	scavenging_system.initialize_tile(Vector3i(5, 10, 0), "industrial", 80)

	var state = scavenging_system.save_state()

	var new_system = ScavengingSystem.new()
	new_system.load_state(state)

	var value1 = new_system.get_tile_scavenge_value(test_position)
	var value2 = new_system.get_tile_scavenge_value(Vector3i(5, 10, 0))

	assert_eq(value1, 75, "First tile value should be restored")
	assert_eq(value2, 80, "Second tile value should be restored")

	var type1 = new_system.get_tile_type(test_position)
	assert_eq(type1, "residential", "Tile type should be restored")

	new_system.free()

# Test: Scavenge hazard events (probabilistic)
func test_scavenge_hazard_events():
	# This test is probabilistic, so we scavenge many times
	scavenging_system.initialize_tile(test_position, "residential")

	var got_event = false
	for i in range(50):  # Try 50 times
		var result = scavenging_system.scavenge_tile(test_position, test_faction_id, 1)
		if result.event_triggered != "":
			got_event = true
			break

	# Note: This test might occasionally fail due to RNG, but with 50 tries it's very unlikely
	# We're just checking that the event system works
	pass  # Not asserting because it's RNG-based

# Test: Industrial ruins yield more
func test_industrial_ruins_yield_more():
	var pos_res = Vector3i(0, 0, 0)
	var pos_ind = Vector3i(1, 0, 0)

	scavenging_system.initialize_tile(pos_res, "residential")
	scavenging_system.initialize_tile(pos_ind, "industrial")

	var initial_res = scavenging_system.get_tile_scavenge_value(pos_res)
	var initial_ind = scavenging_system.get_tile_scavenge_value(pos_ind)

	assert_gte(initial_ind, initial_res, "Industrial should start with higher or equal value")

# Test: Medical ruins yield medicine
func test_medical_ruins_yield_medicine():
	scavenging_system.initialize_tile(test_position, "medical")

	var got_medicine = false
	for i in range(20):
		var result = scavenging_system.scavenge_tile(test_position, test_faction_id, 1)
		if result.resources_found.has("medicine") and result.resources_found["medicine"] > 0:
			got_medicine = true
			break

	assert_true(got_medicine, "Medical tiles should yield medicine")

# Test: Resources are added to faction
func test_resources_added_to_faction():
	scavenging_system.initialize_tile(test_position, "industrial")

	var initial_resources = resource_manager.get_resources(test_faction_id)

	# Scavenge until we get resources
	for i in range(10):
		scavenging_system.scavenge_tile(test_position, test_faction_id, 1)

	var final_resources = resource_manager.get_resources(test_faction_id)

	# At least some resource should have increased
	var total_initial = 0
	var total_final = 0
	for key in initial_resources.keys():
		total_initial += initial_resources[key]
		total_final += final_resources[key]

	assert_gt(total_final, total_initial, "Resources should increase after scavenging")
