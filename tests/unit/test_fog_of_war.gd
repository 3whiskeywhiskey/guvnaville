extends GutTest

## Unit tests for FogOfWar class
##
## Tests per-faction visibility tracking with bit packing
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# SETUP
# ============================================================================

var fog: FogOfWar

func before_each():
	fog = FogOfWar.new(Vector3i(200, 200, 3), 9)

func after_each():
	fog = null

# ============================================================================
# INITIALIZATION TESTS
# ============================================================================

func test_fog_initialization():
	assert_not_null(fog, "FogOfWar should be created")

func test_all_tiles_unexplored_initially():
	# Check several random positions
	for i in range(100):
		var x = randi() % 200
		var y = randi() % 200
		var z = randi() % 3
		var pos = Vector3i(x, y, z)

		for faction_id in range(9):
			assert_false(fog.is_tile_explored(pos, faction_id), "Tile should be unexplored initially")
			assert_false(fog.is_tile_visible(pos, faction_id), "Tile should be invisible initially")

# ============================================================================
# VISIBILITY QUERY TESTS
# ============================================================================

func test_is_tile_visible_initially_false():
	var pos = Vector3i(50, 50, 1)

	for faction_id in range(9):
		assert_false(fog.is_tile_visible(pos, faction_id), "Tile should not be visible initially")

func test_is_tile_explored_initially_false():
	var pos = Vector3i(50, 50, 1)

	for faction_id in range(9):
		assert_false(fog.is_tile_explored(pos, faction_id), "Tile should not be explored initially")

func test_is_tile_visible_invalid_position():
	var invalid_pos = Vector3i(300, 300, 5)

	assert_false(fog.is_tile_visible(invalid_pos, 0), "Invalid position should return false")

func test_is_tile_visible_invalid_faction():
	var pos = Vector3i(50, 50, 1)

	assert_false(fog.is_tile_visible(pos, -1), "Invalid faction should return false")
	assert_false(fog.is_tile_visible(pos, 99), "Invalid faction should return false")

# ============================================================================
# UPDATE FOG OF WAR TESTS
# ============================================================================

func test_update_fog_of_war_basic():
	var visible_positions = [
		Vector3i(50, 50, 1),
		Vector3i(51, 50, 1),
		Vector3i(50, 51, 1),
	]

	fog.update_fog_of_war(0, visible_positions)

	# Visible positions should be both visible and explored
	for pos in visible_positions:
		assert_true(fog.is_tile_visible(pos, 0), "Position should be visible")
		assert_true(fog.is_tile_explored(pos, 0), "Position should be explored")

	# Other positions should not be visible
	assert_false(fog.is_tile_visible(Vector3i(100, 100, 1), 0), "Unseen position should not be visible")

func test_update_fog_of_war_multiple_factions():
	var faction0_visible = [Vector3i(50, 50, 1)]
	var faction1_visible = [Vector3i(100, 100, 1)]

	fog.update_fog_of_war(0, faction0_visible)
	fog.update_fog_of_war(1, faction1_visible)

	# Faction 0 should see their area
	assert_true(fog.is_tile_visible(Vector3i(50, 50, 1), 0), "Faction 0 should see their area")
	assert_false(fog.is_tile_visible(Vector3i(100, 100, 1), 0), "Faction 0 should not see faction 1 area")

	# Faction 1 should see their area
	assert_true(fog.is_tile_visible(Vector3i(100, 100, 1), 1), "Faction 1 should see their area")
	assert_false(fog.is_tile_visible(Vector3i(50, 50, 1), 1), "Faction 1 should not see faction 0 area")

func test_update_fog_of_war_invalid_faction():
	var visible_positions = [Vector3i(50, 50, 1)]

	# Should not crash with invalid faction
	fog.update_fog_of_war(99, visible_positions)
	# Test passes if no crash

func test_update_fog_of_war_empty_array():
	# Should not crash with empty array
	fog.update_fog_of_war(0, [])
	# Test passes if no crash

func test_update_fog_of_war_large_array():
	var visible_positions: Array[Vector3i] = []

	# Add 1000 visible positions
	for i in range(1000):
		var x = i % 200
		var y = (i / 200) % 200
		visible_positions.append(Vector3i(x, y, 1))

	fog.update_fog_of_war(0, visible_positions)

	# Check a few random ones
	assert_true(fog.is_tile_visible(Vector3i(0, 0, 1), 0), "Should be visible")
	assert_true(fog.is_tile_visible(Vector3i(50, 2, 1), 0), "Should be visible")

# ============================================================================
# FOG PERSISTENCE TESTS
# ============================================================================

func test_fog_persists_when_not_visible():
	var position = Vector3i(50, 50, 1)

	# Reveal tile
	fog.update_fog_of_war(0, [position])
	assert_true(fog.is_tile_explored(position, 0), "Should be explored")
	assert_true(fog.is_tile_visible(position, 0), "Should be visible")

	# Update without that position (move vision away)
	fog.update_fog_of_war(0, [Vector3i(60, 60, 1)])

	# Should still be explored but not visible
	assert_true(fog.is_tile_explored(position, 0), "Should remain explored")
	assert_false(fog.is_tile_visible(position, 0), "Should no longer be visible")

func test_explored_never_reverts():
	var position = Vector3i(50, 50, 1)

	# Explore tile
	fog.update_fog_of_war(0, [position])
	assert_true(fog.is_tile_explored(position, 0), "Should be explored")

	# Update many times without that position
	for i in range(100):
		fog.update_fog_of_war(0, [Vector3i(i, i, 1)])

	# Should still be explored
	assert_true(fog.is_tile_explored(position, 0), "Should remain explored after many updates")

# ============================================================================
# REVEAL AREA TESTS
# ============================================================================

func test_reveal_area_basic():
	var center = Vector3i(50, 50, 1)
	var radius = 5

	fog.reveal_area(1, center, radius)

	# Center should be explored and visible
	assert_true(fog.is_tile_explored(center, 1), "Center should be explored")
	assert_true(fog.is_tile_visible(center, 1), "Center should be visible")

	# Points within radius should be explored
	assert_true(fog.is_tile_explored(Vector3i(55, 50, 1), 1), "Point at distance 5 should be explored")

	# Points outside radius should not be explored
	assert_false(fog.is_tile_explored(Vector3i(60, 60, 1), 1), "Point outside radius should not be explored")

func test_reveal_area_manhattan_distance():
	var center = Vector3i(50, 50, 1)
	var radius = 3

	fog.reveal_area(0, center, radius)

	# Check Manhattan distance calculations
	# Distance 3 = 3 units away in cardinal directions
	assert_true(fog.is_tile_explored(Vector3i(53, 50, 1), 0), "3 units east should be explored")
	assert_true(fog.is_tile_explored(Vector3i(47, 50, 1), 0), "3 units west should be explored")
	assert_true(fog.is_tile_explored(Vector3i(50, 53, 1), 0), "3 units south should be explored")
	assert_true(fog.is_tile_explored(Vector3i(50, 47, 1), 0), "3 units north should be explored")

	# Distance > 3 should not be explored
	assert_false(fog.is_tile_explored(Vector3i(54, 50, 1), 0), "4 units away should not be explored")

func test_reveal_area_invalid_faction():
	var center = Vector3i(50, 50, 1)

	# Should not crash with invalid faction
	fog.reveal_area(99, center, 5)
	# Test passes if no crash

func test_reveal_area_invalid_position():
	var center = Vector3i(300, 300, 5)

	# Should not crash with invalid position
	fog.reveal_area(0, center, 5)
	# Test passes if no crash

func test_reveal_area_at_edge():
	var center = Vector3i(0, 0, 0)
	var radius = 5

	# Should not crash when revealing area at map edge
	fog.reveal_area(0, center, radius)

	assert_true(fog.is_tile_explored(Vector3i(0, 0, 0), 0), "Center at edge should be explored")
	assert_true(fog.is_tile_explored(Vector3i(5, 0, 0), 0), "Point within radius should be explored")

# ============================================================================
# CLEAR FOG TESTS
# ============================================================================

func test_clear_fog_for_faction():
	fog.clear_fog_for_faction(0)

	# Check several random positions - all should be explored and visible
	for i in range(100):
		var x = randi() % 200
		var y = randi() % 200
		var z = randi() % 3
		var pos = Vector3i(x, y, z)

		assert_true(fog.is_tile_explored(pos, 0), "All tiles should be explored after clear_fog")
		assert_true(fog.is_tile_visible(pos, 0), "All tiles should be visible after clear_fog")

func test_clear_fog_only_affects_one_faction():
	fog.clear_fog_for_faction(0)

	# Faction 0 should see everything
	assert_true(fog.is_tile_visible(Vector3i(50, 50, 1), 0), "Faction 0 should see everything")

	# Faction 1 should still have fog
	assert_false(fog.is_tile_visible(Vector3i(50, 50, 1), 1), "Faction 1 should still have fog")

func test_clear_fog_invalid_faction():
	# Should not crash with invalid faction
	fog.clear_fog_for_faction(99)
	# Test passes if no crash

# ============================================================================
# SERIALIZATION TESTS
# ============================================================================

func test_fog_to_dict():
	# Set up some fog state
	fog.update_fog_of_war(0, [Vector3i(50, 50, 1)])
	fog.reveal_area(1, Vector3i(100, 100, 1), 5)

	var dict = fog.to_dict()

	assert_not_null(dict, "Dictionary should be created")
	assert_true(dict.has("map_size"), "Should have map_size")
	assert_true(dict.has("num_factions"), "Should have num_factions")
	assert_true(dict.has("fog_data"), "Should have fog_data")
	assert_eq(dict["num_factions"], 9, "Should have 9 factions")

func test_fog_from_dict():
	# Create fog state
	fog.update_fog_of_war(0, [Vector3i(50, 50, 1), Vector3i(51, 50, 1)])

	# Serialize and deserialize
	var dict = fog.to_dict()
	var restored = FogOfWar.from_dict(dict)

	# Check if state was preserved
	assert_true(restored.is_tile_explored(Vector3i(50, 50, 1), 0), "Explored state should be preserved")
	assert_true(restored.is_tile_explored(Vector3i(51, 50, 1), 0), "Explored state should be preserved")
	assert_false(restored.is_tile_explored(Vector3i(100, 100, 1), 0), "Unexplored state should be preserved")

func test_fog_serialization_round_trip():
	# Set up complex fog state
	fog.reveal_area(0, Vector3i(50, 50, 1), 10)
	fog.reveal_area(1, Vector3i(100, 100, 1), 8)
	fog.clear_fog_for_faction(2)

	# Serialize
	var dict = fog.to_dict()

	# Deserialize
	var restored = FogOfWar.from_dict(dict)

	# Verify state preservation
	assert_true(restored.is_tile_explored(Vector3i(50, 50, 1), 0), "Faction 0 area preserved")
	assert_true(restored.is_tile_explored(Vector3i(100, 100, 1), 1), "Faction 1 area preserved")
	assert_true(restored.is_tile_explored(Vector3i(150, 150, 1), 2), "Faction 2 clear fog preserved")

# ============================================================================
# STATISTICS TESTS
# ============================================================================

func test_get_visibility_stats():
	# Explore some tiles
	fog.reveal_area(0, Vector3i(50, 50, 1), 5)

	var stats = fog.get_visibility_stats(0)

	assert_not_null(stats, "Stats should be returned")
	assert_eq(stats["faction_id"], 0, "Should have correct faction ID")
	assert_eq(stats["total_tiles"], 120000, "Should have total tiles")
	assert_gt(stats["explored_tiles"], 0, "Should have explored tiles")
	assert_gt(stats["visible_tiles"], 0, "Should have visible tiles")
	assert_gt(stats["unexplored_tiles"], 0, "Should have unexplored tiles")
	assert_gt(stats["explored_percentage"], 0.0, "Should have explored percentage")

func test_get_visibility_stats_invalid_faction():
	var stats = fog.get_visibility_stats(99)

	assert_true(stats.is_empty(), "Should return empty dict for invalid faction")

func test_get_memory_usage():
	var memory = fog.get_memory_usage()

	assert_not_null(memory, "Memory usage should be returned")
	assert_true(memory.has("bytes_per_faction"), "Should have bytes_per_faction")
	assert_true(memory.has("total_bytes"), "Should have total_bytes")
	assert_true(memory.has("total_kb"), "Should have total_kb")
	assert_eq(memory["num_factions"], 9, "Should have 9 factions")
	assert_eq(memory["total_tiles"], 120000, "Should have 120,000 tiles")
	assert_eq(memory["bits_per_tile"], 2, "Should use 2 bits per tile")

func test_memory_usage_is_reasonable():
	var memory = fog.get_memory_usage()

	# Should use ~90 KB for 9 factions × 120,000 tiles × 2 bits
	assert_lt(memory["total_kb"], 100.0, "Memory usage should be < 100 KB")

# ============================================================================
# FACTION INDEPENDENCE TESTS
# ============================================================================

func test_factions_have_independent_fog():
	var pos = Vector3i(50, 50, 1)

	# Faction 0 reveals tile
	fog.update_fog_of_war(0, [pos])

	# Faction 0 should see it
	assert_true(fog.is_tile_visible(pos, 0), "Faction 0 should see tile")

	# All other factions should not see it
	for faction_id in range(1, 9):
		assert_false(fog.is_tile_visible(pos, faction_id), "Faction %d should not see tile" % faction_id)

func test_all_factions_can_explore_same_tile():
	var pos = Vector3i(75, 75, 1)

	# All factions explore the same tile
	for faction_id in range(9):
		fog.update_fog_of_war(faction_id, [pos])

	# All factions should see it
	for faction_id in range(9):
		assert_true(fog.is_tile_visible(pos, faction_id), "Faction %d should see tile" % faction_id)
		assert_true(fog.is_tile_explored(pos, faction_id), "Faction %d should have explored tile" % faction_id)

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

func test_reveal_radius_zero():
	var center = Vector3i(50, 50, 1)

	fog.reveal_area(0, center, 0)

	# Only center should be revealed
	assert_true(fog.is_tile_explored(center, 0), "Center should be explored")
	assert_false(fog.is_tile_explored(Vector3i(51, 50, 1), 0), "Adjacent tile should not be explored")

func test_reveal_very_large_radius():
	var center = Vector3i(100, 100, 1)
	var radius = 500  # Larger than map

	# Should not crash with large radius
	fog.reveal_area(0, center, radius)

	# Should reveal entire map level
	assert_true(fog.is_tile_explored(Vector3i(0, 0, 1), 0), "Corner should be explored")
	assert_true(fog.is_tile_explored(Vector3i(199, 199, 1), 0), "Opposite corner should be explored")

func test_update_fog_with_invalid_positions():
	var positions = [
		Vector3i(50, 50, 1),  # Valid
		Vector3i(300, 300, 5),  # Invalid
		Vector3i(75, 75, 1),  # Valid
	]

	# Should not crash with mixed valid/invalid positions
	fog.update_fog_of_war(0, positions)

	# Valid positions should be explored
	assert_true(fog.is_tile_explored(Vector3i(50, 50, 1), 0), "Valid position should be explored")
	assert_true(fog.is_tile_explored(Vector3i(75, 75, 1), 0), "Valid position should be explored")

# ============================================================================
# PERFORMANCE INDICATION TESTS
# ============================================================================

func test_visibility_check_is_fast():
	var start_time = Time.get_ticks_usec()

	for i in range(10000):
		var x = i % 200
		var y = (i / 200) % 200
		var z = i % 3
		var is_visible = fog.is_tile_visible(Vector3i(x, y, z), i % 9)

	var elapsed_usec = Time.get_ticks_usec() - start_time
	var avg_usec = elapsed_usec / 10000.0

	assert_lt(avg_usec, 1.0, "Average visibility check should be < 1 microsecond (actual: %.3f μs)" % avg_usec)

func test_update_fog_is_reasonably_fast():
	var visible_positions: Array[Vector3i] = []

	# Create 100 visible positions (typical unit vision)
	for i in range(100):
		var x = (i * 2) % 200
		var y = (i * 3) % 200
		visible_positions.append(Vector3i(x, y, 1))

	var start_time = Time.get_ticks_msec()

	fog.update_fog_of_war(0, visible_positions)

	var elapsed_msec = Time.get_ticks_msec() - start_time

	assert_lt(elapsed_msec, 20.0, "Fog update should be < 20ms (actual: %d ms)" % elapsed_msec)
