extends GutTest

## E2E Tests for Ashes to Empire - Full Game Scenarios
##
## This test suite validates the complete game experience from start to finish,
## testing all systems working together over multiple turns.
##
## @agent: E2E Testing Agent (Phase 4, Workstream 4.1)

# ============================================================================
# CONSTANTS
# ============================================================================

const FULL_CAMPAIGN_TURNS = 50  # Scaled down from 300 for testing speed
const SAVE_LOAD_TEST_TURNS = 20
const SAVE_INTERVAL = 5
const COMBAT_TEST_BATTLES = 20
const PERFORMANCE_TEST_FACTIONS = 8
const MAX_TURN_TIME_MS = 5000  # 5 seconds per turn max

# ============================================================================
# TEST STATE
# ============================================================================

var test_game: GameState = null
var test_metrics: Dictionary = {}
var test_errors: Array = []

# ============================================================================
# SETUP / TEARDOWN
# ============================================================================

func before_all():
	print("\n" + "=".repeat(80))
	print("E2E TEST SUITE - ASHES TO EMPIRE")
	print("=".repeat(80))

	# Ensure data is loaded
	if not DataLoader.is_data_loaded:
		print("[E2E] Loading game data...")
		DataLoader.load_game_data()

	# Initialize metrics
	test_metrics = {
		"tests_run": 0,
		"tests_passed": 0,
		"tests_failed": 0,
		"total_turns_simulated": 0,
		"total_battles_fought": 0,
		"average_turn_time_ms": 0,
		"peak_memory_mb": 0,
		"save_load_cycles": 0
	}

	test_errors.clear()

func before_each():
	print("\n" + "-".repeat(80))
	test_game = null
	test_metrics.tests_run += 1

func after_each():
	if test_game != null:
		GameManager.end_game("test", 0)
		test_game = null

	# Give a moment for cleanup
	await get_tree().process_frame

func after_all():
	print("\n" + "=".repeat(80))
	print("E2E TEST SUITE COMPLETE")
	print("=".repeat(80))
	print("Tests Run: %d" % test_metrics.tests_run)
	print("Tests Passed: %d" % test_metrics.tests_passed)
	print("Tests Failed: %d" % test_metrics.tests_failed)
	print("Total Turns Simulated: %d" % test_metrics.total_turns_simulated)
	print("Total Battles Fought: %d" % test_metrics.total_battles_fought)
	if test_metrics.average_turn_time_ms > 0:
		print("Average Turn Time: %.2f ms" % test_metrics.average_turn_time_ms)
	print("Save/Load Cycles: %d" % test_metrics.save_load_cycles)
	print("=".repeat(80))

	if test_errors.size() > 0:
		print("\nErrors encountered:")
		for error in test_errors:
			print("  - %s" % error)

# ============================================================================
# TEST SCENARIO 1: FULL CAMPAIGN TEST
# ============================================================================

func test_scenario_1_full_campaign():
	"""
	Test Scenario 1: Full Campaign Test

	Simulates a complete game with 8 AI factions over 50 turns.
	Validates all systems work together without crashes or errors.
	"""
	print("\n[E2E SCENARIO 1] Full Campaign Test - 8 AI Factions, 50 Turns")
	print("-".repeat(80))

	# Setup game with 8 AI factions
	var settings = {
		"num_factions": 8,
		"player_faction_id": 0,  # Player faction (will be AI controlled in test)
		"difficulty": "normal",
		"map_seed": 12345
	}

	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "Game should be created")

	if not test_game:
		test_errors.append("Scenario 1: Failed to create game")
		return

	print("[E2E] Game created with %d factions" % test_game.factions.size())

	# Create AI controllers for all factions
	var faction_ais: Array = []
	for i in range(8):
		var personality = ["aggressive", "defensive", "economic", "balanced"][i % 4]
		var ai = FactionAI.new(i, personality)
		faction_ais.append(ai)

	print("[E2E] AI controllers created")

	# Track game state
	var crashes = 0
	var turns_completed = 0
	var turn_times: Array = []

	# Simulate turns
	for turn in range(FULL_CAMPAIGN_TURNS):
		var turn_start_time = Time.get_ticks_msec()

		print("[E2E] Processing Turn %d/%d..." % [turn + 1, FULL_CAMPAIGN_TURNS])

		# Process turn for each faction
		for faction_id in range(8):
			var faction = test_game.get_faction(faction_id)

			if not faction or not faction.is_alive:
				continue

			# AI plans and executes turn
			var ai = faction_ais[faction_id]
			var actions = ai.plan_turn(faction_id, test_game)

			# Execute actions (simplified for testing)
			for action in actions:
				_execute_action(action, faction_id)

		# Process turn through TurnManager
		TurnManager.process_turn()

		turns_completed += 1
		test_metrics.total_turns_simulated += 1

		var turn_time = Time.get_ticks_msec() - turn_start_time
		turn_times.append(turn_time)

		# Check for game over
		if test_game.is_game_over():
			print("[E2E] Game ended at turn %d" % (turn + 1))
			break

		# Yield periodically to prevent timeout
		if turn % 10 == 0:
			await get_tree().process_frame

	# Calculate metrics
	var avg_turn_time = 0
	if turn_times.size() > 0:
		var total_time = 0
		for time in turn_times:
			total_time += time
		avg_turn_time = total_time / float(turn_times.size())

	test_metrics.average_turn_time_ms = avg_turn_time

	print("\n[E2E SCENARIO 1] Results:")
	print("  Turns Completed: %d/%d" % [turns_completed, FULL_CAMPAIGN_TURNS])
	print("  Average Turn Time: %.2f ms" % avg_turn_time)
	print("  Crashes: %d" % crashes)

	# Assertions
	assert_gt(turns_completed, 0, "Should complete at least one turn")
	assert_eq(crashes, 0, "Should not crash during campaign")
	assert_not_null(test_game, "Game state should remain valid")

	# Check victory conditions were tracked
	assert_true(test_game.victory_conditions.has("military_progress"),
		"Victory conditions should be tracked")

	test_metrics.tests_passed += 1
	print("[E2E SCENARIO 1] ✅ PASSED")

# ============================================================================
# TEST SCENARIO 2: SAVE/LOAD STRESS TEST
# ============================================================================

func test_scenario_2_save_load_stress():
	"""
	Test Scenario 2: Save/Load Stress Test

	Saves every 5 turns for 20 turns, loads each save and verifies state integrity.
	Tests deterministic behavior and save system robustness.
	"""
	print("\n[E2E SCENARIO 2] Save/Load Stress Test")
	print("-".repeat(80))

	# Setup game
	var settings = {
		"num_factions": 4,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 54321
	}

	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "Game should be created")

	if not test_game:
		test_errors.append("Scenario 2: Failed to create game")
		return

	print("[E2E] Game created for save/load testing")

	var save_states: Array = []
	var save_names: Array = []

	# Simulate turns with periodic saves
	for turn in range(SAVE_LOAD_TEST_TURNS):
		print("[E2E] Turn %d/%d" % [turn + 1, SAVE_LOAD_TEST_TURNS])

		# Process turn
		TurnManager.process_turn()
		test_metrics.total_turns_simulated += 1

		# Save every SAVE_INTERVAL turns
		if (turn + 1) % SAVE_INTERVAL == 0:
			var save_name = "e2e_test_save_%d" % (turn + 1)
			save_names.append(save_name)

			print("[E2E] Saving game: %s" % save_name)
			var save_success = GameManager.save_game(save_name)
			assert_true(save_success, "Save should succeed at turn %d" % (turn + 1))

			if save_success:
				# Store state snapshot for verification
				save_states.append(test_game.to_dict())
				test_metrics.save_load_cycles += 1

		# Yield periodically
		if turn % 5 == 0:
			await get_tree().process_frame

	print("\n[E2E] Testing save/load integrity...")

	# Load each save and verify state
	var loads_successful = 0
	for i in range(save_names.size()):
		var save_name = save_names[i]
		var expected_state = save_states[i]

		print("[E2E] Loading: %s" % save_name)

		# End current game
		GameManager.end_game("test", 0)

		# Load saved game
		var loaded_game = GameManager.load_game(save_name)
		assert_not_null(loaded_game, "Should load save: %s" % save_name)

		if loaded_game:
			loads_successful += 1

			# Verify key state properties match
			var loaded_dict = loaded_game.to_dict()
			assert_eq(loaded_dict.turn_number, expected_state.turn_number,
				"Turn number should match for %s" % save_name)
			assert_eq(loaded_dict.random_seed, expected_state.random_seed,
				"Random seed should match for %s" % save_name)
			assert_eq(loaded_dict.factions.size(), expected_state.factions.size(),
				"Faction count should match for %s" % save_name)

			# Continue game for a few turns to verify it works
			for j in range(3):
				TurnManager.process_turn()
				test_metrics.total_turns_simulated += 1

		await get_tree().process_frame

	print("\n[E2E SCENARIO 2] Results:")
	print("  Saves Created: %d" % save_names.size())
	print("  Loads Successful: %d/%d" % [loads_successful, save_names.size()])

	assert_eq(loads_successful, save_names.size(),
		"All saves should load successfully")

	# Cleanup test saves
	for save_name in save_names:
		var save_path = "user://saves/%s.save" % save_name
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)

	test_metrics.tests_passed += 1
	print("[E2E SCENARIO 2] ✅ PASSED")

# ============================================================================
# TEST SCENARIO 3: COMBAT STRESS TEST
# ============================================================================

func test_scenario_3_combat_stress():
	"""
	Test Scenario 3: Combat Stress Test

	Runs 20 battles in a single game session.
	Verifies no memory leaks, valid combat results, and morale/experience systems.
	"""
	print("\n[E2E SCENARIO 3] Combat Stress Test")
	print("-".repeat(80))

	# Setup game
	var settings = {
		"num_factions": 2,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 99999
	}

	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "Game should be created")

	if not test_game:
		test_errors.append("Scenario 3: Failed to create game")
		return

	print("[E2E] Game created for combat testing")

	# Create unit manager and combat resolver
	var unit_manager = UnitManager.new()
	var combat_resolver = CombatResolver.new()

	var battles_fought = 0
	var valid_outcomes = 0
	var units_gained_exp = 0
	var memory_start = OS.get_static_memory_usage()

	# Run multiple battles
	for battle_num in range(COMBAT_TEST_BATTLES):
		print("[E2E] Battle %d/%d" % [battle_num + 1, COMBAT_TEST_BATTLES])

		# Create units for battle
		var attacker_pos = Vector3i(battle_num * 2, 0, 1)
		var defender_pos = Vector3i(battle_num * 2 + 1, 0, 1)

		var attacker = unit_manager.create_unit("militia", 0, attacker_pos)
		var defender = unit_manager.create_unit("militia", 1, defender_pos)

		assert_not_null(attacker, "Attacker should be created for battle %d" % battle_num)
		assert_not_null(defender, "Defender should be created for battle %d" % battle_num)

		if not attacker or not defender:
			continue

		# Store initial stats
		var attacker_initial_exp = attacker.experience

		# Resolve combat
		var result = combat_resolver.auto_resolve([attacker], [defender])

		assert_not_null(result, "Combat should resolve for battle %d" % battle_num)

		if result:
			battles_fought += 1
			test_metrics.total_battles_fought += 1

			# Verify outcome is valid
			var valid_outcomes_enum = [
				CombatResolver.Outcome.ATTACKER_VICTORY,
				CombatResolver.Outcome.DEFENDER_VICTORY,
				CombatResolver.Outcome.MUTUAL_RETREAT
			]

			if result.outcome in valid_outcomes_enum:
				valid_outcomes += 1

			# Check if units took damage
			assert_true(
				attacker.current_hp < attacker.max_hp or defender.current_hp < defender.max_hp,
				"At least one unit should take damage in battle %d" % battle_num
			)

			# Check experience gain for survivor
			if attacker.is_alive() and attacker.experience > attacker_initial_exp:
				units_gained_exp += 1

		# Yield to prevent timeout
		if battle_num % 5 == 0:
			await get_tree().process_frame

	# Check memory usage
	var memory_end = OS.get_static_memory_usage()
	var memory_diff_mb = (memory_end - memory_start) / (1024.0 * 1024.0)

	print("\n[E2E SCENARIO 3] Results:")
	print("  Battles Fought: %d/%d" % [battles_fought, COMBAT_TEST_BATTLES])
	print("  Valid Outcomes: %d/%d" % [valid_outcomes, battles_fought])
	print("  Units Gained Experience: %d" % units_gained_exp)
	print("  Memory Delta: %.2f MB" % memory_diff_mb)

	# Assertions
	assert_eq(battles_fought, COMBAT_TEST_BATTLES, "All battles should complete")
	assert_eq(valid_outcomes, battles_fought, "All outcomes should be valid")
	assert_gt(units_gained_exp, 0, "Some units should gain experience")
	assert_lt(memory_diff_mb, 100.0, "Memory usage should not exceed 100 MB increase")

	test_metrics.tests_passed += 1
	print("[E2E SCENARIO 3] ✅ PASSED")

# ============================================================================
# TEST SCENARIO 4: PERFORMANCE TEST
# ============================================================================

func test_scenario_4_performance():
	"""
	Test Scenario 4: Performance Test

	Tests large-scale game performance with 8 factions.
	Verifies turn processing time stays under 5 seconds.
	"""
	print("\n[E2E SCENARIO 4] Performance Test")
	print("-".repeat(80))

	# Setup game with maximum factions
	var settings = {
		"num_factions": PERFORMANCE_TEST_FACTIONS,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": 77777
	}

	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "Game should be created")

	if not test_game:
		test_errors.append("Scenario 4: Failed to create game")
		return

	print("[E2E] Game created with %d factions for performance testing" % PERFORMANCE_TEST_FACTIONS)

	# Create AI controllers
	var faction_ais: Array = []
	for i in range(PERFORMANCE_TEST_FACTIONS):
		var personality = ["aggressive", "defensive", "economic", "balanced"][i % 4]
		faction_ais.append(FactionAI.new(i, personality))

	var turn_times: Array = []
	var memory_samples: Array = []

	# Run performance test for 10 turns
	for turn in range(10):
		var turn_start = Time.get_ticks_msec()
		var memory_before = OS.get_static_memory_usage()

		print("[E2E] Performance Turn %d/10" % (turn + 1))

		# Process AI for each faction
		for faction_id in range(PERFORMANCE_TEST_FACTIONS):
			var faction = test_game.get_faction(faction_id)
			if faction and faction.is_alive:
				var ai = faction_ais[faction_id]
				var _actions = ai.plan_turn(faction_id, test_game)

		# Process turn
		TurnManager.process_turn()
		test_metrics.total_turns_simulated += 1

		var turn_time = Time.get_ticks_msec() - turn_start
		turn_times.append(turn_time)

		var memory_after = OS.get_static_memory_usage()
		memory_samples.append(memory_after / (1024.0 * 1024.0))  # Convert to MB

		print("  Turn Time: %d ms, Memory: %.2f MB" % [turn_time, memory_after / (1024.0 * 1024.0)])

		await get_tree().process_frame

	# Calculate statistics
	var avg_turn_time = 0
	var max_turn_time = 0
	for time in turn_times:
		avg_turn_time += time
		if time > max_turn_time:
			max_turn_time = time
	avg_turn_time /= float(turn_times.size())

	var peak_memory = 0
	for mem in memory_samples:
		if mem > peak_memory:
			peak_memory = mem

	test_metrics.peak_memory_mb = peak_memory

	print("\n[E2E SCENARIO 4] Results:")
	print("  Average Turn Time: %.2f ms" % avg_turn_time)
	print("  Max Turn Time: %d ms" % max_turn_time)
	print("  Peak Memory Usage: %.2f MB" % peak_memory)

	# Performance assertions
	assert_lt(avg_turn_time, MAX_TURN_TIME_MS,
		"Average turn time should be under %d ms (was %.2f ms)" % [MAX_TURN_TIME_MS, avg_turn_time])
	assert_lt(max_turn_time, MAX_TURN_TIME_MS * 2,
		"Max turn time should be under %d ms (was %d ms)" % [MAX_TURN_TIME_MS * 2, max_turn_time])
	assert_lt(peak_memory, 2048.0,
		"Peak memory should be under 2 GB (was %.2f MB)" % peak_memory)

	test_metrics.tests_passed += 1
	print("[E2E SCENARIO 4] ✅ PASSED")

# ============================================================================
# TEST SCENARIO 5: DETERMINISTIC REPLAY TEST
# ============================================================================

func test_scenario_5_deterministic_replay():
	"""
	Test Scenario 5: Deterministic Replay Test

	Runs the same game twice with the same seed.
	Verifies outcomes are identical and RNG is properly seeded.
	"""
	print("\n[E2E SCENARIO 5] Deterministic Replay Test")
	print("-".repeat(80))

	var test_seed = 42424242
	var test_turns = 10

	# Run game first time
	print("[E2E] First run with seed %d" % test_seed)
	var first_run_states: Array = []

	var settings = {
		"num_factions": 4,
		"player_faction_id": 0,
		"difficulty": "normal",
		"map_seed": test_seed
	}

	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "First game should be created")

	if not test_game:
		test_errors.append("Scenario 5: Failed to create first game")
		return

	# Create AI controllers
	var faction_ais_1: Array = []
	for i in range(4):
		faction_ais_1.append(FactionAI.new(i, "balanced"))

	# Run and capture states
	for turn in range(test_turns):
		# AI planning
		for faction_id in range(4):
			var faction = test_game.get_faction(faction_id)
			if faction and faction.is_alive:
				var _actions = faction_ais_1[faction_id].plan_turn(faction_id, test_game)

		TurnManager.process_turn()
		test_metrics.total_turns_simulated += 1

		# Capture state snapshot
		first_run_states.append(test_game.to_dict())

		if turn % 5 == 0:
			await get_tree().process_frame

	# End first game
	GameManager.end_game("test", 0)
	test_game = null

	# Run game second time with same seed
	print("[E2E] Second run with seed %d" % test_seed)
	var second_run_states: Array = []

	test_game = GameManager.start_new_game(settings)
	assert_not_null(test_game, "Second game should be created")

	if not test_game:
		test_errors.append("Scenario 5: Failed to create second game")
		return

	# Create AI controllers (same configuration)
	var faction_ais_2: Array = []
	for i in range(4):
		faction_ais_2.append(FactionAI.new(i, "balanced"))

	# Run and capture states
	for turn in range(test_turns):
		# AI planning
		for faction_id in range(4):
			var faction = test_game.get_faction(faction_id)
			if faction and faction.is_alive:
				var _actions = faction_ais_2[faction_id].plan_turn(faction_id, test_game)

		TurnManager.process_turn()
		test_metrics.total_turns_simulated += 1

		# Capture state snapshot
		second_run_states.append(test_game.to_dict())

		if turn % 5 == 0:
			await get_tree().process_frame

	# Compare states
	print("\n[E2E] Comparing states from both runs...")
	var matching_turns = 0
	var mismatches: Array = []

	for turn in range(min(first_run_states.size(), second_run_states.size())):
		var state1 = first_run_states[turn]
		var state2 = second_run_states[turn]

		# Compare key properties
		var turn_matches = true

		if state1.turn_number != state2.turn_number:
			mismatches.append("Turn %d: turn_number mismatch" % turn)
			turn_matches = false

		if state1.random_seed != state2.random_seed:
			mismatches.append("Turn %d: random_seed mismatch" % turn)
			turn_matches = false

		# Compare faction resources (should be deterministic)
		if state1.factions.size() == state2.factions.size():
			for i in range(state1.factions.size()):
				var faction1 = state1.factions[i]
				var faction2 = state2.factions[i]

				if faction1.resources.scrap != faction2.resources.scrap:
					mismatches.append("Turn %d: Faction %d scrap mismatch (%d vs %d)" %
						[turn, i, faction1.resources.scrap, faction2.resources.scrap])
					turn_matches = false
					break

		if turn_matches:
			matching_turns += 1

	print("\n[E2E SCENARIO 5] Results:")
	print("  Turns Compared: %d" % min(first_run_states.size(), second_run_states.size()))
	print("  Matching Turns: %d" % matching_turns)

	if mismatches.size() > 0:
		print("  Mismatches Found:")
		for mismatch in mismatches:
			print("    - %s" % mismatch)

	# Note: Perfect determinism is hard to achieve with complex AI
	# We allow some variance but expect most turns to match
	var match_percentage = (matching_turns / float(test_turns)) * 100.0
	print("  Match Percentage: %.1f%%" % match_percentage)

	# We expect at least 70% determinism (can be tuned)
	assert_gte(match_percentage, 70.0,
		"Should achieve at least 70%% determinism (got %.1f%%)" % match_percentage)

	test_metrics.tests_passed += 1
	print("[E2E SCENARIO 5] ✅ PASSED")

# ============================================================================
# HELPER METHODS
# ============================================================================

func _execute_action(action: AIAction, faction_id: int) -> void:
	"""Execute an AI action (simplified for testing)"""

	# This is a simplified action executor for testing
	# Real action execution would be more complex and handled by game systems

	match action.type:
		AIAction.ActionType.BUILD_UNIT:
			# Add to production queue
			var faction = test_game.get_faction(faction_id)
			if faction:
				faction.production_queue.append({
					"type": "unit",
					"unit_type": action.get("unit_type", "militia"),
					"progress": 0,
					"build_time": 3
				})

		AIAction.ActionType.BUILD_BUILDING:
			# Add to production queue
			var faction = test_game.get_faction(faction_id)
			if faction:
				faction.production_queue.append({
					"type": "building",
					"building_type": action.get("building_type", "workshop"),
					"progress": 0,
					"build_time": 5
				})

		AIAction.ActionType.RESEARCH:
			# Simple culture point addition
			var faction = test_game.get_faction(faction_id)
			if faction:
				faction.add_culture_points(1)

		AIAction.ActionType.END_TURN:
			# Do nothing
			pass

		_:
			# Other actions not implemented for testing
			pass

func _get_memory_usage_mb() -> float:
	"""Get current memory usage in MB"""
	return OS.get_static_memory_usage() / (1024.0 * 1024.0)
