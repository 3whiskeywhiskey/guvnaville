## CameraController - Manages camera movement and zoom
## Handles input for panning, zooming, edge scrolling, and centering
class_name CameraController
extends Camera2D

# Zoom levels
enum ZoomLevel {
	ZOOM_1X = 0,    # Standard view
	ZOOM_1_5X = 1,  # Medium zoom
	ZOOM_2X = 2     # Maximum zoom
}

# Constants
const CAMERA_SPEED: float = 300.0
const EDGE_SCROLL_MARGIN: int = 20
const ZOOM_ANIMATION_DURATION: float = 0.2
const TILE_SIZE: int = 64

# Camera state
var current_zoom_level: ZoomLevel = ZoomLevel.ZOOM_1X
var map_bounds: Rect2i = Rect2i(0, 0, 200, 200)
var edge_scrolling_enabled: bool = true
var camera_speed: float = CAMERA_SPEED

# Zoom scale mappings
var _zoom_scales: Dictionary = {
	ZoomLevel.ZOOM_1X: Vector2(1.0, 1.0),
	ZoomLevel.ZOOM_1_5X: Vector2(0.667, 0.667),
	ZoomLevel.ZOOM_2X: Vector2(0.5, 0.5)
}

# Animation
var _zoom_tween: Tween
var _pan_tween: Tween

# Signals
signal camera_moved(new_position: Vector2)
signal camera_zoomed(zoom_level: int)
signal camera_centered(tile_position: Vector3i)

func _ready() -> void:
	# Set initial zoom
	zoom = _zoom_scales[current_zoom_level]

func _process(delta: float) -> void:
	_handle_keyboard_movement(delta)
	_handle_edge_scrolling(delta)

func _input(event: InputEvent) -> void:
	_handle_mouse_input(event)

## Handle keyboard camera movement (WASD, arrow keys)
func _handle_keyboard_movement(delta: float) -> void:
	var movement = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1

	if movement.length() > 0:
		move_camera(movement.normalized() * camera_speed * delta)

## Handle edge scrolling (mouse near screen edges)
func _handle_edge_scrolling(delta: float) -> void:
	if not edge_scrolling_enabled:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var movement = Vector2.ZERO

	if mouse_pos.x < EDGE_SCROLL_MARGIN:
		movement.x -= 1
	elif mouse_pos.x > viewport_size.x - EDGE_SCROLL_MARGIN:
		movement.x += 1

	if mouse_pos.y < EDGE_SCROLL_MARGIN:
		movement.y -= 1
	elif mouse_pos.y > viewport_size.y - EDGE_SCROLL_MARGIN:
		movement.y += 1

	if movement.length() > 0:
		move_camera(movement.normalized() * camera_speed * delta)

## Handle mouse input (zoom, middle mouse drag)
func _handle_mouse_input(event: InputEvent) -> void:
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_camera(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_camera(-1)

	# Middle mouse drag (future enhancement)
	# TODO: Implement middle mouse drag panning

## Move camera by delta amount in screen space
func move_camera(delta: Vector2) -> void:
	var new_position = position + delta

	# Clamp to map boundaries
	var map_pixel_bounds = Rect2(
		Vector2.ZERO,
		Vector2(map_bounds.size.x * TILE_SIZE, map_bounds.size.y * TILE_SIZE)
	)

	new_position.x = clampf(new_position.x, map_pixel_bounds.position.x, map_pixel_bounds.end.x)
	new_position.y = clampf(new_position.y, map_pixel_bounds.position.y, map_pixel_bounds.end.y)

	position = new_position
	camera_moved.emit(position)

## Change camera zoom level
func zoom_camera(zoom_delta: int) -> void:
	var new_level = int(current_zoom_level) + zoom_delta

	# Clamp to valid zoom levels
	new_level = clampi(new_level, ZoomLevel.ZOOM_1X, ZoomLevel.ZOOM_2X)

	if new_level != current_zoom_level:
		set_zoom_level(new_level)

## Set camera zoom to specific level
func set_zoom_level(level: int) -> void:
	if level < ZoomLevel.ZOOM_1X or level > ZoomLevel.ZOOM_2X:
		push_warning("CameraController: Invalid zoom level %d" % level)
		return

	current_zoom_level = level as ZoomLevel
	var target_zoom = _zoom_scales[current_zoom_level]

	# Animate zoom
	if _zoom_tween:
		_zoom_tween.kill()

	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "zoom", target_zoom, ZOOM_ANIMATION_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN_OUT)

	camera_zoomed.emit(current_zoom_level)

## Center camera on a specific tile position with animation
func center_camera_on(tile_position: Vector3i) -> void:
	var target_screen_pos = _tile_to_screen_position(tile_position)

	if _pan_tween:
		_pan_tween.kill()

	_pan_tween = create_tween()
	_pan_tween.tween_property(self, "position", target_screen_pos, 0.3) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN_OUT)

	await _pan_tween.finished
	camera_centered.emit(tile_position)

## Get current camera view bounds in tile coordinates
func get_camera_bounds() -> Rect2i:
	var viewport_size = get_viewport().get_visible_rect().size
	var half_size = viewport_size / (2.0 * zoom)

	var top_left_screen = position - half_size
	var bottom_right_screen = position + half_size

	var top_left_tile = _screen_to_tile_position(top_left_screen)
	var bottom_right_tile = _screen_to_tile_position(bottom_right_screen)

	return Rect2i(
		top_left_tile.x, top_left_tile.y,
		bottom_right_tile.x - top_left_tile.x + 1,
		bottom_right_tile.y - top_left_tile.y + 1
	)

## Enable/disable edge scrolling
func enable_edge_scrolling(enabled: bool) -> void:
	edge_scrolling_enabled = enabled

## Set camera movement speed
func set_camera_speed(speed: float) -> void:
	camera_speed = speed

## Set map boundaries
func set_map_bounds(bounds: Rect2i) -> void:
	map_bounds = bounds

## Convert tile position to screen position
func _tile_to_screen_position(tile_pos: Vector3i) -> Vector2:
	return Vector2(
		tile_pos.x * TILE_SIZE + TILE_SIZE / 2,
		tile_pos.y * TILE_SIZE + TILE_SIZE / 2
	)

## Convert screen position to tile position
func _screen_to_tile_position(screen_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(screen_pos.x / TILE_SIZE),
		int(screen_pos.y / TILE_SIZE)
	)
