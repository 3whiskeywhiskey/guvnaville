class_name Unit
extends Resource

## Unit System - Core Unit Class
## Represents a single military or civilian unit in the game
## Part of Workstream 2.3: Unit System

# Core Properties
var id: int = -1                         # Unique unit identifier
var type: String = ""                    # Unit type (e.g., "militia", "soldier")
var faction_id: int = -1                 # Owning faction ID
var position: Vector3i = Vector3i.ZERO   # Current position on map
var stats: UnitStats = null              # Unit statistics object

# Combat Stats
var current_hp: int = 100                # Current hit points
var max_hp: int = 100                    # Maximum hit points
var morale: int = 50                     # Current morale (0-100)
var armor: int = 0                       # Armor value

# Progression
var experience: int = 0                  # Total experience points
var rank: UnitRank = UnitRank.ROOKIE     # Current rank
var level: int = 1                       # Unit level (1-10)

# Abilities and Equipment
var abilities: Array = []                # Array of Ability objects
var equipment: Array = []                # Array of Equipment objects
var status_effects: Array = []           # Array of StatusEffect objects

# Turn State
var movement_remaining: int = 0          # Movement points left this turn
var actions_remaining: int = 1           # Action points left this turn
var has_moved: bool = false              # Moved this turn?
var has_attacked: bool = false           # Attacked this turn?

# Metadata
var name: String = ""                    # Unit name (e.g., "1st Militia Squad")
var created_turn: int = 0                # Turn unit was created
var kills: int = 0                       # Enemy units killed
var battles_fought: int = 0              # Number of battles participated in

## Rank enumeration
enum UnitRank {
	ROOKIE,          # 0-99 XP
	TRAINED,         # 100-299 XP
	VETERAN,         # 300-699 XP
	ELITE,           # 700-1499 XP
	LEGENDARY        # 1500+ XP
}

## Experience thresholds for promotions
const XP_THRESHOLDS = {
	UnitRank.ROOKIE: 0,
	UnitRank.TRAINED: 100,
	UnitRank.VETERAN: 300,
	UnitRank.ELITE: 700,
	UnitRank.LEGENDARY: 1500
}

## Rank bonuses applied when unit is promoted
const RANK_BONUSES = {
	UnitRank.ROOKIE: {
		"stat_multiplier": 1.0,
		"morale_bonus": 0,
		"ability_slots": 2
	},
	UnitRank.TRAINED: {
		"stat_multiplier": 1.1,
		"morale_bonus": 10,
		"ability_slots": 2
	},
	UnitRank.VETERAN: {
		"stat_multiplier": 1.25,
		"morale_bonus": 20,
		"ability_slots": 3
	},
	UnitRank.ELITE: {
		"stat_multiplier": 1.4,
		"morale_bonus": 35,
		"ability_slots": 3
	},
	UnitRank.LEGENDARY: {
		"stat_multiplier": 1.6,
		"morale_bonus": 50,
		"ability_slots": 4
	}
}

## Initialize a new unit
func _init():
	stats = UnitStats.new()

## Serialize unit to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"faction_id": faction_id,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"stats": stats.to_dict() if stats else {},
		"current_hp": current_hp,
		"max_hp": max_hp,
		"morale": morale,
		"armor": armor,
		"experience": experience,
		"rank": rank,
		"level": level,
		"abilities": _serialize_abilities(),
		"equipment": _serialize_equipment(),
		"status_effects": _serialize_status_effects(),
		"movement_remaining": movement_remaining,
		"actions_remaining": actions_remaining,
		"has_moved": has_moved,
		"has_attacked": has_attacked,
		"name": name,
		"created_turn": created_turn,
		"kills": kills,
		"battles_fought": battles_fought
	}

## Deserialize unit from dictionary
func from_dict(data: Dictionary) -> void:
	id = data.get("id", -1)
	type = data.get("type", "")
	faction_id = data.get("faction_id", -1)

	var pos_data = data.get("position", {})
	position = Vector3i(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)

	if stats and data.has("stats"):
		stats.from_dict(data["stats"])

	current_hp = data.get("current_hp", 100)
	max_hp = data.get("max_hp", 100)
	morale = data.get("morale", 50)
	armor = data.get("armor", 0)
	experience = data.get("experience", 0)
	rank = data.get("rank", UnitRank.ROOKIE)
	level = data.get("level", 1)
	movement_remaining = data.get("movement_remaining", 0)
	actions_remaining = data.get("actions_remaining", 1)
	has_moved = data.get("has_moved", false)
	has_attacked = data.get("has_attacked", false)
	name = data.get("name", "")
	created_turn = data.get("created_turn", 0)
	kills = data.get("kills", 0)
	battles_fought = data.get("battles_fought", 0)

	# Note: abilities, equipment, and status_effects would need proper deserialization
	# with their respective classes once implemented

## Check if unit can perform actions this turn
func can_act() -> bool:
	return actions_remaining > 0 and current_hp > 0 and morale > 0

## Check if unit can move this turn
func can_move() -> bool:
	return movement_remaining > 0 and current_hp > 0 and morale > 0 and not _is_immobilized()

## Reset turn state for new turn
func reset_turn_state() -> void:
	movement_remaining = stats.movement if stats else 0
	actions_remaining = 1
	has_moved = false
	has_attacked = false

	# Update status effect durations
	_tick_status_effects()

	# Update ability cooldowns
	_tick_ability_cooldowns()

## Apply damage to unit
func take_damage(amount: int) -> int:
	var actual_damage = max(0, amount)
	current_hp = max(0, current_hp - actual_damage)
	return actual_damage

## Heal unit
func heal(amount: int) -> int:
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	return current_hp - old_hp

## Modify morale
func modify_morale(delta: int) -> void:
	morale = clamp(morale + delta, 0, 100)

## Add experience and check for promotion
func add_experience(xp: int) -> bool:
	experience += xp
	return _check_promotion()

## Get current rank bonuses
func get_rank_bonuses() -> Dictionary:
	return RANK_BONUSES.get(rank, RANK_BONUSES[UnitRank.ROOKIE])

## Get effective stats with all modifiers applied
func get_effective_attack() -> int:
	if not stats:
		return 0
	var base = stats.attack
	var multiplier = get_rank_bonuses()["stat_multiplier"]
	var modifier = _get_status_modifier("attack")
	return int(base * multiplier * modifier)

func get_effective_defense() -> int:
	if not stats:
		return 0
	var base = stats.defense
	var multiplier = get_rank_bonuses()["stat_multiplier"]
	var modifier = _get_status_modifier("defense")
	return int(base * multiplier * modifier)

func get_effective_movement() -> int:
	if not stats:
		return 0
	var base = stats.movement
	var modifier = _get_status_modifier("movement")
	return int(base * modifier)

## Check if unit is alive
func is_alive() -> bool:
	return current_hp > 0

## Check if unit is routed (morale broken)
func is_routed() -> bool:
	return morale <= 0

## Private helper methods

func _check_promotion() -> bool:
	var old_rank = rank

	# Check for rank up
	if experience >= XP_THRESHOLDS[UnitRank.LEGENDARY] and rank != UnitRank.LEGENDARY:
		rank = UnitRank.LEGENDARY
	elif experience >= XP_THRESHOLDS[UnitRank.ELITE] and rank < UnitRank.ELITE:
		rank = UnitRank.ELITE
	elif experience >= XP_THRESHOLDS[UnitRank.VETERAN] and rank < UnitRank.VETERAN:
		rank = UnitRank.VETERAN
	elif experience >= XP_THRESHOLDS[UnitRank.TRAINED] and rank < UnitRank.TRAINED:
		rank = UnitRank.TRAINED

	# Apply rank bonuses if promoted
	if rank != old_rank:
		_apply_rank_bonuses()
		return true

	return false

func _apply_rank_bonuses() -> void:
	var bonuses = get_rank_bonuses()

	# Apply morale bonus
	var base_morale = stats.morale_base if stats else 50
	morale = min(100, base_morale + bonuses["morale_bonus"])

func _is_immobilized() -> bool:
	# Check if any status effect immobilizes the unit
	for effect in status_effects:
		if effect.has("immobilized") and effect["immobilized"]:
			return true
	return false

func _get_status_modifier(stat_name: String) -> float:
	var modifier = 1.0
	for effect in status_effects:
		if effect.has("stat_modifiers") and effect["stat_modifiers"].has(stat_name):
			modifier *= effect["stat_modifiers"][stat_name]
	return modifier

func _tick_status_effects() -> void:
	# Decrement duration and remove expired effects
	var i = status_effects.size() - 1
	while i >= 0:
		var effect = status_effects[i]
		if effect.has("duration"):
			effect["duration"] -= 1
			if effect["duration"] <= 0:
				status_effects.remove_at(i)
		i -= 1

func _tick_ability_cooldowns() -> void:
	for ability in abilities:
		if ability.has("current_cooldown") and ability["current_cooldown"] > 0:
			ability["current_cooldown"] -= 1

func _serialize_abilities() -> Array:
	var result = []
	for ability in abilities:
		if ability.has("to_dict"):
			result.append(ability.to_dict())
		elif ability is Dictionary:
			result.append(ability)
	return result

func _serialize_equipment() -> Array:
	var result = []
	for item in equipment:
		if item.has("to_dict"):
			result.append(item.to_dict())
		elif item is Dictionary:
			result.append(item)
	return result

func _serialize_status_effects() -> Array:
	var result = []
	for effect in status_effects:
		if effect.has("to_dict"):
			result.append(effect.to_dict())
		elif effect is Dictionary:
			result.append(effect)
	return result


## Unit Statistics Class
class_name UnitStats
extends Resource

# Combat Stats
var attack: int = 10                     # Attack power (base)
var defense: int = 5                     # Defense value (base)
var range: int = 1                       # Attack range (tiles)
var armor: int = 0                       # Armor value
var stealth: int = 0                     # Stealth rating (0-100)
var detection: int = 5                   # Detection radius

# Movement Stats
var movement: int = 3                    # Movement points per turn
var movement_type: MovementType = MovementType.INFANTRY  # Movement type

# Special Stats
var morale_base: int = 50                # Base morale (affected by rank)
var supply_cost: int = 1                 # Resource consumption per turn
var vision_range: int = 5                # Sight range in tiles

## Movement type enumeration
enum MovementType {
	INFANTRY,        # Standard foot movement
	WHEELED,         # Wheeled vehicles (streets preferred)
	TRACKED,         # Tracked vehicles (all-terrain)
	AIRBORNE,        # Helicopter/aircraft (future expansion)
}

## Initialize with default values
func _init():
	pass

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"attack": attack,
		"defense": defense,
		"range": range,
		"armor": armor,
		"stealth": stealth,
		"detection": detection,
		"movement": movement,
		"movement_type": movement_type,
		"morale_base": morale_base,
		"supply_cost": supply_cost,
		"vision_range": vision_range
	}

## Deserialize from dictionary
func from_dict(data: Dictionary) -> void:
	attack = data.get("attack", 10)
	defense = data.get("defense", 5)
	range = data.get("range", 1)
	armor = data.get("armor", 0)
	stealth = data.get("stealth", 0)
	detection = data.get("detection", 5)
	movement = data.get("movement", 3)
	movement_type = data.get("movement_type", MovementType.INFANTRY)
	morale_base = data.get("morale_base", 50)
	supply_cost = data.get("supply_cost", 1)
	vision_range = data.get("vision_range", 5)
