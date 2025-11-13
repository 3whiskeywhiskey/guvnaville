extends GutTest

## Unit tests for EventTriggerEvaluator

var trigger_evaluator: EventTriggerEvaluator
var mock_game_state: MockGameState

func before_each():
	trigger_evaluator = EventTriggerEvaluator.new()
	mock_game_state = MockGameState.new(2)

func after_each():
	trigger_evaluator = null
	mock_game_state = null

func test_resource_requirement_met():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		50,
		">="
	)

	mock_game_state.get_faction(0).resources["food"] = 100

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Resource requirement should be met")

func test_resource_requirement_not_met():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		50,
		">="
	)

	mock_game_state.get_faction(0).resources["food"] = 20

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_false(result, "Resource requirement should not be met")

func test_culture_node_requirement():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.CULTURE_NODE,
		"strongman_rule",
		true,
		"=="
	)

	mock_game_state.get_faction(0).unlock_culture_node("strongman_rule")

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Culture node requirement should be met")

func test_culture_node_requirement_not_met():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.CULTURE_NODE,
		"strongman_rule",
		true,
		"=="
	)

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_false(result, "Culture node requirement should not be met")

func test_building_requirement():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.BUILDING,
		"lab",
		1,
		">="
	)

	mock_game_state.get_faction(0).add_building("lab")

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Building requirement should be met")

func test_unit_type_requirement():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.UNIT_TYPE,
		"engineer",
		1,
		">="
	)

	mock_game_state.get_faction(0).add_unit("engineer")

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Unit type requirement should be met")

func test_territory_size_requirement():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.TERRITORY_SIZE,
		"territory",
		10,
		">="
	)

	mock_game_state.get_faction(0).territory_size = 15

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Territory size requirement should be met")

func test_turn_number_requirement():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.TURN_NUMBER,
		"turn",
		10,
		">="
	)

	mock_game_state.current_turn = 15

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Turn number requirement should be met")

func test_turn_number_requirement_not_met():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.TURN_NUMBER,
		"turn",
		10,
		">="
	)

	mock_game_state.current_turn = 5

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_false(result, "Turn number requirement should not be met")

func test_custom_flag_requirement():
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.CUSTOM_FLAG,
		"at_war",
		true,
		"=="
	)

	mock_game_state.get_faction(0).at_war = true

	var result = trigger_evaluator.check_requirement(requirement, 0, mock_game_state)
	assert_true(result, "Custom flag requirement should be met")

func test_comparison_operators():
	# Test >= operator
	var req_gte = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 50, ">=")
	mock_game_state.get_faction(0).resources["food"] = 50
	assert_true(trigger_evaluator.check_requirement(req_gte, 0, mock_game_state), ">= should work with equal values")

	# Test > operator
	var req_gt = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 50, ">")
	mock_game_state.get_faction(0).resources["food"] = 51
	assert_true(trigger_evaluator.check_requirement(req_gt, 0, mock_game_state), "> should work")

	# Test <= operator
	var req_lte = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 100, "<=")
	mock_game_state.get_faction(0).resources["food"] = 50
	assert_true(trigger_evaluator.check_requirement(req_lte, 0, mock_game_state), "<= should work")

	# Test == operator
	var req_eq = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 50, "==")
	mock_game_state.get_faction(0).resources["food"] = 50
	assert_true(trigger_evaluator.check_requirement(req_eq, 0, mock_game_state), "== should work")

	# Test != operator
	var req_ne = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 100, "!=")
	mock_game_state.get_faction(0).resources["food"] = 50
	assert_true(trigger_evaluator.check_requirement(req_ne, 0, mock_game_state), "!= should work")

func test_rarity_system():
	# Test multiple rolls to verify probabilities (statistical test)
	var common_successes = 0
	var rare_successes = 0
	var trials = 1000

	for i in range(trials):
		if trigger_evaluator.roll_rarity("common"):
			common_successes += 1
		if trigger_evaluator.roll_rarity("rare"):
			rare_successes += 1

	# Common should pass ~60% of the time
	var common_rate = float(common_successes) / float(trials)
	assert_gt(common_rate, 0.50, "Common should pass at least 50% of the time")
	assert_lt(common_rate, 0.70, "Common should pass less than 70% of the time")

	# Rare should pass ~12% of the time
	var rare_rate = float(rare_successes) / float(trials)
	assert_gt(rare_rate, 0.05, "Rare should pass at least 5% of the time")
	assert_lt(rare_rate, 0.20, "Rare should pass less than 20% of the time")

func test_evaluate_triggers_simple():
	var event_def = EventDefinition.new("test_event")
	event_def.rarity = "common"

	# Empty triggers should always pass (subject to rarity)
	var can_trigger = trigger_evaluator.evaluate_triggers(event_def, 0, mock_game_state)
	# Result is probabilistic, just ensure no crash
	assert_typeof(can_trigger, TYPE_BOOL, "Should return boolean")

func test_evaluate_triggers_with_conditions():
	var event_def = EventDefinition.new("test_event")
	event_def.rarity = "common"

	var trigger = EventTrigger.new(EventTrigger.TriggerType.RANDOM_CHANCE, 1.0)
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		50,
		">="
	)
	trigger.conditions.append(requirement)
	event_def.triggers.append(trigger)

	# Set up faction to meet requirement
	mock_game_state.get_faction(0).resources["food"] = 100

	# Should have a chance to trigger
	var triggered_once = false
	for i in range(100):  # Multiple attempts due to rarity
		if trigger_evaluator.evaluate_triggers(event_def, 0, mock_game_state):
			triggered_once = true
			break

	assert_true(triggered_once, "Event should trigger at least once with met conditions")

func test_evaluate_triggers_unmet_conditions():
	var event_def = EventDefinition.new("test_event")
	event_def.rarity = "common"

	var trigger = EventTrigger.new(EventTrigger.TriggerType.RANDOM_CHANCE, 1.0)
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		1000,
		">="
	)
	trigger.conditions.append(requirement)
	event_def.triggers.append(trigger)

	# Faction doesn't have enough food
	mock_game_state.get_faction(0).resources["food"] = 10

	# Should never trigger with unmet conditions
	var triggered = false
	for i in range(100):
		if trigger_evaluator.evaluate_triggers(event_def, 0, mock_game_state):
			triggered = true
			break

	assert_false(triggered, "Event should not trigger with unmet conditions")

func test_multiple_conditions_all_required():
	var trigger = EventTrigger.new(EventTrigger.TriggerType.RANDOM_CHANCE, 1.0)

	var req1 = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 50, ">=")
	var req2 = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "scrap", 100, ">=")

	trigger.conditions.append(req1)
	trigger.conditions.append(req2)

	# Meet only first requirement
	mock_game_state.get_faction(0).resources["food"] = 100
	mock_game_state.get_faction(0).resources["scrap"] = 50

	var event_def = EventDefinition.new("test")
	event_def.rarity = "common"
	event_def.triggers.append(trigger)

	# Should not trigger (second requirement not met)
	var triggered = false
	for i in range(100):
		if trigger_evaluator.evaluate_triggers(event_def, 0, mock_game_state):
			triggered = true
			break

	assert_false(triggered, "Should not trigger when not all requirements are met")

	# Now meet both requirements
	mock_game_state.get_faction(0).resources["scrap"] = 150

	# Should trigger now
	var triggered_with_both = false
	for i in range(100):
		if trigger_evaluator.evaluate_triggers(event_def, 0, mock_game_state):
			triggered_with_both = true
			break

	assert_true(triggered_with_both, "Should trigger when all requirements are met")
