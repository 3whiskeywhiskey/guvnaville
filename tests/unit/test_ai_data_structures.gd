extends GutTest

## Unit tests for AI data structures
## Tests AIAction, AIGoal, and AIThreatAssessment classes
##
## @agent: Agent 7

func before_all():
	gut.p("=== AI Data Structures Tests ===")

func test_ai_action_creation():
	var action = AIAction.new(AIAction.ActionType.MOVE_UNIT, 75.0, {"unit_id": 1, "target": Vector3i(10, 20, 0)})

	assert_not_null(action, "AIAction should be created")
	assert_eq(action.type, AIAction.ActionType.MOVE_UNIT, "Action type should be MOVE_UNIT")
	assert_eq(action.priority, 75.0, "Priority should be 75.0")
	assert_true(action.parameters.has("unit_id"), "Should have unit_id parameter")
	assert_true(action.parameters.has("target"), "Should have target parameter")

func test_ai_action_priority_clamping():
	var action1 = AIAction.new(AIAction.ActionType.ATTACK, 150.0)
	var action2 = AIAction.new(AIAction.ActionType.ATTACK, -50.0)

	assert_eq(action1.priority, 100.0, "Priority should be clamped to 100.0")
	assert_eq(action2.priority, 0.0, "Priority should be clamped to 0.0")

func test_ai_action_validation():
	# Valid actions
	var move_action = AIAction.new(AIAction.ActionType.MOVE_UNIT, 50.0, {"unit_id": 1, "target": Vector3i.ZERO})
	assert_true(move_action.is_valid(), "Move action with required params should be valid")

	var attack_action = AIAction.new(AIAction.ActionType.ATTACK, 50.0, {"unit_id": 1, "target_id": 2})
	assert_true(attack_action.is_valid(), "Attack action with required params should be valid")

	var end_turn = AIAction.new(AIAction.ActionType.END_TURN)
	assert_true(end_turn.is_valid(), "END_TURN action should always be valid")

	# Invalid actions
	var invalid_move = AIAction.new(AIAction.ActionType.MOVE_UNIT, 50.0, {"unit_id": 1})  # Missing target
	assert_false(invalid_move.is_valid(), "Move action without target should be invalid")

	var invalid_attack = AIAction.new(AIAction.ActionType.ATTACK, 50.0, {"unit_id": 1})  # Missing target_id
	assert_false(invalid_attack.is_valid(), "Attack action without target_id should be invalid")

func test_ai_action_to_string():
	var action = AIAction.new(AIAction.ActionType.BUILD_UNIT, 60.0, {"unit_type": "soldier"})
	var str_repr = action.to_string()

	assert_true("BUILD_UNIT" in str_repr, "String representation should include action type")
	assert_true("60.0" in str_repr or "60" in str_repr, "String representation should include priority")

func test_ai_goal_creation():
	var goal = AIGoal.new(AIGoal.GoalType.MILITARY_CONQUEST, 80.0, 5)

	assert_not_null(goal, "AIGoal should be created")
	assert_eq(goal.type, AIGoal.GoalType.MILITARY_CONQUEST, "Goal type should be MILITARY_CONQUEST")
	assert_eq(goal.priority, 80.0, "Priority should be 80.0")
	assert_eq(goal.target, 5, "Target should be 5")
	assert_eq(goal.progress, 0.0, "Initial progress should be 0.0")
	assert_eq(goal.turns_active, 0, "Initial turns_active should be 0")

func test_ai_goal_advance_turn():
	var goal = AIGoal.new(AIGoal.GoalType.EXPAND_TERRITORY)

	assert_eq(goal.turns_active, 0, "Initial turns should be 0")

	goal.advance_turn()
	assert_eq(goal.turns_active, 1, "Turns should be 1 after one advance")

	goal.advance_turn()
	goal.advance_turn()
	assert_eq(goal.turns_active, 3, "Turns should be 3 after three advances")

func test_ai_goal_progress_update():
	var goal = AIGoal.new(AIGoal.GoalType.ECONOMIC_GROWTH)

	goal.update_progress(0.5)
	assert_eq(goal.progress, 0.5, "Progress should be 0.5")

	goal.update_progress(1.2)  # Over 1.0
	assert_eq(goal.progress, 1.0, "Progress should be clamped to 1.0")

	goal.update_progress(-0.5)  # Negative
	assert_eq(goal.progress, 0.0, "Progress should be clamped to 0.0")

func test_ai_goal_completion():
	var goal = AIGoal.new(AIGoal.GoalType.DEFEND_TERRITORY)

	assert_false(goal.is_complete(), "Goal should not be complete initially")

	goal.update_progress(0.5)
	assert_false(goal.is_complete(), "Goal should not be complete at 50%")

	goal.update_progress(1.0)
	assert_true(goal.is_complete(), "Goal should be complete at 100%")

func test_ai_goal_staleness():
	var goal = AIGoal.new(AIGoal.GoalType.ESTABLISH_TRADE)

	# Not stale initially
	assert_false(goal.is_stale(50), "Goal should not be stale initially")

	# Advance many turns with no progress
	for i in range(60):
		goal.advance_turn()

	assert_true(goal.is_stale(50), "Goal should be stale after 60 turns with no progress")

	# But not stale if making progress
	goal.update_progress(0.5)
	assert_false(goal.is_stale(50), "Goal should not be stale if making progress")

func test_threat_assessment_creation():
	var threat = AIThreatAssessment.new(5)

	assert_not_null(threat, "AIThreatAssessment should be created")
	assert_eq(threat.faction_id, 5, "Faction ID should be 5")
	assert_eq(threat.military_strength, 50.0, "Default military strength should be 50.0")
	assert_eq(threat.economic_strength, 50.0, "Default economic strength should be 50.0")
	assert_eq(threat.relationship, AIThreatAssessment.Relationship.NEUTRAL, "Default relationship should be NEUTRAL")

func test_threat_assessment_update():
	var threat = AIThreatAssessment.new(3)

	threat.update_assessment(80.0, 60.0, 15, AIThreatAssessment.Relationship.HOSTILE)

	assert_eq(threat.military_strength, 80.0, "Military strength should be updated")
	assert_eq(threat.economic_strength, 60.0, "Economic strength should be updated")
	assert_eq(threat.distance, 15, "Distance should be updated")
	assert_eq(threat.relationship, AIThreatAssessment.Relationship.HOSTILE, "Relationship should be HOSTILE")

func test_threat_level_calculation():
	var threat = AIThreatAssessment.new(2)

	# High military, close distance, hostile = high threat
	threat.update_assessment(90.0, 50.0, 5, AIThreatAssessment.Relationship.HOSTILE)
	assert_gt(threat.threat_level, 70.0, "Threat level should be high for strong, close, hostile faction")

	# Low military, far distance, ally = low threat
	threat.update_assessment(20.0, 30.0, 100, AIThreatAssessment.Relationship.ALLY)
	assert_lt(threat.threat_level, 30.0, "Threat level should be low for weak, distant ally")

func test_threat_assessment_major_threat():
	var threat = AIThreatAssessment.new(4)

	threat.update_assessment(95.0, 80.0, 8, AIThreatAssessment.Relationship.HOSTILE)
	assert_true(threat.is_major_threat(), "Should be major threat with high threat level")

	threat.update_assessment(30.0, 40.0, 50, AIThreatAssessment.Relationship.NEUTRAL)
	assert_false(threat.is_major_threat(), "Should not be major threat with low threat level")

func test_threat_assessment_hostility():
	var threat = AIThreatAssessment.new(6)

	threat.update_assessment(70.0, 60.0, 15, AIThreatAssessment.Relationship.HOSTILE)
	assert_true(threat.is_hostile(), "Should be hostile with HOSTILE relationship")

	threat.update_assessment(95.0, 80.0, 5, AIThreatAssessment.Relationship.NEUTRAL)
	assert_true(threat.is_hostile(), "Should be hostile with very high threat level even if neutral")

	threat.update_assessment(40.0, 50.0, 30, AIThreatAssessment.Relationship.FRIENDLY)
	assert_false(threat.is_hostile(), "Should not be hostile with friendly relationship and low threat")

func test_threat_assessment_action_recording():
	var threat = AIThreatAssessment.new(7)

	threat.record_action("Attacked our border")
	threat.record_action("Captured our city")
	threat.record_action("Demanded tribute")

	assert_eq(threat.recent_actions.size(), 3, "Should have 3 recorded actions")
	assert_true("Attacked our border" in threat.recent_actions, "Should contain first action")

	# Record many actions (should keep only last 10)
	for i in range(15):
		threat.record_action("Action %d" % i)

	assert_eq(threat.recent_actions.size(), 10, "Should keep only last 10 actions")
	assert_false("Attacked our border" in threat.recent_actions, "Old actions should be removed")
