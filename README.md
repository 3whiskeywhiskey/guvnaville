# Ashes to Empire

A grand strategy game set in a post-apocalyptic world where players rebuild civilization from the ruins.

## Overview

Ashes to Empire is a turn-based grand strategy game that challenges players to rebuild civilization in a post-apocalyptic world. Scavenge resources, manage settlements, engage in tactical combat, and navigate the complexities of rebuilding society through a unique culture system.

**Version**: 0.1.0 (MVP in development)
**Engine**: Godot 4.2.2
**Target Platforms**: Windows, macOS, Linux

## Features

### Core Gameplay
- **Turn-based Strategy**: Plan your moves carefully in a persistent world
- **200x200 Tile Map**: Explore a vast post-apocalyptic landscape with 200+ unique locations
- **8 AI Factions**: Compete or cooperate with AI opponents featuring distinct personalities
- **Resource Management**: Scavenge, produce, and trade scarce resources
- **Unit System**: Build and command diverse units with unique abilities
- **Combat**: Auto-resolve battles with tactical depth
- **Culture System**: Shape your faction's identity through a multi-axis progression tree
- **Event System**: Navigate random events that challenge your leadership
- **Save/Load**: Preserve your progress with a robust save system

### Technical Features
- **Automated Testing**: 90%+ test coverage with GUT framework
- **CI/CD Pipeline**: Automated builds and testing via GitHub Actions
- **Cross-platform**: Export to Windows, macOS, and Linux
- **Modular Architecture**: Clean separation of concerns for maintainability

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

- **Godot 4.2.2**: Download from [godotengine.org](https://godotengine.org/download/)
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

## Roadmap

### Phase 1: Foundation (Week 1) ✅
- [x] Project setup
- [x] Directory structure
- [x] GUT testing framework
- [x] CI/CD pipeline
- [ ] Interface contracts

### Phase 2: Parallel Development (Weeks 2-4)
- [ ] Core Foundation module
- [ ] Map System
- [ ] Unit System
- [ ] Combat System
- [ ] Economy System
- [ ] Culture System
- [ ] AI System
- [ ] Event System
- [ ] UI System
- [ ] Rendering System

### Phase 3: Integration (Week 5)
- [ ] Module integration
- [ ] Integration testing
- [ ] First playable build

### Phase 4: Polish & MVP (Weeks 6-8)
- [ ] E2E testing
- [ ] Performance optimization
- [ ] Content completion (200+ locations, 50+ events)
- [ ] Bug fixing
- [ ] Tutorial
- [ ] MVP release

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

**Status**: 🚧 In Active Development (MVP Phase 1)
**Last Updated**: 2025-11-12
