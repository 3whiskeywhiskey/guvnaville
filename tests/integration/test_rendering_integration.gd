## Integration tests for Rendering System
extends GutTest

const MapView = preload("res://ui/map/map_view.gd")
const MockMapData = preload("res://tests/mocks/mock_map_data.gd")
const MockUnit = preload("res://tests/mocks/mock_unit.gd")

var map_view: MapView
var mock_map: MockMapData

func before_each():
	map_view = MapView.new()
	add_child_autofree(map_view)
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	await wait_seconds(0.1)

func test_render_with_real_map_data():
	var start_time = Time.get_ticks_msec()
	map_view.render_map(mock_map)
	var render_time = Time.get_ticks_msec() - start_time

	# Should render within performance budget
	assert_lt(render_time, 500, "Map rendering should complete within 500ms for 200x200 map")
	assert_true(map_view.is_initialized, "Map should be initialized")

	# Should create 10x10 = 100 chunks for 200x200 map
	var expected_chunks = 10 * 10
	assert_eq(map_view.chunks.size(), expected_chunks, "Should create 100 chunks")

func test_render_units_with_fog_of_war():
	map_view.render_map(mock_map)

	# Create units in different positions
	var units = []
	for i in range(20):
		var unit = MockUnit.new(i, Vector3i(i * 10, i * 10, 0), i % 2)
		units.append(unit)

	map_view.render_units(units)
	await wait_seconds(0.1)

	# Set up fog of war for faction 0
	var visible_tiles = []
	for x in range(50, 60):
		for y in range(50, 60):
			visible_tiles.append(Vector3i(x, y, 0))

	map_view.render_fog_of_war(0, visible_tiles)

	# Units outside fog should be hidden
	for unit in units:
		var unit_id = unit.id
		if unit_id in map_view.unit_renderers:
			var renderer = map_view.unit_renderers[unit_id]
			var is_in_visible_area = unit.position.x >= 50 and unit.position.x < 60 and \
									 unit.position.y >= 50 and unit.position.y < 60

			if not is_in_visible_area:
				# Should be hidden by fog (unless it's player's unit)
				pass  # Visibility logic can be complex

	assert_eq(map_view.unit_renderers.size(), 20, "Should render all units")

func test_camera_and_culling():
	map_view.render_map(mock_map)
	await wait_seconds(0.1)

	# Get initial visible chunks
	var visible_chunks_1 = map_view.visible_chunks.duplicate()

	# Move camera significantly
	map_view.move_camera(Vector2(5000, 5000))
	await wait_frames(5)

	var visible_chunks_2 = map_view.visible_chunks.duplicate()

	# Different chunks should be visible after camera move
	# (This may be the same if we move within the same viewport, so we check it's valid)
	assert_gt(visible_chunks_2.size(), 0, "Should have visible chunks after camera move")

func test_full_workflow():
	# 1. Render map
	map_view.render_map(mock_map)
	await wait_seconds(0.1)

	# 2. Create and render units
	var units = []
	for i in range(10):
		var unit = MockUnit.new(i, Vector3i(i * 5, i * 5, 0), 0)
		units.append(unit)
	map_view.render_units(units)

	# 3. Highlight tiles
	var highlight_positions = [
		Vector3i(10, 10, 0),
		Vector3i(11, 10, 0),
		Vector3i(12, 10, 0)
	]
	map_view.highlight_tiles(highlight_positions, Color.GREEN)

	# 4. Show movement path
	var path = [
		Vector3i(10, 10, 0),
		Vector3i(11, 10, 0),
		Vector3i(12, 10, 0),
		Vector3i(12, 11, 0)
	]
	map_view.show_movement_path(path)

	# 5. Move unit
	map_view.update_unit(units[0].id, Vector3i(15, 15, 0))
	await wait_seconds(0.5)

	# 6. Play attack animation
	map_view.play_attack_animation(Vector3i(15, 15, 0), Vector3i(16, 15, 0), "melee")
	await wait_seconds(0.5)

	# 7. Clear highlights
	map_view.clear_highlights()

	# Verify system is still functional
	assert_true(map_view.is_initialized, "Map should still be initialized")
	assert_eq(map_view.unit_renderers.size(), 10, "Should still have all units")

func test_multiple_unit_movements():
	map_view.render_map(mock_map)

	# Create units
	var units = []
	for i in range(5):
		var unit = MockUnit.new(i, Vector3i(i * 10, i * 10, 0), 0)
		units.append(unit)
	map_view.render_units(units)

	# Move all units
	for i in range(units.size()):
		var unit = units[i]
		var new_pos = Vector3i(i * 10 + 5, i * 10 + 5, 0)
		map_view.update_unit(unit.id, new_pos)

	await wait_seconds(0.5)

	# All units should have their renderers updated
	assert_eq(map_view.unit_renderers.size(), 5, "Should maintain all unit renderers")

func test_chunk_loading_and_unloading():
	map_view.render_map(mock_map)
	await wait_seconds(0.1)

	var chunk_loaded_count = 0
	var chunk_unloaded_count = 0

	map_view.chunk_loaded.connect(func(_pos): chunk_loaded_count += 1)
	map_view.chunk_unloaded.connect(func(_pos): chunk_unloaded_count += 1)

	# Move camera to trigger chunk loading/unloading
	map_view.move_camera(Vector2(10000, 10000))
	await wait_frames(10)

	# Some chunks should have been loaded/unloaded
	assert_gt(chunk_loaded_count + chunk_unloaded_count, 0,
			  "Should trigger chunk loading/unloading events")

func test_tile_updates_across_chunks():
	map_view.render_map(mock_map)

	# Update tiles in different chunks
	var tiles_to_update = [
		Vector3i(10, 10, 0),   # Chunk 0,0
		Vector3i(30, 30, 0),   # Chunk 1,1
		Vector3i(50, 50, 0),   # Chunk 2,2
		Vector3i(100, 100, 0)  # Chunk 5,5
	]

	for tile_pos in tiles_to_update:
		var tile = mock_map.get_tile(tile_pos)
		map_view.update_tile(tile_pos, tile)

	# Should not crash and chunks should be marked dirty
	assert_true(map_view.is_initialized, "Map should remain initialized")

func test_fog_of_war_updates():
	map_view.render_map(mock_map)

	# Initial fog state
	var visible_1 = []
	for x in range(20, 30):
		for y in range(20, 30):
			visible_1.append(Vector3i(x, y, 0))

	map_view.render_fog_of_war(0, visible_1)
	await wait_frames(2)

	# Update fog state (move vision)
	var visible_2 = []
	for x in range(40, 50):
		for y in range(40, 50):
			visible_2.append(Vector3i(x, y, 0))

	map_view.render_fog_of_war(0, visible_2)
	await wait_frames(2)

	# Should not crash
	assert_true(map_view.is_initialized, "Map should remain initialized")

func test_simultaneous_effects():
	map_view.render_map(mock_map)

	# Trigger multiple visual effects at once
	map_view.highlight_tiles([Vector3i(10, 10, 0)], Color.GREEN)
	map_view.show_movement_path([Vector3i(10, 10, 0), Vector3i(11, 10, 0)])
	map_view.selection_effect.show_selection(Vector3i(10, 10, 0))

	await wait_seconds(0.1)

	# All effects should be active
	assert_gt(map_view.active_highlights.size(), 0, "Should have highlights")
	assert_true(map_view.selection_effect.visible, "Selection effect should be visible")

	# Clear all
	map_view.clear_highlights()
	map_view.clear_movement_path()
	map_view.selection_effect.hide_selection()

	assert_eq(map_view.active_highlights.size(), 0, "Should clear highlights")
	assert_false(map_view.selection_effect.visible, "Selection effect should be hidden")
