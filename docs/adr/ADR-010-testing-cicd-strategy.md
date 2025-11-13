# ADR-010: Testing and CI/CD Strategy for Cross-Platform Development

## Status
**Accepted**

## Context

We face unique constraints for testing and deployment:

1. **Development on macOS Apple Silicon** only
2. **No Windows test environment** available during development
3. **Must deploy to Windows** (primary target platform)
4. **Parallel AI agent development** requires comprehensive automated testing
5. **Minimal human testing** - must catch bugs automatically
6. **Complex game logic** - 40,000 tiles, deep systems interactions

### Key Challenges

- How do we ensure Windows compatibility without Windows?
- How do we test UI/rendering without manual testing?
- How do we validate AI agents' code changes automatically?
- How do we handle cross-platform differences?

### Options Considered

#### Option A: Manual Testing Only
Rely on community beta testers for Windows validation

**Pros**: Simple development process
**Cons**: High bug risk, slow feedback, unprofessional

#### Option B: Wine/CrossOver for Windows Testing
Run Windows builds on macOS using Wine

**Pros**: Some Windows validation
**Cons**: Wine is not real Windows, bugs can slip through, limited

#### Option C: Comprehensive Automated Testing + CI/CD (RECOMMENDED) ⭐
Multi-layered automated testing with cross-platform CI/CD

**Pros**: Catches bugs early, fast feedback, professional
**Cons**: Requires investment in test infrastructure

## Decision

**We will implement a comprehensive automated testing strategy with multi-layer testing and cross-platform CI/CD.**

### Testing Pyramid

```
           ┌─────────────────┐
          │   E2E Tests     │
         │  (Full games)    │
        └───────────────────┘
       ┌─────────────────────┐
      │  Integration Tests   │
     │  (System interactions) │
    └───────────────────────────┘
   ┌──────────────────────────────┐
  │        Unit Tests             │
 │   (Pure logic, individual      │
│      functions/classes)         │
└─────────────────────────────────┘
```

**Distribution**:
- 70% Unit Tests (fast, isolated)
- 20% Integration Tests (cross-system)
- 10% E2E Tests (full simulation)

### CI/CD Pipeline

```
┌──────────────────────────────────────────────────────────┐
│                   GitHub Actions                          │
└──────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────┴──────────────────┐
        │                                      │
   ┌────▼────┐                           ┌────▼────┐
   │  macOS  │                           │  Linux  │
   │ Runner  │                           │ Runner  │
   └────┬────┘                           └────┬────┘
        │                                      │
    ┌───▼────┐                           ┌────▼────┐
    │ Build  │                           │  Build  │
    │ Test   │                           │  Test   │
    │ macOS  │                           │  Linux  │
    └────────┘                           └────┬────┘
                                              │
                                         ┌────▼─────┐
                                         │Cross-comp│
                                         │ Windows  │
                                         └────┬─────┘
                                              │
                                         ┌────▼─────┐
                                         │ Smoke    │
                                         │ Test     │
                                         └──────────┘
```

## Testing Strategy

### Level 1: Unit Tests (70% of tests)

**Pure GDScript logic** - no Godot nodes or rendering:

```gdscript
# tests/unit/test_combat_calculator.gd
extends GutTest

var calculator: CombatCalculator

func before_each():
    calculator = CombatCalculator.new()

func test_attack_damage_calculation():
    var attacker_stats = {"attack": 20, "hp_percent": 1.0, "morale": 100}
    var defender_stats = {"defense": 10}
    var modifiers = {"terrain": 1.0, "elevation": 1.0}

    var damage = calculator.calculate_damage(attacker_stats, defender_stats, modifiers)

    assert_eq(damage, 10, "Damage should be attack - defense")

func test_morale_affects_combat():
    var attacker_stats = {"attack": 20, "hp_percent": 1.0, "morale": 50}  # Low morale
    var defender_stats = {"defense": 10}
    var modifiers = {"terrain": 1.0, "elevation": 1.0}

    var damage = calculator.calculate_damage(attacker_stats, defender_stats, modifiers)

    assert_lt(damage, 10, "Low morale should reduce damage")

func test_elevation_bonus():
    var attacker_stats = {"attack": 20, "hp_percent": 1.0, "morale": 100}
    var defender_stats = {"defense": 10}
    var modifiers = {"terrain": 1.0, "elevation": 1.25}  # +25% from elevation

    var damage = calculator.calculate_damage(attacker_stats, defender_stats, modifiers)

    assert_eq(damage, 15, "Elevation should provide +25% attack")

func test_minimum_damage():
    var attacker_stats = {"attack": 5, "hp_percent": 1.0, "morale": 100}
    var defender_stats = {"defense": 50}  # Defense >> Attack
    var modifiers = {"terrain": 1.0, "elevation": 1.0}

    var damage = calculator.calculate_damage(attacker_stats, defender_stats, modifiers)

    assert_gte(damage, 5, "Minimum damage should be enforced")
```

**Coverage Target**: 90%+ for core logic

### Level 2: Integration Tests (20% of tests)

**System interactions** - multiple modules working together:

```gdscript
# tests/integration/test_economy_turn.gd
extends GutTest

var game_state: GameState
var resource_manager: ResourceManager
var production_system: ProductionSystem

func before_each():
    game_state = _create_test_game_state()
    resource_manager = ResourceManager.new()
    production_system = ProductionSystem.new()

func test_population_consumes_food_per_turn():
    var faction = game_state.factions[0]
    faction.population = 10
    faction.resources.food = 100

    resource_manager.process_consumption(faction)

    # 10 pops * 1 food/pop = 10 food consumed
    assert_eq(faction.resources.food, 90)

func test_production_with_resource_shortage():
    var faction = game_state.factions[0]
    faction.production_queue.append({"type": "soldier", "progress": 0})
    faction.resources.scrap = 5  # Not enough (needs 30)

    production_system.process_production(faction)

    # Should not complete production
    assert_eq(faction.production_queue.size(), 1)
    assert_eq(faction.production_queue[0].progress, 0)

func test_full_economic_turn():
    var faction = game_state.factions[0]
    var initial_food = faction.resources.food

    # Process income
    resource_manager.process_income(faction)
    # Process consumption
    resource_manager.process_consumption(faction)
    # Process production
    production_system.process_production(faction)

    # Verify state changed
    assert_ne(faction.resources.food, initial_food)
    assert_true(faction.resources.scrap >= 0, "Resources should not go negative")
```

### Level 3: System Tests (10% of tests)

**Full game simulations** - AI vs AI playthroughs:

```gdscript
# tests/system/test_full_game_simulation.gd
extends GutTest

func test_ai_vs_ai_game_completes():
    var game = Game.new()
    game.start_new_game({
        "all_ai": true,
        "num_factions": 4,
        "max_turns": 300,
        "fast_mode": true,
        "seed": 12345
    })

    var turns_processed = 0
    var max_iterations = 300

    while not game.has_winner() and turns_processed < max_iterations:
        game.process_turn()
        turns_processed += 1

    # Game should end in victory or turn limit
    assert_true(game.has_winner() or turns_processed >= max_iterations)

func test_deterministic_replay():
    var seed = 99999

    # Run 1
    var game1 = Game.new()
    game1.start_new_game({"all_ai": true, "seed": seed})
    for i in range(50):
        game1.process_turn()
    var state1_checksum = game1.state.get_checksum()

    # Run 2
    var game2 = Game.new()
    game2.start_new_game({"all_ai": true, "seed": seed})
    for i in range(50):
        game2.process_turn()
    var state2_checksum = game2.state.get_checksum()

    assert_eq(state1_checksum, state2_checksum, "Games should be deterministic")

func test_save_load_round_trip():
    var game = Game.new()
    game.start_new_game({"all_ai": true, "seed": 11111})

    # Play 20 turns
    for i in range(20):
        game.process_turn()

    var pre_save_checksum = game.state.get_checksum()

    # Save
    SaveManager.save_game("round_trip_test", game.state)

    # Load
    var loaded_state = SaveManager.load_game("round_trip_test")
    var post_load_checksum = loaded_state.get_checksum()

    assert_eq(pre_save_checksum, post_load_checksum, "Save/load should be lossless")

    # Clean up
    DirAccess.remove_absolute("user://saves/round_trip_test.json")
```

### Headless Testing

All tests run **without rendering**:

```bash
# Run all tests headlessly
godot --headless --path . -s addons/gut/gut_cmdln.gd

# Run specific test suite
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_combat_calculator.gd

# Generate coverage report
godot --headless --path . -s addons/gut/gut_cmdln.gd -gcoverage=true
```

### Performance Tests

```gdscript
# tests/performance/test_performance.gd
extends GutTest

func test_pathfinding_performance():
    var map_data = _create_large_map(200, 200)
    var pathfinding = Pathfinding.new()

    var start_time = Time.get_ticks_msec()

    # Find 100 paths
    for i in range(100):
        var start = Vector2i(randi() % 200, randi() % 200)
        var goal = Vector2i(randi() % 200, randi() % 200)
        pathfinding.find_path(start, goal, 10)

    var elapsed = Time.get_ticks_msec() - start_time

    assert_lt(elapsed, 1000, "100 pathfinding operations should take < 1 second")

func test_turn_processing_performance():
    var game = Game.new()
    game.start_new_game({"all_ai": true, "num_factions": 8})

    var start_time = Time.get_ticks_msec()

    game.process_turn()

    var elapsed = Time.get_ticks_msec() - start_time

    assert_lt(elapsed, 5000, "Full turn with 8 AI factions should take < 5 seconds")
```

## CI/CD Pipeline Configuration

### GitHub Actions Workflow

```yaml
# .github/workflows/build-and-test.yml
name: Build and Test

on:
  push:
    branches: [main, develop, "claude/*"]
  pull_request:
    branches: [main, develop]

env:
  GODOT_VERSION: 4.5.1
  EXPORT_NAME: AshesToEmpire

jobs:
  # Job 1: Run tests on Linux (fastest, cheapest)
  test-linux:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Godot
        run: |
          wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64

      - name: Run unit tests
        run: |
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --path . -s addons/gut/gut_cmdln.gd -gdir=tests/unit/

      - name: Run integration tests
        run: |
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --path . -s addons/gut/gut_cmdln.gd -gdir=tests/integration/

      - name: Run system tests
        run: |
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --path . -s addons/gut/gut_cmdln.gd -gdir=tests/system/

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-linux
          path: |
            .gut/*.xml
            .gut/coverage/

  # Job 2: Build macOS version
  build-macos:
    runs-on: macos-latest
    needs: test-linux
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Godot
        run: |
          wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_macos.universal.zip
          unzip Godot_v${GODOT_VERSION}-stable_macos.universal.zip

      - name: Import assets
        run: |
          ./Godot.app/Contents/MacOS/Godot --headless --path . --import

      - name: Export macOS build
        run: |
          mkdir -p builds
          ./Godot.app/Contents/MacOS/Godot --headless --export-release "macOS" builds/${EXPORT_NAME}-macOS.zip

      - name: Upload macOS build
        uses: actions/upload-artifact@v4
        with:
          name: macos-build
          path: builds/${EXPORT_NAME}-macOS.zip

  # Job 3: Build Linux version
  build-linux:
    runs-on: ubuntu-latest
    needs: test-linux
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Godot
        run: |
          wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64

      - name: Download export templates
        run: |
          wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz
          mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
          unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz -d ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable

      - name: Import assets
        run: |
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --path . --import

      - name: Export Linux build
        run: |
          mkdir -p builds
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --export-release "Linux/X11" builds/${EXPORT_NAME}-Linux.x86_64

      - name: Upload Linux build
        uses: actions/upload-artifact@v4
        with:
          name: linux-build
          path: builds/${EXPORT_NAME}-Linux.x86_64

  # Job 4: Cross-compile Windows version
  build-windows:
    runs-on: ubuntu-latest
    needs: test-linux
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Godot
        run: |
          wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64

      - name: Download export templates
        run: |
          wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz
          mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
          unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz -d ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable

      - name: Import assets
        run: |
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --path . --import

      - name: Export Windows build
        run: |
          mkdir -p builds
          ./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --export-release "Windows Desktop" builds/${EXPORT_NAME}-Windows.exe

      - name: Upload Windows build
        uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: builds/${EXPORT_NAME}-Windows.exe

      - name: Smoke test Windows build (Wine)
        run: |
          sudo dpkg --add-architecture i386
          sudo apt-get update
          sudo apt-get install -y wine wine32 wine64
          timeout 30s wine builds/${EXPORT_NAME}-Windows.exe --headless --test-mode || true

  # Job 5: Create release (on tags)
  release:
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    needs: [build-macos, build-linux, build-windows]
    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v4

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            macos-build/*
            linux-build/*
            windows-build/*
```

### Export Presets Configuration

```ini
# export_presets.cfg
[preset.0]
name="macOS"
platform="macOS"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/AshesToEmpire-macOS.zip"

[preset.1]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/AshesToEmpire-Windows.exe"

[preset.2]
name="Linux/X11"
platform="Linux/X11"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/AshesToEmpire-Linux.x86_64"
```

## Handling Windows Compatibility Without Windows

### Strategy Layers

**Layer 1: Platform-Agnostic Core**
- All game logic in pure GDScript (no platform-specific code)
- No direct file system operations (use Godot abstractions)
- No hardcoded paths

**Layer 2: Godot's Cross-Platform Abstraction**
- Godot handles platform differences (file paths, input, rendering)
- Export templates tested by Godot team

**Layer 3: Automated Testing**
- 90%+ code coverage catches logic bugs
- Deterministic tests verify behavior

**Layer 4: Wine Smoke Tests**
- Basic "does it launch?" tests in Wine
- Not comprehensive but catches major issues

**Layer 5: Community Beta Testing**
- Windows users beta test before release
- Issue tracker for Windows-specific bugs

### Automated Windows Validation

```bash
# Run Windows build in Wine (smoke test)
wine AshesToEmpire-Windows.exe --headless --test-mode

# Expected: No crashes, basic functionality works
```

### Platform Abstraction Patterns

```gdscript
# BAD: Platform-specific code
var save_path = "C:\\Users\\Player\\Saves\\"  # Windows only!

# GOOD: Godot abstraction
var save_path = OS.get_user_data_dir() + "/saves/"
# Returns correct path for each platform:
# - macOS: ~/Library/Application Support/AshesToEmpire/saves/
# - Windows: %APPDATA%/AshesToEmpire/saves/
# - Linux: ~/.local/share/AshesToEmpire/saves/
```

## Code Quality Gates

### Pre-Commit Checks
```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running pre-commit checks..."

# Run unit tests (fast)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=tests/unit/ -gexit

if [ $? -ne 0 ]; then
    echo "Unit tests failed. Commit aborted."
    exit 1
fi

echo "Pre-commit checks passed!"
```

### Pull Request Requirements
- All tests pass
- Code coverage >= 90%
- No GDScript errors/warnings
- Performance tests pass

## Continuous Monitoring

### Automated Game Testing
```gdscript
# Run nightly full game simulations
# Tests long-term stability, memory leaks, performance
func nightly_endurance_test():
    for i in range(10):  # 10 full games
        var game = Game.new()
        game.start_new_game({"all_ai": true, "seed": i})

        while not game.has_winner():
            game.process_turn()

        # Log results
        _log_game_result(game)
```

## Consequences

### Positive
- ✅ Comprehensive automated testing catches bugs early
- ✅ Cross-platform builds generated automatically
- ✅ Windows compatibility ensured without Windows machine
- ✅ AI agents get immediate feedback on changes
- ✅ Deterministic testing ensures reliability
- ✅ Performance regression detection
- ✅ Community beta testing as final validation layer

### Negative
- ⚠️ Initial setup effort for CI/CD
  - *Mitigation*: One-time cost, pays dividends long-term
- ⚠️ Wine smoke tests not comprehensive
  - *Mitigation*: Community beta testing catches remaining issues
- ⚠️ Test suite takes time to run
  - *Mitigation*: Fast unit tests run locally, full suite on CI

### Technical Implications
- Must maintain 90%+ test coverage
- All features must be testable headlessly
- Deterministic behavior required (fixed RNG seeds)
- Platform-agnostic code patterns enforced

### Development Workflow
1. AI agent writes code
2. Run unit tests locally (< 10 seconds)
3. Commit and push
4. CI runs full test suite (< 5 minutes)
5. CI builds all platforms
6. Automated deployment to itch.io/Steam (if tests pass)

## Related Decisions
- ADR-007: Programming Language and Framework Selection
- ADR-008: Game Engine Architecture
- ADR-011: AI Development and Parallel Agent Architecture

## References
- [Godot Headless Testing](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [GitHub Actions for Godot](https://github.com/marketplace/actions/godot-export)

## Date
2025-11-12

## Authors
Architecture Team
