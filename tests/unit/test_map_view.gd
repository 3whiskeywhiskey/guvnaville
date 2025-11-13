## Unit tests for MapView
extends GutTest

const MapView = preload("res://ui/map/map_view.gd")
const MockMapData = preload("res://tests/mocks/mock_map_data.gd")
const MockUnit = preload("res://tests/mocks/mock_unit.gd")

var map_view: MapView
var mock_map: MockMapData

func before_each():
	map_view = MapView.new()
	add_child_autofree(map_view)
	mock_map = MockMapData.new(Vector3i(100, 100, 3))
	await wait_seconds(0.1)  # Wait for components to initialize

func test_map_view_initializes_components():
	assert_not_null(map_view.camera_controller, "Should have camera controller")
	assert_not_null(map_view.sprite_loader, "Should have sprite loader")
	assert_not_null(map_view.selection_effect, "Should have selection effect")
	assert_not_null(map_view.movement_effect, "Should have movement effect")
	assert_not_null(map_view.attack_effect, "Should have attack effect")
	assert_not_null(map_view.fog_renderer, "Should have fog renderer")

func test_render_map_creates_chunks():
	var signal_received = false
	map_view.map_rendered.connect(func(): signal_received = true)

	map_view.render_map(mock_map)
	await wait_seconds(0.1)

	assert_true(signal_received, "Should emit map_rendered signal")
	assert_true(map_view.is_initialized, "Should be initialized")
	assert_gt(map_view.chunks.size(), 0, "Should create chunks")

	# For 100x100 map with 20x20 chunks, should have 5x5 = 25 chunks
	var expected_chunks = 5 * 5
	assert_eq(map_view.chunks.size(), expected_chunks,
			  "Should create correct number of chunks")

func test_render_map_performance():
	var start_time = Time.get_ticks_msec()
	map_view.render_map(mock_map)
	var elapsed = Time.get_ticks_msec() - start_time

	# Should render within performance budget (500ms target)
	assert_lt(elapsed, 500, "Map rendering should complete within 500ms")

func test_render_units():
	map_view.render_map(mock_map)

	# Create test units
	var units = []
	for i in range(10):
		var unit = MockUnit.new(i, Vector3i(i * 5, i * 5, 0), 0)
		units.append(unit)

	map_view.render_units(units)
	await wait_seconds(0.1)

	assert_eq(map_view.unit_renderers.size(), 10, "Should create 10 unit renderers")

func test_update_tile():
	map_view.render_map(mock_map)

	var tile_pos = Vector3i(10, 10, 0)
	var tile = mock_map.get_tile(tile_pos)

	# Should not crash
	map_view.update_tile(tile_pos, tile)

	# Chunk should be marked dirty
	var chunk_pos = Vector2i(0, 0)  # Tile 10,10 is in chunk 0,0
	if chunk_pos in map_view.chunks:
		assert_true(map_view.chunks[chunk_pos].is_dirty,
					"Chunk should be marked dirty after tile update")

func test_update_unit_position():
	map_view.render_map(mock_map)

	var unit = MockUnit.new(1, Vector3i(10, 10, 0), 0)
	map_view.render_units([unit])

	var new_pos = Vector3i(15, 15, 0)
	map_view.update_unit(unit.id, new_pos)

	await wait_seconds(0.5)  # Wait for animation

	# Unit renderer should exist and be at new position
	assert_true(unit.id in map_view.unit_renderers,
				"Unit renderer should still exist")

func test_highlight_tiles():
	map_view.render_map(mock_map)

	var positions = [
		Vector3i(10, 10, 0),
		Vector3i(11, 10, 0),
		Vector3i(10, 11, 0)
	]

	map_view.highlight_tiles(positions, Color.GREEN)

	assert_eq(map_view.active_highlights.size(), 3,
			  "Should create 3 highlight sprites")

func test_clear_highlights():
	map_view.render_map(mock_map)

	var positions = [Vector3i(10, 10, 0), Vector3i(11, 10, 0)]
	map_view.highlight_tiles(positions, Color.GREEN)

	assert_gt(map_view.active_highlights.size(), 0, "Should have highlights")

	var signal_received = false
	map_view.highlights_cleared.connect(func(): signal_received = true)

	map_view.clear_highlights()

	assert_eq(map_view.active_highlights.size(), 0, "Should clear all highlights")
	assert_true(signal_received, "Should emit highlights_cleared signal")

func test_show_movement_path():
	map_view.render_map(mock_map)

	var path = [
		Vector3i(10, 10, 0),
		Vector3i(11, 10, 0),
		Vector3i(12, 10, 0),
		Vector3i(12, 11, 0)
	]

	# Should not crash
	map_view.show_movement_path(path)

func test_clear_movement_path():
	map_view.render_map(mock_map)

	var path = [Vector3i(10, 10, 0), Vector3i(11, 10, 0)]
	map_view.show_movement_path(path)

	# Should not crash
	map_view.clear_movement_path()

func test_get_tile_at_screen_position():
	map_view.render_map(mock_map)

	# Screen position at tile 10, 10 (approximately)
	var screen_pos = Vector2(10 * 64 + 32, 10 * 64 + 32)
	var tile_pos = map_view.get_tile_at_screen_position(screen_pos)

	# Should return valid position
	assert_true(tile_pos.x >= 0, "Should return valid X coordinate")
	assert_true(tile_pos.y >= 0, "Should return valid Y coordinate")

func test_get_tile_at_screen_position_out_of_bounds():
	map_view.render_map(mock_map)

	var screen_pos = Vector2(-100, -100)
	var tile_pos = map_view.get_tile_at_screen_position(screen_pos)

	assert_eq(tile_pos, Vector3i(-1, -1, -1),
			  "Should return invalid position for out of bounds")

func test_get_visible_bounds():
	map_view.render_map(mock_map)

	var bounds = map_view.get_visible_bounds()

	assert_true(bounds is Rect2i, "Should return Rect2i")
	assert_gt(bounds.size.x, 0, "Bounds width should be positive")
	assert_gt(bounds.size.y, 0, "Bounds height should be positive")

func test_render_fog_of_war():
	map_view.render_map(mock_map)

	var visible_tiles = [
		Vector3i(10, 10, 0),
		Vector3i(11, 10, 0),
		Vector3i(10, 11, 0)
	]

	# Should not crash
	map_view.render_fog_of_war(0, visible_tiles)

func test_play_attack_animation_melee():
	map_view.render_map(mock_map)

	var signal_received = false
	map_view.attack_animation_complete.connect(func(_a, _d): signal_received = true)

	var from = Vector3i(10, 10, 0)
	var to = Vector3i(11, 10, 0)

	map_view.play_attack_animation(from, to, "melee")
	await wait_seconds(0.5)

	assert_true(signal_received, "Should emit attack_animation_complete signal")

func test_play_attack_animation_ranged():
	map_view.render_map(mock_map)

	var signal_received = false
	map_view.attack_animation_complete.connect(func(_a, _d): signal_received = true)

	var from = Vector3i(10, 10, 0)
	var to = Vector3i(15, 10, 0)

	map_view.play_attack_animation(from, to, "ranged")
	await wait_seconds(1.0)

	assert_true(signal_received, "Should emit attack_animation_complete signal")

func test_camera_controls():
	map_view.render_map(mock_map)

	var original_pos = map_view.camera_controller.position

	map_view.move_camera(Vector2(100, 100))

	assert_ne(map_view.camera_controller.position, original_pos,
			  "Camera should move")

func test_zoom_controls():
	map_view.render_map(mock_map)

	var signal_received = false
	map_view.camera_zoomed.connect(func(_level): signal_received = true)

	map_view.zoom_camera(1)

	assert_true(signal_received, "Should emit camera_zoomed signal")

func test_center_camera():
	map_view.render_map(mock_map)

	var signal_received = false
	map_view.camera_centered.connect(func(_pos): signal_received = true)

	map_view.center_camera_on(Vector3i(50, 50, 0))
	await wait_seconds(0.5)

	assert_true(signal_received, "Should emit camera_centered signal")

func test_performance_stats_updated():
	map_view.render_map(mock_map)

	await wait_seconds(0.2)

	# Stats should be updated
	assert_gte(map_view.render_stats["fps"], 0, "FPS should be tracked")
	assert_gte(map_view.render_stats["frame_time_ms"], 0, "Frame time should be tracked")
	assert_gte(map_view.render_stats["chunks_rendered"], 0, "Chunks rendered should be tracked")
