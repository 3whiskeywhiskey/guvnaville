## FogRenderer - Renders fog of war overlay
## Manages three visibility layers: visible, explored, hidden
class_name FogRenderer
extends Node2D

enum VisibilityLevel {
	HIDDEN = 0,     # Never seen (black)
	EXPLORED = 1,   # Previously seen (greyed)
	VISIBLE = 2     # Currently visible (clear)
}

const TILE_SIZE: int = 64
const FOG_COLOR: Color = Color(0.0, 0.0, 0.0, 0.8)
const EXPLORED_COLOR: Color = Color(0.0, 0.0, 0.0, 0.4)

var _fog_tiles: Dictionary = {}  # Vector3i -> ColorRect
var _map_size: Vector3i = Vector3i(200, 200, 3)
var _render_bounds: Rect2i = Rect2i()  # Only render fog within these bounds

## Render fog of war for faction
func render_fog(faction_id: int, visibility_map: Dictionary) -> void:
	# Clear existing fog tiles
	_clear_fog()

	# Determine render bounds - if not set, use a reasonable default around visible tiles
	var bounds = _render_bounds
	if bounds.size.x == 0 or bounds.size.y == 0:
		# Calculate bounds from visible tiles with padding
		if visibility_map.size() > 0:
			var min_x = _map_size.x
			var min_y = _map_size.y
			var max_x = 0
			var max_y = 0

			for pos in visibility_map.keys():
				if pos is Vector3i:
					min_x = min(min_x, pos.x)
					min_y = min(min_y, pos.y)
					max_x = max(max_x, pos.x)
					max_y = max(max_y, pos.y)

			# Add padding around visible area
			var padding = 30
			bounds = Rect2i(
				max(0, min_x - padding),
				max(0, min_y - padding),
				min(_map_size.x, max_x + padding * 2),
				min(_map_size.y, max_y + padding * 2)
			)
		else:
			# No visible tiles, render small area around origin
			bounds = Rect2i(0, 0, 50, 50)

	# Create fog tiles based on visibility - only within render bounds
	for x in range(bounds.position.x, min(bounds.position.x + bounds.size.x, _map_size.x)):
		for y in range(bounds.position.y, min(bounds.position.y + bounds.size.y, _map_size.y)):
			var pos = Vector3i(x, y, 0)  # Ground level for fog
			var visibility = visibility_map.get(pos, VisibilityLevel.HIDDEN)

			if visibility == VisibilityLevel.VISIBLE:
				# No fog
				continue
			elif visibility == VisibilityLevel.EXPLORED:
				_create_fog_tile(pos, EXPLORED_COLOR)
			else:
				# Hidden
				_create_fog_tile(pos, FOG_COLOR)

## Update fog for specific positions
func update_fog_positions(positions: Array, visibility: VisibilityLevel) -> void:
	for pos in positions:
		if not pos is Vector3i:
			continue

		if visibility == VisibilityLevel.VISIBLE:
			# Remove fog tile
			if pos in _fog_tiles:
				_fog_tiles[pos].queue_free()
				_fog_tiles.erase(pos)
		elif visibility == VisibilityLevel.EXPLORED:
			_update_fog_tile(pos, EXPLORED_COLOR)
		else:
			_update_fog_tile(pos, FOG_COLOR)

## Set map size for fog rendering
func set_map_size(size: Vector3i) -> void:
	_map_size = size

## Set render bounds to limit fog tile creation (performance optimization)
func set_render_bounds(bounds: Rect2i) -> void:
	_render_bounds = bounds

## Clear all fog tiles
func _clear_fog() -> void:
	for tile in _fog_tiles.values():
		tile.queue_free()
	_fog_tiles.clear()

## Create a fog tile at position
func _create_fog_tile(pos: Vector3i, color: Color) -> void:
	if pos in _fog_tiles:
		_fog_tiles[pos].color = color
		return

	var fog_tile = ColorRect.new()
	fog_tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	fog_tile.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
	fog_tile.color = color
	fog_tile.z_index = 10  # Above tiles and units, but below UI
	fog_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input
	add_child(fog_tile)

	_fog_tiles[pos] = fog_tile

## Update existing fog tile color
func _update_fog_tile(pos: Vector3i, color: Color) -> void:
	if pos in _fog_tiles:
		_fog_tiles[pos].color = color
	else:
		_create_fog_tile(pos, color)
