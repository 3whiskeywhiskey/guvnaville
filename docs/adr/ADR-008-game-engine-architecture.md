# ADR-008: Game Engine Architecture

## Status
**Accepted**

## Context

Given our decision to use Godot Engine (ADR-007), we need to determine how to architect the game within Godot's framework. The architecture must support:

1. **Modular development**: Different AI agents working on different systems in parallel
2. **Testability**: Comprehensive automated testing without UI
3. **Separation of concerns**: Game logic independent from presentation
4. **Performance**: Efficient handling of 40,000 tiles and complex simulations
5. **Maintainability**: Clear structure that AI agents can navigate

### Options Considered

#### Option A: Traditional Godot Scene-Heavy Architecture
- UI scenes contain game logic
- Nodes directly manage game state
- Heavy use of signals between scenes
- State stored in scene tree

**Pros**: Idiomatic Godot, visual scene editor powerful
**Cons**: Tight coupling between UI and logic, hard to test, difficult for parallel development

#### Option B: Pure GDScript MVC Pattern
- Model: Plain GDScript classes (no Node inheritance)
- View: Godot scenes (UI only)
- Controller: Autoloaded singletons managing flow

**Pros**: Clean separation, testable, familiar pattern
**Cons**: Fights Godot's node system, loses engine benefits

#### Option C: Hybrid Data-Node Architecture (RECOMMENDED) ⭐
- Core game state in pure GDScript classes (no Node)
- Godot Nodes as thin wrappers for presentation
- Autoloaded managers coordinate systems
- Clear boundaries between logic and rendering

**Pros**: Best of both worlds, testable, performant, modular
**Cons**: Requires discipline to maintain separation

## Decision

**We will use a Hybrid Data-Node Architecture with the following structure:**

```
Autoloaded Managers (Singletons)
    ├── GameManager (orchestrates game loop)
    ├── TurnManager (turn processing)
    ├── EventBus (decoupled communication)
    └── DataLoader (game data)
            ↓
Core Logic (Pure GDScript Classes)
    ├── GameState (data only)
    ├── FactionState (data only)
    ├── Combat Calculator (pure functions)
    └── PathfindingEngine (algorithms)
            ↓
Godot Nodes (Presentation Layer)
    ├── MapView (renders tiles)
    ├── UnitSprite (renders units)
    ├── UIManager (manages screens)
    └── CameraController (player view)
```

## Architecture Details

### Layer 1: Data Classes (Pure GDScript)

**No Node inheritance**, pure data and algorithms:

```gdscript
# core/game_state.gd
class_name GameState

var turn_number: int = 1
var world_state: WorldState
var factions: Array[FactionState]
var event_queue: Array[GameEvent]

func duplicate() -> GameState:
    # Deep copy for simulation
    var copy = GameState.new()
    copy.turn_number = turn_number
    copy.world_state = world_state.duplicate()
    # ... copy all data
    return copy

func to_dict() -> Dictionary:
    # Serialization for save/load
    return {
        "turn_number": turn_number,
        "world_state": world_state.to_dict(),
        "factions": factions.map(func(f): return f.to_dict()),
        "event_queue": event_queue.map(func(e): return e.to_dict())
    }

static func from_dict(data: Dictionary) -> GameState:
    var state = GameState.new()
    state.turn_number = data["turn_number"]
    state.world_state = WorldState.from_dict(data["world_state"])
    # ... load all data
    return state
```

This class has:
- **No dependencies on Godot Nodes**
- **Serializable** to/from Dictionary
- **Deep copyable** for AI simulation
- **Testable** without any rendering

### Layer 2: System Managers (Autoloaded Singletons)

**Autoloaded nodes** that orchestrate systems:

```gdscript
# core/game_manager.gd (Autoloaded as "Game")
extends Node

var state: GameState
var config: GameConfig

signal game_started
signal turn_processed
signal game_ended(winner: FactionState)

func _ready():
    config = DataLoader.load_game_config()

func start_new_game(settings: GameSettings) -> void:
    state = GameState.new()
    state.initialize(settings)
    game_started.emit()

func process_turn() -> void:
    TurnManager.process_turn(state)
    turn_processed.emit()

func save_game(save_name: String) -> void:
    var save_data = state.to_dict()
    SaveManager.save_to_file(save_name, save_data)

func load_game(save_name: String) -> void:
    var save_data = SaveManager.load_from_file(save_name)
    state = GameState.from_dict(save_data)
    game_started.emit()
```

### Layer 3: Presentation Layer (Godot Scenes/Nodes)

**Thin wrappers** that render and handle input:

```gdscript
# ui/map/map_view.gd
extends Node2D

@onready var tile_layer = $TileLayer
@onready var unit_layer = $UnitLayer

func _ready():
    Game.game_started.connect(_on_game_started)
    Game.turn_processed.connect(_on_turn_processed)

func _on_game_started():
    _render_map(Game.state.world_state.map)

func _on_turn_processed():
    _update_visible_tiles()
    _update_units()

func _render_map(map: MapData):
    for tile in map.tiles:
        var tile_sprite = _create_tile_sprite(tile)
        tile_layer.add_child(tile_sprite)

func _update_units():
    # Only update what's visible and changed
    for unit_id in _get_visible_units():
        var unit_node = unit_layer.get_node_or_null(str(unit_id))
        if unit_node:
            unit_node.update_from_state(Game.state.get_unit(unit_id))
```

### Event Bus Pattern

**Decoupled communication** between systems:

```gdscript
# core/event_bus.gd (Autoloaded as "EventBus")
extends Node

# Signals for game events
signal resource_changed(faction_id: int, resource_type: String, amount: int)
signal unit_moved(unit_id: int, from: Vector3i, to: Vector3i)
signal combat_started(attacker_units: Array, defender_units: Array)
signal combat_ended(result: CombatResult)
signal building_captured(building_id: int, old_owner: int, new_owner: int)
signal faction_defeated(faction_id: int)
signal victory_achieved(faction_id: int, victory_type: String)

# Systems connect to these signals
# UI updates, AI reactions, achievements, etc.
```

**Benefits**:
- Systems don't directly reference each other
- Easy to add new systems listening to events
- Clear communication flow
- Testable (can emit events in tests)

## Project Structure

```
ashes_to_empire/
├── project.godot
├── export_presets.cfg
│
├── addons/
│   └── gut/                    # Testing framework
│
├── assets/                     # Art, audio, fonts
│   ├── sprites/
│   ├── audio/
│   └── fonts/
│
├── data/                       # JSON game data
│   ├── units/
│   ├── buildings/
│   ├── culture/
│   ├── technologies/
│   ├── events/
│   └── world/
│
├── core/                       # Core game logic (Pure GDScript)
│   ├── autoload/
│   │   ├── game_manager.gd     # Orchestrates game
│   │   ├── turn_manager.gd     # Turn processing
│   │   ├── event_bus.gd        # Event system
│   │   ├── data_loader.gd      # Load JSON data
│   │   └── save_manager.gd     # Save/load games
│   │
│   ├── state/                  # Game state classes
│   │   ├── game_state.gd
│   │   ├── faction_state.gd
│   │   ├── world_state.gd
│   │   └── turn_state.gd
│   │
│   └── types/                  # Data types
│       ├── tile.gd
│       ├── unit.gd
│       ├── building.gd
│       └── resource.gd
│
├── systems/                    # Game systems (Pure GDScript)
│   ├── map/
│   │   ├── map_data.gd
│   │   ├── map_generator.gd
│   │   └── fog_of_war.gd
│   │
│   ├── units/
│   │   ├── unit_manager.gd
│   │   ├── unit_factory.gd
│   │   └── abilities/
│   │
│   ├── combat/
│   │   ├── combat_resolver.gd
│   │   ├── combat_calculator.gd
│   │   └── tactical_combat.gd
│   │
│   ├── economy/
│   │   ├── resource_manager.gd
│   │   ├── production_system.gd
│   │   └── trade_system.gd
│   │
│   ├── culture/
│   │   ├── culture_tree.gd
│   │   └── culture_effects.gd
│   │
│   ├── ai/
│   │   ├── faction_ai.gd
│   │   ├── tactical_ai.gd
│   │   └── diplomacy_ai.gd
│   │
│   └── events/
│       ├── event_manager.gd
│       └── event_trigger.gd
│
├── ui/                         # Godot scenes and UI
│   ├── screens/
│   │   ├── main_menu.tscn
│   │   ├── game_screen.tscn
│   │   └── settings.tscn
│   │
│   ├── hud/
│   │   ├── resource_bar.tscn
│   │   ├── turn_indicator.tscn
│   │   └── minimap.tscn
│   │
│   ├── map/
│   │   ├── map_view.tscn
│   │   ├── tile_sprite.gd
│   │   └── unit_sprite.gd
│   │
│   └── dialogs/
│       ├── event_dialog.tscn
│       └── combat_dialog.tscn
│
├── modules/                    # C# performance modules
│   ├── pathfinding/
│   │   └── Pathfinding.cs
│   └── simulation/
│       └── FastSimulation.cs
│
└── tests/                      # GUT tests
    ├── unit/
    │   ├── test_game_state.gd
    │   ├── test_combat.gd
    │   └── test_economy.gd
    │
    ├── integration/
    │   ├── test_turn_processing.gd
    │   └── test_save_load.gd
    │
    └── system/
        └── test_full_game.gd
```

## Autoload Configuration

In `project.godot`:
```ini
[autoload]

EventBus="*res://core/autoload/event_bus.gd"
DataLoader="*res://core/autoload/data_loader.gd"
SaveManager="*res://core/autoload/save_manager.gd"
Game="*res://core/autoload/game_manager.gd"
TurnManager="*res://core/autoload/turn_manager.gd"
```

**Order matters**: EventBus first, Game last.

## Testing Strategy

### Unit Tests (Pure Logic)

```gdscript
# tests/unit/test_combat.gd
extends GutTest

var combat_calculator: CombatCalculator

func before_each():
    combat_calculator = CombatCalculator.new()

func test_attacker_wins_with_superior_strength():
    var attacker = _create_unit(UnitType.SOLDIER, 80)
    var defender = _create_unit(UnitType.MILITIA, 50)
    var terrain = Terrain.new()

    var result = combat_calculator.calculate_auto_resolve([attacker], [defender], terrain)

    assert_eq(result.outcome, CombatOutcome.ATTACKER_VICTORY)
    assert_gt(result.defender_casualties, result.attacker_casualties)

func _create_unit(type: UnitType, hp: int) -> Unit:
    var unit = Unit.new()
    unit.type = type
    unit.current_hp = hp
    unit.stats = DataLoader.get_unit_stats(type)
    return unit
```

**No Godot nodes needed** - pure logic testing.

### Integration Tests (System Interaction)

```gdscript
# tests/integration/test_turn_processing.gd
extends GutTest

var game_state: GameState

func before_each():
    game_state = GameState.new()
    game_state.initialize(_get_test_settings())

func test_full_turn_cycle():
    var initial_turn = game_state.turn_number
    var initial_resources = game_state.factions[0].resources.food

    TurnManager.process_turn(game_state)

    assert_eq(game_state.turn_number, initial_turn + 1)
    assert_ne(game_state.factions[0].resources.food, initial_resources)
```

### Headless Testing

```bash
# Run all tests headlessly (no GUI)
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

## Performance Optimization

### C# for Hot Paths

For performance-critical systems, use C#:

```csharp
// modules/pathfinding/Pathfinding.cs
using Godot;
using System.Collections.Generic;
using System.Linq;

[GlobalClass]
public partial class Pathfinding : Node
{
    private readonly PriorityQueue<Vector2I, float> _openSet = new();
    private readonly Dictionary<Vector2I, float> _gScore = new();

    public List<Vector2I> FindPath(Vector2I start, Vector2I goal, int movementRange)
    {
        // Optimized A* implementation
        // 10-100x faster than GDScript for pathfinding
    }
}
```

Called from GDScript:
```gdscript
var pathfinding = Pathfinding.new()
var path = pathfinding.find_path(start_tile, goal_tile, unit.movement)
```

### Culling and LOD

```gdscript
# ui/map/map_view.gd
func _update_visible_tiles():
    var camera_rect = _get_camera_rect()

    # Only update tiles in view
    for tile in Game.state.world_state.get_tiles_in_rect(camera_rect):
        if not _visible_tiles.has(tile.id):
            _render_tile(tile)
            _visible_tiles[tile.id] = true

    # Remove tiles outside view
    for tile_id in _visible_tiles.keys():
        if not camera_rect.has_point(tile_id.position):
            _remove_tile(tile_id)
            _visible_tiles.erase(tile_id)
```

## Development Workflow

### Module Development

Each AI agent works on a specific module:

**Agent 1: Combat System**
```
systems/combat/
├── combat_resolver.gd
├── combat_calculator.gd
└── tactical_combat.gd

tests/unit/
└── test_combat.gd
```

**Agent 2: Economy System**
```
systems/economy/
├── resource_manager.gd
├── production_system.gd
└── trade_system.gd

tests/unit/
└── test_economy.gd
```

Agents can work **in parallel** because:
- Systems are independent
- Communication via EventBus (signals)
- Tests run in isolation
- No shared mutable state

### Integration Points

Systems integrate via EventBus:

```gdscript
# Agent 1's code
# systems/combat/combat_resolver.gd
func resolve_combat(attacker, defender):
    var result = _calculate_result(attacker, defender)
    EventBus.combat_ended.emit(result)
    return result

# Agent 2's code
# systems/economy/resource_manager.gd
func _ready():
    EventBus.combat_ended.connect(_on_combat_ended)

func _on_combat_ended(result: CombatResult):
    # Award loot to winner
    add_resources(result.winner, result.loot)
```

No direct coupling between systems!

## Consequences

### Positive
- ✅ Clear separation between logic and presentation
- ✅ Pure GDScript classes are easily testable
- ✅ Modular architecture enables parallel development
- ✅ Autoloaded managers provide single source of truth
- ✅ EventBus decouples systems
- ✅ Performance escape hatch with C# modules
- ✅ Godot's strengths (rendering, input, scenes) fully utilized
- ✅ AI agents can focus on logic without worrying about rendering

### Negative
- ⚠️ Requires discipline to maintain separation
  - *Mitigation*: Linting rules, code review, clear documentation
- ⚠️ More boilerplate than pure scene-based architecture
  - *Mitigation*: Templates and generators
- ⚠️ EventBus can become cluttered with many signals
  - *Mitigation*: Organize signals by category, document well

### Technical Implications
- Core logic must not extend Node (except managers)
- All data classes implement `to_dict()` and `from_dict()`
- All data classes implement `duplicate()` for deep copy
- UI code only reads state, never modifies directly
- All game logic changes go through managers

### Development Guidelines
1. **Never put game logic in scene scripts** - only presentation
2. **Always emit events** when state changes
3. **Test pure logic first** before UI
4. **Use C# sparingly** - only for proven bottlenecks
5. **Document autoload dependencies** clearly

## Related Decisions
- ADR-007: Programming Language and Framework Selection
- ADR-009: Data Storage and Serialization
- ADR-011: AI Development and Parallel Agent Architecture

## References
- [Godot Autoload Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [Godot C# Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/)

## Date
2025-11-12

## Authors
Architecture Team
