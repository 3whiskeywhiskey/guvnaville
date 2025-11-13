## TileRenderer - Renders a single chunk of tiles (20x20 tiles)
## Uses sprite batching for efficient rendering
class_name TileRenderer
extends Node2D

# Preload dependencies for Godot 4.5.1 compatibility
const SpriteLoader = preload("res://rendering/sprite_loader.gd")

# Constants
const CHUNK_SIZE: int = 20
const TILE_SIZE: int = 64

# Chunk data
var chunk_position: Vector2i
var tiles: Array = []
var is_initialized: bool = false
var is_dirty: bool = true

# Sprite batching
var _tile_sprites: Dictionary = {}  # tile_type -> Array[Sprite2D]
var _sprite_loader: SpriteLoader

## Initialize the chunk with tile data
func initialize(chunk_pos: Vector2i, chunk_tiles: Array, sprite_loader: SpriteLoader) -> void:
	chunk_position = chunk_pos
	tiles = chunk_tiles
	_sprite_loader = sprite_loader

	_create_tile_sprites()
	is_initialized = true
	is_dirty = false

## Update a single tile within this chunk
func update_tile_at(local_position: Vector2i, tile_data) -> void:
	if not is_initialized:
		push_warning("TileRenderer: Cannot update tile, chunk not initialized")
		return

	if local_position.x < 0 or local_position.x >= CHUNK_SIZE or \
	   local_position.y < 0 or local_position.y >= CHUNK_SIZE:
		push_warning("TileRenderer: Invalid local position %s" % local_position)
		return

	var index = local_position.y * CHUNK_SIZE + local_position.x
	if index < tiles.size():
		tiles[index] = tile_data
		is_dirty = true
		_update_single_tile_sprite(local_position, tile_data)

## Show or hide entire chunk (for culling)
func set_chunk_visible(is_visible: bool) -> void:
	visible = is_visible

## Check if chunk is within camera view
func is_in_view(camera_rect: Rect2i) -> bool:
	var chunk_rect = Rect2i(
		chunk_position * CHUNK_SIZE,
		Vector2i(CHUNK_SIZE, CHUNK_SIZE)
	)
	return camera_rect.intersects(chunk_rect)

## Redraw all tiles in chunk
func redraw() -> void:
	if not is_initialized:
		return

	# Clear existing sprites
	for child in get_children():
		child.queue_free()

	_tile_sprites.clear()

	# Recreate sprites
	_create_tile_sprites()
	is_dirty = false

## Create sprite instances for all tiles
func _create_tile_sprites() -> void:
	for y in range(CHUNK_SIZE):
		for x in range(CHUNK_SIZE):
			var index = y * CHUNK_SIZE + x
			if index >= tiles.size():
				continue

			var tile_data = tiles[index]
			var tile_type = _get_tile_type(tile_data)

			var sprite = Sprite2D.new()
			sprite.texture = _sprite_loader.get_tile_sprite(tile_type)
			sprite.centered = false

			# Position within chunk
			sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)

			# Set z_index based on tile properties
			sprite.z_index = 0

			add_child(sprite)

			# Add to batch dictionary
			if not tile_type in _tile_sprites:
				_tile_sprites[tile_type] = []
			_tile_sprites[tile_type].append(sprite)

## Update a single tile sprite
func _update_single_tile_sprite(local_position: Vector2i, tile_data) -> void:
	var index = local_position.y * CHUNK_SIZE + local_position.x

	# Find and update the sprite
	var children = get_children()
	if index < children.size():
		var sprite = children[index] as Sprite2D
		if sprite:
			var tile_type = _get_tile_type(tile_data)
			sprite.texture = _sprite_loader.get_tile_sprite(tile_type)

## Get tile type from tile data (handles both mock and real tiles)
func _get_tile_type(tile_data) -> String:
	if tile_data == null:
		return "default"

	# Handle dictionary
	if tile_data is Dictionary:
		return tile_data.get("tile_type", "default")

	# Handle object with properties
	if "tile_type" in tile_data:
		var tile_type = tile_data.tile_type
		if tile_type is int:
			# Convert enum to string
			return _tile_type_enum_to_string(tile_type)
		return str(tile_type).to_lower()

	return "default"

## Convert tile type enum to string
func _tile_type_enum_to_string(tile_type: int) -> String:
	# Tile type enum values
	const TILE_TYPES = [
		"residential", "commercial", "industrial", "military",
		"medical", "cultural", "infrastructure", "ruins",
		"street", "park"
	]

	if tile_type >= 0 and tile_type < TILE_TYPES.size():
		return TILE_TYPES[tile_type]

	return "default"

## Get memory usage estimate
func get_memory_usage() -> int:
	return tiles.size() * 100  # Rough estimate in bytes
