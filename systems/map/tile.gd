extends RefCounted
class_name MapTile

## MapTile data class representing a single tile in the 200x200x3 grid
##
## The Tile class stores all properties of a map tile including:
## - Position and type
## - Ownership and resources
## - Buildings and units
## - Movement and combat properties
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# ENUMS
# ============================================================================

enum TileType {
	RESIDENTIAL,    ## Residential buildings (housing)
	COMMERCIAL,     ## Commercial buildings (shops, offices)
	INDUSTRIAL,     ## Industrial facilities (factories)
	MILITARY,       ## Military installations
	MEDICAL,        ## Medical facilities
	CULTURAL,       ## Cultural sites
	INFRASTRUCTURE, ## Infrastructure (utilities, roads)
	RUINS,          ## Destroyed/ruined buildings
	STREET,         ## Streets and roads
	PARK            ## Parks and green spaces
}

enum TerrainType {
	OPEN_GROUND,    ## Open ground (clear)
	BUILDING,       ## Inside or adjacent to building
	RUBBLE,         ## Rubble and debris
	STREET,         ## Street terrain
	WATER,          ## Water (rivers, flooded areas)
	TUNNEL,         ## Underground tunnel
	ROOFTOP         ## Rooftop (elevated level)
}

# ============================================================================
# PROPERTIES
# ============================================================================

## Grid position (x: 0-199, y: 0-199, z: 0-2)
var position: Vector3i = Vector3i.ZERO

## Type of tile
var tile_type: TileType = TileType.RUINS

## Terrain type
var terrain: TerrainType = TerrainType.RUBBLE

## Owning faction ID (-1 = neutral, 0-8 = faction)
var owner_id: int = -1

## Scavenge value (0.0-100.0), resources available
var scavenge_value: float = 0.0

## Whether tile has a building
var has_building: bool = false

## Building ID if has_building is true
var building_id: String = ""

## Movement cost to enter tile (1-10)
var movement_cost: int = 1

## Cover value for combat (0=none, 1=low, 2=medium, 3=high)
var cover_value: int = 0

## Elevation modifier (affects vision and combat)
var elevation: int = 0

## Whether units can enter this tile
var is_passable: bool = true

## Whether tile is water
var is_water: bool = false

## ID of unique location if applicable
var unique_location_id: String = ""

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(_position: Vector3i = Vector3i.ZERO) -> void:
	position = _position
	# Set default properties based on position
	_initialize_defaults()

func _initialize_defaults() -> void:
	"""Initialize default tile properties based on position."""
	# Underground level (z=0) defaults
	if position.z == 0:
		terrain = TerrainType.TUNNEL
		tile_type = TileType.INFRASTRUCTURE
		cover_value = 2
		movement_cost = 2
	# Ground level (z=1) defaults
	elif position.z == 1:
		terrain = TerrainType.RUBBLE
		tile_type = TileType.RUINS
		cover_value = 1
		movement_cost = 1
	# Elevated level (z=2) defaults
	elif position.z == 2:
		terrain = TerrainType.ROOFTOP
		tile_type = TileType.RUINS
		cover_value = 2
		movement_cost = 2

	# Set scavenge value randomly (can be overridden by map data)
	scavenge_value = randf() * 50.0

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	"""
	Serializes tile to dictionary for saving.

	Returns:
		Dictionary with all tile properties
	"""
	return {
		"position": {
			"x": position.x,
			"y": position.y,
			"z": position.z
		},
		"tile_type": TileType.keys()[tile_type],
		"terrain": TerrainType.keys()[terrain],
		"owner_id": owner_id,
		"scavenge_value": scavenge_value,
		"has_building": has_building,
		"building_id": building_id,
		"movement_cost": movement_cost,
		"cover_value": cover_value,
		"elevation": elevation,
		"is_passable": is_passable,
		"is_water": is_water,
		"unique_location_id": unique_location_id
	}

static func from_dict(data: Dictionary) -> Tile:
	"""
	Deserializes tile from dictionary.

	Args:
		data: Dictionary containing tile data

	Returns:
		Tile instance
	"""
	var tile = Tile.new()

	# Position
	if data.has("position"):
		var pos_data = data["position"]
		tile.position = Vector3i(
			pos_data.get("x", 0),
			pos_data.get("y", 0),
			pos_data.get("z", 0)
		)

	# Tile type
	if data.has("tile_type"):
		var type_name = data["tile_type"]
		if typeof(type_name) == TYPE_STRING:
			tile.tile_type = TileType.get(type_name, TileType.RUINS)
		else:
			tile.tile_type = data["tile_type"]

	# Terrain
	if data.has("terrain"):
		var terrain_name = data["terrain"]
		if typeof(terrain_name) == TYPE_STRING:
			tile.terrain = TerrainType.get(terrain_name, TerrainType.RUBBLE)
		else:
			tile.terrain = data["terrain"]

	# Other properties
	tile.owner_id = data.get("owner_id", -1)
	tile.scavenge_value = data.get("scavenge_value", 0.0)
	tile.has_building = data.get("has_building", false)
	tile.building_id = data.get("building_id", "")
	tile.movement_cost = data.get("movement_cost", 1)
	tile.cover_value = data.get("cover_value", 0)
	tile.elevation = data.get("elevation", 0)
	tile.is_passable = data.get("is_passable", true)
	tile.is_water = data.get("is_water", false)
	tile.unique_location_id = data.get("unique_location_id", "")

	return tile

# ============================================================================
# HELPER METHODS
# ============================================================================

func get_defense_bonus() -> int:
	"""Returns the defense bonus provided by this tile."""
	return cover_value

func can_be_scavenged() -> bool:
	"""Returns true if tile has resources to scavenge."""
	return scavenge_value > 0.0

func deplete_scavenge(amount: float) -> float:
	"""
	Depletes scavenge value by the given amount.

	Args:
		amount: Amount to deplete

	Returns:
		Actual amount depleted (may be less if scavenge_value < amount)
	"""
	var actual_amount = min(amount, scavenge_value)
	scavenge_value = max(0.0, scavenge_value - amount)
	return actual_amount

func is_controlled() -> bool:
	"""Returns true if tile is controlled by any faction."""
	return owner_id >= 0

func is_neutral() -> bool:
	"""Returns true if tile is neutral (not controlled)."""
	return owner_id == -1

func get_movement_penalty() -> float:
	"""Returns movement penalty multiplier (1.0 = normal, 2.0 = double cost)."""
	return movement_cost / 1.0

func is_valid_position() -> bool:
	"""Checks if the tile's position is within valid map bounds."""
	return (position.x >= 0 and position.x < 200 and
			position.y >= 0 and position.y < 200 and
			position.z >= 0 and position.z < 3)

func _to_string() -> String:
	"""Returns string representation of tile for debugging."""
	return "Tile(%s, type=%s, terrain=%s, owner=%d)" % [
		position,
		TileType.keys()[tile_type],
		TerrainType.keys()[terrain],
		owner_id
	]
