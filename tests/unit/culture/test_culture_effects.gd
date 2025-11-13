extends GutTest

## Unit tests for CultureEffects class

var CultureEffects = preload("res://systems/culture/culture_effects.gd")
var CultureNode = preload("res://systems/culture/culture_node.gd")

var effects_calc: CultureEffects


func before_each():
	effects_calc = CultureEffects.new()


func after_each():
	effects_calc = null


func _create_test_node(id: String, effect_dict: Dictionary) -> CultureNode:
	var node = CultureNode.new()
	node.id = id
	node.name = id.capitalize()
	node.axis = "military"
	node.tier = 1
	node.cost = 50
	node.effects = effect_dict.duplicate(true)
	return node


func _create_node_with_unlocks(id: String, unlocks_dict: Dictionary) -> CultureNode:
	var node = CultureNode.new()
	node.id = id
	node.name = id.capitalize()
	node.axis = "military"
	node.tier = 1
	node.cost = 50
	node.unlocks = unlocks_dict.duplicate(true)
	return node


func test_calculate_total_effects_single_node():
	var node = _create_test_node("node1", {
		"unit_attack_bonus": 0.1,
		"resource_production_bonus": 0.2
	})

	var nodes: Array[CultureNode] = [node]
	var total = effects_calc.calculate_total_effects(nodes)

	assert_almost_eq(total["unit_attack_bonus"], 0.1, 0.001)
	assert_almost_eq(total["resource_production_bonus"], 0.2, 0.001)


func test_calculate_total_effects_multiple_nodes():
	var node1 = _create_test_node("node1", {
		"unit_attack_bonus": 0.1,
		"resource_production_bonus": 0.15
	})
	var node2 = _create_test_node("node2", {
		"unit_attack_bonus": 0.05,
		"building_cost_reduction": 0.1
	})

	var nodes: Array[CultureNode] = [node1, node2]
	var total = effects_calc.calculate_total_effects(nodes)

	assert_almost_eq(total["unit_attack_bonus"], 0.15, 0.001)
	assert_almost_eq(total["resource_production_bonus"], 0.15, 0.001)
	assert_almost_eq(total["building_cost_reduction"], 0.1, 0.001)


func test_calculate_total_effects_with_special_abilities():
	var node1 = _create_test_node("node1", {
		"unit_attack_bonus": 0.1,
		"special_abilities": [
			{"id": "ability1", "name": "Super Strike"}
		]
	})
	var node2 = _create_test_node("node2", {
		"resource_production_bonus": 0.2,
		"special_abilities": [
			{"id": "ability2", "name": "Double Resources"}
		]
	})

	var nodes: Array[CultureNode] = [node1, node2]
	var total = effects_calc.calculate_total_effects(nodes)

	assert_true(total.has("special_abilities"))
	assert_eq(total["special_abilities"].size(), 2)


func test_calculate_total_effects_empty_nodes():
	var nodes: Array[CultureNode] = []
	var total = effects_calc.calculate_total_effects(nodes)

	assert_eq(total.size(), 0)


func test_calculate_synergy_bonuses_active():
	var synergies = [
		{
			"id": "synergy1",
			"name": "Test Synergy",
			"required_nodes": ["node1", "node2"],
			"effects": {
				"unit_attack_bonus": 0.5
			}
		}
	]

	effects_calc.set_synergy_definitions(synergies)

	var unlocked: Array[String] = ["node1", "node2", "node3"]
	var active = effects_calc.calculate_synergy_bonuses(unlocked, synergies)

	assert_eq(active.size(), 1)
	assert_eq(active[0]["id"], "synergy1")


func test_calculate_synergy_bonuses_inactive():
	var synergies = [
		{
			"id": "synergy1",
			"name": "Test Synergy",
			"required_nodes": ["node1", "node2"],
			"effects": {
				"unit_attack_bonus": 0.5
			}
		}
	]

	var unlocked: Array[String] = ["node1", "node3"]
	var active = effects_calc.calculate_synergy_bonuses(unlocked, synergies)

	assert_eq(active.size(), 0)


func test_calculate_synergy_bonuses_multiple():
	var synergies = [
		{
			"id": "synergy1",
			"required_nodes": ["node1", "node2"],
			"effects": {"bonus1": 0.1}
		},
		{
			"id": "synergy2",
			"required_nodes": ["node3", "node4"],
			"effects": {"bonus2": 0.2}
		}
	]

	var unlocked: Array[String] = ["node1", "node2", "node3", "node4"]
	var active = effects_calc.calculate_synergy_bonuses(unlocked, synergies)

	assert_eq(active.size(), 2)


func test_calculate_total_effects_with_synergies():
	var node1 = _create_test_node("node1", {"unit_attack_bonus": 0.1})
	var node2 = _create_test_node("node2", {"unit_attack_bonus": 0.05})

	var synergies = [
		{
			"id": "synergy1",
			"required_nodes": ["node1", "node2"],
			"effects": {"unit_attack_bonus": 0.15}
		}
	]

	effects_calc.set_synergy_definitions(synergies)

	var nodes: Array[CultureNode] = [node1, node2]
	var unlocked: Array[String] = ["node1", "node2"]
	var total = effects_calc.calculate_total_effects_with_synergies(nodes, unlocked)

	# 0.1 + 0.05 + 0.15 (synergy) = 0.3
	assert_almost_eq(total["unit_attack_bonus"], 0.3, 0.001)


func test_get_effect_modifier_bonus():
	var effects = {"unit_attack_bonus": 0.25}

	var modified = effects_calc.get_effect_modifier(100.0, "unit_attack_bonus", effects)
	assert_almost_eq(modified, 125.0, 0.01)


func test_get_effect_modifier_reduction():
	var effects = {"building_cost_reduction": 0.2}

	var modified = effects_calc.get_effect_modifier(100.0, "building_cost_reduction", effects)
	assert_almost_eq(modified, 80.0, 0.01)


func test_get_effect_modifier_multiplier():
	var effects = {"damage_mult": 2.0}

	var modified = effects_calc.get_effect_modifier(50.0, "damage_mult", effects)
	assert_almost_eq(modified, 100.0, 0.01)


func test_get_effect_modifier_flat():
	var effects = {"happiness": 5.0}

	var modified = effects_calc.get_effect_modifier(10.0, "happiness", effects)
	assert_almost_eq(modified, 15.0, 0.01)


func test_get_effect_modifier_no_effect():
	var effects = {"unit_attack_bonus": 0.1}

	var modified = effects_calc.get_effect_modifier(100.0, "nonexistent", effects)
	assert_almost_eq(modified, 100.0, 0.01)


func test_get_unlocked_content_units():
	var node1 = _create_node_with_unlocks("node1", {
		"units": ["soldier", "sniper"],
		"buildings": [],
		"policies": []
	})
	var node2 = _create_node_with_unlocks("node2", {
		"units": ["medic"],
		"buildings": [],
		"policies": []
	})

	var nodes: Array[CultureNode] = [node1, node2]
	var content = effects_calc.get_unlocked_content(nodes)

	assert_eq(content["units"].size(), 3)
	assert_true("soldier" in content["units"])
	assert_true("sniper" in content["units"])
	assert_true("medic" in content["units"])


func test_get_unlocked_content_buildings():
	var node = _create_node_with_unlocks("node", {
		"units": [],
		"buildings": ["barracks", "workshop"],
		"policies": []
	})

	var nodes: Array[CultureNode] = [node]
	var content = effects_calc.get_unlocked_content(nodes)

	assert_eq(content["buildings"].size(), 2)
	assert_true("barracks" in content["buildings"])
	assert_true("workshop" in content["buildings"])


func test_get_unlocked_content_policies():
	var node = _create_node_with_unlocks("node", {
		"units": [],
		"buildings": [],
		"policies": ["martial_law", "free_trade"]
	})

	var nodes: Array[CultureNode] = [node]
	var content = effects_calc.get_unlocked_content(nodes)

	assert_eq(content["policies"].size(), 2)
	assert_true("martial_law" in content["policies"])
	assert_true("free_trade" in content["policies"])


func test_get_unlocked_content_no_duplicates():
	var node1 = _create_node_with_unlocks("node1", {
		"units": ["soldier"],
		"buildings": [],
		"policies": []
	})
	var node2 = _create_node_with_unlocks("node2", {
		"units": ["soldier", "medic"],
		"buildings": [],
		"policies": []
	})

	var nodes: Array[CultureNode] = [node1, node2]
	var content = effects_calc.get_unlocked_content(nodes)

	assert_eq(content["units"].size(), 2)
	assert_true("soldier" in content["units"])
	assert_true("medic" in content["units"])


func test_get_all_effect_keys():
	var node1 = _create_test_node("node1", {
		"unit_attack_bonus": 0.1,
		"resource_production_bonus": 0.2
	})
	var node2 = _create_test_node("node2", {
		"unit_attack_bonus": 0.05,
		"building_cost_reduction": 0.1
	})

	var nodes: Array[CultureNode] = [node1, node2]
	var keys = effects_calc.get_all_effect_keys(nodes)

	assert_eq(keys.size(), 3)
	assert_true("unit_attack_bonus" in keys)
	assert_true("resource_production_bonus" in keys)
	assert_true("building_cost_reduction" in keys)


func test_merge_effects():
	var base = {
		"unit_attack_bonus": 0.1,
		"resource_production_bonus": 0.15
	}
	var additional = {
		"unit_attack_bonus": 0.05,
		"building_cost_reduction": 0.1
	}

	var merged = effects_calc.merge_effects(base, additional)

	assert_almost_eq(merged["unit_attack_bonus"], 0.15, 0.001)
	assert_almost_eq(merged["resource_production_bonus"], 0.15, 0.001)
	assert_almost_eq(merged["building_cost_reduction"], 0.1, 0.001)


func test_merge_effects_with_abilities():
	var base = {
		"unit_attack_bonus": 0.1,
		"special_abilities": [{"id": "ability1"}]
	}
	var additional = {
		"unit_attack_bonus": 0.05,
		"special_abilities": [{"id": "ability2"}]
	}

	var merged = effects_calc.merge_effects(base, additional)

	assert_eq(merged["special_abilities"].size(), 2)


func test_is_synergy_active_true():
	var synergies = [
		{
			"id": "test_synergy",
			"required_nodes": ["node1", "node2"]
		}
	]
	effects_calc.set_synergy_definitions(synergies)

	var unlocked: Array[String] = ["node1", "node2", "node3"]
	assert_true(effects_calc.is_synergy_active("test_synergy", unlocked))


func test_is_synergy_active_false():
	var synergies = [
		{
			"id": "test_synergy",
			"required_nodes": ["node1", "node2"]
		}
	]
	effects_calc.set_synergy_definitions(synergies)

	var unlocked: Array[String] = ["node1", "node3"]
	assert_false(effects_calc.is_synergy_active("test_synergy", unlocked))


func test_get_synergy_by_id():
	var synergies = [
		{
			"id": "synergy1",
			"name": "First Synergy"
		},
		{
			"id": "synergy2",
			"name": "Second Synergy"
		}
	]
	effects_calc.set_synergy_definitions(synergies)

	var synergy = effects_calc.get_synergy_by_id("synergy1")
	assert_eq(synergy["name"], "First Synergy")


func test_get_synergy_by_id_not_found():
	effects_calc.set_synergy_definitions([])

	var synergy = effects_calc.get_synergy_by_id("nonexistent")
	assert_eq(synergy.size(), 0)


func test_calculate_node_contributions():
	var node1 = _create_test_node("node1", {
		"unit_attack_bonus": 0.1,
		"resource_production_bonus": 0.2
	})
	var node2 = _create_test_node("node2", {
		"unit_attack_bonus": 0.15
	})

	var nodes: Array[CultureNode] = [node1, node2]
	var contributions = effects_calc.calculate_node_contributions(nodes)

	assert_true(contributions.has("node1"))
	assert_true(contributions.has("node2"))
	assert_almost_eq(contributions["node1"]["unit_attack_bonus"], 0.1, 0.001)
	assert_almost_eq(contributions["node2"]["unit_attack_bonus"], 0.15, 0.001)
