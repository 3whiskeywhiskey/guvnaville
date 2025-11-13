class_name MoraleSystem
extends Node

## Handles morale checks, morale damage, and retreat logic
##
## This singleton manages all morale-related calculations including
## morale checks, retreat decisions, and morale restoration.

## Morale damage by trigger type
const MORALE_DAMAGE = {
	"hp_critical": 20,
	"ally_killed": 10,
	"outnumbered": 15,
	"leader_killed": 25,
	"combat_loss": 20,
	"siege_attrition": 10,
	"ambushed": 15,
	"heavy_casualties": 25
}

## Morale restoration by source
const MORALE_RESTORATION = {
	"rest": 10,
	"victory": 20,
	"rally": 15,
	"propaganda": 5,
	"hero_presence": 10,
	"supplies": 5
}

## Rally chance based on morale
const BASE_RALLY_CHANCE: float = 0.3


## Performs morale check on a unit and determines if it retreats
##
## Morale Check Triggers:
## - hp_critical: Unit lost 50%+ HP
## - ally_killed: Friendly unit destroyed nearby (within 5 tiles)
## - outnumbered: Outnumbered 3:1 or more
## - leader_killed: Leader/hero unit destroyed
## - combat_loss: Lost combat engagement
## - combat_victory: Won combat engagement (morale gain)
##
## @param unit: Unit to check morale (Dictionary with morale, stats, etc.)
## @param trigger: Reason for morale check
## @param morale_damage: Base morale damage to apply (before modifiers)
## @return: MoraleCheckResult with state and retreat decision
static func apply_morale_check(
	unit: Dictionary,
	trigger: String,
	morale_damage_override: int = 0
) -> MoraleCheckResult:
	var result = MoraleCheckResult.new()

	if not unit:
		push_warning("MoraleSystem.apply_morale_check: Invalid unit")
		return result

	# Check for morale immunity
	if CombatModifiersCalculator.is_morale_immune(unit):
		result.unit_id = unit.get("id", "")
		result.previous_morale = unit.get("morale", 100)
		result.current_morale = unit.get("morale", 100)
		result.morale_change = 0
		result.state = MoraleCheckResult.MoraleState.HOLDING
		result.will_retreat = false
		return result

	# Get current morale
	result.unit_id = unit.get("id", "")
	result.previous_morale = unit.get("morale", 50)

	# Calculate morale damage
	var damage: int = morale_damage_override if morale_damage_override > 0 else calculate_morale_damage(unit, trigger, {})

	# Apply morale change
	result.morale_change = -damage if trigger != "combat_victory" else damage
	result.current_morale = clamp(result.previous_morale + result.morale_change, 0, 100)

	# Update unit morale
	unit["morale"] = result.current_morale

	# Determine state and retreat decision
	result.update_state_from_morale()

	# Calculate rally chance if retreating
	if result.will_retreat:
		result.rally_chance = calculate_rally_chance(unit)

	return result


## Calculates morale damage based on trigger and context
##
## @param unit: Unit receiving morale damage
## @param trigger: Reason for morale loss
## @param context: Additional context {leader_present: bool, etc.}
## @return: Integer morale damage (0-50)
static func calculate_morale_damage(
	unit: Dictionary,
	trigger: String,
	context: Dictionary
) -> int:
	# Base morale damage
	var base_damage: int = MORALE_DAMAGE.get(trigger, 10)

	# Apply modifiers
	var damage_modifier: float = 1.0

	# Experience reduces morale damage
	var experience: int = unit.get("experience", 0)
	if experience >= 500:
		damage_modifier *= 0.5  # Legendary: -50% morale damage
	elif experience >= 250:
		damage_modifier *= 0.7  # Elite: -30% morale damage
	elif experience >= 100:
		damage_modifier *= 0.85 # Veteran: -15% morale damage

	# Leadership reduces morale damage
	var leader_present: bool = context.get("leader_present", false)
	if leader_present:
		damage_modifier *= 0.7  # -30% morale damage with leader

	# Cultural modifiers
	var culture: String = unit.get("culture", "")
	match culture:
		"military_dictatorship":
			damage_modifier *= 0.9  # -10% morale damage
		"democratic":
			damage_modifier *= 1.1  # +10% morale damage (civilians less hardened)
		"raider":
			damage_modifier *= 0.8  # -20% morale damage (brutal and fearless)
		_:
			pass

	var final_damage: int = int(base_damage * damage_modifier)
	return clamp(final_damage, 0, 50)


## Handles unit retreat, finding safe direction and moving unit
##
## Retreat Logic:
## 1. Find direction toward nearest friendly territory
## 2. Move up to half movement speed
## 3. Take opportunity attacks from adjacent enemies
## 4. If no escape route, unit surrenders/destroyed
##
## @param unit: Unit that is retreating
## @param current_location: Current position
## @param friendly_positions: Array of friendly territory positions (optional)
## @return: New position after retreat (or current position if trapped)
static func process_retreat(
	unit: Dictionary,
	current_location: Vector3i,
	friendly_positions: Array = []
) -> Vector3i:
	if not unit:
		return current_location

	# Get unit movement capability
	var stats = unit.get("stats", {})
	var movement: int = stats.get("movement", 3)
	var retreat_distance: int = max(1, movement / 2)  # Half movement for retreat

	# Find retreat direction
	var retreat_direction: Vector3i = find_retreat_direction(current_location, friendly_positions)

	# Calculate new position
	var new_position: Vector3i = current_location + (retreat_direction * retreat_distance)

	# Update unit position
	unit["position"] = new_position

	# Apply retreat damage (represents opportunity attacks)
	apply_retreat_damage(unit)

	return new_position


## Finds the best direction to retreat
##
## @param current_location: Current position
## @param friendly_positions: Array of friendly positions
## @return: Direction vector (normalized)
static func find_retreat_direction(
	current_location: Vector3i,
	friendly_positions: Array
) -> Vector3i:
	if friendly_positions.is_empty():
		# No friendly positions known, retreat in random direction away from combat
		var directions = [
			Vector3i(-1, 0, 0),
			Vector3i(1, 0, 0),
			Vector3i(0, -1, 0),
			Vector3i(0, 1, 0)
		]
		return directions[randi() % directions.size()]

	# Find nearest friendly position
	var nearest_distance: float = INF
	var nearest_direction: Vector3i = Vector3i.ZERO

	for pos in friendly_positions:
		if not pos is Vector3i:
			continue

		var distance: float = current_location.distance_to(pos)
		if distance < nearest_distance:
			nearest_distance = distance
			var direction = pos - current_location
			# Normalize to unit vector (approximately)
			if abs(direction.x) > abs(direction.y):
				nearest_direction = Vector3i(sign(direction.x), 0, 0)
			else:
				nearest_direction = Vector3i(0, sign(direction.y), 0)

	return nearest_direction if nearest_direction != Vector3i.ZERO else Vector3i(-1, 0, 0)


## Applies damage during retreat (opportunity attacks)
##
## @param unit: Retreating unit
static func apply_retreat_damage(unit: Dictionary) -> void:
	if not unit:
		return

	var stats = unit.get("stats", {})
	var max_hp: int = stats.get("hp", 100)
	var current_hp: int = unit.get("current_hp", max_hp)

	# Retreat damage is 10-20% of max HP
	var retreat_damage: int = int(max_hp * randf_range(0.1, 0.2))

	current_hp -= retreat_damage
	unit["current_hp"] = max(current_hp, 0)


## Calculates rally chance for a retreating unit
##
## @param unit: Unit attempting to rally
## @return: Rally chance (0.0 - 1.0)
static func calculate_rally_chance(unit: Dictionary) -> float:
	if not unit:
		return 0.0

	var base_chance: float = BASE_RALLY_CHANCE

	# Higher morale increases rally chance
	var morale: int = unit.get("morale", 50)
	var morale_modifier: float = morale / 100.0

	# Experience increases rally chance
	var experience: int = unit.get("experience", 0)
	var experience_modifier: float = 1.0
	if experience >= 500:
		experience_modifier = 1.5  # Legendary
	elif experience >= 250:
		experience_modifier = 1.3  # Elite
	elif experience >= 100:
		experience_modifier = 1.15 # Veteran

	var final_chance: float = base_chance * morale_modifier * experience_modifier
	return clamp(final_chance, 0.0, 0.8)  # Max 80% rally chance


## Attempts to rally a retreating unit
##
## @param unit: Unit attempting to rally
## @return: True if rally successful
static func attempt_rally(unit: Dictionary) -> bool:
	if not unit:
		return false

	var rally_chance: float = calculate_rally_chance(unit)
	var roll: float = randf()

	if roll < rally_chance:
		# Rally successful
		restore_morale(unit, MORALE_RESTORATION["rally"], "rally")
		return true

	return false


## Restores morale to a unit
##
## @param unit: Unit to restore morale
## @param amount: Morale to restore
## @param reason: Source of morale restoration
static func restore_morale(
	unit: Dictionary,
	amount: int,
	reason: String = "rest"
) -> void:
	if not unit:
		return

	var current_morale: int = unit.get("morale", 50)
	var new_morale: int = clamp(current_morale + amount, 0, 100)
	unit["morale"] = new_morale


## Checks if multiple units in a group should trigger mass retreat
##
## @param units: Array of units in the group
## @param casualties: Number of recent casualties
## @return: True if group morale is broken
static func check_mass_morale_break(units: Array, casualties: int) -> bool:
	if units.is_empty():
		return false

	# Mass retreat if 50%+ casualties
	if casualties >= units.size() * 0.5:
		return true

	# Check average morale
	var total_morale: int = 0
	for unit in units:
		if unit is Dictionary:
			total_morale += unit.get("morale", 50)

	var average_morale: int = total_morale / units.size()

	# Mass retreat if average morale below 20
	return average_morale < 20


## Applies morale effects to all units in a group
##
## @param units: Array of units
## @param trigger: Morale trigger
## @param context: Optional context
## @return: Array of MoraleCheckResults
static func apply_group_morale_check(
	units: Array,
	trigger: String,
	context: Dictionary = {}
) -> Array:
	var results: Array = []

	for unit in units:
		if not unit is Dictionary:
			continue

		var result = apply_morale_check(unit, trigger)
		results.append(result)

	return results


## Gets morale state description for UI
##
## @param morale: Morale value (0-100)
## @return: String description
static func get_morale_description(morale: int) -> String:
	if morale >= 80:
		return "High Morale"
	elif morale >= 60:
		return "Good Morale"
	elif morale >= 40:
		return "Steady"
	elif morale >= 20:
		return "Shaken"
	else:
		return "Broken"


## Gets morale color for UI representation
##
## @param morale: Morale value (0-100)
## @return: Color
static func get_morale_color(morale: int) -> Color:
	if morale >= 80:
		return Color.GREEN
	elif morale >= 60:
		return Color(0.5, 1.0, 0.5)  # Light green
	elif morale >= 40:
		return Color.YELLOW
	elif morale >= 20:
		return Color.ORANGE
	else:
		return Color.RED
