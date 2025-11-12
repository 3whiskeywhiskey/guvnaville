# Rendering System Interface Contract

**Module**: Rendering System
**Agent**: Agent 10
**Layer**: 4 (Presentation)
**Dependencies**: Core, Map, Units
**Version**: 1.0
**Last Updated**: 2025-11-12

---

## Table of Contents

1. [Overview](#overview)
2. [Module Structure](#module-structure)
3. [Dependencies](#dependencies)
4. [Public Interfaces](#public-interfaces)
5. [Data Structures](#data-structures)
6. [Events](#events)
7. [Performance Requirements](#performance-requirements)
8. [Error Handling](#error-handling)
9. [Testing Requirements](#testing-requirements)
10. [Implementation Notes](#implementation-notes)

---

## Overview

The Rendering System is responsible for all visual presentation of the game world, including:
- Map rendering (tiles and terrain)
- Unit rendering (sprites and animations)
- Camera controls (pan, zoom, and centering)
- Fog of war visualization
- Visual effects (selection highlights, movement paths, animations)
- Performance optimization (culling, chunking, batching)

The Rendering System is a **read-only consumer** of game state. It does not modify game logic, only presents it visually.

### Key Design Principles
- **Separation of concerns**: Rendering is completely decoupled from game logic
- **Performance-first**: Maintain 60 FPS at 1920x1080 resolution
- **Event-driven updates**: React to game state changes via EventBus
- **Chunk-based rendering**: Divide large maps into manageable chunks
- **Frustum culling**: Only render visible elements

---

## Module Structure

```
ui/map/
├── map_view.gd            # Main map view orchestrator
├── tile_renderer.gd       # Individual tile rendering
├── unit_renderer.gd       # Unit sprite rendering
└── camera_controller.gd   # Camera movement and zoom

rendering/
├── sprite_loader.gd       # Asset loading and caching
└── effects/               # Visual effects
    ├── selection_effect.gd      # Tile selection highlight
    ├── movement_effect.gd       # Movement path display
    ├── attack_effect.gd         # Attack animations
    └── fog_renderer.gd          # Fog of war overlay
```

---

## Dependencies

### Required Modules

**Core Foundation** (Layer 0):
- `EventBus`: Subscribe to game state change events
- `GameState`: Read current game state
- `DataLoader`: Load sprite and visual data

**Map System** (Layer 1):
- `MapData`: Access tile information
- `Tile`: Individual tile data
- `FogOfWar`: Visibility information per faction

**Unit System** (Layer 2):
- `Unit`: Unit data for rendering
- `UnitManager`: Access to all units

### Import Examples
```gdscript
# Godot autoloads (singletons)
var event_bus = EventBus
var game_state = GameManager.state
var data_loader = DataLoader

# System references
var map_data: MapData
var unit_manager: UnitManager
```

---

## Public Interfaces

### 1. MapView Class

**File**: `ui/map/map_view.gd`

**Purpose**: Main orchestrator for map rendering. Manages tile renderers, unit renderers, camera, and effects.

#### Public Methods

##### `render_map(map_data: MapData) -> void`
Initializes the map view with complete map data. Creates all tile renderers organized in chunks.

**Parameters**:
- `map_data`: MapData instance containing all tile information

**Behavior**:
- Divides map into 20x20 tile chunks
- Creates TileRenderer instances for each chunk
- Sets up spatial partitioning for efficient queries
- Initializes fog of war overlay
- Emits `map_rendered` signal when complete

**Performance**: < 500ms for 200x200 map (40,000 tiles)

**Example**:
```gdscript
var map_view = MapView.new()
map_view.render_map(game_state.world_state.map)
```

---

##### `render_units(units: Array[Unit]) -> void`
Renders all units on the map. Updates existing unit sprites or creates new ones.

**Parameters**:
- `units`: Array of Unit instances to render

**Behavior**:
- Creates or updates UnitRenderer for each unit
- Positions units at their tile coordinates
- Applies faction colors/insignias
- Updates Z-index for proper layering
- Skips units in fog of war

**Performance**: < 50ms for 200 units

**Example**:
```gdscript
map_view.render_units(game_state.get_all_units())
```

---

##### `render_fog_of_war(faction_id: int, visible_tiles: Array[Vector3i]) -> void`
Updates fog of war visualization for a specific faction.

**Parameters**:
- `faction_id`: ID of faction whose fog of war to render
- `visible_tiles`: Array of tile positions visible to faction

**Behavior**:
- Creates three visibility layers:
  - **Visible**: Clear view (current visibility)
  - **Explored**: Greyed out (previously seen)
  - **Hidden**: Completely dark (never seen)
- Updates fog overlay textures
- Hides enemy units in fog
- Shows last known state for explored tiles

**Performance**: < 100ms per faction update

**Example**:
```gdscript
var visible = fog_of_war.get_visible_tiles(player_faction_id)
map_view.render_fog_of_war(player_faction_id, visible)
```

---

##### `update_tile(position: Vector3i, tile: Tile) -> void`
Updates a single tile's rendering (e.g., after terrain change, ownership change).

**Parameters**:
- `position`: 3D position of tile (x, y, z where z is elevation level)
- `tile`: Updated tile data

**Behavior**:
- Finds tile renderer for this position
- Updates tile sprite based on tile type
- Updates terrain overlay
- Updates ownership indicator (border color)
- Updates resource indicators if present
- Marks chunk as dirty for redraw

**Performance**: < 1ms per tile

**Example**:
```gdscript
# When tile is captured
map_view.update_tile(Vector3i(10, 15, 1), updated_tile)
```

---

##### `update_unit(unit_id: int, position: Vector3i) -> void`
Updates a single unit's position or state.

**Parameters**:
- `unit_id`: Unique unit identifier
- `position`: New 3D position for unit

**Behavior**:
- Finds UnitRenderer for this unit ID
- Animates movement from old to new position (smooth transition)
- Updates unit sprite if state changed (HP, status effects)
- Updates Z-index based on elevation
- Plays movement sound effect (optional)

**Performance**: < 5ms per unit

**Example**:
```gdscript
# After unit moves
map_view.update_unit(unit.id, new_position)
```

---

##### `move_camera(delta: Vector2) -> void`
Moves camera by a delta amount in screen space.

**Parameters**:
- `delta`: Movement vector in pixels (x, y)

**Behavior**:
- Translates camera position by delta
- Clamps to map boundaries
- Updates visible chunk list
- Triggers culling update
- Smooth interpolation for continuous movement

**Performance**: < 1ms (60 FPS compatible)

**Example**:
```gdscript
# WASD movement
if Input.is_action_pressed("ui_right"):
    map_view.move_camera(Vector2(5, 0))
```

---

##### `zoom_camera(zoom_delta: float) -> void`
Changes camera zoom level.

**Parameters**:
- `zoom_delta`: Zoom increment (+1 = zoom in, -1 = zoom out)

**Behavior**:
- Supports 3 zoom levels:
  - **Level 1**: 1x (standard, see full tiles)
  - **Level 2**: 1.5x (closer view)
  - **Level 3**: 2x (maximum zoom)
- Snaps to discrete zoom levels (no continuous zoom)
- Updates tile LOD (Level of Detail) based on zoom
- Recalculates visible area
- Maintains focus point at screen center

**Performance**: < 10ms per zoom change

**Example**:
```gdscript
# Mouse wheel zoom
if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
        map_view.zoom_camera(1)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        map_view.zoom_camera(-1)
```

---

##### `center_camera_on(position: Vector3i) -> void`
Centers camera on a specific tile position with smooth animation.

**Parameters**:
- `position`: 3D tile position to center on

**Behavior**:
- Converts tile position to screen coordinates
- Animates camera to center this position
- Animation duration: 0.3 seconds (configurable)
- Uses ease-in-out interpolation
- Emits `camera_centered` signal when complete

**Performance**: < 5ms (animation is async)

**Example**:
```gdscript
# Double-click on tile or "Go to unit" button
map_view.center_camera_on(selected_unit.position)
```

---

##### `highlight_tiles(positions: Array[Vector3i], color: Color) -> void`
Highlights multiple tiles with a colored overlay (e.g., movement range, attack range).

**Parameters**:
- `positions`: Array of tile positions to highlight
- `color`: Highlight color with alpha (e.g., Color(0, 1, 0, 0.3) for green)

**Behavior**:
- Creates overlay sprites for each position
- Applies color modulation
- Adds to highlight layer (above tiles, below units)
- Existing highlights are cleared before applying new ones
- Respects fog of war (don't highlight invisible tiles)

**Performance**: < 20ms for 100 tiles

**Example**:
```gdscript
# Show movement range
var movement_range = pathfinding.get_reachable_tiles(unit.position, unit.movement)
map_view.highlight_tiles(movement_range, Color(0, 0.5, 1, 0.4))
```

---

##### `clear_highlights() -> void`
Removes all tile highlights.

**Behavior**:
- Removes all highlight overlay sprites
- Frees memory for highlight objects
- Emits `highlights_cleared` signal

**Performance**: < 5ms

**Example**:
```gdscript
# When unit is deselected
map_view.clear_highlights()
```

---

##### `show_movement_path(path: Array[Vector3i]) -> void`
Displays a visual path showing unit movement.

**Parameters**:
- `path`: Ordered array of tile positions forming the path

**Behavior**:
- Creates connected path overlay
- Uses directional arrows or lines
- Highlights start (green) and end (red) positions
- Shows path cost/movement points required (optional)
- Animated dashed line effect
- Clears previous path automatically

**Performance**: < 15ms for 20-tile path

**Example**:
```gdscript
# When player hovers over destination tile
var path = pathfinding.find_path(unit.position, target_position)
if path:
    map_view.show_movement_path(path)
```

---

##### `clear_movement_path() -> void`
Removes the currently displayed movement path.

**Behavior**:
- Removes path overlay sprites
- Stops path animation
- Frees path resources

**Performance**: < 2ms

---

##### `play_attack_animation(attacker_pos: Vector3i, defender_pos: Vector3i, attack_type: String) -> void`
Plays a visual attack animation between two positions.

**Parameters**:
- `attacker_pos`: Position of attacking unit
- `defender_pos`: Position of defending unit
- `attack_type`: Type of attack ("melee", "ranged", "artillery")

**Behavior**:
- Creates projectile or effect between positions
- Plays attack sound effect
- Triggers hit animation at defender position
- Waits for animation to complete (async)
- Emits `attack_animation_complete` signal

**Performance**: Animation duration 0.5-1.0 seconds

**Example**:
```gdscript
await map_view.play_attack_animation(
    attacker.position,
    defender.position,
    "ranged"
)
# Continue with combat resolution
```

---

##### `get_tile_at_screen_position(screen_pos: Vector2) -> Vector3i`
Converts screen coordinates to tile position (for mouse clicks).

**Parameters**:
- `screen_pos`: Mouse position in screen pixels

**Returns**:
- `Vector3i`: Tile position, or Vector3i(-1, -1, -1) if out of bounds

**Behavior**:
- Converts screen space to world space
- Accounts for camera position and zoom
- Handles isometric/orthogonal projection
- Returns null equivalent if clicking outside map

**Performance**: < 1ms

**Example**:
```gdscript
func _on_map_clicked(event: InputEventMouseButton):
    var tile_pos = map_view.get_tile_at_screen_position(event.position)
    if tile_pos.x >= 0:
        handle_tile_click(tile_pos)
```

---

##### `get_visible_bounds() -> Rect2i`
Returns the current visible area in tile coordinates.

**Returns**:
- `Rect2i`: Rectangle defining visible area (x, y, width, height)

**Behavior**:
- Calculates based on camera position and zoom
- Used for culling and chunk loading
- Updates when camera moves or zooms

**Performance**: < 1ms

---

##### `set_render_mode(mode: RenderMode) -> void`
Changes rendering mode for debugging or performance.

**Parameters**:
- `mode`: Enum value (NORMAL, WIREFRAME, CHUNK_BOUNDS, FOG_DEBUG)

**Behavior**:
- NORMAL: Standard rendering
- WIREFRAME: Show tile boundaries
- CHUNK_BOUNDS: Highlight chunk borders
- FOG_DEBUG: Show fog of war layers with colors

**Performance**: < 5ms to switch modes

---

### 2. TileRenderer Class

**File**: `ui/map/tile_renderer.gd`

**Purpose**: Renders a single chunk of tiles (20x20 tiles).

#### Public Methods

##### `initialize(chunk_position: Vector2i, tiles: Array[Tile]) -> void`
Sets up a tile chunk for rendering.

**Parameters**:
- `chunk_position`: Chunk coordinates (not tile coordinates)
- `tiles`: Array of 400 tiles (20x20) in this chunk

**Behavior**:
- Creates sprite instances for all tiles
- Batches tiles by type for efficient rendering
- Sets up texture atlases
- Marks chunk as ready to render

**Performance**: < 50ms per chunk

---

##### `update_tile_at(local_position: Vector2i, tile: Tile) -> void`
Updates a single tile within this chunk.

**Parameters**:
- `local_position`: Position within chunk (0-19, 0-19)
- `tile`: Updated tile data

---

##### `set_visible(visible: bool) -> void`
Shows or hides entire chunk (for culling).

---

##### `is_in_view(camera_rect: Rect2i) -> bool`
Checks if chunk is within camera view.

**Returns**: true if chunk should be rendered

---

### 3. UnitRenderer Class

**File**: `ui/map/unit_renderer.gd`

**Purpose**: Renders a single unit sprite.

#### Public Methods

##### `initialize(unit: Unit) -> void`
Creates visual representation for a unit.

**Parameters**:
- `unit`: Unit data to render

**Behavior**:
- Loads sprite based on unit type
- Applies faction colors
- Sets up health bar
- Adds status effect icons
- Positions at unit's tile

---

##### `update_position(new_position: Vector3i, animate: bool = true) -> void`
Moves unit sprite to new position.

**Parameters**:
- `new_position`: Target tile position
- `animate`: If true, smoothly animate movement

---

##### `update_health(current_hp: int, max_hp: int) -> void`
Updates health bar display.

---

##### `show_status_effects(effects: Array[String]) -> void`
Displays status effect icons above unit.

---

##### `play_animation(anim_name: String) -> void`
Plays unit animation (idle, walk, attack, death).

**Parameters**:
- `anim_name`: Animation name ("idle", "walk", "attack", "death", "hit")

---

### 4. CameraController Class

**File**: `ui/map/camera_controller.gd`

**Purpose**: Manages camera movement and zoom, handles input.

#### Public Methods

##### `_process(delta: float) -> void`
Handles continuous camera movement (WASD, edge scrolling).

**Parameters**:
- `delta`: Frame time in seconds

**Behavior**:
- Checks for keyboard input (WASD, arrow keys)
- Checks for edge scrolling (mouse near screen edges)
- Applies smooth camera movement
- Respects camera speed settings

---

##### `_input(event: InputEvent) -> void`
Handles discrete camera input (zoom, clicks).

**Parameters**:
- `event`: Input event from Godot

**Behavior**:
- Mouse wheel: Zoom in/out
- Middle mouse drag: Pan camera
- Double-click: Center on tile

---

##### `set_zoom_level(level: int) -> void`
Sets camera zoom to specific level (1, 2, or 3).

---

##### `get_camera_bounds() -> Rect2i`
Returns current camera view bounds in tile coordinates.

---

##### `enable_edge_scrolling(enabled: bool) -> void`
Enables/disables edge scrolling.

---

##### `set_camera_speed(speed: float) -> void`
Sets camera movement speed (pixels per second).

**Parameters**:
- `speed`: Speed multiplier (default 300.0)

---

### 5. SpriteLoader Class

**File**: `rendering/sprite_loader.gd`

**Purpose**: Loads and caches all sprite assets.

#### Public Methods

##### `load_tile_sprites() -> Dictionary`
Loads all tile sprites into a dictionary.

**Returns**:
- Dictionary mapping tile type to Texture2D

**Behavior**:
- Loads from `res://assets/sprites/tiles/`
- Creates texture atlas for efficient rendering
- Caches loaded textures
- Returns immediately if already loaded

**Performance**: < 200ms on first call, < 1ms on subsequent calls

---

##### `load_unit_sprites() -> Dictionary`
Loads all unit sprite animations.

**Returns**:
- Dictionary mapping unit type to SpriteFrames

**Behavior**:
- Loads from `res://assets/sprites/units/`
- Organizes into animations (idle, walk, attack)
- Supports multiple factions with color variations
- Caches loaded animations

**Performance**: < 300ms on first call

---

##### `get_tile_sprite(tile_type: String) -> Texture2D`
Gets sprite for a specific tile type.

**Parameters**:
- `tile_type`: Type identifier (e.g., "residential", "street", "rubble")

**Returns**:
- Texture2D or null if not found

---

##### `get_unit_sprite(unit_type: String, faction_id: int) -> SpriteFrames`
Gets animated sprite for a unit with faction colors.

**Parameters**:
- `unit_type`: Unit type identifier
- `faction_id`: Faction ID for color variant

---

##### `preload_all_assets() -> void`
Preloads all sprites at game startup (async).

**Behavior**:
- Loads all tiles and units in background
- Emits `assets_loaded` signal when complete
- Shows loading progress via `loading_progress` signal

---

##### `clear_cache() -> void`
Clears sprite cache (for memory management).

---

### 6. Visual Effects Classes

**File**: `rendering/effects/*.gd`

#### SelectionEffect

##### `show_selection(position: Vector3i) -> void`
Shows selection highlight on a tile.

##### `hide_selection() -> void`
Hides selection highlight.

---

#### MovementEffect

##### `show_path(path: Array[Vector3i]) -> void`
Displays movement path with arrows.

##### `hide_path() -> void`
Hides movement path.

---

#### AttackEffect

##### `play_melee_attack(from: Vector3i, to: Vector3i) -> void`
Plays melee attack animation.

##### `play_ranged_attack(from: Vector3i, to: Vector3i) -> void`
Plays ranged attack with projectile.

##### `play_explosion(at: Vector3i) -> void`
Plays explosion effect.

---

#### FogRenderer

##### `render_fog(faction_id: int, visibility_map: Dictionary) -> void`
Renders fog of war overlay.

**Parameters**:
- `faction_id`: Faction whose fog to render
- `visibility_map`: Dictionary of Vector3i -> VisibilityLevel

---

## Data Structures

### Enums

```gdscript
enum RenderMode {
    NORMAL,
    WIREFRAME,
    CHUNK_BOUNDS,
    FOG_DEBUG
}

enum ZoomLevel {
    ZOOM_1X = 0,    # Standard view
    ZOOM_1_5X = 1,  # Medium zoom
    ZOOM_2X = 2     # Maximum zoom
}

enum VisibilityLevel {
    HIDDEN = 0,     # Never seen (black)
    EXPLORED = 1,   # Previously seen (greyed)
    VISIBLE = 2     # Currently visible (clear)
}
```

---

### Configuration Constants

```gdscript
const CHUNK_SIZE: int = 20          # 20x20 tiles per chunk
const TILE_SIZE: int = 64           # 64x64 pixels per tile
const TARGET_FPS: int = 60
const MAX_FRAME_TIME_MS: float = 16.67  # ~60 FPS
const CAMERA_SPEED: float = 300.0   # Pixels per second
const ZOOM_ANIMATION_DURATION: float = 0.2  # Seconds
const MOVEMENT_ANIMATION_DURATION: float = 0.3  # Seconds
const EDGE_SCROLL_MARGIN: int = 20  # Pixels from edge
const MAX_VISIBLE_UNITS: int = 500  # Cull units beyond this
```

---

### ChunkData Structure

```gdscript
class ChunkData:
    var position: Vector2i      # Chunk coordinates
    var tiles: Array[Tile]      # 400 tiles (20x20)
    var renderer: TileRenderer  # Renderer instance
    var is_visible: bool        # Is in camera view
    var is_dirty: bool          # Needs redraw
```

---

### RenderStats Structure

```gdscript
class RenderStats:
    var fps: int
    var frame_time_ms: float
    var visible_tiles: int
    var visible_units: int
    var draw_calls: int
    var chunks_rendered: int
```

---

## Events

### Events Emitted

The Rendering System emits the following signals via EventBus:

```gdscript
# Map rendering events
signal map_rendered()
signal chunk_loaded(chunk_position: Vector2i)
signal chunk_unloaded(chunk_position: Vector2i)

# Camera events
signal camera_moved(new_position: Vector2)
signal camera_zoomed(zoom_level: int)
signal camera_centered(tile_position: Vector3i)

# Interaction events
signal tile_clicked(tile_position: Vector3i, button_index: int)
signal tile_hovered(tile_position: Vector3i)
signal unit_clicked(unit_id: int, button_index: int)
signal unit_hovered(unit_id: int)

# Animation events
signal attack_animation_complete(attacker_id: int, defender_id: int)
signal movement_animation_complete(unit_id: int)

# Highlight events
signal highlights_cleared()

# Performance events
signal performance_warning(stats: RenderStats)  # When FPS drops below 60
```

---

### Events Consumed

The Rendering System listens to these EventBus signals:

```gdscript
# Game state events
EventBus.turn_started.connect(_on_turn_started)
EventBus.turn_ended.connect(_on_turn_ended)

# Tile events
EventBus.tile_captured.connect(_on_tile_captured)
EventBus.tile_scavenged.connect(_on_tile_scavenged)
EventBus.tile_changed.connect(_on_tile_changed)
EventBus.building_constructed.connect(_on_building_constructed)

# Unit events
EventBus.unit_created.connect(_on_unit_created)
EventBus.unit_destroyed.connect(_on_unit_destroyed)
EventBus.unit_moved.connect(_on_unit_moved)
EventBus.unit_attacked.connect(_on_unit_attacked)
EventBus.unit_health_changed.connect(_on_unit_health_changed)
EventBus.unit_status_changed.connect(_on_unit_status_changed)

# Fog of war events
EventBus.fog_updated.connect(_on_fog_updated)

# UI events
EventBus.unit_selected.connect(_on_unit_selected)
EventBus.unit_deselected.connect(_on_unit_deselected)
EventBus.show_movement_range.connect(_on_show_movement_range)
EventBus.hide_movement_range.connect(_on_hide_movement_range)
```

---

### Event Handler Examples

```gdscript
func _on_unit_moved(unit_id: int, from_pos: Vector3i, to_pos: Vector3i):
    update_unit(unit_id, to_pos)
    # Play movement animation
    var unit_renderer = _get_unit_renderer(unit_id)
    await unit_renderer.animate_movement(from_pos, to_pos)
    EventBus.movement_animation_complete.emit(unit_id)

func _on_tile_captured(position: Vector3i, old_owner: int, new_owner: int):
    var tile = map_data.get_tile(position)
    update_tile(position, tile)
    # Play capture effect
    _play_capture_effect(position, new_owner)

func _on_unit_selected(unit_id: int):
    var unit = unit_manager.get_unit(unit_id)
    # Highlight unit
    _highlight_unit(unit_id)
    # Show movement range
    var movement_range = pathfinding.get_reachable_tiles(unit.position, unit.movement)
    highlight_tiles(movement_range, Color(0, 0.5, 1, 0.4))
```

---

## Performance Requirements

### Frame Rate
- **Target**: 60 FPS at 1920x1080
- **Minimum**: 30 FPS at 1920x1080
- **Frame time budget**: < 16.67ms (60 FPS) or < 33.33ms (30 FPS)

### Rendering Performance

| Operation | Max Time | Notes |
|-----------|----------|-------|
| Full map render | < 500ms | Initial load only |
| Chunk render | < 50ms | 20x20 tiles |
| Update single tile | < 1ms | Incremental update |
| Update single unit | < 5ms | Including animation |
| Camera movement | < 1ms | Per frame |
| Zoom change | < 10ms | Discrete zoom levels |
| Highlight 100 tiles | < 20ms | Movement range |
| Render fog of war | < 100ms | Per faction |
| Unit animation | 0.3-1.0s | Async, non-blocking |

### Memory Constraints
- **Total rendering memory**: < 500MB
- **Sprite cache**: < 200MB
- **Chunk data**: < 100MB
- **Effect pool**: < 50MB

### Draw Call Optimization
- **Max draw calls per frame**: < 500
- **Use sprite batching**: Batch tiles by type
- **Texture atlases**: Combine sprites into atlases
- **Chunk-based culling**: Render only visible chunks

### Culling Strategy

```gdscript
func _update_visible_chunks():
    var camera_bounds = camera_controller.get_camera_bounds()
    var chunk_bounds = _get_chunks_in_bounds(camera_bounds)

    # Show visible chunks
    for chunk_pos in chunk_bounds:
        var chunk = chunks[chunk_pos]
        if not chunk.is_visible:
            chunk.set_visible(true)
            chunk_loaded.emit(chunk_pos)

    # Hide non-visible chunks
    for chunk_pos in chunks.keys():
        if chunk_pos not in chunk_bounds:
            var chunk = chunks[chunk_pos]
            if chunk.is_visible:
                chunk.set_visible(false)
                chunk_unloaded.emit(chunk_pos)
```

### LOD (Level of Detail)

```gdscript
func _get_unit_lod(distance_from_camera: float) -> int:
    if zoom_level == ZOOM_2X:
        return 0  # High detail
    elif zoom_level == ZOOM_1_5X:
        return 1  # Medium detail
    else:
        if distance_from_camera > 1000:
            return 2  # Low detail (distant units)
        else:
            return 1  # Medium detail
```

---

## Error Handling

### Error Conditions

#### Invalid Tile Position
```gdscript
func update_tile(position: Vector3i, tile: Tile) -> void:
    if not map_data.is_valid_position(position):
        push_error("Invalid tile position: %s" % position)
        return
    # ... proceed with update
```

#### Missing Sprite
```gdscript
func _load_unit_sprite(unit_type: String) -> Texture2D:
    var sprite = sprite_loader.get_unit_sprite(unit_type, faction_id)
    if sprite == null:
        push_warning("Missing sprite for unit type: %s, using placeholder" % unit_type)
        sprite = placeholder_sprite
    return sprite
```

#### Performance Degradation
```gdscript
func _monitor_performance():
    var stats = _get_render_stats()
    if stats.fps < 30:
        push_warning("FPS dropped below 30: %d" % stats.fps)
        performance_warning.emit(stats)
        _reduce_visual_quality()

func _reduce_visual_quality():
    # Disable expensive effects
    enable_shadows = false
    enable_particle_effects = false
    # Reduce unit LOD
    max_visible_units = 200
```

#### Out of Memory
```gdscript
func _on_low_memory_warning():
    push_warning("Low memory detected, clearing caches")
    sprite_loader.clear_cache()
    _clear_effect_pool()
    _garbage_collect_chunks()
```

### Graceful Degradation

If performance requirements cannot be met:
1. Reduce draw distance (render fewer chunks)
2. Disable visual effects (particles, shadows)
3. Reduce unit LOD (simpler sprites for distant units)
4. Skip animations (instant updates instead of smooth transitions)
5. Reduce fog of war detail (larger fog tiles)

---

## Testing Requirements

### Unit Tests

**Test Coverage Target**: 60%

#### Test Cases

```gdscript
# tests/unit/test_map_view.gd
class TestMapView extends GutTest:
    func test_render_map_creates_chunks():
        var map_data = create_test_map(100, 100)
        var map_view = MapView.new()
        map_view.render_map(map_data)

        # Should create 5x5 = 25 chunks for 100x100 map
        assert_eq(map_view.chunks.size(), 25)

    func test_get_tile_at_screen_position():
        var map_view = MapView.new()
        map_view.render_map(create_test_map(10, 10))

        var tile_pos = map_view.get_tile_at_screen_position(Vector2(320, 240))
        assert_true(tile_pos.x >= 0 and tile_pos.x < 10)

    func test_highlight_tiles_respects_fog():
        var map_view = MapView.new()
        var positions = [Vector3i(0,0,1), Vector3i(1,1,1), Vector3i(2,2,1)]
        # Assume position (2,2,1) is in fog
        map_view.highlight_tiles(positions, Color.GREEN)

        # Should only highlight 2 tiles (not the fogged one)
        assert_eq(map_view.active_highlights.size(), 2)
```

```gdscript
# tests/unit/test_camera_controller.gd
class TestCameraController extends GutTest:
    func test_zoom_clamps_to_levels():
        var camera = CameraController.new()
        camera.set_zoom_level(1)

        camera.zoom_camera(10)  # Try to zoom way in
        assert_eq(camera.zoom_level, ZOOM_2X)  # Should clamp to max

        camera.zoom_camera(-10)  # Try to zoom way out
        assert_eq(camera.zoom_level, ZOOM_1X)  # Should clamp to min

    func test_camera_bounds_respect_map_limits():
        var camera = CameraController.new()
        camera.map_bounds = Rect2i(0, 0, 100, 100)

        camera.move_camera(Vector2(99999, 99999))  # Try to move far off map
        var pos = camera.get_position()

        # Should be clamped within map
        assert_true(pos.x <= 100 * TILE_SIZE)
        assert_true(pos.y <= 100 * TILE_SIZE)
```

```gdscript
# tests/unit/test_sprite_loader.gd
class TestSpriteLoader extends GutTest:
    func test_load_tile_sprites_caches_results():
        var loader = SpriteLoader.new()

        var start_time = Time.get_ticks_msec()
        loader.load_tile_sprites()
        var first_load_time = Time.get_ticks_msec() - start_time

        start_time = Time.get_ticks_msec()
        loader.load_tile_sprites()  # Second call
        var second_load_time = Time.get_ticks_msec() - start_time

        # Second load should be much faster (cached)
        assert_lt(second_load_time, first_load_time / 10)
```

---

### Integration Tests

```gdscript
# tests/integration/test_rendering_integration.gd
class TestRenderingIntegration extends GutTest:
    func test_render_with_real_map_data():
        var map_data = MapData.new()
        map_data.generate(200, 200, 3)  # 200x200x3 grid

        var map_view = MapView.new()
        add_child_autofree(map_view)

        var start_time = Time.get_ticks_msec()
        map_view.render_map(map_data)
        var render_time = Time.get_ticks_msec() - start_time

        # Should render within performance budget
        assert_lt(render_time, 500, "Map rendering took too long")

    func test_render_units_with_fog_of_war():
        var game_state = create_test_game_state()
        var map_view = MapView.new()
        add_child_autofree(map_view)

        map_view.render_map(game_state.world_state.map)

        # Render fog for player faction
        var fog = game_state.world_state.fog_of_war
        var visible = fog.get_visible_tiles(0)  # Player faction
        map_view.render_fog_of_war(0, visible)

        # Render all units
        var units = game_state.get_all_units()
        map_view.render_units(units)

        # Units in fog should not be visible
        for unit in units:
            if unit.faction != 0:  # Enemy units
                var is_visible = position_in_array(unit.position, visible)
                var renderer = map_view._get_unit_renderer(unit.id)
                assert_eq(renderer.visible, is_visible)

    func test_camera_and_culling():
        var map_view = MapView.new()
        add_child_autofree(map_view)
        map_view.render_map(create_test_map(200, 200))

        # Initial view
        var visible_chunks_1 = map_view._get_visible_chunks()

        # Move camera significantly
        map_view.move_camera(Vector2(5000, 5000))
        await get_tree().process_frame

        var visible_chunks_2 = map_view._get_visible_chunks()

        # Different chunks should be visible
        assert_ne(visible_chunks_1, visible_chunks_2)
```

---

### Performance Tests

```gdscript
# tests/performance/test_rendering_performance.gd
class TestRenderingPerformance extends GutTest:
    func test_60fps_with_200_units():
        var map_view = MapView.new()
        add_child_autofree(map_view)
        map_view.render_map(create_test_map(200, 200))

        var units = []
        for i in range(200):
            units.append(create_test_unit(i))
        map_view.render_units(units)

        # Simulate 100 frames
        var total_time = 0.0
        for frame in range(100):
            var start = Time.get_ticks_usec()
            map_view._process(0.016)  # Simulate frame
            var frame_time = (Time.get_ticks_usec() - start) / 1000.0
            total_time += frame_time

        var avg_frame_time = total_time / 100.0
        assert_lt(avg_frame_time, 16.67, "Average frame time exceeds 60 FPS budget")

    func test_chunk_culling_performance():
        var map_view = MapView.new()
        add_child_autofree(map_view)
        map_view.render_map(create_test_map(200, 200))

        # All chunks loaded
        var total_chunks = map_view.chunks.size()

        # Set camera to see only small portion
        map_view.camera_controller.set_position(Vector2(0, 0))
        await get_tree().process_frame

        var visible_chunks = map_view._get_visible_chunks().size()

        # Should render much less than total
        assert_lt(visible_chunks, total_chunks / 4, "Too many chunks visible")
```

---

### Visual Tests (Manual)

**Test Checklist**:
- [ ] Map renders correctly at all zoom levels
- [ ] Units appear at correct positions
- [ ] Fog of war hides enemy units
- [ ] Selection highlight is visible
- [ ] Movement path displays correctly
- [ ] Attack animations play smoothly
- [ ] Camera movement is smooth (no stuttering)
- [ ] Edge scrolling works
- [ ] Double-click centers camera
- [ ] Tile highlights clear properly
- [ ] Performance stays above 30 FPS with 200 units

---

## Implementation Notes

### Chunk-Based Rendering

Divide the 200x200 map into 10x10 = 100 chunks of 20x20 tiles each. Each chunk is rendered as a single node with batched sprites.

```gdscript
func _create_chunks():
    var map_width = map_data.width
    var map_height = map_data.height
    var chunks_x = ceili(map_width / float(CHUNK_SIZE))
    var chunks_y = ceili(map_height / float(CHUNK_SIZE))

    for cx in range(chunks_x):
        for cy in range(chunks_y):
            var chunk_pos = Vector2i(cx, cy)
            var tiles = _get_tiles_for_chunk(chunk_pos)
            var renderer = TileRenderer.new()
            renderer.initialize(chunk_pos, tiles)
            add_child(renderer)
            chunks[chunk_pos] = ChunkData.new(chunk_pos, tiles, renderer)
```

---

### Sprite Batching

Batch tiles of the same type into a single draw call using MultiMeshInstance2D.

```gdscript
func _batch_tiles_by_type(tiles: Array[Tile]) -> Dictionary:
    var batches = {}
    for tile in tiles:
        var tile_type = tile.tile_type
        if tile_type not in batches:
            batches[tile_type] = []
        batches[tile_type].append(tile)
    return batches

func _create_multimesh_for_type(tile_type: String, tiles: Array[Tile]) -> MultiMeshInstance2D:
    var multimesh_instance = MultiMeshInstance2D.new()
    var multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_2D
    multimesh.instance_count = tiles.size()
    multimesh.mesh = QuadMesh.new()

    var texture = sprite_loader.get_tile_sprite(tile_type)
    multimesh_instance.texture = texture

    for i in range(tiles.size()):
        var tile = tiles[i]
        var transform = Transform2D()
        transform.origin = _tile_to_screen_position(tile.position)
        multimesh.set_instance_transform_2d(i, transform)

    multimesh_instance.multimesh = multimesh
    return multimesh_instance
```

---

### Fog of War Rendering

Use a shader to render fog of war as an overlay.

```gdscript
# fog_of_war.gdshader
shader_type canvas_item;

uniform sampler2D visibility_map;  // Texture where RGB = visibility level
uniform vec4 fog_color = vec4(0.0, 0.0, 0.0, 0.8);  // Dark fog
uniform vec4 explored_color = vec4(0.3, 0.3, 0.3, 0.5);  // Grey fog

void fragment() {
    vec4 visibility = texture(visibility_map, UV);
    float level = visibility.r;

    if (level < 0.33) {
        // Hidden
        COLOR = fog_color;
    } else if (level < 0.66) {
        // Explored
        COLOR = explored_color;
    } else {
        // Visible
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);  // Transparent
    }
}
```

---

### Camera Smoothing

Use Godot's Tween for smooth camera movement.

```gdscript
func center_camera_on(position: Vector3i):
    var screen_pos = _tile_to_screen_position(position)
    var tween = create_tween()
    tween.tween_property(camera, "position", screen_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    camera_centered.emit(position)
```

---

### Placeholder Art

For MVP, use simple colored rectangles as placeholders.

```gdscript
func _create_placeholder_tile_sprite(tile_type: String) -> Texture2D:
    var color_map = {
        "residential": Color.BLUE,
        "commercial": Color.YELLOW,
        "industrial": Color.ORANGE,
        "military": Color.RED,
        "street": Color.DARK_GRAY,
        "park": Color.GREEN,
        "rubble": Color.BROWN
    }

    var color = color_map.get(tile_type, Color.WHITE)
    var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
    image.fill(color)
    return ImageTexture.create_from_image(image)
```

---

### Event-Driven Updates

React to game state changes rather than polling.

```gdscript
func _ready():
    # Connect to relevant events
    EventBus.unit_moved.connect(_on_unit_moved)
    EventBus.tile_captured.connect(_on_tile_captured)
    EventBus.fog_updated.connect(_on_fog_updated)
    EventBus.unit_created.connect(_on_unit_created)
    EventBus.unit_destroyed.connect(_on_unit_destroyed)

func _on_unit_moved(unit_id: int, from_pos: Vector3i, to_pos: Vector3i):
    # Only update this specific unit, not re-render everything
    update_unit(unit_id, to_pos)
```

---

### Optimization: Dirty Flagging

Only redraw chunks that have changed.

```gdscript
func update_tile(position: Vector3i, tile: Tile):
    var chunk_pos = _get_chunk_for_tile(position)
    var chunk = chunks[chunk_pos]

    # Mark chunk as dirty
    chunk.is_dirty = true

    # Update tile data
    var local_pos = _get_local_position(position, chunk_pos)
    chunk.renderer.update_tile_at(local_pos, tile)

func _process(delta):
    # Only redraw dirty chunks
    for chunk in chunks.values():
        if chunk.is_dirty:
            chunk.renderer.redraw()
            chunk.is_dirty = false
```

---

## Summary

This interface contract defines:

✅ **10 public functions** for MapView (core rendering operations)
✅ **Camera controls** (WASD, zoom, edge scrolling, centering)
✅ **Performance requirements** (60 FPS, < 100ms frame time, culling)
✅ **Visual effects** (selection, movement paths, attacks, fog of war)
✅ **Optimization techniques** (chunking, batching, culling, LOD)
✅ **Event-driven architecture** (reacts to game state changes)
✅ **Comprehensive testing requirements** (unit, integration, performance)
✅ **Error handling** (graceful degradation)

### Key Integration Points

- **Depends on**: Core (EventBus, GameState), Map (MapData, FogOfWar), Units (Unit, UnitManager)
- **Provides**: Visual presentation of game state
- **Communication**: Event-driven via EventBus
- **Performance**: Optimized for 60 FPS with 40,000 tiles and 200+ units

---

**Ready for Implementation**: ✅
**Review Status**: Awaiting approval
**Next Steps**: Begin Phase 2 implementation (Weeks 2-4)
