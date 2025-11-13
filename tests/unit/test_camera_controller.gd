## Unit tests for CameraController
extends GutTest

const CameraController = preload("res://ui/map/camera_controller.gd")

var camera: CameraController

func before_each():
	camera = CameraController.new()
	add_child_autofree(camera)
	camera.set_map_bounds(Rect2i(0, 0, 200, 200))

func test_initial_zoom_level():
	assert_eq(camera.current_zoom_level, CameraController.ZoomLevel.ZOOM_1X,
			  "Should start at zoom level 1X")

func test_zoom_camera_increases_level():
	camera.set_zoom_level(CameraController.ZoomLevel.ZOOM_1X)
	camera.zoom_camera(1)

	assert_eq(camera.current_zoom_level, CameraController.ZoomLevel.ZOOM_1_5X,
			  "Should zoom in to 1.5X")

func test_zoom_camera_decreases_level():
	camera.set_zoom_level(CameraController.ZoomLevel.ZOOM_1_5X)
	camera.zoom_camera(-1)

	assert_eq(camera.current_zoom_level, CameraController.ZoomLevel.ZOOM_1X,
			  "Should zoom out to 1X")

func test_zoom_clamps_to_minimum():
	camera.set_zoom_level(CameraController.ZoomLevel.ZOOM_1X)
	camera.zoom_camera(-10)  # Try to zoom way out

	assert_eq(camera.current_zoom_level, CameraController.ZoomLevel.ZOOM_1X,
			  "Should clamp to minimum zoom level")

func test_zoom_clamps_to_maximum():
	camera.set_zoom_level(CameraController.ZoomLevel.ZOOM_2X)
	camera.zoom_camera(10)  # Try to zoom way in

	assert_eq(camera.current_zoom_level, CameraController.ZoomLevel.ZOOM_2X,
			  "Should clamp to maximum zoom level")

func test_move_camera_changes_position():
	var original_pos = camera.position
	camera.move_camera(Vector2(100, 100))

	assert_ne(camera.position, original_pos, "Camera position should change")

func test_camera_movement_respects_bounds():
	camera.move_camera(Vector2(999999, 999999))  # Try to move far off map

	# Should be clamped within map bounds
	var map_max_x = 200 * 64  # 200 tiles * 64 pixels
	var map_max_y = 200 * 64

	assert_lte(camera.position.x, map_max_x, "X should be clamped to map bounds")
	assert_lte(camera.position.y, map_max_y, "Y should be clamped to map bounds")
	assert_gte(camera.position.x, 0, "X should not be negative")
	assert_gte(camera.position.y, 0, "Y should not be negative")

func test_center_camera_on_moves_to_tile():
	var tile_pos = Vector3i(50, 50, 0)
	camera.center_camera_on(tile_pos)

	await wait_seconds(0.5)  # Wait for animation

	# Camera should be centered on tile (approximately)
	var expected_x = 50 * 64 + 32  # tile * size + half tile
	var expected_y = 50 * 64 + 32

	assert_almost_eq(camera.position.x, expected_x, 10,
					 "Camera X should be near tile center")
	assert_almost_eq(camera.position.y, expected_y, 10,
					 "Camera Y should be near tile center")

func test_get_camera_bounds_returns_valid_rect():
	var bounds = camera.get_camera_bounds()

	assert_true(bounds is Rect2i, "Should return Rect2i")
	assert_gt(bounds.size.x, 0, "Bounds width should be positive")
	assert_gt(bounds.size.y, 0, "Bounds height should be positive")

func test_enable_edge_scrolling():
	camera.enable_edge_scrolling(false)
	assert_false(camera.edge_scrolling_enabled, "Edge scrolling should be disabled")

	camera.enable_edge_scrolling(true)
	assert_true(camera.edge_scrolling_enabled, "Edge scrolling should be enabled")

func test_set_camera_speed():
	camera.set_camera_speed(500.0)
	assert_eq(camera.camera_speed, 500.0, "Camera speed should be updated")

func test_camera_moved_signal_emitted():
	var signal_received = false
	camera.camera_moved.connect(func(_pos): signal_received = true)

	camera.move_camera(Vector2(10, 10))

	assert_true(signal_received, "Should emit camera_moved signal")

func test_camera_zoomed_signal_emitted():
	var signal_received = false
	camera.camera_zoomed.connect(func(_level): signal_received = true)

	camera.zoom_camera(1)

	assert_true(signal_received, "Should emit camera_zoomed signal")

func test_camera_centered_signal_emitted():
	var signal_received = false
	camera.camera_centered.connect(func(_pos): signal_received = true)

	camera.center_camera_on(Vector3i(10, 10, 0))
	await wait_seconds(0.5)

	assert_true(signal_received, "Should emit camera_centered signal")

func test_set_map_bounds():
	camera.set_map_bounds(Rect2i(0, 0, 100, 100))

	assert_eq(camera.map_bounds.size.x, 100, "Map bounds width should be updated")
	assert_eq(camera.map_bounds.size.y, 100, "Map bounds height should be updated")
