extends RefCounted
class_name WorldState

## WorldState - World and map state
##
## Manages the game map including all tiles, unique locations,
## and fog of war information.

# ============================================================================
# PROPERTIES
# ============================================================================

## Map width in tiles
var map_width: int = 200

## Map height in tiles
var map_height: int = 200

## Map depth (number of layers)
var map_depth: int = 3

## All tiles in the world {Vector3i -> Tile}
var tiles: Dictionary = {}

## Unique location instances
var unique_locations: Array = []

## Fog of war {faction_id -> Array[Vector3i]} (visible tiles per faction)
var fog_of_war: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	pass

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize world state to dictionary
func to_dict() -> Dictionary:
	# Serialize tiles
	var tiles_data = []
	for pos in tiles:
		var tile = tiles[pos]
		tiles_data.append(tile.to_dict())

	# Serialize fog of war
	var fow_data = {}
	for faction_id in fog_of_war:
		var visible_tiles = []
		for pos in fog_of_war[faction_id]:
			visible_tiles.append({
				"x": pos.x,
				"y": pos.y,
				"z": pos.z
			})
		fow_data[str(faction_id)] = visible_tiles

	return {
		"map_width": map_width,
		"map_height": map_height,
		"map_depth": map_depth,
		"tiles": tiles_data,
		"unique_locations": unique_locations.duplicate(true),
		"fog_of_war": fow_data
	}

## Deserialize world state from dictionary
func from_dict(data: Dictionary) -> void:
	map_width = data.get("map_width", 200)
	map_height = data.get("map_height", 200)
	map_depth = data.get("map_depth", 3)
	unique_locations = data.get("unique_locations", []).duplicate(true)

	# Deserialize tiles
	tiles.clear()
	var tiles_data = data.get("tiles", [])
	for tile_data in tiles_data:
		var tile = Tile.new()
		tile.from_dict(tile_data)
		tiles[tile.position] = tile

	# Deserialize fog of war
	fog_of_war.clear()
	var fow_data = data.get("fog_of_war", {})
	for faction_id_str in fow_data:
		var faction_id = int(faction_id_str)
		var visible_tiles: Array[Vector3i] = []
		for pos_data in fow_data[faction_id_str]:
			visible_tiles.append(Vector3i(
				pos_data.get("x", 0),
				pos_data.get("y", 0),
				pos_data.get("z", 0)
			))
		fog_of_war[faction_id] = visible_tiles

# ============================================================================
# TILE MANAGEMENT
# ============================================================================

## Get a tile at the specified position
func get_tile(position: Vector3i) -> Tile:
	return tiles.get(position, null)

## Set a tile at the specified position
func set_tile(position: Vector3i, tile: Tile) -> void:
	tiles[position] = tile

## Check if a position is valid (within map bounds)
func is_valid_position(position: Vector3i) -> bool:
	return (
		position.x >= 0 and position.x < map_width and
		position.y >= 0 and position.y < map_height and
		position.z >= 0 and position.z < map_depth
	)

## Check if a tile exists at the position
func has_tile(position: Vector3i) -> bool:
	return tiles.has(position)

## Remove a tile at the specified position
func remove_tile(position: Vector3i) -> void:
	tiles.erase(position)

## Get all tile positions
func get_all_tile_positions() -> Array:
	return tiles.keys()

## Get tiles in a rectangular area
func get_tiles_in_area(min_pos: Vector3i, max_pos: Vector3i) -> Array:
	var result = []
	for x in range(min_pos.x, max_pos.x + 1):
		for y in range(min_pos.y, max_pos.y + 1):
			for z in range(min_pos.z, max_pos.z + 1):
				var pos = Vector3i(x, y, z)
				if has_tile(pos):
					result.append(get_tile(pos))
	return result

# ============================================================================
# FOG OF WAR
# ============================================================================

## Set visibility for a faction at a position
func set_visibility(faction_id: int, position: Vector3i, visible: bool) -> void:
	if not fog_of_war.has(faction_id):
		fog_of_war[faction_id] = []

	var visible_tiles: Array = fog_of_war[faction_id]

	if visible and not visible_tiles.has(position):
		visible_tiles.append(position)
	elif not visible and visible_tiles.has(position):
		visible_tiles.erase(position)

## Check if a tile is visible to a faction
func is_visible_to(faction_id: int, position: Vector3i) -> bool:
	if not fog_of_war.has(faction_id):
		return false
	return fog_of_war[faction_id].has(position)

## Get all visible tiles for a faction
func get_visible_tiles(faction_id: int) -> Array:
	return fog_of_war.get(faction_id, [])

## Clear fog of war for a faction
func clear_fog_of_war(faction_id: int) -> void:
	fog_of_war[faction_id] = []

# ============================================================================
# UNIQUE LOCATIONS
# ============================================================================

## Add a unique location
func add_unique_location(location_data: Dictionary) -> void:
	unique_locations.append(location_data)

## Get unique location by ID
func get_unique_location(location_id: String) -> Dictionary:
	for location in unique_locations:
		if location.get("id", "") == location_id:
			return location
	return {}

## Check if unique location exists
func has_unique_location(location_id: String) -> bool:
	return not get_unique_location(location_id).is_empty()
