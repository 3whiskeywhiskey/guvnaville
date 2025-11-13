extends GutTest

## Unit tests for state classes (GameState, FactionState, WorldState, TurnState)

# ============================================================================
# TURN STATE TESTS
# ============================================================================

func test_turn_state_creation():
	var turn_state = TurnState.new()

	assert_eq(turn_state.current_turn, 1, "Initial turn should be 1")
	assert_eq(turn_state.current_phase, TurnState.TurnPhase.MOVEMENT, "Initial phase should be MOVEMENT")
	assert_eq(turn_state.active_faction, 0, "Initial faction should be 0")

func test_turn_state_serialization():
	var turn_state = TurnState.new()
	turn_state.current_turn = 5
	turn_state.current_phase = TurnState.TurnPhase.COMBAT
	turn_state.active_faction = 2
	turn_state.time_elapsed = 120.5

	var dict = turn_state.to_dict()

	assert_eq(dict["current_turn"], 5, "Serialized turn")
	assert_eq(dict["current_phase"], TurnState.TurnPhase.COMBAT, "Serialized phase")
	assert_eq(dict["active_faction"], 2, "Serialized faction")
	assert_eq(dict["time_elapsed"], 120.5, "Serialized time")

func test_turn_state_deserialization():
	var data = {
		"current_turn": 10,
		"current_phase": TurnState.TurnPhase.ECONOMY,
		"active_faction": 3,
		"actions_this_turn": [{"action": "move"}],
		"time_elapsed": 45.2
	}

	var turn_state = TurnState.new()
	turn_state.from_dict(data)

	assert_eq(turn_state.current_turn, 10, "Deserialized turn")
	assert_eq(turn_state.current_phase, TurnState.TurnPhase.ECONOMY, "Deserialized phase")
	assert_eq(turn_state.active_faction, 3, "Deserialized faction")

func test_turn_state_reset():
	var turn_state = TurnState.new()
	turn_state.actions_this_turn.append({"action": "test"})
	turn_state.time_elapsed = 100.0

	turn_state.reset_for_new_turn()

	assert_eq(turn_state.actions_this_turn.size(), 0, "Actions should be cleared")
	assert_eq(turn_state.time_elapsed, 0.0, "Time should be reset")
	assert_eq(turn_state.current_phase, TurnState.TurnPhase.MOVEMENT, "Phase should reset to MOVEMENT")

func test_turn_state_phase_names():
	var turn_state = TurnState.new()

	turn_state.current_phase = TurnState.TurnPhase.MOVEMENT
	assert_eq(turn_state.get_phase_name(), "Movement", "Movement phase name")

	turn_state.current_phase = TurnState.TurnPhase.COMBAT
	assert_eq(turn_state.get_phase_name(), "Combat", "Combat phase name")

# ============================================================================
# FACTION STATE TESTS
# ============================================================================

func test_faction_state_creation():
	var faction = FactionState.new(0, "Test Faction", true)

	assert_eq(faction.faction_id, 0, "Faction ID")
	assert_eq(faction.faction_name, "Test Faction", "Faction name")
	assert_true(faction.is_player, "Is player")
	assert_true(faction.is_alive, "Is alive")

func test_faction_state_serialization():
	var faction = FactionState.new(1, "AI Faction", false)
	faction.resources["scrap"] = 200
	faction.units.append("unit_1")
	faction.buildings.append("bld_1")
	faction.controlled_tiles.append(Vector3i(10, 10, 1))

	var dict = faction.to_dict()

	assert_eq(dict["faction_id"], 1, "Serialized ID")
	assert_eq(dict["faction_name"], "AI Faction", "Serialized name")
	assert_false(dict["is_player"], "Serialized is_player")
	assert_eq(dict["resources"]["scrap"], 200, "Serialized resources")

func test_faction_state_deserialization():
	var data = {
		"faction_id": 2,
		"faction_name": "Enemy Faction",
		"is_player": false,
		"is_alive": true,
		"resources": {"scrap": 150, "ammo": 50},
		"culture": {"total_points": 100, "unlocked_nodes": []},
		"units": ["unit_2"],
		"buildings": ["bld_2"],
		"controlled_tiles": [{"x": 5, "y": 5, "z": 1}],
		"diplomacy": {},
		"ai_personality": "aggressive"
	}

	var faction = FactionState.new()
	faction.from_dict(data)

	assert_eq(faction.faction_id, 2, "Deserialized ID")
	assert_eq(faction.faction_name, "Enemy Faction", "Deserialized name")
	assert_eq(faction.resources["scrap"], 150, "Deserialized resources")
	assert_eq(faction.controlled_tiles.size(), 1, "Deserialized tiles")

func test_faction_resource_management():
	var faction = FactionState.new(0, "Test", true)
	faction.resources["scrap"] = 100

	faction.add_resource("scrap", 50)
	assert_eq(faction.get_resource("scrap"), 150, "Resource should increase")

	var removed = faction.remove_resource("scrap", 30)
	assert_true(removed, "Should remove resource")
	assert_eq(faction.get_resource("scrap"), 120, "Resource should decrease")

	removed = faction.remove_resource("scrap", 200)
	assert_false(removed, "Should not remove more than available")
	assert_eq(faction.get_resource("scrap"), 120, "Resource should not change")

func test_faction_has_resource():
	var faction = FactionState.new(0, "Test", true)
	faction.resources["ammo"] = 50

	assert_true(faction.has_resource("ammo", 50), "Should have 50 ammo")
	assert_true(faction.has_resource("ammo", 30), "Should have at least 30 ammo")
	assert_false(faction.has_resource("ammo", 100), "Should not have 100 ammo")

func test_faction_territory():
	var faction = FactionState.new(0, "Test", true)

	var pos1 = Vector3i(10, 10, 1)
	var pos2 = Vector3i(11, 10, 1)

	faction.add_controlled_tile(pos1)
	assert_eq(faction.get_territory_size(), 1, "Territory size should be 1")
	assert_true(faction.controls_tile(pos1), "Should control tile")

	faction.add_controlled_tile(pos1)
	assert_eq(faction.get_territory_size(), 1, "Duplicate tile should not be added")

	faction.add_controlled_tile(pos2)
	assert_eq(faction.get_territory_size(), 2, "Territory size should be 2")

	faction.remove_controlled_tile(pos1)
	assert_eq(faction.get_territory_size(), 1, "Territory size should be 1")
	assert_false(faction.controls_tile(pos1), "Should not control tile")

func test_faction_culture():
	var faction = FactionState.new(0, "Test", true)
	faction.culture["total_points"] = 0
	faction.culture["unlocked_nodes"] = []

	faction.add_culture_points(50)
	assert_eq(faction.culture["total_points"], 50, "Culture points should increase")

	faction.unlock_culture_node("node_1")
	assert_true(faction.has_culture_node("node_1"), "Should have culture node")
	assert_false(faction.has_culture_node("node_2"), "Should not have other nodes")

func test_faction_diplomacy():
	var faction = FactionState.new(0, "Test", true)

	faction.set_diplomacy(1, 50)
	assert_eq(faction.get_diplomacy(1), 50, "Diplomacy should be 50")

	faction.modify_diplomacy(1, -20)
	assert_eq(faction.get_diplomacy(1), 30, "Diplomacy should be 30")

	faction.set_diplomacy(2, 150)
	assert_eq(faction.get_diplomacy(2), 100, "Diplomacy should be clamped to 100")

	faction.set_diplomacy(3, -150)
	assert_eq(faction.get_diplomacy(3), -100, "Diplomacy should be clamped to -100")

# ============================================================================
# WORLD STATE TESTS
# ============================================================================

func test_world_state_creation():
	var world = WorldState.new()

	assert_eq(world.map_width, 200, "Map width")
	assert_eq(world.map_height, 200, "Map height")
	assert_eq(world.map_depth, 3, "Map depth")

func test_world_state_serialization():
	var world = WorldState.new()

	var tile1 = Tile.new(Vector3i(5, 5, 1), "residential", "rubble")
	var tile2 = Tile.new(Vector3i(6, 5, 1), "commercial", "building")

	world.set_tile(tile1.position, tile1)
	world.set_tile(tile2.position, tile2)

	var dict = world.to_dict()

	assert_eq(dict["map_width"], 200, "Serialized width")
	assert_eq(dict["tiles"].size(), 2, "Serialized tiles count")

func test_world_state_deserialization():
	var tile_data = {
		"position": {"x": 10, "y": 10, "z": 1},
		"tile_type": "residential",
		"terrain_type": "rubble",
		"owner": -1,
		"building": "",
		"units": [],
		"scavenge_value": 50,
		"visibility": {},
		"hazards": [],
		"movement_cost": 1,
		"defense_bonus": 0,
		"elevation": 1
	}

	var data = {
		"map_width": 100,
		"map_height": 100,
		"map_depth": 2,
		"tiles": [tile_data],
		"unique_locations": [],
		"fog_of_war": {}
	}

	var world = WorldState.new()
	world.from_dict(data)

	assert_eq(world.map_width, 100, "Deserialized width")
	assert_eq(world.map_height, 100, "Deserialized height")
	assert_eq(world.tiles.size(), 1, "Deserialized tiles")

func test_world_state_tile_management():
	var world = WorldState.new()
	var pos = Vector3i(10, 10, 1)
	var tile = Tile.new(pos, "residential", "rubble")

	world.set_tile(pos, tile)
	assert_true(world.has_tile(pos), "World should have tile")

	var retrieved = world.get_tile(pos)
	assert_not_null(retrieved, "Should retrieve tile")
	assert_eq(retrieved.position, pos, "Retrieved tile position")

	world.remove_tile(pos)
	assert_false(world.has_tile(pos), "Tile should be removed")

func test_world_state_valid_position():
	var world = WorldState.new()
	world.map_width = 10
	world.map_height = 10
	world.map_depth = 2

	assert_true(world.is_valid_position(Vector3i(5, 5, 1)), "Position should be valid")
	assert_true(world.is_valid_position(Vector3i(0, 0, 0)), "Min position should be valid")
	assert_true(world.is_valid_position(Vector3i(9, 9, 1)), "Max position should be valid")

	assert_false(world.is_valid_position(Vector3i(-1, 5, 1)), "Negative X should be invalid")
	assert_false(world.is_valid_position(Vector3i(10, 5, 1)), "Out of bounds X should be invalid")
	assert_false(world.is_valid_position(Vector3i(5, 5, 2)), "Out of bounds Z should be invalid")

func test_world_state_fog_of_war():
	var world = WorldState.new()
	var pos = Vector3i(10, 10, 1)

	world.set_visibility(0, pos, true)
	assert_true(world.is_visible_to(0, pos), "Tile should be visible to faction 0")
	assert_false(world.is_visible_to(1, pos), "Tile should not be visible to faction 1")

	world.set_visibility(0, pos, false)
	assert_false(world.is_visible_to(0, pos), "Tile should no longer be visible")

func test_world_state_unique_locations():
	var world = WorldState.new()

	var location = {"id": "loc_1", "name": "Test Location"}
	world.add_unique_location(location)

	assert_true(world.has_unique_location("loc_1"), "Should have location")

	var retrieved = world.get_unique_location("loc_1")
	assert_eq(retrieved["name"], "Test Location", "Should retrieve correct location")

# ============================================================================
# GAME STATE TESTS
# ============================================================================

func test_game_state_creation():
	var game_state = GameState.new()

	assert_not_null(game_state.world_state, "World state should be created")
	assert_not_null(game_state.turn_state, "Turn state should be created")
	assert_eq(game_state.turn_number, 1, "Initial turn should be 1")

func test_game_state_serialization():
	var game_state = GameState.new()
	game_state.turn_number = 5
	game_state.random_seed = 12345

	var faction = FactionState.new(0, "Test Faction", true)
	game_state.add_faction(faction)

	var dict = game_state.to_dict()

	assert_eq(dict["turn_number"], 5, "Serialized turn")
	assert_eq(dict["random_seed"], 12345, "Serialized seed")
	assert_eq(dict["factions"].size(), 1, "Serialized factions")

func test_game_state_deserialization():
	var faction_data = {
		"faction_id": 0,
		"faction_name": "Player",
		"is_player": true,
		"is_alive": true,
		"resources": {"scrap": 100},
		"culture": {"total_points": 0, "unlocked_nodes": []},
		"units": [],
		"buildings": [],
		"controlled_tiles": [],
		"diplomacy": {},
		"ai_personality": ""
	}

	var data = {
		"turn_number": 10,
		"world_state": {
			"map_width": 200,
			"map_height": 200,
			"map_depth": 3,
			"tiles": [],
			"unique_locations": [],
			"fog_of_war": {}
		},
		"factions": [faction_data],
		"turn_state": {
			"current_turn": 10,
			"current_phase": 0,
			"active_faction": 0,
			"actions_this_turn": [],
			"time_elapsed": 0.0
		},
		"event_queue": [],
		"victory_conditions": {},
		"game_settings": {},
		"random_seed": 54321
	}

	var game_state = GameState.new()
	game_state.from_dict(data)

	assert_eq(game_state.turn_number, 10, "Deserialized turn")
	assert_eq(game_state.random_seed, 54321, "Deserialized seed")
	assert_eq(game_state.factions.size(), 1, "Deserialized factions")

func test_game_state_round_trip():
	var original = GameState.new()
	original.turn_number = 15
	original.random_seed = 99999

	var faction1 = FactionState.new(0, "Player", true)
	var faction2 = FactionState.new(1, "AI", false)
	original.add_faction(faction1)
	original.add_faction(faction2)

	var dict = original.to_dict()
	var restored = GameState.new()
	restored.from_dict(dict)

	assert_eq(restored.turn_number, original.turn_number, "Round-trip turn")
	assert_eq(restored.random_seed, original.random_seed, "Round-trip seed")
	assert_eq(restored.factions.size(), original.factions.size(), "Round-trip factions")

func test_game_state_clone():
	var original = GameState.new()
	original.turn_number = 20
	original.add_faction(FactionState.new(0, "Test", true))

	var cloned = original.clone()

	assert_eq(cloned.turn_number, original.turn_number, "Cloned turn")
	assert_eq(cloned.factions.size(), original.factions.size(), "Cloned factions")

	# Modify clone - should not affect original
	cloned.turn_number = 25
	assert_eq(original.turn_number, 20, "Original should not change")

func test_game_state_validation():
	var game_state = GameState.new()

	# Empty state should be invalid (no factions)
	assert_false(game_state.validate(), "Empty state should be invalid")

	# Add faction
	game_state.add_faction(FactionState.new(0, "Test", true))
	assert_true(game_state.validate(), "Valid state should validate")

	# Invalid turn number
	game_state.turn_number = 0
	assert_false(game_state.validate(), "Invalid turn should fail validation")

func test_game_state_faction_management():
	var game_state = GameState.new()

	var faction1 = FactionState.new(0, "Faction 1", true)
	var faction2 = FactionState.new(1, "Faction 2", false)

	game_state.add_faction(faction1)
	game_state.add_faction(faction2)

	assert_eq(game_state.factions.size(), 2, "Should have 2 factions")

	var retrieved = game_state.get_faction(1)
	assert_not_null(retrieved, "Should retrieve faction")
	assert_eq(retrieved.faction_name, "Faction 2", "Should retrieve correct faction")

	game_state.remove_faction(0)
	assert_eq(game_state.factions.size(), 1, "Should have 1 faction")

func test_game_state_player_faction():
	var game_state = GameState.new()

	var player = FactionState.new(0, "Player", true)
	var ai = FactionState.new(1, "AI", false)

	game_state.add_faction(player)
	game_state.add_faction(ai)

	var player_faction = game_state.get_player_faction()
	assert_not_null(player_faction, "Should find player faction")
	assert_eq(player_faction.faction_name, "Player", "Should be player faction")

func test_game_state_ai_factions():
	var game_state = GameState.new()

	game_state.add_faction(FactionState.new(0, "Player", true))
	game_state.add_faction(FactionState.new(1, "AI 1", false))
	game_state.add_faction(FactionState.new(2, "AI 2", false))

	var ai_factions = game_state.get_ai_factions()
	assert_eq(ai_factions.size(), 2, "Should have 2 AI factions")

func test_game_state_event_queue():
	var game_state = GameState.new()

	game_state.queue_event({"id": "event_1"})
	game_state.queue_event({"id": "event_2"})

	assert_true(game_state.has_pending_events(), "Should have pending events")

	var event = game_state.pop_event()
	assert_eq(event["id"], "event_1", "Should pop first event")

	event = game_state.pop_event()
	assert_eq(event["id"], "event_2", "Should pop second event")

	assert_false(game_state.has_pending_events(), "Should have no pending events")
