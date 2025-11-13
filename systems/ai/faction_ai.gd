## FactionAI - High-level strategic AI controller
##
## Main AI system that coordinates strategic decision-making for AI-controlled
## factions. Combines goal planning, utility scoring, and personality-driven
## behavior to create challenging and varied AI opponents.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name FactionAI
extends RefCounted

# Preload dependencies for Godot 4.5.1 compatibility
const GoalPlanner = preload("res://systems/ai/goal_planner.gd")
const UtilityScorer = preload("res://systems/ai/utility_scorer.gd")
const TacticalAI = preload("res://systems/ai/tactical_ai.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")
const AIThreatAssessment = preload("res://systems/ai/ai_threat_assessment.gd")
const AggressivePersonality = preload("res://systems/ai/personalities/aggressive.gd")
const DefensivePersonality = preload("res://systems/ai/personalities/defensive.gd")
const EconomicPersonality = preload("res://systems/ai/personalities/economic.gd")

## Maximum time allowed for turn planning (milliseconds)
const MAX_PLANNING_TIME_MS: int = 10000

## Warning threshold for planning time (milliseconds)
const WARNING_PLANNING_TIME_MS: int = 5000

## Faction this AI controls
var _faction_id: int

## AI personality type
var _personality_type: String

## Personality class reference
var _personality: Variant

## Goal planner instance
var _goal_planner: GoalPlanner

## Utility scorer instance
var _scorer: UtilityScorer

## Tactical AI instance
var _tactical_ai: TacticalAI

## Threat assessments for other factions
var _threat_assessments: Dictionary = {}

## Last game state analyzed
var _last_game_state: Variant = null


## Constructor
##
## @param faction_id: ID of faction this AI controls
## @param personality: Personality type ("aggressive", "defensive", "economic")
func _init(faction_id: int, personality: String = "defensive") -> void:
	_faction_id = faction_id
	_personality_type = personality

	# Load personality
	_load_personality(personality)

	# Initialize subsystems
	_goal_planner = GoalPlanner.new(personality)
	_scorer = UtilityScorer.new()
	_tactical_ai = TacticalAI.new()

	# Apply personality weights
	_apply_personality_weights()


## Plans and returns all actions for the AI faction's turn
##
## This is the main entry point for AI decision-making each turn.
##
## @param faction_id: ID of the faction being controlled
## @param game_state: Current game state (read-only)
## @returns: Array of AIAction objects, sorted by priority (highest first)
func plan_turn(faction_id: int, game_state: Variant) -> Array[AIAction]:
	var start_time = Time.get_ticks_msec()

	# Validation
	if faction_id != _faction_id:
		push_warning("FactionAI: Faction ID mismatch (expected %d, got %d)" % [_faction_id, faction_id])
		return []

	if game_state == null:
		push_error("FactionAI: Null game state provided")
		return _create_fallback_actions()

	_last_game_state = game_state

	# Update strategic assessment
	_assess_threats(game_state)
	_goal_planner.update_goals(faction_id, game_state)

	# Generate action candidates
	var actions: Array[AIAction] = []
	actions.append_array(_plan_economic_actions(game_state))
	actions.append_array(_plan_military_actions(game_state))
	actions.append_array(_plan_expansion_actions(game_state))
	actions.append_array(_plan_cultural_actions(game_state))

	# Score and prioritize actions
	_score_actions(actions, game_state)

	# Sort by priority (highest first)
	actions.sort_custom(func(a, b): return a.priority > b.priority)

	# Add END_TURN action at the end
	actions.append(AIAction.new(AIAction.ActionType.END_TURN, 0.0))

	# Check performance
	var elapsed = Time.get_ticks_msec() - start_time
	if elapsed > WARNING_PLANNING_TIME_MS:
		push_warning("FactionAI: Turn planning took %d ms (faction %d)" % [elapsed, faction_id])

	if elapsed > MAX_PLANNING_TIME_MS:
		push_error("FactionAI: Turn planning exceeded maximum time (%d ms)" % elapsed)

	return actions


## Scores a single action for the given faction
##
## @param action: The action to evaluate
## @param faction_id: ID of the faction evaluating the action
## @param game_state: Current game state (read-only)
## @returns: Float score value (0.0 to 100.0, higher is better)
func score_action(action: AIAction, faction_id: int, game_state: Variant) -> float:
	if action == null or faction_id != _faction_id:
		return 0.0

	if not action.is_valid():
		return 0.0

	var base_score: float = 50.0

	# Score based on action type
	match action.type:
		AIAction.ActionType.MOVE_UNIT:
			base_score = _score_move_action(action, game_state)
		AIAction.ActionType.ATTACK:
			base_score = _score_attack_action(action, game_state)
		AIAction.ActionType.BUILD_UNIT, AIAction.ActionType.BUILD_BUILDING:
			base_score = _score_production_action(action, game_state)
		AIAction.ActionType.RESEARCH:
			base_score = _score_research_action(action, game_state)
		AIAction.ActionType.TRADE:
			base_score = _score_trade_action(action, game_state)
		AIAction.ActionType.FORTIFY:
			base_score = _score_fortify_action(action, game_state)

	# Apply personality modifiers
	base_score = _personality.modify_action_score(base_score, action.type)

	return clampf(base_score, 0.0, 100.0)


## Selects what unit or building to produce next
##
## @param faction_id: ID of the faction
## @param available_resources: Dictionary of current resource stockpiles
## @returns: String identifier of unit/building type, or "" if none affordable
func select_production(faction_id: int, available_resources: Dictionary) -> String:
	if faction_id != _faction_id or available_resources.is_empty():
		return ""

	# Get current situation assessment
	var situation = _assess_production_situation(available_resources)

	# Use personality to select production
	var production = _personality.select_production(situation)

	# Validate affordability (simplified for MVP)
	if not _can_afford_production(production, available_resources):
		return "militia"  # Fallback to cheapest unit

	return production


## Selects which culture node to unlock next
##
## @param faction_id: ID of the faction
## @param available_nodes: Array of culture node IDs that can be unlocked
## @returns: String ID of selected culture node, or "" if none desirable
func select_culture_node(faction_id: int, available_nodes: Array[String]) -> String:
	if faction_id != _faction_id or available_nodes.is_empty():
		return ""

	# Get active goals for context
	var active_goals = _goal_planner.get_active_goals(faction_id)

	# Prioritize nodes based on personality
	var prioritized = _personality.prioritize_culture_nodes(available_nodes)

	# Score each node
	var best_node: String = ""
	var best_score: float = 0.0

	for node_id in prioritized:
		var score = _scorer.score_culture_node(node_id, faction_id, active_goals)
		if score > best_score:
			best_score = score
			best_node = node_id

	return best_node if best_score > 30.0 else (prioritized[0] if not prioritized.is_empty() else "")


## Plans movement for a single unit
##
## @param unit_id: ID of the unit to move
## @param game_state: Current game state (read-only)
## @returns: Vector3i target position for unit movement
func plan_movement(unit_id: int, game_state: Variant) -> Vector3i:
	if unit_id < 0 or game_state == null:
		return Vector3i.ZERO

	# MVP: Simple movement planning
	# In production, would use pathfinding and tactical analysis

	# Mock: Move towards a random nearby position
	var direction = Vector3i(
		randi_range(-2, 2),
		randi_range(-2, 2),
		0
	)

	return direction


## Plans an attack action for a unit
##
## @param unit_id: ID of the attacking unit
## @param game_state: Current game state (read-only)
## @returns: Dictionary with attack details
func plan_attack(unit_id: int, game_state: Variant) -> Dictionary:
	if unit_id < 0 or game_state == null:
		return {"should_attack": false}

	# Mock: Evaluate potential targets
	var potential_targets = _find_nearby_enemies(unit_id, game_state)

	if potential_targets.is_empty():
		return {"should_attack": false}

	# Use tactical AI to evaluate combat
	var attacker_units = [unit_id]  # Simplified
	var defender_units = [potential_targets[0]]  # Simplified

	var evaluation = _tactical_ai.evaluate_combat_engagement(attacker_units, defender_units)

	if not evaluation.engage:
		return {"should_attack": false}

	# Select target
	var target_selection = _tactical_ai.select_attack_target(unit_id, potential_targets, game_state)

	return {
		"should_attack": target_selection.has_target,
		"target_id": target_selection.get("target_id", -1),
		"use_tactical": false,  # MVP uses auto-resolve
		"ability": ""
	}


## Sets the AI personality for this faction
##
## @param faction_id: ID of the faction
## @param personality: Personality type ("aggressive", "defensive", "economic")
func set_personality(faction_id: int, personality: String) -> void:
	if faction_id != _faction_id:
		push_warning("FactionAI: Faction ID mismatch in set_personality")
		return

	if personality not in ["aggressive", "defensive", "economic"]:
		push_warning("FactionAI: Invalid personality '%s', defaulting to 'defensive'" % personality)
		personality = "defensive"

	_personality_type = personality
	_load_personality(personality)
	_apply_personality_weights()

	if _goal_planner:
		_goal_planner.set_personality(personality)


## Loads personality class
func _load_personality(personality: String) -> void:
	match personality:
		"aggressive":
			_personality = AggressivePersonality
		"defensive":
			_personality = DefensivePersonality
		"economic":
			_personality = EconomicPersonality
		_:
			_personality = DefensivePersonality


## Applies personality weights to subsystems
func _apply_personality_weights() -> void:
	if _scorer and _personality:
		_scorer.set_personality_weights(_personality.get_weights())

	if _tactical_ai and _personality:
		var combat_threshold = _personality.get_combat_threshold()
		var risk_tolerance = _personality.get_weights().get("risk_tolerance", 0.5)
		_tactical_ai.set_risk_tolerance(risk_tolerance)


## Creates fallback actions when planning fails
func _create_fallback_actions() -> Array[AIAction]:
	var actions: Array[AIAction] = []
	actions.append(AIAction.new(AIAction.ActionType.END_TURN, 100.0))
	return actions


## Assesses threats from other factions
func _assess_threats(game_state: Variant) -> void:
	# MVP: Simple threat assessment
	# In production, would analyze faction strengths, positions, etc.

	_threat_assessments.clear()

	# Mock threat assessment for other factions
	for i in range(8):  # Assume up to 8 factions
		if i == _faction_id:
			continue

		var assessment = AIThreatAssessment.new(i)
		assessment.update_assessment(
			randf_range(30.0, 80.0),  # Military strength
			randf_range(30.0, 80.0),  # Economic strength
			randi_range(10, 100),      # Distance
			AIThreatAssessment.Relationship.NEUTRAL
		)

		_threat_assessments[i] = assessment


## Plans economic actions
func _plan_economic_actions(game_state: Variant) -> Array[AIAction]:
	var actions: Array[AIAction] = []

	# Production planning
	var resources = _get_faction_resources(game_state)
	var production_type = select_production(_faction_id, resources)

	if not production_type.is_empty():
		var action = AIAction.new(
			AIAction.ActionType.BUILD_UNIT,
			60.0,
			{"unit_type": production_type, "location": Vector3i.ZERO}
		)
		actions.append(action)

	# Scavenging actions (mock)
	if randf() < 0.3:
		var action = AIAction.new(
			AIAction.ActionType.SCAVENGE,
			40.0,
			{"target": Vector3i(randi_range(-10, 10), randi_range(-10, 10), 0)}
		)
		actions.append(action)

	return actions


## Plans military actions
func _plan_military_actions(game_state: Variant) -> Array[AIAction]:
	var actions: Array[AIAction] = []

	# Mock: Plan some unit movements and attacks
	for i in range(3):  # Mock 3 units
		var unit_id = _faction_id * 100 + i

		# Movement
		var move_target = plan_movement(unit_id, game_state)
		if move_target != Vector3i.ZERO:
			var action = AIAction.new(
				AIAction.ActionType.MOVE_UNIT,
				45.0,
				{"unit_id": unit_id, "target": move_target}
			)
			actions.append(action)

		# Attack planning
		var attack_plan = plan_attack(unit_id, game_state)
		if attack_plan.get("should_attack", false):
			var action = AIAction.new(
				AIAction.ActionType.ATTACK,
				70.0,
				attack_plan
			)
			actions.append(action)

	return actions


## Plans expansion actions
func _plan_expansion_actions(game_state: Variant) -> Array[AIAction]:
	var actions: Array[AIAction] = []

	# Check if expansion goal is active
	var has_expansion_goal = false
	for goal in _goal_planner.get_active_goals(_faction_id):
		if goal.type == AIGoal.GoalType.EXPAND_TERRITORY:
			has_expansion_goal = true
			break

	if has_expansion_goal:
		# Mock: Identify expansion target
		var target = Vector3i(randi_range(-50, 50), randi_range(-50, 50), 0)
		var score = _scorer.score_expansion(target, _faction_id, game_state)

		if score > 40.0:
			# Send scout or settler (mocked)
			var action = AIAction.new(
				AIAction.ActionType.MOVE_UNIT,
				score,
				{"unit_id": -1, "target": target, "purpose": "expansion"}
			)
			actions.append(action)

	return actions


## Plans cultural/research actions
func _plan_cultural_actions(game_state: Variant) -> Array[AIAction]:
	var actions: Array[AIAction] = []

	# Mock: Select culture node
	var available_nodes: Array[String] = ["military_doctrine", "trade_networks", "fortification_tech"]
	var selected_node = select_culture_node(_faction_id, available_nodes)

	if not selected_node.is_empty():
		var action = AIAction.new(
			AIAction.ActionType.RESEARCH,
			55.0,
			{"node_id": selected_node}
		)
		actions.append(action)

	return actions


## Scores all actions in array
func _score_actions(actions: Array[AIAction], game_state: Variant) -> void:
	for action in actions:
		if action is AIAction:
			action.priority = score_action(action, _faction_id, game_state)


## Scoring helper functions
func _score_move_action(action: AIAction, game_state: Variant) -> float:
	return 45.0 + randf_range(-10.0, 10.0)

func _score_attack_action(action: AIAction, game_state: Variant) -> float:
	return 65.0 + randf_range(-15.0, 15.0)

func _score_production_action(action: AIAction, game_state: Variant) -> float:
	var production_type = action.parameters.get("unit_type", "")
	return _scorer.score_production(production_type, _faction_id, {})

func _score_research_action(action: AIAction, game_state: Variant) -> float:
	var node_id = action.parameters.get("node_id", "")
	return _scorer.score_culture_node(node_id, _faction_id, _goal_planner.get_active_goals(_faction_id))

func _score_trade_action(action: AIAction, game_state: Variant) -> float:
	var target_faction = action.parameters.get("target_faction", -1)
	return _scorer.score_trade(target_faction, _faction_id)

func _score_fortify_action(action: AIAction, game_state: Variant) -> float:
	var location = action.parameters.get("location", Vector3i.ZERO)
	return _scorer.score_defense(location, 50.0)


## Helper functions
func _assess_production_situation(resources: Dictionary) -> Dictionary:
	return {
		"military_units_ratio": randf_range(0.3, 0.7),
		"under_attack": randf() < 0.2,
		"resources": resources,
		"trade_routes": randi_range(0, 5),
		"has_fortifications": randf() < 0.5
	}

func _can_afford_production(production_type: String, resources: Dictionary) -> bool:
	var scrap = resources.get("scrap", 0)
	return scrap > 20  # Simplified affordability check

func _get_faction_resources(game_state: Variant) -> Dictionary:
	# Mock resource retrieval
	return {
		"scrap": randi_range(50, 200),
		"food": randi_range(30, 150),
		"fuel": randi_range(10, 50),
		"ammunition": randi_range(20, 100)
	}

func _find_nearby_enemies(unit_id: int, game_state: Variant) -> Array:
	# Mock: Return some potential enemy targets
	if randf() < 0.4:
		return [randi_range(0, 100)]
	return []
