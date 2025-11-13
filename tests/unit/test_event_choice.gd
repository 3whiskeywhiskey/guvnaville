extends GutTest

## Unit tests for EventChoiceResolver

var choice_resolver: EventChoiceResolver
var mock_game_state: MockGameState

func before_each():
	choice_resolver = EventChoiceResolver.new()
	mock_game_state = MockGameState.new(2)

func after_each():
	choice_resolver = null
	mock_game_state = null

func test_validate_choice_no_requirements():
	var choice = EventChoice.new("test", "Test choice")

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)

	assert_true(result["available"], "Choice with no requirements should be available")
	assert_eq(result["reason"], "", "Should have no reason when available")

func test_validate_choice_resource_requirement_met():
	var choice = EventChoice.new("test", "Test choice")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		50,
		">="
	)
	choice.requirements.append(requirement)

	mock_game_state.get_faction(0).resources["food"] = 100

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)

	assert_true(result["available"], "Choice should be available when requirements met")

func test_validate_choice_resource_requirement_not_met():
	var choice = EventChoice.new("test", "Test choice")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		50,
		">="
	)
	choice.requirements.append(requirement)

	mock_game_state.get_faction(0).resources["food"] = 20

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)

	assert_false(result["available"], "Choice should not be available when requirements not met")
	assert_ne(result["reason"], "", "Should have reason when unavailable")

func test_validate_choice_culture_requirement():
	var choice = EventChoice.new("test", "Test choice")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.CULTURE_NODE,
		"strongman_rule",
		true,
		"=="
	)
	choice.requirements.append(requirement)

	mock_game_state.get_faction(0).unlock_culture_node("strongman_rule")

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)

	assert_true(result["available"], "Choice should be available with culture node")

func test_validate_choice_building_requirement():
	var choice = EventChoice.new("test", "Test choice")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.BUILDING,
		"lab",
		1,
		">="
	)
	choice.requirements.append(requirement)

	mock_game_state.get_faction(0).add_building("lab")

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)

	assert_true(result["available"], "Choice should be available with building")

func test_validate_choice_unit_requirement():
	var choice = EventChoice.new("test", "Test choice")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.UNIT_TYPE,
		"engineer",
		1,
		">="
	)
	choice.requirements.append(requirement)

	mock_game_state.get_faction(0).add_unit("engineer")

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)

	assert_true(result["available"], "Choice should be available with unit")

func test_validate_choice_multiple_requirements():
	var choice = EventChoice.new("test", "Test choice")

	var req1 = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "food", 50, ">=")
	var req2 = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, "scrap", 100, ">=")

	choice.requirements.append(req1)
	choice.requirements.append(req2)

	# Meet only first requirement
	mock_game_state.get_faction(0).resources["food"] = 100
	mock_game_state.get_faction(0).resources["scrap"] = 50

	var result = choice_resolver.validate_choice(choice, 0, mock_game_state)
	assert_false(result["available"], "Should not be available when not all requirements met")

	# Meet both requirements
	mock_game_state.get_faction(0).resources["scrap"] = 150
	result = choice_resolver.validate_choice(choice, 0, mock_game_state)
	assert_true(result["available"], "Should be available when all requirements met")

func test_resolve_probabilistic_choice_non_probabilistic():
	var choice = EventChoice.new("test", "Test choice")
	choice.probabilistic = false

	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	)
	choice.outcomes.append(consequence)

	var selected = choice_resolver.resolve_probabilistic_choice(choice)

	assert_eq(selected.size(), 1, "Should return all outcomes for non-probabilistic")
	assert_eq(selected[0].target, "food", "Should return correct consequence")

func test_resolve_probabilistic_choice():
	var choice = EventChoice.new("test", "Test choice")
	choice.probabilistic = true
	choice.probability_weights = [0.7, 0.3]

	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	)
	choice.outcomes.append(consequence)

	var selected = choice_resolver.resolve_probabilistic_choice(choice)

	# Should return outcomes (implementation details may vary)
	assert_typeof(selected, TYPE_ARRAY, "Should return array")

func test_validate_all_choices():
	var instance = EventInstance.new(1, "test_event")
	instance.faction_id = 0

	# Add available choice
	var available_choice = EventChoice.new("c1", "Available")
	instance.choices.append(available_choice)

	# Add unavailable choice
	var unavailable_choice = EventChoice.new("c2", "Unavailable")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		1000,
		">="
	)
	unavailable_choice.requirements.append(requirement)
	instance.choices.append(unavailable_choice)

	choice_resolver.validate_all_choices(instance, 0, mock_game_state)

	assert_true(instance.choices[0].is_available, "First choice should be available")
	assert_false(instance.choices[1].is_available, "Second choice should not be available")
	assert_ne(instance.choices[1].unavailable_reason, "", "Should have unavailability reason")

func test_get_available_choices():
	var instance = EventInstance.new(1, "test_event")
	instance.faction_id = 0

	# Add available choice
	var available_choice = EventChoice.new("c1", "Available")
	instance.choices.append(available_choice)

	# Add unavailable choice
	var unavailable_choice = EventChoice.new("c2", "Unavailable")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		1000,
		">="
	)
	unavailable_choice.requirements.append(requirement)
	instance.choices.append(unavailable_choice)

	var available = choice_resolver.get_available_choices(instance, 0, mock_game_state)

	assert_eq(available.size(), 1, "Should have 1 available choice")
	assert_eq(available[0].choice_id, "c1", "Should be the first choice")

func test_ai_select_choice_prefers_positive():
	var instance = EventInstance.new(1, "test_event")
	instance.faction_id = 0

	# Add choice with negative consequence
	var bad_choice = EventChoice.new("bad", "Bad choice")
	var bad_consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		-50
	)
	bad_choice.outcomes.append(bad_consequence)
	instance.choices.append(bad_choice)

	# Add choice with positive consequence
	var good_choice = EventChoice.new("good", "Good choice")
	var good_consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		100
	)
	good_choice.outcomes.append(good_consequence)
	instance.choices.append(good_choice)

	var selected = choice_resolver.ai_select_choice(instance, 0, mock_game_state)

	# AI should prefer the positive choice (index 1)
	assert_eq(selected, 1, "AI should select the positive choice")

func test_ai_select_choice_values_units():
	var instance = EventInstance.new(1, "test_event")
	instance.faction_id = 0

	# Add choice with small resource gain
	var resource_choice = EventChoice.new("resource", "Resource choice")
	var resource_consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		10
	)
	resource_choice.outcomes.append(resource_consequence)
	instance.choices.append(resource_choice)

	# Add choice that spawns units (should be valued higher)
	var unit_choice = EventChoice.new("unit", "Unit choice")
	var unit_consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.SPAWN_UNIT,
		"soldier",
		2
	)
	unit_choice.outcomes.append(unit_consequence)
	instance.choices.append(unit_choice)

	var selected = choice_resolver.ai_select_choice(instance, 0, mock_game_state)

	# AI should prefer spawning units (valued at 20 per unit)
	assert_eq(selected, 1, "AI should prefer unit spawning")

func test_ai_select_choice_all_unavailable():
	var instance = EventInstance.new(1, "test_event")
	instance.faction_id = 0

	# Add unavailable choice
	var choice = EventChoice.new("locked", "Locked choice")
	var requirement = EventRequirement.new(
		EventRequirement.RequirementType.RESOURCE,
		"food",
		10000,
		">="
	)
	choice.requirements.append(requirement)
	instance.choices.append(choice)

	var selected = choice_resolver.ai_select_choice(instance, 0, mock_game_state)

	assert_eq(selected, -1, "Should return -1 when no choices available")

func test_ai_evaluates_morale_and_culture():
	var instance = EventInstance.new(1, "test_event")
	instance.faction_id = 0

	# Choice with morale benefit
	var morale_choice = EventChoice.new("morale", "Morale choice")
	var morale_consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.MORALE_CHANGE,
		"morale",
		10
	)
	morale_choice.outcomes.append(morale_consequence)
	instance.choices.append(morale_choice)

	# Choice with culture points
	var culture_choice = EventChoice.new("culture", "Culture choice")
	var culture_consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.CULTURE_POINTS,
		"culture",
		20
	)
	culture_choice.outcomes.append(culture_consequence)
	instance.choices.append(culture_choice)

	var selected = choice_resolver.ai_select_choice(instance, 0, mock_game_state)

	# Should select one of the positive choices
	assert_gte(selected, 0, "Should select a choice")
	assert_lt(selected, 2, "Should select valid choice index")
