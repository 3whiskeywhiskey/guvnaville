# Event System Interface Contract

**Module**: Event System (`systems/events/`)
**Agent**: Agent 8
**Layer**: Layer 2 (Systems)
**Dependencies**: Core (Layer 1)
**Version**: 1.0
**Last Updated**: 2025-11-12

---

## Table of Contents
1. [Module Overview](#module-overview)
2. [Dependencies](#dependencies)
3. [File Structure](#file-structure)
4. [Data Structures](#data-structures)
5. [Public Interfaces](#public-interfaces)
6. [Signals](#signals)
7. [Configuration](#configuration)
8. [Event Data Format](#event-data-format)
9. [Integration Points](#integration-points)
10. [Testing Requirements](#testing-requirements)
11. [Implementation Notes](#implementation-notes)

---

## Module Overview

The Event System manages the game's dynamic narrative and random events, providing players with choices that affect their faction's progression. It handles:

- Event loading from JSON data files
- Event queue management with priority and timing
- Trigger evaluation based on game state conditions
- Choice presentation and resolution
- Consequence application (resources, units, culture, etc.)
- Event chains and sequencing

### Key Responsibilities
1. **Event Loading**: Parse and validate event data from JSON
2. **Event Queue**: Manage priority-based event queue with turn-based timing
3. **Trigger Evaluation**: Check conditions to determine which events should fire
4. **Choice System**: Present choices and handle player/AI selection
5. **Consequence Application**: Apply effects to game state
6. **Event Chains**: Support sequential and branching event narratives

---

## Dependencies

### Core Dependencies (Layer 1)
- `GameState`: Access to current game state for trigger evaluation
- `ResourceManager`: Apply resource consequences
- `DataLoader`: Load event data from JSON

### External Dependencies
- Godot `Resource` system for event data
- Godot `Signal` system for event notifications

---

## File Structure

```
systems/events/
├── event_manager.gd          # Main coordinator, event queue management
├── event_trigger.gd          # Trigger condition evaluation
├── event_choice.gd           # Choice data and resolution logic
├── event_consequences.gd     # Apply consequences to game state
└── README.md                 # Module documentation
```

### Component Responsibilities

#### `event_manager.gd`
- Load events from data files
- Manage event queue (priority, scheduling)
- Process queue each turn
- Coordinate trigger evaluation
- Track event history (prevent duplicates)
- Generate event instances

#### `event_trigger.gd`
- Evaluate trigger conditions
- Check prerequisites
- Calculate rarity-based probabilities
- Filter available events for factions

#### `event_choice.gd`
- Store choice data structure
- Validate choice requirements
- Handle probabilistic outcomes

#### `event_consequences.gd`
- Parse consequence definitions
- Apply effects to game state
- Handle resource changes
- Trigger follow-up events
- Report consequence results

---

## Data Structures

### EventInstance
```gdscript
class_name EventInstance
extends Resource

## Unique runtime identifier for this event instance
var id: int = -1

## Reference to the event definition ID
var event_id: String = ""

## Faction receiving this event
var faction_id: int = -1

## Display title (localized)
var title: String = ""

## Event description/narrative (localized)
var description: String = ""

## Available choices for this event
var choices: Array[EventChoice] = []

## Turn number when this event should be presented
var trigger_turn: int = -1

## Turn number when this event was queued
var queued_turn: int = -1

## Priority level (higher = processed first)
var priority: int = 0

## Optional image/icon path
var image_path: String = ""

## Optional flavor metadata
var metadata: Dictionary = {}
```

### EventChoice
```gdscript
class_name EventChoice
extends Resource

## Choice display text (localized)
var text: String = ""

## Internal identifier
var choice_id: String = ""

## Requirements to enable this choice
var requirements: Array[Requirement] = []

## Whether this choice is currently available
var is_available: bool = true

## Reason why choice is unavailable (for UI feedback)
var unavailable_reason: String = ""

## Outcomes/consequences of selecting this choice
var outcomes: Array[Consequence] = []

## Whether outcomes are probabilistic
var probabilistic: bool = false

## If probabilistic, array of weighted outcomes
var probability_weights: Array[float] = []
```

### Requirement
```gdscript
class_name EventRequirement
extends Resource

enum RequirementType {
    RESOURCE,           # Has X amount of resource
    CULTURE_NODE,       # Has unlocked culture node
    BUILDING,           # Owns building type
    UNIT_TYPE,          # Has unit type available
    TERRITORY_SIZE,     # Controls X tiles
    FACTION_RELATIONSHIP, # Relationship level with faction
    TURN_NUMBER,        # Game turn >= X
    EVENT_COMPLETED,    # Previous event completed
    CUSTOM_FLAG         # Custom game flag set
}

var type: RequirementType
var parameter: String = ""      # Resource name, building ID, etc.
var value: Variant = null       # Required amount/value
var comparison: String = ">="   # >=, <=, ==, !=
```

### Consequence
```gdscript
class_name EventConsequence
extends Resource

enum ConsequenceType {
    RESOURCE_CHANGE,    # Add/remove resources
    SPAWN_UNIT,         # Create unit at location
    DESTROY_UNIT,       # Remove unit
    ADD_BUILDING,       # Construct building
    DAMAGE_BUILDING,    # Damage/destroy building
    CULTURE_POINTS,     # Add culture points
    MORALE_CHANGE,      # Change faction morale
    RELATIONSHIP_CHANGE, # Change diplomacy
    QUEUE_EVENT,        # Add another event to queue
    SET_FLAG,           # Set custom game flag
    GRANT_ABILITY,      # Unlock special ability
    MODIFY_STAT         # Modify unit/building stats
}

var type: ConsequenceType
var target: String = ""         # What this affects
var value: Variant = null       # Amount/data
var duration: int = -1          # -1 = permanent, else turn count
var description: String = ""    # Human-readable description
```

### EventDefinition
```gdscript
class_name EventDefinition
extends Resource

## Unique event identifier
var event_id: String = ""

## Display title
var title: String = ""

## Description text
var description: String = ""

## Event category
var category: String = "random"  # random, cultural, diplomatic, discovery, crisis, quest

## Rarity level
var rarity: String = "common"    # common, uncommon, rare, epic

## Trigger conditions
var triggers: Array[EventTrigger] = []

## Available choices
var choices: Array[EventChoice] = []

## Base priority (0-100, higher = more important)
var base_priority: int = 50

## Can this event repeat?
var repeatable: bool = false

## Cooldown turns before can repeat
var cooldown_turns: int = 0

## Image/icon path
var image_path: String = ""

## Metadata
var metadata: Dictionary = {}
```

### EventTrigger
```gdscript
class_name EventTrigger
extends Resource

enum TriggerType {
    TURN_NUMBER,        # Specific turn or turn range
    RESOURCE_THRESHOLD, # Resource amount crosses threshold
    TERRITORY_SIZE,     # Controls X tiles
    CULTURE_UNLOCK,     # Unlocked culture node
    BUILDING_BUILT,     # Built specific building
    UNIT_LOST,          # Lost unit in combat
    LOCATION_CAPTURED,  # Captured unique location
    RELATIONSHIP_LEVEL, # Diplomacy level reached
    RANDOM_CHANCE,      # Pure RNG each turn
    EVENT_CHAIN         # Previous event triggered
}

var type: TriggerType
var conditions: Array[EventRequirement] = []
var chance: float = 1.0         # 0.0-1.0 probability if conditions met
```

---

## Public Interfaces

### EventManager (Main Interface)

```gdscript
class_name EventManager
extends Node

## Load events from data array
## @param data: Array of event definition dictionaries
## @returns: void
func load_events(data: Array) -> void:
    pass

## Queue an event to be presented to a faction
## @param event_id: ID of event to queue
## @param faction_id: Target faction
## @param delay_turns: Turns to wait before presenting (0 = this turn)
## @returns: void
func queue_event(event_id: String, faction_id: int, delay_turns: int = 0) -> void:
    pass

## Check which events should trigger for a faction
## @param faction_id: Faction to check
## @param game_state: Current game state
## @returns: Array of event IDs that should trigger
func check_triggers(faction_id: int, game_state: GameState) -> Array[String]:
    pass

## Present an event to a faction and create an instance
## @param event_id: Event definition ID
## @param faction_id: Target faction
## @returns: EventInstance ready for presentation
func present_event(event_id: String, faction_id: int) -> EventInstance:
    pass

## Record a choice made for an event instance
## @param event_instance_id: Runtime instance ID
## @param choice_index: Index of selected choice
## @returns: void
func make_choice(event_instance_id: int, choice_index: int) -> void:
    pass

## Apply consequences of a choice
## @param event_id: Event definition ID
## @param choice_index: Index of selected choice
## @param faction_id: Faction making choice
## @returns: Dictionary of applied consequences for feedback
func apply_consequences(event_id: String, choice_index: int, faction_id: int) -> Dictionary:
    pass

## Process event queue for current turn
## @param current_turn: Current turn number
## @returns: Array of EventInstances that should be presented this turn
func process_event_queue(current_turn: int) -> Array[EventInstance]:
    pass

## Get event definition by ID
## @param event_id: Event definition ID
## @returns: EventDefinition or null if not found
func get_event_definition(event_id: String) -> EventDefinition:
    pass

## Get active event instance by ID
## @param instance_id: Runtime instance ID
## @returns: EventInstance or null if not found
func get_event_instance(instance_id: int) -> EventInstance:
    pass

## Clear event history (for testing)
## @returns: void
func clear_history() -> void:
    pass

## Get faction's event history
## @param faction_id: Faction to query
## @returns: Array of event IDs that have fired for this faction
func get_faction_event_history(faction_id: int) -> Array[String]:
    pass
```

### EventTriggerEvaluator

```gdscript
class_name EventTriggerEvaluator
extends Node

## Evaluate if event should trigger
## @param event_def: Event definition to check
## @param faction_id: Faction to check for
## @param game_state: Current game state
## @returns: bool - true if should trigger
func evaluate_triggers(event_def: EventDefinition, faction_id: int, game_state: GameState) -> bool:
    pass

## Check if requirement is met
## @param requirement: Requirement to check
## @param faction_id: Faction to check for
## @param game_state: Current game state
## @returns: bool - true if requirement met
func check_requirement(requirement: EventRequirement, faction_id: int, game_state: GameState) -> bool:
    pass

## Evaluate rarity roll
## @param rarity: Rarity string (common, uncommon, rare, epic)
## @returns: bool - true if rarity check passed
func roll_rarity(rarity: String) -> bool:
    pass
```

### EventChoiceResolver

```gdscript
class_name EventChoiceResolver
extends Node

## Validate if choice is available
## @param choice: Choice to validate
## @param faction_id: Faction making choice
## @param game_state: Current game state
## @returns: Dictionary with {available: bool, reason: String}
func validate_choice(choice: EventChoice, faction_id: int, game_state: GameState) -> Dictionary:
    pass

## Resolve probabilistic outcomes
## @param choice: Choice with multiple outcomes
## @returns: Array[Consequence] - selected consequences
func resolve_probabilistic_choice(choice: EventChoice) -> Array[Consequence]:
    pass
```

### EventConsequenceApplicator

```gdscript
class_name EventConsequenceApplicator
extends Node

## Apply all consequences from a choice
## @param consequences: Array of consequences to apply
## @param faction_id: Target faction
## @param game_state: Current game state
## @returns: Dictionary describing what was applied
func apply_consequences(consequences: Array[Consequence], faction_id: int, game_state: GameState) -> Dictionary:
    pass

## Apply single consequence
## @param consequence: Consequence to apply
## @param faction_id: Target faction
## @param game_state: Current game state
## @returns: Dictionary describing result
func apply_consequence(consequence: Consequence, faction_id: int, game_state: GameState) -> Dictionary:
    pass

## Validate consequences can be applied
## @param consequences: Array of consequences
## @param faction_id: Target faction
## @param game_state: Current game state
## @returns: bool - true if all can be applied
func validate_consequences(consequences: Array[Consequence], faction_id: int, game_state: GameState) -> bool:
    pass
```

---

## Signals

### EventManager Signals

```gdscript
## Emitted when an event is triggered for a faction
## @param faction_id: Faction receiving event
## @param event_id: Event definition ID
## @param event_instance: EventInstance object
signal event_triggered(faction_id: int, event_id: String, event_instance: EventInstance)

## Emitted when a faction makes a choice
## @param faction_id: Faction making choice
## @param event_id: Event definition ID
## @param choice_index: Index of selected choice
signal event_choice_made(faction_id: int, event_id: String, choice_index: int)

## Emitted after consequences are applied
## @param faction_id: Faction affected
## @param event_id: Event definition ID
## @param consequences: Dictionary of applied consequences
signal event_consequences_applied(faction_id: int, event_id: String, consequences: Dictionary)

## Emitted when an event chain starts
## @param faction_id: Faction in chain
## @param chain_id: Identifier for the chain
signal event_chain_started(faction_id: int, chain_id: String)

## Emitted when event is queued
## @param faction_id: Target faction
## @param event_id: Event definition ID
## @param trigger_turn: Turn when it will fire
signal event_queued(faction_id: int, event_id: String, trigger_turn: int)

## Emitted when event is removed from queue (expired, cancelled)
## @param faction_id: Target faction
## @param event_id: Event definition ID
## @param reason: Why it was removed
signal event_dequeued(faction_id: int, event_id: String, reason: String)
```

---

## Configuration

### Rarity System

The rarity system determines event occurrence probability:

| Rarity    | Chance | Description                    |
|-----------|--------|--------------------------------|
| Common    | 60%    | Frequent, low-impact events    |
| Uncommon  | 25%    | Moderate impact events         |
| Rare      | 12%    | High impact, memorable events  |
| Epic      | 3%     | Game-changing, legendary events|

**Implementation**:
```gdscript
const RARITY_CHANCES := {
    "common": 0.60,
    "uncommon": 0.25,
    "rare": 0.12,
    "epic": 0.03
}
```

### Event Categories

- **random**: General random events
- **cultural**: Tied to culture progression
- **diplomatic**: Faction relationships
- **discovery**: Finding locations/resources
- **crisis**: Negative events requiring response
- **quest**: Multi-part event chains

### Priority System

Events are processed by priority (0-100):
- **Critical (80-100)**: Crisis events, time-sensitive
- **High (60-79)**: Major events, story-critical
- **Normal (40-59)**: Standard events
- **Low (20-39)**: Minor flavor events
- **Trivial (0-19)**: Background events

---

## Event Data Format

### JSON Event Definition

```json
{
  "event_id": "scavenge_discovery",
  "title": "Unexpected Discovery",
  "description": "Your scavengers have found something unusual in the ruins...",
  "category": "discovery",
  "rarity": "uncommon",
  "repeatable": false,
  "cooldown_turns": 0,
  "base_priority": 50,
  "image_path": "res://assets/events/scavenge_discovery.png",

  "triggers": [
    {
      "type": "RANDOM_CHANCE",
      "conditions": [
        {
          "type": "UNIT_TYPE",
          "parameter": "scavenger",
          "value": 1,
          "comparison": ">="
        },
        {
          "type": "TURN_NUMBER",
          "value": 10,
          "comparison": ">="
        }
      ],
      "chance": 0.15
    }
  ],

  "choices": [
    {
      "choice_id": "investigate",
      "text": "Investigate thoroughly",
      "requirements": [],
      "probabilistic": false,
      "outcomes": [
        {
          "type": "RESOURCE_CHANGE",
          "target": "components",
          "value": 50,
          "description": "Gained 50 components"
        },
        {
          "type": "CULTURE_POINTS",
          "target": "technology",
          "value": 10,
          "description": "Gained 10 technology culture points"
        }
      ]
    },
    {
      "choice_id": "quick_grab",
      "text": "Grab what you can and leave",
      "requirements": [],
      "probabilistic": true,
      "probability_weights": [0.7, 0.3],
      "outcomes": [
        [
          {
            "type": "RESOURCE_CHANGE",
            "target": "scrap",
            "value": 30,
            "description": "Gained 30 scrap"
          }
        ],
        [
          {
            "type": "RESOURCE_CHANGE",
            "target": "scrap",
            "value": 10,
            "description": "Gained only 10 scrap"
          },
          {
            "type": "MORALE_CHANGE",
            "value": -5,
            "description": "Morale decreased by 5"
          }
        ]
      ]
    },
    {
      "choice_id": "ignore",
      "text": "Too risky, leave it",
      "requirements": [],
      "probabilistic": false,
      "outcomes": []
    }
  ],

  "metadata": {
    "author": "Agent 8",
    "version": "1.0",
    "tags": ["scavenging", "discovery", "risk-reward"]
  }
}
```

---

## Integration Points

### With Core Systems

#### GameState
```gdscript
# Event system needs to read:
- game_state.current_turn
- game_state.factions[faction_id].resources
- game_state.factions[faction_id].culture_state
- game_state.factions[faction_id].units
- game_state.factions[faction_id].buildings
- game_state.world_state.map

# Event system needs to modify:
- game_state.factions[faction_id].resources (via consequences)
- game_state.factions[faction_id].morale (via consequences)
- game_state.custom_flags (set/check flags)
```

#### ResourceManager
```gdscript
# Apply resource consequences
ResourceManager.add_resource(faction_id, resource_type, amount)
ResourceManager.remove_resource(faction_id, resource_type, amount)
ResourceManager.get_resource(faction_id, resource_type) -> int
```

#### CultureSystem
```gdscript
# Apply culture point consequences
CultureSystem.add_culture_points(faction_id, axis, amount)
CultureSystem.has_unlocked_node(faction_id, node_id) -> bool
```

#### UnitSystem
```gdscript
# Spawn/remove units as consequences
UnitSystem.spawn_unit(faction_id, unit_type, position)
UnitSystem.remove_unit(unit_id)
```

#### DiplomacySystem
```gdscript
# Modify relationships
DiplomacySystem.modify_relationship(faction_a, faction_b, amount)
DiplomacySystem.get_relationship(faction_a, faction_b) -> int
```

### With UI System

```gdscript
# UI displays event instances
EventUI.show_event(event_instance: EventInstance)
EventUI.highlight_choice(choice_index: int, is_available: bool)
EventUI.show_consequences(consequences: Dictionary)

# UI signals back to EventManager
EventUI.choice_selected.connect(event_manager.make_choice)
```

### With AI System

```gdscript
# AI evaluates and selects choices
AIEventHandler.evaluate_event(event_instance: EventInstance) -> int
# Returns choice index to select
```

---

## Testing Requirements

### Unit Tests

#### EventManager Tests
```gdscript
# test_event_manager.gd
func test_load_events():
    # Load event data and verify parsing

func test_queue_event():
    # Queue event and verify it appears in queue

func test_process_queue_timing():
    # Events fire on correct turns

func test_event_history_no_duplicates():
    # Non-repeatable events don't fire twice

func test_priority_ordering():
    # Higher priority events processed first
```

#### EventTriggerEvaluator Tests
```gdscript
# test_event_trigger.gd
func test_resource_requirement():
    # Trigger when resource threshold met

func test_culture_requirement():
    # Trigger when culture node unlocked

func test_turn_requirement():
    # Trigger on specific turn

func test_random_chance():
    # Test probability distribution

func test_rarity_system():
    # Verify rarity percentages
```

#### EventChoiceResolver Tests
```gdscript
# test_event_choice.gd
func test_validate_available_choice():
    # Choice available when requirements met

func test_validate_unavailable_choice():
    # Choice unavailable when requirements not met

func test_probabilistic_resolution():
    # Weighted outcomes selected correctly
```

#### EventConsequenceApplicator Tests
```gdscript
# test_event_consequences.gd
func test_apply_resource_change():
    # Resources modified correctly

func test_apply_culture_points():
    # Culture points added

func test_apply_spawn_unit():
    # Unit created at location

func test_chain_event_queued():
    # Follow-up event queued

func test_consequence_validation():
    # Invalid consequences rejected
```

### Integration Tests

```gdscript
# test_event_integration.gd
func test_full_event_flow():
    # Trigger -> Present -> Choose -> Apply consequences

func test_event_affects_game_state():
    # Consequences properly modify GameState

func test_event_chain_sequence():
    # Multi-event chains work correctly

func test_ai_event_handling():
    # AI can evaluate and select choices
```

### Test Data

Create test event files:
```
tests/data/events/
├── test_events_basic.json
├── test_events_chains.json
├── test_events_probabilistic.json
└── test_events_requirements.json
```

---

## Implementation Notes

### Development Order

1. **Data Structures** (Day 1)
   - Define all class structures
   - Create JSON schema

2. **Event Loading** (Day 2)
   - Implement `load_events()`
   - Parse JSON into EventDefinition objects
   - Write load tests

3. **Event Queue** (Day 2-3)
   - Implement queue management
   - Priority sorting
   - `process_event_queue()`

4. **Trigger Evaluation** (Day 3-4)
   - Implement condition checking
   - Rarity system
   - `check_triggers()`

5. **Choice System** (Day 4-5)
   - Choice validation
   - Probabilistic resolution
   - `validate_choice()`, `resolve_probabilistic_choice()`

6. **Consequence Application** (Day 5-6)
   - Implement all consequence types
   - Integration with other systems
   - `apply_consequences()`

7. **Event Chains** (Day 6-7)
   - Chain event queuing
   - Sequence tracking

8. **Testing & Polish** (Day 7-8)
   - Complete unit tests
   - Integration tests
   - Documentation

### Performance Considerations

- **Event Pool**: Pre-load all events at game start
- **Trigger Cache**: Cache trigger evaluation results per turn
- **Event Instances**: Pool and reuse EventInstance objects
- **History Tracking**: Use Set/Dictionary for O(1) lookups

### Error Handling

- Validate event data on load
- Graceful fallback for missing events
- Log warnings for invalid triggers
- Prevent crashes from malformed consequence data

### Localization

- All text fields support localization keys
- Use TranslationServer for runtime translation
- Format: `"EVENT_{event_id}_TITLE"`, `"EVENT_{event_id}_DESC"`

### Save/Load Support

Events must be serializable:
```gdscript
func serialize_event_state() -> Dictionary:
    return {
        "event_history": _event_history,
        "queued_events": _serialize_queue(),
        "active_instances": _serialize_instances()
    }

func deserialize_event_state(data: Dictionary) -> void:
    _event_history = data["event_history"]
    _deserialize_queue(data["queued_events"])
    _deserialize_instances(data["active_instances"])
```

---

## Contract Validation

This interface contract is considered complete when:

- [ ] All public functions are implemented with correct signatures
- [ ] All signals are defined and emitted at correct times
- [ ] All data structures are defined and documented
- [ ] Unit tests pass with >80% coverage
- [ ] Integration tests pass with other systems
- [ ] Event data can be loaded from JSON
- [ ] Events trigger, present, and resolve correctly
- [ ] Consequences properly modify game state
- [ ] Save/load preserves event state
- [ ] Documentation is complete and accurate

---

## Version History

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | 2025-11-12 | Initial interface contract       |

---

## Contact

**Agent**: Agent 8
**Module**: Event System
**Questions**: Refer to implementation plan or integration coordinator
