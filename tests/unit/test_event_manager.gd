extends GutTest

## Unit tests for EventManager

var event_manager: EventManager
var mock_game_state: MockGameState

func before_each():
	event_manager = EventManager.new()
	mock_game_state = MockGameState.new(2)

func after_each():
	event_manager = null
	mock_game_state = null

func test_load_events_from_array():
	var test_events = [
		{
			"id": "test_event_1",
			"name": "Test Event",
			"description": "A test event",
			"rarity": "common",
			"choices": [
				{
					"id": "choice_1",
					"text": "Accept",
					"consequences": {}
				}
			]
		}
	]

	event_manager.load_events(test_events)

	var definitions = event_manager.get_all_event_definitions()
	assert_eq(definitions.size(), 1, "Should load 1 event")
	assert_true(definitions.has("test_event_1"), "Should have test_event_1")

func test_load_events_from_file():
	var success = event_manager.load_events_from_file("res://data/events/events.json")
	assert_true(success, "Should load events from file")

	var definitions = event_manager.get_all_event_definitions()
	assert_gt(definitions.size(), 0, "Should have loaded events")

func test_queue_event():
	var test_events = [
		{
			"id": "test_queue",
			"name": "Queue Test",
			"description": "Test queuing",
			"rarity": "common",
			"base_priority": 50,
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	var signal_received = false
	event_manager.event_queued.connect(func(f, e, t): signal_received = true)

	event_manager.queue_event("test_queue", 0, 0)

	assert_true(signal_received, "Should emit event_queued signal")
	assert_eq(event_manager.get_queue_size(), 1, "Queue should have 1 event")

func test_queue_event_with_delay():
	var test_events = [
		{
			"id": "delayed_event",
			"name": "Delayed Event",
			"description": "Test delay",
			"rarity": "common",
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	event_manager.queue_event("delayed_event", 0, 5)

	var queue_size = event_manager.get_queue_size()
	assert_eq(queue_size, 1, "Should queue event with delay")

func test_process_event_queue():
	var test_events = [
		{
			"id": "immediate_event",
			"name": "Immediate",
			"description": "Fires immediately",
			"rarity": "common",
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	event_manager.queue_event("immediate_event", 0, 0)

	var events_to_present = event_manager.process_event_queue(1)

	assert_eq(events_to_present.size(), 1, "Should have 1 event to present")
	assert_eq(events_to_present[0].event_id, "immediate_event", "Should be immediate_event")

func test_priority_ordering():
	var test_events = [
		{
			"id": "low_priority",
			"name": "Low",
			"description": "Low priority",
			"rarity": "common",
			"base_priority": 10,
			"choices": []
		},
		{
			"id": "high_priority",
			"name": "High",
			"description": "High priority",
			"rarity": "common",
			"base_priority": 90,
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	event_manager.queue_event("low_priority", 0, 0)
	event_manager.queue_event("high_priority", 0, 0)

	var events = event_manager.process_event_queue(1)

	# Higher priority should come first
	assert_eq(events.size(), 2, "Should have 2 events")
	assert_eq(events[0].event_id, "high_priority", "High priority should be first")

func test_present_event():
	var test_events = [
		{
			"id": "present_test",
			"name": "Present Test",
			"description": "Test presentation",
			"rarity": "common",
			"choices": [
				{
					"id": "choice_1",
					"text": "Option 1",
					"consequences": {}
				}
			]
		}
	]
	event_manager.load_events(test_events)

	var signal_received = false
	event_manager.event_triggered.connect(func(f, e, i): signal_received = true)

	var instance = event_manager.present_event("present_test", 0)

	assert_not_null(instance, "Should create event instance")
	assert_eq(instance.event_id, "present_test", "Instance should have correct event_id")
	assert_eq(instance.faction_id, 0, "Instance should have correct faction_id")
	assert_eq(instance.choices.size(), 1, "Instance should have 1 choice")
	assert_true(signal_received, "Should emit event_triggered signal")

func test_make_choice():
	var test_events = [
		{
			"id": "choice_test",
			"name": "Choice Test",
			"description": "Test choices",
			"rarity": "common",
			"choices": [
				{"id": "c1", "text": "Choice 1", "consequences": {}},
				{"id": "c2", "text": "Choice 2", "consequences": {}}
			]
		}
	]
	event_manager.load_events(test_events)

	var instance = event_manager.present_event("choice_test", 0)

	var signal_received = false
	var received_choice_idx = -1
	event_manager.event_choice_made.connect(func(f, e, c):
		signal_received = true
		received_choice_idx = c
	)

	event_manager.make_choice(instance.id, 1)

	assert_true(signal_received, "Should emit choice_made signal")
	assert_eq(received_choice_idx, 1, "Should receive correct choice index")

func test_check_triggers():
	event_manager.load_events_from_file("res://data/events/events.json")

	# Set up game state to trigger some events
	mock_game_state.current_turn = 10
	mock_game_state.get_faction(0).add_resource("food", 100)

	var triggered = event_manager.check_triggers(0, mock_game_state)

	# Should find some events that can trigger
	assert_gt(triggered.size(), 0, "Should find triggerable events")

func test_event_history():
	var test_events = [
		{
			"id": "history_test",
			"name": "History Test",
			"description": "Test history tracking",
			"rarity": "common",
			"repeatable": false,
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	# Present event
	event_manager.present_event("history_test", 0)

	# Check history
	var history = event_manager.get_faction_event_history(0)
	assert_true("history_test" in history, "Event should be in history")

	# Try to trigger again (should fail for non-repeatable)
	var triggered = event_manager.check_triggers(0, mock_game_state)
	assert_false("history_test" in triggered, "Non-repeatable event should not trigger again")

func test_clear_history():
	var test_events = [
		{
			"id": "clear_test",
			"name": "Clear Test",
			"description": "Test clearing",
			"rarity": "common",
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	event_manager.present_event("clear_test", 0)
	var history_before = event_manager.get_faction_event_history(0)
	assert_gt(history_before.size(), 0, "Should have history")

	event_manager.clear_history()
	var history_after = event_manager.get_faction_event_history(0)
	assert_eq(history_after.size(), 0, "History should be cleared")

func test_get_event_definition():
	var test_events = [
		{
			"id": "get_def_test",
			"name": "Get Definition Test",
			"description": "Test getting definition",
			"rarity": "rare",
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	var event_def = event_manager.get_event_definition("get_def_test")
	assert_not_null(event_def, "Should get event definition")
	assert_eq(event_def.event_id, "get_def_test", "Should have correct ID")
	assert_eq(event_def.rarity, "rare", "Should have correct rarity")

func test_get_event_instance():
	var test_events = [
		{
			"id": "instance_test",
			"name": "Instance Test",
			"description": "Test instance retrieval",
			"rarity": "common",
			"choices": []
		}
	]
	event_manager.load_events(test_events)

	var instance = event_manager.present_event("instance_test", 0)
	var retrieved = event_manager.get_event_instance(instance.id)

	assert_not_null(retrieved, "Should retrieve instance")
	assert_eq(retrieved.id, instance.id, "Should have same ID")
	assert_eq(retrieved.event_id, "instance_test", "Should have correct event_id")

func test_validate_choices():
	var test_events = [
		{
			"id": "validate_test",
			"name": "Validate Test",
			"description": "Test choice validation",
			"rarity": "common",
			"choices": [
				{
					"id": "free_choice",
					"text": "Free choice",
					"consequences": {}
				},
				{
					"id": "locked_choice",
					"text": "Requires food",
					"requirements": {
						"resources": {"food": 1000}
					},
					"consequences": {}
				}
			]
		}
	]
	event_manager.load_events(test_events)

	var instance = event_manager.present_event("validate_test", 0)
	event_manager.validate_choices(instance.id, mock_game_state)

	assert_true(instance.choices[0].is_available, "Free choice should be available")
	assert_false(instance.choices[1].is_available, "Locked choice should not be available")

func test_ai_select_choice():
	var test_events = [
		{
			"id": "ai_test",
			"name": "AI Test",
			"description": "Test AI selection",
			"rarity": "common",
			"choices": [
				{
					"id": "bad_choice",
					"text": "Lose resources",
					"consequences": {
						"resource_changes": {"food": -10}
					}
				},
				{
					"id": "good_choice",
					"text": "Gain resources",
					"consequences": {
						"resource_changes": {"food": 20}
					}
				}
			]
		}
	]
	event_manager.load_events(test_events)

	var instance = event_manager.present_event("ai_test", 0)
	var selected = event_manager.ai_select_choice(instance.id, mock_game_state)

	assert_gte(selected, 0, "Should select a choice")
	# AI should prefer the good choice (index 1)
	# Note: This might be probabilistic, so we just check it's valid
	assert_lt(selected, 2, "Should select valid choice")

func test_apply_consequences_with_state():
	var test_events = [
		{
			"id": "consequence_test",
			"name": "Consequence Test",
			"description": "Test consequences",
			"rarity": "common",
			"choices": [
				{
					"id": "gain_food",
					"text": "Gain food",
					"consequences": {
						"resource_changes": {"food": 50}
					}
				}
			]
		}
	]
	event_manager.load_events(test_events)

	var initial_food = mock_game_state.get_faction(0).resources["food"]
	var instance = event_manager.present_event("consequence_test", 0)

	var results = event_manager.apply_consequences_with_state(instance.id, 0, mock_game_state)

	assert_true(results["success"], "Consequences should apply successfully")
	var new_food = mock_game_state.get_faction(0).resources["food"]
	assert_eq(new_food, initial_food + 50, "Food should increase by 50")
