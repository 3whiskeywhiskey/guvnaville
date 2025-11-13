extends RefCounted
class_name SpatialQuery

## Provides optimized spatial query operations on map data
##
## Provides efficient queries with caching:
## - Get tiles by type (with caching)
## - Get tiles by owner (with caching)
## - Get border tiles (ownership boundaries)
## - Find path (stub for MVP - full A* implementation post-MVP)
##
## Caching strategy:
## - Caches are built on first query
## - Caches are invalidated when relevant map changes occur
## - Cache hit provides O(1) access instead of O(n) scan
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# PROPERTIES
# ============================================================================

## Reference to the MapData instance
var _map_data: MapData = null

## Cache for tiles by type (Dictionary: TileType -> Array[Tile])
var _tile_type_cache: Dictionary = {}

## Cache for tiles by owner (Dictionary: owner_id -> Array[Tile])
var _owner_cache: Dictionary = {}

## Cache for border tiles (Dictionary: owner_id -> Array[Tile])
var _border_cache: Dictionary = {}

## Whether caches are dirty and need rebuilding
var _cache_dirty: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(map_data: MapData) -> void:
	"""
	Initializes spatial query system with a map data instance.

	Args:
		map_data: MapData instance to query
	"""
	_map_data = map_data
	_cache_dirty = true

# ============================================================================
# PATHFINDING (STUB)
# ============================================================================

func find_path(start: Vector3i, goal: Vector3i, movement_type: int = 0) -> Array[Vector3i]:
	"""
	STUB FOR MVP - Returns empty array. Full pathfinding implementation post-MVP.

	For MVP, units will use simple direct movement. A* pathfinding will be
	implemented in Phase 4 or post-MVP.

	Performance: < 1ms (stub), < 100ms for long paths (future implementation)

	Args:
		start: Starting position
		goal: Goal position
		movement_type: Movement type (0=ground, 1=flying, etc.)

	Returns:
		Empty array for MVP. Will return path positions in post-MVP.
	"""
	# MVP stub - return empty array
	# Future implementation will use A* algorithm with:
	# - Movement cost consideration
	# - Terrain passability checks
	# - Movement type restrictions
	# - Line of sight considerations
	return []

# ============================================================================
# TILE TYPE QUERIES
# ============================================================================

func get_tiles_by_type(tile_type: int, level: int = -1) -> Array[Tile]:
	"""
	Returns all tiles of a specific type, optionally filtered by level.

	Results are cached. Cache invalidates on tile type changes.

	Performance: O(n) where n = total tiles on first call, O(1) with cache

	Args:
		tile_type: Tile type enum value (see Tile.TileType)
		level: Z level filter (-1 = all levels, 0-2 = specific level)

	Returns:
		Array of all matching tiles
	"""
	if not _map_data:
		push_warning("SpatialQuery: No map data available")
		return []

	# Rebuild cache if needed
	if _cache_dirty:
		_rebuild_type_cache()

	# Get tiles from cache
	var cache_key = tile_type
	var tiles: Array[Tile] = []

	if _tile_type_cache.has(cache_key):
		tiles = _tile_type_cache[cache_key].duplicate()

	# Filter by level if requested
	if level >= 0 and level < 3:
		tiles = tiles.filter(func(tile): return tile.position.z == level)

	return tiles

func _rebuild_type_cache() -> void:
	"""Rebuilds the tile type cache by scanning all tiles."""
	_tile_type_cache.clear()

	var map_size = _map_data.get_map_size()
	for z in range(map_size.z):
		for y in range(map_size.y):
			for x in range(map_size.x):
				var pos = Vector3i(x, y, z)
				var tile = _map_data.get_tile(pos)
				if tile:
					if not _tile_type_cache.has(tile.tile_type):
						_tile_type_cache[tile.tile_type] = []
					_tile_type_cache[tile.tile_type].append(tile)

# ============================================================================
# OWNERSHIP QUERIES
# ============================================================================

func get_tiles_by_owner(owner_id: int, level: int = -1) -> Array[Tile]:
	"""
	Returns all tiles owned by a faction.

	Results are cached. Cache invalidates on ownership changes.

	Performance: O(n) where n = total tiles on first call, O(1) with cache

	Args:
		owner_id: Owner faction ID (-1 for neutral, 0-8 for factions)
		level: Z level filter (-1 = all levels, 0-2 = specific level)

	Returns:
		Array of all tiles owned by faction
	"""
	if not _map_data:
		push_warning("SpatialQuery: No map data available")
		return []

	# Rebuild cache if needed
	if _cache_dirty:
		_rebuild_owner_cache()

	# Get tiles from cache
	var tiles: Array[Tile] = []

	if _owner_cache.has(owner_id):
		tiles = _owner_cache[owner_id].duplicate()

	# Filter by level if requested
	if level >= 0 and level < 3:
		tiles = tiles.filter(func(tile): return tile.position.z == level)

	return tiles

func _rebuild_owner_cache() -> void:
	"""Rebuilds the owner cache by scanning all tiles."""
	_owner_cache.clear()

	var map_size = _map_data.get_map_size()
	for z in range(map_size.z):
		for y in range(map_size.y):
			for x in range(map_size.x):
				var pos = Vector3i(x, y, z)
				var tile = _map_data.get_tile(pos)
				if tile:
					if not _owner_cache.has(tile.owner_id):
						_owner_cache[tile.owner_id] = []
					_owner_cache[tile.owner_id].append(tile)

func get_border_tiles(owner_id: int) -> Array[Tile]:
	"""
	Returns all tiles owned by a faction that are adjacent to non-owned tiles (border tiles).

	Performance: O(n) where n = owned tiles, < 150ms

	Args:
		owner_id: Owner faction ID

	Returns:
		Array of all border tiles
	"""
	if not _map_data:
		push_warning("SpatialQuery: No map data available")
		return []

	# Rebuild cache if needed
	if _cache_dirty:
		_rebuild_owner_cache()
		_rebuild_border_cache()

	# Return from cache if available
	if _border_cache.has(owner_id):
		return _border_cache[owner_id].duplicate()

	return []

func _rebuild_border_cache() -> void:
	"""Rebuilds the border tile cache."""
	_border_cache.clear()

	# For each faction's tiles, check if they're on the border
	for owner_id in _owner_cache:
		var border_tiles: Array[Tile] = []
		var owned_tiles = _owner_cache[owner_id]

		for tile in owned_tiles:
			# Check if this tile is adjacent to a non-owned tile
			if _is_border_tile(tile, owner_id):
				border_tiles.append(tile)

		_border_cache[owner_id] = border_tiles

func _is_border_tile(tile: Tile, owner_id: int) -> bool:
	"""
	Checks if a tile is a border tile (adjacent to non-owned tiles).

	Args:
		tile: Tile to check
		owner_id: Expected owner ID

	Returns:
		true if tile is on the border
	"""
	if not _map_data:
		return false

	# Get neighbors (4-way connectivity)
	var neighbors = _map_data.get_neighbors(tile.position, false)

	# If any neighbor has a different owner, this is a border tile
	for neighbor in neighbors:
		if neighbor.owner_id != owner_id:
			return true

	return false

# ============================================================================
# CACHE MANAGEMENT
# ============================================================================

func invalidate_cache() -> void:
	"""Invalidates all caches, forcing rebuild on next query."""
	_cache_dirty = true
	_tile_type_cache.clear()
	_owner_cache.clear()
	_border_cache.clear()

func invalidate_type_cache() -> void:
	"""Invalidates only the type cache."""
	_tile_type_cache.clear()

func invalidate_owner_cache() -> void:
	"""Invalidates owner and border caches (border depends on owner)."""
	_owner_cache.clear()
	_border_cache.clear()

func rebuild_caches() -> void:
	"""Forces immediate rebuild of all caches."""
	_rebuild_type_cache()
	_rebuild_owner_cache()
	_rebuild_border_cache()
	_cache_dirty = false

# ============================================================================
# ADVANCED QUERIES
# ============================================================================

func get_tiles_in_area(center: Vector3i, radius: int, filter_func: Callable = Callable()) -> Array[Tile]:
	"""
	Returns tiles in an area that match an optional filter function.

	Args:
		center: Center position
		radius: Radius in tiles
		filter_func: Optional filter function (tile -> bool)

	Returns:
		Array of matching tiles
	"""
	if not _map_data:
		return []

	var tiles = _map_data.get_tiles_in_radius(center, radius, true)

	if filter_func.is_valid():
		tiles = tiles.filter(filter_func)

	return tiles

func get_passable_tiles_in_area(center: Vector3i, radius: int) -> Array[Tile]:
	"""
	Returns all passable tiles in an area.

	Args:
		center: Center position
		radius: Radius in tiles

	Returns:
		Array of passable tiles
	"""
	return get_tiles_in_area(center, radius, func(tile): return tile.is_passable)

func get_scavenge_tiles_in_area(center: Vector3i, radius: int, min_value: float = 0.0) -> Array[Tile]:
	"""
	Returns all tiles with scavenge value in an area.

	Args:
		center: Center position
		radius: Radius in tiles
		min_value: Minimum scavenge value (default: 0.0)

	Returns:
		Array of scavengeable tiles
	"""
	return get_tiles_in_area(center, radius, func(tile): return tile.scavenge_value >= min_value)

func get_controlled_tiles_in_area(center: Vector3i, radius: int, owner_id: int) -> Array[Tile]:
	"""
	Returns all tiles controlled by a specific faction in an area.

	Args:
		center: Center position
		radius: Radius in tiles
		owner_id: Owner faction ID

	Returns:
		Array of controlled tiles
	"""
	return get_tiles_in_area(center, radius, func(tile): return tile.owner_id == owner_id)

# ============================================================================
# STATISTICAL QUERIES
# ============================================================================

func count_tiles_by_type(tile_type: int, level: int = -1) -> int:
	"""
	Returns count of tiles of a specific type.

	Args:
		tile_type: Tile type enum value
		level: Z level filter (-1 = all levels)

	Returns:
		Number of matching tiles
	"""
	return get_tiles_by_type(tile_type, level).size()

func count_tiles_by_owner(owner_id: int, level: int = -1) -> int:
	"""
	Returns count of tiles owned by a faction.

	Args:
		owner_id: Owner faction ID
		level: Z level filter (-1 = all levels)

	Returns:
		Number of owned tiles
	"""
	return get_tiles_by_owner(owner_id, level).size()

func get_territory_stats(owner_id: int) -> Dictionary:
	"""
	Returns territory statistics for a faction.

	Args:
		owner_id: Owner faction ID

	Returns:
		Dictionary with territory stats
	"""
	var tiles = get_tiles_by_owner(owner_id)
	var border_tiles = get_border_tiles(owner_id)

	var stats = {
		"owner_id": owner_id,
		"total_tiles": tiles.size(),
		"border_tiles": border_tiles.size(),
		"interior_tiles": tiles.size() - border_tiles.size(),
		"total_scavenge_value": 0.0,
		"avg_scavenge_value": 0.0,
		"tiles_by_level": {
			0: 0,  # Underground
			1: 0,  # Ground
			2: 0   # Elevated
		},
		"tiles_by_type": {}
	}

	# Calculate statistics
	for tile in tiles:
		stats["total_scavenge_value"] += tile.scavenge_value
		stats["tiles_by_level"][tile.position.z] += 1

		var type_name = Tile.TileType.keys()[tile.tile_type]
		if not stats["tiles_by_type"].has(type_name):
			stats["tiles_by_type"][type_name] = 0
		stats["tiles_by_type"][type_name] += 1

	# Calculate averages
	if tiles.size() > 0:
		stats["avg_scavenge_value"] = stats["total_scavenge_value"] / float(tiles.size())

	return stats

# ============================================================================
# DISTANCE CALCULATIONS
# ============================================================================

func manhattan_distance(pos_a: Vector3i, pos_b: Vector3i, include_z: bool = false) -> int:
	"""
	Calculates Manhattan distance between two positions.

	Args:
		pos_a: First position
		pos_b: Second position
		include_z: Whether to include Z distance

	Returns:
		Manhattan distance
	"""
	var dist = abs(pos_a.x - pos_b.x) + abs(pos_a.y - pos_b.y)
	if include_z:
		dist += abs(pos_a.z - pos_b.z)
	return dist

func euclidean_distance(pos_a: Vector3i, pos_b: Vector3i, include_z: bool = false) -> float:
	"""
	Calculates Euclidean distance between two positions.

	Args:
		pos_a: First position
		pos_b: Second position
		include_z: Whether to include Z distance

	Returns:
		Euclidean distance
	"""
	var dx = float(pos_a.x - pos_b.x)
	var dy = float(pos_a.y - pos_b.y)
	var dist_sq = dx * dx + dy * dy

	if include_z:
		var dz = float(pos_a.z - pos_b.z)
		dist_sq += dz * dz

	return sqrt(dist_sq)

# ============================================================================
# DEBUGGING
# ============================================================================

func get_cache_stats() -> Dictionary:
	"""
	Returns cache statistics for debugging.

	Returns:
		Dictionary with cache statistics
	"""
	return {
		"cache_dirty": _cache_dirty,
		"type_cache_size": _tile_type_cache.size(),
		"owner_cache_size": _owner_cache.size(),
		"border_cache_size": _border_cache.size(),
		"type_cache_entries": _count_cache_entries(_tile_type_cache),
		"owner_cache_entries": _count_cache_entries(_owner_cache),
		"border_cache_entries": _count_cache_entries(_border_cache)
	}

func _count_cache_entries(cache: Dictionary) -> int:
	"""Counts total entries across all cache buckets."""
	var count = 0
	for key in cache:
		if cache[key] is Array:
			count += cache[key].size()
	return count
