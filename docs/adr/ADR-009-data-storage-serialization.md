# ADR-009: Data Storage and Serialization

## Status
**Accepted**

## Context

Ashes to Empire requires robust data storage and serialization for:

1. **Game Content**: Units, buildings, culture trees, events, map data (200+ unique locations)
2. **Save/Load System**: Player save files, autosaves, quick saves
3. **Testing**: Deterministic test data, replay files
4. **Modding Support**: Community content (future consideration)
5. **Localization**: Text in multiple languages

### Requirements

- **Human-readable formats** for game content (easier for AI agents to edit)
- **Version migration** support (game updates don't break saves)
- **Validation**: Catch data errors early
- **Performance**: Fast loading and saving
- **Cross-platform**: Same format on all platforms
- **Determinism**: Identical data produces identical results

### Options Considered

#### Option A: Binary Serialization
Format: Custom binary format or protobuf

**Pros**: Fast, compact, efficient
**Cons**: Not human-readable, hard for AI agents to edit, versioning complex

#### Option B: XML
Format: XML files for all data

**Pros**: Structured, validation with XSD
**Cons**: Verbose, harder to edit manually, slower parsing

#### Option C: JSON (RECOMMENDED) ⭐
Format: JSON for game content and saves

**Pros**: Human-readable, widely supported, easy to edit, Godot native support
**Cons**: Larger file sizes, slower than binary (acceptable for turn-based)

#### Option D: TOML
Format: TOML for configuration

**Pros**: More readable than JSON, good for config
**Cons**: Less universal, Godot has no native support

#### Option E: Hybrid Approach (RECOMMENDED) ⭐⭐
- **JSON** for game content and save files
- **Compressed binary** for autosaves (optional)
- **CSV** for large tabular data (balance tables)
- **TOML** for configuration files

## Decision

**We will use JSON as the primary format with a hybrid approach:**

```
Game Content: JSON (human-readable, AI-editable)
Save Files:   JSON (player saves)
Autosaves:    JSON or compressed (performance)
Config:       JSON (simple)
Localization: JSON (standard i18n format)
Balance Data: CSV or JSON (for large tables)
```

## Data Format Specifications

### 1. Game Content Data (JSON)

**Unit Definitions**:
```json
{
  "version": "1.0",
  "units": [
    {
      "id": "soldier",
      "name": "Soldier",
      "description": "Professional balanced military unit",
      "type": "infantry",
      "cost": {
        "production": 150,
        "scrap": 30,
        "ammunition": 20
      },
      "stats": {
        "max_hp": 80,
        "attack": 20,
        "defense": 10,
        "range": 3,
        "movement": 4,
        "armor": 0,
        "stealth": 0,
        "detection": 0
      },
      "abilities": ["entrench"],
      "requirements": ["military_training_facility"]
    }
  ]
}
```

**Building Definitions**:
```json
{
  "version": "1.0",
  "buildings": [
    {
      "id": "workshop",
      "name": "Workshop",
      "description": "Basic production facility",
      "cost": {
        "production": 100,
        "scrap": 50
      },
      "effects": {
        "production_per_turn": 5
      },
      "requirements": []
    }
  ]
}
```

**Culture Tree**:
```json
{
  "version": "1.0",
  "governance": {
    "autocratic": {
      "tiers": [
        {
          "id": "strongman_rule",
          "name": "Strongman Rule",
          "cost": 100,
          "prerequisites": [],
          "effects": [
            {
              "type": "unit_cost_modifier",
              "unit_type": "militia",
              "modifier": -0.25
            }
          ],
          "unlocks": ["warlord_state"]
        },
        {
          "id": "warlord_state",
          "name": "Warlord State",
          "cost": 250,
          "prerequisites": ["strongman_rule"],
          "effects": [
            {
              "type": "combat_bonus",
              "value": 0.15
            }
          ],
          "unlocks": ["military_dictatorship"]
        }
      ]
    }
  }
}
```

### 2. Save File Format

**Save File Structure**:
```json
{
  "save_version": "1.0.0",
  "game_version": "0.1.0",
  "timestamp": "2025-11-12T10:30:00Z",
  "metadata": {
    "save_name": "The New Order - Turn 125",
    "play_time_seconds": 18450,
    "difficulty": "normal",
    "player_faction": "player_faction_0"
  },
  "game_state": {
    "turn_number": 125,
    "turn_phase": "economy",
    "world_state": {
      "map_seed": 12345,
      "tiles": [
        {
          "id": "tile_0_0_1",
          "position": {"x": 0, "y": 0, "z": 1},
          "type": "residential",
          "terrain": "building",
          "owner": "faction_vault_collective",
          "scavenge_value": 45,
          "building": "workshop_instance_42",
          "units": ["unit_123"],
          "hazards": []
        }
      ],
      "fog_of_war": {
        "player_faction_0": {
          "revealed_tiles": ["tile_0_0_1", "tile_0_1_1"],
          "visible_tiles": ["tile_0_0_1"]
        }
      }
    },
    "factions": [
      {
        "id": "player_faction_0",
        "name": "Player Faction",
        "is_player": true,
        "resources": {
          "scrap": 450,
          "food": 200,
          "medicine": 80,
          "ammunition": 150,
          "fuel": 20,
          "components": 30,
          "water": 180
        },
        "culture": {
          "points": 850,
          "governance_path": "democratic",
          "governance_tier": 2,
          "unlocked_nodes": ["town_council", "representative_democracy"]
        },
        "units": ["unit_123", "unit_124"],
        "buildings": ["workshop_instance_42"],
        "technologies": ["scavenging_1", "industry_2"]
      }
    ],
    "units": [
      {
        "id": "unit_123",
        "type": "soldier",
        "faction": "player_faction_0",
        "position": {"x": 0, "y": 0, "z": 1},
        "current_hp": 65,
        "max_hp": 80,
        "morale": 85,
        "experience": 120,
        "rank": "veteran",
        "movement_remaining": 4,
        "actions_remaining": 2
      }
    ]
  },
  "checksum": "abc123def456789"
}
```

### 3. Localization Format

```json
{
  "locale": "en_US",
  "version": "1.0",
  "ui": {
    "main_menu": {
      "new_game": "New Game",
      "load_game": "Load Game",
      "settings": "Settings",
      "quit": "Quit"
    }
  },
  "units": {
    "soldier": {
      "name": "Soldier",
      "description": "Professional balanced military unit. Can entrench for defensive bonuses."
    }
  },
  "events": {
    "refugee_arrival": {
      "title": "Refugees at the Gates",
      "description": "A group of {count} refugees has arrived, fleeing from {threat}. They beg for shelter and protection.",
      "choices": {
        "accept": "Welcome them (costs {food} food)",
        "turn_away": "Turn them away",
        "conscript": "Conscript them into your army"
      }
    }
  }
}
```

## Data Loading System

### Data Loader (Autoloaded)

```gdscript
# core/autoload/data_loader.gd
extends Node

var unit_types: Dictionary = {}
var building_types: Dictionary = {}
var culture_trees: Dictionary = {}
var event_definitions: Array[GameEvent] = []
var unique_locations: Dictionary = {}

var _schemas: Dictionary = {}

func _ready():
    _load_schemas()
    _validate_and_load_all_data()

func _load_schemas():
    # Load JSON schemas for validation
    _schemas["unit"] = _load_json("res://data/schemas/unit_schema.json")
    _schemas["building"] = _load_json("res://data/schemas/building_schema.json")
    # ... etc

func _validate_and_load_all_data():
    unit_types = _load_and_validate("res://data/units/unit_types.json", "unit")
    building_types = _load_and_validate("res://data/buildings/building_types.json", "building")
    # ... etc

func _load_and_validate(path: String, schema_name: String) -> Dictionary:
    var data = _load_json(path)

    if not _validate_against_schema(data, _schemas[schema_name]):
        push_error("Data validation failed for: " + path)
        return {}

    return data

func _load_json(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("Failed to load: " + path)
        return {}

    var json = JSON.new()
    var parse_result = json.parse(file.get_as_text())

    if parse_result != OK:
        push_error("JSON parse error in: " + path)
        return {}

    return json.data

func _validate_against_schema(data: Dictionary, schema: Dictionary) -> bool:
    # Simple validation (could use external validator)
    # Check required fields, types, ranges, etc.
    return true  # TODO: Implement full validation
```

### Save Manager

```gdscript
# core/autoload/save_manager.gd
extends Node

const SAVE_DIR = "user://saves/"
const AUTOSAVE_DIR = "user://autosaves/"
const MAX_AUTOSAVES = 5

func save_game(save_name: String, game_state: GameState) -> bool:
    var save_data = {
        "save_version": "1.0.0",
        "game_version": ProjectSettings.get_setting("application/config/version"),
        "timestamp": Time.get_datetime_string_from_system(),
        "metadata": _create_metadata(save_name, game_state),
        "game_state": game_state.to_dict(),
        "checksum": ""
    }

    # Calculate checksum
    save_data["checksum"] = _calculate_checksum(save_data["game_state"])

    # Write to file
    var save_path = SAVE_DIR + save_name + ".json"
    return _write_json(save_path, save_data)

func load_game(save_name: String) -> GameState:
    var save_path = SAVE_DIR + save_name + ".json"
    var save_data = _load_json(save_path)

    if not save_data:
        push_error("Failed to load save: " + save_name)
        return null

    # Verify checksum
    var checksum = _calculate_checksum(save_data["game_state"])
    if checksum != save_data["checksum"]:
        push_error("Save file corrupted: " + save_name)
        return null

    # Check version compatibility
    if not _is_compatible_version(save_data["save_version"]):
        save_data = _migrate_save(save_data)

    # Reconstruct game state
    return GameState.from_dict(save_data["game_state"])

func autosave(game_state: GameState) -> bool:
    var autosave_name = "autosave_turn_%d" % game_state.turn_number
    var save_path = AUTOSAVE_DIR + autosave_name + ".json"

    var save_data = {
        "save_version": "1.0.0",
        "game_version": ProjectSettings.get_setting("application/config/version"),
        "timestamp": Time.get_datetime_string_from_system(),
        "game_state": game_state.to_dict()
    }

    var success = _write_json(save_path, save_data)

    if success:
        _cleanup_old_autosaves()

    return success

func _cleanup_old_autosaves():
    var autosaves = _list_files(AUTOSAVE_DIR)
    if autosaves.size() > MAX_AUTOSAVES:
        # Sort by timestamp, delete oldest
        autosaves.sort()
        for i in range(autosaves.size() - MAX_AUTOSAVES):
            DirAccess.remove_absolute(AUTOSAVE_DIR + autosaves[i])

func _calculate_checksum(data: Dictionary) -> String:
    var json_string = JSON.stringify(data)
    return json_string.md5_text()

func _is_compatible_version(save_version: String) -> bool:
    # Check if save version is compatible with current game version
    var current_version = "1.0.0"
    # TODO: Implement semantic versioning comparison
    return save_version == current_version

func _migrate_save(save_data: Dictionary) -> Dictionary:
    # Migrate old save formats to current version
    var from_version = save_data["save_version"]
    push_warning("Migrating save from version: " + from_version)

    # Apply migrations sequentially
    if from_version == "0.9.0":
        save_data = _migrate_0_9_to_1_0(save_data)

    return save_data

func _write_json(path: String, data: Dictionary) -> bool:
    var dir = path.get_base_dir()
    if not DirAccess.dir_exists_absolute(dir):
        DirAccess.make_dir_recursive_absolute(dir)

    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        push_error("Failed to write: " + path)
        return false

    file.store_string(JSON.stringify(data, "\t"))
    return true

func _load_json(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}

    var json = JSON.new()
    var parse_result = json.parse(file.get_as_text())

    if parse_result != OK:
        push_error("JSON parse error in: " + path)
        return {}

    return json.data

func _list_files(dir_path: String) -> Array:
    var files = []
    var dir = DirAccess.open(dir_path)

    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()

        while file_name != "":
            if not dir.current_is_dir():
                files.append(file_name)
            file_name = dir.get_next()

    return files
```

## Data Validation with JSON Schema

**Unit Schema Example**:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Unit Definition",
  "type": "object",
  "required": ["id", "name", "type", "cost", "stats"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-z_]+$"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "type": {
      "type": "string",
      "enum": ["infantry", "vehicle", "specialist"]
    },
    "cost": {
      "type": "object",
      "required": ["production"],
      "properties": {
        "production": {"type": "integer", "minimum": 1},
        "scrap": {"type": "integer", "minimum": 0},
        "ammunition": {"type": "integer", "minimum": 0}
      }
    },
    "stats": {
      "type": "object",
      "required": ["max_hp", "attack", "defense", "range", "movement"],
      "properties": {
        "max_hp": {"type": "integer", "minimum": 1},
        "attack": {"type": "integer", "minimum": 0},
        "defense": {"type": "integer", "minimum": 0},
        "range": {"type": "integer", "minimum": 1},
        "movement": {"type": "integer", "minimum": 1}
      }
    }
  }
}
```

## Serialization Pattern

All serializable classes implement:

```gdscript
class_name GameState

func to_dict() -> Dictionary:
    return {
        "turn_number": turn_number,
        "world_state": world_state.to_dict() if world_state else {},
        "factions": factions.map(func(f): return f.to_dict())
    }

static func from_dict(data: Dictionary) -> GameState:
    var state = GameState.new()
    state.turn_number = data.get("turn_number", 1)
    state.world_state = WorldState.from_dict(data.get("world_state", {}))
    state.factions = data.get("factions", []).map(
        func(f): return FactionState.from_dict(f)
    )
    return state

func duplicate() -> GameState:
    # For AI simulation
    return GameState.from_dict(to_dict())
```

## Performance Optimization

### Compressed Autosaves

```gdscript
func save_compressed(path: String, data: Dictionary) -> bool:
    var json_string = JSON.stringify(data)
    var compressed = json_string.compress(FileAccess.COMPRESSION_GZIP)

    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        return false

    file.store_buffer(compressed)
    return true

func load_compressed(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}

    var compressed = file.get_buffer(file.get_length())
    var json_string = compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()

    var json = JSON.new()
    json.parse(json_string)
    return json.data
```

### Lazy Loading

```gdscript
# Don't load all tiles at once
func load_world_state(data: Dictionary) -> WorldState:
    var world = WorldState.new()
    world.map_seed = data["map_seed"]
    # Load tiles in chunks as needed
    world._tile_data = data["tiles"]  # Store raw data
    world._tiles_loaded = false
    return world

func get_tile(position: Vector3i) -> Tile:
    if not _tiles_loaded:
        _load_tiles_chunk(position)
    return _tiles[position]
```

## Consequences

### Positive
- ✅ Human-readable game content (AI agents can edit)
- ✅ Easy to version control (Git-friendly)
- ✅ Godot native JSON support (no external libraries)
- ✅ Validation prevents data errors
- ✅ Save migration system for updates
- ✅ Checksum validation for corruption detection
- ✅ Cross-platform compatibility
- ✅ Compression option for performance

### Negative
- ⚠️ Larger file sizes than binary
  - *Mitigation*: Acceptable for turn-based game, compression available
- ⚠️ Slower parsing than binary
  - *Mitigation*: Lazy loading, autosaves compressed
- ⚠️ Save files could be manually edited (cheating)
  - *Mitigation*: Checksums detect tampering, not a priority for single-player

### Technical Implications
- All data classes must implement `to_dict()` and `from_dict()`
- JSON schemas must be maintained alongside data
- Save format versioning must be carefully managed
- Large data (40,000 tiles) requires chunking or lazy loading

### Development Guidelines
1. **Always validate JSON** on load (catch errors early)
2. **Use schemas** for all game content
3. **Version all data files** (include version field)
4. **Test save/load** after any data structure change
5. **Document migration path** for version updates
6. **Use compressed saves** for autosaves only
7. **Checksum all saves** to detect corruption

## Testing Strategy

```gdscript
# tests/unit/test_serialization.gd
extends GutTest

func test_game_state_round_trip():
    var original = _create_test_game_state()

    var dict = original.to_dict()
    var restored = GameState.from_dict(dict)

    assert_eq(restored.turn_number, original.turn_number)
    assert_eq(restored.factions.size(), original.factions.size())
    # ... etc

func test_save_load_integrity():
    var original_state = _create_test_game_state()

    SaveManager.save_game("test_save", original_state)
    var loaded_state = SaveManager.load_game("test_save")

    assert_eq(loaded_state.turn_number, original_state.turn_number)
    # Clean up
    DirAccess.remove_absolute("user://saves/test_save.json")

func test_corrupted_save_detection():
    var state = _create_test_game_state()
    SaveManager.save_game("corrupt_test", state)

    # Corrupt the file
    var file = FileAccess.open("user://saves/corrupt_test.json", FileAccess.READ_WRITE)
    file.seek(100)
    file.store_8(0xFF)  # Corrupt data

    var loaded = SaveManager.load_game("corrupt_test")
    assert_null(loaded, "Should detect corruption")
```

## Related Decisions
- ADR-007: Programming Language and Framework Selection
- ADR-008: Game Engine Architecture

## References
- [Godot FileAccess Documentation](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html)
- [Godot JSON Documentation](https://docs.godotengine.org/en/stable/classes/class_json.html)
- [JSON Schema](https://json-schema.org/)

## Date
2025-11-12

## Authors
Architecture Team
