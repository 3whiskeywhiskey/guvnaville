extends GutTest

## Unit tests for SpatialQuery class
##
## Tests spatial queries, caching, and advanced query operations
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# SETUP
# ============================================================================

var map_data: MapData
var spatial_query: SpatialQuery

func before_each():
	map_data = MapData.new()
	spatial_query = SpatialQuery.new(map_data)

func after_each():
	spatial_query = null
	map_data = null

# ============================================================================
# INITIALIZATION TESTS
# ============================================================================

func test_spatial_query_initialization():
	assert_not_null(spatial_query, "SpatialQuery should be created")

# ============================================================================
# PATHFINDING STUB TESTS
# ============================================================================

func test_find_path_returns_empty():
	var start = Vector3i(10, 10, 1)
	var goal = Vector3i(50, 50, 1)

	var path = spatial_query.find_path(start, goal)

	assert_not_null(path, "Path should not be null")
	assert_eq(path.size(), 0, "Path should be empty (stub implementation)")

func test_find_path_different_movement_types():
	var start = Vector3i(10, 10, 1)
	var goal = Vector3i(50, 50, 1)

	var path_ground = spatial_query.find_path(start, goal, 0)
	var path_flying = spatial_query.find_path(start, goal, 1)

	assert_eq(path_ground.size(), 0, "Ground path should be empty (stub)")
	assert_eq(path_flying.size(), 0, "Flying path should be empty (stub)")

# ============================================================================
# GET TILES BY TYPE TESTS
# ============================================================================

func test_get_tiles_by_type_basic():
	# Set some tiles to specific types
	for i in range(10):
		var tile = map_data.get_tile(Vector3i(i, 0, 1))
		tile.tile_type = Tile.TileType.RESIDENTIAL

	var tiles = spatial_query.get_tiles_by_type(Tile.TileType.RESIDENTIAL)

	assert_gte(tiles.size(), 10, "Should have at least 10 residential tiles")

func test_get_tiles_by_type_with_level_filter():
	# Set tiles on different levels
	var tile1 = map_data.get_tile(Vector3i(0, 0, 0))
	tile1.tile_type = Tile.TileType.COMMERCIAL

	var tile2 = map_data.get_tile(Vector3i(0, 0, 1))
	tile2.tile_type = Tile.TileType.COMMERCIAL

	var tile3 = map_data.get_tile(Vector3i(0, 0, 2))
	tile3.tile_type = Tile.TileType.COMMERCIAL

	var tiles_all = spatial_query.get_tiles_by_type(Tile.TileType.COMMERCIAL, -1)
	var tiles_level1 = spatial_query.get_tiles_by_type(Tile.TileType.COMMERCIAL, 1)

	assert_gte(tiles_all.size(), 3, "Should have tiles from all levels")
	assert_gte(tiles_level1.size(), 1, "Should have tiles from level 1")

	# Check level filter works
	for tile in tiles_level1:
		assert_eq(tile.position.z, 1, "All tiles should be from level 1")

func test_get_tiles_by_type_no_map_data():
	var query_no_map = SpatialQuery.new(null)
	var tiles = query_no_map.get_tiles_by_type(Tile.TileType.RESIDENTIAL)

	assert_eq(tiles.size(), 0, "Should return empty array without map data")

func test_get_tiles_by_type_caching():
	# Set some tiles
	for i in range(5):
		var tile = map_data.get_tile(Vector3i(i, 0, 1))
		tile.tile_type = Tile.TileType.MILITARY

	# First query (builds cache)
	var tiles1 = spatial_query.get_tiles_by_type(Tile.TileType.MILITARY)

	# Second query (should use cache)
	var tiles2 = spatial_query.get_tiles_by_type(Tile.TileType.MILITARY)

	assert_eq(tiles1.size(), tiles2.size(), "Cached query should return same size")

# ============================================================================
# GET TILES BY OWNER TESTS
# ============================================================================

func test_get_tiles_by_owner_basic():
	# Assign some tiles to faction 2
	map_data.update_tile_owner(Vector3i(10, 10, 1), 2)
	map_data.update_tile_owner(Vector3i(11, 10, 1), 2)
	map_data.update_tile_owner(Vector3i(12, 10, 1), 2)

	spatial_query.invalidate_owner_cache()  # Ensure cache is rebuilt
	var owned_tiles = spatial_query.get_tiles_by_owner(2)

	assert_gte(owned_tiles.size(), 3, "Should have at least 3 tiles owned by faction 2")

	# Check all returned tiles are owned by faction 2
	for tile in owned_tiles:
		assert_eq(tile.owner_id, 2, "All tiles should be owned by faction 2")

func test_get_tiles_by_owner_neutral():
	spatial_query.rebuild_caches()
	var neutral_tiles = spatial_query.get_tiles_by_owner(-1)

	# Most tiles should be neutral initially
	assert_gt(neutral_tiles.size(), 100000, "Should have many neutral tiles")

func test_get_tiles_by_owner_with_level_filter():
	# Assign tiles on different levels
	map_data.update_tile_owner(Vector3i(10, 10, 0), 3)
	map_data.update_tile_owner(Vector3i(10, 10, 1), 3)
	map_data.update_tile_owner(Vector3i(10, 10, 2), 3)

	spatial_query.invalidate_owner_cache()
	var tiles_all = spatial_query.get_tiles_by_owner(3, -1)
	var tiles_level1 = spatial_query.get_tiles_by_owner(3, 1)

	assert_gte(tiles_all.size(), 3, "Should have tiles from all levels")
	assert_gte(tiles_level1.size(), 1, "Should have tile from level 1")

	# Check level filter
	for tile in tiles_level1:
		assert_eq(tile.position.z, 1, "All tiles should be from level 1")

func test_get_tiles_by_owner_no_tiles():
	var tiles = spatial_query.get_tiles_by_owner(7)

	assert_eq(tiles.size(), 0, "Faction 7 should have no tiles initially")

# ============================================================================
# GET BORDER TILES TESTS
# ============================================================================

func test_get_border_tiles_basic():
	# Create a 3x3 territory for faction 5
	for x in range(20, 23):
		for y in range(20, 23):
			map_data.update_tile_owner(Vector3i(x, y, 1), 5)

	spatial_query.rebuild_caches()
	var border_tiles = spatial_query.get_border_tiles(5)

	# Border should be the outer ring (8 tiles)
	# Center tile (21, 21) is not border
	assert_eq(border_tiles.size(), 8, "3x3 territory should have 8 border tiles")

func test_get_border_tiles_single_tile():
	# Single isolated tile
	map_data.update_tile_owner(Vector3i(50, 50, 1), 6)

	spatial_query.rebuild_caches()
	var border_tiles = spatial_query.get_border_tiles(6)

	assert_eq(border_tiles.size(), 1, "Single tile should be its own border")

func test_get_border_tiles_line():
	# Create a line of tiles
	for x in range(30, 35):
		map_data.update_tile_owner(Vector3i(x, 40, 1), 7)

	spatial_query.rebuild_caches()
	var border_tiles = spatial_query.get_border_tiles(7)

	# All tiles in a line are border tiles (except if completely surrounded)
	assert_eq(border_tiles.size(), 5, "All tiles in line should be border tiles")

func test_get_border_tiles_no_territory():
	var border_tiles = spatial_query.get_border_tiles(8)

	assert_eq(border_tiles.size(), 0, "Faction with no territory should have no border")

# ============================================================================
# ADVANCED QUERY TESTS
# ============================================================================

func test_get_tiles_in_area_with_filter():
	var center = Vector3i(50, 50, 1)
	var radius = 10

	# Set some tiles as passable
	for i in range(5):
		var tile = map_data.get_tile(Vector3i(50 + i, 50, 1))
		tile.is_passable = true

	var filter = func(tile): return tile.is_passable
	var tiles = spatial_query.get_tiles_in_area(center, radius, filter)

	# Check all returned tiles are passable
	for tile in tiles:
		assert_true(tile.is_passable, "All returned tiles should be passable")

func test_get_passable_tiles_in_area():
	var center = Vector3i(75, 75, 1)
	var radius = 5

	# Set some tiles as passable
	map_data.get_tile(Vector3i(75, 75, 1)).is_passable = true
	map_data.get_tile(Vector3i(76, 75, 1)).is_passable = true
	map_data.get_tile(Vector3i(77, 75, 1)).is_passable = false

	var passable = spatial_query.get_passable_tiles_in_area(center, radius)

	# All returned tiles should be passable
	for tile in passable:
		assert_true(tile.is_passable, "Tile should be passable")

func test_get_scavenge_tiles_in_area():
	var center = Vector3i(100, 100, 1)
	var radius = 5

	# Set scavenge values
	map_data.update_tile_scavenge_value(Vector3i(100, 100, 1), 50.0)
	map_data.update_tile_scavenge_value(Vector3i(101, 100, 1), 30.0)
	map_data.update_tile_scavenge_value(Vector3i(102, 100, 1), 0.0)

	var scavenge_tiles = spatial_query.get_scavenge_tiles_in_area(center, radius, 25.0)

	# Check all returned tiles have sufficient scavenge value
	for tile in scavenge_tiles:
		assert_gte(tile.scavenge_value, 25.0, "Tile should have scavenge value >= 25.0")

func test_get_controlled_tiles_in_area():
	var center = Vector3i(120, 120, 1)
	var radius = 5

	# Set some tiles to faction 3
	map_data.update_tile_owner(Vector3i(120, 120, 1), 3)
	map_data.update_tile_owner(Vector3i(121, 120, 1), 3)
	map_data.update_tile_owner(Vector3i(122, 120, 1), 5)  # Different faction

	var controlled = spatial_query.get_controlled_tiles_in_area(center, radius, 3)

	# Check all returned tiles are owned by faction 3
	for tile in controlled:
		assert_eq(tile.owner_id, 3, "Tile should be owned by faction 3")

# ============================================================================
# STATISTICAL QUERY TESTS
# ============================================================================

func test_count_tiles_by_type():
	# Set some tiles
	for i in range(15):
		var tile = map_data.get_tile(Vector3i(i, 0, 1))
		tile.tile_type = Tile.TileType.INDUSTRIAL

	var count = spatial_query.count_tiles_by_type(Tile.TileType.INDUSTRIAL)

	assert_gte(count, 15, "Should count at least 15 industrial tiles")

func test_count_tiles_by_owner():
	# Assign tiles to faction 4
	for i in range(20):
		map_data.update_tile_owner(Vector3i(i, 0, 1), 4)

	spatial_query.invalidate_owner_cache()
	var count = spatial_query.count_tiles_by_owner(4)

	assert_gte(count, 20, "Should count at least 20 tiles for faction 4")

func test_get_territory_stats():
	# Create territory for faction 2
	for x in range(10, 15):
		for y in range(10, 15):
			map_data.update_tile_owner(Vector3i(x, y, 1), 2)
			map_data.update_tile_scavenge_value(Vector3i(x, y, 1), 50.0)

	spatial_query.rebuild_caches()
	var stats = spatial_query.get_territory_stats(2)

	assert_not_null(stats, "Stats should be returned")
	assert_eq(stats["owner_id"], 2, "Should be for faction 2")
	assert_eq(stats["total_tiles"], 25, "Should have 25 tiles (5x5)")
	assert_gt(stats["border_tiles"], 0, "Should have border tiles")
	assert_gt(stats["total_scavenge_value"], 0.0, "Should have scavenge value")
	assert_true(stats.has("tiles_by_level"), "Should have tiles_by_level")
	assert_true(stats.has("tiles_by_type"), "Should have tiles_by_type")

# ============================================================================
# DISTANCE CALCULATION TESTS
# ============================================================================

func test_manhattan_distance_2d():
	var pos_a = Vector3i(10, 10, 1)
	var pos_b = Vector3i(15, 13, 1)

	var dist = spatial_query.manhattan_distance(pos_a, pos_b, false)

	assert_eq(dist, 8, "Manhattan distance should be 8 (5+3)")

func test_manhattan_distance_3d():
	var pos_a = Vector3i(10, 10, 0)
	var pos_b = Vector3i(15, 13, 2)

	var dist_2d = spatial_query.manhattan_distance(pos_a, pos_b, false)
	var dist_3d = spatial_query.manhattan_distance(pos_a, pos_b, true)

	assert_eq(dist_2d, 8, "2D distance should be 8")
	assert_eq(dist_3d, 10, "3D distance should be 10 (8+2)")

func test_euclidean_distance_2d():
	var pos_a = Vector3i(0, 0, 0)
	var pos_b = Vector3i(3, 4, 0)

	var dist = spatial_query.euclidean_distance(pos_a, pos_b, false)

	assert_almost_eq(dist, 5.0, 0.01, "Euclidean distance should be 5.0 (3-4-5 triangle)")

func test_euclidean_distance_3d():
	var pos_a = Vector3i(0, 0, 0)
	var pos_b = Vector3i(3, 4, 0)

	var dist_2d = spatial_query.euclidean_distance(pos_a, pos_b, false)
	var dist_3d = spatial_query.euclidean_distance(pos_a, pos_b, true)

	assert_almost_eq(dist_2d, 5.0, 0.01, "2D distance should be 5.0")
	assert_almost_eq(dist_3d, 5.0, 0.01, "3D distance should be 5.0 (z=0 for both)")

func test_distance_same_position():
	var pos = Vector3i(50, 50, 1)

	var manhattan = spatial_query.manhattan_distance(pos, pos)
	var euclidean = spatial_query.euclidean_distance(pos, pos)

	assert_eq(manhattan, 0, "Manhattan distance to self should be 0")
	assert_almost_eq(euclidean, 0.0, 0.01, "Euclidean distance to self should be 0")

# ============================================================================
# CACHE MANAGEMENT TESTS
# ============================================================================

func test_invalidate_cache():
	# Build cache
	spatial_query.rebuild_caches()

	# Invalidate
	spatial_query.invalidate_cache()

	var stats = spatial_query.get_cache_stats()

	assert_true(stats["cache_dirty"], "Cache should be marked dirty")

func test_invalidate_type_cache():
	spatial_query.rebuild_caches()

	spatial_query.invalidate_type_cache()

	var stats = spatial_query.get_cache_stats()

	assert_eq(stats["type_cache_size"], 0, "Type cache should be empty")

func test_invalidate_owner_cache():
	spatial_query.rebuild_caches()

	spatial_query.invalidate_owner_cache()

	var stats = spatial_query.get_cache_stats()

	assert_eq(stats["owner_cache_size"], 0, "Owner cache should be empty")
	assert_eq(stats["border_cache_size"], 0, "Border cache should also be empty")

func test_rebuild_caches():
	# Set up some data
	for i in range(10):
		var tile = map_data.get_tile(Vector3i(i, 0, 1))
		tile.tile_type = Tile.TileType.PARK

	map_data.update_tile_owner(Vector3i(20, 20, 1), 5)

	spatial_query.rebuild_caches()

	var stats = spatial_query.get_cache_stats()

	assert_false(stats["cache_dirty"], "Cache should not be dirty after rebuild")
	assert_gt(stats["type_cache_size"], 0, "Type cache should have entries")
	assert_gt(stats["owner_cache_size"], 0, "Owner cache should have entries")

func test_cache_stats():
	spatial_query.rebuild_caches()

	var stats = spatial_query.get_cache_stats()

	assert_not_null(stats, "Stats should be returned")
	assert_true(stats.has("cache_dirty"), "Should have cache_dirty")
	assert_true(stats.has("type_cache_size"), "Should have type_cache_size")
	assert_true(stats.has("owner_cache_size"), "Should have owner_cache_size")
	assert_true(stats.has("border_cache_size"), "Should have border_cache_size")
	assert_true(stats.has("type_cache_entries"), "Should have type_cache_entries")
	assert_true(stats.has("owner_cache_entries"), "Should have owner_cache_entries")
	assert_true(stats.has("border_cache_entries"), "Should have border_cache_entries")

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

func test_query_after_map_changes():
	# Initial setup
	map_data.update_tile_owner(Vector3i(50, 50, 1), 3)
	map_data.update_tile_owner(Vector3i(51, 50, 1), 3)

	spatial_query.rebuild_caches()
	var initial_count = spatial_query.count_tiles_by_owner(3)

	# Make changes
	map_data.update_tile_owner(Vector3i(52, 50, 1), 3)
	map_data.update_tile_owner(Vector3i(53, 50, 1), 3)

	spatial_query.invalidate_owner_cache()
	var updated_count = spatial_query.count_tiles_by_owner(3)

	assert_gt(updated_count, initial_count, "Count should increase after adding tiles")

func test_border_tiles_update_correctly():
	# Create initial territory
	for x in range(30, 33):
		for y in range(30, 33):
			map_data.update_tile_owner(Vector3i(x, y, 1), 4)

	spatial_query.rebuild_caches()
	var initial_border = spatial_query.get_border_tiles(4)

	# Expand territory (add outer ring)
	for x in range(29, 34):
		for y in range(29, 34):
			map_data.update_tile_owner(Vector3i(x, y, 1), 4)

	spatial_query.rebuild_caches()
	var expanded_border = spatial_query.get_border_tiles(4)

	# Border should have changed
	assert_neq(initial_border.size(), expanded_border.size(), "Border size should change after expansion")

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

func test_empty_filter():
	var center = Vector3i(50, 50, 1)
	var tiles = spatial_query.get_tiles_in_area(center, 5, Callable())

	assert_gt(tiles.size(), 0, "Should return all tiles with empty filter")

func test_filter_that_matches_nothing():
	var center = Vector3i(50, 50, 1)
	var filter = func(tile): return false  # Matches nothing

	var tiles = spatial_query.get_tiles_in_area(center, 5, filter)

	assert_eq(tiles.size(), 0, "Should return no tiles when filter matches nothing")

func test_query_with_no_map_data():
	var query = SpatialQuery.new(null)

	var tiles_by_type = query.get_tiles_by_type(Tile.TileType.RESIDENTIAL)
	var tiles_by_owner = query.get_tiles_by_owner(0)
	var border_tiles = query.get_border_tiles(0)

	assert_eq(tiles_by_type.size(), 0, "Should return empty array")
	assert_eq(tiles_by_owner.size(), 0, "Should return empty array")
	assert_eq(border_tiles.size(), 0, "Should return empty array")

# ============================================================================
# PERFORMANCE INDICATION TESTS
# ============================================================================

func test_cached_query_is_faster_than_rebuild():
	# Build cache
	spatial_query.rebuild_caches()

	# Time a cached query
	var start_cached = Time.get_ticks_usec()
	for i in range(100):
		var tiles = spatial_query.get_tiles_by_type(Tile.TileType.RUINS)
	var cached_time = Time.get_ticks_usec() - start_cached

	# Time queries with cache invalidation each time
	spatial_query.invalidate_cache()
	var start_uncached = Time.get_ticks_usec()
	for i in range(100):
		spatial_query.invalidate_cache()
		var tiles = spatial_query.get_tiles_by_type(Tile.TileType.RUINS)
	var uncached_time = Time.get_ticks_usec() - start_uncached

	assert_lt(cached_time, uncached_time, "Cached queries should be faster than rebuilding cache")
