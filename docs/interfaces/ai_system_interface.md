# AI System Interface Contract

**Module**: AI System
**Location**: `systems/ai/`
**Layer**: Layer 3 (AI)
**Dependencies**: All game systems (Core, Map, Units, Combat, Economy, Culture, Events)
**Version**: 1.0
**Status**: Interface Definition
**Agent**: Agent 7

---

## Executive Summary

The AI System provides autonomous decision-making for AI-controlled factions in Ashes to Empire. It implements a multi-layered AI architecture combining strategic planning, tactical execution, and distinct personalities to create challenging and varied AI opponents.

### Design Philosophy
- **Utility-Based AI**: Actions scored based on current game state and personality
- **Goal-Oriented Planning**: AI maintains long-term strategic goals
- **Personality-Driven**: Three distinct personalities with different playstyles
- **Deterministic Core**: Same inputs produce same outputs (for testing/replay)
- **Fail-Safe Design**: AI never crashes or stalls the game

---

## Module Components

```
systems/ai/
├── faction_ai.gd          # High-level strategic AI controller
├── goal_planner.gd        # Goal selection and planning system
├── tactical_ai.gd         # Combat and unit control AI
├── utility_scorer.gd      # Action scoring and evaluation
└── personalities/         # AI personality implementations
    ├── aggressive.gd      # Military-focused aggressive AI
    ├── defensive.gd       # Territory defense and fortification AI
    └── economic.gd        # Resource and growth focused AI
```

---

## Key Responsibilities

1. **Strategic Decision-Making**: Plan faction-level actions (expansion, warfare, diplomacy, research)
2. **Goal Planning**: Maintain and prioritize long-term strategic goals
3. **Action Scoring**: Evaluate and rank all possible actions using utility-based scoring
4. **Personality Implementation**: Provide three distinct AI playstyles
5. **Tactical AI**: Control units in combat situations (basic for MVP, auto-resolve focus)
6. **Fail-Safe Execution**: Ensure AI always makes valid decisions and never hangs

---

## Public Functions

### FactionAI Core Functions

#### plan_turn(faction_id: int, game_state: GameState) -> Array[AIAction]
Plans and returns all actions for the AI faction's turn.

**Parameters**:
- `faction_id`: ID of the faction being controlled
- `game_state`: Current game state (read-only)

**Returns**:
- Array of `AIAction` objects, sorted by priority (highest first)

**Behavior**:
- Analyzes current game state
- Updates internal threat assessment
- Evaluates opportunities and weaknesses
- Generates action candidates
- Scores actions using utility system
- Returns prioritized action list

**Performance**: < 3 seconds for typical game state (8 factions, 200x200 map)

**Error Conditions**:
- Returns empty array if faction_id invalid
- Returns default defensive actions if game_state is null/corrupted
- Logs warning if scoring takes > 5 seconds

---

#### score_action(action: AIAction, faction_id: int, game_state: GameState) -> float
Scores a single action for the given faction.

**Parameters**:
- `action`: The action to evaluate
- `faction_id`: ID of the faction evaluating the action
- `game_state`: Current game state (read-only)

**Returns**:
- Float score value (0.0 to 100.0, higher is better)

**Behavior**:
- Evaluates action based on:
  - Immediate benefit (resources, territory, etc.)
  - Risk assessment (probability of success)
  - Strategic alignment (matches faction goals)
  - Personality modifiers (weights based on AI type)
  - Long-term consequences (2-3 turns lookahead)

**Performance**: < 10ms per action

**Error Conditions**:
- Returns 0.0 if action is invalid
- Returns 0.0 if faction_id doesn't exist
- Clamps return value to 0.0-100.0 range

---

#### select_production(faction_id: int, available_resources: Dictionary) -> String
Selects what unit or building to produce next.

**Parameters**:
- `faction_id`: ID of the faction
- `available_resources`: Dictionary of current resource stockpiles
  ```gdscript
  {
    "scrap": int,
    "food": int,
    "medicine": int,
    "ammunition": int,
    "fuel": int,
    "components": int,
    "water": int,
    "production_points": int
  }
  ```

**Returns**:
- String identifier of unit/building type to produce (e.g., "soldier", "factory")
- Empty string if no valid production options available

**Behavior**:
- Evaluates production queue priorities
- Considers resource availability
- Balances military vs. economic production
- Respects personality preferences (aggressive = more military, etc.)
- Ensures faction doesn't over-invest in single unit type

**Performance**: < 50ms

**Error Conditions**:
- Returns "" if no affordable options
- Returns "militia" as fallback if scoring fails

---

#### select_culture_node(faction_id: int, available_nodes: Array[String]) -> String
Selects which culture node to unlock next.

**Parameters**:
- `faction_id`: ID of the faction
- `available_nodes`: Array of culture node IDs that can be unlocked

**Returns**:
- String ID of selected culture node
- Empty string if no nodes available or none desirable

**Behavior**:
- Evaluates culture nodes based on:
  - Alignment with victory condition
  - Synergy with existing culture choices
  - Personality preferences
  - Current strategic needs (e.g., military culture if at war)
- Prioritizes nodes that unlock key units/buildings

**Performance**: < 20ms

**Error Conditions**:
- Returns "" if available_nodes is empty
- Returns first available node if scoring fails

---

#### plan_movement(unit_id: int, game_state: GameState) -> Vector3i
Plans movement for a single unit.

**Parameters**:
- `unit_id`: ID of the unit to move
- `game_state`: Current game state (read-only)

**Returns**:
- `Vector3i` target position for unit movement
- Returns unit's current position if no movement desired

**Behavior**:
- Evaluates tactical situation
- Considers:
  - Nearby enemies (attack or avoid)
  - Friendly units (formation, support)
  - Strategic objectives (capture locations, defend territory)
  - Terrain and fog of war
  - Unit role (scouts explore, soldiers defend, etc.)
- Uses pathfinding to find reachable position

**Performance**: < 50ms per unit

**Error Conditions**:
- Returns current position if unit_id invalid
- Returns current position if unit has no movement remaining
- Returns safe fallback position if pathfinding fails

---

#### plan_attack(unit_id: int, game_state: GameState) -> Dictionary
Plans an attack action for a unit.

**Parameters**:
- `unit_id`: ID of the attacking unit
- `game_state`: Current game state (read-only)

**Returns**:
- Dictionary with attack details:
  ```gdscript
  {
    "should_attack": bool,           # Whether to attack
    "target_id": int,                 # Target unit ID
    "use_tactical": bool,             # Use tactical combat vs auto-resolve
    "ability": String                 # Special ability to use, or ""
  }
  ```

**Behavior**:
- Identifies potential targets in range
- Evaluates combat odds using combat calculator
- Considers:
  - Probability of victory
  - Potential casualties
  - Strategic value of target
  - Risk vs. reward
- Recommends tactical combat for important battles
- Selects appropriate special abilities

**Performance**: < 100ms per unit

**Error Conditions**:
- Returns `{"should_attack": false}` if unit_id invalid
- Returns `{"should_attack": false}` if no valid targets
- Defaults to auto-resolve if uncertainty in tactical decision

---

#### set_personality(faction_id: int, personality: String) -> void
Sets the AI personality for a faction.

**Parameters**:
- `faction_id`: ID of the faction
- `personality`: Personality type ("aggressive", "defensive", "economic")

**Returns**: void

**Behavior**:
- Changes AI behavior weights
- Loads personality-specific parameters
- Updates goal priorities
- Emits `EventBus.ai_personality_changed` signal

**Performance**: < 1ms (configuration change only)

**Error Conditions**:
- Logs warning if faction_id invalid (no-op)
- Defaults to "defensive" if personality string invalid
- Logs warning if personality name not recognized

---

### GoalPlanner Functions

#### update_goals(faction_id: int, game_state: GameState) -> void
Updates faction's strategic goals based on current situation.

**Parameters**:
- `faction_id`: ID of the faction
- `game_state`: Current game state

**Returns**: void

**Behavior**:
- Analyzes faction's current state
- Updates goal priorities based on:
  - Victory conditions progress
  - Threats from other factions
  - Resource availability
  - Cultural progression
  - Expansion opportunities
- Maintains goal stack (LIFO for urgent goals)

**Performance**: < 100ms per faction

---

#### get_active_goals(faction_id: int) -> Array[AIGoal]
Returns current active goals for a faction.

**Parameters**:
- `faction_id`: ID of the faction

**Returns**:
- Array of `AIGoal` objects, ordered by priority

---

### TacticalAI Functions (Basic MVP Implementation)

#### select_unit_action(unit_id: int, battle_state: BattleState) -> Dictionary
Selects action for unit in tactical combat (future expansion).

**Note**: MVP focuses on auto-resolve. This is a stub for future tactical combat.

**Parameters**:
- `unit_id`: ID of the unit
- `battle_state`: Current tactical battle state

**Returns**:
- Dictionary with action details (format TBD for post-MVP)

---

### UtilityScorer Functions

#### score_expansion(target_tile: Vector3i, faction_id: int, game_state: GameState) -> float
Scores the value of expanding to a tile.

**Parameters**:
- `target_tile`: Position to evaluate
- `faction_id`: ID of evaluating faction
- `game_state`: Current game state

**Returns**:
- Float score (0.0 to 100.0)

**Scoring Factors**:
- Resources on tile (+10 per resource type)
- Unique locations (+30 for valuable sites)
- Strategic position (+15 if borders enemies)
- Defensibility (+10 for good terrain)
- Distance from borders (-5 per tile distance)

---

#### score_combat(attacker_units: Array, defender_units: Array, terrain: Tile) -> float
Scores combat viability (chance of success).

**Parameters**:
- `attacker_units`: Array of attacking units
- `defender_units`: Array of defending units
- `terrain`: Tile where combat occurs

**Returns**:
- Float score representing expected outcome (-100 to +100)
  - Positive: Attacker favored
  - Negative: Defender favored
  - Magnitude indicates confidence

**Uses**: Combat system's strength calculation

---

## Data Structures

### AIAction
Main data structure for AI decisions.

```gdscript
class_name AIAction
extends RefCounted

enum ActionType {
    MOVE_UNIT,           # Move a unit
    ATTACK,              # Attack with unit
    BUILD_UNIT,          # Start building a unit
    BUILD_BUILDING,      # Start building a structure
    RESEARCH,            # Select research/culture node
    TRADE,               # Establish trade route
    RECRUIT,             # Recruit new units
    SCAVENGE,            # Send scavengers to tile
    FORTIFY,             # Build fortifications
    DIPLOMACY,           # Diplomatic action (future)
    END_TURN             # End turn (always last)
}

var type: ActionType              # Type of action
var priority: float               # Priority score (0.0-100.0, higher = more important)
var parameters: Dictionary        # Action-specific parameters

# Example parameters by type:
# MOVE_UNIT: {"unit_id": int, "target": Vector3i}
# ATTACK: {"unit_id": int, "target_id": int, "use_tactical": bool}
# BUILD_UNIT: {"unit_type": String, "location": Vector3i}
# BUILD_BUILDING: {"building_type": String, "location": Vector3i}
# RESEARCH: {"node_id": String}
# TRADE: {"target_faction": int, "offer": Dictionary, "request": Dictionary}
```

---

### AIGoal
Represents strategic goals.

```gdscript
class_name AIGoal
extends RefCounted

enum GoalType {
    EXPAND_TERRITORY,    # Expand controlled area
    MILITARY_CONQUEST,   # Conquer specific faction/location
    ECONOMIC_GROWTH,     # Build economy
    CULTURAL_VICTORY,    # Pursue cultural victory
    TECH_ADVANCEMENT,    # Research focus
    DEFEND_TERRITORY,    # Defensive posture
    ESTABLISH_TRADE,     # Create trade network
    SECURE_RESOURCE      # Control specific resource type
}

var type: GoalType               # Type of goal
var priority: float              # Priority (0.0-100.0)
var target: Variant              # Goal-specific target (faction ID, location, etc.)
var progress: float              # Completion progress (0.0-1.0)
var turns_active: int            # How long goal has been active
```

---

### AIThreatAssessment
Internal threat tracking.

```gdscript
class_name AIThreatAssessment
extends RefCounted

var faction_id: int              # Faction being assessed
var military_strength: float     # Estimated military power (0-100)
var economic_strength: float     # Estimated economic power (0-100)
var threat_level: float          # Overall threat (0-100)
var distance: int                # Distance in tiles to nearest border
var relationship: String         # "hostile", "neutral", "friendly", "ally"
var recent_actions: Array[String] # Recent hostile/friendly actions
```

---

## AI Personalities

### Aggressive
**Philosophy**: "The best defense is a good offense."

**Characteristics**:
- Prioritizes military production (+40% weight)
- Seeks early combat opportunities
- Expands aggressively into contested territory
- Less concerned with economic development
- High risk tolerance
- Prefers military victory condition

**Goal Priorities**:
1. MILITARY_CONQUEST (90)
2. EXPAND_TERRITORY (70)
3. SECURE_RESOURCE - Ammunition/Fuel (60)
4. ECONOMIC_GROWTH (40)
5. CULTURAL_VICTORY (20)

**Behavior Modifiers**:
- Combat willingness: +50% (attacks at 60/40 odds vs. 80/20 for defensive)
- Military spending: 60-70% of production
- Trade priority: Low (prefers conquest)
- Expansion rate: Fast
- Culture selection: Military-focused nodes

**Production Queue**:
- 70% military units
- 20% economic buildings (to sustain war)
- 10% infrastructure

**Tactical Behavior**:
- Prefers offense over defense
- Focuses fire on weakest targets
- Uses terrain aggressively (charges from high ground)
- Accepts higher casualties for objectives

---

### Defensive
**Philosophy**: "Secure what you have before seeking more."

**Characteristics**:
- Prioritizes fortification and defense
- Expands cautiously into secure territory
- Builds strong economy behind defensive lines
- High emphasis on territory control
- Low risk tolerance
- Prefers cultural or diplomatic victory

**Goal Priorities**:
1. DEFEND_TERRITORY (95)
2. ECONOMIC_GROWTH (80)
3. ESTABLISH_TRADE (70)
4. CULTURAL_VICTORY (60)
5. EXPAND_TERRITORY (40)
6. MILITARY_CONQUEST (20)

**Behavior Modifiers**:
- Combat willingness: -30% (only attacks at 90/10 odds or better)
- Military spending: 30-40% of production (defensive units)
- Trade priority: High (mutual benefit)
- Expansion rate: Slow, methodical
- Culture selection: Defensive and economic nodes

**Production Queue**:
- 40% defensive military (militia, fortifications)
- 50% economic buildings
- 10% infrastructure and culture

**Tactical Behavior**:
- Prefers defensive positions
- Uses fortifications heavily
- Retreats rather than accepting heavy casualties
- Focuses on protecting key locations

---

### Economic
**Philosophy**: "Wealth is power."

**Characteristics**:
- Maximizes resource production and trade
- Avoids military conflict when possible
- Pursues diplomatic and economic victories
- High trade engagement
- Moderate risk tolerance
- Flexible victory condition (adapts to opportunities)

**Goal Priorities**:
1. ECONOMIC_GROWTH (95)
2. ESTABLISH_TRADE (85)
3. SECURE_RESOURCE - All types (70)
4. CULTURAL_VICTORY (60)
5. EXPAND_TERRITORY (50)
6. DEFEND_TERRITORY (50)
7. MILITARY_CONQUEST (10)

**Behavior Modifiers**:
- Combat willingness: -20% (avoids combat unless favorable)
- Military spending: 25-35% of production (defensive minimum)
- Trade priority: Very high (trades with everyone)
- Expansion rate: Opportunistic (targets resource-rich tiles)
- Culture selection: Economic and trade-focused nodes

**Production Queue**:
- 25% military (minimal defense)
- 65% economic buildings
- 10% cultural/infrastructure

**Tactical Behavior**:
- Avoids combat when possible
- Hires mercenaries if needed (future feature)
- Uses economic leverage in diplomacy
- Focuses on protecting economic assets

---

## Events

### Events Emitted
The AI System does **not** emit events (it is a reactive system).

### Events Consumed (Reacted To)
The AI System reacts to these EventBus signals:

#### Game Events
- `EventBus.turn_started(turn_number: int)` - Triggers AI planning for new turn
- `EventBus.faction_turn_started(faction_id: int)` - Triggers specific faction AI
- `EventBus.game_state_changed(state: GameState)` - Updates AI's world knowledge

#### Combat Events
- `EventBus.combat_started(attacker_id, defender_id, location)` - AI decides on reinforcements
- `EventBus.combat_ended(result: CombatResult)` - AI updates threat assessment
- `EventBus.unit_destroyed(unit_id, owner_faction)` - AI adjusts military strength estimates

#### Territory Events
- `EventBus.tile_captured(position, old_owner, new_owner)` - AI updates territory control maps
- `EventBus.unique_location_captured(location_id, new_owner)` - AI re-evaluates strategic priorities

#### Economic Events
- `EventBus.resource_changed(faction_id, resource_type, amount)` - AI updates resource tracking
- `EventBus.trade_route_established(faction_a, faction_b)` - AI notes diplomatic relationships

#### Culture Events
- `EventBus.culture_node_unlocked(faction_id, node_id)` - AI updates faction capabilities assessment

---

## Dependencies

### Required Dependencies (Layer 3 - AI depends on all game systems)

#### Core Foundation (Layer 0)
- `GameState`: Read current game state for decision-making
- `EventBus`: Listen to game events
- `TurnManager`: Respond to turn phases

#### Map System (Layer 1)
- `MapData`: Query tile information, find paths, assess territory
- `FogOfWar`: Understand what AI can see
- `SpatialQuery`: Find tiles in radius, identify borders

#### Unit System (Layer 2)
- `UnitManager`: Query unit stats, create movement plans
- `Unit`: Access unit capabilities, stats, position

#### Combat System (Layer 2)
- `CombatCalculator`: Estimate combat outcomes before attacking
- `CombatResolver`: Understand combat mechanics for decision-making

#### Economy System (Layer 2)
- `ResourceManager`: Read faction resources
- `ProductionSystem`: Understand production costs and times
- `TradeSystem`: Evaluate trade opportunities

#### Culture System (Layer 1)
- `CultureTree`: Query available culture nodes
- `CultureEffects`: Understand what unlocks provide

#### Event System (Layer 1)
- `EventManager`: Understand active events affecting decisions

### Optional Dependencies
- None (AI uses all systems)

---

## Performance Requirements

### Turn Planning Performance
- **Target**: < 3 seconds per faction per turn (8 AI factions = < 24 seconds total)
- **Acceptable**: < 5 seconds per faction
- **Maximum**: 10 seconds per faction (warning logged)

### Action Scoring Performance
- **Target**: < 10ms per action
- **Acceptable**: < 50ms per action
- **Maximum**: 100ms per action

### Function-Specific Performance

| Function | Target | Acceptable | Maximum |
|----------|--------|------------|---------|
| plan_turn() | 3s | 5s | 10s |
| score_action() | 10ms | 50ms | 100ms |
| select_production() | 20ms | 50ms | 100ms |
| select_culture_node() | 10ms | 20ms | 50ms |
| plan_movement() | 30ms | 50ms | 100ms |
| plan_attack() | 50ms | 100ms | 200ms |

### Memory Usage
- **Target**: < 50MB per faction AI instance
- **Maximum**: 100MB per faction AI instance

### Determinism
- **Requirement**: 100% deterministic with same random seed
- **Testing**: Same game state + same seed = identical AI decisions

---

## Test Specifications

### Unit Tests

#### Test: AI Makes Valid Decisions
```gdscript
func test_ai_plans_valid_turn():
    var game_state = create_test_game_state()
    var ai = FactionAI.new(1, "aggressive")

    var actions = ai.plan_turn(1, game_state)

    assert_gt(actions.size(), 0, "AI should return at least one action")
    for action in actions:
        assert_true(_is_valid_action(action, game_state), "All actions must be valid")
```

#### Test: Action Scoring Consistency
```gdscript
func test_action_scoring_deterministic():
    var game_state = create_test_game_state()
    var ai = FactionAI.new(1, "aggressive")
    var action = create_test_action(AIAction.ActionType.MOVE_UNIT)

    var score1 = ai.score_action(action, 1, game_state)
    var score2 = ai.score_action(action, 1, game_state)

    assert_eq(score1, score2, "Score should be deterministic")
```

#### Test: Personality Differences
```gdscript
func test_personalities_behave_differently():
    var game_state = create_test_game_state()

    var aggressive_ai = FactionAI.new(1, "aggressive")
    var defensive_ai = FactionAI.new(2, "defensive")
    var economic_ai = FactionAI.new(3, "economic")

    var agg_actions = aggressive_ai.plan_turn(1, game_state)
    var def_actions = defensive_ai.plan_turn(2, game_state)
    var eco_actions = economic_ai.plan_turn(3, game_state)

    var agg_military = _count_military_actions(agg_actions)
    var def_military = _count_military_actions(def_actions)
    var eco_trade = _count_trade_actions(eco_actions)

    assert_gt(agg_military, def_military, "Aggressive should prioritize military more")
    assert_gt(eco_trade, agg_military, "Economic should trade more than aggressive attacks")
```

#### Test: AI Doesn't Crash
```gdscript
func test_ai_handles_edge_cases():
    var ai = FactionAI.new(1, "aggressive")

    # Test with null state
    var actions = ai.plan_turn(1, null)
    assert_not_null(actions, "Should handle null state gracefully")

    # Test with invalid faction
    actions = ai.plan_turn(999, create_test_game_state())
    assert_eq(actions.size(), 0, "Should return empty array for invalid faction")

    # Test with empty resources
    var production = ai.select_production(1, {})
    assert_true(production == "" or production == "militia", "Should handle empty resources")
```

---

### Integration Tests

#### Test: AI vs AI Game Completes
```gdscript
func test_ai_vs_ai_game_100_turns():
    var game = Game.new()
    game.start_new_game({
        "all_ai": true,
        "num_factions": 4,
        "personalities": ["aggressive", "defensive", "economic", "aggressive"]
    })

    for turn in range(100):
        game.process_turn()
        assert_false(game.state.is_corrupted(), "Game state should remain valid")
        assert_true(game.state.turn_number == turn + 2, "Turns should progress")

    assert_eq(game.state.turn_number, 101, "Should complete 100 turns")
```

#### Test: AI Responds to Threats
```gdscript
func test_ai_responds_to_invasion():
    var game = create_test_game_with_invasion_setup()
    var defender_ai = game.factions[0].ai  # Defensive AI

    # Simulate enemy invasion
    game.state.factions[1].units.append(create_unit_near_border(0))

    var actions = defender_ai.plan_turn(0, game.state)

    var military_actions = _count_military_actions(actions)
    assert_gt(military_actions, 0, "AI should respond to threats with military actions")
```

#### Test: AI Manages Economy
```gdscript
func test_ai_manages_resources():
    var game = Game.new()
    game.start_new_game({"all_ai": true, "num_factions": 1})

    var initial_resources = game.state.factions[0].resources.scrap

    # Run 50 turns
    for i in range(50):
        game.process_turn()

    var final_resources = game.state.factions[0].resources.scrap

    # AI should accumulate resources over time
    assert_gt(final_resources, initial_resources, "AI should grow economy")
```

---

### System Tests

#### Test: Full AI Game to Victory
```gdscript
func test_ai_game_reaches_victory():
    var game = Game.new()
    game.start_new_game({
        "all_ai": true,
        "num_factions": 8,
        "fast_mode": true,  # Skip animations, etc.
        "max_turns": 500
    })

    var max_turns = 500
    for turn in range(max_turns):
        game.process_turn()
        if game.check_victory():
            break

    assert_true(game.has_winner(), "AI game should reach victory condition")
    assert_lt(game.state.turn_number, max_turns, "Should complete before max turns")
```

#### Test: Performance Benchmarks
```gdscript
func test_ai_performance_benchmarks():
    var game = create_large_game_state()  # 8 factions, 200x200 map

    for faction_id in range(8):
        var ai = game.factions[faction_id].ai
        var start_time = Time.get_ticks_msec()

        var actions = ai.plan_turn(faction_id, game.state)

        var elapsed = Time.get_ticks_msec() - start_time
        assert_lt(elapsed, 5000, "AI turn planning should complete in < 5 seconds")
```

---

### Test Coverage Target
- **Overall**: 85%+ (AI is complex, some paths hard to test)
- **Critical paths**: 95%+ (action scoring, decision validity)
- **Edge cases**: 80%+ (error handling, null checks)

---

## Error Handling

### Error Categories

#### Invalid Input
- **Behavior**: Log warning, return safe default
- **Example**: Invalid faction_id → return empty action array
- **Recovery**: Automatic

#### Corrupted Game State
- **Behavior**: Log error, return defensive actions
- **Example**: Null game_state → return [END_TURN action]
- **Recovery**: Automatic, may degrade AI quality

#### Performance Timeout
- **Behavior**: Log warning, return best actions found so far
- **Example**: plan_turn() exceeds 10s → return prioritized actions completed
- **Recovery**: Automatic, may have incomplete planning

#### Scoring Failure
- **Behavior**: Use fallback heuristics
- **Example**: score_action() crashes → assign default score of 50.0
- **Recovery**: Automatic, may make suboptimal decisions

---

## Integration Points

### Integration with Turn Manager
```gdscript
# TurnManager calls AI for each AI-controlled faction
func process_ai_faction_turn(faction_id: int):
    var ai = get_faction_ai(faction_id)
    var actions = ai.plan_turn(faction_id, game_state)

    for action in actions:
        execute_action(action)
```

### Integration with Combat System
```gdscript
# AI uses combat calculator to evaluate battles
var combat_calc = CombatCalculator.new()
var expected_outcome = combat_calc.calculate_auto_resolve(attackers, defenders, terrain)

if expected_outcome.attacker_victory_probability > 0.7:
    # Plan attack
    return create_attack_action(target)
```

### Integration with Economy System
```gdscript
# AI reads resource state to plan production
var resources = ResourceManager.get_faction_resources(faction_id)

if resources.scrap > 100 and resources.ammunition > 50:
    return select_production(faction_id, resources)
```

---

## Future Enhancements (Post-MVP)

### Advanced Tactical AI
- Full tactical combat control
- Flanking and positioning strategies
- Ability usage optimization
- Formation management

### Diplomacy AI
- Treaty negotiation
- Alliance management
- Betrayal detection and prevention
- Diplomatic victory pursuit

### Learning AI (Optional)
- Track successful strategies
- Adapt to player tactics
- Difficulty scaling based on player skill

### Multi-Turn Planning
- 5-10 turn lookahead for strategic decisions
- Build order optimization
- Coordinated multi-faction strategies (alliances)

---

## Notes for Implementation

### Development Order
1. **Week 1**: Core data structures (AIAction, AIGoal, AIThreatAssessment)
2. **Week 1**: UtilityScorer (action scoring framework)
3. **Week 2**: FactionAI basic framework (plan_turn stub, action execution)
4. **Week 2**: GoalPlanner (goal tracking and updates)
5. **Week 3**: Personality implementations (Aggressive, Defensive, Economic)
6. **Week 3**: Production and culture selection
7. **Week 3**: Movement and attack planning
8. **Week 4**: Integration testing and tuning
9. **Week 4**: Performance optimization

### Testing Strategy
- Use mocks for game systems initially
- Create test game states with known scenarios
- Run AI vs AI battles extensively
- Validate determinism with replay tests
- Performance test with realistic game states

### Tuning Parameters
Many AI behaviors will need tuning. Create data files for:
- Personality weight modifiers
- Scoring function coefficients
- Goal priority values
- Risk tolerance thresholds

Example: `data/ai/aggressive_personality.json`
```json
{
  "name": "Aggressive",
  "military_production_weight": 1.4,
  "combat_threshold": 0.6,
  "expansion_speed": "fast",
  "risk_tolerance": 0.7
}
```

---

## Validation Checklist

Before marking AI System as complete:

- [ ] All public functions implemented with correct signatures
- [ ] All three personalities functional and distinct
- [ ] AI vs AI game completes to victory without crashes
- [ ] Performance benchmarks met (< 5s per turn)
- [ ] Deterministic behavior verified
- [ ] Unit tests pass (85%+ coverage)
- [ ] Integration tests pass
- [ ] Error handling tested
- [ ] Documentation complete

---

**Document Version**: 1.0
**Last Updated**: 2025-11-12
**Status**: Ready for Implementation
**Agent 7**: AI System Module Owner
