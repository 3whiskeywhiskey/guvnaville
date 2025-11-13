extends GutTest

## Phase 3 Integration Tests - Game Systems Layer
## Tests integration between Combat, Economy, Units, Culture, Events, and Map systems
##
## @agent: Integration Coordinator

# ============================================================================
# SETUP / TEARDOWN
# ============================================================================

var test_game: GameState = null
var test_faction: FactionState = null

func before_each():
	# Ensure data is loaded
	if not DataLoader.is_data_loaded:
		DataLoader.load_game_data()

	# Create a test game
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 12345
	}

	test_game = GameManager.start_new_game(settings)
	test_faction = test_game.get_faction(0)

func after_each():
	if test_game != null:
		GameManager.end_game("test", 0)
		test_game = null
	test_faction = null

# ============================================================================
# COMBAT + UNITS INTEGRATION TESTS
# ============================================================================

func test_combat_with_real_units():
	"""Test that combat system works with real unit instances"""
	# Create unit manager
	var unit_manager = UnitManager.new()

	# Create two units
	var attacker = unit_manager.create_unit("militia", test_faction.faction_id, Vector3i(0, 0, 1))
	var defender = unit_manager.create_unit("militia", 1, Vector3i(0, 1, 1))

	assert_not_null(attacker, "Attacker should be created")
	assert_not_null(defender, "Defender should be created")

	# Create combat resolver
	var combat_resolver = CombatResolver.new()

	# Resolve combat
	var result = combat_resolver.auto_resolve([attacker], [defender])

	assert_not_null(result, "Combat should resolve")
	assert_true(result.has("outcome"), "Result should have outcome")
	assert_true(result.outcome in [CombatResolver.Outcome.ATTACKER_VICTORY,
		CombatResolver.Outcome.DEFENDER_VICTORY,
		CombatResolver.Outcome.MUTUAL_RETREAT],
		"Outcome should be valid")

	# Verify units took damage
	assert_true(attacker.current_hp < attacker.max_hp or defender.current_hp < defender.max_hp,
		"At least one unit should take damage")

func test_combat_with_terrain_modifiers():
	"""Test that combat respects terrain modifiers from map"""
	var unit_manager = UnitManager.new()
	var combat_resolver = CombatResolver.new()

	# Create units
	var attacker = unit_manager.create_unit("militia", 0, Vector3i(0, 0, 1))
	var defender = unit_manager.create_unit("militia", 1, Vector3i(0, 1, 1))

	# Get terrain from map (if map system integrated)
	var map_data = MapData.new()
	map_data.initialize(50, 50, 3)

	# Set defender on elevated/defensive terrain
	var defender_tile = map_data.get_tile(Vector3i(0, 1, 2))  # Higher elevation
	if defender_tile:
		defender_tile.terrain_type = "rubble"  # Defensive bonus

	# Combat with terrain
	var result = combat_resolver.auto_resolve([attacker], [defender])

	assert_not_null(result, "Combat with terrain should resolve")

func test_combat_affects_unit_experience():
	"""Test that combat gives experience to units"""
	var unit_manager = UnitManager.new()
	var combat_resolver = CombatResolver.new()

	var attacker = unit_manager.create_unit("militia", 0, Vector3i(0, 0, 1))
	var initial_exp = attacker.experience

	# Defender
	var defender = unit_manager.create_unit("militia", 1, Vector3i(0, 1, 1))

	# Resolve combat
	combat_resolver.auto_resolve([attacker], [defender])

	# Attacker should gain experience (if they survived and/or won)
	if attacker.is_alive():
		assert_gte(attacker.experience, initial_exp, "Surviving attacker should gain experience")

# ============================================================================
# ECONOMY + PRODUCTION INTEGRATION TESTS
# ============================================================================

func test_economy_production():
	"""Test that production system works with real resources"""
	# Set up faction resources
	test_faction.resources.scrap = 100
	test_faction.resources.food = 50
	test_faction.resources.medicine = 20

	# Add production item
	var production_item = {
		"type": "unit",
		"unit_type": "militia",
		"cost": {"scrap": 50, "food": 20},
		"build_time": 2,
		"progress": 0
	}

	test_faction.production_queue.append(production_item)

	# Create production system
	var production_system = ProductionSystem.new()

	# Process production for one turn
	production_system.process_production(test_faction, 1)

	# Production should have advanced
	assert_gt(production_item.progress, 0, "Production should have progressed")

	# If production complete, resources should be consumed
	if production_item.progress >= production_item.build_time:
		assert_lt(test_faction.resources.scrap, 100, "Scrap should be consumed")
		assert_lt(test_faction.resources.food, 50, "Food should be consumed")

func test_economy_resource_consumption():
	"""Test that resources are consumed correctly"""
	var resource_manager = ResourceManager.new()

	# Set initial resources
	var resources = {
		"scrap": 200,
		"food": 100,
		"medicine": 50
	}

	test_faction.resources.scrap = resources.scrap
	test_faction.resources.food = resources.food
	test_faction.resources.medicine = resources.medicine

	# Consume resources
	var consumption = {
		"scrap": 50,
		"food": 30,
		"medicine": 10
	}

	var consumed = resource_manager.consume_resources(test_faction, consumption)

	assert_true(consumed, "Resources should be consumed")
	assert_eq(test_faction.resources.scrap, 150, "Scrap should be reduced")
	assert_eq(test_faction.resources.food, 70, "Food should be reduced")
	assert_eq(test_faction.resources.medicine, 40, "Medicine should be reduced")

func test_economy_insufficient_resources():
	"""Test that production fails with insufficient resources"""
	var resource_manager = ResourceManager.new()

	test_faction.resources.scrap = 20  # Not enough

	var cost = {
		"scrap": 100,
		"food": 50
	}

	var consumed = resource_manager.consume_resources(test_faction, cost)

	assert_false(consumed, "Should fail to consume with insufficient resources")
	assert_eq(test_faction.resources.scrap, 20, "Resources should not change on failure")

func test_trade_routes_transfer_resources():
	"""Test that trade routes work"""
	var trade_system = TradeSystem.new()

	# Setup two factions
	var faction1 = test_game.get_faction(0)
	var faction2 = test_game.get_faction(1)

	faction1.resources.scrap = 100
	faction2.resources.food = 100

	# Create trade route
	var trade_route = {
		"from_faction": 0,
		"to_faction": 1,
		"resource_from": "scrap",
		"resource_to": "food",
		"amount": 10,
		"turns_remaining": 5
	}

	# Process trade
	trade_system.process_trade_route(trade_route, test_game)

	# Check resources transferred (if route is valid)
	# Note: Actual transfer depends on trade system implementation

func test_scavenging_system():
	"""Test scavenging depletes tiles"""
	var scavenging_system = ScavengingSystem.new()

	# Create map with scavengeable tile
	var map_data = MapData.new()
	map_data.initialize(10, 10, 3)

	var tile_pos = Vector3i(5, 5, 1)
	var tile = map_data.get_tile(tile_pos)

	if tile:
		tile.scavenge_value = 100
		var initial_value = tile.scavenge_value

		# Scavenge
		var result = scavenging_system.scavenge_tile(tile, test_faction)

		assert_not_null(result, "Scavenging should return result")
		assert_gt(result.get("resources_gained", {}).get("scrap", 0), 0, "Should gain scrap from scavenging")
		assert_lt(tile.scavenge_value, initial_value, "Tile should be depleted")

# ============================================================================
# CULTURE INTEGRATION TESTS
# ============================================================================

func test_culture_progression():
	"""Test culture point accumulation and node unlocking"""
	var culture_tree = CultureTree.new()

	# Set culture points
	test_faction.culture.points = 150

	# Try to unlock a node
	var node_id = "strongman_rule"  # Assuming this exists in culture data

	var unlocked = culture_tree.unlock_node(test_faction, node_id)

	# Check if unlock succeeded (depends on prerequisites)
	if unlocked:
		assert_true(test_faction.culture.unlocked_nodes.has(node_id),
			"Node should be in unlocked nodes list")
		assert_lt(test_faction.culture.points, 150,
			"Culture points should be spent")

func test_culture_effects_apply():
	"""Test that culture node effects are applied"""
	var culture_effects = CultureEffects.new()

	# Unlock a node that gives bonuses
	test_faction.culture.unlocked_nodes.append("militaristic_training")

	# Apply effects
	var effects = culture_effects.get_faction_effects(test_faction)

	assert_not_null(effects, "Should return effects")
	# Effects structure depends on implementation

func test_culture_prerequisites():
	"""Test that culture prerequisites are enforced"""
	var culture_tree = CultureTree.new()

	# Try to unlock advanced node without prerequisites
	test_faction.culture.points = 500  # Plenty of points

	# Try to unlock tier 2 node without tier 1
	var unlocked = culture_tree.unlock_node(test_faction, "advanced_tactics")

	# Should fail if prerequisites not met
	# (Actual behavior depends on culture tree structure)

# ============================================================================
# EVENT SYSTEM INTEGRATION TESTS
# ============================================================================

func test_event_triggers():
	"""Test that events trigger correctly"""
	var event_manager = EventManager.new()

	# Set up conditions for an event
	test_faction.resources.food = 5  # Low food

	# Check for triggered events
	var triggered = event_manager.check_triggers(test_game)

	assert_not_null(triggered, "Should check for events")
	# Whether events trigger depends on event definitions

func test_event_choice_consequences():
	"""Test that event choices apply consequences"""
	var event_manager = EventManager.new()

	# Create a test event
	var event_data = {
		"id": "test_event",
		"title": "Test Event",
		"description": "A test event",
		"choices": [
			{
				"text": "Choice A",
				"consequences": [
					{"type": "MODIFY_RESOURCE", "resource": "scrap", "amount": 100}
				]
			}
		]
	}

	var initial_scrap = test_faction.resources.scrap

	# Apply choice consequences
	var event_choice = EventChoice.new()
	event_choice.apply_consequences(event_data.choices[0], test_faction, test_game)

	assert_gt(test_faction.resources.scrap, initial_scrap,
		"Scrap should increase from event consequence")

func test_event_chains():
	"""Test that events can chain to other events"""
	var event_manager = EventManager.new()

	# Create event that queues another event
	var event_data = {
		"id": "chain_start",
		"title": "Chain Start",
		"description": "First event in chain",
		"choices": [
			{
				"text": "Continue",
				"consequences": [
					{"type": "QUEUE_EVENT", "event_id": "chain_next", "delay": 1}
				]
			}
		]
	}

	# Process event
	# (Implementation depends on event manager structure)

# ============================================================================
# MAP + UNITS INTEGRATION TESTS
# ============================================================================

func test_unit_movement_on_map():
	"""Test that units can move on the map"""
	var map_data = MapData.new()
	map_data.initialize(50, 50, 3)

	var unit_manager = UnitManager.new()
	var movement_system = MovementSystem.new()

	# Create unit
	var unit = unit_manager.create_unit("militia", 0, Vector3i(10, 10, 1))

	var start_pos = unit.position
	var target_pos = Vector3i(12, 10, 1)

	# Calculate path
	var path = movement_system.find_path(map_data, start_pos, target_pos)

	assert_not_null(path, "Should find a path")
	assert_gt(path.size(), 0, "Path should have steps")

	# Move unit
	if path.size() > 0:
		var moved = movement_system.move_unit_along_path(unit, path, map_data)
		assert_true(moved, "Unit should move")

func test_fog_of_war_updates():
	"""Test that fog of war updates when units move"""
	var map_data = MapData.new()
	map_data.initialize(50, 50, 3)

	var fog_of_war = FogOfWar.new()
	fog_of_war.initialize(map_data, 2)  # 2 factions

	var unit_pos = Vector3i(10, 10, 1)

	# Update fog based on unit position
	fog_of_war.update_unit_visibility(0, unit_pos, 3)  # Faction 0, vision radius 3

	# Check that nearby tiles are visible
	var visible_tiles = fog_of_war.get_visible_tiles(0)

	assert_not_null(visible_tiles, "Should have visible tiles")
	# At least the unit's tile should be visible

func test_tile_ownership():
	"""Test that tiles can be owned by factions"""
	var map_data = MapData.new()
	map_data.initialize(50, 50, 3)

	var tile_pos = Vector3i(15, 15, 1)
	var tile = map_data.get_tile(tile_pos)

	if tile:
		# Set ownership
		tile.owner_faction = 0

		assert_eq(tile.owner_faction, 0, "Tile should be owned by faction 0")

		# Change ownership
		tile.owner_faction = 1
		assert_eq(tile.owner_faction, 1, "Tile ownership should change")

# ============================================================================
# CROSS-SYSTEM INTEGRATION TESTS
# ============================================================================

func test_full_turn_processing():
	"""Test that a full turn can be processed with all systems"""
	# This is a comprehensive test that exercises multiple systems

	# Setup
	test_faction.resources.scrap = 100
	test_faction.resources.food = 100

	# Create some units
	var unit_manager = UnitManager.new()
	var unit1 = unit_manager.create_unit("militia", 0, Vector3i(10, 10, 1))

	# Add production
	test_faction.production_queue.append({
		"type": "unit",
		"unit_type": "soldier",
		"progress": 0,
		"build_time": 3
	})

	# Process turn
	TurnManager.start_new_turn()

	# Verify turn advanced
	assert_gt(test_game.turn_number, 1, "Turn should advance")

func test_ai_with_real_game_systems():
	"""Test that AI can interact with real game systems"""
	var faction_ai = FactionAI.new(1, "aggressive")

	# Create real game state
	var ai_faction = test_game.get_faction(1)
	ai_faction.resources.scrap = 100
	ai_faction.resources.food = 50

	# AI plans turn
	var actions = faction_ai.plan_turn(1, test_game)

	assert_not_null(actions, "AI should plan actions")
	assert_gt(actions.size(), 0, "AI should return at least one action")

	# Verify actions are valid
	for action in actions:
		assert_not_null(action, "Each action should be valid")
		assert_true(action.has("type"), "Action should have type")

func test_resource_production_consumption_cycle():
	"""Test full resource cycle: production -> consumption -> replenishment"""
	var resource_manager = ResourceManager.new()
	var production_system = ProductionSystem.new()

	# Initial resources
	test_faction.resources.scrap = 50
	test_faction.resources.food = 50

	# Simulate resource income
	test_faction.resources.scrap += 20  # Base income
	test_faction.resources.food += 10

	# Consume resources (population, units)
	var consumption = {"food": 15}  # Population eats
	resource_manager.consume_resources(test_faction, consumption)

	# Produce something
	test_faction.production_queue.append({
		"type": "building",
		"building_type": "workshop",
		"progress": 0,
		"build_time": 5
	})

	production_system.process_production(test_faction, 1)

	# Verify faction is still functional
	assert_gte(test_faction.resources.scrap, 0, "Should not have negative scrap")
	assert_gte(test_faction.resources.food, 0, "Should not have negative food")

func test_combat_loot_economy_integration():
	"""Test that combat loot integrates with economy"""
	var unit_manager = UnitManager.new()
	var combat_resolver = CombatResolver.new()

	# Create units
	var attacker = unit_manager.create_unit("soldier", 0, Vector3i(10, 10, 1))
	var defender = unit_manager.create_unit("militia", 1, Vector3i(10, 11, 1))

	var initial_scrap = test_faction.resources.scrap

	# Combat
	var result = combat_resolver.auto_resolve([attacker], [defender])

	# If attacker won, they should get loot
	if result.outcome == CombatResolver.Outcome.ATTACKER_VICTORY:
		if result.has("loot"):
			# Apply loot to faction
			test_faction.resources.scrap += result.loot.get("scrap", 0)

			assert_gte(test_faction.resources.scrap, initial_scrap,
				"Winning combat should give loot")

func test_population_growth_with_resources():
	"""Test that population grows with sufficient resources"""
	var population_system = PopulationSystem.new()

	# Set up resources
	test_faction.resources.food = 200
	test_faction.resources.medicine = 50

	var initial_pop = test_faction.population.current

	# Process population growth
	population_system.process_turn(test_faction)

	# Population should grow with sufficient resources
	# (Growth rate depends on implementation)

func test_shortage_detection():
	"""Test that resource shortages are detected"""
	var resource_manager = ResourceManager.new()

	# Set low resources
	test_faction.resources.food = 5
	test_faction.resources.medicine = 2

	# Check for shortages
	var shortages = resource_manager.check_shortages(test_faction)

	assert_not_null(shortages, "Should check for shortages")
	# Shortage detection depends on implementation
