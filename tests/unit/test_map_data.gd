extends GutTest

## Unit tests for MapData class
##
## Tests map grid operations, spatial queries, and map loading
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# SETUP
# ============================================================================

var map_data: MapData

func before_each():
	map_data = MapData.new()

func after_each():
	map_data = null

# ============================================================================
# INITIALIZATION TESTS
# ============================================================================

func test_map_initialization():
	assert_not_null(map_data, "MapData should be created")
	assert_eq(map_data.get_map_size(), Vector3i(200, 200, 3), "Map size should be 200x200x3")
	assert_eq(map_data.get_tile_count(), 120000, "Should have 120,000 tiles")

func test_all_tiles_initialized():
	var count = 0
	for z in range(3):
		for y in range(200):
			for x in range(200):
				var tile = map_data.get_tile(Vector3i(x, y, z))
				if tile:
					count += 1

	assert_eq(count, 120000, "All 120,000 tiles should be initialized")

# ============================================================================
# POSITION VALIDATION TESTS
# ============================================================================

func test_is_position_valid_corners():
	assert_true(map_data.is_position_valid(Vector3i(0, 0, 0)), "0,0,0 is valid")
	assert_true(map_data.is_position_valid(Vector3i(199, 199, 2)), "199,199,2 is valid")

func test_is_position_valid_edges():
	assert_true(map_data.is_position_valid(Vector3i(0, 100, 1)), "Left edge is valid")
	assert_true(map_data.is_position_valid(Vector3i(199, 100, 1)), "Right edge is valid")
	assert_true(map_data.is_position_valid(Vector3i(100, 0, 1)), "Top edge is valid")
	assert_true(map_data.is_position_valid(Vector3i(100, 199, 1)), "Bottom edge is valid")

func test_is_position_valid_out_of_bounds():
	assert_false(map_data.is_position_valid(Vector3i(-1, 0, 0)), "Negative X is invalid")
	assert_false(map_data.is_position_valid(Vector3i(0, -1, 0)), "Negative Y is invalid")
	assert_false(map_data.is_position_valid(Vector3i(0, 0, -1)), "Negative Z is invalid")
	assert_false(map_data.is_position_valid(Vector3i(200, 0, 0)), "X=200 is invalid")
	assert_false(map_data.is_position_valid(Vector3i(0, 200, 0)), "Y=200 is invalid")
	assert_false(map_data.is_position_valid(Vector3i(0, 0, 3)), "Z=3 is invalid")

# ============================================================================
# TILE ACCESS TESTS
# ============================================================================

func test_get_tile_valid_position():
	var tile = map_data.get_tile(Vector3i(50, 50, 1))

	assert_not_null(tile, "Should return tile for valid position")
	assert_eq(tile.position, Vector3i(50, 50, 1), "Tile position should match")

func test_get_tile_invalid_position():
	var tile = map_data.get_tile(Vector3i(300, 300, 5))

	assert_null(tile, "Should return null for invalid position")

func test_get_tile_different_levels():
	var underground = map_data.get_tile(Vector3i(50, 50, 0))
	var ground = map_data.get_tile(Vector3i(50, 50, 1))
	var elevated = map_data.get_tile(Vector3i(50, 50, 2))

	assert_not_null(underground, "Underground tile exists")
	assert_not_null(ground, "Ground tile exists")
	assert_not_null(elevated, "Elevated tile exists")
	assert_eq(underground.position.z, 0, "Underground is z=0")
	assert_eq(ground.position.z, 1, "Ground is z=1")
	assert_eq(elevated.position.z, 2, "Elevated is z=2")

# ============================================================================
# SPATIAL QUERY TESTS - get_tiles_in_radius
# ============================================================================

func test_get_tiles_in_radius_basic():
	var center = Vector3i(50, 50, 1)
	var radius = 5

	var tiles = map_data.get_tiles_in_radius(center, radius, true)

	assert_gt(tiles.size(), 0, "Should return tiles")
	assert_lte(tiles.size(), (radius * 2 + 1) * (radius * 2 + 1), "Should not exceed max possible tiles")

func test_get_tiles_in_radius_manhattan_distance():
	var center = Vector3i(50, 50, 1)
	var radius = 3

	var tiles = map_data.get_tiles_in_radius(center, radius, true)

	# Check all returned tiles are within Manhattan distance
	for tile in tiles:
		var dist = abs(tile.position.x - center.x) + abs(tile.position.y - center.y)
		assert_lte(dist, radius, "Tile %s should be within radius %d (dist=%d)" % [tile.position, radius, dist])

func test_get_tiles_in_radius_same_level():
	var center = Vector3i(50, 50, 1)
	var radius = 5

	var tiles = map_data.get_tiles_in_radius(center, radius, true)

	# All tiles should be on same Z level
	for tile in tiles:
		assert_eq(tile.position.z, center.z, "Tile should be on same Z level")

func test_get_tiles_in_radius_multiple_levels():
	var center = Vector3i(50, 50, 1)
	var radius = 5

	var tiles = map_data.get_tiles_in_radius(center, radius, false)

	# Should include tiles from multiple levels
	var z_levels = {}
	for tile in tiles:
		z_levels[tile.position.z] = true

	assert_gte(z_levels.size(), 1, "Should have tiles from at least one level")

func test_get_tiles_in_radius_out_of_bounds():
	var center = Vector3i(300, 300, 5)
	var radius = 5

	var tiles = map_data.get_tiles_in_radius(center, radius, true)

	assert_eq(tiles.size(), 0, "Should return empty array for invalid center")

func test_get_tiles_in_radius_edge():
	var center = Vector3i(0, 0, 0)
	var radius = 2

	var tiles = map_data.get_tiles_in_radius(center, radius, true)

	assert_gt(tiles.size(), 0, "Should return tiles even at map edge")

	# Check tiles are clamped to map bounds
	for tile in tiles:
		assert_true(map_data.is_position_valid(tile.position), "All tiles should be valid")

# ============================================================================
# SPATIAL QUERY TESTS - get_tiles_in_rect
# ============================================================================

func test_get_tiles_in_rect_basic():
	var rect = Rect2i(Vector2i(10, 10), Vector2i(20, 20))
	var tiles = map_data.get_tiles_in_rect(rect, 1)

	assert_eq(tiles.size(), 400, "20x20 rect should have 400 tiles")

func test_get_tiles_in_rect_positions():
	var rect = Rect2i(Vector2i(10, 10), Vector2i(20, 20))
	var tiles = map_data.get_tiles_in_rect(rect, 1)

	for tile in tiles:
		assert_gte(tile.position.x, 10, "X should be >= 10")
		assert_lt(tile.position.x, 30, "X should be < 30")
		assert_gte(tile.position.y, 10, "Y should be >= 10")
		assert_lt(tile.position.y, 30, "Y should be < 30")
		assert_eq(tile.position.z, 1, "Z should be 1")

func test_get_tiles_in_rect_invalid_level():
	var rect = Rect2i(Vector2i(10, 10), Vector2i(20, 20))
	var tiles = map_data.get_tiles_in_rect(rect, 5)

	assert_eq(tiles.size(), 0, "Should return empty array for invalid level")

func test_get_tiles_in_rect_edge():
	var rect = Rect2i(Vector2i(190, 190), Vector2i(20, 20))
	var tiles = map_data.get_tiles_in_rect(rect, 1)

	# Should be clamped to map bounds
	assert_gt(tiles.size(), 0, "Should return tiles even when rect extends beyond map")
	assert_lte(tiles.size(), 100, "Should be clamped to valid tiles (10x10 = 100)")

func test_get_tiles_in_rect_single_tile():
	var rect = Rect2i(Vector2i(50, 50), Vector2i(1, 1))
	var tiles = map_data.get_tiles_in_rect(rect, 1)

	assert_eq(tiles.size(), 1, "1x1 rect should have 1 tile")
	assert_eq(tiles[0].position, Vector3i(50, 50, 1), "Should be the correct tile")

# ============================================================================
# SPATIAL QUERY TESTS - get_neighbors
# ============================================================================

func test_get_neighbors_4way():
	var center = Vector3i(50, 50, 1)
	var neighbors = map_data.get_neighbors(center, false)

	assert_eq(neighbors.size(), 4, "Should have 4 neighbors (4-way)")

func test_get_neighbors_8way():
	var center = Vector3i(50, 50, 1)
	var neighbors = map_data.get_neighbors(center, true)

	assert_eq(neighbors.size(), 8, "Should have 8 neighbors (8-way)")

func test_get_neighbors_corner():
	var corner = Vector3i(0, 0, 0)
	var neighbors = map_data.get_neighbors(corner, false)

	assert_eq(neighbors.size(), 2, "Corner should have 2 neighbors (4-way)")

func test_get_neighbors_corner_8way():
	var corner = Vector3i(0, 0, 0)
	var neighbors = map_data.get_neighbors(corner, true)

	assert_eq(neighbors.size(), 3, "Corner should have 3 neighbors (8-way)")

func test_get_neighbors_edge():
	var edge = Vector3i(0, 50, 1)
	var neighbors = map_data.get_neighbors(edge, false)

	assert_eq(neighbors.size(), 3, "Edge should have 3 neighbors (4-way)")

func test_get_neighbors_invalid():
	var invalid = Vector3i(300, 300, 5)
	var neighbors = map_data.get_neighbors(invalid, false)

	assert_eq(neighbors.size(), 0, "Invalid position should have 0 neighbors")

# ============================================================================
# TILE MODIFICATION TESTS
# ============================================================================

func test_update_tile_owner():
	var position = Vector3i(25, 30, 1)
	var tile = map_data.get_tile(position)

	var old_owner = tile.owner_id
	map_data.update_tile_owner(position, 3)

	assert_eq(tile.owner_id, 3, "Owner should be updated to 3")

func test_update_tile_owner_invalid_position():
	# Should not crash with invalid position
	map_data.update_tile_owner(Vector3i(300, 300, 5), 3)
	# Test passes if no crash

func test_update_tile_owner_invalid_owner_id():
	# Should not crash with invalid owner ID
	map_data.update_tile_owner(Vector3i(25, 30, 1), 99)
	# Test passes if no crash

func test_update_tile_owner_no_change():
	var position = Vector3i(25, 30, 1)
	map_data.update_tile_owner(position, 5)

	var tile = map_data.get_tile(position)
	var owner_before = tile.owner_id

	# Update to same owner
	map_data.update_tile_owner(position, 5)

	assert_eq(tile.owner_id, owner_before, "Owner should remain unchanged")

func test_update_tile_scavenge_value():
	var position = Vector3i(25, 30, 1)
	var tile = map_data.get_tile(position)

	map_data.update_tile_scavenge_value(position, 75.5)

	assert_almost_eq(tile.scavenge_value, 75.5, 0.01, "Scavenge value should be updated")

func test_update_tile_scavenge_value_clamped():
	var position = Vector3i(25, 30, 1)
	var tile = map_data.get_tile(position)

	map_data.update_tile_scavenge_value(position, 150.0)
	assert_almost_eq(tile.scavenge_value, 100.0, 0.01, "Should be clamped to 100.0")

	map_data.update_tile_scavenge_value(position, -50.0)
	assert_almost_eq(tile.scavenge_value, 0.0, 0.01, "Should be clamped to 0.0")

func test_update_tile_scavenge_value_invalid_position():
	# Should not crash with invalid position
	map_data.update_tile_scavenge_value(Vector3i(300, 300, 5), 50.0)
	# Test passes if no crash

# ============================================================================
# MAP LOADING TESTS
# ============================================================================

func test_load_map_success():
	var result = map_data.load_map("res://data/world/test_map.json")

	assert_true(result, "Map should load successfully")
	assert_eq(map_data.get_map_size(), Vector3i(200, 200, 3), "Map size should be correct")

func test_load_map_tile_data():
	var result = map_data.load_map("res://data/world/test_map.json")
	assert_true(result, "Map should load")

	# Check if specific tiles from test_map.json were loaded
	var tile1 = map_data.get_tile(Vector3i(0, 0, 0))
	assert_not_null(tile1, "Tile at 0,0,0 should exist")
	assert_eq(tile1.tile_type, Tile.TileType.RESIDENTIAL, "Tile type should be RESIDENTIAL")
	assert_almost_eq(tile1.scavenge_value, 50.0, 0.01, "Scavenge value should be 50.0")

	var tile2 = map_data.get_tile(Vector3i(1, 0, 0))
	assert_not_null(tile2, "Tile at 1,0,0 should exist")
	assert_eq(tile2.tile_type, Tile.TileType.COMMERCIAL, "Tile type should be COMMERCIAL")
	assert_almost_eq(tile2.scavenge_value, 75.0, 0.01, "Scavenge value should be 75.0")

func test_load_map_file_not_found():
	var result = map_data.load_map("res://nonexistent.json")

	assert_false(result, "Should return false for nonexistent file")

func test_load_map_invalid_dimensions():
	var result = map_data.load_map("res://data/world/invalid_map.json")

	assert_false(result, "Should return false for invalid dimensions")

# ============================================================================
# STATISTICS TESTS
# ============================================================================

func test_get_statistics():
	var stats = map_data.get_statistics()

	assert_not_null(stats, "Statistics should be returned")
	assert_eq(stats["total_tiles"], 120000, "Should have 120,000 total tiles")
	assert_true(stats.has("tiles_by_type"), "Should have tiles_by_type")
	assert_true(stats.has("tiles_by_owner"), "Should have tiles_by_owner")
	assert_true(stats.has("total_scavenge_value"), "Should have total_scavenge_value")
	assert_true(stats.has("passable_tiles"), "Should have passable_tiles count")

func test_get_statistics_after_changes():
	# Make some changes
	map_data.update_tile_owner(Vector3i(10, 10, 1), 2)
	map_data.update_tile_owner(Vector3i(11, 10, 1), 2)
	map_data.update_tile_owner(Vector3i(12, 10, 1), 2)

	var stats = map_data.get_statistics()

	assert_true(stats["tiles_by_owner"].has(2), "Should have owner 2 in stats")
	assert_gte(stats["tiles_by_owner"][2], 3, "Owner 2 should have at least 3 tiles")

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

func test_map_corners_accessible():
	var corner1 = map_data.get_tile(Vector3i(0, 0, 0))
	var corner2 = map_data.get_tile(Vector3i(199, 0, 0))
	var corner3 = map_data.get_tile(Vector3i(0, 199, 0))
	var corner4 = map_data.get_tile(Vector3i(199, 199, 0))

	assert_not_null(corner1, "Corner 0,0,0 accessible")
	assert_not_null(corner2, "Corner 199,0,0 accessible")
	assert_not_null(corner3, "Corner 0,199,0 accessible")
	assert_not_null(corner4, "Corner 199,199,0 accessible")

func test_all_levels_accessible():
	var underground = map_data.get_tile(Vector3i(100, 100, 0))
	var ground = map_data.get_tile(Vector3i(100, 100, 1))
	var elevated = map_data.get_tile(Vector3i(100, 100, 2))

	assert_not_null(underground, "Underground level accessible")
	assert_not_null(ground, "Ground level accessible")
	assert_not_null(elevated, "Elevated level accessible")

func test_radius_zero():
	var center = Vector3i(50, 50, 1)
	var tiles = map_data.get_tiles_in_radius(center, 0, true)

	assert_eq(tiles.size(), 1, "Radius 0 should return only center tile")
	assert_eq(tiles[0].position, center, "Should be the center tile")

func test_rect_zero_size():
	var rect = Rect2i(Vector2i(50, 50), Vector2i(0, 0))
	var tiles = map_data.get_tiles_in_rect(rect, 1)

	assert_eq(tiles.size(), 0, "Zero-size rect should return no tiles")

# ============================================================================
# PERFORMANCE INDICATION TESTS
# ============================================================================

func test_get_tile_is_fast():
	var start_time = Time.get_ticks_usec()

	for i in range(1000):
		var x = i % 200
		var y = (i / 200) % 200
		var z = i % 3
		var tile = map_data.get_tile(Vector3i(x, y, z))

	var elapsed_usec = Time.get_ticks_usec() - start_time
	var avg_usec = elapsed_usec / 1000.0

	assert_lt(avg_usec, 10.0, "Average get_tile should be < 10 microseconds (actual: %.2f μs)" % avg_usec)

func test_update_owner_is_fast():
	var start_time = Time.get_ticks_usec()

	for i in range(1000):
		var x = i % 200
		var y = (i / 200) % 200
		map_data.update_tile_owner(Vector3i(x, y, 1), i % 9)

	var elapsed_usec = Time.get_ticks_usec() - start_time
	var avg_usec = elapsed_usec / 1000.0

	assert_lt(avg_usec, 10.0, "Average update_tile_owner should be < 10 microseconds (actual: %.2f μs)" % avg_usec)
