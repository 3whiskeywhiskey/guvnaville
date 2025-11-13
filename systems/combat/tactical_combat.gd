class_name TacticalCombat
extends Node

## Tactical battle engine (stub for MVP - full implementation post-MVP)
##
## This class provides the interface for tactical turn-based combat.
## In MVP, it redirects to auto-resolve. Full tactical combat will be
## implemented in a later phase.

## Battle state enum
enum BattleState {
	NOT_STARTED,
	DEPLOYMENT,
	IN_PROGRESS,
	ENDED
}

## Turn phase enum
enum TurnPhase {
	PLAYER_TURN,
	ENEMY_TURN,
	ROUND_END
}

## Singleton instance
static var instance: TacticalCombat = null

## Current battle state
var battle_state: BattleState = BattleState.NOT_STARTED

## Current turn phase
var turn_phase: TurnPhase = TurnPhase.PLAYER_TURN

## Current round number
var current_round: int = 0

## Battle ID
var battle_id: String = ""

## Attacker units
var attackers: Array = []

## Defender units
var defenders: Array = []

## Battle location
var location: Vector3i = Vector3i.ZERO

## Tactical map (20x20 subset of strategic map)
var tactical_map: Array = []


func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()


## Starts a tactical battle (stub - redirects to auto-resolve in MVP)
##
## @param p_attackers: Attacking units
## @param p_defenders: Defending units
## @param p_location: Battle location
## @param p_map_subset: Tactical map tiles
## @return: Battle ID
func start_battle(
	p_attackers: Array,
	p_defenders: Array,
	p_location: Vector3i,
	p_map_subset: Array = []
) -> String:
	# Generate battle ID
	battle_id = "tactical_battle_%d" % Time.get_ticks_msec()

	# Store battle parameters
	attackers = p_attackers.duplicate()
	defenders = p_defenders.duplicate()
	location = p_location
	tactical_map = p_map_subset.duplicate()

	# Set battle state
	battle_state = BattleState.DEPLOYMENT

	push_warning("TacticalCombat: Full tactical combat not implemented in MVP")
	push_warning("TacticalCombat: Redirecting to auto-resolve")

	# Emit battle started event (stub)
	# EventBus.emit_signal("tactical_combat_started", battle_id, attackers, defenders)

	# For MVP, immediately auto-resolve
	_auto_resolve_stub()

	return battle_id


## Auto-resolve stub for MVP
func _auto_resolve_stub() -> void:
	# Get terrain from tactical map (or use default)
	var terrain: Dictionary = {}
	if not tactical_map.is_empty() and tactical_map[0] is Dictionary:
		terrain = tactical_map[0]

	# Call auto-resolve
	var result = CombatResolver.resolve_combat(attackers, defenders, location, terrain)

	# Update battle state
	battle_state = BattleState.ENDED

	# Emit battle ended event (stub)
	# EventBus.emit_signal("tactical_combat_ended", battle_id, result)

	print("TacticalCombat: Battle auto-resolved with outcome: %s" % CombatResult.CombatOutcome.keys()[result.outcome])


## Deploys units on tactical map (stub - not implemented)
##
## @param unit: Unit to deploy
## @param position: Deployment position
## @return: True if successful
func deploy_unit(unit: Dictionary, position: Vector3i) -> bool:
	push_warning("TacticalCombat.deploy_unit: Not implemented in MVP")
	return false


## Executes a unit action (stub - not implemented)
##
## @param unit_id: Unit performing action
## @param action_type: Type of action (move, attack, etc.)
## @param target: Action target (position or unit)
## @return: True if successful
func execute_action(unit_id: String, action_type: String, target) -> bool:
	push_warning("TacticalCombat.execute_action: Not implemented in MVP")
	return false


## Moves a unit on tactical map (stub - not implemented)
##
## @param unit_id: Unit to move
## @param path: Path to follow
## @return: True if successful
func move_unit(unit_id: String, path: Array) -> bool:
	push_warning("TacticalCombat.move_unit: Not implemented in MVP")
	return false


## Attacks with a unit (stub - not implemented)
##
## @param attacker_id: Attacking unit
## @param defender_id: Defending unit
## @return: Damage dealt
func attack_unit(attacker_id: String, defender_id: String) -> int:
	push_warning("TacticalCombat.attack_unit: Not implemented in MVP")
	return 0


## Uses unit special ability (stub - not implemented)
##
## @param unit_id: Unit using ability
## @param ability_id: Ability to use
## @param target: Ability target
## @return: True if successful
func use_ability(unit_id: String, ability_id: String, target) -> bool:
	push_warning("TacticalCombat.use_ability: Not implemented in MVP")
	return false


## Ends current turn (stub - not implemented)
func end_turn() -> void:
	push_warning("TacticalCombat.end_turn: Not implemented in MVP")

	# Advance turn phase
	match turn_phase:
		TurnPhase.PLAYER_TURN:
			turn_phase = TurnPhase.ENEMY_TURN
		TurnPhase.ENEMY_TURN:
			turn_phase = TurnPhase.ROUND_END
		TurnPhase.ROUND_END:
			current_round += 1
			turn_phase = TurnPhase.PLAYER_TURN


## Gets valid movement positions for a unit (stub - not implemented)
##
## @param unit_id: Unit to check
## @return: Array of valid positions
func get_valid_movement_positions(unit_id: String) -> Array:
	push_warning("TacticalCombat.get_valid_movement_positions: Not implemented in MVP")
	return []


## Gets valid attack targets for a unit (stub - not implemented)
##
## @param unit_id: Unit to check
## @return: Array of valid target unit IDs
func get_valid_attack_targets(unit_id: String) -> Array:
	push_warning("TacticalCombat.get_valid_attack_targets: Not implemented in MVP")
	return []


## Checks if unit can act this turn (stub - not implemented)
##
## @param unit_id: Unit to check
## @return: True if can act
func can_unit_act(unit_id: String) -> bool:
	push_warning("TacticalCombat.can_unit_act: Not implemented in MVP")
	return false


## Gets battle status summary (stub - not implemented)
##
## @return: Battle status dictionary
func get_battle_status() -> Dictionary:
	return {
		"battle_id": battle_id,
		"state": BattleState.keys()[battle_state],
		"turn_phase": TurnPhase.keys()[turn_phase],
		"current_round": current_round,
		"attackers_alive": attackers.size(),
		"defenders_alive": defenders.size(),
		"location": location
	}


## Retreats from tactical battle (stub - not implemented)
##
## @param retreating_side: "attacker" or "defender"
## @return: True if successful
func retreat_from_battle(retreating_side: String) -> bool:
	push_warning("TacticalCombat.retreat_from_battle: Not implemented in MVP")

	# For MVP, treat as combat loss and auto-resolve with retreat outcome
	battle_state = BattleState.ENDED

	var result = CombatResult.new()
	result.outcome = CombatResult.CombatOutcome.RETREAT
	result.location = location

	# Emit battle ended event (stub)
	# EventBus.emit_signal("tactical_combat_ended", battle_id, result)

	return true


## Cleans up battle resources
func cleanup_battle() -> void:
	battle_id = ""
	attackers.clear()
	defenders.clear()
	tactical_map.clear()
	location = Vector3i.ZERO
	battle_state = BattleState.NOT_STARTED
	turn_phase = TurnPhase.PLAYER_TURN
	current_round = 0


## Gets combat preview for UI (stub - not implemented)
##
## @param attacker_id: Attacking unit
## @param defender_id: Defending unit
## @return: Preview data
func get_combat_preview(attacker_id: String, defender_id: String) -> Dictionary:
	push_warning("TacticalCombat.get_combat_preview: Not implemented in MVP")
	return {
		"hit_chance": 0.75,
		"damage_estimate": 20,
		"retaliation_damage": 10,
		"attacker_morale": 50,
		"defender_morale": 50
	}


## Checks victory conditions (stub - not implemented)
##
## @return: "attacker", "defender", or "" if ongoing
func check_victory_condition() -> String:
	if defenders.is_empty():
		return "attacker"
	elif attackers.is_empty():
		return "defender"
	else:
		return ""
