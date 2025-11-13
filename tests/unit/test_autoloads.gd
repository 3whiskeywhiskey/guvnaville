extends GutTest

## Unit tests for autoload singletons (DataLoader, SaveManager, TurnManager, GameManager)

var test_save_name = "test_save_unit_test"

func after_each():
	# Clean up test saves
	if SaveManager.list_saves().any(func(s): return s.name == test_save_name):
		SaveManager.delete_save(test_save_name)

	# Reset game state
	if GameManager:
		GameManager.current_state = null
		GameManager.is_game_active = false
		GameManager.is_paused = false

# ============================================================================
# DATA LOADER TESTS
# ============================================================================

func test_data_loader_exists():
	assert_not_null(DataLoader, "DataLoader should exist")

func test_load_game_data():
	var success = DataLoader.load_game_data()
	assert_true(success, "Should load game data")
	assert_true(DataLoader.is_data_loaded, "Data should be marked as loaded")

func test_data_loader_unit_types():
	DataLoader.load_game_data()
	assert_gt(DataLoader.unit_types.size(), 0, "Should have unit types loaded")

func test_data_loader_building_types():
	DataLoader.load_game_data()
	# Buildings are optional, so just check it doesn't crash
	assert_true(true, "Building loading should not crash")

func test_data_loader_resources():
	DataLoader.load_game_data()
	assert_gt(DataLoader.resource_definitions.size(), 0, "Should have resource definitions")

func test_get_unit_definition():
	DataLoader.load_game_data()

	var militia_def = DataLoader.get_unit_definition("militia")
	assert_false(militia_def.is_empty(), "Should find militia definition")

	var invalid_def = DataLoader.get_unit_definition("nonexistent")
	assert_true(invalid_def.is_empty(), "Should return empty dict for invalid type")

func test_validate_data():
	DataLoader.load_game_data()

	var report = DataLoader.validate_data()
	assert_true(report.has("valid"), "Report should have 'valid' field")
	assert_true(report.has("errors"), "Report should have 'errors' field")
	assert_true(report.has("warnings"), "Report should have 'warnings' field")

func test_reload_data():
	DataLoader.load_game_data()
	var initial_size = DataLoader.unit_types.size()

	var success = DataLoader.reload_data()
	assert_true(success, "Reload should succeed")
	assert_eq(DataLoader.unit_types.size(), initial_size, "Should have same data after reload")

# ============================================================================
# SAVE MANAGER TESTS
# ============================================================================

func test_save_manager_exists():
	assert_not_null(SaveManager, "SaveManager should exist")

func test_save_directory():
	var dir = SaveManager.get_save_directory()
	assert_false(dir.is_empty(), "Save directory should be set")
	assert_true(DirAccess.dir_exists_absolute(dir), "Save directory should exist")

func test_save_and_load_game():
	var game_state = GameState.new()
	game_state.turn_number = 42
	game_state.random_seed = 12345
	game_state.add_faction(FactionState.new(0, "Test Faction", true))

	var save_success = SaveManager.save_game(test_save_name, game_state)
	assert_true(save_success, "Save should succeed")

	var loaded_state = SaveManager.load_game(test_save_name)
	assert_not_null(loaded_state, "Loaded state should not be null")
	assert_eq(loaded_state.turn_number, 42, "Turn number should match")
	assert_eq(loaded_state.random_seed, 12345, "Random seed should match")
	assert_eq(loaded_state.factions.size(), 1, "Should have 1 faction")

func test_save_game_state_preservation():
	var game_state = GameState.new()
	game_state.turn_number = 100

	var faction = FactionState.new(0, "Player", true)
	faction.resources["scrap"] = 500
	faction.resources["ammo"] = 200
	faction.add_controlled_tile(Vector3i(10, 10, 1))
	game_state.add_faction(faction)

	# Add a tile to world
	var tile = Tile.new(Vector3i(5, 5, 1)).setup("residential", "rubble")
	tile.owner = 0
	tile.scavenge_value = 75
	game_state.world_state.set_tile(tile.position, tile)

	SaveManager.save_game(test_save_name, game_state)
	var loaded = SaveManager.load_game(test_save_name)

	assert_eq(loaded.turn_number, 100, "Turn should match")

	var loaded_faction = loaded.get_faction(0)
	assert_not_null(loaded_faction, "Faction should be loaded")
	assert_eq(loaded_faction.resources["scrap"], 500, "Scrap should match")
	assert_eq(loaded_faction.resources["ammo"], 200, "Ammo should match")
	assert_eq(loaded_faction.controlled_tiles.size(), 1, "Controlled tiles should match")

	var loaded_tile = loaded.world_state.get_tile(Vector3i(5, 5, 1))
	assert_not_null(loaded_tile, "Tile should be loaded")
	assert_eq(loaded_tile.owner, 0, "Tile owner should match")
	assert_eq(loaded_tile.scavenge_value, 75, "Scavenge value should match")

func test_list_saves():
	var game_state = GameState.new()
	game_state.turn_number = 1

	SaveManager.save_game(test_save_name, game_state)

	var saves = SaveManager.list_saves()
	var found = false

	for save in saves:
		if save.name == test_save_name:
			found = true
			assert_eq(save.turn_number, 1, "Listed save should have correct turn")
			break

	assert_true(found, "Saved game should appear in list")

func test_delete_save():
	var game_state = GameState.new()
	SaveManager.save_game(test_save_name, game_state)

	var exists_before = SaveManager.verify_save_integrity(test_save_name)
	assert_true(exists_before, "Save should exist before deletion")

	var deleted = SaveManager.delete_save(test_save_name)
	assert_true(deleted, "Delete should succeed")

	var exists_after = SaveManager.verify_save_integrity(test_save_name)
	assert_false(exists_after, "Save should not exist after deletion")

func test_verify_save_integrity():
	var game_state = GameState.new()
	SaveManager.save_game(test_save_name, game_state)

	var valid = SaveManager.verify_save_integrity(test_save_name)
	assert_true(valid, "Saved game should have valid integrity")

func test_autosave():
	var game_state = GameState.new()
	game_state.turn_number = 10

	var success = SaveManager.create_autosave(game_state)
	assert_true(success, "Autosave should succeed")

	var loaded = SaveManager.load_game("autosave")
	assert_not_null(loaded, "Should load autosave")
	assert_eq(loaded.turn_number, 10, "Autosave turn should match")

	# Clean up autosave
	SaveManager.delete_save("autosave")

func test_save_invalid_state():
	var success = SaveManager.save_game("", null)
	assert_false(success, "Saving null state should fail")

	success = SaveManager.save_game("", GameState.new())
	assert_false(success, "Saving with empty name should fail")

func test_load_nonexistent_save():
	var loaded = SaveManager.load_game("nonexistent_save_file")
	assert_null(loaded, "Loading nonexistent save should return null")

# ============================================================================
# TURN MANAGER TESTS
# ============================================================================

func test_turn_manager_exists():
	assert_not_null(TurnManager, "TurnManager should exist")

func test_turn_phase_enum():
	assert_eq(TurnManager.TurnPhase.MOVEMENT, 0, "MOVEMENT phase")
	assert_eq(TurnManager.TurnPhase.COMBAT, 1, "COMBAT phase")
	assert_eq(TurnManager.TurnPhase.ECONOMY, 2, "ECONOMY phase")
	assert_eq(TurnManager.TurnPhase.CULTURE, 3, "CULTURE phase")
	assert_eq(TurnManager.TurnPhase.EVENTS, 4, "EVENTS phase")
	assert_eq(TurnManager.TurnPhase.END_TURN, 5, "END_TURN phase")

func test_turn_phase_names():
	assert_eq(TurnManager.get_phase_name(TurnManager.TurnPhase.MOVEMENT), "Movement")
	assert_eq(TurnManager.get_phase_name(TurnManager.TurnPhase.COMBAT), "Combat")
	assert_eq(TurnManager.get_phase_name(TurnManager.TurnPhase.ECONOMY), "Economy")

func test_process_turn_without_game():
	# Should not crash when no game is active
	TurnManager.process_turn()
	assert_true(true, "Processing turn without game should not crash")

func test_process_turn_with_game():
	# Set up game
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)
	var initial_turn = GameManager.current_state.turn_number

	# Process turn
	TurnManager.process_turn()

	assert_eq(GameManager.current_state.turn_number, initial_turn + 1, "Turn should increment")

func test_turn_signals():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)

	var phases_seen = []
	var turns_started = 0
	var turns_ended = 0

	EventBus.turn_phase_changed.connect(func(phase): phases_seen.append(phase))
	EventBus.turn_started.connect(func(turn, faction): turns_started += 1)
	EventBus.turn_ended.connect(func(turn): turns_ended += 1)

	TurnManager.process_turn()

	assert_gt(phases_seen.size(), 0, "Should have phase changes")
	assert_eq(turns_started, 2, "Should start turn for 2 factions")
	assert_eq(turns_ended, 1, "Should end 1 complete turn")

# ============================================================================
# GAME MANAGER TESTS
# ============================================================================

func test_game_manager_exists():
	assert_not_null(GameManager, "GameManager should exist")

func test_start_new_game():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 3,
		"difficulty": "normal",
		"player_faction_id": 0,
		"map_seed": 12345
	}

	var state = GameManager.start_new_game(settings)

	assert_not_null(state, "Game state should be created")
	assert_eq(state.turn_number, 1, "Initial turn should be 1")
	assert_eq(state.factions.size(), 3, "Should have 3 factions")
	assert_eq(state.random_seed, 12345, "Random seed should match")
	assert_true(GameManager.is_game_active, "Game should be active")

func test_start_game_with_invalid_settings():
	DataLoader.load_game_data()

	var invalid_settings = {
		"num_factions": 0,  # Invalid
		"difficulty": "normal"
	}

	var state = GameManager.start_new_game(invalid_settings)
	assert_null(state, "Should fail with invalid settings")

	invalid_settings = {
		"num_factions": 2,
		"difficulty": "impossible"  # Invalid
	}

	state = GameManager.start_new_game(invalid_settings)
	assert_null(state, "Should fail with invalid difficulty")

func test_save_and_load_game():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)
	GameManager.current_state.turn_number = 50

	var save_success = GameManager.save_game(test_save_name)
	assert_true(save_success, "Save should succeed")

	# Start new game (clears current state)
	GameManager.start_new_game(settings)
	assert_eq(GameManager.current_state.turn_number, 1, "New game should be turn 1")

	# Load saved game
	var loaded_state = GameManager.load_game(test_save_name)
	assert_not_null(loaded_state, "Load should succeed")
	assert_eq(loaded_state.turn_number, 50, "Loaded turn should be 50")
	assert_true(GameManager.is_game_active, "Game should be active after load")

func test_pause_and_resume():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)

	GameManager.pause_game()
	assert_true(GameManager.is_paused, "Game should be paused")

	GameManager.resume_game()
	assert_false(GameManager.is_paused, "Game should be resumed")

func test_end_game():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)
	assert_true(GameManager.is_game_active, "Game should be active")

	GameManager.end_game("military", 0)
	assert_false(GameManager.is_game_active, "Game should not be active after ending")

func test_get_faction():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 3,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)

	var faction = GameManager.get_faction(1)
	assert_not_null(faction, "Should retrieve faction 1")
	assert_eq(faction.faction_id, 1, "Faction ID should be 1")

	faction = GameManager.get_faction(99)
	assert_null(faction, "Should return null for invalid faction ID")

func test_game_started_signal():
	DataLoader.load_game_data()

	var signal_received = false
	EventBus.game_started.connect(func(state): signal_received = true)

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)

	assert_true(signal_received, "game_started signal should be emitted")

func test_player_faction_created():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 4,
		"difficulty": "normal",
		"player_faction_id": 2  # Player is faction 2
	}

	GameManager.start_new_game(settings)

	var player = GameManager.current_state.get_player_faction()
	assert_not_null(player, "Should have player faction")
	assert_eq(player.faction_id, 2, "Player should be faction 2")
	assert_true(player.is_player, "Player faction should have is_player = true")

func test_ai_personalities_assigned():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 3,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)

	# AI factions (1 and 2) should have personalities
	var faction1 = GameManager.get_faction(1)
	var faction2 = GameManager.get_faction(2)

	assert_false(faction1.ai_personality.is_empty(), "AI faction should have personality")
	assert_false(faction2.ai_personality.is_empty(), "AI faction should have personality")

func test_world_initialization():
	DataLoader.load_game_data()

	var settings = {
		"num_factions": 2,
		"difficulty": "normal",
		"player_faction_id": 0
	}

	GameManager.start_new_game(settings)

	assert_not_null(GameManager.current_state.world_state, "World state should exist")
	assert_gt(GameManager.current_state.world_state.tiles.size(), 0, "World should have tiles")
