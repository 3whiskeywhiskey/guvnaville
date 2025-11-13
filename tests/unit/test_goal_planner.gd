extends GutTest

## Unit tests for GoalPlanner
## Tests strategic goal management and planning
##
## @agent: Agent 7

var planner: GoalPlanner

func before_each():
	planner = GoalPlanner.new("defensive")

func after_each():
	planner = null

func test_planner_creation():
	assert_not_null(planner, "GoalPlanner should be created")

func test_initial_goals_empty():
	var goals = planner.get_active_goals(1)
	assert_eq(goals.size(), 0, "Faction should have no goals initially")

func test_add_goal():
	var goal = AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0)
	planner.add_goal(1, goal)

	var goals = planner.get_active_goals(1)
	assert_eq(goals.size(), 1, "Faction should have 1 goal after adding")
	assert_eq(goals[0].type, AIGoal.GoalType.EXPAND_TERRITORY, "Goal type should match")

func test_add_multiple_goals():
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0))
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 80.0))
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.DEFEND_TERRITORY, 90.0))

	var goals = planner.get_active_goals(1)
	assert_eq(goals.size(), 3, "Faction should have 3 goals")

func test_remove_goal():
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0))
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 80.0))

	planner.remove_goal(1, AIGoal.GoalType.EXPAND_TERRITORY)

	var goals = planner.get_active_goals(1)
	assert_eq(goals.size(), 1, "Should have 1 goal after removing")
	assert_eq(goals[0].type, AIGoal.GoalType.ECONOMIC_GROWTH, "Remaining goal should be ECONOMIC_GROWTH")

func test_update_goal_progress():
	var goal = AIGoal.new(AIGoal.GoalType.MILITARY_CONQUEST, 85.0)
	planner.add_goal(1, goal)

	planner.update_goal_progress(1, AIGoal.GoalType.MILITARY_CONQUEST, 0.6)

	var goals = planner.get_active_goals(1)
	assert_eq(goals[0].progress, 0.6, "Goal progress should be updated to 0.6")

func test_update_goals_advances_turns():
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0))

	var goals_before = planner.get_active_goals(1)
	var turns_before = goals_before[0].turns_active

	planner.update_goals(1, null)

	var goals_after = planner.get_active_goals(1)
	var turns_after = goals_after[0].turns_active

	assert_eq(turns_after, turns_before + 1, "Goal turns should be advanced by 1")

func test_update_goals_removes_completed():
	var goal = AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 80.0)
	goal.update_progress(1.0)  # Mark as complete
	planner.add_goal(1, goal)

	assert_eq(planner.get_active_goals(1).size(), 1, "Should have 1 goal before update")

	planner.update_goals(1, null)

	assert_eq(planner.get_active_goals(1).size(), 0, "Completed goal should be removed")

func test_update_goals_removes_stale():
	var goal = AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0)
	planner.add_goal(1, goal)

	# Advance goal many turns without progress
	for i in range(60):
		goal.advance_turn()

	planner.update_goals(1, null)

	# Stale goal should be removed
	assert_eq(planner.get_active_goals(1).size(), 0, "Stale goal should be removed")

func test_update_goals_adds_default_if_empty():
	# Start with no goals
	assert_eq(planner.get_active_goals(1).size(), 0, "Should start with no goals")

	planner.update_goals(1, null)

	# Default goals should be added
	assert_gt(planner.get_active_goals(1).size(), 0, "Default goals should be added")

func test_update_goals_limits_max_goals():
	# Add many goals
	for i in range(10):
		planner.add_goal(1, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 50.0 + i))

	planner.update_goals(1, null)

	# Should be limited to MAX_ACTIVE_GOALS
	assert_le(planner.get_active_goals(1).size(), 5, "Should be limited to 5 active goals")

func test_update_goals_sorts_by_priority():
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 50.0))
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 80.0))
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.DEFEND_TERRITORY, 90.0))

	planner.update_goals(1, null)

	var goals = planner.get_active_goals(1)
	assert_ge(goals[0].priority, goals[1].priority, "Goals should be sorted by priority (descending)")
	assert_ge(goals[1].priority, goals[2].priority, "Goals should be sorted by priority (descending)")

func test_personality_affects_default_goals():
	var aggressive_planner = GoalPlanner.new("aggressive")
	var defensive_planner = GoalPlanner.new("defensive")
	var economic_planner = GoalPlanner.new("economic")

	aggressive_planner.update_goals(1, null)
	defensive_planner.update_goals(2, null)
	economic_planner.update_goals(3, null)

	var agg_goals = aggressive_planner.get_active_goals(1)
	var def_goals = defensive_planner.get_active_goals(2)
	var eco_goals = economic_planner.get_active_goals(3)

	# All should have goals
	assert_gt(agg_goals.size(), 0, "Aggressive should have goals")
	assert_gt(def_goals.size(), 0, "Defensive should have goals")
	assert_gt(eco_goals.size(), 0, "Economic should have goals")

	# Aggressive should prioritize military
	var has_military = false
	for goal in agg_goals:
		if goal.type == AIGoal.GoalType.MILITARY_CONQUEST:
			has_military = true
			break
	assert_true(has_military, "Aggressive should have military conquest goal")

	# Defensive should prioritize defense
	var has_defense = false
	for goal in def_goals:
		if goal.type == AIGoal.GoalType.DEFEND_TERRITORY:
			has_defense = true
			break
	assert_true(has_defense, "Defensive should have defend territory goal")

	# Economic should prioritize economy
	var has_economy = false
	for goal in eco_goals:
		if goal.type == AIGoal.GoalType.ECONOMIC_GROWTH:
			has_economy = true
			break
	assert_true(has_economy, "Economic should have economic growth goal")

func test_clear_goals():
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY, 70.0))
	planner.add_goal(1, AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH, 80.0))

	assert_eq(planner.get_active_goals(1).size(), 2, "Should have 2 goals")

	planner.clear_goals(1)

	assert_eq(planner.get_active_goals(1).size(), 0, "Should have 0 goals after clear")

func test_set_personality():
	planner.set_personality("aggressive")
	# Personality change should not crash
	assert_not_null(planner, "Planner should still exist after personality change")
