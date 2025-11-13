extends GutTest

## Unit tests for CultureNode class

var CultureNode = preload("res://systems/culture/culture_node.gd")


func before_each():
	pass


func after_each():
	pass


func test_create_empty_node():
	var node = CultureNode.new()
	assert_not_null(node, "Should create node instance")
	assert_eq(node.id, "", "Default id should be empty")
	assert_eq(node.tier, 1, "Default tier should be 1")


func test_from_dict_basic():
	var data = {
		"id": "test_node",
		"name": "Test Node",
		"description": "A test node",
		"axis": "military",
		"tier": 2,
		"cost": 100,
		"prerequisites": [],
		"effects": {}
	}

	var node = CultureNode.from_dict(data)
	assert_eq(node.id, "test_node")
	assert_eq(node.name, "Test Node")
	assert_eq(node.description, "A test node")
	assert_eq(node.axis, "military")
	assert_eq(node.tier, 2)
	assert_eq(node.cost, 100)


func test_from_dict_with_prerequisites():
	var data = {
		"id": "advanced_node",
		"name": "Advanced",
		"description": "Requires other nodes",
		"axis": "economic",
		"tier": 3,
		"cost": 150,
		"prerequisites": ["base_node", "mid_node"]
	}

	var node = CultureNode.from_dict(data)
	assert_eq(node.prerequisites.size(), 2)
	assert_true("base_node" in node.prerequisites)
	assert_true("mid_node" in node.prerequisites)


func test_from_dict_with_mutually_exclusive():
	var data = {
		"id": "path_a",
		"name": "Path A",
		"description": "Cannot take with Path B",
		"axis": "social",
		"tier": 2,
		"cost": 100,
		"mutually_exclusive": ["path_b"]
	}

	var node = CultureNode.from_dict(data)
	assert_eq(node.mutually_exclusive.size(), 1)
	assert_true("path_b" in node.mutually_exclusive)


func test_from_dict_with_stat_modifiers():
	var data = {
		"id": "bonus_node",
		"name": "Bonus Node",
		"description": "Provides bonuses",
		"axis": "technological",
		"tier": 1,
		"cost": 50,
		"effects": {
			"stat_modifiers": {
				"unit_attack_bonus": 0.15,
				"resource_production_bonus": 0.25
			}
		}
	}

	var node = CultureNode.from_dict(data)
	assert_true(node.effects.has("unit_attack_bonus"))
	assert_almost_eq(node.effects["unit_attack_bonus"], 0.15, 0.001)
	assert_almost_eq(node.effects["resource_production_bonus"], 0.25, 0.001)


func test_from_dict_with_unlocks():
	var data = {
		"id": "unlock_node",
		"name": "Unlock Node",
		"description": "Unlocks content",
		"axis": "military",
		"tier": 2,
		"cost": 100,
		"effects": {
			"unit_unlocks": ["soldier", "sniper"],
			"building_unlocks": ["barracks"]
		}
	}

	var node = CultureNode.from_dict(data)
	assert_eq(node.unlocks["units"].size(), 2)
	assert_true("soldier" in node.unlocks["units"])
	assert_true("sniper" in node.unlocks["units"])
	assert_eq(node.unlocks["buildings"].size(), 1)
	assert_true("barracks" in node.unlocks["buildings"])


func test_to_dict():
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.description = "Test node"
	node.axis = "social"
	node.tier = 2
	node.cost = 100
	node.prerequisites = ["prereq1"]
	node.mutually_exclusive = ["exclusive1"]

	var dict = node.to_dict()
	assert_eq(dict["id"], "test")
	assert_eq(dict["name"], "Test")
	assert_eq(dict["tier"], 2)
	assert_eq(dict["cost"], 100)
	assert_eq(dict["prerequisites"].size(), 1)


func test_validate_valid_node():
	var node = CultureNode.new()
	node.id = "valid_node"
	node.name = "Valid"
	node.axis = "military"
	node.tier = 2
	node.cost = 100

	assert_true(node.validate())


func test_validate_empty_id():
	var node = CultureNode.new()
	node.id = ""
	node.name = "Test"
	node.axis = "military"

	assert_false(node.validate())


func test_validate_empty_name():
	var node = CultureNode.new()
	node.id = "test"
	node.name = ""
	node.axis = "military"

	assert_false(node.validate())


func test_validate_invalid_axis():
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.axis = "invalid_axis"

	assert_false(node.validate())


func test_validate_invalid_tier():
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.axis = "military"
	node.tier = 0

	assert_false(node.validate())

	node.tier = 5
	assert_false(node.validate())


func test_validate_negative_cost():
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.axis = "military"
	node.cost = -50

	assert_false(node.validate())


func test_validate_self_prerequisite():
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.axis = "military"
	node.prerequisites = ["test"]

	assert_false(node.validate())


func test_validate_self_exclusion():
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.axis = "military"
	node.mutually_exclusive = ["test"]

	assert_false(node.validate())


func test_get_effect_keys():
	var node = CultureNode.new()
	node.effects = {
		"unit_attack_bonus": 0.1,
		"resource_production_bonus": 0.2,
		"special_abilities": []
	}

	var keys = node.get_effect_keys()
	assert_eq(keys.size(), 2)
	assert_true("unit_attack_bonus" in keys)
	assert_true("resource_production_bonus" in keys)
	assert_false("special_abilities" in keys)


func test_get_effect_value():
	var node = CultureNode.new()
	node.effects = {
		"unit_attack_bonus": 0.25,
		"building_cost_reduction": 0.15
	}

	assert_almost_eq(node.get_effect_value("unit_attack_bonus"), 0.25, 0.001)
	assert_almost_eq(node.get_effect_value("building_cost_reduction"), 0.15, 0.001)
	assert_eq(node.get_effect_value("nonexistent"), 0.0)
	assert_eq(node.get_effect_value("nonexistent", 5.0), 5.0)


func test_has_prerequisite():
	var node = CultureNode.new()
	node.prerequisites = ["prereq1", "prereq2"]

	assert_true(node.has_prerequisite("prereq1"))
	assert_true(node.has_prerequisite("prereq2"))
	assert_false(node.has_prerequisite("prereq3"))


func test_is_exclusive_with():
	var node = CultureNode.new()
	node.mutually_exclusive = ["exclusive1", "exclusive2"]

	assert_true(node.is_exclusive_with("exclusive1"))
	assert_true(node.is_exclusive_with("exclusive2"))
	assert_false(node.is_exclusive_with("exclusive3"))


func test_from_dict_with_special_abilities():
	var data = {
		"id": "ability_node",
		"name": "Special Abilities",
		"description": "Has special abilities",
		"axis": "military",
		"tier": 3,
		"cost": 200,
		"effects": {
			"special_abilities": [
				{
					"id": "ability1",
					"name": "Super Attack",
					"description": "+50% damage"
				}
			]
		}
	}

	var node = CultureNode.from_dict(data)
	assert_true(node.effects.has("special_abilities"))
	assert_eq(node.effects["special_abilities"].size(), 1)
	assert_eq(node.effects["special_abilities"][0]["id"], "ability1")
