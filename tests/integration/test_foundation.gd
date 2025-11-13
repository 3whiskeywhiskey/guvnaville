extends GutTest

## Phase 3 Integration Tests - Foundation Layer
## Tests Core Foundation module and data loading integration
##
## @agent: Integration Coordinator

# ============================================================================
# SETUP / TEARDOWN
# ============================================================================

var test_game: GameState = null

func before_each():
	# Ensure data is loaded before each test
	if not DataLoader.is_data_loaded:
		DataLoader.load_game_data()

	test_game = null

func after_each():
	# Clean up
	if test_game != null:
		test_game = null

	# Clear any test saves
	var save_dir = "user://saves/"
	if DirAccess.dir_exists_absolute(save_dir):
		var dir = DirAccess.open(save_dir)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.begins_with("test_"):
					dir.remove(save_dir + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

# ============================================================================
# GAME INITIALIZATION TESTS
# ============================================================================

func test_game_initialization():
	"""Test that a game can be initialized with default settings"""
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 12345
	}

	test_game = GameManager.start_new_game(settings)

	assert_not_null(test_game, "Game state should be created")
	assert_eq(test_game.turn_number, 1, "Should start at turn 1")
	assert_eq(test_game.factions.size(), 2, "Should have 2 factions")
	assert_true(GameManager.is_game_active, "Game should be active")
	assert_false(GameManager.is_paused, "Game should not be paused")

func test_game_initialization_multiple_factions():
	"""Test game initialization with multiple factions"""
	var settings = {
		"num_factions": 4,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)

	assert_not_null(test_game, "Game state should be created")
	assert_eq(test_game.factions.size(), 4, "Should have 4 factions")

	# Check faction 0 is player
	var player_faction = test_game.get_faction(0)
	assert_not_null(player_faction, "Player faction should exist")
	assert_true(player_faction.is_player, "Faction 0 should be player")

	# Check other factions are AI
	for i in range(1, 4):
		var ai_faction = test_game.get_faction(i)
		assert_not_null(ai_faction, "Faction %d should exist" % i)
		assert_false(ai_faction.is_player, "Faction %d should be AI" % i)
		assert_true(ai_faction.ai_personality in ["aggressive", "defensive", "economic", "balanced"],
			"Faction %d should have valid AI personality" % i)

func test_game_initialization_with_max_factions():
	"""Test game initialization with maximum factions (8)"""
	var settings = {
		"num_factions": 8,
		"player_faction_id": 0,
		"difficulty": "hard"
	}

	test_game = GameManager.start_new_game(settings)

	assert_not_null(test_game, "Game state should be created")
	assert_eq(test_game.factions.size(), 8, "Should have 8 factions")

func test_game_initialization_invalid_settings():
	"""Test that invalid settings are rejected"""
	var invalid_settings = [
		{"num_factions": 0},  # Too few
		{"num_factions": 9},  # Too many
		{"num_factions": 2, "difficulty": "invalid"},  # Invalid difficulty
		{"num_factions": 2, "player_faction_id": 5},  # Invalid player ID
	]

	for settings in invalid_settings:
		test_game = GameManager.start_new_game(settings)
		assert_null(test_game, "Should reject invalid settings: %s" % str(settings))

# ============================================================================
# DATA LOADING TESTS
# ============================================================================

func test_data_loading():
	"""Test that game data loads successfully"""
	# Data should already be loaded in before_each, but test explicitly
	assert_true(DataLoader.is_data_loaded, "Data should be loaded")

	# Check unit types loaded
	var units = DataLoader.unit_types
	assert_not_null(units, "Unit types should be loaded")
	assert_gt(units.size(), 0, "Should have at least one unit type")

	# Check a specific unit exists
	assert_true(units.has("militia"), "Should have militia unit")
	var militia = units["militia"]
	assert_not_null(militia, "Militia data should exist")
	assert_true(militia.has("name"), "Militia should have name")
	assert_true(militia.has("cost"), "Militia should have cost")

func test_data_loading_all_types():
	"""Test that all data types load successfully"""
	assert_true(DataLoader.is_data_loaded, "Data should be loaded")

	# Check all data types
	assert_gt(DataLoader.unit_types.size(), 0, "Should load unit types")
	assert_gt(DataLoader.building_types.size(), 0, "Should load building types")
	assert_not_null(DataLoader.culture_tree, "Should load culture tree")
	assert_gt(DataLoader.event_types.size(), 0, "Should load event types")
	assert_gt(DataLoader.locations.size(), 0, "Should load locations")

func test_data_loading_unit_properties():
	"""Test that loaded units have correct properties"""
	var units = DataLoader.unit_types

	for unit_id in units:
		var unit = units[unit_id]

		# Check required fields
		assert_true(unit.has("name"), "Unit %s should have name" % unit_id)
		assert_true(unit.has("category"), "Unit %s should have category" % unit_id)
		assert_true(unit.has("cost"), "Unit %s should have cost" % unit_id)
		assert_true(unit.has("combat_stats"), "Unit %s should have combat_stats" % unit_id)

		# Check combat stats
		var stats = unit.combat_stats
		assert_true(stats.has("attack"), "Unit %s combat_stats should have attack" % unit_id)
		assert_true(stats.has("defense"), "Unit %s combat_stats should have defense" % unit_id)
		assert_true(stats.has("health"), "Unit %s combat_stats should have health" % unit_id)

func test_data_loading_buildings():
	"""Test that buildings load with correct structure"""
	var buildings = DataLoader.building_types

	assert_gt(buildings.size(), 0, "Should have buildings loaded")

	for building_id in buildings:
		var building = buildings[building_id]

		assert_true(building.has("name"), "Building %s should have name" % building_id)
		assert_true(building.has("category"), "Building %s should have category" % building_id)
		assert_true(building.has("cost"), "Building %s should have cost" % building_id)
		assert_true(building.has("build_time"), "Building %s should have build_time" % building_id)

func test_data_loading_culture_tree():
	"""Test that culture tree loads correctly"""
	var culture_tree = DataLoader.culture_tree

	assert_not_null(culture_tree, "Culture tree should exist")
	assert_true(culture_tree.has("nodes"), "Culture tree should have nodes")

	var nodes = culture_tree.nodes
	assert_gt(nodes.size(), 0, "Should have culture nodes")

	# Check a node structure
	for node in nodes:
		assert_true(node.has("id"), "Node should have id")
		assert_true(node.has("name"), "Node should have name")
		assert_true(node.has("axis"), "Node should have axis")
		assert_true(node.has("tier"), "Node should have tier")

func test_data_loading_events():
	"""Test that events load correctly"""
	var events = DataLoader.event_types

	assert_gt(events.size(), 0, "Should have events loaded")

	for event_id in events:
		var event = events[event_id]

		assert_true(event.has("title"), "Event %s should have title" % event_id)
		assert_true(event.has("description"), "Event %s should have description" % event_id)
		assert_true(event.has("choices"), "Event %s should have choices" % event_id)
		assert_gt(event.choices.size(), 0, "Event %s should have at least one choice" % event_id)

# ============================================================================
# SAVE/LOAD ROUND-TRIP TESTS
# ============================================================================

func test_save_load_round_trip():
	"""Test that game state survives save/load cycle"""
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 54321
	}

	# Create game
	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "Game should be created")

	var original_turn = test_game.turn_number
	var original_seed = test_game.random_seed
	var original_faction_count = test_game.factions.size()

	# Save game
	var save_name = "test_round_trip"
	var save_success = GameManager.save_game(save_name)
	assert_true(save_success, "Save should succeed")

	# End current game
	GameManager.end_game("test", 0)

	# Load game
	var loaded_game = GameManager.load_game(save_name)
	assert_not_null(loaded_game, "Loaded game should not be null")

	# Verify loaded state matches original
	assert_eq(loaded_game.turn_number, original_turn, "Turn number should match")
	assert_eq(loaded_game.random_seed, original_seed, "Random seed should match")
	assert_eq(loaded_game.factions.size(), original_faction_count, "Faction count should match")

func test_save_load_preserves_faction_state():
	"""Test that faction state is preserved through save/load"""
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	# Create game
	test_game = GameManager.start_new_game(settings)

	# Modify faction state
	var faction = test_game.get_faction(0)
	faction.resources.scrap = 500
	faction.resources.food = 200
	faction.culture.points = 100

	# Save game
	var save_name = "test_faction_state"
	GameManager.save_game(save_name)

	# Load game
	GameManager.end_game("test", 0)
	var loaded_game = GameManager.load_game(save_name)

	# Verify faction state preserved
	var loaded_faction = loaded_game.get_faction(0)
	assert_eq(loaded_faction.resources.scrap, 500, "Scrap should be preserved")
	assert_eq(loaded_faction.resources.food, 200, "Food should be preserved")
	assert_eq(loaded_faction.culture.points, 100, "Culture points should be preserved")

func test_save_load_multiple_times():
	"""Test multiple save/load cycles"""
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)

	for i in range(5):
		# Modify game state
		test_game.turn_number = i + 1

		# Save
		var save_name = "test_multiple_%d" % i
		var save_success = GameManager.save_game(save_name)
		assert_true(save_success, "Save %d should succeed" % i)

		# Load
		GameManager.end_game("test", 0)
		var loaded = GameManager.load_game(save_name)
		assert_not_null(loaded, "Load %d should succeed" % i)
		assert_eq(loaded.turn_number, i + 1, "Turn should match for save %d" % i)

		test_game = loaded

# ============================================================================
# GAME STATE VALIDATION TESTS
# ============================================================================

func test_game_state_validation():
	"""Test that game state validation works"""
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)

	# Valid state should pass
	assert_true(test_game.validate(), "Valid game state should pass validation")

func test_game_state_to_dict_from_dict():
	"""Test game state serialization round-trip"""
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 99999
	}

	test_game = GameManager.start_new_game(settings)

	# Convert to dictionary
	var game_dict = test_game.to_dict()
	assert_not_null(game_dict, "to_dict should return dictionary")
	assert_true(game_dict.has("turn_number"), "Dictionary should have turn_number")
	assert_true(game_dict.has("random_seed"), "Dictionary should have random_seed")
	assert_true(game_dict.has("factions"), "Dictionary should have factions")

	# Create new state from dictionary
	var new_state = GameState.new()
	new_state.from_dict(game_dict)

	# Verify it matches
	assert_eq(new_state.turn_number, test_game.turn_number, "Turn number should match")
	assert_eq(new_state.random_seed, test_game.random_seed, "Random seed should match")
	assert_eq(new_state.factions.size(), test_game.factions.size(), "Faction count should match")

# ============================================================================
# EVENT BUS INTEGRATION TESTS
# ============================================================================

func test_event_bus_game_started_signal():
	"""Test that game_started signal is emitted"""
	var signal_received = false
	var received_state = null

	EventBus.game_started.connect(func(state):
		signal_received = true
		received_state = state
	)

	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)

	# Give a frame for signal to propagate
	await get_tree().process_frame

	assert_true(signal_received, "game_started signal should be emitted")
	assert_not_null(received_state, "Signal should include game state")

func test_event_bus_game_loaded_signal():
	"""Test that game_loaded signal is emitted"""
	# Create and save a game first
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)
	GameManager.save_game("test_load_signal")
	GameManager.end_game("test", 0)

	# Connect to signal
	var signal_received = false
	EventBus.game_loaded.connect(func(_state):
		signal_received = true
	)

	# Load game
	test_game = GameManager.load_game("test_load_signal")
	await get_tree().process_frame

	assert_true(signal_received, "game_loaded signal should be emitted")

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

func test_game_initialization_performance():
	"""Test that game initialization completes quickly"""
	var settings = {
		"num_factions": 8,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	var start_time = Time.get_ticks_msec()

	test_game = GameManager.start_new_game(settings)

	var elapsed = Time.get_ticks_msec() - start_time

	assert_not_null(test_game, "Game should be created")
	assert_lt(elapsed, 2000, "Game initialization should complete within 2 seconds (took %d ms)" % elapsed)

func test_save_performance():
	"""Test that save operation is fast"""
	var settings = {
		"num_factions": 4,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)

	var start_time = Time.get_ticks_msec()

	var success = GameManager.save_game("test_save_perf")

	var elapsed = Time.get_ticks_msec() - start_time

	assert_true(success, "Save should succeed")
	assert_lt(elapsed, 1000, "Save should complete within 1 second (took %d ms)" % elapsed)

func test_load_performance():
	"""Test that load operation is fast"""
	var settings = {
		"num_factions": 4,
		"player_faction_id": 0,
		"difficulty": "normal"
	}

	test_game = GameManager.start_new_game(settings)
	GameManager.save_game("test_load_perf")
	GameManager.end_game("test", 0)

	var start_time = Time.get_ticks_msec()

	test_game = GameManager.load_game("test_load_perf")

	var elapsed = Time.get_ticks_msec() - start_time

	assert_not_null(test_game, "Load should succeed")
	assert_lt(elapsed, 1000, "Load should complete within 1 second (took %d ms)" % elapsed)
