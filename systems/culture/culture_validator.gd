class_name CultureValidator
extends RefCounted

## Culture node validation system
##
## Validates whether a faction can unlock a culture node based on:
## - Prerequisites (required nodes must be unlocked first)
## - Mutual exclusions (conflicting nodes cannot coexist)
## - Cost requirements (sufficient culture points)
## - Tier progression (must unlock lower tiers first in same axis)

## Error codes for validation failures
enum ValidationError {
	NONE = 0,
	INSUFFICIENT_POINTS,
	MISSING_PREREQUISITES,
	EXCLUSIVE_CONFLICT,
	INVALID_TIER_PROGRESSION,
	NODE_ALREADY_UNLOCKED,
	NODE_NOT_FOUND
}


## Validate all requirements for unlocking a node
## @param node: CultureNode to validate
## @param unlocked_nodes: Array of currently unlocked node IDs
## @param available_points: Current culture points balance
## @param all_nodes: Dictionary of all nodes (id -> CultureNode) for tier validation
## @return: ValidationError code (NONE if valid)
func validate_unlock(
	node: CultureNode,
	unlocked_nodes: Array[String],
	available_points: int,
	all_nodes: Dictionary
) -> ValidationError:
	# Check if node is already unlocked
	if node.id in unlocked_nodes:
		return ValidationError.NODE_ALREADY_UNLOCKED

	# Validate cost
	if not validate_cost(node, available_points):
		return ValidationError.INSUFFICIENT_POINTS

	# Validate prerequisites
	if not validate_prerequisites(node, unlocked_nodes):
		return ValidationError.MISSING_PREREQUISITES

	# Validate exclusions
	if not validate_exclusions(node, unlocked_nodes):
		return ValidationError.EXCLUSIVE_CONFLICT

	# Validate tier progression
	if not validate_tier_progression(node, unlocked_nodes, all_nodes):
		return ValidationError.INVALID_TIER_PROGRESSION

	return ValidationError.NONE


## Check if all prerequisite nodes are unlocked
## @param node: CultureNode to validate
## @param unlocked_nodes: Currently unlocked node IDs
## @return: true if all prerequisites met
func validate_prerequisites(
	node: CultureNode,
	unlocked_nodes: Array[String]
) -> bool:
	for prereq_id in node.prerequisites:
		if prereq_id not in unlocked_nodes:
			return false
	return true


## Check if any mutually exclusive nodes are unlocked
## @param node: CultureNode to validate
## @param unlocked_nodes: Currently unlocked node IDs
## @return: true if no conflicts (false if exclusive node already unlocked)
func validate_exclusions(
	node: CultureNode,
	unlocked_nodes: Array[String]
) -> bool:
	for exclusive_id in node.mutually_exclusive:
		if exclusive_id in unlocked_nodes:
			return false
	return true


## Check if faction has enough culture points
## @param node: CultureNode to validate
## @param available_points: Current culture point balance
## @return: true if sufficient points
func validate_cost(
	node: CultureNode,
	available_points: int
) -> bool:
	return available_points >= node.cost


## Check if tier progression is valid (must unlock lower tiers first in same axis)
## @param node: CultureNode to validate
## @param unlocked_nodes: Currently unlocked node IDs
## @param all_nodes: Dictionary of all nodes (id -> CultureNode)
## @return: true if tier progression valid
func validate_tier_progression(
	node: CultureNode,
	unlocked_nodes: Array[String],
	all_nodes: Dictionary
) -> bool:
	# Tier 1 nodes can always be unlocked (no tier requirements)
	if node.tier <= 1:
		return true

	# Check if at least one lower tier node in the same axis is unlocked
	var has_lower_tier = false
	for unlocked_id in unlocked_nodes:
		if all_nodes.has(unlocked_id):
			var unlocked_node = all_nodes[unlocked_id]
			# Check if it's in the same axis and lower tier
			if unlocked_node.axis == node.axis and unlocked_node.tier < node.tier:
				has_lower_tier = true
				break

	return has_lower_tier


## Get list of prerequisite node IDs not yet unlocked
## @param node: CultureNode being checked
## @param unlocked_nodes: Currently unlocked node IDs
## @return: Array of missing prerequisite node IDs
func get_missing_prerequisites(
	node: CultureNode,
	unlocked_nodes: Array[String]
) -> Array[String]:
	var missing: Array[String] = []
	for prereq_id in node.prerequisites:
		if prereq_id not in unlocked_nodes:
			missing.append(prereq_id)
	return missing


## Get list of conflicting exclusive nodes already unlocked
## @param node: CultureNode being checked
## @param unlocked_nodes: Currently unlocked node IDs
## @return: Array of conflicting node IDs
func get_exclusive_conflicts(
	node: CultureNode,
	unlocked_nodes: Array[String]
) -> Array[String]:
	var conflicts: Array[String] = []
	for exclusive_id in node.mutually_exclusive:
		if exclusive_id in unlocked_nodes:
			conflicts.append(exclusive_id)
	return conflicts


## Get human-readable failure reason for a validation error
## @param error: ValidationError code
## @param node: CultureNode that failed validation
## @param unlocked_nodes: Currently unlocked node IDs
## @param available_points: Current culture points
## @param all_nodes: Dictionary of all nodes
## @return: Human-readable error message
func get_failure_reason(
	error: ValidationError,
	node: CultureNode,
	unlocked_nodes: Array[String],
	available_points: int,
	all_nodes: Dictionary
) -> String:
	match error:
		ValidationError.NONE:
			return ""

		ValidationError.NODE_ALREADY_UNLOCKED:
			return "Node '%s' is already unlocked" % node.name

		ValidationError.INSUFFICIENT_POINTS:
			var needed = node.cost - available_points
			return "Requires %d culture points (need %d more)" % [node.cost, needed]

		ValidationError.MISSING_PREREQUISITES:
			var missing = get_missing_prerequisites(node, unlocked_nodes)
			var missing_names: Array[String] = []
			for prereq_id in missing:
				if all_nodes.has(prereq_id):
					missing_names.append(all_nodes[prereq_id].name)
				else:
					missing_names.append(prereq_id)
			return "Missing prerequisites: %s" % ", ".join(missing_names)

		ValidationError.EXCLUSIVE_CONFLICT:
			var conflicts = get_exclusive_conflicts(node, unlocked_nodes)
			var conflict_names: Array[String] = []
			for conflict_id in conflicts:
				if all_nodes.has(conflict_id):
					conflict_names.append(all_nodes[conflict_id].name)
				else:
					conflict_names.append(conflict_id)
			return "Conflicts with already unlocked: %s" % ", ".join(conflict_names)

		ValidationError.INVALID_TIER_PROGRESSION:
			return "Must unlock a lower tier node in the %s axis first" % node.axis

		ValidationError.NODE_NOT_FOUND:
			return "Node not found in culture tree"

		_:
			return "Unknown validation error"


## Validate culture tree data structure for circular dependencies
## @param all_nodes: Dictionary of all nodes (id -> CultureNode)
## @return: Dictionary with "valid" bool and "errors" array
func validate_culture_tree(all_nodes: Dictionary) -> Dictionary:
	var errors: Array[String] = []

	# Check for circular prerequisite dependencies
	for node_id in all_nodes:
		var node = all_nodes[node_id]
		var visited: Array[String] = []
		if _has_circular_dependency(node, all_nodes, visited):
			errors.append("Circular dependency detected for node '%s'" % node_id)

	# Validate all prerequisites exist
	for node_id in all_nodes:
		var node = all_nodes[node_id]
		for prereq_id in node.prerequisites:
			if not all_nodes.has(prereq_id):
				errors.append("Node '%s' has non-existent prerequisite '%s'" % [node_id, prereq_id])

	# Validate all mutual exclusions exist
	for node_id in all_nodes:
		var node = all_nodes[node_id]
		for exclusive_id in node.mutually_exclusive:
			if not all_nodes.has(exclusive_id):
				errors.append("Node '%s' has non-existent exclusive node '%s'" % [node_id, exclusive_id])

	# Validate mutual exclusions are bidirectional
	for node_id in all_nodes:
		var node = all_nodes[node_id]
		for exclusive_id in node.mutually_exclusive:
			if all_nodes.has(exclusive_id):
				var exclusive_node = all_nodes[exclusive_id]
				if node_id not in exclusive_node.mutually_exclusive:
					errors.append("Mutual exclusion not bidirectional: '%s' excludes '%s' but not vice versa" % [node_id, exclusive_id])

	return {
		"valid": errors.is_empty(),
		"errors": errors
	}


## Check for circular dependencies in prerequisite chain
## @param node: Node to check
## @param all_nodes: Dictionary of all nodes
## @param visited: Array of node IDs already visited (for cycle detection)
## @return: true if circular dependency found
func _has_circular_dependency(
	node: CultureNode,
	all_nodes: Dictionary,
	visited: Array[String]
) -> bool:
	if node.id in visited:
		return true

	visited.append(node.id)

	for prereq_id in node.prerequisites:
		if all_nodes.has(prereq_id):
			var prereq_node = all_nodes[prereq_id]
			if _has_circular_dependency(prereq_node, all_nodes, visited):
				return true

	# Remove from visited for other paths
	visited.erase(node.id)
	return false
