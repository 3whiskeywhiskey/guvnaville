# ADR-007: Programming Language and Framework Selection

## Status
**Accepted**

## Context

We need to select a programming language and framework for developing Ashes to Empire with specific constraints:

1. **Cross-platform development**: Develop on macOS Apple Silicon, deploy to Windows (no Windows test environment available)
2. **Parallel AI agent development**: Multiple AI agents will work on different modules simultaneously
3. **Minimal human testing**: Comprehensive automated testing required
4. **Complex game systems**: 40,000 tile grid, deep simulation, turn-based strategy
5. **Performance requirements**: Smooth 60 FPS, < 5s AI turns
6. **Maintainability**: Clear, testable code that AI agents can understand and modify

### Options Considered

#### Option A: Python with Pygame/Arcade
**Pros**:
- Excellent for AI agent development (clear, readable syntax)
- Rich ecosystem for testing (pytest, hypothesis)
- Rapid development and iteration
- Cross-platform support
- Easy JSON/data handling
- Strong scientific/numeric libraries (NumPy)

**Cons**:
- Performance concerns for 40,000 tiles
- GIL limits true multithreading
- Slower than compiled languages
- Distribution requires bundling interpreter
- Type safety requires additional tooling (mypy)

#### Option B: Rust with ggez/macroquad
**Pros**:
- Excellent performance (compiled, native)
- Memory safety without garbage collection
- Cross-compilation to Windows from macOS
- Strong type system prevents bugs
- Modern tooling (cargo)

**Cons**:
- Steeper learning curve for AI agents
- Slower development iteration
- Complex lifetimes and ownership
- Smaller ecosystem for game development
- More verbose error handling

#### Option C: C# with MonoGame
**Pros**:
- Proven for game development (used in Stardew Valley, Celeste)
- Good performance (JIT compiled)
- Strong type system
- Good cross-platform support
- Familiar OOP patterns

**Cons**:
- .NET runtime required
- Less ideal for AI agent development (more verbose than Python)
- Larger deployment size
- Ecosystem fragmentation (Framework vs Core vs 5+)

#### Option D: TypeScript with Phaser/PixiJS
**Pros**:
- Excellent for AI agent development (readable, widely understood)
- Strong type system (TypeScript)
- Great tooling and ecosystem
- Easy deployment (web or Electron)
- Fast iteration
- Good cross-platform story

**Cons**:
- Performance limitations for complex simulation
- JavaScript quirks despite TypeScript
- Electron bloat for desktop apps
- Less mature for complex strategy games

#### Option E: Python with Godot (via GDScript/Python bindings) ⭐
**Pros**:
- Godot handles rendering, input, windowing (platform abstraction)
- Python for game logic (AI-friendly)
- Excellent cross-platform support (export to Windows from macOS)
- Open source, no licensing issues
- Built-in editor for debugging
- Strong community
- Good performance (Godot engine is C++)
- Scene system for UI
- Built-in testing framework

**Cons**:
- Two-language system (GDScript + Python or just GDScript)
- Python bindings experimental
- GDScript learning curve

#### Option F: Pure Godot with GDScript ⭐⭐ (RECOMMENDED)
**Pros**:
- Python-like syntax (easy for AI agents)
- Excellent cross-platform export (one-click Windows build from macOS)
- Built-in editor, debugger, profiler
- Scene-based UI system
- Handles all platform abstraction
- No external dependencies
- Strong typing available (GDScript 2.0)
- Active development and community
- Open source (MIT license)
- Built-in automated testing (GUT framework)
- Export templates for all platforms

**Cons**:
- GDScript is domain-specific (less transferable knowledge)
- Smaller ecosystem than Python/JS
- Less familiar to some AI agents initially

## Decision

**We will use Godot Engine 4.x with GDScript as the primary language.**

For performance-critical subsystems (pathfinding, large simulations), we will write C# plugins within Godot.

### Hybrid Approach: GDScript + C# Modules

```
┌─────────────────────────────────────┐
│         Godot Engine (GDScript)     │
│  ┌──────────────────────────────┐   │
│  │   Game Logic (GDScript)      │   │
│  │   - Turn management          │   │
│  │   - UI/Rendering             │   │
│  │   - Event system             │   │
│  │   - AI coordination          │   │
│  └──────────────────────────────┘   │
│               │                      │
│  ┌────────────▼─────────────────┐   │
│  │ Performance Modules (C#)     │   │
│  │ - Pathfinding engine         │   │
│  │ - Combat calculation         │   │
│  │ - Map generation             │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Rationale

### Cross-Platform Excellence
Godot provides **one-click export** to Windows, macOS, and Linux from any platform. This solves our primary constraint of developing on macOS and deploying to Windows without a test environment.

```bash
# Export to Windows from macOS
godot --export "Windows Desktop" builds/AshesToEmpire.exe
```

### AI Agent Friendly

**GDScript syntax (Python-like)**:
```gdscript
# Easy to read and write for AI agents
class_name Unit extends Node2D

var health: int = 100
var attack: int = 20

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    queue_free()
```

This is far more readable for AI agents than Rust or even TypeScript.

### Built-in Testing Framework

Godot has GUT (Godot Unit Test), similar to pytest:

```gdscript
extends GutTest

func test_unit_takes_damage():
    var unit = Unit.new()
    unit.health = 100
    unit.take_damage(30)
    assert_eq(unit.health, 70, "Unit should have 70 health")

func test_unit_dies_at_zero_health():
    var unit = Unit.new()
    unit.health = 10
    unit.take_damage(10)
    assert_true(unit.is_queued_for_deletion(), "Unit should be dead")
```

### Modular Architecture for Parallel Development

Godot's scene system naturally supports modular development:

```
game/
├── core/
│   ├── GameState.gd
│   ├── TurnManager.gd
│   └── SaveManager.gd
├── map/
│   ├── MapData.gd
│   ├── Tile.gd
│   └── FogOfWar.gd
├── units/
│   ├── Unit.gd
│   ├── UnitManager.gd
│   └── abilities/
├── combat/
│   ├── CombatResolver.gd
│   ├── TacticalCombat.gd
│   └── CombatCalculator.gd
├── economy/
│   ├── ResourceManager.gd
│   └── ProductionSystem.gd
└── ui/
    ├── MainMenu.tscn
    ├── HUD.tscn
    └── MapView.tscn
```

Each directory is a module that can be developed independently.

### Performance

For performance-critical code, we use C# modules:

**C# Pathfinding Module**:
```csharp
// modules/pathfinding/Pathfinding.cs
using Godot;
using System.Collections.Generic;

public partial class Pathfinding : Node
{
    [Export] public TileMap Map { get; set; }

    public List<Vector2I> FindPath(Vector2I start, Vector2I goal)
    {
        // Optimized A* in C#
        // ...
    }
}
```

**Called from GDScript**:
```gdscript
var pathfinding = Pathfinding.new()
var path = pathfinding.find_path(start_pos, goal_pos)
```

### Data-Driven Design

Godot supports JSON natively:

```gdscript
# Load unit data
func load_unit_types() -> Dictionary:
    var file = FileAccess.open("res://data/units/unit_types.json", FileAccess.READ)
    var json = JSON.parse_string(file.get_as_text())
    return json
```

### Automated Testing Without Windows

**CI/CD with GitHub Actions**:
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Godot
        run: |
          wget https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_linux.x86_64.zip
          unzip Godot_v4.2-stable_linux.x86_64.zip
      - name: Run tests
        run: |
          ./Godot_v4.2-stable_linux.x86_64 --headless --path . -s addons/gut/gut_cmdln.gd

  build-windows:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Godot
        run: # ... setup Godot
      - name: Export Windows Build
        run: |
          ./Godot_v4.2-stable_linux.x86_64 --headless --export "Windows Desktop" builds/AshesToEmpire.exe
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: windows-build
          path: builds/AshesToEmpire.exe
```

### Community and Ecosystem

- **Active community**: Godot has exploded in popularity
- **Tutorials**: Extensive documentation and tutorials
- **Asset library**: Plugins and tools
- **Open source**: MIT license, full engine source available
- **Indie-proven**: Many successful indie games built with Godot

## Consequences

### Positive
- ✅ One-click cross-platform export (solves primary constraint)
- ✅ AI-friendly language (GDScript similar to Python)
- ✅ Built-in editor, debugger, profiler
- ✅ Excellent testing support
- ✅ Modular architecture by design
- ✅ No licensing costs or restrictions
- ✅ Performance escape hatch (C# for hot paths)
- ✅ Data-driven design naturally supported
- ✅ Strong community and documentation

### Negative
- ⚠️ GDScript is domain-specific (less transferable than Python)
  - *Mitigation*: Very similar to Python, AI agents can learn quickly
- ⚠️ Godot 4.x is relatively new (less mature than Unity)
  - *Mitigation*: We're building turn-based strategy, not AAA 3D; Godot is stable enough
- ⚠️ Smaller ecosystem than Unity/Unreal
  - *Mitigation*: Strategy games don't need heavy asset stores
- ⚠️ Two-language system (GDScript + C#) adds complexity
  - *Mitigation*: Most code will be GDScript; C# only for performance-critical modules

### Technical Implications
- Use Godot 4.2 or later (stable release)
- GDScript for 90% of code
- C# for performance-critical systems (pathfinding, simulation)
- JSON for all game data
- GUT framework for automated testing
- GitHub Actions for CI/CD

### Development Workflow
1. AI agents primarily write GDScript
2. Performance bottlenecks identified through profiling
3. Hot paths rewritten in C# if needed
4. All changes tested in headless mode
5. Cross-platform builds generated automatically

## Alternatives Considered

**Python + Pygame**: More familiar but lacks platform abstraction and deployment story.

**Rust**: Best performance but too complex for parallel AI agent development.

**Unity**: Licensing concerns and C# verbosity make it less ideal for AI agents.

**Custom engine**: Too much effort reinventing platform abstraction.

## Related Decisions
- ADR-008: Game Engine Architecture
- ADR-009: Data Storage and Serialization
- ADR-010: Testing and CI/CD Strategy

## References
- [Godot Engine](https://godotengine.org/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [Godot C# Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/)

## Date
2025-11-12

## Authors
Architecture Team
