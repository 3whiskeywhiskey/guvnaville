extends RefCounted
class_name Building

## Building - Data class for structures
##
## Represents a building constructed on a tile, with its stats,
## garrison, and production capabilities.

# ============================================================================
# PROPERTIES
# ============================================================================

## Unique identifier for this building
var building_id: String = ""

## Type of building (e.g., "workshop", "barracks", "watchtower")
var building_type: String = ""

## Faction that owns this building
var faction_id: int = -1

## Position on the map
var position: Vector3i = Vector3i.ZERO

## Maximum hit points
var max_hp: int = 100

## Current hit points
var current_hp: int = 100

## Whether the building is operational
var is_operational: bool = true

## Production bonuses provided {resource_type: bonus_amount}
var production_bonus: Dictionary = {}

## Garrisoned unit IDs
var garrison: Array[String] = []

## Active building effects
var effects: Array = []

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(
	p_building_id: String = "",
	p_building_type: String = "",
	p_faction_id: int = -1,
	p_position: Vector3i = Vector3i.ZERO
) -> void:
	building_id = p_building_id
	building_type = p_building_type
	faction_id = p_faction_id
	position = p_position

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize building to dictionary
func to_dict() -> Dictionary:
	return {
		"building_id": building_id,
		"building_type": building_type,
		"faction_id": faction_id,
		"position": {
			"x": position.x,
			"y": position.y,
			"z": position.z
		},
		"max_hp": max_hp,
		"current_hp": current_hp,
		"is_operational": is_operational,
		"production_bonus": production_bonus.duplicate(),
		"garrison": garrison.duplicate(),
		"effects": effects.duplicate()
	}

## Deserialize building from dictionary
func from_dict(data: Dictionary) -> void:
	building_id = data.get("building_id", "")
	building_type = data.get("building_type", "")
	faction_id = data.get("faction_id", -1)

	var pos_data = data.get("position", {})
	position = Vector3i(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)

	max_hp = data.get("max_hp", 100)
	current_hp = data.get("current_hp", 100)
	is_operational = data.get("is_operational", true)
	production_bonus = data.get("production_bonus", {}).duplicate()
	garrison = Array(data.get("garrison", []), TYPE_STRING, "", null)
	effects = data.get("effects", []).duplicate()

# ============================================================================
# BUILDING MANAGEMENT
# ============================================================================

## Apply damage to the building
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)

	# Building becomes non-operational if heavily damaged
	if current_hp < max_hp * 0.3:
		is_operational = false

	if current_hp == 0:
		# Building is destroyed
		garrison.clear()

## Repair the building
func repair(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)

	# Restore operational status if repaired enough
	if current_hp >= max_hp * 0.3:
		is_operational = true

## Add a unit to garrison
func add_garrison(unit_id: String) -> bool:
	# Check if there's room (max 5 units)
	if garrison.size() >= 5:
		return false

	if not garrison.has(unit_id):
		garrison.append(unit_id)
		return true

	return false

## Remove a unit from garrison
func remove_garrison(unit_id: String) -> bool:
	var idx = garrison.find(unit_id)
	if idx >= 0:
		garrison.remove_at(idx)
		return true
	return false

## Check if building is destroyed
func is_destroyed() -> bool:
	return current_hp == 0

## Get garrison count
func get_garrison_count() -> int:
	return garrison.size()

## Check if garrison is full
func is_garrison_full() -> bool:
	return garrison.size() >= 5

## Get production bonus for a resource type
func get_production_bonus(resource_type: String) -> int:
	return production_bonus.get(resource_type, 0)
