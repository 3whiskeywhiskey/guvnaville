# ADR-011: AI Agent Parallel Development Architecture

## Status
**Accepted**

## Context

This project will be developed primarily by multiple AI agents working in parallel with minimal human oversight. This creates unique requirements:

1. **Clear module boundaries**: Agents must work independently without conflicts
2. **Comprehensive documentation**: Agents need context without human explanation
3. **Extensive automated testing**: Validation without manual QA
4. **Interface-driven development**: Clear contracts between modules
5. **Minimal coordination overhead**: Agents shouldn't block each other
6. **Self-validating**: Agents must verify their own work

### Challenges

- How do we prevent merge conflicts?
- How do agents understand the codebase?
- How do agents validate their changes?
- How do we ensure consistency across modules?
- How do we handle integration?

### Options Considered

#### Option A: Monolithic Development
Single agent builds entire system sequentially

**Pros**: No coordination needed, simple
**Cons**: Extremely slow, doesn't leverage parallel development

#### Option B: Feature-Branch Parallel Development
Multiple agents on separate feature branches

**Pros**: True isolation
**Cons**: Complex merges, integration nightmares

#### Option C: Module-Based Parallel Development (RECOMMENDED) ⭐
Structured parallel development with clear module ownership and interfaces

**Pros**: Maximum parallelism with minimal conflicts
**Cons**: Requires upfront architecture design

## Decision

**We will use Module-Based Parallel Development with the following structure:**

### Core Principles

1. **Module Ownership**: Each agent owns specific modules
2. **Interface Contracts**: Clear API boundaries between modules
3. **Test-Driven Development**: Tests define module behavior
4. **Documentation-First**: Agents document before implementing
5. **Integration Milestones**: Planned integration points
6. **Continuous Integration**: Automated validation

## Module Architecture for Parallel Development

### Module Dependency Graph

```
┌─────────────────────────────────────────────────────────┐
│                    Module Layer 1                        │
│                  (Core Foundation)                       │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ GameState    │  │ DataLoader   │  │ SaveManager  │  │
│  │ Management   │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Module Layer 2                        │
│                 (Game Systems - Parallel)                │
│                                                          │
│  ┌───────┐  ┌────────┐  ┌─────────┐  ┌───────────┐    │
│  │  Map  │  │ Combat │  │ Economy │  │  Culture  │    │
│  │System │  │ System │  │ System  │  │  System   │    │
│  └───────┘  └────────┘  └─────────┘  └───────────┘    │
│                                                          │
│  ┌───────┐  ┌────────┐  ┌─────────┐                    │
│  │ Unit  │  │ Event  │  │   AI    │                    │
│  │System │  │ System │  │ System  │                    │
│  └───────┘  └────────┘  └─────────┘                    │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Module Layer 3                        │
│                  (Presentation Layer)                    │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ UI       │  │ Rendering│  │  Audio   │             │
│  │ System   │  │          │  │          │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

### Module Assignments

**Agent 1: Core Foundation**
```
modules/core/
├── game_state.gd          # Game state management
├── turn_manager.gd        # Turn processing
└── event_bus.gd           # Event system

Deliverables:
- GameState class with serialization
- TurnManager with phase processing
- EventBus with all signal definitions
- 90%+ test coverage
```

**Agent 2: Map System**
```
modules/map/
├── map_data.gd            # Map structure
├── tile.gd                # Tile class
├── fog_of_war.gd          # Visibility system
└── map_generator.gd       # Map generation

Deliverables:
- 200x200x3 grid implementation
- Tile type definitions
- Fog of war calculations
- Spatial queries (get tiles in radius, etc.)
- 90%+ test coverage
```

**Agent 3: Unit System**
```
modules/units/
├── unit.gd                # Unit class
├── unit_manager.gd        # Unit lifecycle
├── unit_factory.gd        # Unit creation
└── abilities/             # Unit abilities
    ├── entrench.gd
    ├── overwatch.gd
    └── heal.gd

Deliverables:
- Unit data structures
- Movement system
- Ability framework
- Experience/promotion system
- 90%+ test coverage
```

**Agent 4: Combat System**
```
modules/combat/
├── combat_resolver.gd     # Auto-resolve
├── combat_calculator.gd   # Damage calculations
├── tactical_combat.gd     # Tactical battles
└── combat_modifiers.gd    # Terrain, elevation, etc.

Deliverables:
- Auto-resolve algorithm
- Tactical combat engine
- Combat formulas
- Morale system
- 90%+ test coverage
```

**Agent 5: Economy System**
```
modules/economy/
├── resource_manager.gd    # Resource tracking
├── production_system.gd   # Production queue
├── trade_system.gd        # Trade routes
└── scavenging_system.gd   # Scavenging mechanics

Deliverables:
- Resource management
- Production processing
- Trade route logic
- Scavenging system
- 90%+ test coverage
```

**Agent 6: Culture System**
```
modules/culture/
├── culture_tree.gd        # Culture progression
├── culture_effects.gd     # Apply culture bonuses
└── culture_nodes.gd       # Node definitions

Deliverables:
- Culture tree structure
- Progression logic
- Effect application
- Culture synergies
- 90%+ test coverage
```

**Agent 7: AI System**
```
modules/ai/
├── faction_ai.gd          # Strategic AI
├── tactical_ai.gd         # Combat AI
├── diplomacy_ai.gd        # Diplomatic decisions
└── utility_scorer.gd      # Decision scoring

Deliverables:
- AI decision-making framework
- Personality system
- Goal planning
- Action evaluation
- AI vs AI test games
```

**Agent 8: Event System**
```
modules/events/
├── event_manager.gd       # Event queue
├── event_trigger.gd       # Trigger evaluation
├── event_choice.gd        # Player choices
└── event_consequences.gd  # Apply outcomes

Deliverables:
- Event loading and processing
- Trigger system
- Choice resolution
- Event chains
- 90%+ test coverage
```

**Agent 9: UI System**
```
modules/ui/
├── ui_manager.gd          # Screen management
├── hud/                   # HUD components
├── dialogs/               # Dialog windows
└── screens/               # Main screens

Deliverables:
- UI screens (main menu, game screen)
- HUD elements
- Input handling
- Camera controls
- UI tests
```

**Agent 10: Rendering System**
```
modules/rendering/
├── map_renderer.gd        # Render map
├── unit_renderer.gd       # Render units
├── camera_controller.gd   # Camera system
└── effects/               # Visual effects

Deliverables:
- Map rendering
- Unit sprites
- Camera controls
- Visual effects
- Performance optimization
```

## Interface Contracts

### Module Interface Pattern

Each module exposes a clear public interface:

```gdscript
# modules/combat/combat_system_interface.gd
class_name CombatSystemInterface

## Interface for the Combat System
## All combat-related functionality goes through this interface

## Auto-resolve a combat between attackers and defenders
## Returns: CombatResult with outcome and casualties
func resolve_combat(
    attackers: Array[Unit],
    defenders: Array[Unit],
    terrain: Terrain
) -> CombatResult:
    pass

## Start a tactical battle
## Returns: TacticalBattle instance for turn-by-turn resolution
func start_tactical_battle(
    attackers: Array[Unit],
    defenders: Array[Unit],
    battlefield: Battlefield
) -> TacticalBattle:
    pass

## Calculate potential damage for UI preview
## Returns: Estimated damage range
func estimate_damage(
    attacker: Unit,
    defender: Unit,
    modifiers: Dictionary
) -> Dictionary:
    pass
```

### Interface Documentation

**Interface Contract Document** for each module:

```markdown
# Combat System Interface Contract

## Version: 1.0
## Owner: Agent 4

### Public Functions

#### `resolve_combat(attackers, defenders, terrain) -> CombatResult`

**Purpose**: Resolve combat automatically

**Parameters**:
- `attackers: Array[Unit]` - Attacking units
- `defenders: Array[Unit]` - Defending units
- `terrain: Terrain` - Terrain at battle location

**Returns**: `CombatResult`
```gdscript
{
    "outcome": CombatOutcome,  # ATTACKER_VICTORY, DEFENDER_VICTORY, STALEMATE
    "attacker_casualties": Array[Unit],  # Dead/wounded attackers
    "defender_casualties": Array[Unit],  # Dead/wounded defenders
    "loot": Dictionary,  # Resources gained by winner
    "morale_impact": Dictionary  # Morale changes
}
```

**Events Emitted**:
- `EventBus.combat_started(attacker_units, defender_units)`
- `EventBus.combat_ended(result)`

**Dependencies**:
- `UnitSystem.get_unit(unit_id)`
- `GameState.world_state.get_tile(position)`

**Errors**:
- Throws error if units array is empty
- Throws error if units are from same faction
```

## Development Workflow

### Phase 1: Specification (Week 1)

Each agent:
1. Reads architecture documentation
2. Reads their module assignment
3. Writes interface contract
4. Writes test specifications
5. Human reviews interface contracts

**Output**: Interface contracts for all modules

### Phase 2: Test-Driven Development (Weeks 2-4)

Each agent:
1. Writes tests based on interface contract
2. Implements module to pass tests
3. Documents implementation
4. Submits PR with tests + implementation

**No dependencies on other modules yet** - use mock/stub implementations.

Example:
```gdscript
# Agent 4 implementing CombatSystem
# Doesn't have real UnitSystem yet, so uses mock

func resolve_combat(attackers, defenders, terrain):
    # Mock unit data for now
    for unit in attackers:
        if not unit.has("stats"):
            unit.stats = _get_mock_stats()

    # Implement combat logic
    # ...
```

### Phase 3: Integration (Week 5)

**Integration Agent** (Agent 11):
1. Reviews all module PRs
2. Integrates modules
3. Replaces mocks with real implementations
4. Runs integration tests
5. Fixes integration issues

**Integration Checklist**:
```markdown
- [ ] All modules pass their unit tests
- [ ] Interface contracts match
- [ ] Mock implementations replaced
- [ ] Integration tests pass
- [ ] No circular dependencies
- [ ] Performance acceptable
```

### Phase 4: End-to-End Testing (Week 6)

All agents:
1. Run full game simulations
2. Test edge cases
3. Performance profiling
4. Bug fixing

## Communication Protocol

### Minimal Coordination

Agents communicate through:

**1. Interface Contracts** (primary)
- Document-based, no real-time communication needed
- Contracts committed to repo

**2. GitHub Issues** (async)
- Interface changes → open issue
- Breaking changes → tag relevant agents
- Questions → comment on issue

**3. Code Comments** (in-code)
```gdscript
# NOTE: This function is used by CombatSystem (Agent 4)
# If you change signature, update combat_resolver.gd
func get_unit_stats(unit_id: int) -> Dictionary:
    pass
```

**4. Integration Tests** (validation)
- Tests verify contracts are followed
- Failed tests indicate contract violation

### Conflict Resolution

**Scenario**: Two agents need to modify the same interface

**Solution**:
1. First agent to commit wins
2. Second agent adapts to new interface
3. If fundamental conflict, escalate to human (rare)

**Prevention**:
- Clear module boundaries minimize conflicts
- Interface changes go through review

## Validation Strategy

### Agent Self-Validation Checklist

Before submitting:
```markdown
## Pre-Submission Checklist

- [ ] All unit tests pass (90%+ coverage)
- [ ] Integration tests pass (if applicable)
- [ ] Interface contract followed exactly
- [ ] Documentation complete
- [ ] No TODO/FIXME comments
- [ ] Performance benchmarks met
- [ ] No GDScript errors/warnings
- [ ] Code follows style guide
- [ ] Dependencies clearly documented
- [ ] Events emitted as specified
```

### Automated Validation (CI)

```yaml
# Every PR triggers:
1. Lint check (GDScript syntax)
2. Unit tests (module-specific)
3. Integration tests (cross-module)
4. Performance tests (no regression)
5. Coverage check (>= 90%)
6. Documentation check (all public functions documented)
```

### Human Review Triggers

Automated review for most PRs, human review only for:
- Interface contract changes
- Cross-module breaking changes
- Performance regressions
- Test coverage below 90%

## Module Communication Patterns

### Pattern 1: Event Bus (Decoupled)

Preferred for cross-module notifications:

```gdscript
# Agent 4 (Combat System)
func resolve_combat(attackers, defenders, terrain):
    var result = _calculate_combat(attackers, defenders, terrain)
    EventBus.combat_ended.emit(result)
    return result

# Agent 5 (Economy System)
func _ready():
    EventBus.combat_ended.connect(_on_combat_ended)

func _on_combat_ended(result: CombatResult):
    # Award loot to winner
    _add_loot(result.winner, result.loot)
```

**Benefits**: No direct coupling, easy to test

### Pattern 2: Manager Access (Controlled)

For querying game state:

```gdscript
# Agent 4 (Combat System) needs unit data
func resolve_combat(attackers, defenders, terrain):
    for unit in attackers:
        var full_unit_data = Game.state.get_unit(unit.id)
        # Use full data
```

**Benefits**: Single source of truth, controlled access

### Pattern 3: Data Passing (Explicit)

For operations that need data:

```gdscript
# Agent 5 (Economy System)
func calculate_income(faction: FactionState) -> Dictionary:
    # All data passed in, no external dependencies
    var income = {}
    for building in faction.buildings:
        income[building.resource_type] += building.yield
    return income
```

**Benefits**: Pure functions, easy to test

## Testing in Parallel Development

### Test Doubles (Mocks/Stubs)

Each agent creates test doubles for dependencies:

```gdscript
# tests/mocks/mock_unit_system.gd
class_name MockUnitSystem

var _mock_units: Dictionary = {}

func get_unit(unit_id: int) -> Unit:
    if _mock_units.has(unit_id):
        return _mock_units[unit_id]
    return _create_default_mock_unit()

func add_mock_unit(unit: Unit):
    _mock_units[unit.id] = unit

func _create_default_mock_unit() -> Unit:
    var unit = Unit.new()
    unit.id = randi()
    unit.stats = {"attack": 20, "defense": 10}
    return unit
```

**Usage in tests**:
```gdscript
# tests/unit/test_combat_system.gd
extends GutTest

var combat_system: CombatSystem
var mock_unit_system: MockUnitSystem

func before_each():
    mock_unit_system = MockUnitSystem.new()
    combat_system = CombatSystem.new()
    combat_system.unit_system = mock_unit_system  # Inject mock

func test_attacker_wins():
    var strong_unit = mock_unit_system._create_unit({"attack": 50})
    var weak_unit = mock_unit_system._create_unit({"attack": 10})

    var result = combat_system.resolve_combat([strong_unit], [weak_unit], Terrain.new())

    assert_eq(result.outcome, CombatOutcome.ATTACKER_VICTORY)
```

### Integration Tests (Cross-Agent)

After modules integrated:

```gdscript
# tests/integration/test_combat_and_economy.gd
extends GutTest

func test_combat_awards_loot_to_winner():
    var game = Game.new()
    game.start_new_game({})

    var attacker = game.create_unit(UnitType.SOLDIER, Vector3i(0, 0, 1))
    var defender = game.create_unit(UnitType.MILITIA, Vector3i(0, 1, 1))

    var initial_scrap = game.state.factions[0].resources.scrap

    # Combat
    var result = game.combat_system.resolve_combat([attacker], [defender], Terrain.new())

    # Economy should have updated
    var final_scrap = game.state.factions[0].resources.scrap
    assert_gt(final_scrap, initial_scrap, "Winner should gain loot")
```

## Documentation Requirements

### Module README

Each module has README:

```markdown
# Combat System

## Owner: Agent 4

## Purpose
Handles all combat resolution, both auto-resolve and tactical battles.

## Dependencies
- `UnitSystem`: Unit data and stats
- `MapSystem`: Terrain modifiers
- `GameState`: World state

## Public Interface
See `combat_system_interface.gd` for full contract.

### Key Functions
- `resolve_combat(...)`: Auto-resolve combat
- `start_tactical_battle(...)`: Initiate tactical mode
- `estimate_damage(...)`: Calculate damage preview

## Events
- `EventBus.combat_started`: Emitted when combat begins
- `EventBus.combat_ended`: Emitted when combat resolves

## Testing
Run tests: `godot --headless -s tests/unit/test_combat_system.gd`
Coverage: 95%

## Performance
- Auto-resolve: < 50ms per battle
- Tactical battle turn: < 100ms
```

### Code Documentation

All public functions documented:

```gdscript
## Resolves combat automatically between two armies.
##
## Calculates strength based on unit stats, terrain, and modifiers.
## Determines outcome and casualties.
##
## @param attackers: Array of attacking Unit instances
## @param defenders: Array of defending Unit instances
## @param terrain: Terrain instance at battle location
## @return: CombatResult with outcome, casualties, and loot
##
## Example:
##   var result = resolve_combat([soldier1, soldier2], [militia1], plains)
##   if result.outcome == CombatOutcome.ATTACKER_VICTORY:
##       print("Attackers won!")
func resolve_combat(
    attackers: Array[Unit],
    defenders: Array[Unit],
    terrain: Terrain
) -> CombatResult:
    # Implementation...
```

## Consequences

### Positive
- ✅ Maximum parallelism - 10 agents working simultaneously
- ✅ Minimal merge conflicts (different modules)
- ✅ Clear ownership and accountability
- ✅ Interface-driven development ensures compatibility
- ✅ Test-driven development catches issues early
- ✅ Documentation-first approach provides context
- ✅ Automated validation reduces human oversight

### Negative
- ⚠️ Requires upfront architecture design
  - *Mitigation*: Architecture already defined in this ADR
- ⚠️ Integration phase could reveal issues
  - *Mitigation*: Interface contracts and tests minimize surprises
- ⚠️ Agents must be disciplined about boundaries
  - *Mitigation*: Automated linting and CI enforce boundaries

### Technical Implications
- Strict module boundaries enforced
- Interface contracts are immutable (changes require review)
- Comprehensive testing required (90%+ coverage)
- Documentation mandatory
- CI/CD enforces all rules

### Success Metrics
- 10 modules developed in parallel
- < 5% integration issues
- 90%+ test coverage across all modules
- < 10 interface contract violations
- First integrated build within 6 weeks

## Related Decisions
- ADR-007: Programming Language and Framework Selection
- ADR-008: Game Engine Architecture
- ADR-010: Testing and CI/CD Strategy

## References
- [Godot GDScript Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [Interface Segregation Principle](https://en.wikipedia.org/wiki/Interface_segregation_principle)

## Date
2025-11-12

## Authors
Architecture Team
