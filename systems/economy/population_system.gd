extends Node
class_name PopulationSystem

## Population System - manages population growth, happiness, and assignment
## Part of the Economy System (Workstream 2.5)
##
## This class manages:
## - Population growth and mortality
## - Happiness calculation and tracking
## - Population assignment to roles
## - Food/water consumption

# Signals
signal population_changed(faction_id: int, old_population: int, new_population: int)
signal happiness_changed(faction_id: int, old_happiness: float, new_happiness: float)
signal population_assigned(faction_id: int, role: String, count: int)

# Population data class
class PopulationData:
	var total_population: int = 0
	var happiness: float = 50.0        # 0.0-100.0
	var growth_rate: float = 0.02      # Base 2% per turn
	var mortality_rate: float = 0.01   # Base 1% per turn
	var food_consumption: int = 0      # Food needed per turn
	var water_consumption: int = 0     # Water needed per turn
	var assigned_workers: Dictionary = {
		"unassigned": 0,
		"worker": 0,
		"scavenger": 0,
		"soldier": 0,
		"specialist": 0
	}

	func _init():
		pass

	func get_unassigned() -> int:
		return assigned_workers.get("unassigned", 0)

	func to_dict() -> Dictionary:
		return {
			"total_population": total_population,
			"happiness": happiness,
			"growth_rate": growth_rate,
			"mortality_rate": mortality_rate,
			"food_consumption": food_consumption,
			"water_consumption": water_consumption,
			"assigned_workers": assigned_workers.duplicate()
		}

	static func from_dict(data: Dictionary) -> PopulationData:
		var pop_data = PopulationData.new()
		pop_data.total_population = data.get("total_population", 0)
		pop_data.happiness = data.get("happiness", 50.0)
		pop_data.growth_rate = data.get("growth_rate", 0.02)
		pop_data.mortality_rate = data.get("mortality_rate", 0.01)
		pop_data.food_consumption = data.get("food_consumption", 0)
		pop_data.water_consumption = data.get("water_consumption", 0)
		pop_data.assigned_workers = data.get("assigned_workers", {
			"unassigned": 0,
			"worker": 0,
			"scavenger": 0,
			"soldier": 0,
			"specialist": 0
		})
		return pop_data

# Constants
const BASE_GROWTH_RATE = 0.02
const BASE_MORTALITY_RATE = 0.01
const FOOD_PER_POP = 1
const WATER_PER_POP = 2
const HAPPINESS_THRESHOLD_SIGNIFICANT_CHANGE = 5.0

# Data storage
var _faction_populations: Dictionary = {}  # faction_id -> PopulationData
var _resource_manager: ResourceManager = null

## Sets the resource manager reference
func set_resource_manager(manager: ResourceManager) -> void:
	_resource_manager = manager

## Initializes a faction's population data
func initialize_faction(faction_id: int, initial_population: int = 50) -> void:
	if faction_id < 0:
		push_error("PopulationSystem: Invalid faction_id %d" % faction_id)
		return

	var pop_data = PopulationData.new()
	pop_data.total_population = initial_population
	pop_data.assigned_workers["unassigned"] = initial_population
	pop_data.food_consumption = initial_population * FOOD_PER_POP
	pop_data.water_consumption = initial_population * WATER_PER_POP
	pop_data.happiness = 50.0

	_faction_populations[faction_id] = pop_data

## Processes population growth for a faction
## This should be called once per turn
## Parameters:
##   faction_id: int - The faction whose population to process
## Emits: population_changed if population changes
func process_population_growth(faction_id: int) -> void:
	if not _is_valid_faction(faction_id):
		push_error("PopulationSystem: Invalid faction_id %d" % faction_id)
		return

	var pop_data = _faction_populations[faction_id]
	var old_population = pop_data.total_population

	# Calculate actual growth rate based on conditions
	var actual_growth_rate = _calculate_growth_rate(faction_id)
	var actual_mortality_rate = _calculate_mortality_rate(faction_id)

	# Apply growth and mortality
	var net_rate = actual_growth_rate - actual_mortality_rate
	var population_change = int(pop_data.total_population * net_rate)

	# Apply change
	pop_data.total_population = max(1, pop_data.total_population + population_change)

	# Update consumption
	pop_data.food_consumption = pop_data.total_population * FOOD_PER_POP
	pop_data.water_consumption = pop_data.total_population * WATER_PER_POP

	# Consume food and water
	if _resource_manager != null:
		var consumption = {
			"food": pop_data.food_consumption,
			"water": pop_data.water_consumption
		}

		if not _resource_manager.consume_resources(faction_id, consumption):
			# Starvation/dehydration - increase mortality
			pop_data.mortality_rate = min(0.20, pop_data.mortality_rate + 0.05)
			pop_data.happiness = max(0.0, pop_data.happiness - 20.0)

	# Emit signal if population changed significantly
	if abs(pop_data.total_population - old_population) >= 1:
		population_changed.emit(faction_id, old_population, pop_data.total_population)

		# Adjust unassigned population
		var delta = pop_data.total_population - old_population
		pop_data.assigned_workers["unassigned"] = max(0, pop_data.assigned_workers["unassigned"] + delta)

## Calculates the actual growth rate based on conditions
func _calculate_growth_rate(faction_id: int) -> float:
	var pop_data = _faction_populations[faction_id]
	var growth = BASE_GROWTH_RATE

	# Food surplus bonus
	if _resource_manager != null:
		var food = _resource_manager.get_resource(faction_id, "food")
		var food_surplus = food - pop_data.food_consumption
		if food_surplus > 0:
			growth += 0.005 * int(food_surplus / 10.0)

		# Medicine bonus
		var medicine = _resource_manager.get_resource(faction_id, "medicine")
		if medicine >= 5:
			growth += 0.01

	# Happiness bonus (0-2%)
	var happiness_bonus = (pop_data.happiness - 50.0) / 50.0 * 0.02
	growth += happiness_bonus

	return max(0.0, growth)

## Calculates the actual mortality rate based on conditions
func _calculate_mortality_rate(faction_id: int) -> float:
	var pop_data = _faction_populations[faction_id]
	var mortality = pop_data.mortality_rate

	# Medicine reduces mortality
	if _resource_manager != null:
		var medicine = _resource_manager.get_resource(faction_id, "medicine")
		if medicine >= 10:
			mortality = max(0.005, mortality - 0.01)

	return mortality

## Retrieves the current population for a faction
## Parameters:
##   faction_id: int - The faction to query
## Returns: int - Total population
func get_population(faction_id: int) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	return _faction_populations[faction_id].total_population

## Sets the population (admin/debug function)
func set_population(faction_id: int, population: int) -> void:
	if not _is_valid_faction(faction_id):
		return

	var pop_data = _faction_populations[faction_id]
	var old_population = pop_data.total_population
	pop_data.total_population = max(1, population)

	# Adjust unassigned
	var delta = pop_data.total_population - old_population
	pop_data.assigned_workers["unassigned"] = max(0, pop_data.assigned_workers["unassigned"] + delta)

	population_changed.emit(faction_id, old_population, pop_data.total_population)

## Retrieves the current happiness level for a faction
## Parameters:
##   faction_id: int - The faction to query
## Returns: float - Happiness value (0.0 - 100.0)
func get_happiness(faction_id: int) -> float:
	if not _is_valid_faction(faction_id):
		return 50.0

	return _faction_populations[faction_id].happiness

## Recalculates happiness for a faction based on current conditions
## Parameters:
##   faction_id: int - The faction whose happiness to update
## Emits: happiness_changed if happiness changes significantly (>5 points)
func update_happiness(faction_id: int) -> void:
	if not _is_valid_faction(faction_id):
		return

	var pop_data = _faction_populations[faction_id]
	var old_happiness = pop_data.happiness

	# Base happiness starts at 50
	var new_happiness = 50.0

	if _resource_manager != null:
		# Food surplus/shortage
		var food = _resource_manager.get_resource(faction_id, "food")
		var food_surplus = food - pop_data.food_consumption
		if food_surplus > 0:
			new_happiness += 10.0
		elif food < pop_data.food_consumption:
			new_happiness -= 20.0

		# Medicine availability
		var medicine = _resource_manager.get_resource(faction_id, "medicine")
		if medicine >= 10:
			new_happiness += 10.0

		# Water shortage is critical
		var water = _resource_manager.get_resource(faction_id, "water")
		if water < pop_data.water_consumption:
			new_happiness -= 30.0

	# Clamp happiness
	new_happiness = clamp(new_happiness, 0.0, 100.0)
	pop_data.happiness = new_happiness

	# Emit signal if significant change
	if abs(new_happiness - old_happiness) >= HAPPINESS_THRESHOLD_SIGNIFICANT_CHANGE:
		happiness_changed.emit(faction_id, old_happiness, new_happiness)

## Assigns population to a specific role
## Parameters:
##   faction_id: int - The faction whose population to assign
##   role: String - Role type: "worker", "scavenger", "soldier", "specialist"
##   count: int - Number of pops to assign
## Returns: bool - true if successfully assigned, false if insufficient population
## Emits: population_assigned
func assign_population(faction_id: int, role: String, count: int) -> bool:
	if not _is_valid_faction(faction_id):
		return false

	var pop_data = _faction_populations[faction_id]

	# Check if enough unassigned pops
	var unassigned = pop_data.assigned_workers.get("unassigned", 0)
	if unassigned < count:
		return false

	# Validate role
	if not pop_data.assigned_workers.has(role):
		push_error("PopulationSystem: Invalid role '%s'" % role)
		return false

	# Assign
	pop_data.assigned_workers["unassigned"] -= count
	pop_data.assigned_workers[role] = pop_data.assigned_workers.get(role, 0) + count

	population_assigned.emit(faction_id, role, count)

	return true

## Unassigns population from a role
## Parameters:
##   faction_id: int - The faction whose population to unassign
##   role: String - Role type to unassign from
##   count: int - Number of pops to unassign
## Returns: bool - true if successfully unassigned
func unassign_population(faction_id: int, role: String, count: int) -> bool:
	if not _is_valid_faction(faction_id):
		return false

	var pop_data = _faction_populations[faction_id]

	if not pop_data.assigned_workers.has(role):
		return false

	var assigned = pop_data.assigned_workers.get(role, 0)
	if assigned < count:
		return false

	# Unassign
	pop_data.assigned_workers[role] -= count
	pop_data.assigned_workers["unassigned"] += count

	return true

## Retrieves detailed population assignment breakdown
## Parameters:
##   faction_id: int - The faction to query
## Returns: Dictionary - Population by role: {"unassigned": 20, "worker": 30, ...}
func get_population_breakdown(faction_id: int) -> Dictionary:
	if not _is_valid_faction(faction_id):
		return {}

	return _faction_populations[faction_id].assigned_workers.duplicate()

## Gets the number of unassigned population
func get_unassigned_population(faction_id: int) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	return _faction_populations[faction_id].assigned_workers.get("unassigned", 0)

## Gets the population assigned to a specific role
func get_assigned_to_role(faction_id: int, role: String) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	return _faction_populations[faction_id].assigned_workers.get(role, 0)

## Gets food consumption per turn
func get_food_consumption(faction_id: int) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	return _faction_populations[faction_id].food_consumption

## Gets water consumption per turn
func get_water_consumption(faction_id: int) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	return _faction_populations[faction_id].water_consumption

## Modifies happiness directly (for events, buildings, etc.)
func modify_happiness(faction_id: int, delta: float) -> void:
	if not _is_valid_faction(faction_id):
		return

	var pop_data = _faction_populations[faction_id]
	var old_happiness = pop_data.happiness
	pop_data.happiness = clamp(pop_data.happiness + delta, 0.0, 100.0)

	if abs(delta) >= HAPPINESS_THRESHOLD_SIGNIFICANT_CHANGE:
		happiness_changed.emit(faction_id, old_happiness, pop_data.happiness)

## Checks if a faction ID is valid (has been initialized)
func _is_valid_faction(faction_id: int) -> bool:
	return _faction_populations.has(faction_id)

## Serializes population system state
func save_state() -> Dictionary:
	var populations_data = {}
	for faction_id in _faction_populations.keys():
		populations_data[str(faction_id)] = _faction_populations[faction_id].to_dict()

	return {
		"populations": populations_data
	}

## Restores population system state
func load_state(state: Dictionary) -> void:
	_faction_populations.clear()

	if state.has("populations"):
		for faction_id_str in state["populations"].keys():
			var faction_id = int(faction_id_str)
			var pop_data = PopulationData.from_dict(state["populations"][faction_id_str])
			_faction_populations[faction_id] = pop_data
