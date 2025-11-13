## SelectionEffect - Displays selection highlight on a tile
## Shows animated border around selected tile
class_name SelectionEffect
extends Node2D

const TILE_SIZE: int = 64
const BORDER_WIDTH: float = 3.0
const PULSE_DURATION: float = 1.0

var _line: Line2D
var _pulse_tween: Tween
var _current_position: Vector3i = Vector3i(-1, -1, -1)

func _ready() -> void:
	_create_selection_border()
	visible = false

## Show selection highlight on a tile
func show_selection(tile_position: Vector3i) -> void:
	_current_position = tile_position
	position = _tile_to_screen_position(tile_position)
	visible = true

	# Start pulsing animation
	_start_pulse_animation()

## Hide selection highlight
func hide_selection() -> void:
	visible = false
	_current_position = Vector3i(-1, -1, -1)

	if _pulse_tween:
		_pulse_tween.kill()

## Create the selection border visual
func _create_selection_border() -> void:
	_line = Line2D.new()
	_line.width = BORDER_WIDTH
	_line.default_color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow
	_line.closed = true

	# Define rectangle points
	_line.add_point(Vector2(0, 0))
	_line.add_point(Vector2(TILE_SIZE, 0))
	_line.add_point(Vector2(TILE_SIZE, TILE_SIZE))
	_line.add_point(Vector2(0, TILE_SIZE))

	add_child(_line)

## Start pulsing animation
func _start_pulse_animation() -> void:
	if _pulse_tween:
		_pulse_tween.kill()

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(_line, "default_color:a", 0.4, PULSE_DURATION / 2)
	_pulse_tween.tween_property(_line, "default_color:a", 0.8, PULSE_DURATION / 2)

## Convert tile position to screen position
func _tile_to_screen_position(tile_pos: Vector3i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
