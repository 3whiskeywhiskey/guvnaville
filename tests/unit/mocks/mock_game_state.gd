extends RefCounted
class_name MockGameState

## Mock GameState for testing Event System
## Provides a simplified game state structure for testing event triggers and consequences

var current_turn: int = 1
var turn_number: int = 1
var factions: Array = []
var queued_events: Array = []

func _init(num_factions: int = 2):
	# Initialize factions
	for i in range(num_factions):
		var faction = MockFaction.new(i)
		factions.append(faction)

## Get faction by ID
func get_faction(faction_id: int) -> MockFaction:
	if faction_id >= 0 and faction_id < factions.size():
		return factions[faction_id]
	return null

## Advance turn
func advance_turn() -> void:
	current_turn += 1
	turn_number += 1

## Reset to initial state
func reset() -> void:
	current_turn = 1
	turn_number = 1
	queued_events.clear()
	for faction in factions:
		faction.reset()


## ============================================================================
## MockFaction - Simplified faction state for testing
## ============================================================================
class MockFaction extends RefCounted:
	var faction_id: int = 0
	var resources: Dictionary = {}
	var culture_points: int = 0
	var culture_nodes: Array = []
	var units: Array = []
	var buildings: Array = []
	var morale: int = 50
	var reputation: int = 0
	var territory_size: int = 0
	var controlled_tiles: Array = []
	var flags: Dictionary = {}
	var at_war: bool = false
	var has_trade_routes: bool = false
	var settlement_count: int = 1

	func _init(p_faction_id: int = 0):
		faction_id = p_faction_id
		_init_resources()

	func _init_resources() -> void:
		resources = {
			"scrap": 100,
			"food": 50,
			"medicine": 20,
			"fuel": 30,
			"population": 20
		}

	func add_resource(resource_type: String, amount: int) -> void:
		if not resources.has(resource_type):
			resources[resource_type] = 0
		resources[resource_type] += amount

	func remove_resource(resource_type: String, amount: int) -> bool:
		if not resources.has(resource_type) or resources[resource_type] < amount:
			return false
		resources[resource_type] -= amount
		return true

	func has_resource(resource_type: String, amount: int) -> bool:
		return resources.has(resource_type) and resources[resource_type] >= amount

	func unlock_culture_node(node_id: String) -> void:
		if not node_id in culture_nodes:
			culture_nodes.append(node_id)

	func add_unit(unit_type: String) -> void:
		units.append({"type": unit_type, "id": "unit_%d_%d" % [faction_id, units.size()]})

	func add_building(building_type: String) -> void:
		buildings.append({"type": building_type, "id": "building_%d_%d" % [faction_id, buildings.size()]})

	func set_flag(flag_name: String, value: Variant) -> void:
		flags[flag_name] = value

	func get_flag(flag_name: String, default_value: Variant = null) -> Variant:
		return flags.get(flag_name, default_value)

	func reset() -> void:
		_init_resources()
		culture_points = 0
		culture_nodes.clear()
		units.clear()
		buildings.clear()
		morale = 50
		reputation = 0
		territory_size = 0
		controlled_tiles.clear()
		flags.clear()
		at_war = false
		has_trade_routes = false
		settlement_count = 1
