extends GutTest

## Unit tests for EventConsequenceApplicator

var consequence_applicator: EventConsequenceApplicator
var mock_game_state: MockGameState

func before_each():
	consequence_applicator = EventConsequenceApplicator.new()
	mock_game_state = MockGameState.new(2)

func after_each():
	consequence_applicator = null
	mock_game_state = null

func test_apply_resource_change_positive():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	)

	var initial = mock_game_state.get_faction(0).resources["food"]
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should apply successfully")
	assert_eq(result["type"], EventConsequence.ConsequenceType.RESOURCE_CHANGE)
	assert_eq(result["value"], 50, "Should add 50")

	var new_value = mock_game_state.get_faction(0).resources["food"]
	assert_eq(new_value, initial + 50, "Food should increase by 50")

func test_apply_resource_change_negative():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		-30
	)

	var initial = mock_game_state.get_faction(0).resources["food"]
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should apply successfully")

	var new_value = mock_game_state.get_faction(0).resources["food"]
	assert_eq(new_value, initial - 30, "Food should decrease by 30")

func test_apply_resource_change_cannot_go_negative():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		-1000
	)

	consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	var new_value = mock_game_state.get_faction(0).resources["food"]
	assert_eq(new_value, 0, "Food should not go below 0")

func test_apply_resource_change_new_resource():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"uranium",
		25
	)

	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should create new resource")
	assert_eq(mock_game_state.get_faction(0).resources["uranium"], 25, "Should have new resource")

func test_apply_spawn_unit():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.SPAWN_UNIT,
		"soldier",
		3
	)

	var initial_units = mock_game_state.get_faction(0).units.size()
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should spawn units successfully")
	assert_eq(result["value"], 3, "Should spawn 3 units")

	var new_count = mock_game_state.get_faction(0).units.size()
	assert_eq(new_count, initial_units + 3, "Should have 3 more units")

func test_apply_morale_change():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.MORALE_CHANGE,
		"morale",
		15
	)

	mock_game_state.get_faction(0).morale = 50
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should change morale successfully")
	assert_eq(mock_game_state.get_faction(0).morale, 65, "Morale should increase to 65")

func test_apply_morale_change_clamped_at_100():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.MORALE_CHANGE,
		"morale",
		100
	)

	mock_game_state.get_faction(0).morale = 80
	consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_eq(mock_game_state.get_faction(0).morale, 100, "Morale should be clamped at 100")

func test_apply_morale_change_clamped_at_0():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.MORALE_CHANGE,
		"morale",
		-100
	)

	mock_game_state.get_faction(0).morale = 30
	consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_eq(mock_game_state.get_faction(0).morale, 0, "Morale should be clamped at 0")

func test_apply_culture_points():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.CULTURE_POINTS,
		"technology",
		25
	)

	mock_game_state.get_faction(0).culture_points = 10
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should add culture points successfully")
	assert_eq(mock_game_state.get_faction(0).culture_points, 35, "Culture points should increase to 35")

func test_apply_relationship_change():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RELATIONSHIP_CHANGE,
		"reputation",
		10
	)

	mock_game_state.get_faction(0).reputation = 0
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should change reputation successfully")
	assert_eq(mock_game_state.get_faction(0).reputation, 10, "Reputation should increase to 10")

func test_apply_queue_event():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.QUEUE_EVENT,
		"follow_up_event",
		2
	)

	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should queue event successfully")
	assert_eq(mock_game_state.queued_events.size(), 1, "Should have 1 queued event")
	assert_eq(mock_game_state.queued_events[0]["event_id"], "follow_up_event", "Should queue correct event")
	assert_eq(mock_game_state.queued_events[0]["delay_turns"], 2, "Should have correct delay")

func test_apply_set_flag():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.SET_FLAG,
		"test_flag",
		true
	)

	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should set flag successfully")
	assert_eq(mock_game_state.get_faction(0).flags["test_flag"], true, "Flag should be set")

func test_apply_set_flag_narrative():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.SET_FLAG,
		"narrative",
		"This is a narrative text"
	)

	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should handle narrative successfully")
	assert_eq(result["narrative"], "This is a narrative text", "Should return narrative text")

func test_apply_add_building():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.ADD_BUILDING,
		"factory",
		1
	)

	var initial_buildings = mock_game_state.get_faction(0).buildings.size()
	var result = consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(result["success"], "Should add building successfully")
	assert_eq(mock_game_state.get_faction(0).buildings.size(), initial_buildings + 1, "Should have one more building")

	var last_building = mock_game_state.get_faction(0).buildings[-1]
	assert_eq(last_building["type"], "factory", "Should be a factory")

func test_apply_consequences_multiple():
	var consequences: Array[EventConsequence] = []

	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	))
	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.MORALE_CHANGE,
		"morale",
		10
	))
	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.SPAWN_UNIT,
		"soldier",
		2
	))

	var initial_food = mock_game_state.get_faction(0).resources["food"]
	var initial_morale = mock_game_state.get_faction(0).morale
	var initial_units = mock_game_state.get_faction(0).units.size()

	var results = consequence_applicator.apply_consequences(consequences, 0, mock_game_state)

	assert_true(results["success"], "Should apply all consequences successfully")
	assert_eq(results["applied"].size(), 3, "Should have 3 applied consequences")

	# Verify all changes
	assert_eq(mock_game_state.get_faction(0).resources["food"], initial_food + 50, "Food should increase")
	assert_eq(mock_game_state.get_faction(0).morale, initial_morale + 10, "Morale should increase")
	assert_eq(mock_game_state.get_faction(0).units.size(), initial_units + 2, "Should have 2 more units")

func test_validate_consequences():
	var consequences: Array[EventConsequence] = []
	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	))

	var valid = consequence_applicator.validate_consequences(consequences, 0, mock_game_state)

	assert_true(valid, "Consequences should be valid")

func test_validate_consequences_invalid_faction():
	var consequences: Array[EventConsequence] = []
	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	))

	var valid = consequence_applicator.validate_consequences(consequences, 999, mock_game_state)

	assert_false(valid, "Should be invalid for non-existent faction")

func test_consequence_signal_emitted():
	var consequence = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	)

	var signal_received = false
	var received_type = ""
	var received_target = ""
	var received_value = null

	consequence_applicator.consequence_applied.connect(func(type, target, value):
		signal_received = true
		received_type = type
		received_target = target
		received_value = value
	)

	consequence_applicator.apply_consequence(consequence, 0, mock_game_state)

	assert_true(signal_received, "Should emit consequence_applied signal")
	assert_eq(received_target, "food", "Should emit correct target")
	assert_eq(received_value, 50, "Should emit correct value")

func test_apply_consequences_collects_narrative():
	var consequences: Array[EventConsequence] = []

	var cons1 = EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	)
	cons1.description = "You found food!"
	consequences.append(cons1)

	var cons2 = EventConsequence.new(
		EventConsequence.ConsequenceType.SET_FLAG,
		"narrative",
		"A narrative event occurred."
	)
	consequences.append(cons2)

	var results = consequence_applicator.apply_consequences(consequences, 0, mock_game_state)

	assert_true(results.has("narrative"), "Should have narrative field")
	assert_ne(results["narrative"], "", "Narrative should not be empty")

func test_apply_multiple_resource_changes():
	var consequences: Array[EventConsequence] = []

	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"food",
		50
	))
	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"scrap",
		100
	))
	consequences.append(EventConsequence.new(
		EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"medicine",
		25
	))

	var initial_food = mock_game_state.get_faction(0).resources["food"]
	var initial_scrap = mock_game_state.get_faction(0).resources["scrap"]
	var initial_medicine = mock_game_state.get_faction(0).resources["medicine"]

	var results = consequence_applicator.apply_consequences(consequences, 0, mock_game_state)

	assert_true(results["success"], "Should apply all resource changes")
	assert_eq(mock_game_state.get_faction(0).resources["food"], initial_food + 50)
	assert_eq(mock_game_state.get_faction(0).resources["scrap"], initial_scrap + 100)
	assert_eq(mock_game_state.get_faction(0).resources["medicine"], initial_medicine + 25)
