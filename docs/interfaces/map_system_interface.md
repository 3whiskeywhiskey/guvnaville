# Map System Interface Contract

**Module**: Map System (`systems/map/`)
**Layer**: 1 (Foundation)
**Version**: 1.0
**Date**: 2025-11-12
**Owner**: Agent 2

---

## Overview

The Map System is responsible for managing the 200x200x3 tile grid (40,000 tiles total) that represents the post-apocalyptic cityscape. It provides spatial queries, tile ownership tracking, fog of war per faction, and map data persistence.

### Key Responsibilities

1. Maintain 200x200x3 tile grid with efficient spatial queries
2. Track tile properties (type, terrain, ownership, resources)
3. Manage fog of war visibility per faction
4. Provide spatial query operations (radius, rectangle, pathfinding stub)
5. Handle tile state changes and emit appropriate events
6. Load and validate map data from JSON

---

## Dependencies

### Layer 0 Dependencies
- **Core Foundation** (`core/autoload/`): EventBus for events, DataLoader for JSON loading
- **Core Types** (`core/types/`): Tile data class

### External Dependencies
- Godot 4.5.1 (Vector3i, Rect2i)
- GDScript standard library

---

## Module Structure

```
systems/map/
├── map_data.gd            # Main map grid management (200x200x3)
├── tile.gd                # Tile data class and properties
├── fog_of_war.gd          # Per-faction visibility tracking
└── spatial_query.gd       # Efficient spatial query operations
```

---

## Public API

### MapData Class (`map_data.gd`)

Main class for managing the entire map grid.

#### Constructor

```gdscript
func _init() -> void
```
Initializes an empty 200x200x3 grid.

#### load_map

```gdscript
func load_map(map_file_path: String) -> bool
```
**Description**: Loads map data from JSON file and populates the grid.

**Parameters**:
- `map_file_path` (String): Absolute or relative path to map JSON file

**Returns**:
- `bool`: true if successful, false if file not found or invalid format

**Errors**:
- Emits error message if JSON parsing fails
- Emits error message if map dimensions are invalid
- Returns false if tile validation fails

**Events Emitted**:
- `EventBus.map_loaded(map_size: Vector3i)` on success

**Performance**: < 500ms for full map load

---

#### get_tile

```gdscript
func get_tile(position: Vector3i) -> Tile
```
**Description**: Returns the tile at the specified position.

**Parameters**:
- `position` (Vector3i): Grid coordinates (x: 0-199, y: 0-199, z: 0-2)

**Returns**:
- `Tile`: The tile object at the position, or `null` if out of bounds

**Performance**: O(1), < 1ms

**Example**:
```gdscript
var tile = map_data.get_tile(Vector3i(10, 15, 1))
if tile:
    print("Tile type: ", tile.tile_type)
```

---

#### get_tiles_in_radius

```gdscript
func get_tiles_in_radius(center: Vector3i, radius: int, same_level_only: bool = true) -> Array[Tile]
```
**Description**: Returns all tiles within a given radius of the center position.

**Parameters**:
- `center` (Vector3i): Center position
- `radius` (int): Radius in tiles (Manhattan distance)
- `same_level_only` (bool): If true, only returns tiles on same Z level as center. Default: true

**Returns**:
- `Array[Tile]`: All tiles within radius, empty array if center is out of bounds

**Performance**: O(n) where n = tiles in radius, < 10ms for radius 10

**Example**:
```gdscript
var nearby_tiles = map_data.get_tiles_in_radius(Vector3i(50, 50, 1), 5)
for tile in nearby_tiles:
    print("Found tile at: ", tile.position)
```

---

#### get_tiles_in_rect

```gdscript
func get_tiles_in_rect(rect: Rect2i, level: int) -> Array[Tile]
```
**Description**: Returns all tiles within a rectangular area at a specific Z level.

**Parameters**:
- `rect` (Rect2i): Rectangle defining the area (position and size)
- `level` (int): Z level (0=underground, 1=ground, 2=elevated)

**Returns**:
- `Array[Tile]`: All tiles in rectangle, empty array if invalid parameters

**Performance**: O(n) where n = tiles in rectangle, < 20ms for 20x20 rectangle

**Example**:
```gdscript
var rect = Rect2i(Vector2i(0, 0), Vector2i(20, 20))
var tiles = map_data.get_tiles_in_rect(rect, 1)
```

---

#### update_tile_owner

```gdscript
func update_tile_owner(position: Vector3i, owner_id: int) -> void
```
**Description**: Changes the owner of a tile and emits tile_captured event.

**Parameters**:
- `position` (Vector3i): Position of tile to update
- `owner_id` (int): New owner faction ID (-1 for neutral, 0-8 for factions)

**Errors**:
- Prints warning if position is out of bounds (no-op)
- Prints warning if owner_id is invalid (< -1 or > 8)

**Events Emitted**:
- `EventBus.tile_captured(position: Vector3i, old_owner: int, new_owner: int)` if owner changed

**Performance**: < 1ms

**Example**:
```gdscript
map_data.update_tile_owner(Vector3i(25, 30, 1), 2)  # Faction 2 captures tile
```

---

#### update_tile_scavenge_value

```gdscript
func update_tile_scavenge_value(position: Vector3i, new_value: float) -> void
```
**Description**: Updates the scavenge value of a tile (0.0 - 100.0).

**Parameters**:
- `position` (Vector3i): Position of tile to update
- `new_value` (float): New scavenge value (clamped to 0.0-100.0)

**Errors**:
- Prints warning if position is out of bounds (no-op)

**Events Emitted**:
- `EventBus.tile_scavenged(position: Vector3i, resources_found: Dictionary)` if value decreased

**Performance**: < 1ms

---

#### get_neighbors

```gdscript
func get_neighbors(position: Vector3i, include_diagonal: bool = false) -> Array[Tile]
```
**Description**: Returns adjacent tiles (4-way or 8-way connectivity).

**Parameters**:
- `position` (Vector3i): Center position
- `include_diagonal` (bool): If true, includes diagonal neighbors. Default: false

**Returns**:
- `Array[Tile]`: Adjacent tiles (4 or 8 tiles, fewer at edges)

**Performance**: O(1), < 1ms

---

#### is_position_valid

```gdscript
func is_position_valid(position: Vector3i) -> bool
```
**Description**: Checks if a position is within map bounds.

**Parameters**:
- `position` (Vector3i): Position to check

**Returns**:
- `bool`: true if position is valid (x: 0-199, y: 0-199, z: 0-2)

**Performance**: O(1), < 0.1ms

---

#### get_map_size

```gdscript
func get_map_size() -> Vector3i
```
**Description**: Returns the dimensions of the map.

**Returns**:
- `Vector3i`: Map size (200, 200, 3)

**Performance**: O(1), < 0.1ms

---

### FogOfWar Class (`fog_of_war.gd`)

Manages visibility state for each faction.

#### Constructor

```gdscript
func _init(map_size: Vector3i, num_factions: int) -> void
```
Initializes fog of war for all factions.

**Parameters**:
- `map_size` (Vector3i): Size of the map grid
- `num_factions` (int): Number of factions (typically 9: player + 8 AI)

---

#### is_tile_visible

```gdscript
func is_tile_visible(position: Vector3i, faction_id: int) -> bool
```
**Description**: Checks if a tile is currently visible to a faction.

**Parameters**:
- `position` (Vector3i): Tile position to check
- `faction_id` (int): Faction ID (0-8)

**Returns**:
- `bool`: true if visible, false if in fog of war or invalid parameters

**Performance**: O(1), < 1ms

---

#### is_tile_explored

```gdscript
func is_tile_explored(position: Vector3i, faction_id: int) -> bool
```
**Description**: Checks if a tile has ever been seen by a faction (even if not currently visible).

**Parameters**:
- `position` (Vector3i): Tile position to check
- `faction_id` (int): Faction ID (0-8)

**Returns**:
- `bool`: true if explored, false if never seen or invalid parameters

**Performance**: O(1), < 1ms

---

#### update_fog_of_war

```gdscript
func update_fog_of_war(faction_id: int, visible_positions: Array[Vector3i]) -> void
```
**Description**: Updates the visible tiles for a faction. Marks all positions as visible and explored, all other positions as not currently visible.

**Parameters**:
- `faction_id` (int): Faction ID (0-8)
- `visible_positions` (Array[Vector3i]): All currently visible tile positions

**Events Emitted**:
- `EventBus.fog_revealed(faction_id: int, positions: Array[Vector3i])` for newly explored tiles

**Performance**: < 20ms per faction for typical visibility range

**Example**:
```gdscript
var visible_tiles = []
for unit in faction_units:
    visible_tiles.append_array(calculate_unit_vision(unit))
fog_of_war.update_fog_of_war(faction_id, visible_tiles)
```

---

#### reveal_area

```gdscript
func reveal_area(faction_id: int, center: Vector3i, radius: int) -> void
```
**Description**: Reveals an area around a position for a faction.

**Parameters**:
- `faction_id` (int): Faction ID (0-8)
- `center` (Vector3i): Center of reveal area
- `radius` (int): Radius in tiles

**Events Emitted**:
- `EventBus.fog_revealed(faction_id: int, positions: Array[Vector3i])` for newly explored tiles

**Performance**: < 15ms for radius 10

---

#### clear_fog_for_faction

```gdscript
func clear_fog_for_faction(faction_id: int) -> void
```
**Description**: Reveals entire map for a faction (debug/cheat function).

**Parameters**:
- `faction_id` (int): Faction ID (0-8)

**Performance**: < 50ms

---

### SpatialQuery Class (`spatial_query.gd`)

Provides optimized spatial query operations.

#### find_path

```gdscript
func find_path(start: Vector3i, goal: Vector3i, movement_type: int = 0) -> Array[Vector3i]
```
**Description**: **STUB FOR MVP** - Returns empty array. Full pathfinding implementation post-MVP.

**Parameters**:
- `start` (Vector3i): Starting position
- `goal` (Vector3i): Goal position
- `movement_type` (int): Movement type (0=ground, 1=flying, etc.)

**Returns**:
- `Array[Vector3i]`: Empty array for MVP. Will return path positions in post-MVP.

**Performance**: < 1ms (stub), < 100ms for long paths (future implementation)

**Note**: For MVP, units will use simple direct movement. A* pathfinding will be implemented in Phase 4 or post-MVP.

---

#### get_tiles_by_type

```gdscript
func get_tiles_by_type(tile_type: int, level: int = -1) -> Array[Tile]
```
**Description**: Returns all tiles of a specific type, optionally filtered by level.

**Parameters**:
- `tile_type` (int): Tile type enum value (see Tile.TileType)
- `level` (int): Z level filter (-1 = all levels)

**Returns**:
- `Array[Tile]`: All matching tiles

**Performance**: O(n) where n = total tiles, < 100ms for full scan

**Note**: Results are cached. Cache invalidates on tile type changes.

---

#### get_tiles_by_owner

```gdscript
func get_tiles_by_owner(owner_id: int, level: int = -1) -> Array[Tile]
```
**Description**: Returns all tiles owned by a faction.

**Parameters**:
- `owner_id` (int): Owner faction ID (-1 for neutral)
- `level` (int): Z level filter (-1 = all levels)

**Returns**:
- `Array[Tile]`: All tiles owned by faction

**Performance**: O(n) where n = total tiles, < 100ms for full scan

**Note**: Results are cached. Cache invalidates on ownership changes.

---

#### get_border_tiles

```gdscript
func get_border_tiles(owner_id: int) -> Array[Tile]
```
**Description**: Returns all tiles owned by a faction that are adjacent to non-owned tiles (border tiles).

**Parameters**:
- `owner_id` (int): Owner faction ID

**Returns**:
- `Array[Tile]`: All border tiles

**Performance**: O(n) where n = owned tiles, < 150ms

---

### Tile Class (`tile.gd`)

Data class representing a single tile.

#### Properties

```gdscript
var position: Vector3i           # Grid position
var tile_type: TileType          # Type of tile (Residential, Commercial, etc.)
var terrain: TerrainType         # Terrain type (Rubble, Building, etc.)
var owner_id: int                # Owning faction ID (-1 = neutral)
var scavenge_value: float        # 0.0-100.0, resources available
var has_building: bool           # Whether tile has a building
var building_id: String          # Building ID if has_building is true
var movement_cost: int           # Movement cost to enter tile
var cover_value: int             # Cover value for combat (0-3)
var elevation: int               # Elevation modifier
var is_passable: bool            # Whether units can enter
var is_water: bool               # Whether tile is water
var unique_location_id: String   # ID of unique location if applicable
```

#### Enums

```gdscript
enum TileType {
    RESIDENTIAL,
    COMMERCIAL,
    INDUSTRIAL,
    MILITARY,
    MEDICAL,
    CULTURAL,
    INFRASTRUCTURE,
    RUINS,
    STREET,
    PARK
}

enum TerrainType {
    OPEN_GROUND,
    BUILDING,
    RUBBLE,
    STREET,
    WATER,
    TUNNEL,
    ROOFTOP
}
```

#### Methods

```gdscript
func to_dict() -> Dictionary
```
**Description**: Serializes tile to dictionary for saving.

**Returns**: Dictionary with all tile properties

---

```gdscript
static func from_dict(data: Dictionary) -> Tile
```
**Description**: Deserializes tile from dictionary.

**Parameters**:
- `data` (Dictionary): Tile data

**Returns**: Tile instance

---

## Events

All events are emitted through `EventBus` singleton.

### map_loaded

```gdscript
EventBus.map_loaded.emit(map_size: Vector3i)
```
**When**: Map successfully loads from JSON
**Parameters**:
- `map_size` (Vector3i): Dimensions of loaded map

---

### tile_captured

```gdscript
EventBus.tile_captured.emit(position: Vector3i, old_owner: int, new_owner: int)
```
**When**: Tile ownership changes
**Parameters**:
- `position` (Vector3i): Position of captured tile
- `old_owner` (int): Previous owner faction ID (-1 if neutral)
- `new_owner` (int): New owner faction ID

---

### tile_scavenged

```gdscript
EventBus.tile_scavenged.emit(position: Vector3i, resources_found: Dictionary)
```
**When**: Tile is scavenged and scavenge_value decreases
**Parameters**:
- `position` (Vector3i): Position of scavenged tile
- `resources_found` (Dictionary): Resources obtained (e.g., {"scrap": 10, "components": 2})

---

### fog_revealed

```gdscript
EventBus.fog_revealed.emit(faction_id: int, positions: Array[Vector3i])
```
**When**: New tiles are explored by a faction
**Parameters**:
- `faction_id` (int): Faction that revealed the fog
- `positions` (Array[Vector3i]): Newly explored tile positions

---

## Error Handling

### Invalid Position Errors
- **Behavior**: Print warning and return null/empty/default value
- **Example**: `get_tile()` with out-of-bounds position returns `null`
- **Logging**: `push_warning("Map: Invalid position %s" % position)`

### Invalid Faction ID Errors
- **Behavior**: Print warning and return false/default value
- **Example**: `is_tile_visible()` with invalid faction_id returns `false`
- **Logging**: `push_warning("Map: Invalid faction_id %d" % faction_id)`

### File Loading Errors
- **Behavior**: Return false and print error
- **Example**: `load_map()` with invalid JSON returns `false`
- **Logging**: `push_error("Map: Failed to load %s: %s" % [path, error])`

### Data Validation Errors
- **Behavior**: Use default values and print warning
- **Example**: Tile with invalid tile_type defaults to RUINS
- **Logging**: `push_warning("Map: Invalid tile_type for tile at %s" % position)`

---

## Performance Requirements

### Critical Performance Targets

| Operation | Complexity | Target Time | Max Acceptable |
|-----------|------------|-------------|----------------|
| `get_tile()` | O(1) | < 1ms | < 2ms |
| `get_tiles_in_radius()` (r=10) | O(n) | < 10ms | < 20ms |
| `get_tiles_in_rect()` (20x20) | O(n) | < 20ms | < 30ms |
| `update_tile_owner()` | O(1) | < 1ms | < 2ms |
| `is_tile_visible()` | O(1) | < 1ms | < 2ms |
| `update_fog_of_war()` | O(n) | < 20ms | < 50ms |
| `load_map()` | O(n) | < 500ms | < 1000ms |
| `find_path()` (stub) | O(1) | < 1ms | < 1ms |

### Memory Requirements
- **Total Map Size**: < 100MB for 40,000 tiles
- **Per Tile**: < 2.5KB average
- **Fog of War**: < 20MB (9 factions × 40,000 tiles × 2 bits)

### Optimization Strategies
1. **Flat Array Storage**: Use 1D array for 3D grid with index calculation
2. **Spatial Partitioning**: Implement quadtree for large radius queries
3. **Caching**: Cache frequently accessed tile lists (by type, by owner)
4. **Bit Flags**: Use bit flags for fog of war (2 bits per tile per faction)
5. **Lazy Loading**: Load map in chunks if needed (defer to Phase 4)

---

## Test Specifications

### Unit Tests (`tests/unit/test_map_system.gd`)

#### Basic Grid Operations

```gdscript
func test_get_tile_valid_position():
    # Arrange
    var map_data = MapData.new()

    # Act
    var tile = map_data.get_tile(Vector3i(50, 50, 1))

    # Assert
    assert_not_null(tile)
    assert_eq(tile.position, Vector3i(50, 50, 1))

func test_get_tile_invalid_position():
    var map_data = MapData.new()
    var tile = map_data.get_tile(Vector3i(300, 300, 5))
    assert_null(tile)

func test_is_position_valid():
    var map_data = MapData.new()
    assert_true(map_data.is_position_valid(Vector3i(0, 0, 0)))
    assert_true(map_data.is_position_valid(Vector3i(199, 199, 2)))
    assert_false(map_data.is_position_valid(Vector3i(200, 0, 0)))
    assert_false(map_data.is_position_valid(Vector3i(0, 0, 3)))
```

#### Spatial Queries

```gdscript
func test_get_tiles_in_radius():
    var map_data = MapData.new()
    var center = Vector3i(50, 50, 1)
    var radius = 5

    var tiles = map_data.get_tiles_in_radius(center, radius)

    # Should return tiles in Manhattan distance
    assert_gt(tiles.size(), 0)
    assert_lte(tiles.size(), (radius * 2 + 1) * (radius * 2 + 1))

    # Check all returned tiles are within radius
    for tile in tiles:
        var dist = abs(tile.position.x - center.x) + abs(tile.position.y - center.y)
        assert_lte(dist, radius)

func test_get_tiles_in_rect():
    var map_data = MapData.new()
    var rect = Rect2i(Vector2i(10, 10), Vector2i(20, 20))
    var tiles = map_data.get_tiles_in_rect(rect, 1)

    assert_eq(tiles.size(), 400)  # 20x20 = 400 tiles

    for tile in tiles:
        assert_gte(tile.position.x, 10)
        assert_lt(tile.position.x, 30)
        assert_gte(tile.position.y, 10)
        assert_lt(tile.position.y, 30)
        assert_eq(tile.position.z, 1)

func test_get_neighbors_4way():
    var map_data = MapData.new()
    var center = Vector3i(50, 50, 1)
    var neighbors = map_data.get_neighbors(center, false)

    assert_eq(neighbors.size(), 4)

func test_get_neighbors_8way():
    var map_data = MapData.new()
    var center = Vector3i(50, 50, 1)
    var neighbors = map_data.get_neighbors(center, true)

    assert_eq(neighbors.size(), 8)

func test_get_neighbors_edge():
    var map_data = MapData.new()
    var corner = Vector3i(0, 0, 0)
    var neighbors = map_data.get_neighbors(corner, false)

    assert_eq(neighbors.size(), 2)  # Only 2 neighbors at corner
```

#### Tile Ownership

```gdscript
func test_update_tile_owner():
    var map_data = MapData.new()
    var position = Vector3i(25, 30, 1)
    var tile = map_data.get_tile(position)

    var old_owner = tile.owner_id
    map_data.update_tile_owner(position, 3)

    assert_eq(tile.owner_id, 3)
    # TODO: assert signal emitted

func test_get_tiles_by_owner():
    var map_data = MapData.new()

    # Assign some tiles to faction 2
    map_data.update_tile_owner(Vector3i(10, 10, 1), 2)
    map_data.update_tile_owner(Vector3i(11, 10, 1), 2)
    map_data.update_tile_owner(Vector3i(12, 10, 1), 2)

    var owned_tiles = map_data.get_tiles_by_owner(2)
    assert_gte(owned_tiles.size(), 3)

func test_get_border_tiles():
    var map_data = MapData.new()

    # Create a 3x3 territory for faction 5
    for x in range(20, 23):
        for y in range(20, 23):
            map_data.update_tile_owner(Vector3i(x, y, 1), 5)

    var border_tiles = map_data.get_border_tiles(5)

    # Border should be the outer ring (8 tiles in 3x3)
    # Center tile (21, 21) is not border
    assert_eq(border_tiles.size(), 8)
```

#### Fog of War

```gdscript
func test_fog_of_war_initialization():
    var fog = FogOfWar.new(Vector3i(200, 200, 3), 9)

    # All tiles should be unexplored initially
    for faction_id in range(9):
        assert_false(fog.is_tile_explored(Vector3i(50, 50, 1), faction_id))
        assert_false(fog.is_tile_visible(Vector3i(50, 50, 1), faction_id))

func test_update_fog_of_war():
    var fog = FogOfWar.new(Vector3i(200, 200, 3), 9)
    var visible_positions = [
        Vector3i(50, 50, 1),
        Vector3i(51, 50, 1),
        Vector3i(50, 51, 1),
    ]

    fog.update_fog_of_war(0, visible_positions)

    # Visible positions should be visible and explored
    assert_true(fog.is_tile_visible(Vector3i(50, 50, 1), 0))
    assert_true(fog.is_tile_explored(Vector3i(50, 50, 1), 0))

    # Other positions should not be visible
    assert_false(fog.is_tile_visible(Vector3i(100, 100, 1), 0))

func test_reveal_area():
    var fog = FogOfWar.new(Vector3i(200, 200, 3), 9)
    var center = Vector3i(50, 50, 1)
    var radius = 5

    fog.reveal_area(1, center, radius)

    # All tiles in radius should be explored
    assert_true(fog.is_tile_explored(center, 1))
    assert_true(fog.is_tile_explored(Vector3i(55, 50, 1), 1))

    # Tiles outside radius should not be explored
    assert_false(fog.is_tile_explored(Vector3i(60, 60, 1), 1))

func test_fog_persists_when_not_visible():
    var fog = FogOfWar.new(Vector3i(200, 200, 3), 9)
    var position = Vector3i(50, 50, 1)

    # Reveal tile
    fog.update_fog_of_war(0, [position])
    assert_true(fog.is_tile_explored(position, 0))
    assert_true(fog.is_tile_visible(position, 0))

    # Update without that position
    fog.update_fog_of_war(0, [Vector3i(60, 60, 1)])

    # Should still be explored but not visible
    assert_true(fog.is_tile_explored(position, 0))
    assert_false(fog.is_tile_visible(position, 0))
```

#### Map Loading

```gdscript
func test_load_map_success():
    var map_data = MapData.new()
    var result = map_data.load_map("res://data/world/test_map.json")

    assert_true(result)
    assert_eq(map_data.get_map_size(), Vector3i(200, 200, 3))

func test_load_map_file_not_found():
    var map_data = MapData.new()
    var result = map_data.load_map("res://nonexistent.json")

    assert_false(result)

func test_load_map_invalid_json():
    var map_data = MapData.new()
    var result = map_data.load_map("res://data/world/invalid_map.json")

    assert_false(result)
```

#### Serialization

```gdscript
func test_tile_serialization():
    var tile = Tile.new()
    tile.position = Vector3i(10, 20, 1)
    tile.tile_type = Tile.TileType.RESIDENTIAL
    tile.owner_id = 3
    tile.scavenge_value = 75.5

    var dict = tile.to_dict()
    var restored = Tile.from_dict(dict)

    assert_eq(restored.position, tile.position)
    assert_eq(restored.tile_type, tile.tile_type)
    assert_eq(restored.owner_id, tile.owner_id)
    assert_almost_eq(restored.scavenge_value, tile.scavenge_value, 0.01)
```

### Performance Tests (`tests/performance/test_map_performance.gd`)

```gdscript
func test_get_tile_performance():
    var map_data = MapData.new()
    var start_time = Time.get_ticks_msec()

    for i in range(10000):
        var x = randi() % 200
        var y = randi() % 200
        var z = randi() % 3
        var tile = map_data.get_tile(Vector3i(x, y, z))

    var elapsed = Time.get_ticks_msec() - start_time
    var avg_time = elapsed / 10000.0

    assert_lt(avg_time, 1.0, "Average get_tile should be < 1ms")

func test_radius_query_performance():
    var map_data = MapData.new()
    var start_time = Time.get_ticks_msec()

    for i in range(100):
        var center = Vector3i(randi() % 200, randi() % 200, randi() % 3)
        var tiles = map_data.get_tiles_in_radius(center, 10)

    var elapsed = Time.get_ticks_msec() - start_time
    var avg_time = elapsed / 100.0

    assert_lt(avg_time, 10.0, "Average radius query (r=10) should be < 10ms")

func test_fog_update_performance():
    var fog = FogOfWar.new(Vector3i(200, 200, 3), 9)
    var visible_positions = []

    # Create ~100 visible positions (typical unit vision)
    for i in range(100):
        visible_positions.append(Vector3i(randi() % 200, randi() % 200, 1))

    var start_time = Time.get_ticks_msec()

    fog.update_fog_of_war(0, visible_positions)

    var elapsed = Time.get_ticks_msec() - start_time

    assert_lt(elapsed, 20.0, "Fog update should be < 20ms")

func test_map_load_performance():
    var map_data = MapData.new()
    var start_time = Time.get_ticks_msec()

    var result = map_data.load_map("res://data/world/full_map.json")

    var elapsed = Time.get_ticks_msec() - start_time

    assert_true(result)
    assert_lt(elapsed, 500.0, "Map load should be < 500ms")
```

### Integration Tests (`tests/integration/test_map_integration.gd`)

```gdscript
func test_map_with_event_bus():
    # Verify events are emitted correctly
    var map_data = MapData.new()
    var signal_received = false
    var captured_args = []

    EventBus.tile_captured.connect(func(pos, old, new):
        signal_received = true
        captured_args = [pos, old, new]
    )

    map_data.update_tile_owner(Vector3i(10, 10, 1), 5)

    assert_true(signal_received)
    assert_eq(captured_args[0], Vector3i(10, 10, 1))
    assert_eq(captured_args[2], 5)

func test_fog_of_war_with_multiple_factions():
    var fog = FogOfWar.new(Vector3i(200, 200, 3), 9)

    # Faction 0 sees area A
    fog.reveal_area(0, Vector3i(50, 50, 1), 5)

    # Faction 1 sees area B
    fog.reveal_area(1, Vector3i(100, 100, 1), 5)

    # Faction 0 should not see area B
    assert_true(fog.is_tile_explored(Vector3i(50, 50, 1), 0))
    assert_false(fog.is_tile_explored(Vector3i(100, 100, 1), 0))

    # Faction 1 should not see area A
    assert_true(fog.is_tile_explored(Vector3i(100, 100, 1), 1))
    assert_false(fog.is_tile_explored(Vector3i(50, 50, 1), 1))
```

---

## Map Data Format (JSON)

### Map File Structure

```json
{
  "version": "1.0",
  "size": {
    "x": 200,
    "y": 200,
    "z": 3
  },
  "tiles": [
    {
      "position": {"x": 0, "y": 0, "z": 0},
      "tile_type": "RESIDENTIAL",
      "terrain": "BUILDING",
      "scavenge_value": 50.0,
      "movement_cost": 2,
      "cover_value": 2,
      "elevation": 0,
      "is_passable": true,
      "unique_location_id": ""
    }
  ],
  "unique_locations": [
    {
      "id": "city_hall",
      "name": "Old City Hall",
      "position": {"x": 100, "y": 100, "z": 1},
      "tier": 4
    }
  ]
}
```

### Validation Rules

1. **Map size must be 200x200x3**
2. **Tile positions must be within bounds**
3. **Tile types must be valid enum values**
4. **Scavenge values must be 0.0-100.0**
5. **Movement costs must be positive integers**
6. **Cover values must be 0-3**

---

## Implementation Notes

### Grid Storage Optimization

Use a flat 1D array with calculated indexing:

```gdscript
# Convert 3D position to 1D index
func _pos_to_index(position: Vector3i) -> int:
    return position.x + (position.y * 200) + (position.z * 200 * 200)

# Access tile
var tiles: Array[Tile] = []  # Size: 40,000
var index = _pos_to_index(Vector3i(10, 20, 1))
var tile = tiles[index]
```

### Fog of War Bit Packing

Use PackedByteArray with bit manipulation:

```gdscript
# 2 bits per tile per faction: [explored, visible]
# faction_id * 2 bits per tile
var fog_data: PackedByteArray  # Size: 9 factions × 40,000 tiles × 2 bits ÷ 8 = 90,000 bytes

func _get_fog_bits(position: Vector3i, faction_id: int) -> int:
    var tile_index = _pos_to_index(position)
    var bit_index = (tile_index * 9 + faction_id) * 2
    var byte_index = bit_index / 8
    var bit_offset = bit_index % 8

    var byte_value = fog_data[byte_index]
    return (byte_value >> bit_offset) & 0b11
```

### Spatial Query Caching

```gdscript
var _tile_type_cache: Dictionary = {}  # tile_type -> Array[Tile]
var _owner_cache: Dictionary = {}      # owner_id -> Array[Tile]
var _cache_dirty: bool = true

func _invalidate_cache():
    _cache_dirty = true
    _tile_type_cache.clear()
    _owner_cache.clear()
```

---

## Dependencies on Other Modules

### From Map System to Other Modules

Map System is Layer 1 (Foundation) and does not depend on game systems. However, other modules depend on Map System:

- **Unit System**: Uses map for unit positioning and movement
- **Combat System**: Uses map for terrain modifiers and line of sight
- **Economy System**: Uses map for resource tile queries
- **AI System**: Uses map for strategic planning and pathfinding
- **Rendering System**: Renders map tiles

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-12 | Initial interface contract |

---

## Approval

- [ ] Agent 2 (Map System) - Implementation ready
- [ ] Agent 1 (Core Foundation) - EventBus compatibility verified
- [ ] Integration Coordinator - Interface contract approved

---

**Next Steps**:
1. Review and approve interface contract
2. Implement Map System following this contract
3. Write unit tests as specified
4. Validate performance benchmarks
5. Integrate with Core Foundation in Phase 3
