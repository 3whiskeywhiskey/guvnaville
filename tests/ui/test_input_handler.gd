extends GutTest
## Tests for InputHandler

var input_handler: InputHandler

func before_each():
	input_handler = InputHandler.new()
	add_child_autofree(input_handler)

func test_input_handler_creates():
	assert_not_null(input_handler, "InputHandler should create")

func test_initial_mode_is_menu():
	assert_eq(input_handler.current_mode, InputHandler.InputMode.MENU, "Should start in MENU mode")

func test_set_input_mode():
	input_handler.set_input_mode(InputHandler.InputMode.GAME)

	assert_eq(input_handler.current_mode, InputHandler.InputMode.GAME, "Should change to GAME mode")

func test_is_action_enabled_menu_mode():
	input_handler.set_input_mode(InputHandler.InputMode.MENU)

	assert_true(input_handler.is_action_enabled("ui_up"), "ui_up should be enabled in menu mode")
	assert_true(input_handler.is_action_enabled("ui_down"), "ui_down should be enabled in menu mode")
	assert_true(input_handler.is_action_enabled("ui_accept"), "ui_accept should be enabled in menu mode")
	assert_false(input_handler.is_action_enabled("camera_pan_up"), "camera_pan_up should not be enabled in menu mode")

func test_is_action_enabled_game_mode():
	input_handler.set_input_mode(InputHandler.InputMode.GAME)

	assert_true(input_handler.is_action_enabled("camera_pan_up"), "camera_pan_up should be enabled in game mode")
	assert_true(input_handler.is_action_enabled("select_tile"), "select_tile should be enabled in game mode")
	assert_true(input_handler.is_action_enabled("end_turn"), "end_turn should be enabled in game mode")

func test_is_action_enabled_dialog_mode():
	input_handler.set_input_mode(InputHandler.InputMode.DIALOG)

	assert_true(input_handler.is_action_enabled("ui_up"), "ui_up should be enabled in dialog mode")
	assert_true(input_handler.is_action_enabled("ui_accept"), "ui_accept should be enabled in dialog mode")
	assert_false(input_handler.is_action_enabled("camera_pan_up"), "camera actions should not be enabled in dialog mode")

func test_is_action_enabled_disabled_mode():
	input_handler.set_input_mode(InputHandler.InputMode.DISABLED)

	assert_false(input_handler.is_action_enabled("ui_up"), "No actions should be enabled in disabled mode")
	assert_false(input_handler.is_action_enabled("camera_pan_up"), "No actions should be enabled in disabled mode")

func test_enable_disable_action():
	input_handler.set_input_mode(InputHandler.InputMode.DISABLED)

	input_handler.enable_action("test_action")
	assert_true(input_handler.is_action_enabled("test_action"), "Should enable specific action")

	input_handler.disable_action("test_action")
	assert_false(input_handler.is_action_enabled("test_action"), "Should disable specific action")

func test_end_turn_signal():
	input_handler.set_input_mode(InputHandler.InputMode.GAME)

	var signal_received = false
	input_handler.end_turn_requested.connect(func():
		signal_received = true
	)

	# Simulate end turn action
	var event = InputEventAction.new()
	event.action = "end_turn"
	event.pressed = true
	input_handler._input(event)

	assert_true(signal_received, "Should emit end_turn_requested signal")

func test_action_requested_signal():
	input_handler.set_input_mode(InputHandler.InputMode.GAME)

	var signal_received = false
	var action_type = ""

	input_handler.action_requested.connect(func(type, params):
		signal_received = true
		action_type = type
	)

	# Simulate camera zoom action
	var event = InputEventAction.new()
	event.action = "camera_zoom_in"
	event.pressed = true
	input_handler._input(event)

	assert_true(signal_received, "Should emit action_requested signal")
	assert_eq(action_type, "camera_zoom_in", "Should emit correct action type")

func test_input_disabled_mode_ignores_input():
	input_handler.set_input_mode(InputHandler.InputMode.DISABLED)

	var signal_received = false
	input_handler.action_requested.connect(func(type, params):
		signal_received = true
	)

	# Try to trigger action in disabled mode
	var event = InputEventAction.new()
	event.action = "end_turn"
	event.pressed = true
	input_handler._input(event)

	assert_false(signal_received, "Should not emit signals in disabled mode")
