extends Node
class_name ResourceManager

## Resource Manager - handles resource tracking, income, and consumption
## Part of the Economy System (Workstream 2.5)
##
## This class manages:
## - Resource stockpiles per faction
## - Resource income/consumption tracking
## - Resource addition/consumption operations
## - Shortage detection and warnings

# Signals
signal resource_changed(faction_id: int, resource_type: String, amount_delta: int, new_total: int)
signal resource_shortage(faction_id: int, resource_type: String, deficit: int)

# Resource types supported
const RESOURCE_TYPES = ["scrap", "food", "medicine", "fuel", "electronics", "materials", "water", "ammunition"]

# Data storage: faction_id -> {resource_type: amount}
var _faction_stockpiles: Dictionary = {}
var _faction_income: Dictionary = {}

## Initializes the resource manager
func _ready():
	pass

## Initializes a faction's resource stockpile
## This should be called when a faction is created
func initialize_faction(faction_id: int) -> void:
	if faction_id < 0:
		push_error("ResourceManager: Invalid faction_id %d" % faction_id)
		return

	_faction_stockpiles[faction_id] = _create_empty_stockpile()
	_faction_income[faction_id] = _create_empty_stockpile()

## Creates an empty stockpile dictionary
func _create_empty_stockpile() -> Dictionary:
	var stockpile = {}
	for resource_type in RESOURCE_TYPES:
		stockpile[resource_type] = 0
	return stockpile

## Adds resources to a faction's stockpile
## Parameters:
##   faction_id: int - The faction receiving resources
##   resources: Dictionary - Resource types and amounts: {"scrap": 50, "food": 20}
## Emits: resource_changed for each resource type added
func add_resources(faction_id: int, resources: Dictionary) -> void:
	if not _is_valid_faction(faction_id):
		push_error("ResourceManager: Invalid faction_id %d" % faction_id)
		return

	for resource_type in resources.keys():
		if not _is_valid_resource_type(resource_type):
			push_warning("ResourceManager: Invalid resource type '%s'" % resource_type)
			continue

		var amount = int(resources[resource_type])
		if amount < 0:
			amount = 0

		if amount > 0:
			var old_amount = _faction_stockpiles[faction_id][resource_type]
			_faction_stockpiles[faction_id][resource_type] += amount
			var new_amount = _faction_stockpiles[faction_id][resource_type]
			resource_changed.emit(faction_id, resource_type, amount, new_amount)

## Attempts to consume resources from a faction's stockpile
## This is an atomic operation - either all resources are consumed or none are
## Parameters:
##   faction_id: int - The faction consuming resources
##   resources: Dictionary - Resource types and amounts: {"scrap": 30, "food": 15}
## Returns: bool - true if all resources were available and consumed, false otherwise
## Emits: resource_changed if successful, resource_shortage if insufficient
func consume_resources(faction_id: int, resources: Dictionary) -> bool:
	if not _is_valid_faction(faction_id):
		push_error("ResourceManager: Invalid faction_id %d" % faction_id)
		return false

	# First pass: check if all resources are available
	for resource_type in resources.keys():
		if not _is_valid_resource_type(resource_type):
			push_warning("ResourceManager: Invalid resource type '%s'" % resource_type)
			return false

		var amount = int(resources[resource_type])
		var available = _faction_stockpiles[faction_id][resource_type]

		if available < amount:
			var deficit = amount - available
			resource_shortage.emit(faction_id, resource_type, deficit)
			return false

	# Second pass: consume all resources (atomic)
	for resource_type in resources.keys():
		var amount = int(resources[resource_type])
		if amount > 0:
			var old_amount = _faction_stockpiles[faction_id][resource_type]
			_faction_stockpiles[faction_id][resource_type] -= amount
			var new_amount = _faction_stockpiles[faction_id][resource_type]
			resource_changed.emit(faction_id, resource_type, -amount, new_amount)

	return true

## Checks if a faction has sufficient resources
## Parameters:
##   faction_id: int - The faction to check
##   resources: Dictionary - Resource requirements
## Returns: bool - true if all resources are available
func has_resources(faction_id: int, resources: Dictionary) -> bool:
	if not _is_valid_faction(faction_id):
		return false

	for resource_type in resources.keys():
		if not _is_valid_resource_type(resource_type):
			return false

		var amount = int(resources[resource_type])
		var available = _faction_stockpiles[faction_id][resource_type]

		if available < amount:
			return false

	return true

## Retrieves the current resource stockpile for a faction
## Parameters:
##   faction_id: int - The faction to query
## Returns: Dictionary - Current resource amounts: {"scrap": 450, "food": 200, ...}
func get_resources(faction_id: int) -> Dictionary:
	if not _is_valid_faction(faction_id):
		push_error("ResourceManager: Invalid faction_id %d" % faction_id)
		return _create_empty_stockpile()

	return _faction_stockpiles[faction_id].duplicate()

## Gets a specific resource amount
## Parameters:
##   faction_id: int - The faction to query
##   resource_type: String - The resource type to query
## Returns: int - Amount of the resource
func get_resource(faction_id: int, resource_type: String) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	if not _is_valid_resource_type(resource_type):
		return 0

	return _faction_stockpiles[faction_id][resource_type]

## Directly sets a faction's resource amount (admin/debug function)
## Parameters:
##   faction_id: int - The faction to modify
##   resource_type: String - Resource type: "scrap", "food", etc.
##   amount: int - New amount
## Emits: resource_changed
func set_resource(faction_id: int, resource_type: String, amount: int) -> void:
	if not _is_valid_faction(faction_id):
		push_error("ResourceManager: Invalid faction_id %d" % faction_id)
		return

	if not _is_valid_resource_type(resource_type):
		push_error("ResourceManager: Invalid resource type '%s'" % resource_type)
		return

	var old_amount = _faction_stockpiles[faction_id][resource_type]
	_faction_stockpiles[faction_id][resource_type] = max(0, amount)
	var new_amount = _faction_stockpiles[faction_id][resource_type]
	var delta = new_amount - old_amount
	resource_changed.emit(faction_id, resource_type, delta, new_amount)

## Sets the per-turn income for a faction (called by other systems)
## Parameters:
##   faction_id: int - The faction
##   resource_type: String - Resource type
##   income: int - Net income per turn (can be negative for consumption)
func set_resource_income(faction_id: int, resource_type: String, income: int) -> void:
	if not _is_valid_faction(faction_id):
		return

	if not _is_valid_resource_type(resource_type):
		return

	_faction_income[faction_id][resource_type] = income

## Calculates the net per-turn income for all resources
## Parameters:
##   faction_id: int - The faction to calculate for
## Returns: Dictionary - Net income per turn: {"scrap": 25, "food": -15, ...}
##                       Negative values indicate net consumption
func get_resource_income(faction_id: int) -> Dictionary:
	if not _is_valid_faction(faction_id):
		return _create_empty_stockpile()

	return _faction_income[faction_id].duplicate()

## Checks if a faction ID is valid (has been initialized)
func _is_valid_faction(faction_id: int) -> bool:
	return _faction_stockpiles.has(faction_id)

## Checks if a resource type is valid
func _is_valid_resource_type(resource_type: String) -> bool:
	return resource_type in RESOURCE_TYPES

## Checks for resource shortages and emits warnings
## This should be called at the end of each turn
## Parameters:
##   faction_id: int - The faction to check
##   warning_threshold: int - Emit warning if resource will run out in this many turns
func check_shortages(faction_id: int, warning_threshold: int = 3) -> Array:
	if not _is_valid_faction(faction_id):
		return []

	var warnings = []
	var stockpile = _faction_stockpiles[faction_id]
	var income = _faction_income[faction_id]

	for resource_type in RESOURCE_TYPES:
		var current = stockpile[resource_type]
		var per_turn = income[resource_type]

		# Check if we're consuming this resource
		if per_turn < 0:
			var turns_remaining = -int(current / float(per_turn)) if per_turn != 0 else 999

			if turns_remaining <= warning_threshold:
				var warning = {
					"resource_type": resource_type,
					"current": current,
					"per_turn": per_turn,
					"turns_remaining": turns_remaining
				}
				warnings.append(warning)

				# Emit shortage warning if critical (< 1 turn)
				if current + per_turn < 0:
					resource_shortage.emit(faction_id, resource_type, abs(current + per_turn))

	return warnings

## Serializes resource manager state to a dictionary
## Returns: Dictionary - Serialized state
func save_state() -> Dictionary:
	return {
		"stockpiles": _faction_stockpiles.duplicate(true),
		"income": _faction_income.duplicate(true)
	}

## Restores resource manager state from a dictionary
## Parameters:
##   state: Dictionary - Previously saved state
func load_state(state: Dictionary) -> void:
	if state.has("stockpiles"):
		_faction_stockpiles = state["stockpiles"].duplicate(true)

	if state.has("income"):
		_faction_income = state["income"].duplicate(true)
