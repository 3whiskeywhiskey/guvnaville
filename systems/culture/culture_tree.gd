class_name CultureTree
extends Node

## Main culture tree manager
##
## Manages culture progression system including:
## - Culture tree structure and nodes
## - Culture point accumulation and spending
## - Node unlocking with validation
## - Effect calculation and synergies
## - Per-faction culture state

## Signals
signal culture_tree_loaded()
signal culture_points_earned(faction_id: int, amount: int, new_total: int)
signal culture_node_unlocked(faction_id: int, node_id: String, effects: Dictionary)
signal culture_node_unlock_failed(faction_id: int, node_id: String, reason: String)
signal synergy_activated(faction_id: int, synergy_id: String, bonus: Dictionary)
signal synergy_deactivated(faction_id: int, synergy_id: String)
signal culture_effects_updated(faction_id: int, total_effects: Dictionary)

## Culture state class for per-faction data
class CultureState:
	var faction_id: int
	var culture_points: int = 0
	var total_culture_earned: int = 0

	# Unlocked nodes by axis
	var military_nodes: Array[String] = []
	var economic_nodes: Array[String] = []
	var social_nodes: Array[String] = []
	var technological_nodes: Array[String] = []

	# Cached computed data
	var active_effects: Dictionary = {}
	var active_synergies: Array[Dictionary] = []
	var unlocked_units: Array[String] = []
	var unlocked_buildings: Array[String] = []
	var unlocked_policies: Array[String] = []

	func _init(id: int):
		faction_id = id

	## Get all unlocked nodes across all axes
	func get_all_unlocked() -> Array[String]:
		var all: Array[String] = []
		all.append_array(military_nodes)
		all.append_array(economic_nodes)
		all.append_array(social_nodes)
		all.append_array(technological_nodes)
		return all

	## Add unlocked node to appropriate axis
	func add_unlocked_node(node_id: String, axis: String) -> void:
		match axis:
			"military":
				if node_id not in military_nodes:
					military_nodes.append(node_id)
			"economic":
				if node_id not in economic_nodes:
					economic_nodes.append(node_id)
			"social":
				if node_id not in social_nodes:
					social_nodes.append(node_id)
			"technological", "technology":
				if node_id not in technological_nodes:
					technological_nodes.append(node_id)

## All culture nodes (id -> CultureNode)
var _all_nodes: Dictionary = {}

## Nodes organized by axis
var _nodes_by_axis: Dictionary = {
	"military": [],
	"economic": [],
	"social": [],
	"technological": []
}

## Synergy definitions
var _synergies: Array[Dictionary] = []

## Per-faction culture state (faction_id -> CultureState)
var _faction_states: Dictionary = {}

## Validator instance
var _validator: CultureValidator

## Effects calculator
var _effects: CultureEffects


## Initialize culture tree
func _init() -> void:
	_validator = CultureValidator.new()
	_effects = CultureEffects.new()


## Load culture tree from JSON data
## @param data: Dictionary containing all culture nodes and synergies
func load_culture_tree(data: Dictionary) -> void:
	_all_nodes.clear()
	_nodes_by_axis = {
		"military": [],
		"economic": [],
		"social": [],
		"technological": []
	}

	# Load nodes from culture_tree structure
	if data.has("culture_tree"):
		var tree_data = data["culture_tree"]

		# Load each axis
		for axis in ["military", "economic", "social", "technological"]:
			if tree_data.has(axis):
				var axis_nodes = tree_data[axis]
				if axis_nodes is Array:
					for node_data in axis_nodes:
						if node_data is Dictionary:
							var node = CultureNode.from_dict(node_data)
							if node.validate():
								_all_nodes[node.id] = node
								_nodes_by_axis[axis].append(node)
							else:
								push_error("Invalid culture node: %s" % node.id)

	# Load synergies if present
	if data.has("synergies"):
		var synergies_data = data["synergies"]
		if synergies_data is Array:
			_synergies = synergies_data
			_effects.set_synergy_definitions(_synergies)

	# Validate culture tree structure
	var validation = _validator.validate_culture_tree(_all_nodes)
	if not validation["valid"]:
		for error in validation["errors"]:
			push_error("Culture tree validation error: %s" % error)

	culture_tree_loaded.emit()


## Get all culture nodes in tree
## @return: Array of all CultureNode objects
func get_all_nodes() -> Array[CultureNode]:
	var nodes: Array[CultureNode] = []
	for node_id in _all_nodes:
		nodes.append(_all_nodes[node_id])
	return nodes


## Get all nodes for specific axis
## @param axis: "military", "economic", "social", or "technological"
## @return: Array of CultureNode objects for that axis
func get_nodes_by_axis(axis: String) -> Array[CultureNode]:
	if _nodes_by_axis.has(axis):
		return _nodes_by_axis[axis].duplicate()
	return []


## Get specific culture node by ID
## @param node_id: Node identifier
## @return: CultureNode or null if not found
func get_node_by_id(node_id: String) -> CultureNode:
	return _all_nodes.get(node_id, null)


## Add culture points to faction
## @param faction_id: Faction receiving points
## @param points: Number of points to add (can be negative for spending)
func add_culture_points(faction_id: int, points: int) -> void:
	var state = _get_or_create_state(faction_id)
	state.culture_points += points

	# Track total earned (only for positive additions)
	if points > 0:
		state.total_culture_earned += points

	culture_points_earned.emit(faction_id, points, state.culture_points)


## Get current unspent culture points
## @param faction_id: Faction to query
## @return: Available culture points
func get_culture_points(faction_id: int) -> int:
	var state = _get_or_create_state(faction_id)
	return state.culture_points


## Get lifetime total culture points earned
## @param faction_id: Faction to query
## @return: Total points ever earned (including spent)
func get_total_culture_earned(faction_id: int) -> int:
	var state = _get_or_create_state(faction_id)
	return state.total_culture_earned


## Attempt to unlock a culture node
## @param faction_id: Faction unlocking the node
## @param node_id: Node identifier to unlock
## @return: true if successful, false if failed
func unlock_node(faction_id: int, node_id: String) -> bool:
	var node = get_node_by_id(node_id)
	if node == null:
		culture_node_unlock_failed.emit(faction_id, node_id, "Node not found")
		return false

	var state = _get_or_create_state(faction_id)
	var unlocked_nodes = state.get_all_unlocked()

	# Validate unlock
	var error = _validator.validate_unlock(node, unlocked_nodes, state.culture_points, _all_nodes)
	if error != CultureValidator.ValidationError.NONE:
		var reason = _validator.get_failure_reason(error, node, unlocked_nodes, state.culture_points, _all_nodes)
		culture_node_unlock_failed.emit(faction_id, node_id, reason)
		return false

	# Spend culture points
	state.culture_points -= node.cost

	# Add to unlocked nodes
	state.add_unlocked_node(node_id, node.axis)

	# Check for new synergies
	_check_synergies(faction_id, state)

	# Recalculate effects
	_update_faction_effects(faction_id, state)

	# Emit success
	culture_node_unlocked.emit(faction_id, node_id, node.effects)

	return true


## Check if faction can unlock node (validation only)
## @param faction_id: Faction to check
## @param node_id: Node to validate
## @return: true if all requirements met
func can_unlock_node(faction_id: int, node_id: String) -> bool:
	var node = get_node_by_id(node_id)
	if node == null:
		return false

	var state = _get_or_create_state(faction_id)
	var unlocked_nodes = state.get_all_unlocked()

	var error = _validator.validate_unlock(node, unlocked_nodes, state.culture_points, _all_nodes)
	return error == CultureValidator.ValidationError.NONE


## Get detailed reason why node cannot be unlocked
## @param faction_id: Faction attempting unlock
## @param node_id: Node being checked
## @return: Human-readable reason string or empty if can unlock
func get_unlock_failure_reason(faction_id: int, node_id: String) -> String:
	var node = get_node_by_id(node_id)
	if node == null:
		return "Node not found"

	var state = _get_or_create_state(faction_id)
	var unlocked_nodes = state.get_all_unlocked()

	var error = _validator.validate_unlock(node, unlocked_nodes, state.culture_points, _all_nodes)
	return _validator.get_failure_reason(error, node, unlocked_nodes, state.culture_points, _all_nodes)


## Get all unlocked node IDs for faction
## @param faction_id: Faction to query
## @return: Array of node ID strings
func get_unlocked_nodes(faction_id: int) -> Array[String]:
	var state = _get_or_create_state(faction_id)
	return state.get_all_unlocked()


## Get unlocked nodes for specific axis
## @param faction_id: Faction to query
## @param axis: Axis to filter by
## @return: Array of node ID strings
func get_unlocked_nodes_by_axis(faction_id: int, axis: String) -> Array[String]:
	var state = _get_or_create_state(faction_id)
	match axis:
		"military":
			return state.military_nodes.duplicate()
		"economic":
			return state.economic_nodes.duplicate()
		"social":
			return state.social_nodes.duplicate()
		"technological", "technology":
			return state.technological_nodes.duplicate()
		_:
			return []


## Get nodes that can be unlocked (prerequisites met, not yet unlocked)
## @param faction_id: Faction to query
## @return: Array of node ID strings
func get_available_nodes(faction_id: int) -> Array[String]:
	var state = _get_or_create_state(faction_id)
	var unlocked = state.get_all_unlocked()
	var available: Array[String] = []

	for node_id in _all_nodes:
		if node_id in unlocked:
			continue

		var node = _all_nodes[node_id]
		var error = _validator.validate_unlock(node, unlocked, state.culture_points, _all_nodes)

		# Available if only cost is the issue, or if all requirements met
		if error == CultureValidator.ValidationError.NONE or error == CultureValidator.ValidationError.INSUFFICIENT_POINTS:
			available.append(node_id)

	return available


## Get nodes that cannot yet be unlocked (prerequisites not met)
## @param faction_id: Faction to query
## @return: Array of node ID strings
func get_locked_nodes(faction_id: int) -> Array[String]:
	var state = _get_or_create_state(faction_id)
	var unlocked = state.get_all_unlocked()
	var locked: Array[String] = []

	for node_id in _all_nodes:
		if node_id in unlocked:
			continue

		var node = _all_nodes[node_id]

		# Check prerequisites (ignore cost)
		if not _validator.validate_prerequisites(node, unlocked):
			locked.append(node_id)
		elif not _validator.validate_exclusions(node, unlocked):
			locked.append(node_id)
		elif not _validator.validate_tier_progression(node, unlocked, _all_nodes):
			locked.append(node_id)

	return locked


## Get aggregated culture effects for faction (cached)
## @param faction_id: Faction to query
## @return: Dictionary of effect totals
func get_culture_effects(faction_id: int) -> Dictionary:
	var state = _get_or_create_state(faction_id)
	return state.active_effects.duplicate(true)


## Calculate synergies based on unlocked nodes
## @param faction_id: Faction to check
## @param unlocked_nodes: Array of unlocked node IDs
## @return: Dictionary with synergy bonuses
func calculate_synergies(faction_id: int, unlocked_nodes: Array[String]) -> Dictionary:
	var synergies = _effects.calculate_synergy_bonuses(unlocked_nodes, _synergies)

	# Aggregate synergy effects
	var total_synergy_effects: Dictionary = {}
	for synergy in synergies:
		if synergy.has("effects"):
			var synergy_effects = synergy["effects"]
			if synergy_effects is Dictionary:
				total_synergy_effects = _effects.merge_effects(total_synergy_effects, synergy_effects)

	return total_synergy_effects


## Get list of currently active synergies
## @param faction_id: Faction to query
## @return: Array of synergy dictionaries
func get_active_synergies(faction_id: int) -> Array[Dictionary]:
	var state = _get_or_create_state(faction_id)
	return state.active_synergies.duplicate()


## Get complete culture state for faction (for saving)
## @param faction_id: Faction to query
## @return: CultureState object
func get_faction_culture_state(faction_id: int) -> CultureState:
	return _get_or_create_state(faction_id)


## Restore culture state for faction (from save)
## @param faction_id: Faction being restored
## @param state: CultureState to apply
func set_faction_culture_state(faction_id: int, state: CultureState) -> void:
	_faction_states[faction_id] = state


## Serialize faction culture state to dictionary
## @param faction_id: Faction to serialize
## @return: JSON-serializable dictionary
func to_save_dict(faction_id: int) -> Dictionary:
	var state = _get_or_create_state(faction_id)
	return {
		"culture_points": state.culture_points,
		"total_culture_earned": state.total_culture_earned,
		"military_nodes": state.military_nodes.duplicate(),
		"economic_nodes": state.economic_nodes.duplicate(),
		"social_nodes": state.social_nodes.duplicate(),
		"technological_nodes": state.technological_nodes.duplicate()
	}


## Deserialize faction culture state from dictionary
## @param faction_id: Faction being loaded
## @param data: Save data dictionary
func from_save_dict(faction_id: int, data: Dictionary) -> void:
	var state = _get_or_create_state(faction_id)

	state.culture_points = data.get("culture_points", 0)
	state.total_culture_earned = data.get("total_culture_earned", 0)

	if data.has("military_nodes"):
		state.military_nodes = data["military_nodes"].duplicate()
	if data.has("economic_nodes"):
		state.economic_nodes = data["economic_nodes"].duplicate()
	if data.has("social_nodes"):
		state.social_nodes = data["social_nodes"].duplicate()
	if data.has("technological_nodes"):
		state.technological_nodes = data["technological_nodes"].duplicate()

	# Recalculate effects and synergies
	_check_synergies(faction_id, state)
	_update_faction_effects(faction_id, state)


## Get or create faction state
## @param faction_id: Faction ID
## @return: CultureState for faction
func _get_or_create_state(faction_id: int) -> CultureState:
	if not _faction_states.has(faction_id):
		_faction_states[faction_id] = CultureState.new(faction_id)
	return _faction_states[faction_id]


## Check for new synergies after unlocking a node
## @param faction_id: Faction ID
## @param state: Faction culture state
func _check_synergies(faction_id: int, state: CultureState) -> void:
	var unlocked = state.get_all_unlocked()
	var new_synergies = _effects.calculate_synergy_bonuses(unlocked, _synergies)

	# Check for newly activated synergies
	for synergy in new_synergies:
		var synergy_id = synergy.get("id", "")
		var already_active = false

		for active in state.active_synergies:
			if active.get("id", "") == synergy_id:
				already_active = true
				break

		if not already_active:
			state.active_synergies.append(synergy)
			var bonus = synergy.get("effects", {})
			synergy_activated.emit(faction_id, synergy_id, bonus)

	# Check for deactivated synergies
	var deactivated: Array[int] = []
	for i in range(state.active_synergies.size()):
		var active_synergy = state.active_synergies[i]
		var synergy_id = active_synergy.get("id", "")
		var still_active = false

		for synergy in new_synergies:
			if synergy.get("id", "") == synergy_id:
				still_active = true
				break

		if not still_active:
			deactivated.append(i)
			synergy_deactivated.emit(faction_id, synergy_id)

	# Remove deactivated synergies (reverse order to maintain indices)
	deactivated.reverse()
	for idx in deactivated:
		state.active_synergies.remove_at(idx)


## Update faction's cached effects
## @param faction_id: Faction ID
## @param state: Faction culture state
func _update_faction_effects(faction_id: int, state: CultureState) -> void:
	var unlocked_ids = state.get_all_unlocked()
	var unlocked_node_objects: Array[CultureNode] = []

	for node_id in unlocked_ids:
		if _all_nodes.has(node_id):
			unlocked_node_objects.append(_all_nodes[node_id])

	# Calculate effects with synergies
	state.active_effects = _effects.calculate_total_effects_with_synergies(unlocked_node_objects, unlocked_ids)

	# Extract unlocked content
	var content = _effects.get_unlocked_content(unlocked_node_objects)
	state.unlocked_units = content["units"]
	state.unlocked_buildings = content["buildings"]
	state.unlocked_policies = content["policies"]

	culture_effects_updated.emit(faction_id, state.active_effects)
