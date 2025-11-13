extends GutTest
## Tests for UIManager singleton

var ui_manager: Node
var mock_game_state: RefCounted

func before_each():
	# Create UIManager instance for testing
	ui_manager = load("res://ui/ui_manager.gd").new()
	add_child_autofree(ui_manager)

	# Create mock game state
	mock_game_state = RefCounted.new()

func after_each():
	if ui_manager:
		ui_manager.cleanup()

func test_initialization():
	assert_false(ui_manager.is_initialized, "Should not be initialized initially")

	ui_manager.initialize(mock_game_state)

	assert_true(ui_manager.is_initialized, "Should be initialized")
	assert_eq(ui_manager.game_state, mock_game_state, "Should store game state reference")

func test_double_initialization_fails():
	ui_manager.initialize(mock_game_state)

	# Try to initialize again
	ui_manager.initialize(mock_game_state)

	# Should log error but not crash
	assert_true(ui_manager.is_initialized, "Should still be initialized")

func test_cleanup():
	ui_manager.initialize(mock_game_state)
	ui_manager.cleanup()

	assert_false(ui_manager.is_initialized, "Should not be initialized after cleanup")
	assert_null(ui_manager.game_state, "Game state reference should be cleared")

func test_show_main_menu():
	var signal_received = false
	var screen_name = ""

	ui_manager.screen_changed.connect(func(name):
		signal_received = true
		screen_name = name
	)

	ui_manager.show_main_menu()

	await wait_frames(2)

	assert_true(signal_received, "Should emit screen_changed signal")
	assert_eq(screen_name, "main_menu", "Should emit correct screen name")
	assert_eq(ui_manager.current_screen_name, "main_menu", "Should set current screen name")

func test_show_game_screen():
	var signal_received = false
	var screen_name = ""

	ui_manager.screen_changed.connect(func(name):
		signal_received = true
		screen_name = name
	)

	ui_manager.show_game_screen()

	await wait_frames(2)

	assert_true(signal_received, "Should emit screen_changed signal")
	assert_eq(screen_name, "game", "Should emit correct screen name")
	assert_eq(ui_manager.current_screen_name, "game", "Should set current screen name")

func test_show_settings():
	var signal_received = false
	var screen_name = ""

	ui_manager.screen_changed.connect(func(name):
		signal_received = true
		screen_name = name
	)

	ui_manager.show_settings("main_menu")

	await wait_frames(2)

	assert_true(signal_received, "Should emit screen_changed signal")
	assert_eq(screen_name, "settings", "Should emit correct screen name")
	assert_eq(ui_manager.return_to_screen, "main_menu", "Should remember return screen")

func test_transition_between_screens():
	ui_manager.show_main_menu()
	await wait_frames(2)

	assert_eq(ui_manager.current_screen_name, "main_menu")

	ui_manager.show_game_screen()
	await wait_frames(2)

	assert_eq(ui_manager.current_screen_name, "game")

	ui_manager.show_settings()
	await wait_frames(2)

	assert_eq(ui_manager.current_screen_name, "settings")

func test_start_new_game():
	var settings = {
		"difficulty": "normal",
		"map_size": "normal",
		"ai_opponents": 3,
		"starting_faction": "survivors"
	}

	var signal_received = false
	ui_manager.screen_changed.connect(func(name):
		if name == "game":
			signal_received = true
	)

	ui_manager.start_new_game(settings)

	await wait_frames(2)

	assert_true(signal_received, "Should transition to game screen")

func test_start_new_game_invalid_settings():
	var invalid_settings = {
		"difficulty": "normal"
		# Missing required keys
	}

	ui_manager.start_new_game(invalid_settings)

	await wait_frames(2)

	# Should handle error gracefully (logs error but doesn't crash)
	assert_not_null(ui_manager, "Should not crash on invalid settings")

func test_load_game():
	var result = ui_manager.load_game("test_save")

	await wait_frames(2)

	assert_true(result, "Should return true for valid save name")
	assert_eq(ui_manager.current_screen_name, "game", "Should transition to game screen")

func test_load_game_empty_name():
	var result = ui_manager.load_game("")

	assert_false(result, "Should return false for empty save name")

func test_show_notification():
	var signal_received = false
	var message = ""
	var type = ""

	ui_manager.notification_shown.connect(func(msg, tp):
		signal_received = true
		message = msg
		type = tp
	)

	ui_manager.show_notification("Test message", "info")

	assert_true(signal_received, "Should emit notification_shown signal")
	assert_eq(message, "Test message", "Should emit correct message")
	assert_eq(type, "info", "Should emit correct type")

func test_update_resources():
	ui_manager.show_game_screen()
	await wait_frames(2)

	var resources = {
		"scrap": 100,
		"food": 50,
		"medicine": 25
	}

	# This should not crash even if resource_bar is not set
	ui_manager.update_resources(0, resources)

	# Verify no crash
	assert_not_null(ui_manager, "Should handle resource update gracefully")

func test_update_turn_indicator():
	ui_manager.show_game_screen()
	await wait_frames(2)

	# This should not crash even if turn_indicator is not set
	ui_manager.update_turn_indicator(5, "combat", 0)

	# Verify no crash
	assert_not_null(ui_manager, "Should handle turn update gracefully")
