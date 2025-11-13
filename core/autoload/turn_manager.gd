extends Node

## TurnManager - Manages turn-based game loop and turn phases
##
## This singleton orchestrates the turn-based gameplay, managing turn phases
## and processing turns for all factions.

# ============================================================================
# ENUMS
# ============================================================================

enum TurnPhase {
	MOVEMENT,       ## Units can move
	COMBAT,         ## Combat resolution
	ECONOMY,        ## Resource collection and production
	CULTURE,        ## Culture point accumulation
	EVENTS,         ## Event processing
	END_TURN        ## Cleanup and preparation for next turn
}

# ============================================================================
# PROPERTIES
# ============================================================================

## Current turn phase
var current_phase: int = TurnPhase.MOVEMENT

## Currently active faction ID
var active_faction: int = 0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	pass

# ============================================================================
# TURN PROCESSING
# ============================================================================

## Process a complete turn for all factions
func process_turn() -> void:
	# Get game state from GameManager
	if not GameManager or not GameManager.current_state:
		push_error("[TurnManager] No active game state")
		return

	var game_state = GameManager.current_state

	print("[TurnManager] Processing turn %d" % game_state.turn_number)

	# Get all alive factions
	var alive_factions = game_state.get_alive_factions()

	# Process turn for each faction
	for faction in alive_factions:
		_process_faction_turn(faction.faction_id)

	# Increment turn counter
	game_state.turn_number += 1
	game_state.turn_state.current_turn = game_state.turn_number

	# Reset turn state for new turn
	game_state.turn_state.reset_for_new_turn()

	# Emit turn ended signal
	EventBus.turn_ended.emit(game_state.turn_number - 1)

	print("[TurnManager] Turn %d completed" % (game_state.turn_number - 1))

	# Check victory conditions
	_check_victory_conditions()

## Process a single faction's turn through all phases
func _process_faction_turn(faction_id: int) -> void:
	active_faction = faction_id

	print("[TurnManager] Processing turn for faction %d" % faction_id)

	# Emit faction turn started
	EventBus.faction_turn_started.emit(faction_id)

	# Get game state
	var game_state = GameManager.current_state
	if not game_state:
		return

	# Update turn state
	game_state.turn_state.active_faction = faction_id

	# Emit turn started signal
	EventBus.turn_started.emit(game_state.turn_number, faction_id)

	# Process each phase
	var phases = [
		TurnPhase.MOVEMENT,
		TurnPhase.COMBAT,
		TurnPhase.ECONOMY,
		TurnPhase.CULTURE,
		TurnPhase.EVENTS,
		TurnPhase.END_TURN
	]

	for phase in phases:
		process_phase(phase, faction_id)

	# Emit faction turn ended
	EventBus.faction_turn_ended.emit(faction_id)

## Process a specific turn phase for a faction
func process_phase(phase: int, faction_id: int) -> void:
	current_phase = phase

	# Update turn state
	if GameManager and GameManager.current_state:
		GameManager.current_state.turn_state.current_phase = phase

	# Emit phase changed signal
	EventBus.turn_phase_changed.emit(phase)

	# Process phase-specific logic
	match phase:
		TurnPhase.MOVEMENT:
			_process_movement_phase(faction_id)
		TurnPhase.COMBAT:
			_process_combat_phase(faction_id)
		TurnPhase.ECONOMY:
			_process_economy_phase(faction_id)
		TurnPhase.CULTURE:
			_process_culture_phase(faction_id)
		TurnPhase.EVENTS:
			_process_events_phase(faction_id)
		TurnPhase.END_TURN:
			_process_end_turn_phase(faction_id)

## End the current faction's turn
func end_faction_turn(faction_id: int) -> void:
	print("[TurnManager] Ending turn for faction %d" % faction_id)
	EventBus.faction_turn_ended.emit(faction_id)

## Skip a phase (for debugging/testing)
func skip_phase(phase: int) -> void:
	print("[TurnManager] Skipping phase: %d" % phase)
	current_phase = (phase + 1) % (TurnPhase.END_TURN + 1)

# ============================================================================
# PHASE PROCESSING
# ============================================================================

func _process_movement_phase(faction_id: int) -> void:
	# Movement phase logic will be implemented by the unit system
	# For now, just log
	pass

func _process_combat_phase(faction_id: int) -> void:
	# Combat phase logic will be implemented by the combat system
	# For now, just log
	pass

func _process_economy_phase(faction_id: int) -> void:
	# Economy phase logic
	if not GameManager or not GameManager.current_state:
		return

	var game_state = GameManager.current_state
	var faction = game_state.get_faction(faction_id)

	if not faction:
		return

	# Simple resource generation per turn
	var resource_gain = {
		"scrap": 10,
		"food": 5,
		"ammo": 3
	}

	for resource_type in resource_gain:
		var amount = resource_gain[resource_type]
		faction.add_resource(resource_type, amount)
		EventBus.resource_changed.emit(
			faction_id,
			resource_type,
			amount,
			faction.get_resource(resource_type)
		)

func _process_culture_phase(faction_id: int) -> void:
	# Culture phase logic
	if not GameManager or not GameManager.current_state:
		return

	var game_state = GameManager.current_state
	var faction = game_state.get_faction(faction_id)

	if not faction:
		return

	# Simple culture point generation
	var culture_gain = faction.culture.get("points_per_turn", 1)
	faction.add_culture_points(culture_gain)

	if culture_gain > 0:
		EventBus.culture_points_gained.emit(faction_id, culture_gain)

func _process_events_phase(faction_id: int) -> void:
	# Process any pending events for this faction
	if not GameManager or not GameManager.current_state:
		return

	var game_state = GameManager.current_state

	# Check event queue for faction-specific events
	# Event system will be implemented later
	pass

func _process_end_turn_phase(faction_id: int) -> void:
	# Cleanup and preparation for next turn
	# Reset unit movement points, etc.
	pass

# ============================================================================
# VICTORY CONDITIONS
# ============================================================================

func _check_victory_conditions() -> void:
	if not GameManager or not GameManager.current_state:
		return

	var game_state = GameManager.current_state

	# Check if game is over
	if game_state.is_game_over():
		var winner = game_state.get_winner()
		if winner:
			print("[TurnManager] Victory! Faction %d (%s) wins!" % [winner.faction_id, winner.faction_name])
			GameManager.end_game("military", winner.faction_id)
		else:
			print("[TurnManager] Game over with no winner")
			GameManager.end_game("none", -1)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Get the name of a turn phase
static func get_phase_name(phase: int) -> String:
	match phase:
		TurnPhase.MOVEMENT:
			return "Movement"
		TurnPhase.COMBAT:
			return "Combat"
		TurnPhase.ECONOMY:
			return "Economy"
		TurnPhase.CULTURE:
			return "Culture"
		TurnPhase.EVENTS:
			return "Events"
		TurnPhase.END_TURN:
			return "End Turn"
		_:
			return "Unknown"
