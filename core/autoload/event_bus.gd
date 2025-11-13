extends Node

## EventBus - Central event bus for decoupled communication
##
## This singleton provides signals for all game systems to communicate
## without tight coupling. All modules can emit and listen to these signals.

# ============================================================================
# GAME LIFECYCLE SIGNALS
# ============================================================================

## Emitted when a new game is started
signal game_started(game_state)

## Emitted when a saved game is loaded
signal game_loaded(game_state)

## Emitted when the game ends
signal game_ended(victory_type: String, winning_faction: int)

## Emitted when the game is paused
signal game_paused()

## Emitted when the game is resumed
signal game_resumed()

# ============================================================================
# TURN MANAGEMENT SIGNALS
# ============================================================================

## Emitted when a new turn starts
signal turn_started(turn_number: int, active_faction: int)

## Emitted when the turn phase changes
signal turn_phase_changed(phase: int)

## Emitted when a turn ends
signal turn_ended(turn_number: int)

## Emitted when a faction's turn starts
signal faction_turn_started(faction_id: int)

## Emitted when a faction's turn ends
signal faction_turn_ended(faction_id: int)

# ============================================================================
# MAP & WORLD SIGNALS
# ============================================================================

## Emitted when a tile is captured by a faction
signal tile_captured(position: Vector3i, old_owner: int, new_owner: int)

## Emitted when a tile is scavenged for resources
signal tile_scavenged(position: Vector3i, resources_found: Dictionary)

## Emitted when tile visibility changes for a faction
signal tile_visibility_changed(position: Vector3i, faction_id: int, visibility_level: int)

## Emitted when a building is constructed
signal building_constructed(position: Vector3i, building_type: String, faction_id: int)

## Emitted when a building is destroyed
signal building_destroyed(position: Vector3i, building_type: String)

## Emitted when a unique location is discovered
signal unique_location_discovered(location_id: String, faction_id: int)

# ============================================================================
# UNIT SIGNALS
# ============================================================================

## Emitted when a unit is created
signal unit_created(unit_id: String, unit_type: String, faction_id: int, position: Vector3i)

## Emitted when a unit is destroyed
signal unit_destroyed(unit_id: String, faction_id: int, position: Vector3i)

## Emitted when a unit moves
signal unit_moved(unit_id: String, from_position: Vector3i, to_position: Vector3i)

## Emitted when a unit is promoted to a higher rank
signal unit_promoted(unit_id: String, new_rank: int)

## Emitted when a unit is healed
signal unit_healed(unit_id: String, amount: int)

## Emitted when a unit takes damage
signal unit_damaged(unit_id: String, amount: int)

# ============================================================================
# COMBAT SIGNALS
# ============================================================================

## Emitted when combat starts
signal combat_started(attacker_ids: Array, defender_ids: Array, position: Vector3i)

## Emitted when combat is resolved
signal combat_resolved(outcome: Dictionary)

## Emitted when a unit retreats from combat
signal unit_retreated(unit_id: String, from_position: Vector3i, to_position: Vector3i)

## Emitted when a unit's morale breaks
signal morale_broken(unit_id: String)

# ============================================================================
# RESOURCES & ECONOMY SIGNALS
# ============================================================================

## Emitted when a faction's resources change
signal resource_changed(faction_id: int, resource_type: String, amount: int, new_total: int)

## Emitted when a faction has insufficient resources
signal resource_shortage(faction_id: int, resource_type: String, deficit: int)

## Emitted when production completes
signal production_completed(faction_id: int, item_type: String, item_id: String)

## Emitted when production starts
signal production_started(faction_id: int, item_type: String)

## Emitted when a trade route is established
signal trade_route_established(faction_a: int, faction_b: int)

## Emitted when a trade route is broken
signal trade_route_broken(faction_a: int, faction_b: int)

# ============================================================================
# CULTURE SIGNALS
# ============================================================================

## Emitted when a faction gains culture points
signal culture_points_gained(faction_id: int, points: int)

## Emitted when a culture node is unlocked
signal culture_node_unlocked(faction_id: int, node_id: String, axis: String)

## Emitted when a culture bonus is applied
signal culture_bonus_applied(faction_id: int, bonus_type: String, value: float)

# ============================================================================
# EVENT SIGNALS
# ============================================================================

## Emitted when an event is triggered
signal event_triggered(event_id: String, faction_id: int)

## Emitted when a choice is made for an event
signal event_choice_made(event_id: String, choice_index: int, faction_id: int)

## Emitted when event consequences are applied
signal event_consequence_applied(event_id: String, faction_id: int, consequences: Dictionary)

# ============================================================================
# AI SIGNALS
# ============================================================================

## Emitted when AI makes a decision
signal ai_decision_made(faction_id: int, decision_type: String, details: Dictionary)

## Emitted when an AI error occurs
signal ai_error(faction_id: int, error_message: String)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# EventBus is ready
	pass
