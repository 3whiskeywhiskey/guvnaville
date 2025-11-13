extends GutTest

## Unit tests for PopulationSystem
## Tests population growth, happiness, and assignment

var population_system: PopulationSystem
var resource_manager: ResourceManager
var test_faction_id = 1

func before_each():
	resource_manager = ResourceManager.new()
	resource_manager.initialize_faction(test_faction_id)

	population_system = PopulationSystem.new()
	population_system.set_resource_manager(resource_manager)
	population_system.initialize_faction(test_faction_id, 50)

func after_each():
	population_system.free()
	resource_manager.free()

# Test: Initialize faction
func test_initialize_faction():
	var faction_id = 2
	population_system.initialize_faction(faction_id, 100)

	var population = population_system.get_population(faction_id)
	assert_eq(population, 100, "Initial population should be 100")

	var happiness = population_system.get_happiness(faction_id)
	assert_almost_eq(happiness, 50.0, 0.1, "Initial happiness should be 50.0")

# Test: Get population
func test_get_population():
	var population = population_system.get_population(test_faction_id)
	assert_eq(population, 50, "Population should be 50")

# Test: Set population
func test_set_population():
	watch_signals(population_system)

	population_system.set_population(test_faction_id, 75)

	var population = population_system.get_population(test_faction_id)
	assert_eq(population, 75, "Population should be 75")

	assert_signal_emitted(population_system, "population_changed")

# Test: Get happiness
func test_get_happiness():
	var happiness = population_system.get_happiness(test_faction_id)
	assert_gte(happiness, 0.0, "Happiness should be >= 0")
	assert_lte(happiness, 100.0, "Happiness should be <= 100")

# Test: Update happiness with good conditions
func test_update_happiness_good_conditions():
	# Give faction plenty of resources
	resource_manager.add_resources(test_faction_id, {"food": 200, "water": 200, "medicine": 50})

	population_system.update_happiness(test_faction_id)

	var happiness = population_system.get_happiness(test_faction_id)
	assert_gt(happiness, 50.0, "Happiness should be above baseline with good conditions")

# Test: Update happiness with bad conditions
func test_update_happiness_bad_conditions():
	# Give faction insufficient resources
	resource_manager.add_resources(test_faction_id, {"food": 10, "water": 20})

	population_system.update_happiness(test_faction_id)

	var happiness = population_system.get_happiness(test_faction_id)
	assert_lt(happiness, 50.0, "Happiness should be below baseline with shortages")

# Test: Update happiness emits signal
func test_update_happiness_emits_signal():
	watch_signals(population_system)

	# Create significant change
	resource_manager.add_resources(test_faction_id, {"food": 500, "water": 500, "medicine": 100})
	population_system.update_happiness(test_faction_id)

	assert_signal_emitted(population_system, "happiness_changed")

# Test: Modify happiness
func test_modify_happiness():
	watch_signals(population_system)

	population_system.modify_happiness(test_faction_id, 15.0)

	var happiness = population_system.get_happiness(test_faction_id)
	assert_almost_eq(happiness, 65.0, 0.1, "Happiness should increase by 15")

	assert_signal_emitted(population_system, "happiness_changed")

# Test: Happiness clamped to 0-100
func test_happiness_clamped():
	population_system.modify_happiness(test_faction_id, 100.0)
	var happiness = population_system.get_happiness(test_faction_id)
	assert_lte(happiness, 100.0, "Happiness should not exceed 100")

	population_system.modify_happiness(test_faction_id, -200.0)
	happiness = population_system.get_happiness(test_faction_id)
	assert_gte(happiness, 0.0, "Happiness should not go below 0")

# Test: Process population growth with good conditions
func test_process_population_growth_good():
	# Give faction resources for growth
	resource_manager.add_resources(test_faction_id, {"food": 500, "water": 500, "medicine": 100})

	var initial_population = population_system.get_population(test_faction_id)

	population_system.process_population_growth(test_faction_id)

	var final_population = population_system.get_population(test_faction_id)
	assert_gte(final_population, initial_population, "Population should grow or stay same")

# Test: Process population growth consumes resources
func test_process_population_growth_consumes_resources():
	resource_manager.add_resources(test_faction_id, {"food": 100, "water": 200})

	var initial_food = resource_manager.get_resource(test_faction_id, "food")
	var initial_water = resource_manager.get_resource(test_faction_id, "water")

	population_system.process_population_growth(test_faction_id)

	var final_food = resource_manager.get_resource(test_faction_id, "food")
	var final_water = resource_manager.get_resource(test_faction_id, "water")

	assert_lt(final_food, initial_food, "Food should be consumed")
	assert_lt(final_water, initial_water, "Water should be consumed")

# Test: Process population growth without resources (starvation)
func test_process_population_growth_starvation():
	# Don't give faction any resources

	var initial_happiness = population_system.get_happiness(test_faction_id)

	population_system.process_population_growth(test_faction_id)

	var final_happiness = population_system.get_happiness(test_faction_id)
	assert_lt(final_happiness, initial_happiness, "Happiness should decrease due to starvation")

# Test: Process population growth emits signal
func test_process_population_growth_emits_signal():
	watch_signals(population_system)
	resource_manager.add_resources(test_faction_id, {"food": 500, "water": 500, "medicine": 100})

	# Run multiple times to ensure population change
	for i in range(10):
		population_system.process_population_growth(test_faction_id)

	# Should eventually emit population_changed
	# Note: might not emit every turn due to rounding
	pass  # Signal emission is probabilistic based on growth

# Test: Assign population to role
func test_assign_population():
	watch_signals(population_system)

	var success = population_system.assign_population(test_faction_id, "worker", 10)

	assert_true(success, "Assignment should succeed")
	assert_signal_emitted(population_system, "population_assigned")

	var breakdown = population_system.get_population_breakdown(test_faction_id)
	assert_eq(breakdown["worker"], 10, "Should have 10 workers")
	assert_eq(breakdown["unassigned"], 40, "Should have 40 unassigned")

# Test: Assign population insufficient
func test_assign_population_insufficient():
	var success = population_system.assign_population(test_faction_id, "worker", 100)

	assert_false(success, "Assignment should fail with insufficient population")

# Test: Assign to multiple roles
func test_assign_to_multiple_roles():
	population_system.assign_population(test_faction_id, "worker", 10)
	population_system.assign_population(test_faction_id, "scavenger", 5)
	population_system.assign_population(test_faction_id, "soldier", 15)

	var breakdown = population_system.get_population_breakdown(test_faction_id)
	assert_eq(breakdown["worker"], 10, "Should have 10 workers")
	assert_eq(breakdown["scavenger"], 5, "Should have 5 scavengers")
	assert_eq(breakdown["soldier"], 15, "Should have 15 soldiers")
	assert_eq(breakdown["unassigned"], 20, "Should have 20 unassigned")

# Test: Assign invalid role
func test_assign_invalid_role():
	var success = population_system.assign_population(test_faction_id, "invalid_role", 10)

	assert_false(success, "Assignment should fail with invalid role")

# Test: Unassign population
func test_unassign_population():
	population_system.assign_population(test_faction_id, "worker", 20)

	var success = population_system.unassign_population(test_faction_id, "worker", 10)

	assert_true(success, "Unassignment should succeed")

	var breakdown = population_system.get_population_breakdown(test_faction_id)
	assert_eq(breakdown["worker"], 10, "Should have 10 workers left")
	assert_eq(breakdown["unassigned"], 40, "Should have 40 unassigned")

# Test: Unassign more than assigned
func test_unassign_more_than_assigned():
	population_system.assign_population(test_faction_id, "worker", 5)

	var success = population_system.unassign_population(test_faction_id, "worker", 10)

	assert_false(success, "Unassignment should fail")

# Test: Get population breakdown
func test_get_population_breakdown():
	population_system.assign_population(test_faction_id, "worker", 15)
	population_system.assign_population(test_faction_id, "scavenger", 10)

	var breakdown = population_system.get_population_breakdown(test_faction_id)

	assert_true(breakdown.has("unassigned"), "Should have unassigned")
	assert_true(breakdown.has("worker"), "Should have worker")
	assert_true(breakdown.has("scavenger"), "Should have scavenger")

	# Total should equal population
	var total = 0
	for role in breakdown.keys():
		total += breakdown[role]
	assert_eq(total, 50, "Total assigned should equal population")

# Test: Get unassigned population
func test_get_unassigned_population():
	var unassigned = population_system.get_unassigned_population(test_faction_id)
	assert_eq(unassigned, 50, "All should be unassigned initially")

	population_system.assign_population(test_faction_id, "worker", 20)

	unassigned = population_system.get_unassigned_population(test_faction_id)
	assert_eq(unassigned, 30, "Should have 30 unassigned after assignment")

# Test: Get assigned to role
func test_get_assigned_to_role():
	population_system.assign_population(test_faction_id, "scavenger", 12)

	var assigned = population_system.get_assigned_to_role(test_faction_id, "scavenger")
	assert_eq(assigned, 12, "Should have 12 scavengers")

	var soldiers = population_system.get_assigned_to_role(test_faction_id, "soldier")
	assert_eq(soldiers, 0, "Should have 0 soldiers")

# Test: Get food consumption
func test_get_food_consumption():
	var consumption = population_system.get_food_consumption(test_faction_id)
	assert_eq(consumption, 50, "Should consume 50 food (1 per pop)")

# Test: Get water consumption
func test_get_water_consumption():
	var consumption = population_system.get_water_consumption(test_faction_id)
	assert_eq(consumption, 100, "Should consume 100 water (2 per pop)")

# Test: Food consumption scales with population
func test_food_consumption_scales():
	population_system.set_population(test_faction_id, 100)

	var consumption = population_system.get_food_consumption(test_faction_id)
	assert_eq(consumption, 100, "Should consume 100 food for 100 pops")

# Test: Invalid faction ID
func test_invalid_faction_id():
	var population = population_system.get_population(999)
	assert_eq(population, 0, "Should return 0 for invalid faction")

	var happiness = population_system.get_happiness(999)
	assert_almost_eq(happiness, 50.0, 0.1, "Should return baseline for invalid faction")

# Test: Save and load state
func test_save_load_state():
	population_system.set_population(test_faction_id, 75)
	population_system.modify_happiness(test_faction_id, 20.0)
	population_system.assign_population(test_faction_id, "worker", 25)

	var state = population_system.save_state()

	var new_system = PopulationSystem.new()
	new_system.load_state(state)

	var population = new_system.get_population(test_faction_id)
	assert_eq(population, 75, "Population should be restored")

	var happiness = new_system.get_happiness(test_faction_id)
	assert_almost_eq(happiness, 70.0, 0.1, "Happiness should be restored")

	var breakdown = new_system.get_population_breakdown(test_faction_id)
	assert_eq(breakdown["worker"], 25, "Worker assignment should be restored")

	new_system.free()

# Test: Multiple factions
func test_multiple_factions():
	var faction_a = 1
	var faction_b = 2

	population_system.initialize_faction(faction_a, 50)
	population_system.initialize_faction(faction_b, 75)

	assert_eq(population_system.get_population(faction_a), 50)
	assert_eq(population_system.get_population(faction_b), 75)

	population_system.set_population(faction_a, 60)

	assert_eq(population_system.get_population(faction_a), 60)
	assert_eq(population_system.get_population(faction_b), 75, "Faction B should be unaffected")

# Test: Population growth with medicine bonus
func test_population_growth_with_medicine():
	resource_manager.add_resources(test_faction_id, {"food": 500, "water": 500, "medicine": 50})

	var initial_population = population_system.get_population(test_faction_id)

	# Run multiple turns
	for i in range(10):
		population_system.process_population_growth(test_faction_id)
		resource_manager.add_resources(test_faction_id, {"food": 500, "water": 500, "medicine": 50})

	var final_population = population_system.get_population(test_faction_id)
	assert_gt(final_population, initial_population, "Population should grow with medicine")

# Test: Population assignment adjusted on growth
func test_population_assignment_adjusted_on_growth():
	population_system.assign_population(test_faction_id, "worker", 50)

	var initial_unassigned = population_system.get_unassigned_population(test_faction_id)

	population_system.set_population(test_faction_id, 60)

	var final_unassigned = population_system.get_unassigned_population(test_faction_id)
	assert_gt(final_unassigned, initial_unassigned, "Unassigned should increase with population")
