# Economy System Interface Contract

## Module Information

**Module Name**: Economy System
**Module Path**: `systems/economy/`
**Layer**: Layer 3 (Game Systems)
**Dependencies**: Core (Layer 2)
**Version**: 1.0.0
**Last Updated**: 2025-11-12

## Overview

The Economy System is responsible for managing all resource-related mechanics in Ashes to Empire. This includes resource tracking, production queues, trade routes, scavenging operations, and population management. The system operates on a turn-based model where resources are collected, consumed, and managed each turn.

### Key Responsibilities

1. **Resource Management**: Track stockpiles, income, and consumption for all factions
2. **Production System**: Manage build queues for units, buildings, and infrastructure
3. **Trade System**: Handle trade routes and resource exchanges between factions
4. **Scavenging System**: Process scavenging operations on ruin tiles
5. **Population System**: Manage population growth, happiness, and resource consumption

### Resource Types

The system manages the following resource types:
- **scrap**: Universal building material
- **food**: Population sustenance
- **medicine**: Healthcare and population growth
- **fuel**: Vehicle operation and power generation
- **electronics**: Advanced technology components
- **materials**: Construction materials
- **water**: Critical for population survival (Optional extension)
- **ammunition**: Military operations (Optional extension)

## Module Components

```
systems/economy/
├── resource_manager.gd      # Resource tracking and manipulation
├── production_system.gd     # Production queue management
├── trade_system.gd          # Trade route operations
├── scavenging_system.gd     # Scavenging mechanics
└── population_system.gd     # Population growth and happiness
```

## Data Structures

### ResourceStockpile
```gdscript
# Represents a faction's resource stockpile
class ResourceStockpile:
    var scrap: int = 0
    var food: int = 0
    var medicine: int = 0
    var fuel: int = 0
    var electronics: int = 0
    var materials: int = 0

    # Optional resources
    var water: int = 0
    var ammunition: int = 0
```

### ResourceIncome
```gdscript
# Represents per-turn resource income/consumption
class ResourceIncome:
    var scrap_per_turn: int = 0
    var food_per_turn: int = 0
    var medicine_per_turn: int = 0
    var fuel_per_turn: int = 0
    var electronics_per_turn: int = 0
    var materials_per_turn: int = 0
```

### ProductionQueueItem
```gdscript
# Represents an item in the production queue
class ProductionQueueItem:
    var item_type: String      # "unit", "building", "infrastructure"
    var item_id: String         # Type identifier (e.g., "militia", "factory")
    var total_cost: int         # Total production points required
    var progress: int           # Current production points invested
    var resource_cost: Dictionary  # Resources required: {"scrap": 50, "electronics": 10}
    var resources_paid: bool    # Whether resources have been deducted
    var settlement_id: int      # Which settlement is producing this
```

### TradeRoute
```gdscript
# Represents an active trade route between factions
class TradeRoute:
    var route_id: int
    var from_faction: int
    var to_faction: int
    var resources_offered: Dictionary  # {"food": 20, "medicine": 5}
    var resources_received: Dictionary # {"scrap": 30}
    var duration_turns: int     # Remaining turns (-1 = permanent)
    var security_level: float   # 0.0-1.0, chance of successful delivery
    var active: bool            # Whether route is currently operational
```

### ScavengeResult
```gdscript
# Result of a scavenging operation
class ScavengeResult:
    var success: bool
    var resources_found: Dictionary  # {"scrap": 15, "food": 3}
    var tile_depletion: int     # How much scavenge value was consumed
    var event_triggered: String # Event ID if special event occurred (empty if none)
    var casualties: int         # Number of scavengers lost
    var experience_gained: int  # Experience for surviving scavengers
```

### PopulationData
```gdscript
# Population state for a faction
class PopulationData:
    var total_population: int
    var happiness: float        # 0.0-100.0
    var growth_rate: float      # Percentage per turn
    var mortality_rate: float   # Percentage per turn
    var food_consumption: int   # Food needed per turn
    var water_consumption: int  # Water needed per turn
    var assigned_workers: Dictionary  # {"scavenger": 10, "soldier": 20, "specialist": 5}
```

## Public Interface - Resource Manager

### add_resources()
```gdscript
# Adds resources to a faction's stockpile
# Parameters:
#   faction_id: int - The faction receiving resources
#   resources: Dictionary - Resource types and amounts: {"scrap": 50, "food": 20}
# Returns: void
# Emits: resource_changed for each resource type added
func add_resources(faction_id: int, resources: Dictionary) -> void
```

**Usage Example**:
```gdscript
var loot = {"scrap": 50, "medicine": 10}
economy_system.add_resources(player_faction_id, loot)
```

**Notes**:
- Negative values are treated as 0
- Emits `resource_changed` signal for each resource type in the dictionary
- If faction_id is invalid, logs error and returns without changes

---

### consume_resources()
```gdscript
# Attempts to consume resources from a faction's stockpile
# Parameters:
#   faction_id: int - The faction consuming resources
#   resources: Dictionary - Resource types and amounts: {"scrap": 30, "food": 15}
# Returns: bool - true if all resources were available and consumed, false otherwise
# Emits: resource_changed if successful, resource_shortage if insufficient
func consume_resources(faction_id: int, resources: Dictionary) -> bool
```

**Usage Example**:
```gdscript
var cost = {"scrap": 100, "electronics": 20}
if economy_system.consume_resources(player_faction_id, cost):
    # Build the unit
    unit_system.create_unit(unit_type)
else:
    # Show error: insufficient resources
    ui.show_error("Insufficient resources")
```

**Notes**:
- Checks all resources first; only consumes if ALL are available (atomic operation)
- If any resource is insufficient, emits `resource_shortage` and returns false
- Does not partially consume resources

---

### get_resources()
```gdscript
# Retrieves the current resource stockpile for a faction
# Parameters:
#   faction_id: int - The faction to query
# Returns: Dictionary - Current resource amounts: {"scrap": 450, "food": 200, ...}
func get_resources(faction_id: int) -> Dictionary
```

**Usage Example**:
```gdscript
var resources = economy_system.get_resources(player_faction_id)
print("Scrap: ", resources["scrap"])
print("Food: ", resources["food"])
```

**Notes**:
- Returns empty dictionary if faction_id is invalid
- Always returns a complete dictionary with all resource types (0 if not present)

---

### get_resource_income()
```gdscript
# Calculates the net per-turn income for all resources
# Parameters:
#   faction_id: int - The faction to calculate for
# Returns: Dictionary - Net income per turn: {"scrap": 25, "food": -15, ...}
#                       Negative values indicate net consumption
func get_resource_income(faction_id: int) -> Dictionary
```

**Usage Example**:
```gdscript
var income = economy_system.get_resource_income(player_faction_id)
if income["food"] < 0:
    ui.show_warning("Food shortage imminent!")
```

**Notes**:
- Calculates: income from buildings + trade - consumption
- Useful for UI display and shortage warnings
- Does not modify any state

---

### set_resource()
```gdscript
# Directly sets a faction's resource amount (admin/debug function)
# Parameters:
#   faction_id: int - The faction to modify
#   resource_type: String - Resource type: "scrap", "food", etc.
#   amount: int - New amount
# Returns: void
# Emits: resource_changed
func set_resource(faction_id: int, resource_type: String, amount: int) -> void
```

**Usage Example**:
```gdscript
# Debug command to give resources
economy_system.set_resource(player_faction_id, "scrap", 9999)
```

**Notes**:
- Primarily for debugging, testing, and cheats
- Does not validate if the amount is reasonable
- Emits `resource_changed` signal

## Public Interface - Production System

### add_to_production_queue()
```gdscript
# Adds an item to a faction's production queue
# Parameters:
#   faction_id: int - The faction building the item
#   item_type: String - "unit", "building", or "infrastructure"
#   item_id: String - Specific type identifier (e.g., "militia", "factory")
# Returns: bool - true if successfully added to queue, false if requirements not met
# Emits: production_queue_updated
func add_to_production_queue(faction_id: int, item_type: String, item_id: String) -> bool
```

**Usage Example**:
```gdscript
# Add a militia unit to the production queue
if economy_system.add_to_production_queue(faction_id, "unit", "militia"):
    ui.show_message("Militia added to production queue")
else:
    ui.show_error("Cannot add to production queue")
```

**Notes**:
- Validates that the faction has the required resources before adding
- Does NOT consume resources immediately (consumed when production starts)
- Returns false if prerequisites not met (e.g., required building not present)
- Adds to the end of the queue

---

### process_production()
```gdscript
# Processes production for a faction for the current turn
# Parameters:
#   faction_id: int - The faction whose production to process
#   delta_time: float - Time multiplier (normally 1.0 for one turn)
# Returns: Array - Array of completed items: [{"type": "unit", "id": "militia"}, ...]
# Emits: production_completed for each completed item
func process_production(faction_id: int, delta_time: float) -> Array
```

**Usage Example**:
```gdscript
# Process production at end of turn
var completed = economy_system.process_production(faction_id, 1.0)
for item in completed:
    if item.type == "unit":
        unit_system.spawn_unit(faction_id, item.id)
    elif item.type == "building":
        building_system.construct_building(faction_id, item.id)
```

**Notes**:
- Applies production points based on faction's production capacity
- Automatically consumes required resources when item completes
- Returns array of completed items this turn
- If resources are insufficient when item completes, item is paused (not removed from queue)

---

### get_production_queue()
```gdscript
# Retrieves the current production queue for a faction
# Parameters:
#   faction_id: int - The faction to query
# Returns: Array - Array of ProductionQueueItem objects
func get_production_queue(faction_id: int) -> Array
```

**Usage Example**:
```gdscript
var queue = economy_system.get_production_queue(faction_id)
for item in queue:
    var progress_pct = (float(item.progress) / item.total_cost) * 100
    print(item.item_id, ": ", progress_pct, "% complete")
```

**Notes**:
- Returns items in queue order (first item is currently being built)
- Each item includes progress information for UI display

---

### cancel_production()
```gdscript
# Cancels a production queue item and refunds resources
# Parameters:
#   faction_id: int - The faction whose production to cancel
#   queue_index: int - Index in the production queue (0 = first item)
# Returns: bool - true if cancelled successfully, false if index invalid
# Emits: production_cancelled
func cancel_production(faction_id: int, queue_index: int) -> bool
```

**Usage Example**:
```gdscript
# Cancel the first item in the queue
if economy_system.cancel_production(faction_id, 0):
    ui.show_message("Production cancelled, 50% resources refunded")
```

**Notes**:
- Refunds 50% of production points invested
- Refunds 100% of resources if they were already deducted
- Returns false if queue_index is out of range

---

### rush_production()
```gdscript
# Instantly completes the current production item by paying extra resources
# Parameters:
#   faction_id: int - The faction rushing production
#   queue_index: int - Index in the production queue (usually 0 for first item)
# Returns: bool - true if successfully rushed, false if insufficient resources
# Emits: production_completed if successful
func rush_production(faction_id: int, queue_index: int) -> bool
```

**Usage Example**:
```gdscript
# Rush the current production item
if economy_system.rush_production(faction_id, 0):
    ui.show_message("Production completed instantly!")
else:
    ui.show_error("Insufficient resources to rush production")
```

**Notes**:
- Costs 2× the base resource cost
- Immediately completes the item
- Useful for emergency military production

## Public Interface - Trade System

### create_trade_route()
```gdscript
# Establishes a trade route between two factions
# Parameters:
#   from_faction: int - Faction offering resources
#   to_faction: int - Faction receiving resources
#   resources_offered: Dictionary - Resources to send: {"food": 20}
#   resources_received: Dictionary - Resources to receive: {"scrap": 30}
#   duration: int - Number of turns (-1 for permanent)
# Returns: int - Trade route ID (>= 0) if successful, -1 if failed
# Emits: trade_route_created
func create_trade_route(from_faction: int, to_faction: int, resources_offered: Dictionary,
                        resources_received: Dictionary, duration: int = -1) -> int
```

**Usage Example**:
```gdscript
# Create a trade route: give 20 food, receive 15 medicine
var offered = {"food": 20}
var received = {"medicine": 15}
var route_id = economy_system.create_trade_route(player_faction, ally_faction, offered, received, 20)
if route_id >= 0:
    ui.show_message("Trade route established")
```

**Notes**:
- Requires diplomatic relations allowing trade
- Validates that a safe path exists between factions
- Trade executes each turn automatically
- Returns -1 if factions are at war or path is blocked

---

### process_trade_routes()
```gdscript
# Processes all active trade routes for the turn
# Parameters:
#   faction_id: int - The faction whose trade routes to process
# Returns: void
# Emits: trade_completed for each successful trade, trade_route_raided if route is attacked
func process_trade_routes(faction_id: int) -> void
```

**Usage Example**:
```gdscript
# Called during end-of-turn processing
economy_system.process_trade_routes(faction_id)
```

**Notes**:
- Automatically transfers resources between factions
- Checks route security; routes can be raided by hostile factions
- Decrements duration counter for temporary routes
- Removes expired routes automatically

---

### cancel_trade_route()
```gdscript
# Cancels an active trade route
# Parameters:
#   route_id: int - The trade route to cancel
# Returns: bool - true if cancelled successfully, false if route doesn't exist
# Emits: trade_route_cancelled
func cancel_trade_route(route_id: int) -> bool
```

**Usage Example**:
```gdscript
# Cancel a trade route
if economy_system.cancel_trade_route(trade_route_id):
    ui.show_message("Trade route cancelled")
```

**Notes**:
- Immediately stops resource transfers
- Does not refund any resources already traded

---

### get_trade_routes()
```gdscript
# Retrieves all active trade routes involving a faction
# Parameters:
#   faction_id: int - The faction to query
# Returns: Array - Array of TradeRoute objects
func get_trade_routes(faction_id: int) -> Array
```

**Usage Example**:
```gdscript
var routes = economy_system.get_trade_routes(faction_id)
for route in routes:
    print("Trading with faction ", route.to_faction)
    print("Offering: ", route.resources_offered)
    print("Receiving: ", route.resources_received)
```

**Notes**:
- Returns routes where faction is either sender or receiver
- Useful for UI display of active trades

## Public Interface - Scavenging System

### scavenge_tile()
```gdscript
# Performs a scavenging operation on a tile
# Parameters:
#   position: Vector3i - The tile position to scavenge
#   faction_id: int - The faction performing the scavenging
#   num_scavengers: int - Number of scavengers assigned (default 1)
# Returns: ScavengeResult - Result of the scavenging operation
# Emits: scavenging_completed
func scavenge_tile(position: Vector3i, faction_id: int, num_scavengers: int = 1) -> ScavengeResult
```

**Usage Example**:
```gdscript
var tile_pos = Vector3i(10, 15, 1)
var result = economy_system.scavenge_tile(tile_pos, faction_id, 2)

if result.success:
    economy_system.add_resources(faction_id, result.resources_found)
    ui.show_message("Found: " + str(result.resources_found))

    if result.casualties > 0:
        ui.show_warning(str(result.casualties) + " scavengers lost!")
```

**Notes**:
- Reduces tile's scavenge value
- Random chance of finding resources based on tile type
- Can trigger hazard events (casualties)
- Can trigger special events (survivor found, etc.)
- Requires faction to control or have access to the tile

---

### get_tile_scavenge_value()
```gdscript
# Retrieves the remaining scavenge value of a tile
# Parameters:
#   position: Vector3i - The tile position to query
# Returns: int - Scavenge value (0-100)
func get_tile_scavenge_value(position: Vector3i) -> int
```

**Usage Example**:
```gdscript
var scavenge_value = economy_system.get_tile_scavenge_value(tile_pos)
if scavenge_value > 50:
    ui.highlight_tile(tile_pos, "Good scavenging location")
elif scavenge_value == 0:
    ui.mark_tile(tile_pos, "Picked clean")
```

**Notes**:
- Returns 0 if tile has been completely scavenged
- Scavenge value depletes with each scavenging operation
- Different tile types have different initial values

---

### get_scavenge_estimate()
```gdscript
# Estimates potential yields from scavenging a tile
# Parameters:
#   position: Vector3i - The tile position to evaluate
#   faction_id: int - The faction evaluating (for culture bonuses)
# Returns: Dictionary - Estimated yields: {"min": {...}, "max": {...}, "average": {...}}
func get_scavenge_estimate(position: Vector3i, faction_id: int) -> Dictionary
```

**Usage Example**:
```gdscript
var estimate = economy_system.get_scavenge_estimate(tile_pos, faction_id)
ui.show_tooltip("Expected yield: " + str(estimate.average))
```

**Notes**:
- Used for AI planning and UI tooltips
- Takes into account tile type, scavenge value, and faction culture bonuses
- Does not guarantee exact results (actual scavenging is random)

## Public Interface - Population System

### process_population_growth()
```gdscript
# Processes population growth for a faction
# Parameters:
#   faction_id: int - The faction whose population to process
# Returns: void
# Emits: population_changed if population changes
func process_population_growth(faction_id: int) -> void
```

**Usage Example**:
```gdscript
# Called during end-of-turn processing
economy_system.process_population_growth(faction_id)
```

**Notes**:
- Applies growth rate based on happiness, food, medicine availability
- Applies mortality rate based on conditions
- Automatically consumes food and water for population
- Emits `resource_shortage` if food/water insufficient (triggers starvation)

---

### get_population()
```gdscript
# Retrieves the current population for a faction
# Parameters:
#   faction_id: int - The faction to query
# Returns: int - Total population
func get_population(faction_id: int) -> int
```

**Usage Example**:
```gdscript
var pop = economy_system.get_population(faction_id)
ui.update_label("Population: " + str(pop))
```

**Notes**:
- Returns total population count
- Includes all assigned and unassigned pops

---

### get_happiness()
```gdscript
# Retrieves the current happiness level for a faction
# Parameters:
#   faction_id: int - The faction to query
# Returns: float - Happiness value (0.0 - 100.0)
func get_happiness(faction_id: int) -> float
```

**Usage Example**:
```gdscript
var happiness = economy_system.get_happiness(faction_id)
if happiness < 30.0:
    ui.show_alert("Population is miserable! Risk of rebellion!")
elif happiness > 70.0:
    ui.show_status("Population is happy")
```

**Notes**:
- Happiness affects production, growth rate, and rebellion risk
- Calculated based on resource availability, cultural buildings, and events

---

### update_happiness()
```gdscript
# Recalculates happiness for a faction based on current conditions
# Parameters:
#   faction_id: int - The faction whose happiness to update
# Returns: void
# Emits: happiness_changed if happiness changes significantly (>5 points)
func update_happiness(faction_id: int) -> void
```

**Usage Example**:
```gdscript
# Called when conditions change (new building, won battle, etc.)
economy_system.update_happiness(faction_id)
```

**Notes**:
- Factors: food surplus, cultural buildings, recent victories/defeats, starvation
- Automatically called by other systems when relevant conditions change
- Can be called manually for immediate recalculation

---

### assign_population()
```gdscript
# Assigns population to a specific role
# Parameters:
#   faction_id: int - The faction whose population to assign
#   role: String - Role type: "worker", "scavenger", "soldier", "specialist"
#   count: int - Number of pops to assign
# Returns: bool - true if successfully assigned, false if insufficient population
# Emits: population_assigned
func assign_population(faction_id: int, role: String, count: int) -> bool
```

**Usage Example**:
```gdscript
# Assign 10 pops as scavengers
if economy_system.assign_population(faction_id, "scavenger", 10):
    ui.show_message("10 scavengers assigned")
else:
    ui.show_error("Insufficient unassigned population")
```

**Notes**:
- Reduces unassigned population by count
- Returns false if not enough unassigned pops available
- Different roles have different effects on economy

---

### get_population_breakdown()
```gdscript
# Retrieves detailed population assignment breakdown
# Parameters:
#   faction_id: int - The faction to query
# Returns: Dictionary - Population by role: {"unassigned": 20, "worker": 30, ...}
func get_population_breakdown(faction_id: int) -> Dictionary
```

**Usage Example**:
```gdscript
var breakdown = economy_system.get_population_breakdown(faction_id)
print("Unassigned: ", breakdown["unassigned"])
print("Workers: ", breakdown["worker"])
print("Scavengers: ", breakdown["scavenger"])
```

**Notes**:
- Useful for UI display and AI planning
- Total of all values equals total population

## Signals/Events

### resource_changed
```gdscript
# Emitted when a faction's resource amount changes
signal resource_changed(faction_id: int, resource_type: String, amount_delta: int, new_total: int)
```

**Example Handler**:
```gdscript
func _on_resource_changed(faction_id, resource_type, amount_delta, new_total):
    if faction_id == player_faction_id:
        ui.update_resource_display(resource_type, new_total)
        if amount_delta > 0:
            ui.show_floating_text("+" + str(amount_delta) + " " + resource_type)
```

---

### resource_shortage
```gdscript
# Emitted when a faction cannot afford a resource cost or runs out of critical resources
signal resource_shortage(faction_id: int, resource_type: String, deficit: int)
```

**Example Handler**:
```gdscript
func _on_resource_shortage(faction_id, resource_type, deficit):
    if faction_id == player_faction_id:
        ui.show_alert("Resource shortage: " + resource_type)
        ui.show_suggestion("You need " + str(deficit) + " more " + resource_type)
```

---

### production_completed
```gdscript
# Emitted when a production queue item is completed
signal production_completed(faction_id: int, item_type: String, item_id: String)
```

**Example Handler**:
```gdscript
func _on_production_completed(faction_id, item_type, item_id):
    if item_type == "unit":
        unit_system.spawn_unit(faction_id, item_id)
    elif item_type == "building":
        building_system.construct_building(faction_id, item_id)

    if faction_id == player_faction_id:
        ui.show_notification("Production complete: " + item_id)
```

---

### production_queue_updated
```gdscript
# Emitted when a faction's production queue changes (item added, removed, or reordered)
signal production_queue_updated(faction_id: int)
```

**Example Handler**:
```gdscript
func _on_production_queue_updated(faction_id):
    if faction_id == player_faction_id:
        ui.refresh_production_queue_display()
```

---

### production_cancelled
```gdscript
# Emitted when a production item is cancelled
signal production_cancelled(faction_id: int, item_type: String, item_id: String, refund: Dictionary)
```

**Example Handler**:
```gdscript
func _on_production_cancelled(faction_id, item_type, item_id, refund):
    ui.show_message("Production cancelled: " + item_id)
    ui.show_message("Refunded: " + str(refund))
```

---

### trade_route_created
```gdscript
# Emitted when a new trade route is established
signal trade_route_created(route_id: int, from_faction: int, to_faction: int, resources: Dictionary)
```

**Example Handler**:
```gdscript
func _on_trade_route_created(route_id, from_faction, to_faction, resources):
    if from_faction == player_faction_id or to_faction == player_faction_id:
        ui.show_notification("Trade route established")
        ui.update_trade_display()
```

---

### trade_completed
```gdscript
# Emitted when a trade route successfully transfers resources
signal trade_completed(from_faction: int, to_faction: int, resources_exchanged: Dictionary)
```

**Example Handler**:
```gdscript
func _on_trade_completed(from_faction, to_faction, resources_exchanged):
    # Log trade activity for player
    if from_faction == player_faction_id or to_faction == player_faction_id:
        event_log.add_entry("Trade completed: " + str(resources_exchanged))
```

---

### trade_route_raided
```gdscript
# Emitted when a trade route is attacked and resources are lost
signal trade_route_raided(route_id: int, raider_faction: int, resources_lost: Dictionary)
```

**Example Handler**:
```gdscript
func _on_trade_route_raided(route_id, raider_faction, resources_lost):
    ui.show_alert("Trade route raided! Lost: " + str(resources_lost))
    # May trigger diplomatic incident
    diplomacy_system.record_hostile_action(raider_faction)
```

---

### trade_route_cancelled
```gdscript
# Emitted when a trade route is cancelled
signal trade_route_cancelled(route_id: int, from_faction: int, to_faction: int)
```

**Example Handler**:
```gdscript
func _on_trade_route_cancelled(route_id, from_faction, to_faction):
    ui.update_trade_display()
    if from_faction == player_faction_id:
        ui.show_message("Trade route with faction " + str(to_faction) + " cancelled")
```

---

### scavenging_completed
```gdscript
# Emitted when a scavenging operation completes
signal scavenging_completed(faction_id: int, position: Vector3i, resources_found: Dictionary, casualties: int)
```

**Example Handler**:
```gdscript
func _on_scavenging_completed(faction_id, position, resources_found, casualties):
    if faction_id == player_faction_id:
        if resources_found.size() > 0:
            ui.show_message("Scavenging successful: " + str(resources_found))
        if casualties > 0:
            ui.show_alert(str(casualties) + " scavengers lost!")
```

---

### population_changed
```gdscript
# Emitted when a faction's population changes significantly
signal population_changed(faction_id: int, old_population: int, new_population: int)
```

**Example Handler**:
```gdscript
func _on_population_changed(faction_id, old_pop, new_pop):
    var delta = new_pop - old_pop
    if faction_id == player_faction_id:
        if delta > 0:
            ui.show_notification("Population grew by " + str(delta))
        elif delta < 0:
            ui.show_alert("Population declined by " + str(abs(delta)))
        ui.update_population_display(new_pop)
```

---

### happiness_changed
```gdscript
# Emitted when a faction's happiness changes significantly (>5 points)
signal happiness_changed(faction_id: int, old_happiness: float, new_happiness: float)
```

**Example Handler**:
```gdscript
func _on_happiness_changed(faction_id, old_happiness, new_happiness):
    if faction_id == player_faction_id:
        if new_happiness < 30 and old_happiness >= 30:
            ui.show_alert("Population morale is critically low!")
        ui.update_happiness_indicator(new_happiness)
```

---

### population_assigned
```gdscript
# Emitted when population is assigned to a new role
signal population_assigned(faction_id: int, role: String, count: int)
```

**Example Handler**:
```gdscript
func _on_population_assigned(faction_id, role, count):
    if faction_id == player_faction_id:
        ui.show_message(str(count) + " pops assigned as " + role)
        ui.update_population_breakdown()
```

## Integration Points

### Dependencies

#### Core System (Layer 2)
- **GameState**: Read/write faction states, turn information
- **EventBus**: Emit economy-related events
- **DataLoader**: Load resource definitions, production costs, trade rates
- **SaveManager**: Serialize/deserialize economy state

### Dependents (Systems that use Economy System)

#### AI System
- Query resource availability for decision-making
- Plan resource acquisition strategies
- Manage production priorities
- Establish trade routes with other factions

#### UI System
- Display resource stockpiles
- Show production queue progress
- Render trade route information
- Display population statistics

#### Combat System
- Deduct ammunition costs during combat
- Award resource loot from victories
- Consume fuel for vehicle movement

#### Map System
- Query scavenge values for tiles
- Update tile states after scavenging

#### Culture System
- Apply culture bonuses to production
- Apply culture bonuses to resource generation
- Apply happiness modifiers from cultural policies

## Turn Processing Integration

The Economy System should be called in the following order during turn processing:

1. **Beginning of Turn**:
   - `process_trade_routes()` - Execute trades
   - Update resource income from controlled locations

2. **During Player/AI Actions**:
   - `consume_resources()` - When actions require resources
   - `add_to_production_queue()` - When new items are queued
   - `scavenge_tile()` - When scavenging actions are taken

3. **End of Turn**:
   - `process_production()` - Advance production queues
   - `process_population_growth()` - Update population
   - `update_happiness()` - Recalculate happiness
   - Check for resource shortages and emit warnings

## Testing Considerations

### Unit Tests

1. **Resource Management**:
   - Test adding/consuming resources
   - Test resource shortage detection
   - Test negative value handling
   - Test invalid faction IDs

2. **Production System**:
   - Test adding items to queue
   - Test production progress calculation
   - Test production completion
   - Test resource consumption on completion
   - Test production cancellation and refunds
   - Test rush production

3. **Trade System**:
   - Test trade route creation
   - Test resource transfers
   - Test trade route security checks
   - Test trade route cancellation
   - Test expired route cleanup

4. **Scavenging System**:
   - Test scavenge yield calculation
   - Test tile depletion
   - Test hazard events
   - Test cultural bonuses

5. **Population System**:
   - Test growth rate calculation
   - Test happiness calculation
   - Test population assignment
   - Test starvation mechanics

### Integration Tests

1. **Full Turn Cycle**:
   - Process complete turn with all economy operations
   - Verify resource flow (income → consumption → stockpile)
   - Verify production advances correctly

2. **Resource Shortage Handling**:
   - Trigger shortages and verify proper response
   - Test cascade effects (food shortage → starvation → population decline)

3. **Trade Network**:
   - Establish multiple trade routes
   - Verify resource flows between factions
   - Test trade route disruption

### Performance Tests

1. **Large Scale**:
   - Test with 9 factions, each with complex economies
   - Measure turn processing time
   - Verify no memory leaks

2. **Production Queues**:
   - Test with long production queues (50+ items)
   - Verify efficient processing

## Error Handling

### Invalid Inputs
- Invalid faction IDs: Log error, return default/empty values
- Negative resource amounts: Clamp to 0
- Invalid resource types: Log warning, ignore

### Resource Shortages
- Insufficient resources for consumption: Return false, emit `resource_shortage`
- Insufficient resources for production completion: Pause production, emit warning

### Trade Route Failures
- No valid path between factions: Fail to create route, return -1
- Factions at war: Automatically cancel existing routes

## Performance Considerations

### Optimization Strategies

1. **Caching**:
   - Cache resource income calculations (invalidate when buildings change)
   - Cache scavenge estimates (invalidate when tile changes)

2. **Batch Operations**:
   - Process all trade routes in a single pass
   - Batch resource changes to reduce signal emissions

3. **Lazy Evaluation**:
   - Only recalculate happiness when needed
   - Defer population breakdown calculation until queried

4. **Data Structure**:
   - Use dictionaries for fast resource lookups
   - Use arrays for production queues (sequential access)

## Future Extensions

### Potential Additions

1. **Market System**: Dynamic resource pricing based on supply/demand
2. **Resource Storage Limits**: Warehouses with capacity limits
3. **Resource Spoilage**: Food and medicine decay over time
4. **Advanced Trade**: Multi-faction trade networks, merchant caravans
5. **Economic Events**: Market crashes, resource discoveries, trade embargoes
6. **Wonder Projects**: Special production items with unique bonuses
7. **Resource Conversion**: Convert one resource type to another (e.g., scrap → components)

### Backwards Compatibility

When adding new features:
- New resource types should be optional (default to 0 if not present)
- New signals should be additive (don't break existing signal handlers)
- New functions should not change existing function signatures

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-12 | Initial interface definition |

## Notes for Implementers

1. **Atomic Operations**: Resource consumption must be all-or-nothing
2. **Signal Discipline**: Emit signals consistently; UI depends on them
3. **Validation**: Always validate faction IDs and resource types
4. **Documentation**: Keep inline documentation synchronized with this interface
5. **Testing**: Write tests before implementation (TDD approach preferred)
6. **Performance**: Profile production processing with large queues
7. **Save/Load**: Ensure all state is serializable to JSON

## Contact & Review

**Primary Assignee**: Agent 5
**Reviewers**: Agent 1 (Core System integration), Agent 7 (AI System integration)
**Status**: Draft - Pending Review

---

*This interface contract is a living document and should be updated as the implementation evolves.*
