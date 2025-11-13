extends GutTest
## Tests for TurnIndicator HUD component

var turn_indicator: Control

func before_each():
	var scene = load("res://ui/hud/turn_indicator.tscn")
	turn_indicator = scene.instantiate()
	add_child_autofree(turn_indicator)

func test_turn_indicator_loads():
	assert_not_null(turn_indicator, "Turn indicator should load")

func test_initial_turn_values():
	assert_eq(turn_indicator.current_turn, 1, "Should start at turn 1")
	assert_eq(turn_indicator.current_phase, "movement", "Should start in movement phase")
	assert_eq(turn_indicator.active_faction, 0, "Should start with player faction")

func test_update_turn():
	turn_indicator.update_turn(5, "combat", 1)

	assert_eq(turn_indicator.current_turn, 5, "Turn should update")
	assert_eq(turn_indicator.current_phase, "combat", "Phase should update")
	assert_eq(turn_indicator.active_faction, 1, "Faction should update")

func test_update_display():
	turn_indicator.update_turn(10, "economy", 0)

	await wait_frames(1)

	if turn_indicator.turn_label:
		assert_string_contains(turn_indicator.turn_label.text, "10", "Turn label should show turn number")

	if turn_indicator.phase_label:
		assert_string_contains(turn_indicator.phase_label.text, "Economy", "Phase label should show phase")

func test_get_faction_name():
	assert_eq(turn_indicator._get_faction_name(0), "Player", "Faction 0 should be Player")
	assert_eq(turn_indicator._get_faction_name(1), "AI 1", "Faction 1 should be AI 1")
	assert_eq(turn_indicator._get_faction_name(5), "AI 5", "Faction 5 should be AI 5")

func test_turn_started_signal_handler():
	turn_indicator._on_turn_started(7, 2)

	assert_eq(turn_indicator.current_turn, 7, "Turn should update from signal")
	assert_eq(turn_indicator.active_faction, 2, "Faction should update from signal")

func test_phase_changed_signal_handler():
	turn_indicator._on_phase_changed("movement", "combat")

	assert_eq(turn_indicator.current_phase, "combat", "Phase should update from signal")
