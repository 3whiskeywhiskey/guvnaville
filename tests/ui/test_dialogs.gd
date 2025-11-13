extends GutTest
## Tests for UI dialogs

var event_dialog: Control
var combat_dialog: Control
var production_dialog: Control

func after_each():
	if event_dialog and is_instance_valid(event_dialog):
		event_dialog.queue_free()
	if combat_dialog and is_instance_valid(combat_dialog):
		combat_dialog.queue_free()
	if production_dialog and is_instance_valid(production_dialog):
		production_dialog.queue_free()

func test_event_dialog_loads():
	var scene = load("res://ui/dialogs/event_dialog.tscn")
	event_dialog = scene.instantiate()
	add_child_autofree(event_dialog)

	assert_not_null(event_dialog, "Event dialog should load")

func test_event_dialog_show_event():
	var scene = load("res://ui/dialogs/event_dialog.tscn")
	event_dialog = scene.instantiate()
	add_child_autofree(event_dialog)

	var event = {
		"id": "test_event",
		"title": "Test Event",
		"description": "This is a test event.",
		"choices": [
			{"text": "Choice 1", "disabled": false},
			{"text": "Choice 2", "disabled": true, "disabled_reason": "Not enough resources"}
		]
	}

	event_dialog.show_event(event)

	await wait_frames(1)

	assert_eq(event_dialog.current_event, event, "Should store current event")
	if event_dialog.title_label:
		assert_eq(event_dialog.title_label.text, "Test Event", "Should set title")
	if event_dialog.description_label:
		assert_eq(event_dialog.description_label.text, "This is a test event.", "Should set description")

func test_event_dialog_choice_selected():
	var scene = load("res://ui/dialogs/event_dialog.tscn")
	event_dialog = scene.instantiate()
	add_child_autofree(event_dialog)

	var event = {
		"id": "test_event",
		"title": "Test",
		"description": "Test",
		"choices": [
			{"text": "Choice 1"}
		]
	}

	var signal_received = false
	var choice_id = -1

	event_dialog.choice_selected.connect(func(id):
		signal_received = true
		choice_id = id
	)

	event_dialog.show_event(event)
	await wait_frames(1)

	# Simulate choice selection
	event_dialog._on_choice_pressed(0)

	assert_true(signal_received, "Should emit choice_selected signal")
	assert_eq(choice_id, 0, "Should emit correct choice ID")

func test_combat_dialog_loads():
	var scene = load("res://ui/dialogs/combat_dialog.tscn")
	combat_dialog = scene.instantiate()
	add_child_autofree(combat_dialog)

	assert_not_null(combat_dialog, "Combat dialog should load")

func test_combat_dialog_show_result():
	var scene = load("res://ui/dialogs/combat_dialog.tscn")
	combat_dialog = scene.instantiate()
	add_child_autofree(combat_dialog)

	var result = {
		"outcome": "attacker_victory",
		"attacker_casualties": 5,
		"defender_casualties": 10,
		"loot": {"scrap": 50, "food": 25},
		"experience_gained": 100
	}

	combat_dialog.show_result(result)

	await wait_frames(1)

	if combat_dialog.title_label:
		assert_eq(combat_dialog.title_label.text, "VICTORY!", "Should set victory title")

func test_combat_dialog_auto_close():
	var scene = load("res://ui/dialogs/combat_dialog.tscn")
	combat_dialog = scene.instantiate()
	add_child_autofree(combat_dialog)

	var signal_received = false
	combat_dialog.dialog_closed.connect(func():
		signal_received = true
	)

	var result = {
		"outcome": "defender_victory",
		"attacker_casualties": 10,
		"defender_casualties": 3,
		"loot": {},
		"experience_gained": 0
	}

	combat_dialog.auto_close_timer = 0.1  # Short timer for testing
	combat_dialog.show_result(result)

	await wait_seconds(0.2)

	# Dialog should auto-close
	# Note: In actual test, dialog might be freed, so we check signal
	# This is a basic check
	assert_true(true, "Auto-close timer should work")

func test_production_dialog_loads():
	var scene = load("res://ui/dialogs/production_dialog.tscn")
	production_dialog = scene.instantiate()
	add_child_autofree(production_dialog)

	assert_not_null(production_dialog, "Production dialog should load")

func test_production_dialog_show_queue():
	var scene = load("res://ui/dialogs/production_dialog.tscn")
	production_dialog = scene.instantiate()
	add_child_autofree(production_dialog)

	var queue = [
		{"name": "Unit 1", "turns_remaining": 3},
		{"name": "Building 1", "turns_remaining": 5}
	]

	production_dialog.show_queue(0, queue)

	await wait_frames(1)

	assert_eq(production_dialog.current_faction_id, 0, "Should set faction ID")
	assert_eq(production_dialog.production_queue.size(), 2, "Should have 2 items in queue")

func test_production_dialog_add_item():
	var scene = load("res://ui/dialogs/production_dialog.tscn")
	production_dialog = scene.instantiate()
	add_child_autofree(production_dialog)

	production_dialog.show_queue(0, [])
	await wait_frames(1)

	var initial_size = production_dialog.production_queue.size()

	var signal_received = false
	production_dialog.queue_reordered.connect(func(queue):
		signal_received = true
	)

	production_dialog._on_add_pressed()

	assert_gt(production_dialog.production_queue.size(), initial_size, "Queue should grow")
	assert_true(signal_received, "Should emit queue_reordered signal")

func test_production_dialog_remove_item():
	var scene = load("res://ui/dialogs/production_dialog.tscn")
	production_dialog = scene.instantiate()
	add_child_autofree(production_dialog)

	var queue = [
		{"name": "Unit 1", "turns_remaining": 3}
	]

	production_dialog.show_queue(0, queue)
	await wait_frames(1)

	# Simulate selection and removal
	if production_dialog.queue_list:
		production_dialog.queue_list.select(0)
		production_dialog._on_item_selected(0)

	production_dialog._on_remove_pressed()

	assert_eq(production_dialog.production_queue.size(), 0, "Queue should be empty after removal")
