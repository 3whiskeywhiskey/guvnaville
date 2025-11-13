## MapView - Main map view orchestrator
## Manages tile renderers, unit renderers, camera, fog of war, and effects
class_name MapView
extends Node2D

# Constants
const CHUNK_SIZE: int = 20
const TILE_SIZE: int = 64
const TARGET_FPS: int = 60
const MAX_FRAME_TIME_MS: float = 16.67

# Enums
enum RenderMode {
	NORMAL,
	WIREFRAME,
	CHUNK_BOUNDS,
	FOG_DEBUG
}

# Components
var camera_controller: CameraController
var sprite_loader: SpriteLoader
var selection_effect: SelectionEffect
var movement_effect: MovementEffect
var attack_effect: AttackEffect
var fog_renderer: FogRenderer

# Map data
var map_data = null  # MapData instance
var map_size: Vector3i = Vector3i(200, 200, 3)

# Chunks
var chunks: Dictionary = {}  # Vector2i -> ChunkData
var visible_chunks: Array[Vector2i] = []

# Units
var unit_renderers: Dictionary = {}  # unit_id -> UnitRenderer
var units_at_position: Dictionary = {}  # Vector3i -> Array[int (unit_ids)]

# Highlights
var active_highlights: Array[ColorRect] = []
var highlight_pool: Array[ColorRect] = []  # Pool for reusing highlight rectangles
const HIGHLIGHT_POOL_SIZE: int = 200  # Pre-allocate highlight pool

# State
var current_render_mode: RenderMode = RenderMode.NORMAL
var is_initialized: bool = false

# Performance caching
var _last_camera_bounds: Rect2i = Rect2i()
var _camera_moved_threshold: int = 10  # Only update chunks if camera moves this many pixels

# Performance stats
var render_stats: Dictionary = {
	"fps": 0,
	"frame_time_ms": 0.0,
	"visible_tiles": 0,
	"visible_units": 0,
	"draw_calls": 0,
	"chunks_rendered": 0
}

# Signals
signal map_rendered()
signal chunk_loaded(chunk_position: Vector2i)
signal chunk_unloaded(chunk_position: Vector2i)
signal camera_moved(new_position: Vector2)
signal camera_zoomed(zoom_level: int)
signal camera_centered(tile_position: Vector3i)
signal tile_clicked(tile_position: Vector3i, button_index: int)
signal tile_hovered(tile_position: Vector3i)
signal unit_clicked(unit_id: int, button_index: int)
signal unit_hovered(unit_id: int)
signal attack_animation_complete(attacker_id: int, defender_id: int)
signal movement_animation_complete(unit_id: int)
signal highlights_cleared()
signal performance_warning(stats: Dictionary)

class ChunkData:
	var position: Vector2i
	var tiles: Array
	var renderer: TileRenderer
	var is_visible: bool = false
	var is_dirty: bool = true

	func _init(pos: Vector2i, tile_array: Array, rend: TileRenderer):
		position = pos
		tiles = tile_array
		renderer = rend

func _ready() -> void:
	_initialize_components()

func _process(_delta: float) -> void:
	_update_visible_chunks()
	_update_performance_stats()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var tile_pos = get_tile_at_screen_position(event.position)
			if tile_pos.x >= 0:
				tile_clicked.emit(tile_pos, MOUSE_BUTTON_LEFT)

## Initialize map view with complete map data
func render_map(map_data_instance) -> void:
	map_data = map_data_instance

	# Get map size
	if map_data and "get_map_size" in map_data:
		map_size = map_data.get_map_size()

	var start_time = Time.get_ticks_msec()

	# Create chunks
	_create_chunks()

	# Set fog renderer map size
	fog_renderer.set_map_size(map_size)

	# Set camera bounds
	camera_controller.set_map_bounds(Rect2i(0, 0, map_size.x, map_size.y))

	var elapsed = Time.get_ticks_msec() - start_time
	print("MapView: Map rendered in %d ms" % elapsed)

	is_initialized = true
	map_rendered.emit()

## Render all units on the map
func render_units(units: Array) -> void:
	var start_time = Time.get_ticks_msec()

	for unit in units:
		var unit_id = _get_unit_property(unit, "id", -1)
		if unit_id < 0:
			continue

		if unit_id in unit_renderers:
			# Update existing renderer
			var renderer = unit_renderers[unit_id]
			var new_pos = _get_unit_property(unit, "position", Vector3i.ZERO)
			renderer.update_position(new_pos, false)
		else:
			# Create new renderer
			var renderer = UnitRenderer.new()
			renderer.initialize(unit, sprite_loader)
			add_child(renderer)
			unit_renderers[unit_id] = renderer

			# Track position
			var pos = _get_unit_property(unit, "position", Vector3i.ZERO)
			if not pos in units_at_position:
				units_at_position[pos] = []
			units_at_position[pos].append(unit_id)

	var elapsed = Time.get_ticks_msec() - start_time
	print("MapView: %d units rendered in %d ms" % [units.size(), elapsed])

## Update fog of war visualization for a specific faction
## OPTIMIZED: Only creates visibility map for tiles that need it
func render_fog_of_war(faction_id: int, visible_tiles: Array) -> void:
	# Build visibility map - OPTIMIZED: Only store visible tiles instead of all tiles
	var visibility_map = {}

	# Mark visible tiles (skip the expensive iteration over all tiles)
	for tile_pos in visible_tiles:
		if tile_pos is Vector3i:
			visibility_map[tile_pos] = FogRenderer.VisibilityLevel.VISIBLE

	# Render fog
	fog_renderer.render_fog(faction_id, visibility_map)

	# Hide enemy units in fog - OPTIMIZED: Only check units, not all tiles
	for unit_id in unit_renderers:
		var renderer = unit_renderers[unit_id]
		var unit_pos = renderer.current_position
		# Unit is visible only if its position is in the visibility_map
		var is_visible = visibility_map.has(unit_pos) and visibility_map[unit_pos] == FogRenderer.VisibilityLevel.VISIBLE
		renderer.set_unit_visible(is_visible)

## Update a single tile's rendering
func update_tile(position: Vector3i, tile_data) -> void:
	if not is_initialized:
		return

	# Find chunk containing this tile
	var chunk_pos = _get_chunk_for_tile(position)
	if not chunk_pos in chunks:
		push_warning("MapView: Chunk not found for tile at %s" % position)
		return

	var chunk = chunks[chunk_pos]
	var local_pos = _get_local_position(position, chunk_pos)

	chunk.renderer.update_tile_at(local_pos, tile_data)
	chunk.is_dirty = true

## Update a single unit's position or state
func update_unit(unit_id: int, new_position: Vector3i) -> void:
	if not unit_id in unit_renderers:
		push_warning("MapView: Unit %d not found" % unit_id)
		return

	var renderer = unit_renderers[unit_id]
	var old_position = renderer.current_position

	# Update position tracking
	if old_position in units_at_position:
		units_at_position[old_position].erase(unit_id)

	if not new_position in units_at_position:
		units_at_position[new_position] = []
	units_at_position[new_position].append(unit_id)

	# Animate movement
	await renderer.update_position(new_position, true)
	movement_animation_complete.emit(unit_id)

## Move camera by delta amount
func move_camera(delta: Vector2) -> void:
	camera_controller.move_camera(delta)

## Change camera zoom level
func zoom_camera(zoom_delta: float) -> void:
	camera_controller.zoom_camera(int(zoom_delta))

## Center camera on a specific tile position
func center_camera_on(tile_position: Vector3i) -> void:
	await camera_controller.center_camera_on(tile_position)
	camera_centered.emit(tile_position)

## Highlight multiple tiles with a colored overlay
## OPTIMIZED: Uses object pooling to reuse highlight rectangles
func highlight_tiles(positions: Array, color: Color) -> void:
	clear_highlights()

	for pos in positions:
		if not pos is Vector3i:
			continue

		var highlight: ColorRect
		# Try to get from pool first (object pooling optimization)
		if highlight_pool.size() > 0:
			highlight = highlight_pool.pop_back()
			highlight.visible = true
		else:
			# Pool exhausted, create new one
			highlight = ColorRect.new()
			highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
			highlight.z_index = 5  # Above tiles, below units
			add_child(highlight)

		highlight.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
		highlight.color = color
		active_highlights.append(highlight)

## Remove all tile highlights
## OPTIMIZED: Returns highlights to pool instead of destroying them
func clear_highlights() -> void:
	for highlight in active_highlights:
		# Return to pool instead of destroying (object pooling optimization)
		highlight.visible = false
		if highlight_pool.size() < HIGHLIGHT_POOL_SIZE:
			highlight_pool.append(highlight)
		else:
			highlight.queue_free()  # Pool is full, destroy it

	active_highlights.clear()
	highlights_cleared.emit()

## Display a visual path showing unit movement
func show_movement_path(path: Array) -> void:
	movement_effect.show_path(path)

## Remove the currently displayed movement path
func clear_movement_path() -> void:
	movement_effect.hide_path()

## Play a visual attack animation between two positions
func play_attack_animation(attacker_pos: Vector3i, defender_pos: Vector3i, attack_type: String) -> void:
	match attack_type:
		"melee":
			await attack_effect.play_melee_attack(attacker_pos, defender_pos)
		"ranged", "artillery":
			await attack_effect.play_ranged_attack(attacker_pos, defender_pos)
		_:
			await attack_effect.play_melee_attack(attacker_pos, defender_pos)

	attack_animation_complete.emit(-1, -1)  # TODO: Pass actual IDs

## Convert screen coordinates to tile position (for mouse clicks)
func get_tile_at_screen_position(screen_pos: Vector2) -> Vector3i:
	# Account for camera position and zoom
	var world_pos = screen_pos + camera_controller.position - get_viewport_rect().size / 2
	world_pos = world_pos / camera_controller.zoom

	var tile_x = int(world_pos.x / TILE_SIZE)
	var tile_y = int(world_pos.y / TILE_SIZE)

	# Check bounds
	if tile_x < 0 or tile_x >= map_size.x or tile_y < 0 or tile_y >= map_size.y:
		return Vector3i(-1, -1, -1)

	return Vector3i(tile_x, tile_y, 0)  # Ground level

## Get current visible area in tile coordinates
func get_visible_bounds() -> Rect2i:
	return camera_controller.get_camera_bounds()

## Change rendering mode for debugging
func set_render_mode(mode: RenderMode) -> void:
	current_render_mode = mode
	# TODO: Implement different render modes

## Initialize all components
func _initialize_components() -> void:
	# Create sprite loader
	sprite_loader = SpriteLoader.new()
	add_child(sprite_loader)
	sprite_loader.preload_all_assets()

	# Create camera
	camera_controller = CameraController.new()
	camera_controller.enabled = true
	add_child(camera_controller)
	camera_controller.camera_moved.connect(_on_camera_moved)
	camera_controller.camera_zoomed.connect(_on_camera_zoomed)

	# Create effects
	selection_effect = SelectionEffect.new()
	add_child(selection_effect)

	movement_effect = MovementEffect.new()
	add_child(movement_effect)

	attack_effect = AttackEffect.new()
	add_child(attack_effect)

	fog_renderer = FogRenderer.new()
	add_child(fog_renderer)

	# Pre-allocate highlight pool for performance
	_initialize_highlight_pool()

## Create chunks for the map
func _create_chunks() -> void:
	var chunks_x = ceili(float(map_size.x) / CHUNK_SIZE)
	var chunks_y = ceili(float(map_size.y) / CHUNK_SIZE)

	print("MapView: Creating %dx%d = %d chunks" % [chunks_x, chunks_y, chunks_x * chunks_y])

	for cx in range(chunks_x):
		for cy in range(chunks_y):
			var chunk_pos = Vector2i(cx, cy)
			var chunk_tiles = _get_tiles_for_chunk(chunk_pos)

			var renderer = TileRenderer.new()
			renderer.position = Vector2(cx * CHUNK_SIZE * TILE_SIZE, cy * CHUNK_SIZE * TILE_SIZE)
			renderer.initialize(chunk_pos, chunk_tiles, sprite_loader)
			add_child(renderer)

			var chunk_data = ChunkData.new(chunk_pos, chunk_tiles, renderer)
			chunks[chunk_pos] = chunk_data

## Get tiles for a specific chunk
func _get_tiles_for_chunk(chunk_pos: Vector2i) -> Array:
	var tiles = []

	for y in range(CHUNK_SIZE):
		for x in range(CHUNK_SIZE):
			var tile_x = chunk_pos.x * CHUNK_SIZE + x
			var tile_y = chunk_pos.y * CHUNK_SIZE + y

			if tile_x >= map_size.x or tile_y >= map_size.y:
				tiles.append(null)
				continue

			var tile_pos = Vector3i(tile_x, tile_y, 0)

			# Get tile from map data if available
			if map_data and "get_tile" in map_data:
				var tile = map_data.get_tile(tile_pos)
				tiles.append(tile)
			else:
				# Mock tile for testing
				tiles.append({
					"position": tile_pos,
					"tile_type": "default"
				})

	return tiles

## Update visible chunks based on camera position
## OPTIMIZED: Only updates if camera moved significantly, reduces per-frame overhead
func _update_visible_chunks() -> void:
	if not is_initialized:
		return

	var camera_bounds = camera_controller.get_camera_bounds()

	# OPTIMIZATION: Skip update if camera hasn't moved much
	if not _camera_moved_significantly(camera_bounds):
		return

	_last_camera_bounds = camera_bounds
	var new_visible_chunks: Array[Vector2i] = []

	# OPTIMIZATION: Calculate chunk bounds from camera bounds to avoid checking all chunks
	var min_chunk_x = max(0, camera_bounds.position.x / CHUNK_SIZE)
	var max_chunk_x = min((camera_bounds.position.x + camera_bounds.size.x) / CHUNK_SIZE + 1, ceili(float(map_size.x) / CHUNK_SIZE))
	var min_chunk_y = max(0, camera_bounds.position.y / CHUNK_SIZE)
	var max_chunk_y = min((camera_bounds.position.y + camera_bounds.size.y) / CHUNK_SIZE + 1, ceili(float(map_size.y) / CHUNK_SIZE))

	# Only check chunks that could be visible based on camera bounds
	for cx in range(min_chunk_x, max_chunk_x):
		for cy in range(min_chunk_y, max_chunk_y):
			var chunk_pos = Vector2i(cx, cy)
			if not chunk_pos in chunks:
				continue

			var chunk = chunks[chunk_pos]
			new_visible_chunks.append(chunk_pos)

			# Show chunk if not visible
			if not chunk.is_visible:
				chunk.renderer.set_chunk_visible(true)
				chunk.is_visible = true
				chunk_loaded.emit(chunk_pos)

	# Hide chunks not in view
	for chunk_pos in visible_chunks:
		if not chunk_pos in new_visible_chunks:
			var chunk = chunks[chunk_pos]
			chunk.renderer.set_chunk_visible(false)
			chunk.is_visible = false
			chunk_unloaded.emit(chunk_pos)

	visible_chunks = new_visible_chunks
	render_stats["chunks_rendered"] = visible_chunks.size()

## Update performance statistics
func _update_performance_stats() -> void:
	render_stats["fps"] = Engine.get_frames_per_second()
	render_stats["frame_time_ms"] = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	render_stats["visible_tiles"] = visible_chunks.size() * CHUNK_SIZE * CHUNK_SIZE
	render_stats["visible_units"] = unit_renderers.size()

	# Warn if performance drops
	if render_stats["fps"] < 30:
		performance_warning.emit(render_stats)

## Get chunk position for a tile
func _get_chunk_for_tile(tile_pos: Vector3i) -> Vector2i:
	return Vector2i(tile_pos.x / CHUNK_SIZE, tile_pos.y / CHUNK_SIZE)

## Get local position within chunk
func _get_local_position(tile_pos: Vector3i, chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		tile_pos.x - chunk_pos.x * CHUNK_SIZE,
		tile_pos.y - chunk_pos.y * CHUNK_SIZE
	)

## Get property from unit data (handles both dictionary and object)
func _get_unit_property(unit_data, property: String, default_value):
	if unit_data == null:
		return default_value

	if unit_data is Dictionary:
		return unit_data.get(property, default_value)

	if property in unit_data:
		return unit_data.get(property)

	return default_value

## Signal handlers
func _on_camera_moved(new_position: Vector2) -> void:
	camera_moved.emit(new_position)

func _on_camera_zoomed(zoom_level: int) -> void:
	camera_zoomed.emit(zoom_level)

# ============================================================================
# PERFORMANCE OPTIMIZATION HELPERS
# ============================================================================

## Initialize highlight pool for object pooling
func _initialize_highlight_pool() -> void:
	highlight_pool.clear()
	for i in range(HIGHLIGHT_POOL_SIZE):
		var highlight = ColorRect.new()
		highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
		highlight.z_index = 5
		highlight.visible = false
		add_child(highlight)
		highlight_pool.append(highlight)

## Check if camera moved significantly enough to warrant chunk update
func _camera_moved_significantly(new_bounds: Rect2i) -> bool:
	# First update always counts
	if _last_camera_bounds.size == Vector2i.ZERO:
		return true

	# Check if camera moved more than threshold
	var pos_diff = new_bounds.position - _last_camera_bounds.position
	var moved_distance = abs(pos_diff.x) + abs(pos_diff.y)

	# Also update if size changed (zoom)
	var size_changed = new_bounds.size != _last_camera_bounds.size

	return moved_distance > _camera_moved_threshold or size_changed
