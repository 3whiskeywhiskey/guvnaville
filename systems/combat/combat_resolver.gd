class_name CombatResolver
extends Node

# Preload dependencies for Godot 4.5.1 compatibility
const CombatResult = preload("res://systems/combat/combat_result.gd")
const CombatCalculator = preload("res://systems/combat/combat_calculator.gd")
const MoraleSystem = preload("res://systems/combat/morale_system.gd")
const LootCalculator = preload("res://systems/combat/loot_calculator.gd")

## Main combat resolution interface for auto-resolve and tactical combat initiation
##
## This singleton orchestrates all combat resolution including auto-resolve calculations,
## casualty application, morale checks, loot distribution, and experience awards.

## Singleton instance
static var instance: CombatResolver = null


func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()


## Performs auto-resolve combat calculation and returns the complete result
##
## @param attackers: Array of attacking units (Dictionary)
## @param defenders: Array of defending units (Dictionary)
## @param location: Tile position where combat occurs
## @param terrain: Tile data for terrain modifiers (Dictionary)
## @return: CombatResult with complete battle outcome
static func resolve_combat(
	attackers: Array,
	defenders: Array,
	location: Vector3i,
	terrain: Dictionary = {}
) -> CombatResult:
	var result = CombatResult.new()
	result.location = location

	# Track combat start time
	var start_time: float = Time.get_ticks_msec() / 1000.0

	# Emit combat started event (stub - EventBus not implemented yet)
	# EventBus.emit_signal("combat_started", attackers, defenders, location)

	# Filter valid units
	var valid_attackers: Array = CombatCalculator.filter_valid_units(attackers)
	var valid_defenders: Array = CombatCalculator.filter_valid_units(defenders)

	# Handle edge cases
	if valid_attackers.is_empty() and valid_defenders.is_empty():
		push_warning("CombatResolver: Both sides have no valid units")
		result.outcome = CombatResult.CombatOutcome.STALEMATE
		result.duration = 0.0
		return result

	if valid_attackers.is_empty():
		push_warning("CombatResolver: Attackers have no valid units - defender wins by default")
		result.outcome = CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY
		result.defender_survivors = valid_defenders.duplicate()
		result.duration = 0.0
		return result

	if valid_defenders.is_empty():
		push_warning("CombatResolver: Defenders have no valid units - attacker wins by default")
		result.outcome = CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
		result.attacker_survivors = valid_attackers.duplicate()
		result.duration = 0.0
		return result

	# Calculate combat strength for each side
	result.attacker_strength = CombatCalculator.calculate_combat_strength(valid_attackers, terrain, true)
	result.defender_strength = CombatCalculator.calculate_combat_strength(valid_defenders, terrain, false)

	# Calculate strength ratio
	result.strength_ratio = result.attacker_strength / result.defender_strength if result.defender_strength > 0 else 999.0

	# Determine outcome based on strength ratio
	result.outcome = CombatCalculator.determine_outcome(result.attacker_strength, result.defender_strength)

	# Store terrain modifiers for result
	result.terrain_modifiers = {
		"terrain_type": terrain.get("terrain_type", "open"),
		"cover_type": terrain.get("cover_type", "none"),
		"has_fortification": terrain.get("has_fortification", false)
	}

	# Apply casualties based on outcome
	_apply_combat_casualties(result, valid_attackers, valid_defenders)

	# Apply morale checks to all units
	_apply_combat_morale(result, valid_attackers, valid_defenders)

	# Calculate loot (winner takes all)
	_calculate_combat_loot(result, valid_attackers, valid_defenders)

	# Distribute experience
	_distribute_combat_experience(result, valid_attackers, valid_defenders)

	# Calculate combat duration
	result.duration = (Time.get_ticks_msec() / 1000.0) - start_time

	# Emit combat resolved event (stub)
	# EventBus.emit_signal("combat_resolved", result)

	return result


## Applies casualties to both sides based on combat outcome
static func _apply_combat_casualties(
	result: CombatResult,
	attackers: Array,
	defenders: Array
) -> void:
	# Determine who won
	var attacker_won: bool = result.outcome in [
		CombatResult.CombatOutcome.ATTACKER_VICTORY,
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
	]
	var defender_won: bool = result.outcome in [
		CombatResult.CombatOutcome.DEFENDER_VICTORY,
		CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY
	]

	# Get casualty percentages
	var attacker_casualty_rate: float = CombatCalculator.get_casualty_percentage(
		result.outcome,
		attacker_won
	)
	var defender_casualty_rate: float = CombatCalculator.get_casualty_percentage(
		result.outcome,
		defender_won
	)

	# Apply casualties
	result.attacker_casualties = CombatCalculator.apply_casualties(
		attackers,
		attacker_casualty_rate,
		result.outcome
	)
	result.defender_casualties = CombatCalculator.apply_casualties(
		defenders,
		defender_casualty_rate,
		result.outcome
	)

	# Determine survivors
	for unit in attackers:
		if unit is Dictionary and not result.attacker_casualties.has(unit):
			result.attacker_survivors.append(unit)

	for unit in defenders:
		if unit is Dictionary and not result.defender_casualties.has(unit):
			result.defender_survivors.append(unit)


## Applies morale checks to units after combat
static func _apply_combat_morale(
	result: CombatResult,
	attackers: Array,
	defenders: Array
) -> void:
	# Determine combat result for morale purposes
	var attacker_won: bool = result.outcome in [
		CombatResult.CombatOutcome.ATTACKER_VICTORY,
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
	]
	var defender_won: bool = result.outcome in [
		CombatResult.CombatOutcome.DEFENDER_VICTORY,
		CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY
	]

	var total_attacker_morale_loss: int = 0
	var total_defender_morale_loss: int = 0

	# Apply morale checks to attackers
	for unit in attackers:
		if not unit is Dictionary:
			continue

		var trigger: String = "combat_victory" if attacker_won else "combat_loss"
		var morale_result = MoraleSystem.apply_morale_check(unit, trigger)

		if not attacker_won:
			total_attacker_morale_loss += abs(morale_result.morale_change)

		# Track retreating units
		if morale_result.will_retreat:
			result.retreated_units.append(unit)

	# Apply morale checks to defenders
	for unit in defenders:
		if not unit is Dictionary:
			continue

		var trigger: String = "combat_victory" if defender_won else "combat_loss"
		var morale_result = MoraleSystem.apply_morale_check(unit, trigger)

		if not defender_won:
			total_defender_morale_loss += abs(morale_result.morale_change)

		# Track retreating units
		if morale_result.will_retreat:
			result.retreated_units.append(unit)

	result.attacker_morale_loss = total_attacker_morale_loss
	result.defender_morale_loss = total_defender_morale_loss


## Calculates and assigns loot to winner
static func _calculate_combat_loot(
	result: CombatResult,
	attackers: Array,
	defenders: Array
) -> void:
	# Determine winner
	var attacker_won: bool = result.outcome in [
		CombatResult.CombatOutcome.ATTACKER_VICTORY,
		CombatResult.CombatOutcome.ATTACKER_DECISIVE_VICTORY
	]
	var defender_won: bool = result.outcome in [
		CombatResult.CombatOutcome.DEFENDER_VICTORY,
		CombatResult.CombatOutcome.DEFENDER_DECISIVE_VICTORY
	]

	if not attacker_won and not defender_won:
		# Stalemate - no loot
		return

	# Calculate loot
	if attacker_won:
		result.loot = LootCalculator.calculate_loot(
			result.defender_casualties,
			0,  # Faction ID (stub for MVP)
			result.attacker_survivors
		)
	else:
		result.loot = LootCalculator.calculate_loot(
			result.attacker_casualties,
			0,  # Faction ID (stub for MVP)
			result.defender_survivors
		)


## Distributes experience to all participating units
static func _distribute_combat_experience(
	result: CombatResult,
	attackers: Array,
	defenders: Array
) -> void:
	# Combine all units
	var all_units: Array = []
	all_units.append_array(attackers)
	all_units.append_array(defenders)

	# Distribute experience
	result.experience_gained = LootCalculator.distribute_experience(all_units, result)


## Calculates combat outcome WITHOUT applying changes (for UI predictions)
##
## @param attackers: Array of attacking units
## @param defenders: Array of defending units
## @param location: Tile position
## @param terrain: Terrain data (optional)
## @return: CombatResult with predicted outcome (units not modified)
static func predict_combat_outcome(
	attackers: Array,
	defenders: Array,
	location: Vector3i,
	terrain: Dictionary = {}
) -> CombatResult:
	# Create deep copies of units to avoid modifying originals
	var attacker_copies: Array = _deep_copy_units(attackers)
	var defender_copies: Array = _deep_copy_units(defenders)

	# Run combat resolution on copies
	var result = resolve_combat(attacker_copies, defender_copies, location, terrain)

	return result


## Deep copies an array of unit dictionaries
static func _deep_copy_units(units: Array) -> Array:
	var copies: Array = []
	for unit in units:
		if unit is Dictionary:
			copies.append(unit.duplicate(true))
	return copies


## Initiates tactical combat mode (stub for MVP - calls auto-resolve)
##
## @param attackers: Array of attacking units
## @param defenders: Array of defending units
## @param location: Center position for tactical map
## @param map_subset: 20x20 tile subset for tactical battle (unused in MVP)
static func initiate_tactical_combat(
	attackers: Array,
	defenders: Array,
	location: Vector3i,
	map_subset: Array = []
) -> void:
	# Generate battle ID
	var battle_id: String = "battle_%d_%d_%d_%d" % [
		location.x, location.y, location.z, Time.get_ticks_msec()
	]

	# Emit tactical combat started event (stub)
	# EventBus.emit_signal("tactical_combat_started", battle_id, attackers, defenders)

	push_warning("CombatResolver: Tactical combat not implemented - using auto-resolve")

	# For MVP, immediately call auto-resolve
	var terrain: Dictionary = {}  # Should get from map_subset in full implementation
	var result = resolve_combat(attackers, defenders, location, terrain)

	# Emit tactical combat ended event (stub)
	# EventBus.emit_signal("tactical_combat_ended", battle_id, result)


## Validates combat parameters
##
## @param attackers: Attacker units
## @param defenders: Defender units
## @param location: Combat location
## @return: True if valid
static func validate_combat_parameters(
	attackers: Array,
	defenders: Array,
	location: Vector3i
) -> bool:
	if attackers.is_empty():
		push_error("CombatResolver: No attackers provided")
		return false

	if defenders.is_empty():
		push_error("CombatResolver: No defenders provided")
		return false

	# Location validation (basic check)
	if location.x < 0 or location.y < 0:
		push_warning("CombatResolver: Invalid location coordinates")

	return true


## Gets combat summary string for logging/debugging
##
## @param result: Combat result
## @return: Human-readable summary
static func get_combat_summary(result: CombatResult) -> String:
	var outcome_name: String = CombatResult.CombatOutcome.keys()[result.outcome]
	var summary: String = "Combat at (%d, %d, %d): %s\n" % [
		result.location.x, result.location.y, result.location.z, outcome_name
	]
	summary += "Attacker Strength: %.1f vs Defender Strength: %.1f (Ratio: %.2f)\n" % [
		result.attacker_strength, result.defender_strength, result.strength_ratio
	]
	summary += "Attacker: %d casualties, %d survivors\n" % [
		result.attacker_casualties.size(), result.attacker_survivors.size()
	]
	summary += "Defender: %d casualties, %d survivors\n" % [
		result.defender_casualties.size(), result.defender_survivors.size()
	]
	summary += "Loot: %d scrap, %d ammo, %d components\n" % [
		result.loot.get("scrap", 0), result.loot.get("ammunition", 0), result.loot.get("components", 0)
	]
	summary += "Duration: %.3f seconds" % result.duration

	return summary
