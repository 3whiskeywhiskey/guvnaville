extends RefCounted
class_name GameState

## GameState - Main game state container
##
## The central state object that contains all game information including
## world state, factions, turn information, and game settings.

# ============================================================================
# PRELOADED CLASSES (for Godot 4.5.1 compatibility)
# ============================================================================

const _WorldState = preload("res://core/state/world_state.gd")
const _FactionState = preload("res://core/state/faction_state.gd")
const _TurnState = preload("res://core/state/turn_state.gd")

# ============================================================================
# PROPERTIES
# ============================================================================

## Current turn number
var turn_number: int = 1

## World and map state
var world_state = null

## All faction states
var factions: Array = []

## Current turn state
var turn_state = null

## Pending events queue
var event_queue: Array = []

## Victory condition tracking
var victory_conditions: Dictionary = {
	"military_progress": 0,
	"cultural_progress": 0,
	"technological_progress": 0,
	"diplomatic_progress": 0,
	"survival_progress": 0
}

## Game configuration settings
var game_settings: Dictionary = {}

## Random seed for deterministic replay
var random_seed: int = 0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	world_state = _WorldState.new()
	turn_state = _TurnState.new()

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize game state to dictionary
func to_dict() -> Dictionary:
	# Serialize factions
	var factions_data = []
	for faction in factions:
		factions_data.append(faction.to_dict())

	return {
		"turn_number": turn_number,
		"world_state": world_state.to_dict() if world_state else {},
		"factions": factions_data,
		"turn_state": turn_state.to_dict() if turn_state else {},
		"event_queue": event_queue.duplicate(true),
		"victory_conditions": victory_conditions.duplicate(),
		"game_settings": game_settings.duplicate(true),
		"random_seed": random_seed
	}

## Deserialize game state from dictionary
func from_dict(data: Dictionary) -> void:
	turn_number = data.get("turn_number", 1)
	random_seed = data.get("random_seed", 0)
	event_queue = data.get("event_queue", []).duplicate(true)
	victory_conditions = data.get("victory_conditions", {}).duplicate()
	game_settings = data.get("game_settings", {}).duplicate(true)

	# Deserialize world state
	if data.has("world_state"):
		world_state = _WorldState.new()
		world_state.from_dict(data["world_state"])
	else:
		world_state = _WorldState.new()

	# Deserialize turn state
	if data.has("turn_state"):
		turn_state = _TurnState.new()
		turn_state.from_dict(data["turn_state"])
	else:
		turn_state = _TurnState.new()

	# Deserialize factions
	factions.clear()
	var factions_data = data.get("factions", [])
	for faction_data in factions_data:
		var faction = _FactionState.new()
		faction.from_dict(faction_data)
		factions.append(faction)

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

## Deep clone the game state for simulation
func clone():
	var new_state = get_script().new()
	new_state.from_dict(to_dict())
	return new_state

## Validate state integrity
func validate() -> bool:
	# Check basic state
	if turn_number < 1:
		push_error("Invalid turn number: %d" % turn_number)
		return false

	if world_state == null:
		push_error("World state is null")
		return false

	if turn_state == null:
		push_error("Turn state is null")
		return false

	if factions.is_empty():
		push_error("No factions in game state")
		return false

	# Check faction IDs are unique
	var faction_ids = []
	for faction in factions:
		if faction.faction_id in faction_ids:
			push_error("Duplicate faction ID: %d" % faction.faction_id)
			return false
		faction_ids.append(faction.faction_id)

	# All checks passed
	return true

## Get faction by ID
func get_faction(faction_id: int):
	for faction in factions:
		if faction.faction_id == faction_id:
			return faction
	return null

## Add a faction
func add_faction(faction) -> void:
	if get_faction(faction.faction_id) == null:
		factions.append(faction)

## Remove a faction
func remove_faction(faction_id: int) -> void:
	for i in range(factions.size()):
		if factions[i].faction_id == faction_id:
			factions.remove_at(i)
			return

## Get player faction
func get_player_faction():
	for faction in factions:
		if faction.is_player:
			return faction
	return null

## Get all AI factions
func get_ai_factions() -> Array:
	var ai_factions: Array = []
	for faction in factions:
		if not faction.is_player:
			ai_factions.append(faction)
	return ai_factions

## Get alive factions
func get_alive_factions() -> Array:
	var alive: Array = []
	for faction in factions:
		if faction.is_alive:
			alive.append(faction)
	return alive

## Check if game is over
func is_game_over() -> bool:
	var alive_factions = get_alive_factions()
	return alive_factions.size() <= 1

## Get game winner
func get_winner():
	var alive_factions = get_alive_factions()
	if alive_factions.size() == 1:
		return alive_factions[0]
	return null

# ============================================================================
# EVENT QUEUE
# ============================================================================

## Add an event to the queue
func queue_event(event: Dictionary) -> void:
	event_queue.append(event)

## Get next event from queue
func pop_event() -> Dictionary:
	if event_queue.is_empty():
		return {}
	return event_queue.pop_front()

## Check if there are pending events
func has_pending_events() -> bool:
	return not event_queue.is_empty()

## Clear event queue
func clear_event_queue() -> void:
	event_queue.clear()
