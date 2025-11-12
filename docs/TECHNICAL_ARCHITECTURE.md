# Technical Architecture - Ashes to Empire

## Executive Summary

**Ashes to Empire** is a complex turn-based 4X strategy game requiring a robust, modular, and cross-platform architecture. This document outlines the technical design to support:

- Cross-platform development (OSX dev → Windows deployment)
- Parallel AI agent development workflows
- Automated testing without Windows test environment
- Scalable performance for 40,000 tile grid
- Deep system interactions

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   UI System  │  │  Rendering   │  │   Audio      │      │
│  │   (Menus,    │  │   (Map,      │  │   (Music,    │      │
│  │   HUD, etc)  │  │   Units)     │  │   SFX)       │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Game Logic Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Game State  │  │   Systems    │  │   AI Engine  │      │
│  │  Manager     │  │   (Combat,   │  │   (Decision  │      │
│  │              │  │   Economy,   │  │   Making)    │      │
│  │              │  │   Culture)   │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Game Data  │  │  Save/Load   │  │   Events     │      │
│  │   (JSON)     │  │   System     │  │   System     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Platform Abstraction                      │
│            (File I/O, Input, Windowing)                      │
└─────────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Separation of Concerns**: Game logic independent of presentation
2. **Data-Driven Design**: All game content in JSON/YAML files
3. **Deterministic Simulation**: Reproducible game states for testing
4. **Modular Architecture**: Systems can be developed in parallel
5. **Test-First Development**: Comprehensive automated testing
6. **Cross-Platform by Default**: No platform-specific code in core logic

## Core Systems Architecture

### 1. Game State Management

**Purpose**: Single source of truth for entire game state

**Components**:
```
GameState
├── WorldState
│   ├── Map (200x200x3 grid)
│   ├── Tiles (40,000 tile objects)
│   ├── UniqueLocations (200+ POIs)
│   └── FogOfWar
├── FactionStates (9 factions: player + 8 AI)
│   ├── Resources (stockpiles)
│   ├── Culture (progression trees)
│   ├── Technologies
│   ├── Units
│   ├── Buildings
│   └── Diplomacy
├── TurnState
│   ├── TurnNumber
│   ├── Phase (Movement/Combat/Economy/End)
│   └── ActiveFaction
└── EventQueue
    └── PendingEvents
```

**Key Features**:
- Immutable state snapshots for save/load
- Delta-based state updates for performance
- Serializable to JSON for saves and network play
- Deep copy for AI decision simulation
- State validation for testing

### 2. Map System

**Grid Structure**:
```typescript
interface Tile {
  id: string;                    // Unique identifier
  position: {x: number, y: number, z: number}; // z: 0=underground, 1=ground, 2=elevated
  tileType: TileType;            // Residential, Commercial, Industrial, etc.
  terrain: TerrainType;          // Rubble, Building, Street, Park, etc.
  owner: FactionId | null;       // Controlling faction
  visibility: Map<FactionId, VisibilityLevel>; // Fog of war per faction
  units: UnitId[];               // Units on this tile
  building: Building | null;     // Structure on this tile
  scavengeValue: number;         // 0-100, depletes over time
  hazards: Hazard[];             // Radiation, fire, collapse risk
  resources: ResourceNode | null; // If this tile generates resources
}

enum TileType {
  Residential,
  Commercial,
  Industrial,
  Military,
  Medical,
  Cultural,
  Infrastructure,
  Ruins,
  Street,
  Park
}

enum TerrainType {
  OpenGround,
  Building,
  Rubble,
  Street,
  Water,
  Tunnel,
  Rooftop
}
```

**Performance Optimization**:
- Spatial partitioning (quadtree) for efficient queries
- Chunk-based loading (20x20 chunks)
- Dirty flag system for rendering updates
- Pathfinding grid cache

### 3. Unit System

```typescript
interface Unit {
  id: string;
  type: UnitType;
  faction: FactionId;
  position: Position;
  stats: UnitStats;
  currentHP: number;
  morale: number;
  experience: number;
  rank: UnitRank; // Rookie, Veteran, Elite, Legendary
  specialAbilities: Ability[];
  equipment: Equipment[];
  status: StatusEffect[];
  movementRemaining: number;
  actionsRemaining: number;
}

interface UnitStats {
  maxHP: number;
  attack: number;
  defense: number;
  range: number;
  movement: number;
  armor: number;
  stealth: number;
  detection: number;
}

enum UnitType {
  Militia,
  Scavenger,
  Raider,
  Soldier,
  HeavyInfantry,
  Sniper,
  Engineer,
  Medic,
  Scout,
  Motorcycle,
  ArmoredCar,
  Tank,
  // Culture-specific units
  CyberneticSoldier,
  Berserker,
  GuerrillaFighter,
  ArchaeoTechGuardian,
  PeoplesMilitia
}
```

**Unit Management**:
- Component-based design for modular abilities
- Behavior tree AI for unit tactics
- Formation system for group movement
- Experience and promotion system
- Equipment and loadout customization

### 4. Combat System

**Combat Flow**:
```
Combat Initiation
    ↓
Auto-Resolve or Tactical?
    ↓
[Auto-Resolve Path]         [Tactical Path]
    ↓                           ↓
Calculate Strengths      Setup Tactical Map
    ↓                           ↓
Apply Modifiers         Initiative Order
    ↓                           ↓
Resolve Outcome         Turn-Based Combat
    ↓                           ↓
Apply Casualties        Victory/Defeat
    ↓                           ↓
[Both paths converge]
    ↓
Update Game State
    ↓
Loot & Experience
    ↓
Morale Effects
```

**Combat Calculator**:
```python
class CombatCalculator:
    def calculate_auto_resolve(self, attackers, defenders, terrain):
        attacker_strength = self._calculate_strength(attackers, terrain, is_attacker=True)
        defender_strength = self._calculate_strength(defenders, terrain, is_attacker=False)

        strength_ratio = attacker_strength / defender_strength

        outcome = self._determine_outcome(strength_ratio)
        casualties = self._calculate_casualties(outcome, attackers, defenders)
        loot = self._calculate_loot(casualties)

        return CombatResult(outcome, casualties, loot)

    def _calculate_strength(self, units, terrain, is_attacker):
        total = 0
        for unit in units:
            strength = unit.attack if is_attacker else unit.defense
            strength *= (unit.current_hp / unit.max_hp)
            strength *= terrain.get_modifier(unit, is_attacker)
            strength *= (unit.morale / 100)
            total += strength
        return total
```

**Tactical Combat Engine**:
- Grid-based tactical map (20x20 subset of strategic map)
- Line-of-sight calculation
- Cover system
- Elevation bonuses
- Action point system
- Ability usage
- Flanking detection

### 5. Resource & Economy System

```typescript
interface FactionResources {
  stockpiled: {
    scrap: number;
    food: number;
    medicine: number;
    ammunition: number;
    fuel: number;
    components: number;
    water: number;
  };
  perTurnIncome: {
    scrap: number;
    food: number;
    // ... etc
  };
  perTurnConsumption: {
    food: number;
    water: number;
    fuel: number;
  };
  strategic: {
    knowledge: number;      // Research points/turn
    production: number;     // Production points/turn
    medical: number;        // Medical capacity
    agricultural: number;   // Food production/turn
    energy: number;         // Power generation
    culture: number;        // Culture points/turn
  };
}

interface ResourceNode {
  type: ResourceType;
  tier: 1 | 2 | 3 | 4; // Wonder sites = 4
  yields: ResourceYield[];
  requirements: Requirement[]; // e.g., needs power
  unique: boolean;
  capturable: boolean;
}
```

**Economy Engine**:
```python
class EconomyEngine:
    def process_turn(self, game_state):
        for faction in game_state.factions:
            # Income phase
            self._collect_resources(faction)
            self._process_trade_routes(faction)
            self._process_scavenging(faction)

            # Consumption phase
            self._consume_population_resources(faction)
            self._consume_unit_resources(faction)
            self._process_production(faction)

            # Check shortages
            self._check_resource_shortages(faction)

            # Update happiness
            self._update_population_happiness(faction)
```

### 6. Culture System

```typescript
interface CultureState {
  faction: FactionId;
  culturePoints: number;

  // Four cultural axes
  governance: {
    path: GovernancePath;
    tier: number; // 0-3
    unlockedNodes: CultureNode[];
  };
  belief: {
    path: BeliefPath;
    tier: number;
    unlockedNodes: CultureNode[];
  };
  technology: {
    path: TechnologyPath;
    tier: number;
    unlockedNodes: CultureNode[];
  };
  social: {
    path: SocialPath;
    tier: number;
    unlockedNodes: CultureNode[];
  };

  activeModifiers: CultureModifier[];
  unlockedUnits: UnitType[];
  unlockedBuildings: BuildingType[];
  unlockedPolicies: Policy[];
}

interface CultureNode {
  id: string;
  name: string;
  description: string;
  cost: number;
  prerequisites: string[];
  effects: Effect[];
  unlocks: Unlock[];
}
```

**Culture Tree Data Structure**:
- Tree representation with parent/child relationships
- Prerequisite validation
- Mutually exclusive paths
- Synergy bonuses between axes
- Dynamic UI generation from data

### 7. AI System

**Multi-Layered AI Architecture**:

```
Strategic AI (Per Faction)
    ↓
Goal Selection
├── Victory Path (Cultural/Military/Tech/Diplomatic)
├── Current Priorities
└── Threat Assessment
    ↓
Strategic Planning
├── Expansion Planning
├── Military Strategy
├── Economic Planning
├── Diplomatic Strategy
└── Research Direction
    ↓
Tactical AI (Per Unit)
    ↓
Action Selection
├── Movement
├── Combat
├── Ability Usage
└── Positioning
```

**AI Decision System**:
```python
class FactionAI:
    def __init__(self, faction, personality, victory_preference):
        self.faction = faction
        self.personality = personality  # Aggressive, Defensive, Economic, etc.
        self.victory_preference = victory_preference
        self.goal_stack = []
        self.threat_map = {}

    def plan_turn(self, game_state):
        # Strategic planning
        self._assess_threats(game_state)
        self._evaluate_opportunities(game_state)
        self._update_goals()

        # Generate action plan
        actions = []

        # Economic actions
        actions.extend(self._plan_resource_management(game_state))
        actions.extend(self._plan_production(game_state))
        actions.extend(self._plan_trade(game_state))

        # Military actions
        actions.extend(self._plan_unit_movement(game_state))
        actions.extend(self._plan_attacks(game_state))
        actions.extend(self._plan_defenses(game_state))

        # Diplomatic actions
        actions.extend(self._plan_diplomacy(game_state))

        # Research and culture
        actions.extend(self._plan_research(game_state))
        actions.extend(self._plan_culture(game_state))

        return self._prioritize_actions(actions)
```

**Utility-Based AI**:
- Score all possible actions
- Weight by personality and goals
- Consider risk vs reward
- Look-ahead simulation for critical decisions
- Fuzzy logic for uncertainty

### 8. Event System

```typescript
interface GameEvent {
  id: string;
  type: EventType;
  trigger: EventTrigger;
  conditions: Condition[];
  choices: EventChoice[];
  consequences: Consequence[];
  narrative: {
    title: string;
    description: string;
    image?: string;
  };
}

enum EventType {
  Random,
  Cultural,
  Diplomatic,
  Discovery,
  Crisis,
  Quest
}

interface EventChoice {
  text: string;
  requirements: Requirement[];
  outcomes: Outcome[];
  probabilistic: boolean;
}
```

**Event Engine**:
- Event queue with priority
- Trigger evaluation each turn
- Conditional event chains
- Random event pool with weights
- Historical tracking (no repeat events unless flagged)

### 9. Pathfinding System

**A* Pathfinding with Optimizations**:
```python
class PathfindingEngine:
    def __init__(self, map_data):
        self.map = map_data
        self.grid_cache = self._build_grid_cache()
        self.path_cache = LRUCache(capacity=1000)

    def find_path(self, start, goal, unit, ignore_units=False):
        cache_key = (start, goal, unit.movement, ignore_units)
        if cache_key in self.path_cache:
            return self.path_cache[cache_key]

        # A* algorithm with movement cost
        path = self._astar(start, goal, unit, ignore_units)
        self.path_cache[cache_key] = path
        return path

    def _astar(self, start, goal, unit, ignore_units):
        # Standard A* with terrain costs, ZoC, and verticality
        pass
```

**Optimizations**:
- Jump Point Search for open terrain
- Hierarchical pathfinding for long distances
- Flow field for group movement
- Path smoothing
- Cached paths with invalidation

### 10. Save/Load System

**Save File Structure**:
```json
{
  "version": "1.0.0",
  "gameState": {
    "turnNumber": 125,
    "worldState": { /* compressed */ },
    "factions": [ /* array of faction states */ ],
    "events": [ /* event history */ ]
  },
  "metadata": {
    "saveName": "The New Order - Turn 125",
    "timestamp": "2025-11-12T10:30:00Z",
    "playTime": 18450,
    "difficulty": "Normal"
  },
  "checksums": {
    "worldState": "abc123...",
    "factions": "def456..."
  }
}
```

**Serialization Strategy**:
- JSON for human-readable saves
- Compressed binary format for autosaves
- Incremental saves (delta from last save)
- Checksum validation
- Version migration system

## Data Architecture

### Game Data Organization

```
data/
├── config/
│   ├── game_constants.json
│   ├── balance_config.json
│   └── difficulty_settings.json
├── content/
│   ├── tiles/
│   │   └── tile_types.json
│   ├── units/
│   │   ├── unit_types.json
│   │   └── abilities.json
│   ├── buildings/
│   │   └── building_types.json
│   ├── resources/
│   │   └── resource_definitions.json
│   ├── culture/
│   │   ├── governance.json
│   │   ├── belief.json
│   │   ├── technology.json
│   │   └── social.json
│   ├── technologies/
│   │   └── tech_tree.json
│   └── factions/
│       └── faction_definitions.json
├── world/
│   ├── map_layout.json
│   └── unique_locations.json
├── events/
│   ├── random_events.json
│   ├── cultural_events.json
│   ├── diplomatic_events.json
│   └── crisis_events.json
└── localization/
    ├── en_US.json
    ├── es_ES.json
    └── fr_FR.json
```

### Data Validation

**Schema Validation**:
- JSON Schema for all data files
- Pre-build validation
- Runtime validation in development
- Editor tooling with validation

**Data Loading**:
```python
class DataLoader:
    def __init__(self):
        self.schemas = self._load_schemas()
        self.cache = {}

    def load_game_data(self):
        # Validate and load all JSON files
        units = self._load_and_validate('units', 'unit_types.json')
        buildings = self._load_and_validate('buildings', 'building_types.json')
        # etc...

        return GameData(units=units, buildings=buildings, ...)

    def _load_and_validate(self, schema_name, file_path):
        data = json.load(open(file_path))
        jsonschema.validate(data, self.schemas[schema_name])
        return data
```

## Module Breakdown for Parallel Development

### Module 1: Core Engine (Foundation)
**Responsibility**: Game loop, state management, serialization
**Dependencies**: None
**Interfaces**:
- `GameState`: Read/write game state
- `TurnManager`: Process turn phases
- `SaveManager`: Save/load games

### Module 2: Map & World
**Responsibility**: Map generation, tile management, world state
**Dependencies**: Core Engine
**Interfaces**:
- `MapData`: Access tile data
- `FogOfWar`: Visibility system
- `WorldGenerator`: Create/load map

### Module 3: Unit System
**Responsibility**: Unit management, stats, abilities
**Dependencies**: Core Engine, Map
**Interfaces**:
- `UnitRegistry`: Unit type definitions
- `UnitManager`: Create/destroy units
- `AbilitySystem`: Special abilities

### Module 4: Combat System
**Responsibility**: Auto-resolve and tactical combat
**Dependencies**: Core Engine, Map, Unit System
**Interfaces**:
- `CombatResolver`: Auto-resolve battles
- `TacticalCombat`: Tactical battle engine
- `CombatCalculator`: Damage calculations

### Module 5: Economy System
**Responsibility**: Resources, production, trade
**Dependencies**: Core Engine, Map
**Interfaces**:
- `ResourceManager`: Track resources
- `ProductionSystem`: Build queue
- `TradeSystem`: Trade routes

### Module 6: Culture System
**Responsibility**: Culture trees, progression, bonuses
**Dependencies**: Core Engine
**Interfaces**:
- `CultureTree`: Culture progression
- `CultureEffects`: Apply culture bonuses

### Module 7: AI System
**Responsibility**: AI decision-making, personalities
**Dependencies**: All game systems
**Interfaces**:
- `FactionAI`: High-level AI
- `TacticalAI`: Combat AI
- `DiplomacyAI`: Diplomatic decisions

### Module 8: Event System
**Responsibility**: Events, narrative, choices
**Dependencies**: Core Engine
**Interfaces**:
- `EventManager`: Event queue and triggers
- `NarrativeEngine`: Story progression

### Module 9: UI System
**Responsibility**: Menus, HUD, interfaces
**Dependencies**: All systems (read-only)
**Interfaces**:
- `UIManager`: Screen management
- `InputHandler`: User input

### Module 10: Rendering
**Responsibility**: Graphics rendering
**Dependencies**: Core Engine, Map, Unit System
**Interfaces**:
- `Renderer`: Draw calls
- `CameraSystem`: View control

## Testing Strategy

### Automated Testing Levels

**1. Unit Tests (Per Module)**
```python
# Example: Combat calculation test
def test_combat_strength_calculation():
    attacker = create_test_unit(UnitType.Soldier, hp=80)
    defender = create_test_unit(UnitType.Militia, hp=50)
    terrain = Terrain(cover=CoverType.Heavy)

    calculator = CombatCalculator()
    result = calculator.calculate_auto_resolve([attacker], [defender], terrain)

    assert result.outcome == CombatOutcome.AttackerVictory
    assert result.attacker_casualties < result.defender_casualties
```

**2. Integration Tests (Cross-Module)**
```python
# Example: Full turn simulation
def test_full_turn_processing():
    game = create_test_game(num_factions=2)
    initial_state = game.state.snapshot()

    game.process_turn()

    assert game.state.turn_number == initial_state.turn_number + 1
    assert_resources_consumed(game.state, initial_state)
    assert_units_moved(game.state, initial_state)
```

**3. System Tests (Full Game Simulation)**
```python
# Example: Play through entire game
def test_ai_vs_ai_full_game():
    game = Game.new_game(all_ai=True, fast_mode=True)

    max_turns = 500
    for turn in range(max_turns):
        game.process_turn()
        if game.check_victory():
            break

    assert game.has_winner()
    assert game.state.turn_number < max_turns
```

**4. Deterministic Replay Tests**
```python
# Ensure same inputs = same outputs
def test_deterministic_replay():
    seed = 12345

    game1 = Game.new_game(seed=seed)
    game1.simulate_turns(100)
    state1 = game1.state.snapshot()

    game2 = Game.new_game(seed=seed)
    game2.simulate_turns(100)
    state2 = game2.state.snapshot()

    assert state1 == state2  # Exact match
```

### Continuous Integration

**GitHub Actions Workflow**:
```yaml
name: Cross-Platform Build & Test

on: [push, pull_request]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup environment
        run: make setup
      - name: Run tests
        run: make test
      - name: Build macOS
        run: make build-macos

  test-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup environment
        run: make setup
      - name: Run tests
        run: make test
      - name: Build Linux
        run: make build-linux

  cross-compile-windows:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup cross-compilation
        run: make setup-windows-cross
      - name: Cross-compile Windows
        run: make build-windows
      - name: Smoke test Windows build
        run: make smoke-test-windows
```

### Testing Without Windows Environment

**Strategy**:
1. **Core logic testing**: 100% unit test coverage on all game logic (platform-agnostic)
2. **Cross-compilation**: Build Windows binaries on Linux/macOS using MinGW or similar
3. **Smoke tests**: Basic launch and functionality tests in Wine or VM
4. **Community testing**: Beta testing with Windows users
5. **Automated UI tests**: Headless rendering tests

## Performance Considerations

### Target Performance

- **Turn Processing**: < 1 second for player turn, < 5 seconds for AI turn
- **Rendering**: 60 FPS at 1920x1080
- **Memory**: < 2GB RAM
- **Save/Load**: < 3 seconds
- **Map Size**: 40,000 tiles fully loaded

### Optimization Strategies

**1. Lazy Loading**
- Load map in chunks
- Stream audio/textures on demand
- Lazy initialize AI subsystems

**2. Caching**
- Pathfinding cache
- Line-of-sight cache
- Combat calculation cache

**3. Spatial Partitioning**
- Quadtree for map queries
- Only update visible tiles
- Chunk-based updates

**4. Multithreading**
- AI decision-making on separate threads
- Pathfinding workers
- Asset loading background threads

**5. Data Structures**
- Efficient grid representation (flat arrays, not nested)
- Object pooling for units/projectiles
- Bit flags for tile properties

## Cross-Platform Strategy

### Platform Abstraction Layer

```python
# platform/abstract.py
class PlatformAbstraction:
    def get_save_directory(self) -> Path:
        raise NotImplementedError

    def get_config_directory(self) -> Path:
        raise NotImplementedError

    def open_file_dialog(self, filter: str) -> Optional[Path]:
        raise NotImplementedError

# platform/macos.py
class MacOSPlatform(PlatformAbstraction):
    def get_save_directory(self) -> Path:
        return Path.home() / "Library" / "Application Support" / "AshesToEmpire" / "Saves"

# platform/windows.py
class WindowsPlatform(PlatformAbstraction):
    def get_save_directory(self) -> Path:
        return Path(os.getenv('APPDATA')) / "AshesToEmpire" / "Saves"

# platform/linux.py
class LinuxPlatform(PlatformAbstraction):
    def get_save_directory(self) -> Path:
        return Path.home() / ".local" / "share" / "AshesToEmpire" / "saves"
```

### File Path Handling
- Use `pathlib.Path` (Python) or equivalent
- No hardcoded paths with `/` or `\`
- Respect platform conventions

### Input Handling
- Abstract keyboard/mouse input
- Support keyboard-only navigation
- Gamepad support (optional)

### Graphics
- Resolution scaling
- Fullscreen/windowed mode
- Multiple monitor support

## Deployment Architecture

```
Development → CI/CD → Builds
                ↓
    ┌───────────┼───────────┐
    │           │           │
  macOS      Windows     Linux
  .app       .exe        .AppImage
    │           │           │
    └───────────┴───────────┘
              ↓
        Distribution
    (itch.io / Steam / direct)
```

## Security Considerations

1. **Save File Validation**: Checksum verification
2. **Input Sanitization**: Validate all user input
3. **Mod Security**: Sandboxed mod execution (future)
4. **No Network Code Initially**: Local play only for v1.0
5. **Crash Reporting**: Anonymous telemetry (opt-in)

## Localization Support

**Structure**:
```json
{
  "ui": {
    "main_menu": {
      "new_game": "New Game",
      "load_game": "Load Game",
      "settings": "Settings",
      "quit": "Quit"
    }
  },
  "units": {
    "militia": {
      "name": "Militia",
      "description": "Basic defensive unit"
    }
  }
}
```

**Implementation**:
- All strings externalized
- Localization file per language
- Fallback to English
- Font support for extended character sets

## Modding Support (Future)

**Design for Modding**:
- All game data in JSON (moddable)
- Mod loading system
- Mod conflict resolution
- Steam Workshop integration (if on Steam)

---

## Summary

This architecture provides:
- ✅ Cross-platform compatibility
- ✅ Modular design for parallel development
- ✅ Comprehensive testing without Windows
- ✅ Scalable performance
- ✅ AI-friendly development (clear interfaces, testable)
- ✅ Maintainable codebase

**Next Steps**: Review ADRs for specific technology choices.
