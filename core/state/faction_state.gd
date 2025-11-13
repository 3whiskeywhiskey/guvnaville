extends RefCounted
class_name FactionState

## FactionState - State for a single faction
##
## Manages all state information for one faction including resources,
## units, buildings, territory, and diplomatic relations.

# ============================================================================
# PROPERTIES
# ============================================================================

## Unique faction ID (0-8, 0 is typically player)
var faction_id: int = -1

## Faction name
var faction_name: String = ""

## True if this is the human player
var is_player: bool = false

## True if faction is still in the game
var is_alive: bool = true

## Resource stockpiles {resource_type: amount}
var resources: Dictionary = {}

## Culture progression data
var culture: Dictionary = {
	"total_points": 0,
	"points_per_turn": 0,
	"unlocked_nodes": []
}

## IDs of units owned by this faction
var units: Array = []

## IDs of buildings owned by this faction
var buildings: Array = []

## Tile positions controlled by this faction
var controlled_tiles: Array[Vector3i] = []

## Diplomatic relations {faction_id: relation_value}
## -100 (hostile) to +100 (allied)
var diplomacy: Dictionary = {}

## AI personality type (if AI faction)
var ai_personality: String = ""

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(
	p_faction_id: int = -1,
	p_faction_name: String = "",
	p_is_player: bool = false
) -> void:
	faction_id = p_faction_id
	faction_name = p_faction_name
	is_player = p_is_player

	# Initialize default resources
	resources = {
		"scrap": 100,
		"components": 50,
		"ammo": 100,
		"food": 100,
		"medicine": 20,
		"fuel": 50
	}

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize faction state to dictionary
func to_dict() -> Dictionary:
	var tiles_data = []
	for tile_pos in controlled_tiles:
		tiles_data.append({
			"x": tile_pos.x,
			"y": tile_pos.y,
			"z": tile_pos.z
		})

	return {
		"faction_id": faction_id,
		"faction_name": faction_name,
		"is_player": is_player,
		"is_alive": is_alive,
		"resources": resources.duplicate(),
		"culture": culture.duplicate(true),
		"units": units.duplicate(),
		"buildings": buildings.duplicate(),
		"controlled_tiles": tiles_data,
		"diplomacy": diplomacy.duplicate(),
		"ai_personality": ai_personality
	}

## Deserialize faction state from dictionary
func from_dict(data: Dictionary) -> void:
	faction_id = data.get("faction_id", -1)
	faction_name = data.get("faction_name", "")
	is_player = data.get("is_player", false)
	is_alive = data.get("is_alive", true)
	resources = data.get("resources", {}).duplicate()
	culture = data.get("culture", {}).duplicate(true)
	units = data.get("units", []).duplicate()
	buildings = data.get("buildings", []).duplicate()
	diplomacy = data.get("diplomacy", {}).duplicate()
	ai_personality = data.get("ai_personality", "")

	# Convert tile positions
	controlled_tiles.clear()
	var tiles_data = data.get("controlled_tiles", [])
	for tile_data in tiles_data:
		controlled_tiles.append(Vector3i(
			tile_data.get("x", 0),
			tile_data.get("y", 0),
			tile_data.get("z", 0)
		))

# ============================================================================
# RESOURCE MANAGEMENT
# ============================================================================

## Add resources to the faction's stockpile
func add_resource(resource_type: String, amount: int) -> void:
	if not resources.has(resource_type):
		resources[resource_type] = 0
	resources[resource_type] += amount

## Remove resources from the faction's stockpile
## Returns true if sufficient resources were available
func remove_resource(resource_type: String, amount: int) -> bool:
	if not has_resource(resource_type, amount):
		return false
	resources[resource_type] -= amount
	return true

## Check if faction has sufficient resources
func has_resource(resource_type: String, amount: int) -> bool:
	return resources.get(resource_type, 0) >= amount

## Get resource amount
func get_resource(resource_type: String) -> int:
	return resources.get(resource_type, 0)

# ============================================================================
# TERRITORY MANAGEMENT
# ============================================================================

## Add a tile to controlled territory
func add_controlled_tile(position: Vector3i) -> void:
	if not controlled_tiles.has(position):
		controlled_tiles.append(position)

## Remove a tile from controlled territory
func remove_controlled_tile(position: Vector3i) -> void:
	var idx = controlled_tiles.find(position)
	if idx >= 0:
		controlled_tiles.remove_at(idx)

## Check if faction controls a tile
func controls_tile(position: Vector3i) -> bool:
	return controlled_tiles.has(position)

## Get territory size
func get_territory_size() -> int:
	return controlled_tiles.size()

# ============================================================================
# UNIT & BUILDING MANAGEMENT
# ============================================================================

## Add a unit to this faction
func add_unit(unit_id: String) -> void:
	if not units.has(unit_id):
		units.append(unit_id)

## Remove a unit from this faction
func remove_unit(unit_id: String) -> void:
	var idx = units.find(unit_id)
	if idx >= 0:
		units.remove_at(idx)

## Add a building to this faction
func add_building(building_id: String) -> void:
	if not buildings.has(building_id):
		buildings.append(building_id)

## Remove a building from this faction
func remove_building(building_id: String) -> void:
	var idx = buildings.find(building_id)
	if idx >= 0:
		buildings.remove_at(idx)

# ============================================================================
# CULTURE
# ============================================================================

## Add culture points
func add_culture_points(amount: int) -> void:
	culture["total_points"] += amount

## Unlock a culture node
func unlock_culture_node(node_id: String) -> void:
	var nodes = culture.get("unlocked_nodes", [])
	if not nodes.has(node_id):
		nodes.append(node_id)
		culture["unlocked_nodes"] = nodes

## Check if a culture node is unlocked
func has_culture_node(node_id: String) -> bool:
	return culture.get("unlocked_nodes", []).has(node_id)

# ============================================================================
# DIPLOMACY
# ============================================================================

## Set diplomatic relation with another faction
func set_diplomacy(other_faction_id: int, value: int) -> void:
	diplomacy[other_faction_id] = clampi(value, -100, 100)

## Get diplomatic relation with another faction
func get_diplomacy(other_faction_id: int) -> int:
	return diplomacy.get(other_faction_id, 0)

## Modify diplomatic relation
func modify_diplomacy(other_faction_id: int, delta: int) -> void:
	var current = get_diplomacy(other_faction_id)
	set_diplomacy(other_faction_id, current + delta)
