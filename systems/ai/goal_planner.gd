## GoalPlanner - Strategic goal selection and planning system
##
## Manages AI faction goals, updates priorities based on game state,
## and maintains goal stack for decision-making. Goals drive AI strategy
## and action selection.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name GoalPlanner
extends RefCounted

## Maximum number of active goals per faction
const MAX_ACTIVE_GOALS: int = 5

## Maximum turns before considering a goal stale
const STALE_GOAL_THRESHOLD: int = 50

## Active goals per faction (Dictionary[int, Array[AIGoal]])
var _faction_goals: Dictionary = {}

## Personality type for goal prioritization
var _personality_type: String = "defensive"


## Constructor
func _init(personality: String = "defensive") -> void:
	_personality_type = personality


## Updates faction's strategic goals based on current situation
##
## Analyzes faction state and adjusts goal priorities. Adds new goals,
## removes completed/stale goals, and reorders by priority.
##
## @param faction_id: ID of the faction
## @param game_state: Current game state
func update_goals(faction_id: int, game_state: Variant) -> void:
	if faction_id < 0:
		push_warning("GoalPlanner: Invalid faction_id %d" % faction_id)
		return

	# Initialize faction goals if needed
	if not _faction_goals.has(faction_id):
		_faction_goals[faction_id] = []

	var goals: Array = _faction_goals[faction_id]

	# Advance all goals by one turn
	for goal in goals:
		if goal is AIGoal:
			goal.advance_turn()

	# Remove completed and stale goals
	_remove_completed_goals(faction_id)
	_remove_stale_goals(faction_id)

	# Analyze situation and add new goals if needed
	_analyze_and_add_goals(faction_id, game_state)

	# Sort goals by priority
	goals.sort_custom(func(a, b): return a.priority > b.priority)

	# Limit number of active goals
	if goals.size() > MAX_ACTIVE_GOALS:
		goals.resize(MAX_ACTIVE_GOALS)


## Returns current active goals for a faction
##
## @param faction_id: ID of the faction
## @returns: Array of AIGoal objects, ordered by priority (high to low)
func get_active_goals(faction_id: int) -> Array[AIGoal]:
	if not _faction_goals.has(faction_id):
		return []

	var result: Array[AIGoal] = []
	for goal in _faction_goals[faction_id]:
		if goal is AIGoal:
			result.append(goal)

	return result


## Adds a new goal for a faction
##
## @param faction_id: ID of the faction
## @param goal: AIGoal to add
func add_goal(faction_id: int, goal: AIGoal) -> void:
	if not _faction_goals.has(faction_id):
		_faction_goals[faction_id] = []

	_faction_goals[faction_id].append(goal)


## Removes a specific goal
##
## @param faction_id: ID of the faction
## @param goal_type: Type of goal to remove
func remove_goal(faction_id: int, goal_type: AIGoal.GoalType) -> void:
	if not _faction_goals.has(faction_id):
		return

	var goals: Array = _faction_goals[faction_id]
	for i in range(goals.size() - 1, -1, -1):
		var goal = goals[i]
		if goal is AIGoal and goal.type == goal_type:
			goals.remove_at(i)


## Updates progress on a specific goal
##
## @param faction_id: ID of the faction
## @param goal_type: Type of goal to update
## @param progress: New progress value (0.0-1.0)
func update_goal_progress(faction_id: int, goal_type: AIGoal.GoalType, progress: float) -> void:
	if not _faction_goals.has(faction_id):
		return

	for goal in _faction_goals[faction_id]:
		if goal is AIGoal and goal.type == goal_type:
			goal.update_progress(progress)
			break


## Removes completed goals
func _remove_completed_goals(faction_id: int) -> void:
	if not _faction_goals.has(faction_id):
		return

	var goals: Array = _faction_goals[faction_id]
	for i in range(goals.size() - 1, -1, -1):
		var goal = goals[i]
		if goal is AIGoal and goal.is_complete():
			goals.remove_at(i)


## Removes stale goals (no progress for many turns)
func _remove_stale_goals(faction_id: int) -> void:
	if not _faction_goals.has(faction_id):
		return

	var goals: Array = _faction_goals[faction_id]
	for i in range(goals.size() - 1, -1, -1):
		var goal = goals[i]
		if goal is AIGoal and goal.is_stale(STALE_GOAL_THRESHOLD):
			goals.remove_at(i)


## Analyzes game state and adds appropriate goals
func _analyze_and_add_goals(faction_id: int, game_state: Variant) -> void:
	var goals: Array = _faction_goals[faction_id]

	# Ensure we always have at least one goal
	if goals.is_empty():
		_add_default_goals(faction_id)
		return

	# Check if we need more goals
	if goals.size() < 3:
		_add_situational_goals(faction_id, game_state)


## Adds default goals based on personality
func _add_default_goals(faction_id: int) -> void:
	match _personality_type:
		"aggressive":
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.MILITARY_CONQUEST, 90.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.SECURE_RESOURCE, 60.0, "ammunition"))

		"defensive":
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.DEFEND_TERRITORY, 95.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 80.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.ESTABLISH_TRADE, 70.0))

		"economic":
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 95.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.ESTABLISH_TRADE, 85.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.SECURE_RESOURCE, 70.0, "scrap"))

		_:  # Default to defensive
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.DEFEND_TERRITORY, 80.0))
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 70.0))


## Adds goals based on current situation
func _add_situational_goals(faction_id: int, game_state: Variant) -> void:
	# In MVP, use simple heuristics
	# In full implementation, would analyze game state in detail

	# Check if under threat (mock detection)
	var under_threat = randf() < 0.3
	if under_threat:
		var has_defense_goal = _has_goal_type(faction_id, AIGoal.GoalType.DEFEND_TERRITORY)
		if not has_defense_goal:
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.DEFEND_TERRITORY, 85.0))

	# Check if expansion is viable (mock detection)
	var can_expand = randf() < 0.5
	if can_expand:
		var has_expansion_goal = _has_goal_type(faction_id, AIGoal.GoalType.EXPAND_TERRITORY)
		if not has_expansion_goal:
			var priority = 60.0 if _personality_type == "aggressive" else 40.0
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, priority))

	# Economic opportunities (mock detection)
	var economic_opportunity = randf() < 0.4
	if economic_opportunity:
		var has_economic_goal = _has_goal_type(faction_id, AIGoal.GoalType.ECONOMIC_GROWTH)
		if not has_economic_goal:
			var priority = 75.0 if _personality_type == "economic" else 50.0
			add_goal(faction_id, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, priority))


## Checks if faction has a goal of specific type
func _has_goal_type(faction_id: int, goal_type: AIGoal.GoalType) -> bool:
	if not _faction_goals.has(faction_id):
		return false

	for goal in _faction_goals[faction_id]:
		if goal is AIGoal and goal.type == goal_type:
			return true

	return false


## Sets personality type for goal planning
func set_personality(personality: String) -> void:
	_personality_type = personality


## Clears all goals for a faction
func clear_goals(faction_id: int) -> void:
	if _faction_goals.has(faction_id):
		_faction_goals[faction_id].clear()
