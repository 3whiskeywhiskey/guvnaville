class_name CultureNode
extends Resource

## Culture node definition for culture tree progression system
##
## Represents a single node in the culture tree that can be unlocked by spending
## culture points. Each node provides effects, unlocks content, and may have
## prerequisites or mutually exclusive relationships.

## Unique identifier (e.g., "gov_autocratic_warlord")
@export var id: String = ""

## Display name shown to player
@export var name: String = ""

## Description of the node and its effects
@export var description: String = ""

## Flavor text for narrative immersion
@export var flavor_text: String = ""

## Axis this node belongs to: "military", "economic", "social", or "technological"
@export var axis: String = ""

## Tier level (1=base, 2-4=progression)
@export var tier: int = 1

## Culture points required to unlock
@export var cost: int = 50

## Array of prerequisite node IDs that must be unlocked first
@export var prerequisites: Array[String] = []

## Array of mutually exclusive node IDs (cannot coexist)
@export var mutually_exclusive: Array[String] = []

## Effects provided by this node (stat modifiers, bonuses)
@export var effects: Dictionary = {}

## Content unlocked by this node (units, buildings, policies)
@export var unlocks: Dictionary = {}


## Create CultureNode from dictionary data (JSON deserialization)
## @param data: Dictionary containing node data
## @return: CultureNode instance
static func from_dict(data: Dictionary) -> CultureNode:
	var node = CultureNode.new()

	# Required fields
	node.id = data.get("id", "")
	node.name = data.get("name", "")
	node.description = data.get("description", "")
	node.axis = data.get("axis", "")
	node.tier = data.get("tier", 1)
	node.cost = data.get("cost", 50)

	# Optional fields
	node.flavor_text = data.get("flavor_text", "")

	# Prerequisites array
	if data.has("prerequisites"):
		var prereqs = data["prerequisites"]
		if prereqs is Array:
			for prereq in prereqs:
				if prereq is String:
					node.prerequisites.append(prereq)

	# Mutually exclusive array
	if data.has("mutually_exclusive"):
		var exclusive = data["mutually_exclusive"]
		if exclusive is Array:
			for excl in exclusive:
				if excl is String:
					node.mutually_exclusive.append(excl)

	# Parse effects from data structure
	if data.has("effects"):
		var effects_data = data["effects"]
		if effects_data is Dictionary:
			node.effects = _parse_effects(effects_data)
			node.unlocks = _parse_unlocks(effects_data)

	return node


## Parse effects from data structure
## @param effects_data: Dictionary containing effects
## @return: Normalized effects dictionary
static func _parse_effects(effects_data: Dictionary) -> Dictionary:
	var effects = {}

	# Extract stat modifiers
	if effects_data.has("stat_modifiers"):
		var modifiers = effects_data["stat_modifiers"]
		if modifiers is Dictionary:
			for key in modifiers:
				effects[key] = modifiers[key]

	# Extract special abilities
	if effects_data.has("special_abilities"):
		var abilities = effects_data["special_abilities"]
		if abilities is Array:
			effects["special_abilities"] = abilities

	return effects


## Parse unlocks from data structure
## @param effects_data: Dictionary containing unlocks
## @return: Unlocks dictionary
static func _parse_unlocks(effects_data: Dictionary) -> Dictionary:
	var unlocks = {
		"units": [],
		"buildings": [],
		"policies": []
	}

	# Extract unit unlocks
	if effects_data.has("unit_unlocks"):
		var units = effects_data["unit_unlocks"]
		if units is Array:
			for unit in units:
				if unit is String:
					unlocks["units"].append(unit)

	# Extract building unlocks
	if effects_data.has("building_unlocks"):
		var buildings = effects_data["building_unlocks"]
		if buildings is Array:
			for building in buildings:
				if building is String:
					unlocks["buildings"].append(building)

	# Extract policy unlocks
	if effects_data.has("policy_unlocks"):
		var policies = effects_data["policy_unlocks"]
		if policies is Array:
			for policy in policies:
				if policy is String:
					unlocks["policies"].append(policy)

	return unlocks


## Convert node to dictionary (JSON serialization)
## @return: Dictionary representation of the node
func to_dict() -> Dictionary:
	var data = {
		"id": id,
		"name": name,
		"description": description,
		"axis": axis,
		"tier": tier,
		"cost": cost,
		"prerequisites": prerequisites.duplicate(),
		"mutually_exclusive": mutually_exclusive.duplicate(),
		"effects": effects.duplicate(true),
		"unlocks": unlocks.duplicate(true)
	}

	if flavor_text != "":
		data["flavor_text"] = flavor_text

	return data


## Validate node data integrity
## @return: true if valid, false otherwise
func validate() -> bool:
	# Check required fields
	if id.is_empty():
		push_error("CultureNode validation failed: id is empty")
		return false

	if name.is_empty():
		push_error("CultureNode validation failed: name is empty for node '%s'" % id)
		return false

	if axis.is_empty():
		push_error("CultureNode validation failed: axis is empty for node '%s'" % id)
		return false

	# Validate axis value
	var valid_axes = ["military", "economic", "social", "technological", "governance", "belief", "technology"]
	if not axis in valid_axes:
		push_error("CultureNode validation failed: invalid axis '%s' for node '%s'" % [axis, id])
		return false

	# Validate tier
	if tier < 1 or tier > 4:
		push_error("CultureNode validation failed: invalid tier %d for node '%s' (must be 1-4)" % [tier, id])
		return false

	# Validate cost
	if cost < 0:
		push_error("CultureNode validation failed: negative cost %d for node '%s'" % [cost, id])
		return false

	# Check for circular prerequisites (node referencing itself)
	if id in prerequisites:
		push_error("CultureNode validation failed: node '%s' has itself as prerequisite" % id)
		return false

	# Check for self-exclusion
	if id in mutually_exclusive:
		push_error("CultureNode validation failed: node '%s' is mutually exclusive with itself" % id)
		return false

	return true


## Get all stat modifier keys from this node
## @return: Array of effect keys
func get_effect_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in effects.keys():
		if key != "special_abilities":
			keys.append(key)
	return keys


## Get specific effect value
## @param effect_key: Key of the effect to retrieve
## @param default: Default value if effect not found
## @return: Effect value or default
func get_effect_value(effect_key: String, default: float = 0.0) -> float:
	if effects.has(effect_key):
		var value = effects[effect_key]
		if value is float or value is int:
			return float(value)
	return default


## Check if this node has a specific prerequisite
## @param node_id: ID of potential prerequisite
## @return: true if node_id is a prerequisite
func has_prerequisite(node_id: String) -> bool:
	return node_id in prerequisites


## Check if this node is mutually exclusive with another
## @param node_id: ID of node to check
## @return: true if nodes are mutually exclusive
func is_exclusive_with(node_id: String) -> bool:
	return node_id in mutually_exclusive
