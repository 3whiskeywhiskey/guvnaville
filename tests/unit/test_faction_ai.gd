extends GutTest

## Unit tests for FactionAI
## Tests main AI controller and decision-making
##
## @agent: Agent 7

var ai: FactionAI
var mock_game_state: Dictionary

func before_each():
	ai = FactionAI.new(1, "aggressive")
	mock_game_state = _create_mock_game_state()

func after_each():
	ai = null
	mock_game_state = {}

func _create_mock_game_state() -> Dictionary:
	return {
		"turn": 10,
		"factions": {
			1: {
				"resources": {
					"scrap": 100,
					"food": 50,
					"fuel": 20
				}
			}
		}
	}

func test_faction_ai_creation():
	assert_not_null(ai, "FactionAI should be created")

func test_plan_turn_returns_actions():
	var actions = ai.plan_turn(1, mock_game_state)

	assert_not_null(actions, "Should return actions array")
	assert_gt(actions.size(), 0, "Should return at least one action (END_TURN)")

func test_plan_turn_last_action_is_end_turn():
	var actions = ai.plan_turn(1, mock_game_state)

	var last_action = actions[actions.size() - 1]
	assert_eq(last_action.type, AIAction.ActionType.END_TURN, "Last action should be END_TURN")

func test_plan_turn_invalid_faction():
	var actions = ai.plan_turn(999, mock_game_state)

	assert_eq(actions.size(), 0, "Should return empty array for wrong faction ID")

func test_plan_turn_null_state():
	var actions = ai.plan_turn(1, null)

	# Should return fallback actions (END_TURN)
	assert_gt(actions.size(), 0, "Should return fallback actions for null state")
	assert_eq(actions[0].type, AIAction.ActionType.END_TURN, "Fallback should be END_TURN")

func test_plan_turn_actions_are_sorted():
	var actions = ai.plan_turn(1, mock_game_state)

	# Actions should be sorted by priority (descending), except END_TURN at end
	for i in range(actions.size() - 2):
		assert_ge(actions[i].priority, actions[i + 1].priority,
			"Actions should be sorted by priority (descending)")

func test_score_action_valid_action():
	var action = AIAction.new(AIAction.ActionType.MOVE_UNIT, 50.0, {"unit_id": 1, "target": Vector3i.ZERO})
	var score = ai.score_action(action, 1, mock_game_state)

	assert_ge(score, 0.0, "Score should be >= 0")
	assert_le(score, 100.0, "Score should be <= 100")

func test_score_action_invalid_action():
	var invalid_action = AIAction.new(AIAction.ActionType.MOVE_UNIT, 50.0, {})  # Missing required params
	var score = ai.score_action(invalid_action, 1, mock_game_state)

	assert_eq(score, 0.0, "Invalid action should score 0")

func test_score_action_wrong_faction():
	var action = AIAction.new(AIAction.ActionType.ATTACK, 50.0, {"unit_id": 1, "target_id": 2})
	var score = ai.score_action(action, 999, mock_game_state)

	assert_eq(score, 0.0, "Wrong faction ID should return 0")

func test_select_production():
	var resources = {"scrap": 100, "food": 50, "fuel": 20, "ammunition": 30}
	var production = ai.select_production(1, resources)

	assert_ne(production, "", "Should select production type")
	# Should be a valid unit/building type
	assert_true(production is String, "Production should be a string")

func test_select_production_empty_resources():
	var production = ai.select_production(1, {})

	# Should return empty or fallback
	assert_true(production is String, "Production should be a string")

func test_select_production_wrong_faction():
	var resources = {"scrap": 100}
	var production = ai.select_production(999, resources)

	assert_eq(production, "", "Wrong faction should return empty string")

func test_select_culture_node():
	var available_nodes: Array[String] = ["military_doctrine", "trade_networks", "defensive_tech"]
	var selected = ai.select_culture_node(1, available_nodes)

	# Should select one of the available nodes or empty
	assert_true(selected in available_nodes or selected == "", "Should select valid node or empty")

func test_select_culture_node_empty_array():
	var available_nodes: Array[String] = []
	var selected = ai.select_culture_node(1, available_nodes)

	assert_eq(selected, "", "Should return empty for empty array")

func test_plan_movement():
	var target = ai.plan_movement(1, mock_game_state)

	assert_not_null(target, "Should return Vector3i target")
	# Target could be anything including ZERO
	assert_true(target is Vector3i, "Target should be Vector3i")

func test_plan_movement_invalid_unit():
	var target = ai.plan_movement(-1, mock_game_state)

	assert_eq(target, Vector3i.ZERO, "Invalid unit should return ZERO")

func test_plan_attack():
	var attack_plan = ai.plan_attack(1, mock_game_state)

	assert_not_null(attack_plan, "Should return attack plan dictionary")
	assert_true(attack_plan.has("should_attack"), "Should have 'should_attack' key")

func test_plan_attack_invalid_unit():
	var attack_plan = ai.plan_attack(-1, mock_game_state)

	assert_false(attack_plan.get("should_attack", false), "Invalid unit should not attack")

func test_set_personality():
	ai.set_personality(1, "defensive")

	# Personality change should not crash
	var actions = ai.plan_turn(1, mock_game_state)
	assert_gt(actions.size(), 0, "Should still plan actions after personality change")

func test_set_personality_invalid():
	ai.set_personality(1, "invalid_personality")

	# Should default to defensive
	var actions = ai.plan_turn(1, mock_game_state)
	assert_gt(actions.size(), 0, "Should still work with invalid personality")

func test_set_personality_wrong_faction():
	ai.set_personality(999, "economic")

	# Should not crash, but won't change personality
	var actions = ai.plan_turn(1, mock_game_state)
	assert_gt(actions.size(), 0, "Should still work after failed personality change")

func test_different_personalities_behave_differently():
	var aggressive_ai = FactionAI.new(1, "aggressive")
	var defensive_ai = FactionAI.new(2, "defensive")
	var economic_ai = FactionAI.new(3, "economic")

	var agg_actions = aggressive_ai.plan_turn(1, mock_game_state)
	var def_actions = defensive_ai.plan_turn(2, mock_game_state)
	var eco_actions = economic_ai.plan_turn(3, mock_game_state)

	# All should return actions
	assert_gt(agg_actions.size(), 0, "Aggressive should plan actions")
	assert_gt(def_actions.size(), 0, "Defensive should plan actions")
	assert_gt(eco_actions.size(), 0, "Economic should plan actions")

	# Specific behavior differences are tested in personality tests
	# Here we just verify they all work

func test_ai_doesnt_crash_with_many_turns():
	# Run AI for multiple turns to test stability
	for turn in range(10):
		var actions = ai.plan_turn(1, mock_game_state)
		assert_gt(actions.size(), 0, "AI should plan actions on turn %d" % turn)

func test_action_types_variety():
	var actions = ai.plan_turn(1, mock_game_state)

	# Should generate various action types (not just END_TURN)
	var has_non_end_turn = false
	for action in actions:
		if action.type != AIAction.ActionType.END_TURN:
			has_non_end_turn = true
			break

	assert_true(has_non_end_turn, "Should generate actions beyond END_TURN")
