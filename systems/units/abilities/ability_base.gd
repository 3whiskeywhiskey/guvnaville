class_name Ability
extends Resource

## Ability Base Class - Framework for unit special abilities
## Part of Workstream 2.3: Unit System

# Ability identification
var id: String = ""                      # Unique ability ID
var name: String = ""                    # Display name
var description: String = ""             # Tooltip description
var icon: Texture2D = null               # Ability icon (optional)

# Cooldown system
var cooldown: int = 0                    # Turns between uses
var current_cooldown: int = 0            # Current cooldown counter

# Cost system
var cost_type: CostType = CostType.ACTION_POINT  # What it costs to use
var cost_amount: int = 1                 # Cost value

# Targeting
var range: int = -1                      # Ability range (-1 = self only)
var target_type: TargetType = TargetType.SELF  # What can be targeted

## Cost type enumeration
enum CostType {
	ACTION_POINT,    # Costs action points
	MOVEMENT_POINT,  # Costs movement points
	RESOURCE,        # Costs a resource (ammunition, medicine, etc.)
	FREE             # No cost
}

## Target type enumeration
enum TargetType {
	SELF,            # Only self
	FRIENDLY_UNIT,   # Allied units
	ENEMY_UNIT,      # Enemy units
	ANY_UNIT,        # Any unit
	TILE,            # Tile/position target
	AREA             # Area of effect
}

## Initialize ability
func _init():
	pass

## Check if ability can be used
func can_use(unit: Unit, target) -> bool:
	# Check cooldown
	if current_cooldown > 0:
		return false

	# Check if unit can act
	if not unit or not unit.can_act():
		return false

	# Check cost
	if not _check_cost(unit):
		return false

	# Check target validity (override in subclass)
	return is_valid_target(unit, target)

## Execute the ability
func execute(unit: Unit, target) -> bool:
	if not can_use(unit, target):
		return false

	# Apply cost
	_apply_cost(unit)

	# Start cooldown
	current_cooldown = cooldown

	# Execute ability effect (override in subclass)
	var success = apply_effect(unit, target)

	return success

## Get valid targets for this ability (override in subclass)
func get_valid_targets(unit: Unit) -> Array:
	return []

## Check if target is valid (override in subclass)
func is_valid_target(unit: Unit, target) -> bool:
	return true

## Apply ability effect (override in subclass - MUST IMPLEMENT)
func apply_effect(unit: Unit, target) -> bool:
	push_warning("Ability.apply_effect() not implemented for " + name)
	return false

## Tick cooldown (called each turn)
func tick_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"cooldown": cooldown,
		"current_cooldown": current_cooldown,
		"cost_type": cost_type,
		"cost_amount": cost_amount,
		"range": range,
		"target_type": target_type
	}

## Deserialize from dictionary
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	cooldown = data.get("cooldown", 0)
	current_cooldown = data.get("current_cooldown", 0)
	cost_type = data.get("cost_type", CostType.ACTION_POINT)
	cost_amount = data.get("cost_amount", 1)
	range = data.get("range", -1)
	target_type = data.get("target_type", TargetType.SELF)

## Private helper methods

func _check_cost(unit: Unit) -> bool:
	match cost_type:
		CostType.ACTION_POINT:
			return unit.actions_remaining >= cost_amount
		CostType.MOVEMENT_POINT:
			return unit.movement_remaining >= cost_amount
		CostType.RESOURCE:
			# Would check faction resources - stub for now
			return true
		CostType.FREE:
			return true
		_:
			return false

func _apply_cost(unit: Unit) -> void:
	match cost_type:
		CostType.ACTION_POINT:
			unit.actions_remaining = max(0, unit.actions_remaining - cost_amount)
		CostType.MOVEMENT_POINT:
			unit.movement_remaining = max(0, unit.movement_remaining - cost_amount)
		CostType.RESOURCE:
			# Would deduct faction resources - stub for now
			pass
		CostType.FREE:
			pass

## Helper to check range
func is_target_in_range(unit: Unit, target_pos: Vector3i) -> bool:
	if range < 0:  # Self-only ability
		return target_pos == unit.position

	var distance = abs(target_pos.x - unit.position.x) + \
				   abs(target_pos.y - unit.position.y) + \
				   abs(target_pos.z - unit.position.z)

	return distance <= range
