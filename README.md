# Guvnaville

A post-apocalyptic turn-based strategy game where you lead a faction fighting for survival in the ruins of a once-great city.

## Overview

**Guvnaville** is a turn-based strategy game set in the post-apocalyptic ruins of a city. Lead your faction to survive and thrive by scavenging resources, building units, developing your culture, and competing with rival AI factions for dominance.

**Version**: 0.1.0 MVP (Released 2025-11-13)
**Engine**: Godot 4.5.1
**Status**: ✅ **MVP Complete - Fully Playable**
**Target Platforms**: Windows, macOS, Linux

## Quick Start for Players

### Installation

1. **Download** the latest release for your platform
2. **Extract** the archive to your preferred location
3. **Run** the executable:
   - Windows: `Guvnaville.exe`
   - macOS: `Guvnaville.app`
   - Linux: `Guvnaville.x86_64`

### First Time Playing?

- **Follow the Tutorial**: Launches automatically on first play
- **Read Quick Start**: See `docs/QUICK_START.md` for a 5-minute guide
- **Press F1**: Access in-game help anytime
- **Check the Manual**: See `docs/USER_MANUAL.md` for complete guide

### Essential Controls

- **Space/Enter**: End turn
- **F1**: Help
- **F5**: Quick save
- **F9**: Quick load
- **WASD/Arrows**: Pan camera
- **Mouse Wheel**: Zoom
- **ESC**: Menu

## Player Documentation

- 📖 **[User Manual](docs/USER_MANUAL.md)** - Complete game guide
- 🚀 **[Quick Start Guide](docs/QUICK_START.md)** - Get started in 5 minutes
- 📋 **[Changelog](CHANGELOG.md)** - Version history and features
- 📰 **[Release Notes](RELEASE_NOTES_v0.1.0.md)** - Current release information

## Features

### Gameplay Features (MVP Complete)
- ✅ **Turn-based Strategy**: Plan your moves in a dynamic post-apocalyptic world
- ✅ **Procedural Maps**: Explore varied urban ruins with unique locations
- ✅ **5 Unit Types**: Scavengers, Soldiers, Builders, Traders, Scouts
- ✅ **7 Building Types**: Base, Housing, Workshop, Farm, Clinic, Watchtower, Fortification
- ✅ **10 Resource Types**: Food, Water, Materials, Scrap, Fuel, Medicine, Electronics, Components, Ammunition, Weapons
- ✅ **4 Victory Conditions**: Domination, Economic, Cultural, Survival
- ✅ **AI Opponents**: 5 distinct AI personalities (Aggressive, Defensive, Economic, Balanced, Diplomatic)
- ✅ **Culture System**: 4-branch culture tree with 30+ upgrades
- ✅ **Dynamic Events**: 50+ unique events with choices and consequences
- ✅ **Tactical Combat**: Terrain bonuses, unit stats, and strategic positioning
- ✅ **Resource Management**: Scavenge, produce, trade, and manage scarce resources
- ✅ **Population System**: Grow and maintain your faction's population
- ✅ **Save/Load**: Complete game state persistence with quick save/load
- ✅ **Fog of War**: Dynamic vision based on unit positions

### Polish & User Experience (MVP Complete)
- ✅ **Interactive Tutorial**: 10-step guided tutorial for new players
- ✅ **Comprehensive Help System**: In-game help accessible with F1
- ✅ **Tooltips**: Information on all UI elements
- ✅ **Keyboard Shortcuts**: Efficient controls for all actions
- ✅ **Visual Feedback**: Animations and effects for actions
- ✅ **User Manual**: 50+ page comprehensive guide
- ✅ **Quick Start Guide**: 5-minute getting started document

### Technical Features
- ✅ **Automated Testing**: Comprehensive test coverage with GUT framework
- ✅ **CI/CD Pipeline**: Automated validation via GitHub Actions
- ✅ **Cross-platform**: Windows, macOS, and Linux support
- ✅ **Modular Architecture**: Clean, maintainable codebase
- ✅ **Performance Optimized**: 60 FPS gameplay on minimum specs
- ✅ **Data-Driven**: JSON-based content for easy modding

## Project Structure

```
ashes-to-empire/
├── core/                   # Core game systems
│   ├── autoload/          # Singleton autoloads (EventBus, GameManager, etc.)
│   ├── state/             # Game state management
│   └── types/             # Core data types (Unit, Tile, Building, etc.)
├── systems/               # Game system modules
│   ├── map/              # Map and spatial systems
│   ├── units/            # Unit management and abilities
│   ├── combat/           # Combat resolution
│   ├── economy/          # Resources and production
│   ├── culture/          # Culture progression system
│   ├── ai/               # AI decision-making
│   └── events/           # Event system
├── ui/                    # User interface
│   ├── screens/          # Main menu, game screen, settings
│   ├── hud/              # HUD elements (resource bar, minimap, etc.)
│   ├── dialogs/          # Dialog windows (events, combat results)
│   └── map/              # Map rendering and camera
├── rendering/             # Rendering systems
│   └── effects/          # Visual effects
├── data/                  # Game data (JSON)
│   ├── units/            # Unit definitions
│   ├── buildings/        # Building definitions
│   ├── culture/          # Culture tree data
│   ├── events/           # Event definitions
│   └── world/            # World generation data
├── tests/                 # Test suites
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   └── system/           # System tests
├── modules/               # C# performance modules (optional)
├── addons/                # Third-party addons
│   └── gut/              # GUT testing framework
└── docs/                  # Documentation
    ├── adr/              # Architecture Decision Records
    └── systems/          # System documentation
```

## Getting Started

### Prerequisites

- **Godot 4.5.1**: Download from [godotengine.org](https://godotengine.org/download/)
- **Git**: For version control
- **Git LFS** (optional): For large binary assets

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/guvnaville.git
   cd guvnaville
   ```

2. Open the project in Godot:
   ```bash
   godot --editor .
   ```
   Or use the Godot project manager to open `project.godot`.

3. Install dependencies (if any):
   The GUT testing framework is already included in `addons/gut/`.

### Running the Game

- **From Godot Editor**: Press F5 or click the "Play" button
- **From Command Line**:
  ```bash
  godot --path . res://ui/screens/main_menu.tscn
  ```

## Development

### Running Tests

Run all tests:
```bash
./run_tests.sh
```

Run specific test directory:
```bash
./run_tests.sh res://tests/unit/
```

Run tests in Godot editor:
1. Open the GUT panel (bottom panel)
2. Click "Run All"

### Building for Distribution

#### Linux
```bash
godot --headless --export-release "Linux/X11" build/linux/ashes-to-empire.x86_64
```

#### Windows
```bash
godot --headless --export-release "Windows Desktop" build/windows/ashes-to-empire.exe
```

#### macOS
```bash
godot --headless --export-release "macOS" build/macos/ashes-to-empire.zip
```

### CI/CD

This project uses GitHub Actions for continuous integration:

**Phase 1 (Current - Foundation)**:
- **Project Validation**: Directory structure and JSON data validation
- **Linting**: GDScript syntax checking (core scripts only)
- **Status Reports**: Summary of validation results

**Phase 2+ (Implementation)**:
- **GUT Tests**: Automated unit and integration tests
- **Builds**: Automated builds for Windows, macOS, and Linux
- **Artifact Upload**: Build artifacts and test results

> **Note**: GUT tests and build jobs are disabled for Phase 1 since we're setting up the foundation. They will be enabled in Phase 2 when game content is implemented.

View the workflow: `.github/workflows/ci.yml`

## Contributing

### Development Workflow

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and write tests

3. Run tests locally:
   ```bash
   ./run_tests.sh
   ```

4. Commit your changes:
   ```bash
   git add .
   git commit -m "Add your feature"
   ```

5. Push and create a pull request

### Code Style

- Follow [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Write comprehensive tests for new features
- Document public APIs and complex logic
- Keep functions small and focused

### Testing Guidelines

- **Unit Tests**: Test individual functions and classes in isolation
- **Integration Tests**: Test interactions between modules
- **System Tests**: Test complete game features end-to-end
- **Target Coverage**: 90%+ for critical systems

## Architecture

This project follows a **modular, interface-driven architecture** designed for parallel development by multiple AI agents.

### Key Principles

1. **Layered Dependencies**: Clear dependency hierarchy prevents circular dependencies
2. **Interface Contracts**: Well-defined APIs between modules
3. **Event-Driven Communication**: EventBus for decoupled module communication
4. **Test-First Development**: Tests define expected behavior before implementation
5. **Data-Driven Design**: Game content stored in JSON for easy modification

### Module Layers

```
Layer 0: Core Foundation (no dependencies)
Layer 1: Map, Event, Culture Systems (depend on Core)
Layer 2: Unit, Combat, Economy Systems (depend on Layer 1)
Layer 3: AI System (depends on all game systems)
Layer 4: UI and Rendering (presentation layer)
```

See `docs/IMPLEMENTATION_PLAN.md` for detailed architecture documentation.

## Development Status

### Phase 1: Foundation ✅ COMPLETE
- [x] Project setup and directory structure
- [x] GUT testing framework
- [x] CI/CD pipeline
- [x] Interface contracts
- [x] Core architecture

### Phase 2: Core Systems ✅ COMPLETE
- [x] Core Foundation module (GameManager, EventBus, State)
- [x] Map System (procedural generation, fog of war)
- [x] Unit System (5 unit types, movement, abilities)
- [x] Combat System (tactical combat, terrain bonuses)
- [x] Economy System (10 resources, production, trade)
- [x] Culture System (4 branches, 30+ upgrades)
- [x] AI System (5 personalities, tactical & strategic AI)
- [x] Event System (50+ events, choices, chains)
- [x] UI System (menus, HUD, dialogs)
- [x] Rendering System (sprites, effects, optimization)

### Phase 3: Integration ✅ COMPLETE
- [x] All systems integrated
- [x] Integration testing passed
- [x] First playable build delivered
- [x] System interactions validated

### Phase 4: Polish & MVP ✅ COMPLETE
- [x] Tutorial system (10 guided steps)
- [x] Help system (F1 in-game help)
- [x] Tooltip system (all UI elements)
- [x] Keyboard shortcuts (F5/F9 quick save/load, etc.)
- [x] Visual polish (animations, transitions, feedback)
- [x] User documentation (Manual + Quick Start)
- [x] Technical documentation
- [x] Performance optimization (60 FPS)
- [x] Content completion (events, culture tree)
- [x] Bug fixing and testing
- [x] **MVP RELEASE v0.1.0** 🎉

## Future Roadmap

### Version 0.2.0 (Planned)
- [ ] Multiplayer support (hot-seat mode)
- [ ] Faction customization at game start
- [ ] Additional map types (desert, forest, mountain)
- [ ] More events (targeting 100+ total)
- [ ] Enhanced AI diplomacy
- [ ] Unit experience and leveling
- [ ] Additional building types
- [ ] Audio and music

### Version 0.3.0 (Planned)
- [ ] Online multiplayer
- [ ] Campaign mode with story
- [ ] Advanced mod support
- [ ] Map editor
- [ ] Replay system
- [ ] Steam integration

### Version 1.0.0 (Future)
- [ ] Complete content (200+ events)
- [ ] Polished art assets
- [ ] Full audio design
- [ ] Multiple campaigns
- [ ] Achievements and leaderboards

## Documentation

- **Implementation Plan**: `docs/IMPLEMENTATION_PLAN.md` - Detailed development plan
- **Architecture Decisions**: `docs/adr/` - Architecture Decision Records
- **System Documentation**: `docs/systems/` - Individual system documentation

## License

[Add your license here]

## Contact

[Add contact information or links to Discord/forum]

## Acknowledgments

- Built with [Godot Engine](https://godotengine.org/)
- Testing framework: [GUT (Godot Unit Test)](https://github.com/bitwes/Gut)
- CI/CD: [GitHub Actions](https://github.com/features/actions)

---

**Status**: ✅ **MVP Complete - Ready to Play!**
**Version**: 0.1.0
**Release Date**: 2025-11-13
**Last Updated**: 2025-11-13
