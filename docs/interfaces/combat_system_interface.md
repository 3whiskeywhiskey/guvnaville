# Combat System Interface Contract

**Module**: Combat System (`systems/combat/`)
**Agent**: Agent 4
**Version**: 1.0
**Last Updated**: 2025-11-12

---

## Overview

The Combat System module handles all combat resolution including auto-resolve calculations, tactical combat mechanics (stub for MVP), combat modifiers, morale checks, and loot distribution. It is responsible for determining battle outcomes, applying casualties, and managing morale-based retreats.

## Dependencies

- **Layer 1 (Core)**: Core Foundation (`core/`)
- **Layer 2 (Data)**: Map System (`systems/map/`), Unit System (`systems/units/`)

## Module Structure

```
systems/combat/
├── combat_resolver.gd         # Auto-resolve combat engine
├── combat_calculator.gd       # Damage and strength calculations
├── tactical_combat.gd         # Tactical battle engine (stub for MVP)
├── combat_modifiers.gd        # Terrain, elevation, culture modifiers
├── morale_system.gd           # Morale checks and retreat logic
└── loot_calculator.gd         # Loot distribution after combat
```

---

## Public Classes and Data Structures

### CombatResult

Represents the outcome of a resolved combat encounter.

```gdscript
class_name CombatResult
extends Resource

enum CombatOutcome {
    ATTACKER_DECISIVE_VICTORY,  # Attacker wins decisively (1.5x+ strength)
    ATTACKER_VICTORY,           # Attacker wins (1.0-1.5x strength)
    STALEMATE,                  # No clear winner (0.9-1.1x ratio)
    DEFENDER_VICTORY,           # Defender wins (1.0-1.5x strength)
    DEFENDER_DECISIVE_VICTORY,  # Defender wins decisively (1.5x+ strength)
    RETREAT                     # One side retreated before conclusion
}

var outcome: CombatOutcome
var attacker_casualties: Array[Unit]       # Units destroyed/damaged
var defender_casualties: Array[Unit]       # Units destroyed/damaged
var attacker_survivors: Array[Unit]        # Units that survived
var defender_survivors: Array[Unit]        # Units that survived
var loot: Dictionary                       # Resources gained by winner
var experience_gained: Dictionary          # XP per unit {unit_id: int}
var location: Vector3i                     # Where combat occurred
var duration: float                        # Combat duration in seconds
var attacker_strength: float               # Calculated attacker strength
var defender_strength: float               # Calculated defender strength
var strength_ratio: float                  # attacker_strength / defender_strength
var attacker_morale_loss: int              # Total morale damage to attackers
var defender_morale_loss: int              # Total morale damage to defenders
var retreated_units: Array[Unit]           # Units that retreated
var terrain_modifiers: Dictionary          # Applied terrain bonuses/penalties
```

### CombatModifiers

Encapsulates all combat modifiers for a specific engagement.

```gdscript
class_name CombatModifiers
extends Resource

var terrain_modifier: float = 1.0          # Terrain type modifier
var cover_bonus: int = 0                   # Defense bonus from cover
var elevation_modifier: float = 1.0        # +25% higher, -15% lower, 1.0 same
var flanking_bonus: float = 0.0            # +15% if flanking
var fortification_bonus: int = 0           # +5 to +15 defense
var cultural_bonuses: Dictionary = {}      # Culture-specific bonuses
var weather_modifier: float = 1.0          # Weather effects (future)
var supply_penalty: float = 1.0            # Reduced if unsupplied
var morale_modifier: float = 1.0           # Morale effects on effectiveness
var unit_experience_bonus: float = 1.0     # Veteran/Elite bonuses
var special_abilities: Array = []          # Active special abilities
var total_attack_multiplier: float = 1.0   # Combined attack multiplier
var total_defense_bonus: int = 0           # Combined defense bonus
```

### MoraleCheckResult

Result of a morale check on a unit.

```gdscript
class_name MoraleCheckResult
extends Resource

enum MoraleState {
    HOLDING,           # Unit maintains position and morale
    SHAKEN,           # -10% attack, may retreat soon
    RETREATING,       # Unit is fleeing
    BROKEN,           # Complete rout, unit destroyed or disbanded
    RALLIED           # Previously shaken but recovered
}

var unit_id: String
var previous_morale: int
var current_morale: int
var morale_change: int
var state: MoraleState
var will_retreat: bool
var retreat_direction: Vector3i   # Direction of retreat
var rally_chance: float           # Chance to rally if retreating
```

---

## Public Functions

### CombatResolver

Main combat resolution interface for auto-resolve and tactical combat initiation.

#### resolve_combat

```gdscript
func resolve_combat(
    attackers: Array[Unit],
    defenders: Array[Unit],
    location: Vector3i,
    terrain: Tile
) -> CombatResult
```

**Description**: Performs auto-resolve combat calculation and returns the complete result.

**Parameters**:
- `attackers`: Array of attacking units
- `defenders`: Array of defending units
- `location`: Tile position where combat occurs
- `terrain`: Tile data for terrain modifiers

**Returns**: `CombatResult` with complete battle outcome

**Side Effects**:
- Emits `EventBus.combat_started`
- Emits `EventBus.combat_resolved`
- Updates unit HP and morale
- May trigger morale checks
- Distributes loot to winner
- Awards experience to survivors

**Error Conditions**:
- Returns null if attackers or defenders array is empty
- Logs warning if location is out of bounds
- Clamps all calculations to valid ranges

**Performance**: < 100ms for battles with up to 10 units per side

**Example**:
```gdscript
var attackers = [unit1, unit2, unit3]
var defenders = [enemy1, enemy2]
var tile = MapData.get_tile(location)
var result = CombatResolver.resolve_combat(attackers, defenders, location, tile)

if result.outcome == CombatResult.CombatOutcome.ATTACKER_VICTORY:
    print("Victory! Loot: ", result.loot)
```

---

#### initiate_tactical_combat

```gdscript
func initiate_tactical_combat(
    attackers: Array[Unit],
    defenders: Array[Unit],
    location: Vector3i,
    map_subset: Array[Tile]
) -> void
```

**Description**: Initiates tactical combat mode (stub for MVP - calls auto-resolve).

**Parameters**:
- `attackers`: Array of attacking units
- `defenders`: Array of defending units
- `location`: Center position for tactical map
- `map_subset`: 20x20 tile subset for tactical battle

**Returns**: void (result delivered via `EventBus.tactical_combat_ended`)

**Side Effects**:
- Emits `EventBus.tactical_combat_started`
- Transitions game to tactical combat mode
- **MVP**: Immediately calls `resolve_combat()` for auto-resolve

**Performance**: N/A (instant redirect to auto-resolve in MVP)

---

#### predict_combat_outcome

```gdscript
func predict_combat_outcome(
    attackers: Array[Unit],
    defenders: Array[Unit],
    location: Vector3i
) -> CombatResult
```

**Description**: Calculates combat outcome WITHOUT applying changes. Used for UI predictions.

**Parameters**: Same as `resolve_combat`

**Returns**: `CombatResult` with predicted outcome (units not modified)

**Side Effects**: None (read-only simulation)

**Performance**: < 50ms

**Example**:
```gdscript
var prediction = CombatResolver.predict_combat_outcome(my_units, enemy_units, target_tile)
if prediction.strength_ratio < 0.8:
    show_warning("This attack is risky!")
```

---

### CombatCalculator

Core calculation engine for damage, strength, and combat math.

#### calculate_damage

```gdscript
func calculate_damage(
    attacker: Unit,
    defender: Unit,
    modifiers: CombatModifiers
) -> int
```

**Description**: Calculates raw damage dealt by attacker to defender.

**Formula**:
```
effective_attack = attacker.stats.attack * modifiers.total_attack_multiplier
effective_defense = defender.stats.defense + modifiers.total_defense_bonus + (defender.stats.armor * 0.01 * defender.stats.defense)
raw_damage = effective_attack - effective_defense
clamped_damage = max(raw_damage, 5)  # Minimum 5 damage
final_damage = clamped_damage * randf_range(0.85, 1.15)  # ±15% variance
```

**Parameters**:
- `attacker`: Unit dealing damage
- `defender`: Unit receiving damage
- `modifiers`: Combat modifiers to apply

**Returns**: Integer damage value (always >= 5)

**Performance**: < 1ms per call

---

#### calculate_combat_strength

```gdscript
func calculate_combat_strength(
    units: Array[Unit],
    terrain: Tile,
    is_attacker: bool
) -> float
```

**Description**: Calculates total combat strength for a group of units.

**Formula**:
```
strength = 0
for each unit:
    base_stat = unit.attack if is_attacker else unit.defense
    hp_factor = unit.current_hp / unit.max_hp
    morale_factor = unit.morale / 100.0
    terrain_mod = get_terrain_modifier(unit, terrain, is_attacker)

    strength += base_stat * hp_factor * morale_factor * terrain_mod
```

**Parameters**:
- `units`: Array of units to evaluate
- `terrain`: Terrain providing modifiers
- `is_attacker`: True for attacking force, False for defending

**Returns**: Float representing total combat strength

**Performance**: < 10ms for up to 20 units

---

#### apply_casualties

```gdscript
func apply_casualties(
    units: Array[Unit],
    casualty_percentage: float,
    outcome: CombatResult.CombatOutcome
) -> Array[Unit]
```

**Description**: Applies casualties to units based on combat outcome.

**Casualty Table**:
- Decisive Victory (winner): 10% casualties
- Decisive Victory (loser): 60-80% casualties
- Victory (winner): 25% casualties
- Victory (loser): 50% casualties
- Stalemate: 30% casualties both sides

**Parameters**:
- `units`: Units to apply casualties to
- `casualty_percentage`: Base casualty rate (0.0-1.0)
- `outcome`: Combat outcome affecting distribution

**Returns**: Array of units that were destroyed/heavily damaged

**Side Effects**:
- Reduces unit HP
- May destroy units (HP <= 0)
- Triggers death events

**Performance**: < 5ms per unit

---

### CombatModifiers

Calculates and combines all combat modifiers.

#### get_combat_modifiers

```gdscript
func get_combat_modifiers(
    attacker: Unit,
    defender: Unit,
    terrain: Tile,
    context: Dictionary = {}
) -> CombatModifiers
```

**Description**: Calculates all combat modifiers for a specific engagement.

**Parameters**:
- `attacker`: Attacking unit
- `defender`: Defending unit
- `terrain`: Terrain tile
- `context`: Optional context {elevation_diff: int, is_flanking: bool, weather: String, etc.}

**Returns**: `CombatModifiers` object with all modifiers applied

**Modifier Sources**:
- Terrain type (rubble, building, street, etc.)
- Cover (light +5 def, heavy +10 def, fortification +15 def)
- Elevation (+25% atk higher, -15% atk lower)
- Flanking (+15% atk if flanking)
- Cultural bonuses (varies by culture)
- Unit experience (Veteran +10%, Elite +20%, Legendary +30%)
- Supply status (-50% if unsupplied)
- Morale (High +10% atk, Low -10% atk)

**Performance**: < 5ms

**Example**:
```gdscript
var context = {
    "elevation_diff": 1,  # Attacker 1 level higher
    "is_flanking": true,
    "has_supply": true
}
var mods = CombatModifiers.get_combat_modifiers(my_unit, enemy_unit, tile, context)
print("Total attack multiplier: ", mods.total_attack_multiplier)
```

---

#### get_terrain_modifier

```gdscript
func get_terrain_modifier(
    unit: Unit,
    terrain: Tile,
    is_attacker: bool
) -> float
```

**Description**: Gets terrain-specific modifier for a unit.

**Terrain Modifiers**:
- Open ground: 1.0x (neutral)
- Rubble: 0.9x movement, +5 def (light cover)
- Buildings: +10 def (heavy cover) for defenders
- Street: 1.0x (neutral)
- Elevated: +25% attack if attacker higher
- Underground: Limited sightlines, no elevation

**Parameters**:
- `unit`: Unit being evaluated
- `terrain`: Terrain tile
- `is_attacker`: True if attacking, False if defending

**Returns**: Float multiplier (typically 0.75 - 1.25)

**Performance**: < 1ms

---

#### get_cover_bonus

```gdscript
func get_cover_bonus(terrain: Tile, is_defending: bool) -> int
```

**Description**: Calculates defense bonus from cover.

**Cover Types**:
- No cover: +0 defense
- Light cover (rubble, cars): +5 defense
- Heavy cover (buildings, walls): +10 defense
- Fortifications: +15 defense

**Parameters**:
- `terrain`: Terrain tile
- `is_defending`: Only defenders get cover bonus

**Returns**: Integer defense bonus (0-15)

**Performance**: < 1ms

---

### MoraleSystem

Handles morale checks, morale damage, and retreat logic.

#### apply_morale_check

```gdscript
func apply_morale_check(
    unit: Unit,
    trigger: String,
    morale_damage: int = 0
) -> MoraleCheckResult
```

**Description**: Performs morale check on a unit and determines if it retreats.

**Morale Check Triggers**:
- `"hp_critical"`: Unit lost 50%+ HP
- `"ally_killed"`: Friendly unit destroyed nearby (within 5 tiles)
- `"outnumbered"`: Outnumbered 3:1 or more
- `"leader_killed"`: Leader/hero unit destroyed
- `"combat_loss"`: Lost combat engagement
- `"combat_victory"`: Won combat engagement (morale gain)

**Morale Thresholds**:
- 80-100: High morale (+10% attack)
- 30-79: Normal morale (no effect)
- 10-29: Low morale (-10% attack, may retreat)
- 0-9: Broken morale (auto-retreat)

**Parameters**:
- `unit`: Unit to check morale
- `trigger`: Reason for morale check
- `morale_damage`: Base morale damage to apply (before modifiers)

**Returns**: `MoraleCheckResult` with state and retreat decision

**Side Effects**:
- Updates unit.morale
- May trigger retreat
- Emits `EventBus.unit_morale_changed`
- Emits `EventBus.unit_retreated` if retreating

**Performance**: < 2ms per unit

**Example**:
```gdscript
var result = MoraleSystem.apply_morale_check(unit, "ally_killed", 15)
if result.will_retreat:
    print("Unit is retreating to: ", result.retreat_direction)
```

---

#### calculate_morale_damage

```gdscript
func calculate_morale_damage(
    unit: Unit,
    trigger: String,
    context: Dictionary = {}
) -> int
```

**Description**: Calculates morale damage based on trigger and context.

**Morale Damage by Trigger**:
- `hp_critical`: 20 morale
- `ally_killed`: 10 morale
- `outnumbered`: 15 morale
- `leader_killed`: 25 morale
- `combat_loss`: 20 morale
- `siege_attrition`: 10 morale per turn

**Morale Modifiers**:
- High unit experience: -25% morale damage
- Cultural traits: varies (-50% to +50%)
- Leadership bonuses: -30% morale damage
- Berserkers/fanatics: Immune to morale loss

**Parameters**:
- `unit`: Unit receiving morale damage
- `trigger`: Reason for morale loss
- `context`: Additional context {leader_present: bool, etc.}

**Returns**: Integer morale damage (0-50)

**Performance**: < 1ms

---

#### process_retreat

```gdscript
func process_retreat(
    unit: Unit,
    current_location: Vector3i
) -> Vector3i
```

**Description**: Handles unit retreat, finding safe direction and moving unit.

**Retreat Logic**:
1. Find direction toward nearest friendly territory
2. Move up to half movement speed
3. Take opportunity attacks from adjacent enemies
4. If no escape route, unit surrenders/destroyed

**Parameters**:
- `unit`: Unit that is retreating
- `current_location`: Current position

**Returns**: New position after retreat (or current position if trapped)

**Side Effects**:
- Moves unit on map
- May trigger opportunity attacks
- Emits `EventBus.unit_retreated`
- May destroy unit if no escape

**Performance**: < 10ms

---

#### restore_morale

```gdscript
func restore_morale(
    unit: Unit,
    amount: int,
    reason: String = "rest"
) -> void
```

**Description**: Restores morale to a unit.

**Morale Restoration Sources**:
- Rest in friendly territory: +10 per turn
- Victory: +20
- Rally: +15
- Propaganda building: +5 per turn
- Hero/leader presence: +10

**Parameters**:
- `unit`: Unit to restore morale
- `amount`: Morale to restore
- `reason`: Source of morale restoration

**Returns**: void

**Side Effects**:
- Updates unit.morale (capped at 100)
- Emits `EventBus.unit_morale_restored`

**Performance**: < 1ms

---

### LootCalculator

Calculates and distributes loot after combat.

#### calculate_loot

```gdscript
func calculate_loot(
    defeated_units: Array[Unit],
    victor_faction: int,
    victor_units: Array[Unit]
) -> Dictionary
```

**Description**: Calculates resources looted from defeated units.

**Loot Formula**:
```
Base loot per unit:
- Scrap: unit_cost * 0.3
- Ammunition: unit_ammo * 0.5
- Components: unit_components * 0.4
- Equipment: random chance for special items

Modifiers:
- Scavenger units: +50% loot
- Raider culture: +25% loot
- Complete destruction: -30% loot
```

**Parameters**:
- `defeated_units`: Units that were defeated
- `victor_faction`: Faction ID that won
- `victor_units`: Winning units (for scavenger bonus)

**Returns**: Dictionary of resources:
```gdscript
{
    "scrap": int,
    "food": int,
    "medicine": int,
    "ammunition": int,
    "fuel": int,
    "components": int,
    "special_items": Array[String]
}
```

**Side Effects**:
- Emits `EventBus.loot_collected`

**Performance**: < 5ms

**Example**:
```gdscript
var loot = LootCalculator.calculate_loot(enemy_casualties, my_faction_id, my_units)
ResourceManager.add_resources(my_faction_id, loot)
```

---

#### distribute_experience

```gdscript
func distribute_experience(
    units: Array[Unit],
    combat_result: CombatResult
) -> Dictionary
```

**Description**: Calculates and distributes experience to units after combat.

**Experience Awards**:
- Kill enemy unit: +50 XP
- Survive battle: +10 XP
- Victory: +20 XP
- Defeat: +5 XP (learning from mistakes)

**Promotion Thresholds**:
- Rookie (0-99 XP): Base stats
- Veteran (100-249 XP): +10% attack/defense
- Elite (250-499 XP): +20% attack/defense, +1 ability slot
- Legendary (500+ XP): +30% attack/defense, +2 ability slots

**Parameters**:
- `units`: Units that participated in combat
- `combat_result`: Combat result for context

**Returns**: Dictionary mapping unit_id to XP gained: `{unit_id: xp_amount}`

**Side Effects**:
- Updates unit experience
- May trigger promotion
- Emits `EventBus.unit_gained_experience`
- Emits `EventBus.unit_promoted` on promotion

**Performance**: < 3ms per unit

---

## Events (EventBus Signals)

All combat-related events emitted through the central EventBus.

### combat_started

```gdscript
signal combat_started(attackers: Array[Unit], defenders: Array[Unit], location: Vector3i)
```

**Description**: Emitted when combat is initiated (before resolution).

**Parameters**:
- `attackers`: Attacking units
- `defenders`: Defending units
- `location`: Combat location

**Listeners**: UI, AI, Stats tracking

---

### combat_resolved

```gdscript
signal combat_resolved(result: CombatResult)
```

**Description**: Emitted when combat is fully resolved.

**Parameters**:
- `result`: Complete combat result

**Listeners**: UI, Game Manager, Faction State, AI

---

### unit_morale_changed

```gdscript
signal unit_morale_changed(unit_id: String, old_morale: int, new_morale: int, reason: String)
```

**Description**: Emitted when unit morale changes.

**Parameters**:
- `unit_id`: Unit ID
- `old_morale`: Previous morale value
- `new_morale`: New morale value
- `reason`: Reason for change

**Listeners**: UI, Unit Manager, AI

---

### unit_retreated

```gdscript
signal unit_retreated(unit_id: String, from_location: Vector3i, to_location: Vector3i, morale_broken: bool)
```

**Description**: Emitted when a unit retreats from combat.

**Parameters**:
- `unit_id`: Unit ID
- `from_location`: Retreat origin
- `to_location`: Retreat destination
- `morale_broken`: True if morale caused retreat

**Listeners**: UI, Map, Unit Manager, AI

---

### loot_collected

```gdscript
signal loot_collected(faction_id: int, resources: Dictionary, location: Vector3i)
```

**Description**: Emitted when loot is collected after combat.

**Parameters**:
- `faction_id`: Faction collecting loot
- `resources`: Dictionary of resources collected
- `location`: Where loot was collected

**Listeners**: Economy System, UI, Stats

---

### unit_gained_experience

```gdscript
signal unit_gained_experience(unit_id: String, xp_gained: int, new_total: int)
```

**Description**: Emitted when unit gains experience.

**Parameters**:
- `unit_id`: Unit ID
- `xp_gained`: XP gained this time
- `new_total`: New total XP

**Listeners**: UI, Unit Manager

---

### unit_promoted

```gdscript
signal unit_promoted(unit_id: String, old_rank: String, new_rank: String)
```

**Description**: Emitted when unit is promoted to new rank.

**Parameters**:
- `unit_id`: Unit ID
- `old_rank`: Previous rank
- `new_rank`: New rank

**Listeners**: UI, Unit Manager, Game Manager

---

### tactical_combat_started

```gdscript
signal tactical_combat_started(battle_id: String, attackers: Array[Unit], defenders: Array[Unit])
```

**Description**: Emitted when tactical combat mode is entered.

**Parameters**:
- `battle_id`: Unique battle identifier
- `attackers`: Attacking units
- `defenders`: Defending units

**Listeners**: UI (to switch to tactical view)

**Note**: Stub for MVP - immediately followed by auto-resolve

---

### tactical_combat_ended

```gdscript
signal tactical_combat_ended(battle_id: String, result: CombatResult)
```

**Description**: Emitted when tactical combat ends.

**Parameters**:
- `battle_id`: Battle identifier
- `result`: Combat result

**Listeners**: UI (to return to strategic view), Game Manager

---

## Error Handling

### Error Conditions

**Invalid Unit State**:
- Units with HP <= 0 are excluded from combat
- Units without position are excluded
- Logged as warning, combat continues

**Empty Combat**:
- If either side has 0 valid units, combat immediately resolves as surrender
- Returns appropriate decisive victory result

**Invalid Location**:
- Out of bounds locations use default terrain (open ground)
- Logged as warning

**Calculation Overflow**:
- All strength calculations clamped to safe ranges
- Float values clamped to 0.0 - 999999.0
- Integer values clamped to 0 - 999999

### Error Recovery

All public functions are null-safe and will:
1. Validate inputs
2. Log warnings for invalid data
3. Use safe defaults
4. Continue execution when possible
5. Return valid (possibly empty) results

---

## Performance Requirements

### Benchmarks (Target)

- **Auto-resolve combat** (10 units/side): < 100ms
- **Damage calculation** (single attack): < 1ms
- **Combat strength calculation** (20 units): < 10ms
- **Morale check** (single unit): < 2ms
- **Loot calculation** (10 defeated units): < 5ms
- **Experience distribution** (20 units): < 60ms

### Optimization Strategies

1. **Pre-calculated Modifiers**: Cache culture and terrain modifiers
2. **Batch Processing**: Process multiple units in single pass
3. **Early Exit**: Skip calculations for guaranteed outcomes
4. **Object Pooling**: Reuse CombatResult and modifier objects
5. **Lazy Evaluation**: Only calculate detailed stats when needed

---

## Testing Requirements

### Unit Tests (Target: 95% Coverage)

**CombatResolver Tests**:
- ✓ Test auto-resolve with various strength ratios
- ✓ Test decisive victory conditions
- ✓ Test stalemate conditions
- ✓ Test casualty application
- ✓ Test loot distribution
- ✓ Test experience awards
- ✓ Test empty unit arrays
- ✓ Test combat prediction accuracy

**CombatCalculator Tests**:
- ✓ Test damage formula with various modifiers
- ✓ Test minimum damage enforcement
- ✓ Test damage variance (±15%)
- ✓ Test strength calculations
- ✓ Test casualty percentages
- ✓ Test armor calculations
- ✓ Test edge cases (0 attack, 0 defense)

**CombatModifiers Tests**:
- ✓ Test terrain modifiers
- ✓ Test elevation bonuses
- ✓ Test cover bonuses
- ✓ Test cultural bonuses
- ✓ Test modifier stacking
- ✓ Test context-specific modifiers

**MoraleSystem Tests**:
- ✓ Test morale checks for each trigger
- ✓ Test morale thresholds
- ✓ Test retreat logic
- ✓ Test morale restoration
- ✓ Test morale immunity (Berserkers)
- ✓ Test rally mechanics
- ✓ Test opportunity attacks during retreat

**LootCalculator Tests**:
- ✓ Test base loot calculation
- ✓ Test scavenger bonus
- ✓ Test raider culture bonus
- ✓ Test complete destruction penalty
- ✓ Test experience distribution
- ✓ Test promotion triggers

### Integration Tests

- ✓ Full combat flow (start → resolve → loot → XP)
- ✓ Combat with morale breaks
- ✓ Combat with retreats
- ✓ Combat with promotions
- ✓ Multiple sequential combats
- ✓ Event emission verification

### Mock Dependencies

For testing in isolation:
- **Mock Unit**: Simplified unit with stats
- **Mock Tile**: Terrain with basic modifiers
- **Mock MapData**: Spatial queries return predefined data
- **Mock EventBus**: Capture emitted signals

---

## Usage Examples

### Example 1: Simple Auto-Resolve Combat

```gdscript
# Setup
var my_soldiers = [create_unit("Soldier"), create_unit("Soldier")]
var enemy_militia = [create_unit("Militia"), create_unit("Militia")]
var location = Vector3i(50, 50, 1)
var tile = MapData.get_tile(location)

# Predict outcome first (for UI)
var prediction = CombatResolver.predict_combat_outcome(my_soldiers, enemy_militia, location)
print("Predicted outcome: ", prediction.outcome)
print("Our strength: ", prediction.attacker_strength)
print("Their strength: ", prediction.defender_strength)

# Resolve combat
var result = CombatResolver.resolve_combat(my_soldiers, enemy_militia, location, tile)

# Handle result
if result.outcome in [CombatResult.CombatOutcome.ATTACKER_VICTORY,
                      CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY]:
    print("Victory! Gained loot: ", result.loot)
    ResourceManager.add_resources(my_faction_id, result.loot)

    # Check for promotions
    for unit in result.attacker_survivors:
        if unit.experience >= 100 and unit.rank == "Rookie":
            print(unit.id, " promoted to Veteran!")
else:
    print("Defeat! Retreating...")
```

### Example 2: Combat with Modifiers

```gdscript
# Get terrain and context
var tile = MapData.get_tile(combat_location)
var elevation_diff = attacker_tile.position.z - defender_tile.position.z

var context = {
    "elevation_diff": elevation_diff,
    "is_flanking": check_flanking(attacker, defender),
    "has_supply": check_supply_line(attacker),
    "weather": "clear"
}

# Calculate modifiers
var mods = CombatModifiers.get_combat_modifiers(attacker, defender, tile, context)

# Preview in UI
print("Attack multiplier: x", mods.total_attack_multiplier)
print("Defense bonus: +", mods.total_defense_bonus)
print("Cover: +", mods.cover_bonus, " defense")

# Apply in combat
var damage = CombatCalculator.calculate_damage(attacker, defender, mods)
defender.current_hp -= damage
```

### Example 3: Morale Check After Heavy Casualties

```gdscript
func on_unit_damaged(unit: Unit, damage: int):
    unit.current_hp -= damage

    # Check if HP critical
    if unit.current_hp <= unit.max_hp * 0.5:
        var morale_result = MoraleSystem.apply_morale_check(unit, "hp_critical")

        if morale_result.will_retreat:
            print(unit.id, " is retreating due to low morale!")
            var new_pos = MoraleSystem.process_retreat(unit, unit.position)
            UnitManager.move_unit(unit.id, new_pos)
        elif morale_result.state == MoraleCheckResult.MoraleState.SHAKEN:
            show_morale_warning(unit)
```

### Example 4: Calculating Loot After Victory

```gdscript
func on_combat_resolved(result: CombatResult):
    if result.outcome in [CombatResult.CombatOutcome.ATTACKER_VICTORY,
                          CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY]:
        # Calculate loot
        var loot = LootCalculator.calculate_loot(
            result.defender_casualties,
            player_faction_id,
            result.attacker_survivors
        )

        # Add to faction stockpile
        ResourceManager.add_resources(player_faction_id, loot)

        # Show loot UI
        show_loot_notification(loot)

        # Distribute experience
        var xp_table = LootCalculator.distribute_experience(
            result.attacker_survivors,
            result
        )

        for unit_id in xp_table:
            var unit = UnitManager.get_unit(unit_id)
            unit.experience += xp_table[unit_id]
            check_for_promotion(unit)
```

---

## Future Enhancements (Post-MVP)

The following features are designed into the interface but stubbed for MVP:

1. **Tactical Combat Mode**: Full turn-based tactical battles
2. **Weather System**: Rain, fog, sandstorms affecting combat
3. **Special Abilities**: Unit-specific active abilities
4. **Formation System**: Unit formations affecting combat
5. **Siege Mechanics**: Extended siege warfare
6. **Environmental Destruction**: Building collapse, fire spread
7. **Reinforcements**: Mid-combat reinforcements
8. **Commander Abilities**: Leader units with special powers
9. **Ambush System**: Stealth-based ambush mechanics
10. **Vehicle Combat**: Special rules for vehicle vs infantry

---

## Dependencies on Other Modules

### Core Foundation (Layer 1)

**Required**:
- `EventBus`: All combat events
- `GameState`: Read current game state
- `DataLoader`: Load unit and combat data

**Functions Used**:
- `EventBus.emit_signal(signal_name, ...args)`
- `GameState.get_faction(faction_id)`
- `DataLoader.get_unit_data(unit_type)`

### Map System (Layer 2)

**Required**:
- `MapData`: Query terrain and tiles
- `Tile`: Terrain modifiers

**Functions Used**:
- `MapData.get_tile(position)` → Tile
- `MapData.get_tiles_in_radius(center, radius)` → Array[Tile]
- `Tile.get_terrain_type()` → TerrainType
- `Tile.get_cover_type()` → CoverType

### Unit System (Layer 2)

**Required**:
- `Unit`: Unit stats and state
- `UnitManager`: Query and update units

**Functions Used**:
- `Unit.get_stats()` → UnitStats
- `Unit.take_damage(amount)` → void
- `Unit.add_experience(amount)` → void
- `UnitManager.destroy_unit(unit_id)` → void
- `UnitManager.get_unit(unit_id)` → Unit

---

## Notes

- All combat calculations are deterministic given the same seed
- Random variance uses seeded RNG for replay capability
- Combat results are serializable for save/load
- All float calculations use consistent rounding (round half up)
- Morale system designed for future AI personality integration
- Tactical combat hook points in place for post-MVP implementation

---

## Version History

| Version | Date       | Changes                              |
|---------|------------|--------------------------------------|
| 1.0     | 2025-11-12 | Initial interface contract           |

---

**Document Status**: ✅ Ready for Implementation
**Review Status**: Pending
**Implementation Status**: Not Started
