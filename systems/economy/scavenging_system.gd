extends Node
class_name ScavengingSystem

## Scavenging System - manages scavenging operations on tiles
## Part of the Economy System (Workstream 2.5)
##
## This class manages:
## - Scavenging operations on ruin tiles
## - Tile depletion tracking
## - Scavenge yield calculation
## - Hazard events during scavenging

# Signals
signal scavenging_completed(faction_id: int, position: Vector3i, resources_found: Dictionary, casualties: int)

# Scavenge result class
class ScavengeResult:
	var success: bool = false
	var resources_found: Dictionary = {}
	var tile_depletion: int = 0
	var event_triggered: String = ""
	var casualties: int = 0
	var experience_gained: int = 0

	func to_dict() -> Dictionary:
		return {
			"success": success,
			"resources_found": resources_found,
			"tile_depletion": tile_depletion,
			"event_triggered": event_triggered,
			"casualties": casualties,
			"experience_gained": experience_gained
		}

# Tile types and their scavenge profiles
const TILE_SCAVENGE_PROFILES = {
	"residential": {
		"base_value": 60,
		"yields": [
			{"resources": {"scrap": 5}, "weight": 60},
			{"resources": {"scrap": 10}, "weight": 25},
			{"resources": {"food": 3}, "weight": 10},
			{"resources": {}, "weight": 5, "event": "hazard"}
		],
		"depletion_rate": 5
	},
	"commercial": {
		"base_value": 70,
		"yields": [
			{"resources": {"scrap": 10}, "weight": 40},
			{"resources": {"food": 5}, "weight": 30},
			{"resources": {"electronics": 5}, "weight": 20},
			{"resources": {"scrap": 5, "food": 3}, "weight": 10}
		],
		"depletion_rate": 7
	},
	"industrial": {
		"base_value": 80,
		"yields": [
			{"resources": {"scrap": 20}, "weight": 50},
			{"resources": {"electronics": 10}, "weight": 30},
			{"resources": {"materials": 15}, "weight": 15},
			{"resources": {}, "weight": 5, "event": "hazard"}
		],
		"depletion_rate": 10
	},
	"medical": {
		"base_value": 75,
		"yields": [
			{"resources": {"medicine": 10}, "weight": 40},
			{"resources": {"electronics": 5}, "weight": 30},
			{"resources": {"scrap": 10}, "weight": 20},
			{"resources": {"medicine": 15}, "weight": 10}
		],
		"depletion_rate": 8
	},
	"military": {
		"base_value": 85,
		"yields": [
			{"resources": {"ammunition": 20}, "weight": 50},
			{"resources": {"scrap": 10}, "weight": 25},
			{"resources": {"fuel": 5}, "weight": 15},
			{"resources": {"ammunition": 30, "scrap": 15}, "weight": 10}
		],
		"depletion_rate": 10
	},
	"default": {
		"base_value": 50,
		"yields": [
			{"resources": {"scrap": 3}, "weight": 70},
			{"resources": {"scrap": 5}, "weight": 20},
			{"resources": {}, "weight": 10, "event": "nothing"}
		],
		"depletion_rate": 5
	}
}

# Hazard types
const HAZARDS = [
	{"type": "collapse", "casualties": 1, "weight": 30},
	{"type": "radiation", "casualties": 0, "damage": 20, "weight": 25},
	{"type": "feral_creatures", "casualties": 0, "weight": 25},
	{"type": "booby_trap", "casualties": 1, "weight": 15},
	{"type": "none", "casualties": 0, "weight": 5}
]

# Data storage
var _tile_scavenge_values: Dictionary = {}  # Vector3i -> int (0-100)
var _tile_types: Dictionary = {}  # Vector3i -> String
var _resource_manager: ResourceManager = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	_rng.randomize()

## Sets the resource manager reference
func set_resource_manager(manager: ResourceManager) -> void:
	_resource_manager = manager

## Initializes a tile's scavenge value
## Parameters:
##   position: Vector3i - Tile position
##   tile_type: String - Type of tile (residential, commercial, etc.)
##   initial_value: int - Initial scavenge value (default uses profile base)
func initialize_tile(position: Vector3i, tile_type: String, initial_value: int = -1) -> void:
	_tile_types[position] = tile_type

	if initial_value < 0:
		var profile = TILE_SCAVENGE_PROFILES.get(tile_type, TILE_SCAVENGE_PROFILES["default"])
		initial_value = profile["base_value"]

	_tile_scavenge_values[position] = initial_value

## Performs a scavenging operation on a tile
## Parameters:
##   position: Vector3i - The tile position to scavenge
##   faction_id: int - The faction performing the scavenging
##   num_scavengers: int - Number of scavengers assigned
## Returns: ScavengeResult - Result of the scavenging operation
## Emits: scavenging_completed
func scavenge_tile(position: Vector3i, faction_id: int, num_scavengers: int = 1) -> ScavengeResult:
	var result = ScavengeResult.new()

	# Check if tile exists
	if not _tile_scavenge_values.has(position):
		push_warning("ScavengingSystem: Tile not initialized at %s" % str(position))
		return result

	# Get tile data
	var scavenge_value = _tile_scavenge_values[position]
	var tile_type = _tile_types.get(position, "default")
	var profile = TILE_SCAVENGE_PROFILES.get(tile_type, TILE_SCAVENGE_PROFILES["default"])

	# Check if depleted
	if scavenge_value <= 0:
		result.success = true
		result.resources_found = {"scrap": _rng.randi_range(1, 2)}
		scavenging_completed.emit(faction_id, position, result.resources_found, result.casualties)
		return result

	# Roll for yields
	var yields = profile["yields"]
	var total_weight = 0
	for yield_data in yields:
		total_weight += yield_data["weight"]

	var roll = _rng.randi_range(0, total_weight - 1)
	var cumulative = 0

	for yield_data in yields:
		cumulative += yield_data["weight"]
		if roll < cumulative:
			# This yield was selected
			if yield_data.has("event"):
				# Special event
				if yield_data["event"] == "hazard":
					result.event_triggered = "hazard"
					var hazard = _roll_hazard()
					result.casualties = hazard["casualties"]
				elif yield_data["event"] == "nothing":
					result.event_triggered = "nothing"
			else:
				# Normal resource find
				result.resources_found = yield_data["resources"].duplicate()
				# Scale by number of scavengers (with diminishing returns)
				var scavenger_multiplier = 1.0 + (num_scavengers - 1) * 0.5
				for resource_type in result.resources_found.keys():
					result.resources_found[resource_type] = int(result.resources_found[resource_type] * scavenger_multiplier)

			break

	# Apply depletion
	var depletion = profile["depletion_rate"] * num_scavengers
	_tile_scavenge_values[position] = max(0, scavenge_value - depletion)
	result.tile_depletion = depletion

	# Calculate experience
	if result.casualties == 0:
		result.experience_gained = 5 * num_scavengers

	result.success = true

	# Add resources to faction
	if _resource_manager != null and not result.resources_found.is_empty():
		_resource_manager.add_resources(faction_id, result.resources_found)

	# Emit signal
	scavenging_completed.emit(faction_id, position, result.resources_found, result.casualties)

	return result

## Rolls for a random hazard
func _roll_hazard() -> Dictionary:
	var total_weight = 0
	for hazard in HAZARDS:
		total_weight += hazard["weight"]

	var roll = _rng.randi_range(0, total_weight - 1)
	var cumulative = 0

	for hazard in HAZARDS:
		cumulative += hazard["weight"]
		if roll < cumulative:
			return hazard

	return HAZARDS[0]

## Retrieves the remaining scavenge value of a tile
## Parameters:
##   position: Vector3i - The tile position to query
## Returns: int - Scavenge value (0-100)
func get_tile_scavenge_value(position: Vector3i) -> int:
	if not _tile_scavenge_values.has(position):
		return 0

	return _tile_scavenge_values[position]

## Sets the scavenge value of a tile (admin/debug function)
func set_tile_scavenge_value(position: Vector3i, value: int) -> void:
	if not _tile_scavenge_values.has(position):
		push_warning("ScavengingSystem: Tile not initialized at %s" % str(position))
		return

	_tile_scavenge_values[position] = clamp(value, 0, 100)

## Estimates potential yields from scavenging a tile
## Parameters:
##   position: Vector3i - The tile position to evaluate
##   faction_id: int - The faction evaluating (for culture bonuses)
## Returns: Dictionary - Estimated yields: {"min": {...}, "max": {...}, "average": {...}}
func get_scavenge_estimate(position: Vector3i, faction_id: int = -1) -> Dictionary:
	if not _tile_scavenge_values.has(position):
		return {"min": {}, "max": {}, "average": {}}

	var scavenge_value = _tile_scavenge_values[position]
	if scavenge_value <= 0:
		return {
			"min": {"scrap": 1},
			"max": {"scrap": 2},
			"average": {"scrap": 1.5}
		}

	var tile_type = _tile_types.get(position, "default")
	var profile = TILE_SCAVENGE_PROFILES.get(tile_type, TILE_SCAVENGE_PROFILES["default"])

	# Calculate weighted average yields
	var min_resources = {}
	var max_resources = {}
	var avg_resources = {}

	for yield_data in profile["yields"]:
		if yield_data.has("event"):
			continue

		var weight = float(yield_data["weight"]) / 100.0
		for resource_type in yield_data["resources"].keys():
			var amount = yield_data["resources"][resource_type]

			if not min_resources.has(resource_type):
				min_resources[resource_type] = amount
			else:
				min_resources[resource_type] = min(min_resources[resource_type], amount)

			if not max_resources.has(resource_type):
				max_resources[resource_type] = amount
			else:
				max_resources[resource_type] = max(max_resources[resource_type], amount)

			avg_resources[resource_type] = avg_resources.get(resource_type, 0.0) + amount * weight

	return {
		"min": min_resources,
		"max": max_resources,
		"average": avg_resources
	}

## Gets the tile type
func get_tile_type(position: Vector3i) -> String:
	return _tile_types.get(position, "default")

## Checks if a tile has been completely depleted
func is_tile_depleted(position: Vector3i) -> bool:
	return get_tile_scavenge_value(position) <= 0

## Gets all tiles with remaining scavenge value
func get_available_scavenge_tiles() -> Array:
	var available = []
	for position in _tile_scavenge_values.keys():
		if _tile_scavenge_values[position] > 0:
			available.append(position)
	return available

## Gets the total number of scavengeable tiles
func get_total_tile_count() -> int:
	return _tile_scavenge_values.size()

## Gets the number of depleted tiles
func get_depleted_tile_count() -> int:
	var count = 0
	for position in _tile_scavenge_values.keys():
		if _tile_scavenge_values[position] <= 0:
			count += 1
	return count

## Serializes scavenging system state
func save_state() -> Dictionary:
	var scavenge_values = {}
	for position in _tile_scavenge_values.keys():
		var key = "%d,%d,%d" % [position.x, position.y, position.z]
		scavenge_values[key] = _tile_scavenge_values[position]

	var tile_types = {}
	for position in _tile_types.keys():
		var key = "%d,%d,%d" % [position.x, position.y, position.z]
		tile_types[key] = _tile_types[position]

	return {
		"scavenge_values": scavenge_values,
		"tile_types": tile_types
	}

## Restores scavenging system state
func load_state(state: Dictionary) -> void:
	_tile_scavenge_values.clear()
	_tile_types.clear()

	if state.has("scavenge_values"):
		for key in state["scavenge_values"].keys():
			var parts = key.split(",")
			var position = Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
			_tile_scavenge_values[position] = state["scavenge_values"][key]

	if state.has("tile_types"):
		for key in state["tile_types"].keys():
			var parts = key.split(",")
			var position = Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
			_tile_types[position] = state["tile_types"][key]
