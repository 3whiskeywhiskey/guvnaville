# Core Foundation Interface Contract

**Module**: Core Foundation (`core/`)
**Layer**: 0 (No dependencies)
**Version**: 1.0
**Date**: 2025-11-12

## Overview

The Core Foundation module provides the foundational infrastructure for the entire game. It manages game state, turn processing, event communication, data loading, and save/load functionality. All other modules depend on this module.

**Key Responsibilities**:
- Game state management and serialization
- Turn-based game loop orchestration
- Global event bus for module communication
- JSON data loading and validation
- Save/load system with integrity checks

---

## 1. EventBus (Singleton)

**File**: `core/autoload/event_bus.gd`
**Purpose**: Central event bus for decoupled communication between all game systems.

### Signals

#### Game Lifecycle
```gdscript
signal game_started(game_state: GameState)
signal game_loaded(game_state: GameState)
signal game_ended(victory_type: String, winning_faction: int)
signal game_paused()
signal game_resumed()
```

#### Turn Management
```gdscript
signal turn_started(turn_number: int, active_faction: int)
signal turn_phase_changed(phase: TurnPhase)
signal turn_ended(turn_number: int)
signal faction_turn_started(faction_id: int)
signal faction_turn_ended(faction_id: int)
```

#### Map & World
```gdscript
signal tile_captured(position: Vector3i, old_owner: int, new_owner: int)
signal tile_scavenged(position: Vector3i, resources_found: Dictionary)
signal tile_visibility_changed(position: Vector3i, faction_id: int, visibility_level: int)
signal building_constructed(position: Vector3i, building_type: String, faction_id: int)
signal building_destroyed(position: Vector3i, building_type: String)
signal unique_location_discovered(location_id: String, faction_id: int)
```

#### Units
```gdscript
signal unit_created(unit_id: String, unit_type: String, faction_id: int, position: Vector3i)
signal unit_destroyed(unit_id: String, faction_id: int, position: Vector3i)
signal unit_moved(unit_id: String, from_position: Vector3i, to_position: Vector3i)
signal unit_promoted(unit_id: String, new_rank: int)
signal unit_healed(unit_id: String, amount: int)
signal unit_damaged(unit_id: String, amount: int)
```

#### Combat
```gdscript
signal combat_started(attacker_ids: Array, defender_ids: Array, position: Vector3i)
signal combat_resolved(outcome: Dictionary)
signal unit_retreated(unit_id: String, from_position: Vector3i, to_position: Vector3i)
signal morale_broken(unit_id: String)
```

#### Resources & Economy
```gdscript
signal resource_changed(faction_id: int, resource_type: String, amount: int, new_total: int)
signal resource_shortage(faction_id: int, resource_type: String, deficit: int)
signal production_completed(faction_id: int, item_type: String, item_id: String)
signal production_started(faction_id: int, item_type: String)
signal trade_route_established(faction_a: int, faction_b: int)
signal trade_route_broken(faction_a: int, faction_b: int)
```

#### Culture
```gdscript
signal culture_points_gained(faction_id: int, points: int)
signal culture_node_unlocked(faction_id: int, node_id: String, axis: String)
signal culture_bonus_applied(faction_id: int, bonus_type: String, value: float)
```

#### Events
```gdscript
signal event_triggered(event_id: String, faction_id: int)
signal event_choice_made(event_id: String, choice_index: int, faction_id: int)
signal event_consequence_applied(event_id: String, faction_id: int, consequences: Dictionary)
```

#### AI
```gdscript
signal ai_decision_made(faction_id: int, decision_type: String, details: Dictionary)
signal ai_error(faction_id: int, error_message: String)
```

### Methods

None (signals only).

### Dependencies

None.

### Performance Requirements

- Signal emission: < 0.1ms
- Maximum listeners per signal: 100

### Test Specifications

**Unit Tests**:
```gdscript
# tests/unit/test_event_bus.gd
func test_signal_emission():
    var received = false
    EventBus.turn_started.connect(func(turn, faction): received = true)
    EventBus.turn_started.emit(1, 0)
    assert_true(received, "Signal should be received")

func test_multiple_listeners():
    var count = 0
    EventBus.unit_created.connect(func(a,b,c,d): count += 1)
    EventBus.unit_created.connect(func(a,b,c,d): count += 1)
    EventBus.unit_created.emit("unit_1", "militia", 0, Vector3i.ZERO)
    assert_eq(count, 2, "Both listeners should receive signal")
```

---

## 2. GameManager (Singleton)

**File**: `core/autoload/game_manager.gd`
**Purpose**: Orchestrates high-level game flow and manages the current game state.

### Properties

```gdscript
var current_state: GameState  # Current game state (null if no game active)
var is_game_active: bool  # True if game in progress
var is_paused: bool  # True if game paused
```

### Methods

#### start_new_game(settings: Dictionary) -> GameState
Initializes a new game with the provided settings.

**Parameters**:
- `settings: Dictionary` - Game configuration
  - `num_factions: int` - Number of AI factions (1-8)
  - `difficulty: String` - "easy", "normal", "hard", "brutal"
  - `map_seed: int` - Random seed for map generation (optional, default: random)
  - `player_faction_id: int` - Player's faction ID (0 = player, 1-8 = AI)

**Returns**: `GameState` - Initialized game state

**Emits**: `EventBus.game_started(game_state)`

**Errors**:
- Invalid settings (invalid faction count, unknown difficulty)
- Data not loaded (DataLoader.load_game_data() must be called first)

**Performance**: < 1s

**Example**:
```gdscript
var settings = {
    "num_factions": 4,
    "difficulty": "normal",
    "map_seed": 12345,
    "player_faction_id": 0
}
var state = GameManager.start_new_game(settings)
```

---

#### load_game(save_name: String) -> GameState
Loads a saved game.

**Parameters**:
- `save_name: String` - Name of the save file (without extension)

**Returns**: `GameState` - Loaded game state

**Emits**: `EventBus.game_loaded(game_state)`

**Errors**:
- Save file not found
- Save file corrupted (checksum mismatch)
- Save file version incompatible

**Performance**: < 3s

---

#### save_game(save_name: String) -> bool
Saves the current game.

**Parameters**:
- `save_name: String` - Name for the save file (without extension)

**Returns**: `bool` - true if save successful, false otherwise

**Errors**:
- No active game
- Disk write error
- Invalid save name

**Performance**: < 2s

---

#### end_game(victory_type: String, winning_faction: int) -> void
Ends the current game.

**Parameters**:
- `victory_type: String` - Type of victory ("military", "cultural", "technological", "diplomatic", "survival")
- `winning_faction: int` - ID of winning faction (-1 for no winner)

**Emits**: `EventBus.game_ended(victory_type, winning_faction)`

**Performance**: < 0.1s

---

#### pause_game() -> void
Pauses the game.

**Emits**: `EventBus.game_paused()`

**Performance**: < 0.01s

---

#### resume_game() -> void
Resumes the game.

**Emits**: `EventBus.game_resumed()`

**Performance**: < 0.01s

---

#### get_faction(faction_id: int) -> FactionState
Returns the state for a specific faction.

**Parameters**:
- `faction_id: int` - Faction ID (0-8)

**Returns**: `FactionState` or null if invalid ID

**Performance**: O(1), < 0.01ms

---

### Dependencies

- DataLoader (for game data)
- SaveManager (for save/load)
- TurnManager (for turn processing)

### Error Conditions

- Starting game without loaded data → Error
- Loading non-existent save → Error
- Saving with no active game → Error

### Performance Requirements

- New game initialization: < 1s
- Load game: < 3s
- Save game: < 2s
- State queries: < 0.01ms

### Test Specifications

**Unit Tests**:
```gdscript
func test_start_new_game():
    var settings = {"num_factions": 2, "difficulty": "normal", "player_faction_id": 0}
    var state = GameManager.start_new_game(settings)
    assert_not_null(state)
    assert_eq(state.turn_number, 1)
    assert_eq(state.factions.size(), 2)

func test_save_and_load():
    GameManager.start_new_game(default_settings)
    var success = GameManager.save_game("test_save")
    assert_true(success)

    var loaded_state = GameManager.load_game("test_save")
    assert_not_null(loaded_state)
    assert_eq(loaded_state.turn_number, GameManager.current_state.turn_number)

func test_pause_resume():
    GameManager.start_new_game(default_settings)
    GameManager.pause_game()
    assert_true(GameManager.is_paused)
    GameManager.resume_game()
    assert_false(GameManager.is_paused)
```

---

## 3. TurnManager (Singleton)

**File**: `core/autoload/turn_manager.gd`
**Purpose**: Manages turn-based game loop and turn phases.

### Enums

```gdscript
enum TurnPhase {
    MOVEMENT,       # Units can move
    COMBAT,         # Combat resolution
    ECONOMY,        # Resource collection and production
    CULTURE,        # Culture point accumulation
    EVENTS,         # Event processing
    END_TURN        # Cleanup and preparation for next turn
}
```

### Properties

```gdscript
var current_phase: TurnPhase  # Current turn phase
var active_faction: int  # Currently active faction ID
```

### Methods

#### process_turn() -> void
Processes a complete turn for all factions.

**Flow**:
1. For each faction (player first, then AI):
   - Process all turn phases
   - Wait for player input or AI decisions
2. Increment turn counter
3. Check victory conditions

**Emits**:
- `EventBus.turn_started(turn_number, faction_id)` (for each faction)
- `EventBus.turn_phase_changed(phase)` (for each phase)
- `EventBus.turn_ended(turn_number)`

**Performance**: < 5s per full turn (all factions, AI processing included)

---

#### process_phase(phase: TurnPhase, faction_id: int) -> void
Processes a specific turn phase for a faction.

**Parameters**:
- `phase: TurnPhase` - Phase to process
- `faction_id: int` - Faction ID

**Emits**: `EventBus.turn_phase_changed(phase)`

**Performance**: < 1s per phase

---

#### end_faction_turn(faction_id: int) -> void
Ends the current faction's turn and moves to next faction.

**Parameters**:
- `faction_id: int` - Faction ending their turn

**Emits**: `EventBus.faction_turn_ended(faction_id)`

**Performance**: < 0.1s

---

#### skip_phase(phase: TurnPhase) -> void
Skips a phase (for debugging/testing).

**Parameters**:
- `phase: TurnPhase` - Phase to skip

**Performance**: < 0.01s

---

### Dependencies

- GameManager (for current game state)
- EventBus (for phase notifications)

### Error Conditions

- Processing turn with no active game → Error
- Invalid phase transition → Warning

### Performance Requirements

- Full turn processing: < 5s (including AI)
- Phase transition: < 0.1s
- Player turn processing: < 1s

### Test Specifications

**Unit Tests**:
```gdscript
func test_turn_phases():
    var game = GameManager.start_new_game(default_settings)
    var phases_seen = []

    EventBus.turn_phase_changed.connect(func(phase): phases_seen.append(phase))

    TurnManager.process_turn()

    assert_true(TurnPhase.MOVEMENT in phases_seen)
    assert_true(TurnPhase.COMBAT in phases_seen)
    assert_true(TurnPhase.ECONOMY in phases_seen)

func test_turn_increment():
    var game = GameManager.start_new_game(default_settings)
    var initial_turn = game.turn_number

    TurnManager.process_turn()

    assert_eq(game.turn_number, initial_turn + 1)
```

**Integration Tests**:
```gdscript
func test_multi_faction_turn():
    var game = GameManager.start_new_game({"num_factions": 3, "difficulty": "normal"})

    var faction_turns = 0
    EventBus.faction_turn_ended.connect(func(id): faction_turns += 1)

    TurnManager.process_turn()

    assert_eq(faction_turns, 3, "All 3 factions should take turns")
```

---

## 4. DataLoader (Singleton)

**File**: `core/autoload/data_loader.gd`
**Purpose**: Loads and validates all JSON game data.

### Properties

```gdscript
var unit_types: Dictionary  # UnitType -> Unit definition
var building_types: Dictionary  # BuildingType -> Building definition
var culture_trees: Dictionary  # CultureAxis -> Tree structure
var event_definitions: Array  # All event definitions
var unique_locations: Array  # All unique location data
var tile_types: Dictionary  # TileType -> Tile definition
var resource_definitions: Dictionary  # ResourceType -> Resource definition
var is_data_loaded: bool  # True if data loaded successfully
```

### Methods

#### load_game_data() -> bool
Loads all game data from JSON files.

**Returns**: `bool` - true if all data loaded successfully

**Errors**:
- File not found
- JSON parse error
- Schema validation failure

**Performance**: < 2s (initial load), data cached afterwards

**Example**:
```gdscript
if DataLoader.load_game_data():
    print("Game data loaded successfully")
    print("Loaded %d unit types" % DataLoader.unit_types.size())
```

---

#### reload_data() -> bool
Reloads all game data (for hot-reloading during development).

**Returns**: `bool` - true if reload successful

**Performance**: < 2s

---

#### validate_data() -> Dictionary
Validates all loaded data and returns validation report.

**Returns**: `Dictionary` with structure:
```gdscript
{
    "valid": bool,
    "errors": Array[String],
    "warnings": Array[String]
}
```

**Performance**: < 1s

---

#### get_unit_definition(unit_type: String) -> Dictionary
Returns the definition for a specific unit type.

**Parameters**:
- `unit_type: String` - Unit type identifier

**Returns**: `Dictionary` - Unit definition or empty dict if not found

**Performance**: O(1), < 0.01ms

---

#### get_building_definition(building_type: String) -> Dictionary
Returns the definition for a specific building type.

**Parameters**:
- `building_type: String` - Building type identifier

**Returns**: `Dictionary` - Building definition or empty dict if not found

**Performance**: O(1), < 0.01ms

---

### Dependencies

None (reads from filesystem only).

### Error Conditions

- Missing data files → Error with specific file path
- Invalid JSON → Error with line number
- Schema validation failure → Error with field name
- Duplicate IDs → Error with conflicting IDs

### Performance Requirements

- Initial load: < 2s
- Data queries: < 0.01ms (O(1) dictionary lookups)
- Validation: < 1s

### Test Specifications

**Unit Tests**:
```gdscript
func test_load_game_data():
    var success = DataLoader.load_game_data()
    assert_true(success, "Should load game data")
    assert_true(DataLoader.is_data_loaded)
    assert_gt(DataLoader.unit_types.size(), 0, "Should have unit types")

func test_validate_data():
    DataLoader.load_game_data()
    var report = DataLoader.validate_data()
    assert_true(report.valid, "Data should be valid")
    assert_eq(report.errors.size(), 0, "Should have no errors")

func test_get_unit_definition():
    DataLoader.load_game_data()
    var militia_def = DataLoader.get_unit_definition("militia")
    assert_false(militia_def.is_empty(), "Should find militia definition")
    assert_true("attack" in militia_def, "Should have attack stat")
```

---

## 5. SaveManager (Singleton)

**File**: `core/autoload/save_manager.gd`
**Purpose**: Handles game save/load with integrity verification.

### Properties

```gdscript
var save_directory: String  # Platform-specific save directory
var autosave_enabled: bool  # True if autosaves enabled
var autosave_interval: int  # Turns between autosaves
```

### Methods

#### save_game(save_name: String, game_state: GameState) -> bool
Saves a game state to disk.

**Parameters**:
- `save_name: String` - Name for the save file
- `game_state: GameState` - State to save

**Returns**: `bool` - true if save successful

**Save Format**:
```json
{
    "version": "1.0.0",
    "save_name": "My Game",
    "timestamp": "2025-11-12T10:30:00Z",
    "turn_number": 125,
    "game_state": { ... },
    "checksums": {
        "game_state": "abc123...",
        "world_state": "def456..."
    }
}
```

**Errors**:
- Disk write error
- Serialization error
- Invalid save name (contains invalid characters)

**Performance**: < 2s

---

#### load_game(save_name: String) -> GameState
Loads a game state from disk.

**Parameters**:
- `save_name: String` - Name of save file to load

**Returns**: `GameState` - Loaded game state or null if error

**Errors**:
- File not found
- Checksum mismatch (corrupted save)
- Version incompatible
- Deserialization error

**Performance**: < 3s

---

#### list_saves() -> Array[Dictionary]
Lists all available save files.

**Returns**: `Array[Dictionary]` where each entry contains:
```gdscript
{
    "name": String,
    "timestamp": String,
    "turn_number": int,
    "factions": int,
    "file_size": int
}
```

**Performance**: < 0.5s

---

#### delete_save(save_name: String) -> bool
Deletes a save file.

**Parameters**:
- `save_name: String` - Name of save to delete

**Returns**: `bool` - true if deletion successful

**Performance**: < 0.1s

---

#### get_save_directory() -> String
Returns the platform-specific save directory path.

**Returns**: `String` - Absolute path to save directory

**Performance**: < 0.01ms

---

#### verify_save_integrity(save_name: String) -> bool
Verifies save file integrity using checksums.

**Parameters**:
- `save_name: String` - Save file to verify

**Returns**: `bool` - true if integrity check passes

**Performance**: < 1s

---

#### create_autosave(game_state: GameState) -> bool
Creates an autosave (overwrites previous autosave).

**Parameters**:
- `game_state: GameState` - State to save

**Returns**: `bool` - true if autosave successful

**Performance**: < 2s

---

### Dependencies

- GameState (for serialization)

### Error Conditions

- Save to read-only directory → Error
- Load corrupted file → Error with details
- Disk full → Error
- Concurrent save operations → Queue or error

### Performance Requirements

- Save game: < 2s
- Load game: < 3s
- List saves: < 0.5s
- Integrity check: < 1s

### Test Specifications

**Unit Tests**:
```gdscript
func test_save_and_load():
    var game_state = GameState.new()
    game_state.turn_number = 42

    var success = SaveManager.save_game("test_save", game_state)
    assert_true(success, "Save should succeed")

    var loaded = SaveManager.load_game("test_save")
    assert_not_null(loaded)
    assert_eq(loaded.turn_number, 42)

func test_save_integrity():
    var game_state = GameState.new()
    SaveManager.save_game("integrity_test", game_state)

    var valid = SaveManager.verify_save_integrity("integrity_test")
    assert_true(valid, "Save should be valid")

func test_list_saves():
    SaveManager.save_game("save1", GameState.new())
    SaveManager.save_game("save2", GameState.new())

    var saves = SaveManager.list_saves()
    assert_gte(saves.size(), 2, "Should have at least 2 saves")
```

---

## 6. State Classes

### GameState

**File**: `core/state/game_state.gd`
**Purpose**: Main game state container.

#### Properties

```gdscript
var turn_number: int  # Current turn number
var world_state: WorldState  # World and map state
var factions: Array[FactionState]  # All faction states
var turn_state: TurnState  # Current turn state
var event_queue: Array  # Pending events
var victory_conditions: Dictionary  # Victory condition tracking
var game_settings: Dictionary  # Game configuration
var random_seed: int  # Random seed for deterministic replay
```

#### Methods

```gdscript
func to_dict() -> Dictionary  # Serialize to dictionary
func from_dict(data: Dictionary) -> void  # Deserialize from dictionary
func clone() -> GameState  # Deep copy for simulation
func validate() -> bool  # Validate state integrity
func get_faction(faction_id: int) -> FactionState  # Get faction by ID
```

**Performance**:
- Serialization: < 500ms
- Deserialization: < 500ms
- Clone: < 200ms
- Validate: < 100ms

---

### FactionState

**File**: `core/state/faction_state.gd`
**Purpose**: State for a single faction.

#### Properties

```gdscript
var faction_id: int  # Unique faction ID
var faction_name: String  # Faction name
var is_player: bool  # True if human player
var is_alive: bool  # True if faction not defeated
var resources: Dictionary  # Resource stockpiles
var culture: Dictionary  # Culture progression
var units: Array  # Unit IDs owned by this faction
var buildings: Array  # Building IDs owned by this faction
var controlled_tiles: Array[Vector3i]  # Tile positions controlled
var diplomacy: Dictionary  # Diplomatic relations
var ai_personality: String  # AI personality type (if AI)
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
func add_resource(resource_type: String, amount: int) -> void
func remove_resource(resource_type: String, amount: int) -> bool
func has_resource(resource_type: String, amount: int) -> bool
```

---

### WorldState

**File**: `core/state/world_state.gd`
**Purpose**: World and map state.

#### Properties

```gdscript
var map_width: int  # Map width (200)
var map_height: int  # Map height (200)
var map_depth: int  # Map depth/layers (3)
var tiles: Dictionary  # Vector3i -> Tile
var unique_locations: Array  # Unique location instances
var fog_of_war: Dictionary  # faction_id -> Array[Vector3i] (visible tiles)
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
func get_tile(position: Vector3i) -> Tile
func set_tile(position: Vector3i, tile: Tile) -> void
func is_valid_position(position: Vector3i) -> bool
```

**Performance**:
- get_tile: O(1), < 0.01ms
- set_tile: O(1), < 0.01ms

---

### TurnState

**File**: `core/state/turn_state.gd`
**Purpose**: Current turn state.

#### Properties

```gdscript
var current_turn: int  # Current turn number
var current_phase: int  # Current TurnPhase
var active_faction: int  # Currently active faction ID
var actions_this_turn: Array  # Actions taken this turn (for logging)
var time_elapsed: float  # Real-time elapsed this turn
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
func reset_for_new_turn() -> void
```

---

## 7. Type Classes

### Unit

**File**: `core/types/unit.gd`
**Purpose**: Unit data class.

#### Properties

```gdscript
var unit_id: String  # Unique unit ID
var unit_type: String  # Unit type (references DataLoader)
var faction_id: int  # Owning faction
var position: Vector3i  # Current position
var max_hp: int  # Maximum hit points
var current_hp: int  # Current hit points
var attack: int  # Attack stat
var defense: int  # Defense stat
var movement: int  # Movement points
var morale: int  # Morale (0-100)
var experience: int  # Experience points
var rank: int  # Unit rank (0=Rookie, 1=Veteran, 2=Elite, 3=Legendary)
var abilities: Array[String]  # Ability IDs
var status_effects: Array  # Active status effects
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
func take_damage(amount: int) -> void
func heal(amount: int) -> void
func gain_experience(amount: int) -> void
func check_promotion() -> bool  # Returns true if promoted
```

---

### Tile

**File**: `core/types/tile.gd`
**Purpose**: Tile data class.

#### Properties

```gdscript
var position: Vector3i  # Tile position
var tile_type: String  # Tile type (Residential, Commercial, etc.)
var terrain_type: String  # Terrain type (Rubble, Building, etc.)
var owner: int  # Faction ID or -1 for unclaimed
var building: String  # Building ID or "" for none
var units: Array[String]  # Unit IDs on this tile
var scavenge_value: int  # Remaining scavenge value (0-100)
var visibility: Dictionary  # faction_id -> visibility_level
var hazards: Array  # Active hazards
var movement_cost: int  # Movement cost to enter
var defense_bonus: int  # Defense bonus from terrain
var elevation: int  # Elevation level (0=underground, 1=ground, 2=elevated)
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
func add_unit(unit_id: String) -> void
func remove_unit(unit_id: String) -> void
func set_owner(faction_id: int) -> void
func deplete_scavenge(amount: int) -> int  # Returns actual amount depleted
```

---

### Building

**File**: `core/types/building.gd`
**Purpose**: Building data class.

#### Properties

```gdscript
var building_id: String  # Unique building ID
var building_type: String  # Building type (references DataLoader)
var faction_id: int  # Owning faction
var position: Vector3i  # Tile position
var max_hp: int  # Maximum hit points
var current_hp: int  # Current hit points
var is_operational: bool  # True if functional
var production_bonus: Dictionary  # Resource production bonuses
var garrison: Array[String]  # Garrisoned unit IDs
var effects: Array  # Active building effects
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
func take_damage(amount: int) -> void
func repair(amount: int) -> void
func add_garrison(unit_id: String) -> bool
func remove_garrison(unit_id: String) -> bool
```

---

### Resource

**File**: `core/types/resource.gd`
**Purpose**: Resource definition class.

#### Properties

```gdscript
var resource_type: String  # Resource type identifier
var display_name: String  # Human-readable name
var description: String  # Description
var icon_path: String  # Path to icon asset
var is_stockpiled: bool  # True if resource stockpiled
var is_strategic: bool  # True if strategic resource
var base_value: int  # Base trade value
```

#### Methods

```gdscript
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
```

---

## 8. Error Conditions

### Critical Errors (Stop Execution)

1. **Data Loading Failure**: Game data files missing or corrupted
2. **Save Corruption**: Checksum mismatch on load
3. **State Validation Failure**: Game state integrity check fails
4. **Memory Allocation Failure**: Cannot allocate required memory

### Recoverable Errors (Log and Continue)

1. **Invalid Action**: AI or player attempts invalid action
2. **Resource Deficit**: Faction tries to spend unavailable resources
3. **Autosave Failure**: Autosave fails but game continues
4. **Event Trigger Failure**: Event fails to trigger but game continues

### Warnings (Log Only)

1. **Performance Degradation**: Frame time exceeds target
2. **Large Save File**: Save file size unusually large
3. **Missing Optional Data**: Optional content missing

---

## 9. Performance Requirements

### Critical Path Performance

| Operation | Target | Maximum |
|-----------|--------|---------|
| EventBus signal emission | < 0.1ms | 1ms |
| Game state serialization | < 500ms | 2s |
| Game state deserialization | < 500ms | 2s |
| Save game | < 2s | 5s |
| Load game | < 3s | 10s |
| Start new game | < 1s | 3s |
| Process single turn phase | < 1s | 3s |
| Full turn (all factions) | < 5s | 15s |
| Data loading (initial) | < 2s | 5s |
| State validation | < 100ms | 500ms |

### Memory Requirements

- Maximum game state size: < 500MB
- Maximum save file size: < 50MB (uncompressed), < 10MB (compressed)
- Data cache size: < 100MB

---

## 10. Test Specifications

### Unit Tests (95% coverage target)

**EventBus Tests** (`tests/unit/test_event_bus.gd`):
- Signal emission and reception
- Multiple listener support
- Signal parameter passing
- Disconnection

**GameManager Tests** (`tests/unit/test_game_manager.gd`):
- New game creation
- Save/load game
- Pause/resume
- Faction queries
- Error handling

**TurnManager Tests** (`tests/unit/test_turn_manager.gd`):
- Turn phase progression
- Multi-faction turn processing
- Phase skipping
- Turn counter increment

**DataLoader Tests** (`tests/unit/test_data_loader.gd`):
- Data loading from JSON
- Data validation
- Definition queries
- Error handling for missing files

**SaveManager Tests** (`tests/unit/test_save_manager.gd`):
- Save game
- Load game
- List saves
- Delete save
- Integrity verification
- Autosave functionality

**State Classes Tests** (`tests/unit/test_state_classes.gd`):
- Serialization (to_dict)
- Deserialization (from_dict)
- Round-trip accuracy
- Deep cloning
- Validation

**Type Classes Tests** (`tests/unit/test_type_classes.gd`):
- Unit creation and modification
- Tile state management
- Building functionality
- Resource definitions

### Integration Tests

**State Persistence** (`tests/integration/test_state_persistence.gd`):
```gdscript
func test_save_load_preserves_exact_state():
    var game = GameManager.start_new_game(default_settings)
    game.world_state.get_tile(Vector3i(5, 5, 1)).owner = 1
    game.factions[0].resources["scrap"] = 999

    SaveManager.save_game("test", game)
    var loaded = SaveManager.load_game("test")

    assert_eq(loaded.world_state.get_tile(Vector3i(5, 5, 1)).owner, 1)
    assert_eq(loaded.factions[0].resources["scrap"], 999)
```

**Turn Processing** (`tests/integration/test_turn_processing.gd`):
```gdscript
func test_full_turn_cycle():
    var game = GameManager.start_new_game({"num_factions": 2, "difficulty": "normal"})
    var initial_turn = game.turn_number

    TurnManager.process_turn()

    assert_eq(game.turn_number, initial_turn + 1)
    # Verify all phases executed
```

**Event Communication** (`tests/integration/test_event_communication.gd`):
```gdscript
func test_cross_module_events():
    var events_received = []
    EventBus.unit_created.connect(func(a,b,c,d): events_received.append("unit_created"))
    EventBus.turn_started.connect(func(a,b): events_received.append("turn_started"))

    GameManager.start_new_game(default_settings)

    assert_true("turn_started" in events_received)
```

### Performance Tests

**Benchmark** (`tests/performance/test_core_benchmarks.gd`):
```gdscript
func test_save_load_performance():
    var game = GameManager.start_new_game(default_settings)

    var start = Time.get_ticks_msec()
    SaveManager.save_game("perf_test", game)
    var save_time = Time.get_ticks_msec() - start

    start = Time.get_ticks_msec()
    SaveManager.load_game("perf_test")
    var load_time = Time.get_ticks_msec() - start

    assert_lt(save_time, 2000, "Save should complete in < 2s")
    assert_lt(load_time, 3000, "Load should complete in < 3s")
```

---

## 11. Dependencies

**No external module dependencies** (Layer 0).

**System Dependencies**:
- Godot 4.5.1 Engine
- Filesystem access for save/load
- JSON parsing capability

---

## 12. Integration Points

Other modules will depend on Core Foundation as follows:

**Map System** depends on:
- `EventBus` for tile events
- `WorldState` for map data
- `Tile` type class

**Unit System** depends on:
- `EventBus` for unit events
- `FactionState` for unit ownership
- `Unit` type class

**Combat System** depends on:
- `EventBus` for combat events
- `Unit` type class
- `Tile` type class

**Economy System** depends on:
- `EventBus` for resource events
- `FactionState` for resource management
- `Resource` type class

**Culture System** depends on:
- `EventBus` for culture events
- `FactionState` for culture progression
- `DataLoader` for culture tree data

**AI System** depends on:
- `GameState` for decision making
- All EventBus signals for observation
- `TurnManager` for turn awareness

**Event System** depends on:
- `EventBus` for event notifications
- `GameState` for event evaluation
- `DataLoader` for event definitions

**UI System** depends on:
- All EventBus signals for updates
- `GameState` for display (read-only)
- All type classes for rendering

**Rendering System** depends on:
- `WorldState` for map rendering
- `Unit` for unit rendering
- `Building` for building rendering

---

## 13. Version Compatibility

**Save Format Version**: 1.0.0

**Compatibility Rules**:
- Patch version changes (1.0.x): Full backward compatibility
- Minor version changes (1.x.0): Backward compatible with migration
- Major version changes (x.0.0): May require new save files

**Migration Strategy**:
- SaveManager includes version migration system
- Old saves can be loaded and re-saved in new format
- Deprecated fields handled gracefully

---

## Document Control

**Version**: 1.0
**Status**: Draft
**Last Updated**: 2025-11-12
**Author**: Agent 1 (Core Foundation)
**Reviewers**: TBD
**Approval**: Pending
