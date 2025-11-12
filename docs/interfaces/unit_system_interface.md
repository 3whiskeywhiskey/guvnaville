# Unit System Interface Contract

**Module**: Unit System (`systems/units/`)
**Agent**: Agent 3
**Layer**: 2 (Depends on Core and Map)
**Version**: 1.0
**Date**: 2025-11-12

---

## Overview

The Unit System manages all military and civilian units in the game, including their lifecycle, stats, movement, abilities, and progression. It provides a comprehensive framework for unit creation, management, and interaction with the game world.

### Responsibilities

1. **Unit Management**: Creation, tracking, and destruction of all game units
2. **Unit Stats**: HP, morale, experience, ranks, and stat calculations
3. **Movement System**: Unit movement with terrain costs and pathfinding integration
4. **Ability Framework**: Extensible ability system for unit special actions
5. **Experience/Promotion**: Unit progression through combat and actions
6. **Status Effects**: Manage buffs, debuffs, and temporary conditions
7. **Equipment System**: Unit loadouts and equipment management

---

## Module Structure

```
systems/units/
├── unit.gd                # Core Unit class
├── unit_manager.gd        # Unit lifecycle and registry
├── unit_factory.gd        # Create units from JSON data
├── movement.gd            # Movement system and validation
├── unit_stats.gd          # Stats calculations and modifiers
├── experience_system.gd   # XP and promotion logic
├── equipment.gd           # Equipment management
└── abilities/             # Unit abilities
    ├── ability_base.gd    # Abstract ability base class
    ├── entrench.gd        # Defensive fortification
    ├── overwatch.gd       # Reaction fire ability
    ├── heal.gd            # Medical healing ability
    ├── scout.gd           # Enhanced vision ability
    └── suppress.gd        # Suppression fire ability
```

---

## Dependencies

### Required Dependencies
- **Core System** (`core/autoload/`): EventBus, GameState, DataLoader
- **Map System** (`systems/map/`): MapData, Tile, pathfinding queries

### Optional Dependencies
- **Combat System**: For damage application (loosely coupled via events)
- **Economy System**: For unit costs and upkeep

---

## Public Classes

### Unit Class

The core unit data structure representing a single military or civilian unit.

```gdscript
class_name Unit
extends Resource

# Core Properties
var id: int                          # Unique unit identifier
var type: String                     # Unit type (e.g., "militia", "soldier")
var faction_id: int                  # Owning faction ID
var position: Vector3i               # Current position on map
var stats: UnitStats                 # Unit statistics object

# Combat Stats
var current_hp: int                  # Current hit points
var max_hp: int                      # Maximum hit points
var morale: int                      # Current morale (0-100)
var armor: int                       # Armor value

# Progression
var experience: int                  # Total experience points
var rank: UnitRank                   # Current rank (enum)
var level: int                       # Unit level (1-10)

# Abilities and Equipment
var abilities: Array[Ability]        # Available special abilities
var equipment: Array[Equipment]      # Equipped items
var status_effects: Array[StatusEffect]  # Active status effects

# Turn State
var movement_remaining: int          # Movement points left this turn
var actions_remaining: int           # Action points left this turn
var has_moved: bool                  # Moved this turn?
var has_attacked: bool               # Attacked this turn?

# Metadata
var name: String                     # Unit name (e.g., "1st Militia Squad")
var created_turn: int                # Turn unit was created
var kills: int                       # Enemy units killed
var battles_fought: int              # Number of battles participated in

# Methods
func to_dict() -> Dictionary         # Serialize to dictionary
func from_dict(data: Dictionary) -> void  # Deserialize from dictionary
func can_act() -> bool               # Can perform actions this turn?
func reset_turn_state() -> void      # Reset for new turn
```

### UnitStats Class

Represents unit combat and movement statistics.

```gdscript
class_name UnitStats
extends Resource

# Combat Stats
var attack: int                      # Attack power (base)
var defense: int                     # Defense value (base)
var range: int                       # Attack range (tiles)
var armor: int                       # Armor value
var stealth: int                     # Stealth rating (0-100)
var detection: int                   # Detection radius

# Movement Stats
var movement: int                    # Movement points per turn
var movement_type: MovementType      # Infantry, Wheeled, Tracked, etc.

# Special Stats
var morale_base: int                 # Base morale (affected by rank)
var supply_cost: int                 # Resource consumption per turn
var vision_range: int                # Sight range in tiles

# Calculated Properties
func get_effective_attack() -> int   # Attack with modifiers
func get_effective_defense() -> int  # Defense with modifiers
func get_effective_movement() -> int # Movement with modifiers
```

### UnitRank Enum

```gdscript
enum UnitRank {
    ROOKIE,          # 0-99 XP
    TRAINED,         # 100-299 XP
    VETERAN,         # 300-699 XP
    ELITE,           # 700-1499 XP
    LEGENDARY        # 1500+ XP
}
```

### MovementType Enum

```gdscript
enum MovementType {
    INFANTRY,        # Standard foot movement
    WHEELED,         # Wheeled vehicles (streets preferred)
    TRACKED,         # Tracked vehicles (all-terrain)
    AIRBORNE,        # Helicopter/aircraft (future expansion)
}
```

### Ability Base Class

```gdscript
class_name Ability
extends Resource

var id: String                       # Unique ability ID
var name: String                     # Display name
var description: String              # Tooltip description
var icon: Texture2D                  # Ability icon
var cooldown: int                    # Turns between uses
var current_cooldown: int            # Current cooldown counter
var cost_type: CostType              # What it costs to use
var cost_amount: int                 # Cost value
var range: int                       # Ability range (-1 = self only)
var target_type: TargetType          # What can be targeted

# Abstract methods (must override)
func can_use(unit: Unit, target) -> bool:
    return false

func execute(unit: Unit, target) -> bool:
    return false

func get_valid_targets(unit: Unit) -> Array:
    return []
```

### StatusEffect Class

```gdscript
class_name StatusEffect
extends Resource

var id: String                       # Effect ID
var name: String                     # Display name
var duration: int                    # Turns remaining
var stat_modifiers: Dictionary       # Stat changes
var is_buff: bool                    # Buff or debuff?
var icon: Texture2D                  # Status icon
var stacks: int                      # Number of stacks (if stackable)

func apply_to_unit(unit: Unit) -> void
func remove_from_unit(unit: Unit) -> void
func tick() -> void                  # Called each turn
```

---

## Public Functions

### UnitManager Core Functions

```gdscript
class_name UnitManager
extends Node

# Unit Creation
func create_unit(
    unit_type: String,
    faction_id: int,
    position: Vector3i,
    customization: Dictionary = {}
) -> Unit:
    """
    Creates a new unit of the specified type.

    Parameters:
        unit_type: Type identifier from unit data (e.g., "militia", "soldier")
        faction_id: ID of owning faction
        position: Initial position on map
        customization: Optional stat overrides and customization

    Returns:
        Newly created Unit instance

    Emits:
        unit_created(unit_id, unit_type, position, faction_id)

    Errors:
        - Returns null if unit_type not found in data
        - Returns null if position is invalid/occupied
        - Returns null if faction_id is invalid
    """

func destroy_unit(unit_id: int, cause: String = "") -> void:
    """
    Removes unit from game and emits death event.

    Parameters:
        unit_id: ID of unit to destroy
        cause: Optional death cause (e.g., "combat", "starvation")

    Emits:
        unit_died(unit_id, position, faction_id, cause)

    Errors:
        - Warns if unit_id not found (gracefully fails)
    """

# Unit Queries
func get_unit(unit_id: int) -> Unit:
    """
    Retrieves unit by ID.

    Parameters:
        unit_id: Unique unit identifier

    Returns:
        Unit instance or null if not found

    Performance:
        O(1) - Hash table lookup
    """

func get_units_at_position(position: Vector3i) -> Array[Unit]:
    """
    Gets all units at a specific tile.

    Parameters:
        position: Map position to query

    Returns:
        Array of units at position (empty if none)

    Performance:
        O(1) - Spatial hash lookup
    """

func get_units_by_faction(faction_id: int) -> Array[Unit]:
    """
    Gets all units belonging to a faction.

    Parameters:
        faction_id: Faction to query

    Returns:
        Array of faction's units (empty if none)

    Performance:
        O(1) - Faction index lookup
    """

func get_units_in_radius(
    center: Vector3i,
    radius: int,
    faction_id: int = -1
) -> Array[Unit]:
    """
    Gets units within radius of center position.

    Parameters:
        center: Center position
        radius: Search radius in tiles
        faction_id: Optional faction filter (-1 = all factions)

    Returns:
        Array of units in range

    Performance:
        O(n) where n = units in radius
    """

func get_all_units() -> Array[Unit]:
    """
    Gets all active units in game.

    Returns:
        Array of all units

    Performance:
        O(1) - Returns reference to main array
    """

func unit_exists(unit_id: int) -> bool:
    """
    Checks if unit with given ID exists.

    Parameters:
        unit_id: Unit ID to check

    Returns:
        true if unit exists, false otherwise
    """

# Unit Modification
func damage_unit(unit_id: int, damage: int, source: String = "") -> void:
    """
    Applies damage to a unit.

    Parameters:
        unit_id: Target unit ID
        damage: Damage amount (positive integer)
        source: Optional damage source for events

    Emits:
        unit_damaged(unit_id, damage, remaining_hp)
        unit_died(unit_id, position, faction_id) if HP reaches 0

    Notes:
        - Minimum damage: 0 (no negative damage)
        - Triggers death at HP <= 0
        - Damage reduction from armor handled by caller
    """

func heal_unit(unit_id: int, amount: int, source: String = "") -> void:
    """
    Heals a unit.

    Parameters:
        unit_id: Target unit ID
        amount: Heal amount (positive integer)
        source: Optional heal source for events

    Emits:
        unit_healed(unit_id, amount, new_hp)

    Notes:
        - Cannot exceed max_hp
        - Minimum heal: 0
    """

func modify_morale(unit_id: int, delta: int, reason: String = "") -> void:
    """
    Changes unit morale.

    Parameters:
        unit_id: Target unit ID
        delta: Morale change (positive or negative)
        reason: Optional reason for logging

    Emits:
        unit_morale_changed(unit_id, old_morale, new_morale)
        unit_routed(unit_id) if morale reaches 0

    Notes:
        - Morale clamped to 0-100
        - Routing occurs at morale <= 0
    """

func add_experience(unit_id: int, xp: int, source: String = "") -> void:
    """
    Awards experience to unit and handles promotions.

    Parameters:
        unit_id: Target unit ID
        xp: Experience points to award
        source: Optional XP source (e.g., "combat", "mission")

    Emits:
        unit_gained_xp(unit_id, xp, total_xp)
        unit_promoted(unit_id, old_rank, new_rank) if rank increases

    Notes:
        - Checks for rank promotion automatically
        - XP thresholds: Rookie=0, Trained=100, Veteran=300, Elite=700, Legendary=1500
    """

func set_position(unit_id: int, new_position: Vector3i) -> bool:
    """
    Directly sets unit position (no movement validation).

    Parameters:
        unit_id: Unit to move
        new_position: New map position

    Returns:
        true if successful, false if position invalid

    Emits:
        unit_teleported(unit_id, old_position, new_position)

    Notes:
        - Does not consume movement points
        - Used for special abilities, events, etc.
        - Does not validate terrain passability
    """

# Status Effects
func add_status_effect(
    unit_id: int,
    effect: StatusEffect
) -> void:
    """
    Applies a status effect to unit.

    Parameters:
        unit_id: Target unit
        effect: StatusEffect to apply

    Emits:
        unit_status_applied(unit_id, effect_id)

    Notes:
        - Handles stacking if effect is stackable
        - Replaces effect if non-stackable
    """

func remove_status_effect(
    unit_id: int,
    effect_id: String
) -> void:
    """
    Removes a status effect from unit.

    Parameters:
        unit_id: Target unit
        effect_id: Effect ID to remove

    Emits:
        unit_status_removed(unit_id, effect_id)
    """

func tick_status_effects(unit_id: int) -> void:
    """
    Updates status effects for one turn.

    Parameters:
        unit_id: Unit to update

    Notes:
        - Called by turn manager each turn
        - Decrements durations and removes expired effects
    """
```

### Movement System Functions

```gdscript
class_name MovementSystem
extends Node

func move_unit(
    unit_id: int,
    target_position: Vector3i
) -> bool:
    """
    Moves unit along pathfound route to target.

    Parameters:
        unit_id: Unit to move
        target_position: Destination tile

    Returns:
        true if move successful, false otherwise

    Emits:
        unit_moved(unit_id, old_position, new_position)
        unit_move_failed(unit_id, target_position, reason)

    Errors:
        - Returns false if no path exists
        - Returns false if insufficient movement points
        - Returns false if target occupied by enemy
        - Returns false if unit cannot move (status effect)

    Notes:
        - Consumes movement points based on terrain
        - Updates fog of war along path
        - May trigger zone of control effects
    """

func can_move_to(
    unit_id: int,
    target_position: Vector3i
) -> bool:
    """
    Checks if unit can move to target position.

    Parameters:
        unit_id: Unit to check
        target_position: Destination to validate

    Returns:
        true if move is valid, false otherwise

    Notes:
        - Checks pathing, movement points, and terrain
        - Does not modify unit state
        - Fast validation for UI feedback
    """

func get_movement_cost(
    unit: Unit,
    from: Vector3i,
    to: Vector3i
) -> int:
    """
    Calculates movement cost between adjacent tiles.

    Parameters:
        unit: Unit attempting movement
        from: Starting position
        to: Destination position

    Returns:
        Movement point cost (0 = impassable)

    Notes:
        - Considers terrain type
        - Considers unit movement type
        - Considers status effects
        - Only works for adjacent tiles
    """

func get_reachable_tiles(unit_id: int) -> Array[Vector3i]:
    """
    Gets all tiles unit can reach this turn.

    Parameters:
        unit_id: Unit to query

    Returns:
        Array of reachable positions

    Performance:
        O(n) where n = tiles in movement range

    Notes:
        - Considers current movement remaining
        - Used for movement preview UI
        - Caches result until unit moves
    """

func reset_movement(unit_id: int) -> void:
    """
    Resets unit's movement points to maximum.

    Parameters:
        unit_id: Unit to reset

    Notes:
        - Called by turn manager at turn start
        - Clears movement cache
    """
```

### Ability System Functions

```gdscript
class_name AbilitySystem
extends Node

func use_ability(
    unit_id: int,
    ability_name: String,
    target
) -> bool:
    """
    Executes a unit's ability on target.

    Parameters:
        unit_id: Unit using ability
        ability_name: Name of ability to use
        target: Target (Unit, Vector3i, or null for self-target)

    Returns:
        true if ability executed successfully

    Emits:
        ability_used(unit_id, ability_name, target)
        ability_failed(unit_id, ability_name, reason)

    Errors:
        - Returns false if ability not found
        - Returns false if ability on cooldown
        - Returns false if invalid target
        - Returns false if insufficient resources

    Notes:
        - Triggers cooldown on successful use
        - May consume action points
        - May consume resources (ammo, etc.)
    """

func can_use_ability(
    unit_id: int,
    ability_name: String,
    target
) -> bool:
    """
    Checks if ability can be used on target.

    Parameters:
        unit_id: Unit to check
        ability_name: Ability to validate
        target: Proposed target

    Returns:
        true if ability can be used

    Notes:
        - Checks cooldown, range, resources
        - Does not modify state
        - Fast validation for UI
    """

func get_ability(
    unit_id: int,
    ability_name: String
) -> Ability:
    """
    Gets ability instance from unit.

    Parameters:
        unit_id: Unit to query
        ability_name: Ability identifier

    Returns:
        Ability instance or null if not found
    """

func grant_ability(
    unit_id: int,
    ability: Ability
) -> void:
    """
    Adds ability to unit.

    Parameters:
        unit_id: Target unit
        ability: Ability to grant

    Emits:
        ability_granted(unit_id, ability_name)

    Notes:
        - Used for promotions, equipment, culture bonuses
        - Replaces existing ability with same name
    """

func remove_ability(
    unit_id: int,
    ability_name: String
) -> void:
    """
    Removes ability from unit.

    Parameters:
        unit_id: Target unit
        ability_name: Ability to remove

    Emits:
        ability_removed(unit_id, ability_name)
    """

func update_cooldowns(unit_id: int) -> void:
    """
    Decrements ability cooldowns for unit.

    Parameters:
        unit_id: Unit to update

    Notes:
        - Called by turn manager each turn
        - Emits events when cooldowns complete
    """
```

### Factory Functions

```gdscript
class_name UnitFactory
extends Node

func load_unit_data(data_path: String) -> void:
    """
    Loads unit definitions from JSON file.

    Parameters:
        data_path: Path to unit data JSON

    Notes:
        - Called during game initialization
        - Validates against schema
        - Caches unit templates
    """

func create_from_template(
    template_name: String,
    faction_id: int,
    position: Vector3i,
    overrides: Dictionary = {}
) -> Unit:
    """
    Creates unit from data template.

    Parameters:
        template_name: Unit type from data
        faction_id: Owning faction
        position: Spawn position
        overrides: Custom stat modifications

    Returns:
        Configured Unit instance

    Notes:
        - Applies faction bonuses
        - Applies culture modifiers
        - Generates unique unit ID
    """

func get_unit_template(template_name: String) -> Dictionary:
    """
    Gets raw unit template data.

    Parameters:
        template_name: Unit type identifier

    Returns:
        Template dictionary or empty dict if not found
    """

func get_available_unit_types(faction_id: int) -> Array[String]:
    """
    Gets unit types available to faction.

    Parameters:
        faction_id: Faction to query

    Returns:
        Array of unit type names

    Notes:
        - Considers culture unlocks
        - Considers technology requirements
    """
```

---

## Events

All events are emitted via `EventBus` singleton and follow the naming convention `unit_*`.

### Core Unit Events

```gdscript
# Unit Lifecycle
signal unit_created(unit_id: int, unit_type: String, position: Vector3i, faction_id: int)
signal unit_died(unit_id: int, position: Vector3i, faction_id: int, cause: String)
signal unit_destroyed(unit_id: int)

# Unit State Changes
signal unit_moved(unit_id: int, old_position: Vector3i, new_position: Vector3i)
signal unit_teleported(unit_id: int, old_position: Vector3i, new_position: Vector3i)
signal unit_move_failed(unit_id: int, target_position: Vector3i, reason: String)

# Combat Events
signal unit_damaged(unit_id: int, damage: int, remaining_hp: int)
signal unit_healed(unit_id: int, amount: int, new_hp: int)
signal unit_morale_changed(unit_id: int, old_morale: int, new_morale: int)
signal unit_routed(unit_id: int)

# Progression Events
signal unit_gained_xp(unit_id: int, xp: int, total_xp: int)
signal unit_promoted(unit_id: int, old_rank: UnitRank, new_rank: UnitRank)
signal unit_leveled_up(unit_id: int, new_level: int)

# Ability Events
signal ability_used(unit_id: int, ability_name: String, target)
signal ability_failed(unit_id: int, ability_name: String, reason: String)
signal ability_granted(unit_id: int, ability_name: String)
signal ability_removed(unit_id: int, ability_name: String)
signal ability_cooldown_ready(unit_id: int, ability_name: String)

# Status Effect Events
signal unit_status_applied(unit_id: int, effect_id: String)
signal unit_status_removed(unit_id: int, effect_id: String)
signal unit_status_expired(unit_id: int, effect_id: String)

# Equipment Events
signal unit_equipped_item(unit_id: int, item_id: String)
signal unit_unequipped_item(unit_id: int, item_id: String)

# Turn Events
signal unit_turn_started(unit_id: int)
signal unit_turn_ended(unit_id: int)
signal unit_actions_exhausted(unit_id: int)
```

---

## Data Structures

### Unit Data JSON Schema

```json
{
  "unit_types": [
    {
      "id": "militia",
      "name": "Militia",
      "description": "Basic defensive unit formed from armed civilians",
      "tier": 1,
      "base_stats": {
        "max_hp": 100,
        "attack": 25,
        "defense": 30,
        "armor": 5,
        "range": 1,
        "movement": 3,
        "stealth": 10,
        "detection": 5,
        "vision_range": 5
      },
      "movement_type": "infantry",
      "morale_base": 50,
      "cost": {
        "scrap": 50,
        "ammunition": 20,
        "production_time": 2
      },
      "upkeep": {
        "food": 2,
        "ammunition": 1
      },
      "abilities": [
        "entrench"
      ],
      "requirements": {
        "culture_nodes": [],
        "buildings": []
      },
      "unlock_condition": "default"
    }
  ]
}
```

### Experience Thresholds

```gdscript
const XP_THRESHOLDS = {
    UnitRank.ROOKIE: 0,
    UnitRank.TRAINED: 100,
    UnitRank.VETERAN: 300,
    UnitRank.ELITE: 700,
    UnitRank.LEGENDARY: 1500
}
```

### Rank Bonuses

```gdscript
const RANK_BONUSES = {
    UnitRank.ROOKIE: {
        "stat_multiplier": 1.0,
        "morale_bonus": 0,
        "ability_slots": 2
    },
    UnitRank.TRAINED: {
        "stat_multiplier": 1.1,
        "morale_bonus": 10,
        "ability_slots": 2
    },
    UnitRank.VETERAN: {
        "stat_multiplier": 1.25,
        "morale_bonus": 20,
        "ability_slots": 3
    },
    UnitRank.ELITE: {
        "stat_multiplier": 1.4,
        "morale_bonus": 35,
        "ability_slots": 3
    },
    UnitRank.LEGENDARY: {
        "stat_multiplier": 1.6,
        "morale_bonus": 50,
        "ability_slots": 4
    }
}
```

---

## Core Abilities

### 1. Entrench

```gdscript
class_name EntrenchAbility
extends Ability

# +50% defense, -50% movement until next turn
# Costs: 1 action point
# Cooldown: 0 turns (can use every turn)
# Range: Self
# Target: Self only
```

### 2. Overwatch

```gdscript
class_name OverwatchAbility
extends Ability

# React to enemy movement with free attack
# Costs: 1 action point
# Cooldown: 1 turn
# Range: Attack range
# Target: Self (sets up overwatch mode)
# Duration: Until next turn or attack triggered
```

### 3. Heal

```gdscript
class_name HealAbility
extends Ability

# Restores HP to friendly unit
# Costs: Medicine resource
# Cooldown: 0 turns
# Range: 1 tile (adjacent)
# Target: Friendly unit
# Amount: 30 HP + 10% of target's max HP
```

### 4. Scout

```gdscript
class_name ScoutAbility
extends Ability

# Temporarily increases vision range
# Costs: 1 action point
# Cooldown: 2 turns
# Range: Self
# Target: Self only
# Duration: 2 turns
# Effect: +3 vision range
```

### 5. Suppress

```gdscript
class_name SuppressAbility
extends Ability

# Reduces enemy attack and movement
# Costs: Ammunition
# Cooldown: 0 turns
# Range: Attack range
# Target: Enemy unit
# Duration: 1 turn
# Effect: -50% attack, -50% movement
```

---

## Performance Requirements

### Benchmarks

- **create_unit()**: < 5ms per unit
- **get_unit()**: < 0.1ms (O(1) hash lookup)
- **get_units_at_position()**: < 1ms (O(1) spatial hash)
- **get_units_by_faction()**: < 1ms (O(1) faction index)
- **move_unit()**: < 20ms (includes pathfinding)
- **use_ability()**: < 10ms
- **damage_unit()**: < 1ms
- **add_experience()**: < 2ms

### Scalability

- Support up to 1000 active units simultaneously
- Unit lookups remain O(1) regardless of unit count
- Spatial queries scale with units in query area, not total units
- Memory target: < 1KB per unit

### Optimization Strategies

1. **Spatial Hashing**: Units indexed by tile position
2. **Faction Indexing**: Units indexed by faction_id
3. **Object Pooling**: Reuse unit instances when possible
4. **Lazy Calculation**: Compute effective stats only when needed
5. **Caching**: Cache reachable tiles until unit moves

---

## Error Handling

### Validation Rules

1. **Unit Creation**:
   - Unit type must exist in data
   - Position must be valid and unoccupied
   - Faction must exist
   - If validation fails: return null, log warning

2. **Movement**:
   - Path must exist
   - Sufficient movement points
   - Destination not occupied by enemy
   - If validation fails: return false, emit move_failed event

3. **Abilities**:
   - Ability must exist on unit
   - Not on cooldown
   - Sufficient resources
   - Valid target
   - If validation fails: return false, emit ability_failed event

4. **Damage/Healing**:
   - Unit must exist
   - Amount must be positive
   - If unit not found: warn and return

### Error Logging

All errors logged to `res://logs/units.log` with:
- Timestamp
- Error type
- Context (unit_id, position, etc.)
- Stack trace (if critical)

---

## Testing Specifications

### Unit Tests

```gdscript
# Test Suite: Unit Creation
- test_create_unit_from_template()
- test_create_unit_invalid_type()
- test_create_unit_invalid_position()
- test_create_unit_occupied_position()
- test_unit_serialization_roundtrip()

# Test Suite: Movement
- test_move_unit_valid_path()
- test_move_unit_no_path()
- test_move_unit_insufficient_movement()
- test_move_unit_occupied_destination()
- test_movement_cost_calculation()
- test_get_reachable_tiles()

# Test Suite: Combat
- test_damage_unit()
- test_heal_unit()
- test_unit_death()
- test_morale_modification()
- test_morale_routing()

# Test Suite: Experience
- test_add_experience()
- test_rank_promotion()
- test_rank_bonuses_applied()
- test_multiple_promotions()

# Test Suite: Abilities
- test_use_ability_success()
- test_use_ability_cooldown()
- test_use_ability_invalid_target()
- test_ability_effects_applied()
- test_grant_and_remove_abilities()

# Test Suite: Status Effects
- test_apply_status_effect()
- test_status_effect_duration()
- test_status_effect_stacking()
- test_status_effect_expiration()
```

### Integration Tests

```gdscript
# Test Suite: Unit-Map Integration
- test_unit_movement_with_real_map()
- test_unit_position_updates_fog_of_war()
- test_multiple_units_same_faction()
- test_zone_of_control()

# Test Suite: Unit-Combat Integration
- test_unit_receives_damage_from_combat()
- test_unit_death_triggers_combat_end()
- test_experience_from_combat()

# Test Suite: Full Turn Simulation
- test_unit_turn_reset()
- test_multiple_units_turn_processing()
- test_ability_cooldowns_tick()
- test_status_effects_tick()
```

### Performance Tests

```gdscript
# Test Suite: Performance Benchmarks
- test_create_1000_units_performance()
- test_query_1000_units_performance()
- test_movement_with_pathfinding_performance()
- test_ability_use_performance()
```

### Test Coverage Target

- **Overall Coverage**: 90%
- **Core Functions**: 95%
- **Ability System**: 85%
- **Edge Cases**: 100%

---

## Mock Interfaces for Testing

### MockMapData

```gdscript
class_name MockMapData
extends Node

# Provides stub map for unit testing
# Returns predefined tiles
# Simulates pathfinding results
# No actual map generation
```

### MockGameState

```gdscript
class_name MockGameState
extends Node

# Provides stub game state
# Tracks faction IDs
# Simulates turn state
# No persistence
```

---

## Integration Points

### With Core System

```gdscript
# Unit System listens to:
EventBus.turn_started.connect(_on_turn_started)
EventBus.turn_ended.connect(_on_turn_ended)
EventBus.game_loaded.connect(_on_game_loaded)

# Unit System emits to:
EventBus.unit_created
EventBus.unit_died
EventBus.unit_moved
# ... (see Events section)
```

### With Map System

```gdscript
# Unit System queries:
MapData.get_tile(position)
MapData.is_tile_passable(position, movement_type)
MapData.find_path(start, goal, movement_type)
MapData.get_tiles_in_radius(center, radius)

# Unit System updates:
# (None - map ownership handled by Map System)
```

### With Combat System (Loosely Coupled)

```gdscript
# Combat System queries:
UnitManager.get_unit(unit_id)
UnitManager.get_units_at_position(position)

# Combat System calls:
UnitManager.damage_unit(unit_id, damage)
UnitManager.add_experience(unit_id, xp)
UnitManager.modify_morale(unit_id, delta)
```

---

## Configuration

### Game Constants

```gdscript
# Config: res://data/config/unit_constants.json
{
  "max_units_per_faction": 100,
  "max_units_per_tile": 10,
  "default_vision_range": 5,
  "morale_rout_threshold": 0,
  "xp_per_kill_base": 50,
  "xp_per_rank_difference": 20,
  "movement_point_scaling": 1.0,
  "ability_cost_scaling": 1.0
}
```

---

## Version History

### Version 1.0 (2025-11-12)
- Initial interface contract
- Core unit management functions
- Movement system
- Ability framework
- Experience/promotion system
- 5 core abilities defined
- Complete event definitions
- Testing specifications

---

## Notes for Implementation

### Phase 2 Development Guidelines

1. **Start with Core Unit Class**: Implement Unit and UnitStats first
2. **Build UnitManager Registry**: Set up unit tracking and queries
3. **Implement Factory**: Load data and create units from templates
4. **Add Movement System**: Integrate with map pathfinding
5. **Create Ability Framework**: Base class and validation
6. **Implement Abilities**: Start with simple abilities (Entrench, Heal)
7. **Add Experience System**: XP tracking and rank promotions
8. **Write Tests Throughout**: Test each component as implemented

### Mocking Strategy

- Use `MockMapData` for movement tests
- Use `MockGameState` for faction queries
- Use `MockEventBus` to verify events emitted
- Use `MockCombatSystem` if needed for integration tests

### Performance Considerations

- Pre-allocate unit ID pool (1-10000)
- Use Dictionary for O(1) lookups
- Cache frequently accessed calculations
- Lazy-load ability instances
- Use object pooling for status effects

---

## Contact & Questions

**Assigned Agent**: Agent 3
**Module Owner**: Unit System
**Review Status**: Pending
**Last Updated**: 2025-11-12

For questions or clarifications about this interface, please refer to the implementation plan or consult the integration coordinator.
