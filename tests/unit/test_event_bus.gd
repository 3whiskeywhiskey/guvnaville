extends GutTest

## Unit tests for EventBus singleton

func before_each():
	# Disconnect all signals to ensure clean test state
	# Note: In real tests, we would need to be careful about this
	pass

func test_event_bus_exists():
	assert_not_null(EventBus, "EventBus should exist")

func test_game_lifecycle_signals():
	var game_started_received = false
	var game_loaded_received = false
	var game_ended_received = false
	var game_paused_received = false
	var game_resumed_received = false

	EventBus.game_started.connect(func(state): game_started_received = true)
	EventBus.game_loaded.connect(func(state): game_loaded_received = true)
	EventBus.game_ended.connect(func(victory, faction): game_ended_received = true)
	EventBus.game_paused.connect(func(): game_paused_received = true)
	EventBus.game_resumed.connect(func(): game_resumed_received = true)

	EventBus.game_started.emit(null)
	EventBus.game_loaded.emit(null)
	EventBus.game_ended.emit("military", 0)
	EventBus.game_paused.emit()
	EventBus.game_resumed.emit()

	assert_true(game_started_received, "game_started should be received")
	assert_true(game_loaded_received, "game_loaded should be received")
	assert_true(game_ended_received, "game_ended should be received")
	assert_true(game_paused_received, "game_paused should be received")
	assert_true(game_resumed_received, "game_resumed should be received")

func test_turn_management_signals():
	var turn_started_received = false
	var turn_ended_received = false
	var phase_changed_received = false
	var faction_turn_started_received = false
	var faction_turn_ended_received = false

	EventBus.turn_started.connect(func(turn, faction): turn_started_received = true)
	EventBus.turn_ended.connect(func(turn): turn_ended_received = true)
	EventBus.turn_phase_changed.connect(func(phase): phase_changed_received = true)
	EventBus.faction_turn_started.connect(func(faction): faction_turn_started_received = true)
	EventBus.faction_turn_ended.connect(func(faction): faction_turn_ended_received = true)

	EventBus.turn_started.emit(1, 0)
	EventBus.turn_ended.emit(1)
	EventBus.turn_phase_changed.emit(0)
	EventBus.faction_turn_started.emit(0)
	EventBus.faction_turn_ended.emit(0)

	assert_true(turn_started_received, "turn_started should be received")
	assert_true(turn_ended_received, "turn_ended should be received")
	assert_true(phase_changed_received, "turn_phase_changed should be received")
	assert_true(faction_turn_started_received, "faction_turn_started should be received")
	assert_true(faction_turn_ended_received, "faction_turn_ended should be received")

func test_unit_signals():
	var unit_created_received = false
	var unit_destroyed_received = false
	var unit_moved_received = false
	var unit_promoted_received = false
	var unit_healed_received = false
	var unit_damaged_received = false

	EventBus.unit_created.connect(func(id, type, faction, pos): unit_created_received = true)
	EventBus.unit_destroyed.connect(func(id, faction, pos): unit_destroyed_received = true)
	EventBus.unit_moved.connect(func(id, from, to): unit_moved_received = true)
	EventBus.unit_promoted.connect(func(id, rank): unit_promoted_received = true)
	EventBus.unit_healed.connect(func(id, amount): unit_healed_received = true)
	EventBus.unit_damaged.connect(func(id, amount): unit_damaged_received = true)

	EventBus.unit_created.emit("unit_1", "militia", 0, Vector3i.ZERO)
	EventBus.unit_destroyed.emit("unit_1", 0, Vector3i.ZERO)
	EventBus.unit_moved.emit("unit_1", Vector3i.ZERO, Vector3i(1, 0, 0))
	EventBus.unit_promoted.emit("unit_1", 1)
	EventBus.unit_healed.emit("unit_1", 10)
	EventBus.unit_damaged.emit("unit_1", 20)

	assert_true(unit_created_received, "unit_created should be received")
	assert_true(unit_destroyed_received, "unit_destroyed should be received")
	assert_true(unit_moved_received, "unit_moved should be received")
	assert_true(unit_promoted_received, "unit_promoted should be received")
	assert_true(unit_healed_received, "unit_healed should be received")
	assert_true(unit_damaged_received, "unit_damaged should be received")

func test_resource_signals():
	var resource_changed_received = false
	var resource_shortage_received = false
	var production_completed_received = false
	var production_started_received = false

	EventBus.resource_changed.connect(func(faction, resource, amount, total): resource_changed_received = true)
	EventBus.resource_shortage.connect(func(faction, resource, deficit): resource_shortage_received = true)
	EventBus.production_completed.connect(func(faction, type, id): production_completed_received = true)
	EventBus.production_started.connect(func(faction, type): production_started_received = true)

	EventBus.resource_changed.emit(0, "scrap", 10, 110)
	EventBus.resource_shortage.emit(0, "ammo", 5)
	EventBus.production_completed.emit(0, "unit", "unit_1")
	EventBus.production_started.emit(0, "building")

	assert_true(resource_changed_received, "resource_changed should be received")
	assert_true(resource_shortage_received, "resource_shortage should be received")
	assert_true(production_completed_received, "production_completed should be received")
	assert_true(production_started_received, "production_started should be received")

func test_multiple_listeners():
	var count = 0

	EventBus.unit_created.connect(func(a, b, c, d): count += 1)
	EventBus.unit_created.connect(func(a, b, c, d): count += 1)
	EventBus.unit_created.connect(func(a, b, c, d): count += 1)

	EventBus.unit_created.emit("unit_1", "militia", 0, Vector3i.ZERO)

	assert_eq(count, 3, "All 3 listeners should receive signal")

func test_signal_parameters():
	var received_turn = 0
	var received_faction = 0

	EventBus.turn_started.connect(func(turn, faction):
		received_turn = turn
		received_faction = faction
	)

	EventBus.turn_started.emit(42, 7)

	assert_eq(received_turn, 42, "Should receive correct turn number")
	assert_eq(received_faction, 7, "Should receive correct faction ID")

func test_map_signals():
	var tile_captured_received = false
	var tile_scavenged_received = false
	var building_constructed_received = false

	EventBus.tile_captured.connect(func(pos, old, new): tile_captured_received = true)
	EventBus.tile_scavenged.connect(func(pos, resources): tile_scavenged_received = true)
	EventBus.building_constructed.connect(func(pos, type, faction): building_constructed_received = true)

	EventBus.tile_captured.emit(Vector3i.ZERO, -1, 0)
	EventBus.tile_scavenged.emit(Vector3i.ZERO, {"scrap": 10})
	EventBus.building_constructed.emit(Vector3i.ZERO, "workshop", 0)

	assert_true(tile_captured_received, "tile_captured should be received")
	assert_true(tile_scavenged_received, "tile_scavenged should be received")
	assert_true(building_constructed_received, "building_constructed should be received")

func test_combat_signals():
	var combat_started_received = false
	var combat_resolved_received = false
	var unit_retreated_received = false
	var morale_broken_received = false

	EventBus.combat_started.connect(func(attackers, defenders, pos): combat_started_received = true)
	EventBus.combat_resolved.connect(func(outcome): combat_resolved_received = true)
	EventBus.unit_retreated.connect(func(id, from, to): unit_retreated_received = true)
	EventBus.morale_broken.connect(func(id): morale_broken_received = true)

	EventBus.combat_started.emit(["unit_1"], ["unit_2"], Vector3i.ZERO)
	EventBus.combat_resolved.emit({"winner": 0})
	EventBus.unit_retreated.emit("unit_2", Vector3i.ZERO, Vector3i(1, 0, 0))
	EventBus.morale_broken.emit("unit_2")

	assert_true(combat_started_received, "combat_started should be received")
	assert_true(combat_resolved_received, "combat_resolved should be received")
	assert_true(unit_retreated_received, "unit_retreated should be received")
	assert_true(morale_broken_received, "morale_broken should be received")

func test_culture_signals():
	var points_gained_received = false
	var node_unlocked_received = false
	var bonus_applied_received = false

	EventBus.culture_points_gained.connect(func(faction, points): points_gained_received = true)
	EventBus.culture_node_unlocked.connect(func(faction, node, axis): node_unlocked_received = true)
	EventBus.culture_bonus_applied.connect(func(faction, bonus, value): bonus_applied_received = true)

	EventBus.culture_points_gained.emit(0, 10)
	EventBus.culture_node_unlocked.emit(0, "node_1", "military")
	EventBus.culture_bonus_applied.emit(0, "attack", 1.1)

	assert_true(points_gained_received, "culture_points_gained should be received")
	assert_true(node_unlocked_received, "culture_node_unlocked should be received")
	assert_true(bonus_applied_received, "culture_bonus_applied should be received")

func test_ai_signals():
	var decision_made_received = false
	var ai_error_received = false

	EventBus.ai_decision_made.connect(func(faction, type, details): decision_made_received = true)
	EventBus.ai_error.connect(func(faction, message): ai_error_received = true)

	EventBus.ai_decision_made.emit(1, "move", {"unit": "unit_1"})
	EventBus.ai_error.emit(1, "Error processing turn")

	assert_true(decision_made_received, "ai_decision_made should be received")
	assert_true(ai_error_received, "ai_error should be received")
