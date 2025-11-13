extends GutTest
## Tests for ResourceBar HUD component

var resource_bar: Control

func before_each():
	var scene = load("res://ui/hud/resource_bar.tscn")
	resource_bar = scene.instantiate()
	add_child_autofree(resource_bar)

func test_resource_bar_loads():
	assert_not_null(resource_bar, "Resource bar should load")

func test_initial_resources_are_zero():
	assert_eq(resource_bar.current_resources["scrap"], 0, "Scrap should start at 0")
	assert_eq(resource_bar.current_resources["food"], 0, "Food should start at 0")
	assert_eq(resource_bar.current_resources["medicine"], 0, "Medicine should start at 0")

func test_update_resources():
	var new_resources = {
		"scrap": 100,
		"food": 50,
		"medicine": 25,
		"ammunition": 75,
		"fuel": 30,
		"components": 15,
		"water": 60
	}

	resource_bar.update_resources(new_resources)

	assert_eq(resource_bar.current_resources["scrap"], 100, "Scrap should update")
	assert_eq(resource_bar.current_resources["food"], 50, "Food should update")
	assert_eq(resource_bar.current_resources["medicine"], 25, "Medicine should update")

func test_update_display():
	var new_resources = {
		"scrap": 150
	}

	resource_bar.update_resources(new_resources)

	# Wait for UI update
	await wait_frames(1)

	# Check labels exist and are updated
	if resource_bar.scrap_label:
		assert_string_contains(resource_bar.scrap_label.text, "150", "Scrap label should show updated value")

func test_resource_changed_signal_handler():
	# Simulate EventBus signal
	resource_bar._on_resource_changed(0, "scrap", 50, 150)

	assert_eq(resource_bar.current_resources["scrap"], 150, "Should update resource from signal")

func test_resource_changed_other_faction():
	# Other faction (not player)
	resource_bar._on_resource_changed(1, "scrap", 50, 150)

	# Should not update player resources
	assert_eq(resource_bar.current_resources["scrap"], 0, "Should not update for other factions")

func test_partial_resource_update():
	# Set initial resources
	var initial = {
		"scrap": 100,
		"food": 50
	}
	resource_bar.update_resources(initial)

	# Update only one resource
	var partial = {
		"scrap": 200
	}
	resource_bar.update_resources(partial)

	# Should have new scrap value, but food should be reset
	assert_eq(resource_bar.current_resources["scrap"], 200, "Scrap should update")
