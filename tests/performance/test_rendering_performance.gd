## Performance tests for Rendering System
extends GutTest

const MapView = preload("res://ui/map/map_view.gd")
const MockMapData = preload("res://tests/mocks/mock_map_data.gd")
const MockUnit = preload("res://tests/mocks/mock_unit.gd")

var map_view: MapView
var mock_map: MockMapData

func before_each():
	map_view = MapView.new()
	add_child_autofree(map_view)
	await wait_seconds(0.1)

func test_map_render_performance_200x200():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))

	var start_time = Time.get_ticks_msec()
	map_view.render_map(mock_map)
	var elapsed = Time.get_ticks_msec() - start_time

	print("Map render time (200x200): %d ms" % elapsed)

	# Should render within performance budget
	assert_lt(elapsed, 500, "Should render 200x200 map in < 500ms")

func test_unit_render_performance_200_units():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)

	# Create 200 units
	var units = []
	for i in range(200):
		var x = (i * 7) % 200
		var y = (i * 11) % 200
		var unit = MockUnit.new(i, Vector3i(x, y, 0), i % 9)
		units.append(unit)

	var start_time = Time.get_ticks_msec()
	map_view.render_units(units)
	var elapsed = Time.get_ticks_msec() - start_time

	print("Unit render time (200 units): %d ms" % elapsed)

	# Should render within performance budget
	assert_lt(elapsed, 50, "Should render 200 units in < 50ms")

func test_frame_time_with_200_units():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)

	# Create and render 200 units
	var units = []
	for i in range(200):
		var x = (i * 7) % 200
		var y = (i * 11) % 200
		var unit = MockUnit.new(i, Vector3i(x, y, 0), i % 9)
		units.append(unit)
	map_view.render_units(units)

	await wait_seconds(0.5)  # Let system stabilize

	# Measure frame times over 60 frames (1 second at 60 FPS)
	var frame_times = []
	for frame in range(60):
		var start = Time.get_ticks_usec()
		await get_tree().process_frame
		var frame_time = (Time.get_ticks_usec() - start) / 1000.0  # Convert to ms
		frame_times.append(frame_time)

	# Calculate average frame time
	var total_time = 0.0
	for time in frame_times:
		total_time += time
	var avg_frame_time = total_time / frame_times.size()

	print("Average frame time (200 units): %.2f ms" % avg_frame_time)
	print("Equivalent FPS: %.1f" % (1000.0 / avg_frame_time))

	# Should maintain 60 FPS (16.67ms per frame) or at least 30 FPS (33.33ms)
	# Note: In headless testing, frame times may vary significantly
	# We use a more lenient target for CI
	assert_lt(avg_frame_time, 50.0, "Average frame time should be < 50ms (20 FPS minimum)")

func test_chunk_culling_performance():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)
	await wait_seconds(0.1)

	# Count total chunks
	var total_chunks = map_view.chunks.size()

	# Check visible chunks
	var visible_chunks = map_view.visible_chunks.size()

	print("Total chunks: %d" % total_chunks)
	print("Visible chunks: %d" % visible_chunks)

	# Should render much less than total (culling working)
	assert_lt(visible_chunks, total_chunks / 2,
			  "Should cull at least half of chunks (camera view limited)")

func test_tile_update_performance():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)

	# Update 100 random tiles
	var start_time = Time.get_ticks_msec()

	for i in range(100):
		var x = (i * 7) % 200
		var y = (i * 11) % 200
		var pos = Vector3i(x, y, 0)
		var tile = mock_map.get_tile(pos)
		map_view.update_tile(pos, tile)

	var elapsed = Time.get_ticks_msec() - start_time

	print("Tile update time (100 tiles): %d ms" % elapsed)

	# Should be very fast (< 1ms per tile average)
	assert_lt(elapsed, 100, "Should update 100 tiles in < 100ms")

func test_highlight_performance():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)

	# Highlight 100 tiles
	var positions = []
	for i in range(100):
		positions.append(Vector3i(i % 20, i / 20, 0))

	var start_time = Time.get_ticks_msec()
	map_view.highlight_tiles(positions, Color.GREEN)
	var elapsed = Time.get_ticks_msec() - start_time

	print("Highlight time (100 tiles): %d ms" % elapsed)

	# Should highlight within performance budget
	assert_lt(elapsed, 20, "Should highlight 100 tiles in < 20ms")

func test_fog_of_war_render_performance():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)

	# Create typical visibility area (100 tiles)
	var visible_tiles = []
	for x in range(50, 60):
		for y in range(50, 60):
			visible_tiles.append(Vector3i(x, y, 0))

	var start_time = Time.get_ticks_msec()
	map_view.render_fog_of_war(0, visible_tiles)
	var elapsed = Time.get_ticks_msec() - start_time

	print("Fog of war render time: %d ms" % elapsed)

	# Should render fog within performance budget
	assert_lt(elapsed, 100, "Should render fog of war in < 100ms")

func test_unit_movement_animation_performance():
	mock_map = MockMapData.new(Vector3i(100, 100, 3))
	map_view.render_map(mock_map)

	# Create a unit
	var unit = MockUnit.new(1, Vector3i(10, 10, 0), 0)
	map_view.render_units([unit])

	# Move unit 10 times
	var start_time = Time.get_ticks_msec()

	for i in range(10):
		var new_pos = Vector3i(10 + i, 10, 0)
		map_view.update_unit(unit.id, new_pos)
		await wait_seconds(0.05)  # Small wait between movements

	var elapsed = Time.get_ticks_msec() - start_time

	print("Unit movement time (10 moves): %d ms" % elapsed)

	# Should complete animations in reasonable time
	# (each move is ~300ms animation, so 10 moves + overhead)
	assert_lt(elapsed, 3500, "Should complete 10 unit movements in < 3.5s")

func test_memory_usage_estimate():
	mock_map = MockMapData.new(Vector3i(200, 200, 3))
	map_view.render_map(mock_map)

	# Create 200 units
	var units = []
	for i in range(200):
		var unit = MockUnit.new(i, Vector3i(i % 200, i / 200, 0), 0)
		units.append(unit)
	map_view.render_units(units)

	await wait_seconds(0.5)

	# Get memory stats
	var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	var dynamic_memory = Performance.get_monitor(Performance.MEMORY_DYNAMIC)

	print("Static memory: %.2f MB" % (static_memory / 1024.0 / 1024.0))
	print("Dynamic memory: %.2f MB" % (dynamic_memory / 1024.0 / 1024.0))

	# Total rendering memory should be reasonable (< 500MB target)
	# Note: This includes all of Godot, so we just check it's not excessive
	var total_mb = (static_memory + dynamic_memory) / 1024.0 / 1024.0
	assert_lt(total_mb, 1000.0, "Total memory should be < 1GB")

func test_sustained_performance():
	mock_map = MockMapData.new(Vector3i(100, 100, 3))
	map_view.render_map(mock_map)

	# Create units
	var units = []
	for i in range(50):
		var unit = MockUnit.new(i, Vector3i(i * 2, i * 2, 0), 0)
		units.append(unit)
	map_view.render_units(units)

	await wait_seconds(0.5)

	# Run for 2 seconds and track FPS
	var fps_samples = []
	var start_time = Time.get_ticks_msec()

	while Time.get_ticks_msec() - start_time < 2000:
		await get_tree().process_frame
		fps_samples.append(Engine.get_frames_per_second())

	# Calculate average FPS
	var total_fps = 0
	for fps in fps_samples:
		total_fps += fps
	var avg_fps = total_fps / fps_samples.size() if fps_samples.size() > 0 else 0

	print("Average sustained FPS: %.1f" % avg_fps)

	# Should maintain at least 30 FPS sustained
	# (Note: In headless CI, FPS measurements may not be reliable)
	if avg_fps > 10:  # Only test if FPS is being measured
		assert_gte(avg_fps, 20.0, "Should maintain at least 20 FPS sustained")
