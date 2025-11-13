#!/usr/bin/env -S godot --headless --script
## Validation script for Culture System
## Checks syntax and basic functionality without running full GUT tests

extends SceneTree

# Preload all culture system components
var CultureNode = preload("res://systems/culture/culture_node.gd")
var CultureValidator = preload("res://systems/culture/culture_validator.gd")
var CultureEffects = preload("res://systems/culture/culture_effects.gd")
var CultureTree = preload("res://systems/culture/culture_tree.gd")


func _init():
	print("========================================")
	print("Culture System Validation")
	print("========================================")
	print()

	var all_passed = true

	# Test 1: Check if all classes can be instantiated
	print("Test 1: Class Instantiation")
	all_passed = test_instantiation() and all_passed

	# Test 2: Check CultureNode creation
	print("\nTest 2: CultureNode Creation")
	all_passed = test_culture_node() and all_passed

	# Test 3: Check CultureValidator
	print("\nTest 3: CultureValidator")
	all_passed = test_validator() and all_passed

	# Test 4: Check CultureEffects
	print("\nTest 4: CultureEffects")
	all_passed = test_effects() and all_passed

	# Test 5: Check CultureTree
	print("\nTest 5: CultureTree")
	all_passed = test_culture_tree() and all_passed

	# Test 6: Load real game data
	print("\nTest 6: Load Game Data")
	all_passed = test_load_game_data() and all_passed

	print("\n========================================")
	if all_passed:
		print("✅ ALL VALIDATION TESTS PASSED")
		quit(0)
	else:
		print("❌ SOME VALIDATION TESTS FAILED")
		quit(1)


func test_instantiation() -> bool:
	var node = CultureNode.new()
	if node == null:
		print("  ❌ Failed to instantiate CultureNode")
		return false

	var validator = CultureValidator.new()
	if validator == null:
		print("  ❌ Failed to instantiate CultureValidator")
		return false

	var effects = CultureEffects.new()
	if effects == null:
		print("  ❌ Failed to instantiate CultureEffects")
		return false

	var tree = CultureTree.new()
	if tree == null:
		print("  ❌ Failed to instantiate CultureTree")
		return false

	print("  ✅ All classes instantiate successfully")
	return true


func test_culture_node() -> bool:
	var data = {
		"id": "test_node",
		"name": "Test Node",
		"description": "A test",
		"axis": "military",
		"tier": 1,
		"cost": 50,
		"prerequisites": [],
		"effects": {
			"stat_modifiers": {
				"unit_attack_bonus": 0.1
			}
		}
	}

	var node = CultureNode.from_dict(data)
	if node.id != "test_node":
		print("  ❌ Failed to create node from dict")
		return false

	if not node.validate():
		print("  ❌ Node validation failed")
		return false

	var dict = node.to_dict()
	if dict["id"] != "test_node":
		print("  ❌ Failed to convert node to dict")
		return false

	print("  ✅ CultureNode works correctly")
	return true


func test_validator() -> bool:
	var node = CultureNode.new()
	node.id = "test"
	node.name = "Test"
	node.axis = "military"
	node.tier = 1
	node.cost = 100
	node.prerequisites = []

	var validator = CultureValidator.new()
	var unlocked: Array[String] = []
	var all_nodes = {"test": node}

	var error = validator.validate_unlock(node, unlocked, 100, all_nodes)
	if error != CultureValidator.ValidationError.NONE:
		print("  ❌ Validator validation failed when it should pass")
		return false

	# Test insufficient points
	error = validator.validate_unlock(node, unlocked, 50, all_nodes)
	if error != CultureValidator.ValidationError.INSUFFICIENT_POINTS:
		print("  ❌ Validator should detect insufficient points")
		return false

	print("  ✅ CultureValidator works correctly")
	return true


func test_effects() -> bool:
	var node1 = CultureNode.new()
	node1.id = "node1"
	node1.effects = {"unit_attack_bonus": 0.1}

	var node2 = CultureNode.new()
	node2.id = "node2"
	node2.effects = {"unit_attack_bonus": 0.15}

	var effects_calc = CultureEffects.new()
	var nodes: Array[CultureNode] = [node1, node2]

	var total = effects_calc.calculate_total_effects(nodes)
	if not total.has("unit_attack_bonus"):
		print("  ❌ Effects calculation missing key")
		return false

	var expected = 0.25
	if abs(total["unit_attack_bonus"] - expected) > 0.001:
		print("  ❌ Effects calculation incorrect: got %f, expected %f" % [total["unit_attack_bonus"], expected])
		return false

	print("  ✅ CultureEffects works correctly")
	return true


func test_culture_tree() -> bool:
	var tree = CultureTree.new()

	var data = {
		"culture_tree": {
			"military": [
				{
					"id": "base",
					"name": "Base",
					"description": "Test",
					"axis": "military",
					"tier": 1,
					"cost": 50,
					"prerequisites": [],
					"effects": {}
				}
			],
			"economic": [],
			"social": [],
			"technological": []
		}
	}

	tree.load_culture_tree(data)

	var nodes = tree.get_all_nodes()
	if nodes.size() != 1:
		print("  ❌ Failed to load nodes into tree")
		return false

	tree.add_culture_points(1, 100)
	if tree.get_culture_points(1) != 100:
		print("  ❌ Failed to add culture points")
		return false

	var success = tree.unlock_node(1, "base")
	if not success:
		print("  ❌ Failed to unlock node")
		return false

	if tree.get_culture_points(1) != 50:
		print("  ❌ Points not deducted correctly")
		return false

	print("  ✅ CultureTree works correctly")
	return true


func test_load_game_data() -> bool:
	var file = FileAccess.open("res://data/culture/culture_tree.json", FileAccess.READ)
	if file == null:
		print("  ❌ Failed to open culture_tree.json")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("  ❌ Failed to parse culture_tree.json")
		return false

	var data = json.data

	var tree = CultureTree.new()
	tree.load_culture_tree(data)

	var nodes = tree.get_all_nodes()
	if nodes.size() == 0:
		print("  ❌ No nodes loaded from game data")
		return false

	print("  ✅ Loaded %d nodes from game data" % nodes.size())

	# Validate all nodes
	for node in nodes:
		if not node.validate():
			print("  ❌ Invalid node in game data: %s" % node.id)
			return false

	print("  ✅ All game data nodes are valid")
	return true
