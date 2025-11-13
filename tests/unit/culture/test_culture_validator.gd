extends GutTest

## Unit tests for CultureValidator class

var CultureValidator = preload("res://systems/culture/culture_validator.gd")
var CultureNode = preload("res://systems/culture/culture_node.gd")

var validator: CultureValidator


func before_each():
	validator = CultureValidator.new()


func after_each():
	validator = null


func _create_test_node(id: String, axis: String, tier: int, cost: int, prereqs: Array = [], exclusive: Array = []) -> CultureNode:
	var node = CultureNode.new()
	node.id = id
	node.name = id.capitalize()
	node.axis = axis
	node.tier = tier
	node.cost = cost
	node.prerequisites = prereqs.duplicate()
	node.mutually_exclusive = exclusive.duplicate()
	return node


func test_validate_prerequisites_all_met():
	var node = _create_test_node("advanced", "military", 2, 100, ["base1", "base2"])
	var unlocked: Array[String] = ["base1", "base2", "other"]

	assert_true(validator.validate_prerequisites(node, unlocked))


func test_validate_prerequisites_missing():
	var node = _create_test_node("advanced", "military", 2, 100, ["base1", "base2"])
	var unlocked: Array[String] = ["base1"]

	assert_false(validator.validate_prerequisites(node, unlocked))


func test_validate_prerequisites_none_required():
	var node = _create_test_node("base", "military", 1, 50, [])
	var unlocked: Array[String] = []

	assert_true(validator.validate_prerequisites(node, unlocked))


func test_validate_exclusions_no_conflict():
	var node = _create_test_node("path_a", "social", 2, 100, [], ["path_b"])
	var unlocked: Array[String] = ["base", "other"]

	assert_true(validator.validate_exclusions(node, unlocked))


func test_validate_exclusions_has_conflict():
	var node = _create_test_node("path_a", "social", 2, 100, [], ["path_b"])
	var unlocked: Array[String] = ["base", "path_b"]

	assert_false(validator.validate_exclusions(node, unlocked))


func test_validate_exclusions_none_defined():
	var node = _create_test_node("node", "military", 1, 50, [], [])
	var unlocked: Array[String] = ["anything"]

	assert_true(validator.validate_exclusions(node, unlocked))


func test_validate_cost_sufficient_points():
	var node = _create_test_node("node", "military", 1, 100)

	assert_true(validator.validate_cost(node, 100))
	assert_true(validator.validate_cost(node, 150))


func test_validate_cost_insufficient_points():
	var node = _create_test_node("node", "military", 1, 100)

	assert_false(validator.validate_cost(node, 99))
	assert_false(validator.validate_cost(node, 0))


func test_validate_tier_progression_tier1_always_valid():
	var node = _create_test_node("base", "military", 1, 50)
	var unlocked: Array[String] = []
	var all_nodes: Dictionary = {}

	assert_true(validator.validate_tier_progression(node, unlocked, all_nodes))


func test_validate_tier_progression_valid():
	var tier1 = _create_test_node("tier1", "military", 1, 50)
	var tier2 = _create_test_node("tier2", "military", 2, 100)

	var all_nodes = {
		"tier1": tier1,
		"tier2": tier2
	}
	var unlocked: Array[String] = ["tier1"]

	assert_true(validator.validate_tier_progression(tier2, unlocked, all_nodes))


func test_validate_tier_progression_invalid_skip_tier():
	var tier1 = _create_test_node("tier1", "military", 1, 50)
	var tier3 = _create_test_node("tier3", "military", 3, 150)

	var all_nodes = {
		"tier1": tier1,
		"tier3": tier3
	}
	var unlocked: Array[String] = []

	assert_false(validator.validate_tier_progression(tier3, unlocked, all_nodes))


func test_validate_tier_progression_different_axis():
	var mil_tier1 = _create_test_node("mil1", "military", 1, 50)
	var eco_tier2 = _create_test_node("eco2", "economic", 2, 100)

	var all_nodes = {
		"mil1": mil_tier1,
		"eco2": eco_tier2
	}
	var unlocked: Array[String] = ["mil1"]

	# Should fail because no tier 1 economic node unlocked
	assert_false(validator.validate_tier_progression(eco_tier2, unlocked, all_nodes))


func test_get_missing_prerequisites():
	var node = _create_test_node("advanced", "military", 2, 100, ["prereq1", "prereq2", "prereq3"])
	var unlocked: Array[String] = ["prereq1", "other"]

	var missing = validator.get_missing_prerequisites(node, unlocked)
	assert_eq(missing.size(), 2)
	assert_true("prereq2" in missing)
	assert_true("prereq3" in missing)


func test_get_missing_prerequisites_none():
	var node = _create_test_node("node", "military", 1, 50, ["prereq1"])
	var unlocked: Array[String] = ["prereq1", "other"]

	var missing = validator.get_missing_prerequisites(node, unlocked)
	assert_eq(missing.size(), 0)


func test_get_exclusive_conflicts():
	var node = _create_test_node("path_a", "social", 2, 100, [], ["path_b", "path_c"])
	var unlocked: Array[String] = ["base", "path_b"]

	var conflicts = validator.get_exclusive_conflicts(node, unlocked)
	assert_eq(conflicts.size(), 1)
	assert_true("path_b" in conflicts)


func test_get_exclusive_conflicts_none():
	var node = _create_test_node("path_a", "social", 2, 100, [], ["path_b", "path_c"])
	var unlocked: Array[String] = ["base", "other"]

	var conflicts = validator.get_exclusive_conflicts(node, unlocked)
	assert_eq(conflicts.size(), 0)


func test_validate_unlock_success():
	var node = _create_test_node("node", "military", 1, 100)
	var unlocked: Array[String] = []
	var all_nodes = {"node": node}

	var error = validator.validate_unlock(node, unlocked, 100, all_nodes)
	assert_eq(error, CultureValidator.ValidationError.NONE)


func test_validate_unlock_already_unlocked():
	var node = _create_test_node("node", "military", 1, 100)
	var unlocked: Array[String] = ["node"]
	var all_nodes = {"node": node}

	var error = validator.validate_unlock(node, unlocked, 100, all_nodes)
	assert_eq(error, CultureValidator.ValidationError.NODE_ALREADY_UNLOCKED)


func test_validate_unlock_insufficient_points():
	var node = _create_test_node("node", "military", 1, 100)
	var unlocked: Array[String] = []
	var all_nodes = {"node": node}

	var error = validator.validate_unlock(node, unlocked, 50, all_nodes)
	assert_eq(error, CultureValidator.ValidationError.INSUFFICIENT_POINTS)


func test_validate_unlock_missing_prerequisites():
	var node = _create_test_node("advanced", "military", 2, 100, ["base"])
	var unlocked: Array[String] = []
	var all_nodes = {"advanced": node}

	var error = validator.validate_unlock(node, unlocked, 100, all_nodes)
	assert_eq(error, CultureValidator.ValidationError.MISSING_PREREQUISITES)


func test_validate_unlock_exclusive_conflict():
	var node = _create_test_node("path_a", "social", 2, 100, [], ["path_b"])
	var unlocked: Array[String] = ["path_b"]
	var all_nodes = {"path_a": node}

	var error = validator.validate_unlock(node, unlocked, 100, all_nodes)
	assert_eq(error, CultureValidator.ValidationError.EXCLUSIVE_CONFLICT)


func test_validate_unlock_invalid_tier():
	var tier3 = _create_test_node("tier3", "military", 3, 150)
	var unlocked: Array[String] = []
	var all_nodes = {"tier3": tier3}

	var error = validator.validate_unlock(tier3, unlocked, 150, all_nodes)
	assert_eq(error, CultureValidator.ValidationError.INVALID_TIER_PROGRESSION)


func test_get_failure_reason_none():
	var node = _create_test_node("node", "military", 1, 100)
	var unlocked: Array[String] = []
	var all_nodes = {"node": node}

	var reason = validator.get_failure_reason(CultureValidator.ValidationError.NONE, node, unlocked, 100, all_nodes)
	assert_eq(reason, "")


func test_get_failure_reason_already_unlocked():
	var node = _create_test_node("node", "military", 1, 100)
	var unlocked: Array[String] = []
	var all_nodes = {"node": node}

	var reason = validator.get_failure_reason(CultureValidator.ValidationError.NODE_ALREADY_UNLOCKED, node, unlocked, 100, all_nodes)
	assert_true(reason.contains("already unlocked"))


func test_get_failure_reason_insufficient_points():
	var node = _create_test_node("node", "military", 1, 100)
	var unlocked: Array[String] = []
	var all_nodes = {"node": node}

	var reason = validator.get_failure_reason(CultureValidator.ValidationError.INSUFFICIENT_POINTS, node, unlocked, 60, all_nodes)
	assert_true(reason.contains("100"))
	assert_true(reason.contains("40"))


func test_get_failure_reason_missing_prerequisites():
	var base = _create_test_node("base", "military", 1, 50)
	var advanced = _create_test_node("advanced", "military", 2, 100, ["base"])
	var unlocked: Array[String] = []
	var all_nodes = {"base": base, "advanced": advanced}

	var reason = validator.get_failure_reason(CultureValidator.ValidationError.MISSING_PREREQUISITES, advanced, unlocked, 100, all_nodes)
	assert_true(reason.contains("prerequisites") or reason.contains("Base"))


func test_validate_culture_tree_valid():
	var node1 = _create_test_node("base", "military", 1, 50)
	var node2 = _create_test_node("advanced", "military", 2, 100, ["base"])

	var all_nodes = {
		"base": node1,
		"advanced": node2
	}

	var result = validator.validate_culture_tree(all_nodes)
	assert_true(result["valid"])
	assert_eq(result["errors"].size(), 0)


func test_validate_culture_tree_nonexistent_prerequisite():
	var node = _create_test_node("node", "military", 2, 100, ["nonexistent"])

	var all_nodes = {"node": node}

	var result = validator.validate_culture_tree(all_nodes)
	assert_false(result["valid"])
	assert_gt(result["errors"].size(), 0)


func test_validate_culture_tree_nonexistent_exclusive():
	var node = _create_test_node("node", "military", 1, 50, [], ["nonexistent"])

	var all_nodes = {"node": node}

	var result = validator.validate_culture_tree(all_nodes)
	assert_false(result["valid"])
	assert_gt(result["errors"].size(), 0)


func test_validate_culture_tree_circular_dependency():
	var node1 = _create_test_node("node1", "military", 2, 100, ["node2"])
	var node2 = _create_test_node("node2", "military", 2, 100, ["node1"])

	var all_nodes = {
		"node1": node1,
		"node2": node2
	}

	var result = validator.validate_culture_tree(all_nodes)
	assert_false(result["valid"])
	assert_gt(result["errors"].size(), 0)


func test_validate_culture_tree_asymmetric_exclusion():
	var node_a = _create_test_node("path_a", "social", 2, 100, [], ["path_b"])
	var node_b = _create_test_node("path_b", "social", 2, 100, [], [])

	var all_nodes = {
		"path_a": node_a,
		"path_b": node_b
	}

	var result = validator.validate_culture_tree(all_nodes)
	assert_false(result["valid"])
	assert_gt(result["errors"].size(), 0)
