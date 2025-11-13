extends RefCounted
class_name MapData

## Main map grid management class for 200x200x3 tile grid (40,000 tiles)
##
## Manages the entire game map including:
## - 200x200x3 grid storage with O(1) access
## - MapTile ownership tracking
## - Map loading from JSON
## - Spatial query operations
## - Event emission for map changes
##
## @version 1.0
## @author Agent 2 (Map System)

# Preload dependencies for Godot 4.5.1 compatibility
const MapTile = preload("res://systems/map/tile.gd")

# ============================================================================
# CONSTANTS
# ============================================================================

const MAP_WIDTH: int = 200
const MAP_HEIGHT: int = 200
const MAP_DEPTH: int = 3
const TOTAL_TILES: int = MAP_WIDTH * MAP_HEIGHT * MAP_DEPTH  # 120,000 tiles

# ============================================================================
# PROPERTIES
# ============================================================================

## Flat 1D array storing all tiles (optimized for O(1) access)
var _tiles: Array[MapTile] = []

## Cache for tiles by type (invalidated on tile type changes)
var _tile_type_cache: Dictionary = {}

## Cache for tiles by owner (invalidated on ownership changes)
var _owner_cache: Dictionary = {}

## Whether caches need rebuilding
var _cache_dirty: bool = true

## OPTIMIZATION: Track which specific caches are dirty for incremental updates
var _type_cache_dirty: bool = true
var _owner_cache_dirty: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	"""Initializes an empty 200x200x3 grid."""
	_initialize_grid()

func _initialize_grid() -> void:
	"""Creates all tiles in the grid with default values."""
	_tiles.resize(TOTAL_TILES)

	for z in range(MAP_DEPTH):
		for y in range(MAP_HEIGHT):
			for x in range(MAP_WIDTH):
				var pos = Vector3i(x, y, z)
				var tile = MapTile.new(pos)
				var index = _pos_to_index(pos)
				_tiles[index] = tile

	_cache_dirty = true

# ============================================================================
# POSITION CONVERSION
# ============================================================================

func _pos_to_index(position: Vector3i) -> int:
	"""
	Converts 3D position to 1D array index.

	Uses formula: x + (y * WIDTH) + (z * WIDTH * HEIGHT)

	Args:
		position: 3D grid position

	Returns:
		1D array index
	"""
	return position.x + (position.y * MAP_WIDTH) + (position.z * MAP_WIDTH * MAP_HEIGHT)

func _index_to_pos(index: int) -> Vector3i:
	"""
	Converts 1D array index to 3D position.

	Args:
		index: 1D array index

	Returns:
		3D grid position
	"""
	var z = index / (MAP_WIDTH * MAP_HEIGHT)
	var remainder = index % (MAP_WIDTH * MAP_HEIGHT)
	var y = remainder / MAP_WIDTH
	var x = remainder % MAP_WIDTH
	return Vector3i(x, y, z)

# ============================================================================
# VALIDATION
# ============================================================================

func is_position_valid(position: Vector3i) -> bool:
	"""
	Checks if a position is within map bounds.

	Args:
		position: Position to check

	Returns:
		true if position is valid (x: 0-199, y: 0-199, z: 0-2)
	"""
	return (position.x >= 0 and position.x < MAP_WIDTH and
			position.y >= 0 and position.y < MAP_HEIGHT and
			position.z >= 0 and position.z < MAP_DEPTH)

# ============================================================================
# TILE ACCESS
# ============================================================================

func get_tile(position: Vector3i) -> MapTile:
	"""
	Returns the tile at the specified position.

	Performance: O(1), < 1ms

	Args:
		position: Grid coordinates (x: 0-199, y: 0-199, z: 0-2)

	Returns:
		MapTile object at position, or null if out of bounds
	"""
	if not is_position_valid(position):
		push_warning("MapData: Invalid position %s" % position)
		return null

	var index = _pos_to_index(position)
	return _tiles[index]

func get_map_size() -> Vector3i:
	"""
	Returns the dimensions of the map.

	Returns:
		Map size as Vector3i (200, 200, 3)
	"""
	return Vector3i(MAP_WIDTH, MAP_HEIGHT, MAP_DEPTH)

# ============================================================================
# SPATIAL QUERIES
# ============================================================================

func get_tiles_in_radius(center: Vector3i, radius: int, same_level_only: bool = true) -> Array[MapTile]:
	"""
	Returns all tiles within a given radius (Manhattan distance).

	Performance: O(n) where n = tiles in radius, < 10ms for radius 10

	Args:
		center: Center position
		radius: Radius in tiles (Manhattan distance)
		same_level_only: If true, only returns tiles on same Z level as center

	Returns:
		Array of tiles within radius, empty if center out of bounds
	"""
	if not is_position_valid(center):
		push_warning("MapData: Invalid center position %s" % center)
		return []

	var result: Array[MapTile] = []

	# Calculate bounding box
	var min_x = max(0, center.x - radius)
	var max_x = min(MAP_WIDTH - 1, center.x + radius)
	var min_y = max(0, center.y - radius)
	var max_y = min(MAP_HEIGHT - 1, center.y + radius)

	var min_z = center.z if same_level_only else 0
	var max_z = center.z if same_level_only else MAP_DEPTH - 1

	# Iterate through bounding box and check Manhattan distance
	for z in range(min_z, max_z + 1):
		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				var pos = Vector3i(x, y, z)
				var manhattan_dist = abs(pos.x - center.x) + abs(pos.y - center.y)

				if not same_level_only:
					manhattan_dist += abs(pos.z - center.z)

				if manhattan_dist <= radius:
					var tile = get_tile(pos)
					if tile:
						result.append(tile)

	return result

func get_tiles_in_rect(rect: Rect2i, level: int) -> Array[MapTile]:
	"""
	Returns all tiles within a rectangular area at a specific Z level.

	Performance: O(n) where n = tiles in rectangle, < 20ms for 20x20 rectangle

	Args:
		rect: Rectangle defining the area (position and size)
		level: Z level (0=underground, 1=ground, 2=elevated)

	Returns:
		Array of tiles in rectangle, empty if invalid parameters
	"""
	if level < 0 or level >= MAP_DEPTH:
		push_warning("MapData: Invalid level %d" % level)
		return []

	var result: Array[MapTile] = []

	# Calculate clamped bounds
	var min_x = clamp(rect.position.x, 0, MAP_WIDTH - 1)
	var min_y = clamp(rect.position.y, 0, MAP_HEIGHT - 1)
	var max_x = clamp(rect.position.x + rect.size.x, 0, MAP_WIDTH)
	var max_y = clamp(rect.position.y + rect.size.y, 0, MAP_HEIGHT)

	# Collect all tiles in rectangle
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var tile = get_tile(Vector3i(x, y, level))
			if tile:
				result.append(tile)

	return result

func get_neighbors(position: Vector3i, include_diagonal: bool = false) -> Array[MapTile]:
	"""
	Returns adjacent tiles (4-way or 8-way connectivity).

	Performance: O(1), < 1ms

	Args:
		position: Center position
		include_diagonal: If true, includes diagonal neighbors

	Returns:
		Array of adjacent tiles (4 or 8 tiles, fewer at edges)
	"""
	if not is_position_valid(position):
		return []

	var result: Array[MapTile] = []

	# Cardinal directions (4-way)
	var directions = [
		Vector3i(1, 0, 0),   # East
		Vector3i(-1, 0, 0),  # West
		Vector3i(0, 1, 0),   # South
		Vector3i(0, -1, 0),  # North
	]

	# Add diagonal directions if requested (8-way)
	if include_diagonal:
		directions.append_array([
			Vector3i(1, 1, 0),   # Southeast
			Vector3i(1, -1, 0),  # Northeast
			Vector3i(-1, 1, 0),  # Southwest
			Vector3i(-1, -1, 0), # Northwest
		])

	# Get neighbors
	for dir in directions:
		var neighbor_pos = position + dir
		var tile = get_tile(neighbor_pos)
		if tile:
			result.append(tile)

	return result

# ============================================================================
# TILE MODIFICATION
# ============================================================================

func update_tile_owner(position: Vector3i, new_owner_id: int) -> void:
	"""
	Changes the owner of a tile and emits tile_captured event.

	Performance: < 1ms (OPTIMIZED: Incremental cache update instead of full rebuild)

	Args:
		position: Position of tile to update
		new_owner_id: New owner faction ID (-1 for neutral, 0-8 for factions)
	"""
	if not is_position_valid(position):
		push_warning("MapData: Cannot update owner, invalid position %s" % position)
		return

	if new_owner_id < -1 or new_owner_id > 8:
		push_warning("MapData: Invalid owner_id %d (must be -1 to 8)" % new_owner_id)
		return

	var tile = get_tile(position)
	if not tile:
		return

	var old_owner = tile.owner_id
	if old_owner == new_owner_id:
		return  # No change

	# OPTIMIZATION: Incrementally update owner cache instead of invalidating
	_update_owner_cache_incremental(tile, old_owner, new_owner_id)

	tile.owner_id = new_owner_id

	# Emit event (using mock EventBus pattern - will be replaced with real EventBus)
	_emit_tile_captured(position, old_owner, new_owner_id)

func update_tile_scavenge_value(position: Vector3i, new_value: float) -> void:
	"""
	Updates the scavenge value of a tile (0.0 - 100.0).

	Performance: < 1ms

	Args:
		position: Position of tile to update
		new_value: New scavenge value (clamped to 0.0-100.0)
	"""
	if not is_position_valid(position):
		push_warning("MapData: Cannot update scavenge value, invalid position %s" % position)
		return

	var tile = get_tile(position)
	if not tile:
		return

	var old_value = tile.scavenge_value
	tile.scavenge_value = clamp(new_value, 0.0, 100.0)

	# If value decreased, emit scavenged event
	if tile.scavenge_value < old_value:
		var resources_found = {
			"scrap": int((old_value - tile.scavenge_value) * 0.5),
			"components": int((old_value - tile.scavenge_value) * 0.1)
		}
		_emit_tile_scavenged(position, resources_found)

# ============================================================================
# MAP LOADING
# ============================================================================

func load_map(map_file_path: String) -> bool:
	"""
	Loads map data from JSON file and populates the grid.

	Performance: < 500ms for full map load

	Args:
		map_file_path: Absolute or relative path to map JSON file

	Returns:
		true if successful, false if file not found or invalid format
	"""
	# Check if file exists
	if not FileAccess.file_exists(map_file_path):
		push_error("MapData: Map file not found: %s" % map_file_path)
		return false

	# Load and parse JSON
	var file = FileAccess.open(map_file_path, FileAccess.READ)
	if not file:
		push_error("MapData: Failed to open map file: %s" % map_file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("MapData: Failed to parse JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return false

	var data = json.data

	# Validate map data
	if not _validate_map_data(data):
		return false

	# Load tiles from data
	if data.has("tiles") and data["tiles"] is Array:
		for tile_data in data["tiles"]:
			var tile = MapTile.from_dict(tile_data)
			if tile and is_position_valid(tile.position):
				var index = _pos_to_index(tile.position)
				_tiles[index] = tile

	_cache_dirty = true

	# Emit map loaded event
	_emit_map_loaded(get_map_size())

	return true

func _validate_map_data(data: Dictionary) -> bool:
	"""Validates loaded map data structure."""
	if not data.has("version"):
		push_error("MapData: Map data missing 'version' field")
		return false

	if not data.has("size"):
		push_error("MapData: Map data missing 'size' field")
		return false

	var size = data["size"]
	if not (size.get("x") == MAP_WIDTH and size.get("y") == MAP_HEIGHT and size.get("z") == MAP_DEPTH):
		push_error("MapData: Invalid map dimensions. Expected 200x200x3, got %dx%dx%d" % [
			size.get("x", 0), size.get("y", 0), size.get("z", 0)
		])
		return false

	return true

# ============================================================================
# CACHE MANAGEMENT
# ============================================================================

func _invalidate_cache() -> void:
	"""Invalidates all caches."""
	_cache_dirty = true
	_type_cache_dirty = true
	_owner_cache_dirty = true
	_tile_type_cache.clear()
	_owner_cache.clear()

func _invalidate_owner_cache() -> void:
	"""Invalidates only the owner cache."""
	_owner_cache_dirty = true
	_owner_cache.clear()

func _invalidate_type_cache() -> void:
	"""Invalidates only the type cache."""
	_type_cache_dirty = true
	_tile_type_cache.clear()

func _rebuild_cache_if_needed() -> void:
	"""Rebuilds caches if they're marked dirty (OPTIMIZED: Only rebuilds dirty caches)."""
	# OPTIMIZATION: Only rebuild specific caches that are dirty
	if _type_cache_dirty:
		_rebuild_type_cache()

	if _owner_cache_dirty:
		_rebuild_owner_cache()

	_cache_dirty = false

func _rebuild_type_cache() -> void:
	"""Rebuilds only the type cache."""
	_tile_type_cache.clear()

	for tile in _tiles:
		if not _tile_type_cache.has(tile.tile_type):
			_tile_type_cache[tile.tile_type] = []
		_tile_type_cache[tile.tile_type].append(tile)

	_type_cache_dirty = false

func _rebuild_owner_cache() -> void:
	"""Rebuilds only the owner cache."""
	_owner_cache.clear()

	for tile in _tiles:
		if not _owner_cache.has(tile.owner_id):
			_owner_cache[tile.owner_id] = []
		_owner_cache[tile.owner_id].append(tile)

	_owner_cache_dirty = false

## OPTIMIZATION: Incrementally update owner cache without full rebuild
func _update_owner_cache_incremental(tile: MapTile, old_owner: int, new_owner: int) -> void:
	"""
	Updates owner cache incrementally for a single tile change.

	This avoids scanning all 120,000 tiles for a single ownership change.

	Args:
		tile: The tile that changed ownership
		old_owner: Previous owner ID
		new_owner: New owner ID
	"""
	# Skip if cache isn't built yet (will be built on first query)
	if _owner_cache_dirty or _owner_cache.is_empty():
		return

	# Remove from old owner's list
	if _owner_cache.has(old_owner):
		var old_list = _owner_cache[old_owner]
		var index = old_list.find(tile)
		if index >= 0:
			old_list.remove_at(index)

	# Add to new owner's list
	if not _owner_cache.has(new_owner):
		_owner_cache[new_owner] = []
	_owner_cache[new_owner].append(tile)

# ============================================================================
# EVENT EMISSION (Mock - will be replaced with EventBus)
# ============================================================================

func _emit_map_loaded(map_size: Vector3i) -> void:
	"""Emits map_loaded event (mock for testing)."""
	# In production, this would be: EventBus.map_loaded.emit(map_size)
	pass

func _emit_tile_captured(position: Vector3i, old_owner: int, new_owner: int) -> void:
	"""Emits tile_captured event (mock for testing)."""
	# In production, this would be: EventBus.tile_captured.emit(position, old_owner, new_owner)
	pass

func _emit_tile_scavenged(position: Vector3i, resources_found: Dictionary) -> void:
	"""Emits tile_scavenged event (mock for testing)."""
	# In production, this would be: EventBus.tile_scavenged.emit(position, resources_found)
	pass

# ============================================================================
# DEBUGGING
# ============================================================================

func get_tile_count() -> int:
	"""Returns total number of tiles in the map."""
	return _tiles.size()

func get_statistics() -> Dictionary:
	"""Returns map statistics for debugging."""
	_rebuild_cache_if_needed()

	var stats = {
		"total_tiles": _tiles.size(),
		"tiles_by_type": {},
		"tiles_by_owner": {},
		"total_scavenge_value": 0.0,
		"passable_tiles": 0,
		"water_tiles": 0,
	}

	for tile in _tiles:
		# Count by type
		var type_name = MapTile.MapTileType.keys()[tile.tile_type]
		if not stats["tiles_by_type"].has(type_name):
			stats["tiles_by_type"][type_name] = 0
		stats["tiles_by_type"][type_name] += 1

		# Count by owner
		if not stats["tiles_by_owner"].has(tile.owner_id):
			stats["tiles_by_owner"][tile.owner_id] = 0
		stats["tiles_by_owner"][tile.owner_id] += 1

		# Aggregate stats
		stats["total_scavenge_value"] += tile.scavenge_value
		if tile.is_passable:
			stats["passable_tiles"] += 1
		if tile.is_water:
			stats["water_tiles"] += 1

	return stats
