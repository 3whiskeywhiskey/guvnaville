## MovementEffect - Displays movement path with arrows
## Shows visual path for unit movement
class_name MovementEffect
extends Node2D

const TILE_SIZE: int = 64
const PATH_COLOR: Color = Color(0.2, 0.8, 1.0, 0.6)  # Light blue
const ARROW_SIZE: float = 8.0
const LINE_WIDTH: float = 4.0

var _path_lines: Array[Line2D] = []
var _current_path: Array[Vector3i] = []

## Show movement path
func show_path(path: Array) -> void:
	hide_path()

	if path.size() < 2:
		return

	_current_path.clear()
	for pos in path:
		if pos is Vector3i:
			_current_path.append(pos)

	_draw_path()

## Hide movement path
func hide_path() -> void:
	for line in _path_lines:
		line.queue_free()
	_path_lines.clear()
	_current_path.clear()

## Draw the path visualization
func _draw_path() -> void:
	for i in range(_current_path.size() - 1):
		var from = _current_path[i]
		var to = _current_path[i + 1]

		var line = Line2D.new()
		line.width = LINE_WIDTH
		line.default_color = PATH_COLOR

		var from_screen = _tile_to_screen_center(from)
		var to_screen = _tile_to_screen_center(to)

		line.add_point(from_screen)
		line.add_point(to_screen)

		add_child(line)
		_path_lines.append(line)

		# Add arrow at the end
		if i == _current_path.size() - 2:
			_draw_arrow(to_screen, (to_screen - from_screen).normalized())

## Draw arrow at path end
func _draw_arrow(pos: Vector2, direction: Vector2) -> void:
	var arrow = Line2D.new()
	arrow.width = LINE_WIDTH
	arrow.default_color = PATH_COLOR

	var perp = Vector2(-direction.y, direction.x)

	arrow.add_point(pos)
	arrow.add_point(pos - direction * ARROW_SIZE + perp * ARROW_SIZE / 2)
	arrow.add_point(pos)
	arrow.add_point(pos - direction * ARROW_SIZE - perp * ARROW_SIZE / 2)

	add_child(arrow)
	_path_lines.append(arrow)

## Convert tile position to screen center
func _tile_to_screen_center(tile_pos: Vector3i) -> Vector2:
	return Vector2(
		tile_pos.x * TILE_SIZE + TILE_SIZE / 2,
		tile_pos.y * TILE_SIZE + TILE_SIZE / 2
	)
