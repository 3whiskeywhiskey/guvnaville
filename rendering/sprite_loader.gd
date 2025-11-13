## SpriteLoader - Loads and caches all sprite assets
## Provides efficient sprite loading with caching and placeholder generation
class_name SpriteLoader
extends Node

# Cache for loaded sprites
var _tile_sprites: Dictionary = {}
var _unit_sprites: Dictionary = {}
var _is_tiles_loaded: bool = false
var _is_units_loaded: bool = false

# Constants
const TILE_SIZE: int = 64
const SPRITE_PATH_TILES: String = "res://assets/sprites/tiles/"
const SPRITE_PATH_UNITS: String = "res://assets/sprites/units/"

# Signals
signal assets_loaded()
signal loading_progress(current: int, total: int)

## Load all tile sprites into cache
func load_tile_sprites() -> Dictionary:
	if _is_tiles_loaded:
		return _tile_sprites

	# For MVP, generate placeholder tiles
	_tile_sprites = _generate_placeholder_tiles()
	_is_tiles_loaded = true

	return _tile_sprites

## Load all unit sprite animations
func load_unit_sprites() -> Dictionary:
	if _is_units_loaded:
		return _unit_sprites

	# For MVP, generate placeholder unit sprites
	_unit_sprites = _generate_placeholder_units()
	_is_units_loaded = true

	return _unit_sprites

## Get sprite for a specific tile type
func get_tile_sprite(tile_type: String) -> Texture2D:
	if not _is_tiles_loaded:
		load_tile_sprites()

	if tile_type in _tile_sprites:
		return _tile_sprites[tile_type]

	# Return default sprite if not found
	push_warning("SpriteLoader: Tile type '%s' not found, using default" % tile_type)
	return _tile_sprites.get("default", _create_placeholder_texture(Color.WHITE))

## Get animated sprite for a unit with faction colors
func get_unit_sprite(unit_type: String, faction_id: int) -> Texture2D:
	if not _is_units_loaded:
		load_unit_sprites()

	var key = "%s_%d" % [unit_type, faction_id]
	if key in _unit_sprites:
		return _unit_sprites[key]

	# Try without faction
	if unit_type in _unit_sprites:
		return _unit_sprites[unit_type]

	# Return default sprite if not found
	push_warning("SpriteLoader: Unit type '%s' not found, using default" % unit_type)
	return _unit_sprites.get("default", _create_placeholder_texture(Color.RED))

## Preload all assets at game startup (async)
func preload_all_assets() -> void:
	var start_time = Time.get_ticks_msec()

	load_tile_sprites()
	loading_progress.emit(1, 2)

	load_unit_sprites()
	loading_progress.emit(2, 2)

	var elapsed = Time.get_ticks_msec() - start_time
	print("SpriteLoader: All assets loaded in %d ms" % elapsed)

	assets_loaded.emit()

## Clear sprite cache (for memory management)
func clear_cache() -> void:
	_tile_sprites.clear()
	_unit_sprites.clear()
	_is_tiles_loaded = false
	_is_units_loaded = false
	print("SpriteLoader: Cache cleared")

## Generate placeholder tile sprites (colored squares)
func _generate_placeholder_tiles() -> Dictionary:
	var tiles = {}

	var tile_colors = {
		"residential": Color(0.2, 0.4, 0.8),  # Blue
		"commercial": Color(0.9, 0.8, 0.2),   # Yellow
		"industrial": Color(0.8, 0.5, 0.2),   # Orange
		"military": Color(0.8, 0.2, 0.2),     # Red
		"medical": Color(0.9, 0.9, 0.9),      # White
		"cultural": Color(0.6, 0.3, 0.7),     # Purple
		"infrastructure": Color(0.5, 0.5, 0.5), # Gray
		"ruins": Color(0.4, 0.3, 0.2),        # Brown
		"street": Color(0.3, 0.3, 0.3),       # Dark Gray
		"park": Color(0.2, 0.6, 0.3),         # Green
		"water": Color(0.2, 0.4, 0.6),        # Blue
		"rubble": Color(0.5, 0.4, 0.3),       # Light Brown
		"default": Color(0.7, 0.7, 0.7)       # Light Gray
	}

	for tile_type in tile_colors:
		tiles[tile_type] = _create_placeholder_texture(tile_colors[tile_type])

	return tiles

## Generate placeholder unit sprites (colored circles)
func _generate_placeholder_units() -> Dictionary:
	var units = {}

	# Basic unit types
	var unit_colors = {
		"militia": Color(0.6, 0.6, 0.8),
		"soldier": Color(0.4, 0.6, 0.4),
		"scout": Color(0.7, 0.7, 0.3),
		"sniper": Color(0.5, 0.3, 0.3),
		"medic": Color(0.9, 0.9, 0.9),
		"engineer": Color(0.8, 0.6, 0.2),
		"default": Color(0.8, 0.2, 0.2)
	}

	for unit_type in unit_colors:
		units[unit_type] = _create_placeholder_unit_texture(unit_colors[unit_type])

	# Generate faction variants (9 factions)
	var faction_hue_offsets = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
	for unit_type in unit_colors:
		for faction_id in range(9):
			var base_color = unit_colors[unit_type]
			var faction_color = _apply_faction_hue(base_color, faction_hue_offsets[faction_id])
			var key = "%s_%d" % [unit_type, faction_id]
			units[key] = _create_placeholder_unit_texture(faction_color)

	return units

## Create a placeholder texture with given color
func _create_placeholder_texture(color: Color) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)

	# Add a border for visibility
	var border_color = color.darkened(0.3)
	for x in range(TILE_SIZE):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, TILE_SIZE - 1, border_color)
	for y in range(TILE_SIZE):
		image.set_pixel(0, y, border_color)
		image.set_pixel(TILE_SIZE - 1, y, border_color)

	return ImageTexture.create_from_image(image)

## Create a placeholder unit texture (circle with border)
func _create_placeholder_unit_texture(color: Color) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent background

	# Draw a circle
	var center = TILE_SIZE / 2
	var radius = TILE_SIZE / 3

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var dx = x - center
			var dy = y - center
			var dist = sqrt(dx * dx + dy * dy)

			if dist < radius:
				image.set_pixel(x, y, color)
			elif dist < radius + 2:
				# Border
				image.set_pixel(x, y, color.darkened(0.5))

	return ImageTexture.create_from_image(image)

## Apply faction hue shift to a color
func _apply_faction_hue(color: Color, hue_offset: float) -> Color:
	var hsv = color
	hsv.h = fmod(hsv.h + hue_offset, 1.0)
	return hsv
