extends GutTest

## Unit tests for CultureTree class

var CultureTree = preload("res://systems/culture/culture_tree.gd")

var culture_tree: CultureTree


func before_each():
	culture_tree = CultureTree.new()
	add_child_autofree(culture_tree)


func after_each():
	if culture_tree:
		culture_tree.queue_free()
	culture_tree = null


func _get_test_culture_data() -> Dictionary:
	return {
		"culture_tree": {
			"military": [
				{
					"id": "militia_training",
					"name": "Militia Training",
					"description": "Basic combat training",
					"axis": "military",
					"tier": 1,
					"cost": 50,
					"prerequisites": [],
					"effects": {
						"stat_modifiers": {
							"unit_attack_bonus": 0.1
						}
					}
				},
				{
					"id": "organized_warfare",
					"name": "Organized Warfare",
					"description": "Military organization",
					"axis": "military",
					"tier": 2,
					"cost": 100,
					"prerequisites": ["militia_training"],
					"effects": {
						"unit_unlocks": ["soldier"],
						"stat_modifiers": {
							"unit_attack_bonus": 0.15,
							"unit_defense_bonus": 0.1
						}
					}
				},
				{
					"id": "raider_culture",
					"name": "Raider Culture",
					"description": "Aggressive tactics",
					"axis": "military",
					"tier": 2,
					"cost": 100,
					"prerequisites": ["militia_training"],
					"mutually_exclusive": ["organized_warfare"],
					"effects": {
						"stat_modifiers": {
							"unit_attack_bonus": 0.2
						}
					}
				}
			],
			"economic": [
				{
					"id": "salvage_operations",
					"name": "Salvage Operations",
					"description": "Scavenging basics",
					"axis": "economic",
					"tier": 1,
					"cost": 50,
					"prerequisites": [],
					"effects": {
						"stat_modifiers": {
							"resource_production_bonus": 0.1
						}
					}
				}
			],
			"social": [],
			"technological": []
		},
		"synergies": [
			{
				"id": "synergy_military_economic",
				"name": "War Economy",
				"required_nodes": ["organized_warfare", "salvage_operations"],
				"effects": {
					"resource_production_bonus": 0.2
				}
			}
		]
	}


func test_load_culture_tree():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var all_nodes = culture_tree.get_all_nodes()
	assert_eq(all_nodes.size(), 4)


func test_load_culture_tree_emits_signal():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	assert_signal_emitted(culture_tree, "culture_tree_loaded")


func test_get_nodes_by_axis():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var military_nodes = culture_tree.get_nodes_by_axis("military")
	assert_eq(military_nodes.size(), 3)

	var economic_nodes = culture_tree.get_nodes_by_axis("economic")
	assert_eq(economic_nodes.size(), 1)


func test_get_node_by_id():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var node = culture_tree.get_node_by_id("militia_training")
	assert_not_null(node)
	assert_eq(node.name, "Militia Training")


func test_get_node_by_id_not_found():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var node = culture_tree.get_node_by_id("nonexistent")
	assert_null(node)


func test_add_culture_points():
	watch_signals(culture_tree)

	culture_tree.add_culture_points(1, 50)

	assert_eq(culture_tree.get_culture_points(1), 50)
	assert_signal_emitted_with_parameters(culture_tree, "culture_points_earned", [1, 50, 50])


func test_add_negative_culture_points():
	culture_tree.add_culture_points(1, 100)
	culture_tree.add_culture_points(1, -30)

	assert_eq(culture_tree.get_culture_points(1), 70)


func test_get_total_culture_earned():
	culture_tree.add_culture_points(1, 100)
	culture_tree.add_culture_points(1, 50)
	culture_tree.add_culture_points(1, -30)

	assert_eq(culture_tree.get_total_culture_earned(1), 150)


func test_unlock_node_success():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 100)

	var success = culture_tree.unlock_node(1, "militia_training")

	assert_true(success)
	assert_eq(culture_tree.get_culture_points(1), 50)
	assert_signal_emitted(culture_tree, "culture_node_unlocked")


func test_unlock_node_insufficient_points():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 25)

	var success = culture_tree.unlock_node(1, "militia_training")

	assert_false(success)
	assert_signal_emitted(culture_tree, "culture_node_unlock_failed")


func test_unlock_node_missing_prerequisites():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	var success = culture_tree.unlock_node(1, "organized_warfare")

	assert_false(success)
	assert_signal_emitted(culture_tree, "culture_node_unlock_failed")


func test_unlock_node_with_prerequisites():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	culture_tree.unlock_node(1, "militia_training")
	var success = culture_tree.unlock_node(1, "organized_warfare")

	assert_true(success)


func test_unlock_node_mutually_exclusive():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 300)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "organized_warfare")

	var success = culture_tree.unlock_node(1, "raider_culture")

	assert_false(success)


func test_unlock_node_not_found():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var success = culture_tree.unlock_node(1, "nonexistent")

	assert_false(success)
	assert_signal_emitted(culture_tree, "culture_node_unlock_failed")


func test_can_unlock_node():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 100)

	assert_true(culture_tree.can_unlock_node(1, "militia_training"))
	assert_false(culture_tree.can_unlock_node(1, "organized_warfare"))


func test_get_unlock_failure_reason():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 25)

	var reason = culture_tree.get_unlock_failure_reason(1, "militia_training")

	assert_ne(reason, "")
	assert_true(reason.contains("50") or reason.contains("points"))


func test_get_unlocked_nodes():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "salvage_operations")

	var unlocked = culture_tree.get_unlocked_nodes(1)

	assert_eq(unlocked.size(), 2)
	assert_true("militia_training" in unlocked)
	assert_true("salvage_operations" in unlocked)


func test_get_unlocked_nodes_by_axis():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "salvage_operations")

	var military = culture_tree.get_unlocked_nodes_by_axis(1, "military")
	var economic = culture_tree.get_unlocked_nodes_by_axis(1, "economic")

	assert_eq(military.size(), 1)
	assert_eq(economic.size(), 1)


func test_get_available_nodes():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 100)

	culture_tree.unlock_node(1, "militia_training")

	var available = culture_tree.get_available_nodes(1)

	# Should include organized_warfare and raider_culture (prerequisites met)
	# and salvage_operations (tier 1)
	assert_true("organized_warfare" in available or "raider_culture" in available or "salvage_operations" in available)


func test_get_locked_nodes():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var locked = culture_tree.get_locked_nodes(1)

	# organized_warfare and raider_culture should be locked (need militia_training)
	assert_true("organized_warfare" in locked)
	assert_true("raider_culture" in locked)


func test_get_culture_effects():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "salvage_operations")

	var effects = culture_tree.get_culture_effects(1)

	assert_true(effects.has("unit_attack_bonus"))
	assert_true(effects.has("resource_production_bonus"))


func test_synergy_activation():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 300)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "salvage_operations")

	# Clear previous signals
	clear_signal_watcher()

	culture_tree.unlock_node(1, "organized_warfare")

	# Should emit synergy_activated for war economy
	assert_signal_emitted(culture_tree, "synergy_activated")


func test_get_active_synergies():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 300)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "salvage_operations")
	culture_tree.unlock_node(1, "organized_warfare")

	var synergies = culture_tree.get_active_synergies(1)

	assert_eq(synergies.size(), 1)
	assert_eq(synergies[0]["id"], "synergy_military_economic")


func test_calculate_synergies():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var unlocked: Array[String] = ["organized_warfare", "salvage_operations"]
	var synergy_effects = culture_tree.calculate_synergies(1, unlocked)

	assert_true(synergy_effects.has("resource_production_bonus"))


func test_to_save_dict():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	culture_tree.unlock_node(1, "militia_training")
	culture_tree.unlock_node(1, "salvage_operations")

	var save_data = culture_tree.to_save_dict(1)

	assert_eq(save_data["culture_points"], 100)
	assert_eq(save_data["total_culture_earned"], 200)
	assert_eq(save_data["military_nodes"].size(), 1)
	assert_eq(save_data["economic_nodes"].size(), 1)


func test_from_save_dict():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var save_data = {
		"culture_points": 75,
		"total_culture_earned": 250,
		"military_nodes": ["militia_training"],
		"economic_nodes": ["salvage_operations"],
		"social_nodes": [],
		"technological_nodes": []
	}

	culture_tree.from_save_dict(1, save_data)

	assert_eq(culture_tree.get_culture_points(1), 75)
	assert_eq(culture_tree.get_total_culture_earned(1), 250)

	var unlocked = culture_tree.get_unlocked_nodes(1)
	assert_eq(unlocked.size(), 2)


func test_multiple_factions_independent():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	culture_tree.add_culture_points(1, 100)
	culture_tree.add_culture_points(2, 200)

	culture_tree.unlock_node(1, "militia_training")

	assert_eq(culture_tree.get_culture_points(1), 50)
	assert_eq(culture_tree.get_culture_points(2), 200)

	var faction1_unlocked = culture_tree.get_unlocked_nodes(1)
	var faction2_unlocked = culture_tree.get_unlocked_nodes(2)

	assert_eq(faction1_unlocked.size(), 1)
	assert_eq(faction2_unlocked.size(), 0)


func test_culture_effects_updated_signal():
	watch_signals(culture_tree)

	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 100)

	culture_tree.unlock_node(1, "militia_training")

	assert_signal_emitted(culture_tree, "culture_effects_updated")


func test_unlock_node_twice_fails():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	var first = culture_tree.unlock_node(1, "militia_training")
	var second = culture_tree.unlock_node(1, "militia_training")

	assert_true(first)
	assert_false(second)


func test_get_faction_culture_state():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 100)
	culture_tree.unlock_node(1, "militia_training")

	var state = culture_tree.get_faction_culture_state(1)

	assert_not_null(state)
	assert_eq(state.faction_id, 1)
	assert_eq(state.culture_points, 50)


func test_set_faction_culture_state():
	var data = _get_test_culture_data()
	culture_tree.load_culture_tree(data)

	var state = CultureTree.CultureState.new(1)
	state.culture_points = 150
	state.military_nodes = ["militia_training"]

	culture_tree.set_faction_culture_state(1, state)

	assert_eq(culture_tree.get_culture_points(1), 150)
	var unlocked = culture_tree.get_unlocked_nodes(1)
	assert_eq(unlocked.size(), 1)
