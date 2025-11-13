extends RefCounted
class_name Tile

## Tile - Data class for map tiles
##
## Represents a single tile on the game map with its type, terrain,
## ownership, and state information.

# ============================================================================
# PROPERTIES
# ============================================================================

## Position on the map
var position: Vector3i = Vector3i.ZERO

## Type of tile (e.g., "Residential", "Commercial", "Industrial")
var tile_type: String = ""

## Terrain type (e.g., "Rubble", "Building", "Street")
var terrain_type: String = ""

## Owning faction ID (-1 for unclaimed)
var owner: int = -1

## Building ID on this tile ("" for none)
var building: String = ""

## Unit IDs on this tile
var units: Array[String] = []

## Remaining scavenge value (0-100)
var scavenge_value: int = 50

## Visibility per faction {faction_id: visibility_level}
var visibility: Dictionary = {}

## Active hazards on this tile
var hazards: Array = []

## Movement cost to enter this tile
var movement_cost: int = 1

## Defense bonus provided by this terrain
var defense_bonus: int = 0

## Elevation level (0=underground, 1=ground, 2=elevated)
var elevation: int = 1

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(p_position: Vector3i = Vector3i.ZERO) -> void:
	position = p_position

func setup(p_tile_type: String, p_terrain_type: String) -> Tile:
	tile_type = p_tile_type
	terrain_type = p_terrain_type
	return self

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize tile to dictionary
func to_dict() -> Dictionary:
	return {
		"position": {
			"x": position.x,
			"y": position.y,
			"z": position.z
		},
		"tile_type": tile_type,
		"terrain_type": terrain_type,
		"owner": owner,
		"building": building,
		"units": units.duplicate(),
		"scavenge_value": scavenge_value,
		"visibility": visibility.duplicate(),
		"hazards": hazards.duplicate(),
		"movement_cost": movement_cost,
		"defense_bonus": defense_bonus,
		"elevation": elevation
	}

## Deserialize tile from dictionary
func from_dict(data: Dictionary) -> void:
	var pos_data = data.get("position", {})
	position = Vector3i(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)

	tile_type = data.get("tile_type", "")
	terrain_type = data.get("terrain_type", "")
	owner = data.get("owner", -1)
	building = data.get("building", "")
	units = Array(data.get("units", []), TYPE_STRING, "", null)
	scavenge_value = data.get("scavenge_value", 50)
	visibility = data.get("visibility", {}).duplicate()
	hazards = data.get("hazards", []).duplicate()
	movement_cost = data.get("movement_cost", 1)
	defense_bonus = data.get("defense_bonus", 0)
	elevation = data.get("elevation", 1)

# ============================================================================
# TILE MANAGEMENT
# ============================================================================

## Add a unit to this tile
func add_unit(unit_id: String) -> void:
	if not units.has(unit_id):
		units.append(unit_id)

## Remove a unit from this tile
func remove_unit(unit_id: String) -> void:
	var idx = units.find(unit_id)
	if idx >= 0:
		units.remove_at(idx)

## Change tile ownership
func set_owner(faction_id: int) -> void:
	owner = faction_id

## Deplete scavenge resources
func deplete_scavenge(amount: int) -> int:
	var actual_amount = min(amount, scavenge_value)
	scavenge_value -= actual_amount
	return actual_amount

## Check if tile is passable
func is_passable() -> bool:
	# Tiles with very high movement cost are impassable
	return movement_cost < 100

## Check if tile is visible to a faction
func is_visible_to(faction_id: int) -> bool:
	return visibility.get(faction_id, 0) > 0

## Get visibility level for a faction
func get_visibility_level(faction_id: int) -> int:
	return visibility.get(faction_id, 0)

## Set visibility level for a faction
func set_visibility(faction_id: int, level: int) -> void:
	visibility[faction_id] = level

## Check if tile is occupied by units
func is_occupied() -> bool:
	return units.size() > 0

## Check if tile has a building
func has_building() -> bool:
	return building != ""
