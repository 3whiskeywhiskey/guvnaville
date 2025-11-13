extends Node
class_name ProductionSystem

## Production System - manages production queues for units and buildings
## Part of the Economy System (Workstream 2.5)
##
## This class manages:
## - Production queue per faction
## - Production progress tracking
## - Resource consumption for production
## - Production completion and rush options

# Signals
signal production_queue_updated(faction_id: int)
signal production_completed(faction_id: int, item_type: String, item_id: String)
signal production_cancelled(faction_id: int, item_type: String, item_id: String, refund: Dictionary)

# Production queue item class
class ProductionQueueItem:
	var item_type: String      # "unit", "building", "infrastructure"
	var item_id: String         # Type identifier (e.g., "militia", "factory")
	var total_cost: int         # Total production points required
	var progress: int = 0       # Current production points invested
	var resource_cost: Dictionary  # Resources required: {"scrap": 50, "electronics": 10}
	var resources_paid: bool = false  # Whether resources have been deducted
	var settlement_id: int = -1 # Which settlement is producing this

	func _init(type: String, id: String, cost: int, resources: Dictionary, settlement: int = -1):
		item_type = type
		item_id = id
		total_cost = cost
		resource_cost = resources
		settlement_id = settlement

	func is_complete() -> bool:
		return progress >= total_cost

	func to_dict() -> Dictionary:
		return {
			"item_type": item_type,
			"item_id": item_id,
			"total_cost": total_cost,
			"progress": progress,
			"resource_cost": resource_cost,
			"resources_paid": resources_paid,
			"settlement_id": settlement_id
		}

	static func from_dict(data: Dictionary) -> ProductionQueueItem:
		var item = ProductionQueueItem.new(
			data.get("item_type", ""),
			data.get("item_id", ""),
			data.get("total_cost", 0),
			data.get("resource_cost", {}),
			data.get("settlement_id", -1)
		)
		item.progress = data.get("progress", 0)
		item.resources_paid = data.get("resources_paid", false)
		return item

# Data storage
var _faction_queues: Dictionary = {}  # faction_id -> Array[ProductionQueueItem]
var _production_data: Dictionary = {}  # Loaded from data files
var _resource_manager: ResourceManager = null

## Initializes the production system
func _ready():
	_load_production_data()

## Sets the resource manager reference
func set_resource_manager(manager: ResourceManager) -> void:
	_resource_manager = manager

## Loads production data from JSON files
func _load_production_data() -> void:
	# Load unit data
	var units_data = _load_json("res://data/units/units.json")
	if units_data and units_data.has("units"):
		for unit in units_data["units"]:
			var key = "unit:" + unit["id"]
			_production_data[key] = {
				"type": "unit",
				"id": unit["id"],
				"cost": unit.get("stats", {}).get("cost", {}),
				"production_time": unit.get("production_time", 1)
			}

	# Load building data
	var buildings_data = _load_json("res://data/buildings/buildings.json")
	if buildings_data and buildings_data.has("buildings"):
		for building in buildings_data["buildings"]:
			var key = "building:" + building["id"]
			_production_data[key] = {
				"type": "building",
				"id": building["id"],
				"cost": building.get("cost", {}),
				"production_time": building.get("construction_time", 1)
			}

## Loads a JSON file
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("ProductionSystem: Failed to parse JSON at %s" % path)
		return {}

	return json.data

## Initializes a faction's production queue
func initialize_faction(faction_id: int) -> void:
	if faction_id < 0:
		push_error("ProductionSystem: Invalid faction_id %d" % faction_id)
		return

	_faction_queues[faction_id] = []

## Adds an item to a faction's production queue
## Parameters:
##   faction_id: int - The faction building the item
##   item_type: String - "unit", "building", or "infrastructure"
##   item_id: String - Specific type identifier (e.g., "militia", "factory")
##   settlement_id: int - Optional settlement ID
## Returns: bool - true if successfully added to queue, false if requirements not met
## Emits: production_queue_updated
func add_to_production_queue(faction_id: int, item_type: String, item_id: String, settlement_id: int = -1) -> bool:
	if not _is_valid_faction(faction_id):
		push_error("ProductionSystem: Invalid faction_id %d" % faction_id)
		return false

	# Look up production data
	var key = item_type + ":" + item_id
	if not _production_data.has(key):
		push_error("ProductionSystem: Unknown production item '%s'" % key)
		return false

	var data = _production_data[key]
	var production_time = data.get("production_time", 1)
	var resource_cost = data.get("cost", {})

	# Base production cost (can be modified by bonuses)
	var production_cost = production_time * 100  # 100 PP per turn base

	# Create queue item
	var queue_item = ProductionQueueItem.new(
		item_type,
		item_id,
		production_cost,
		resource_cost,
		settlement_id
	)

	# Add to queue
	_faction_queues[faction_id].append(queue_item)
	production_queue_updated.emit(faction_id)

	return true

## Processes production for a faction for the current turn
## Parameters:
##   faction_id: int - The faction whose production to process
##   production_points: int - Production points available this turn (default 100)
## Returns: Array - Array of completed items: [{"type": "unit", "id": "militia"}, ...]
## Emits: production_completed for each completed item
func process_production(faction_id: int, production_points: int = 100) -> Array:
	if not _is_valid_faction(faction_id):
		return []

	var completed_items = []
	var queue = _faction_queues[faction_id]

	if queue.is_empty():
		return completed_items

	# Process the first item in the queue
	var item = queue[0]

	# Try to pay for resources if not already paid
	if not item.resources_paid and _resource_manager != null:
		if _resource_manager.consume_resources(faction_id, item.resource_cost):
			item.resources_paid = true
		else:
			# Can't afford resources yet, pause production
			return completed_items

	# Apply production points
	item.progress += production_points

	# Check if complete
	if item.is_complete():
		# Remove from queue
		queue.pop_front()

		# Add to completed items
		completed_items.append({
			"type": item.item_type,
			"id": item.item_id,
			"settlement_id": item.settlement_id
		})

		production_completed.emit(faction_id, item.item_type, item.item_id)
		production_queue_updated.emit(faction_id)

	return completed_items

## Retrieves the current production queue for a faction
## Parameters:
##   faction_id: int - The faction to query
## Returns: Array - Array of ProductionQueueItem dictionaries
func get_production_queue(faction_id: int) -> Array:
	if not _is_valid_faction(faction_id):
		return []

	var result = []
	for item in _faction_queues[faction_id]:
		result.append(item.to_dict())
	return result

## Cancels a production queue item and refunds resources
## Parameters:
##   faction_id: int - The faction whose production to cancel
##   queue_index: int - Index in the production queue (0 = first item)
## Returns: bool - true if cancelled successfully, false if index invalid
## Emits: production_cancelled
func cancel_production(faction_id: int, queue_index: int) -> bool:
	if not _is_valid_faction(faction_id):
		return false

	var queue = _faction_queues[faction_id]
	if queue_index < 0 or queue_index >= queue.size():
		return false

	var item = queue[queue_index]

	# Calculate refund (50% of progress)
	var refund = {}

	# Refund 100% of resources if already paid
	if item.resources_paid and _resource_manager != null:
		refund = item.resource_cost.duplicate()
		_resource_manager.add_resources(faction_id, refund)

	# Remove from queue
	queue.remove_at(queue_index)

	production_cancelled.emit(faction_id, item.item_type, item.item_id, refund)
	production_queue_updated.emit(faction_id)

	return true

## Instantly completes the current production item by paying extra resources
## Parameters:
##   faction_id: int - The faction rushing production
##   queue_index: int - Index in the production queue (usually 0 for first item)
## Returns: bool - true if successfully rushed, false if insufficient resources
## Emits: production_completed if successful
func rush_production(faction_id: int, queue_index: int) -> bool:
	if not _is_valid_faction(faction_id):
		return false

	var queue = _faction_queues[faction_id]
	if queue_index < 0 or queue_index >= queue.size():
		return false

	var item = queue[queue_index]

	# Calculate rush cost (2x resource cost)
	var rush_cost = {}
	for resource_type in item.resource_cost.keys():
		rush_cost[resource_type] = item.resource_cost[resource_type] * 2

	# Try to pay rush cost
	if _resource_manager != null:
		if not _resource_manager.consume_resources(faction_id, rush_cost):
			return false

	# Mark as paid and complete
	item.resources_paid = true
	item.progress = item.total_cost

	# Remove from queue and emit completion
	queue.remove_at(queue_index)
	production_completed.emit(faction_id, item.item_type, item.item_id)
	production_queue_updated.emit(faction_id)

	return true

## Gets the current production progress for the first item in queue
## Parameters:
##   faction_id: int - The faction to query
## Returns: float - Progress as a percentage (0.0 - 1.0), or -1.0 if no items in queue
func get_current_production_progress(faction_id: int) -> float:
	if not _is_valid_faction(faction_id):
		return -1.0

	var queue = _faction_queues[faction_id]
	if queue.is_empty():
		return -1.0

	var item = queue[0]
	return float(item.progress) / float(item.total_cost)

## Checks if a faction is currently producing anything
func is_producing(faction_id: int) -> bool:
	if not _is_valid_faction(faction_id):
		return false

	return not _faction_queues[faction_id].is_empty()

## Gets the number of items in a faction's production queue
func get_queue_size(faction_id: int) -> int:
	if not _is_valid_faction(faction_id):
		return 0

	return _faction_queues[faction_id].size()

## Checks if a faction ID is valid (has been initialized)
func _is_valid_faction(faction_id: int) -> bool:
	return _faction_queues.has(faction_id)

## Serializes production system state
func save_state() -> Dictionary:
	var queues_data = {}
	for faction_id in _faction_queues.keys():
		var queue_items = []
		for item in _faction_queues[faction_id]:
			queue_items.append(item.to_dict())
		queues_data[str(faction_id)] = queue_items

	return {
		"queues": queues_data
	}

## Restores production system state
func load_state(state: Dictionary) -> void:
	if not state.has("queues"):
		return

	_faction_queues.clear()
	var queues_data = state["queues"]

	for faction_id_str in queues_data.keys():
		var faction_id = int(faction_id_str)
		_faction_queues[faction_id] = []

		for item_data in queues_data[faction_id_str]:
			var item = ProductionQueueItem.from_dict(item_data)
			_faction_queues[faction_id].append(item)
