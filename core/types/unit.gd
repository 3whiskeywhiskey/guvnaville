extends RefCounted
class_name Unit

## Unit - Data class for game units
##
## Represents a single military unit in the game with all its stats,
## position, and state information.

# ============================================================================
# PROPERTIES
# ============================================================================

## Unique identifier for this unit
var unit_id: String = ""

## Type of unit (e.g., "militia", "scouts", "soldiers")
var unit_type: String = ""

## Faction that owns this unit (0-8)
var faction_id: int = -1

## Current position on the map
var position: Vector3i = Vector3i.ZERO

## Maximum hit points
var max_hp: int = 100

## Current hit points
var current_hp: int = 100

## Attack stat
var attack: int = 10

## Defense stat
var defense: int = 10

## Movement points per turn
var movement: int = 3

## Morale (0-100)
var morale: int = 100

## Experience points
var experience: int = 0

## Unit rank (0=Rookie, 1=Veteran, 2=Elite, 3=Legendary)
var rank: int = 0

## List of ability IDs this unit has
var abilities: Array[String] = []

## Active status effects
var status_effects: Array = []

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(
	p_unit_id: String = "",
	p_unit_type: String = "",
	p_faction_id: int = -1,
	p_position: Vector3i = Vector3i.ZERO
) -> void:
	unit_id = p_unit_id
	unit_type = p_unit_type
	faction_id = p_faction_id
	position = p_position

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize unit to dictionary
func to_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"unit_type": unit_type,
		"faction_id": faction_id,
		"position": {
			"x": position.x,
			"y": position.y,
			"z": position.z
		},
		"max_hp": max_hp,
		"current_hp": current_hp,
		"attack": attack,
		"defense": defense,
		"movement": movement,
		"morale": morale,
		"experience": experience,
		"rank": rank,
		"abilities": abilities.duplicate(),
		"status_effects": status_effects.duplicate()
	}

## Deserialize unit from dictionary
func from_dict(data: Dictionary) -> void:
	unit_id = data.get("unit_id", "")
	unit_type = data.get("unit_type", "")
	faction_id = data.get("faction_id", -1)

	var pos_data = data.get("position", {})
	position = Vector3i(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)

	max_hp = data.get("max_hp", 100)
	current_hp = data.get("current_hp", 100)
	attack = data.get("attack", 10)
	defense = data.get("defense", 10)
	movement = data.get("movement", 3)
	morale = data.get("morale", 100)
	experience = data.get("experience", 0)
	rank = data.get("rank", 0)
	abilities = Array(data.get("abilities", []), TYPE_STRING, "", null)
	status_effects = data.get("status_effects", []).duplicate()

# ============================================================================
# COMBAT & STATS
# ============================================================================

## Apply damage to the unit
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	if current_hp == 0:
		# Unit is destroyed
		pass

## Heal the unit
func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)

## Add experience and check for promotion
func gain_experience(amount: int) -> void:
	experience += amount
	check_promotion()

## Check if unit should be promoted and promote if eligible
func check_promotion() -> bool:
	var promoted = false

	# Experience thresholds for each rank
	var rank_thresholds = [
		100,  # Rookie -> Veteran
		300,  # Veteran -> Elite
		600   # Elite -> Legendary
	]

	while rank < rank_thresholds.size() and experience >= rank_thresholds[rank]:
		rank += 1
		promoted = true

		# Apply stat bonuses for promotion
		max_hp += 10
		current_hp = max_hp
		attack += 2
		defense += 2
		morale = 100

	return promoted

## Check if unit is alive
func is_alive() -> bool:
	return current_hp > 0

## Get unit's effective combat power
func get_combat_power() -> int:
	var base_power = attack + defense
	var morale_modifier = morale / 100.0
	var rank_bonus = rank * 5
	return int(base_power * morale_modifier) + rank_bonus
