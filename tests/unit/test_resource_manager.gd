extends GutTest

## Unit tests for ResourceManager
## Tests resource tracking, addition, consumption, and shortage detection

var resource_manager: ResourceManager
var test_faction_id = 1

func before_each():
	resource_manager = ResourceManager.new()
	resource_manager.initialize_faction(test_faction_id)

func after_each():
	resource_manager.free()

# Test: Faction initialization
func test_initialize_faction():
	var faction_id = 2
	resource_manager.initialize_faction(faction_id)

	var resources = resource_manager.get_resources(faction_id)
	assert_not_null(resources, "Resources should not be null")
	assert_eq(resources["scrap"], 0, "Initial scrap should be 0")
	assert_eq(resources["food"], 0, "Initial food should be 0")
	assert_eq(resources["medicine"], 0, "Initial medicine should be 0")
	assert_eq(resources["fuel"], 0, "Initial fuel should be 0")

# Test: Add resources
func test_add_resources():
	var resources_to_add = {"scrap": 50, "food": 30}
	resource_manager.add_resources(test_faction_id, resources_to_add)

	var resources = resource_manager.get_resources(test_faction_id)
	assert_eq(resources["scrap"], 50, "Scrap should be 50")
	assert_eq(resources["food"], 30, "Food should be 30")

# Test: Add resources emits signal
func test_add_resources_emits_signal():
	watch_signals(resource_manager)

	resource_manager.add_resources(test_faction_id, {"scrap": 25})

	assert_signal_emitted(resource_manager, "resource_changed")
	var signal_params = get_signal_parameters(resource_manager, "resource_changed")
	assert_eq(signal_params[0], test_faction_id, "Signal should include faction_id")
	assert_eq(signal_params[1], "scrap", "Signal should include resource type")
	assert_eq(signal_params[2], 25, "Signal should include amount delta")

# Test: Add negative resources (should be treated as 0)
func test_add_negative_resources():
	resource_manager.add_resources(test_faction_id, {"scrap": -50})

	var resources = resource_manager.get_resources(test_faction_id)
	assert_eq(resources["scrap"], 0, "Negative amounts should be ignored")

# Test: Consume resources successfully
func test_consume_resources_success():
	resource_manager.add_resources(test_faction_id, {"scrap": 100, "food": 50})

	var success = resource_manager.consume_resources(test_faction_id, {"scrap": 30, "food": 20})

	assert_true(success, "Consumption should succeed")
	var resources = resource_manager.get_resources(test_faction_id)
	assert_eq(resources["scrap"], 70, "Scrap should be 70")
	assert_eq(resources["food"], 30, "Food should be 30")

# Test: Consume resources fails when insufficient
func test_consume_resources_insufficient():
	resource_manager.add_resources(test_faction_id, {"scrap": 20})

	var success = resource_manager.consume_resources(test_faction_id, {"scrap": 30})

	assert_false(success, "Consumption should fail")
	var resources = resource_manager.get_resources(test_faction_id)
	assert_eq(resources["scrap"], 20, "Scrap should remain unchanged")

# Test: Consume resources is atomic
func test_consume_resources_atomic():
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 10})

	# Try to consume more food than available
	var success = resource_manager.consume_resources(test_faction_id, {"scrap": 30, "food": 20})

	assert_false(success, "Consumption should fail")
	var resources = resource_manager.get_resources(test_faction_id)
	assert_eq(resources["scrap"], 50, "Scrap should remain unchanged (atomic)")
	assert_eq(resources["food"], 10, "Food should remain unchanged (atomic)")

# Test: Consume resources emits shortage signal
func test_consume_resources_emits_shortage():
	watch_signals(resource_manager)
	resource_manager.add_resources(test_faction_id, {"scrap": 10})

	resource_manager.consume_resources(test_faction_id, {"scrap": 20})

	assert_signal_emitted(resource_manager, "resource_shortage")
	var signal_params = get_signal_parameters(resource_manager, "resource_shortage")
	assert_eq(signal_params[0], test_faction_id, "Signal should include faction_id")
	assert_eq(signal_params[1], "scrap", "Signal should include resource type")
	assert_eq(signal_params[2], 10, "Signal should include deficit")

# Test: Has resources check
func test_has_resources():
	resource_manager.add_resources(test_faction_id, {"scrap": 50, "food": 30})

	assert_true(resource_manager.has_resources(test_faction_id, {"scrap": 30, "food": 20}))
	assert_false(resource_manager.has_resources(test_faction_id, {"scrap": 60}))
	assert_false(resource_manager.has_resources(test_faction_id, {"food": 40}))

# Test: Get specific resource
func test_get_resource():
	resource_manager.add_resources(test_faction_id, {"scrap": 75})

	var scrap = resource_manager.get_resource(test_faction_id, "scrap")
	assert_eq(scrap, 75, "Should return correct resource amount")

	var fuel = resource_manager.get_resource(test_faction_id, "fuel")
	assert_eq(fuel, 0, "Should return 0 for unset resource")

# Test: Set resource
func test_set_resource():
	watch_signals(resource_manager)

	resource_manager.set_resource(test_faction_id, "scrap", 999)

	var scrap = resource_manager.get_resource(test_faction_id, "scrap")
	assert_eq(scrap, 999, "Resource should be set to 999")
	assert_signal_emitted(resource_manager, "resource_changed")

# Test: Set resource income
func test_set_resource_income():
	resource_manager.set_resource_income(test_faction_id, "scrap", 25)
	resource_manager.set_resource_income(test_faction_id, "food", -15)

	var income = resource_manager.get_resource_income(test_faction_id)
	assert_eq(income["scrap"], 25, "Scrap income should be 25")
	assert_eq(income["food"], -15, "Food income should be -15")

# Test: Check shortages with warning threshold
func test_check_shortages():
	resource_manager.add_resources(test_faction_id, {"food": 20})
	resource_manager.set_resource_income(test_faction_id, "food", -10)

	var warnings = resource_manager.check_shortages(test_faction_id, 3)

	assert_eq(warnings.size(), 1, "Should have 1 warning")
	assert_eq(warnings[0]["resource_type"], "food", "Warning should be for food")
	assert_eq(warnings[0]["turns_remaining"], 2, "Should run out in 2 turns")

# Test: Check shortages emits signal when critical
func test_check_shortages_emits_signal():
	watch_signals(resource_manager)
	resource_manager.add_resources(test_faction_id, {"food": 5})
	resource_manager.set_resource_income(test_faction_id, "food", -10)

	resource_manager.check_shortages(test_faction_id, 3)

	assert_signal_emitted(resource_manager, "resource_shortage")

# Test: Invalid faction ID
func test_invalid_faction_id():
	var resources = resource_manager.get_resources(999)
	assert_eq(resources["scrap"], 0, "Should return empty stockpile for invalid faction")

	var success = resource_manager.consume_resources(999, {"scrap": 10})
	assert_false(success, "Should fail for invalid faction")

# Test: Invalid resource type
func test_invalid_resource_type():
	resource_manager.add_resources(test_faction_id, {"invalid_resource": 100})

	var resources = resource_manager.get_resources(test_faction_id)
	assert_false(resources.has("invalid_resource"), "Invalid resource should not be added")

# Test: Save and load state
func test_save_load_state():
	resource_manager.add_resources(test_faction_id, {"scrap": 100, "food": 50})
	resource_manager.set_resource_income(test_faction_id, "scrap", 25)

	var state = resource_manager.save_state()

	# Create new manager and load state
	var new_manager = ResourceManager.new()
	new_manager.load_state(state)

	var resources = new_manager.get_resources(test_faction_id)
	assert_eq(resources["scrap"], 100, "Scrap should be restored")
	assert_eq(resources["food"], 50, "Food should be restored")

	var income = new_manager.get_resource_income(test_faction_id)
	assert_eq(income["scrap"], 25, "Income should be restored")

	new_manager.free()

# Test: Multiple factions
func test_multiple_factions():
	var faction_a = 1
	var faction_b = 2

	resource_manager.initialize_faction(faction_a)
	resource_manager.initialize_faction(faction_b)

	resource_manager.add_resources(faction_a, {"scrap": 100})
	resource_manager.add_resources(faction_b, {"scrap": 200})

	assert_eq(resource_manager.get_resource(faction_a, "scrap"), 100)
	assert_eq(resource_manager.get_resource(faction_b, "scrap"), 200)

	# Consuming from one faction shouldn't affect the other
	resource_manager.consume_resources(faction_a, {"scrap": 50})
	assert_eq(resource_manager.get_resource(faction_a, "scrap"), 50)
	assert_eq(resource_manager.get_resource(faction_b, "scrap"), 200)

# Test: All resource types
func test_all_resource_types():
	var all_resources = {
		"scrap": 10,
		"food": 20,
		"medicine": 30,
		"fuel": 40,
		"electronics": 50,
		"materials": 60,
		"water": 70,
		"ammunition": 80
	}

	resource_manager.add_resources(test_faction_id, all_resources)

	var resources = resource_manager.get_resources(test_faction_id)
	for resource_type in all_resources.keys():
		assert_eq(resources[resource_type], all_resources[resource_type],
			"Resource %s should match" % resource_type)
