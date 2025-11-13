class_name StatusEffect
extends Resource

## Status Effect - Represents buffs, debuffs, and temporary conditions
## Part of Workstream 2.3: Unit System

# Effect identification
var id: String = ""                      # Effect ID
var name: String = ""                    # Display name
var description: String = ""             # Effect description
var icon: Texture2D = null               # Status icon (optional)

# Duration
var duration: int = -1                   # Turns remaining (-1 = permanent)
var max_duration: int = -1               # Original duration

# Effect properties
var is_buff: bool = true                 # Buff (true) or debuff (false)?
var stacks: int = 1                      # Number of stacks (if stackable)
var max_stacks: int = 1                  # Maximum stacks allowed
var is_stackable: bool = false           # Can this effect stack?

# Stat modifiers (multipliers)
var stat_modifiers: Dictionary = {}      # Stat name -> multiplier
# Example: {"attack": 1.5, "defense": 0.8}

# Special flags
var immobilized: bool = false            # Unit cannot move
var silenced: bool = false               # Unit cannot use abilities
var stunned: bool = false                # Unit cannot act
var hidden: bool = false                 # Effect hidden from UI

## Initialize status effect
func _init():
	pass

## Apply effect to unit
func apply_to_unit(unit: Unit) -> void:
	if not unit:
		return

	# Check if effect already exists
	var existing_effect = _find_existing_effect(unit)

	if existing_effect:
		if is_stackable and existing_effect["stacks"] < max_stacks:
			# Stack the effect
			existing_effect["stacks"] += 1
			existing_effect["duration"] = duration  # Refresh duration
		else:
			# Replace with new effect (refresh duration)
			existing_effect["duration"] = duration
	else:
		# Add new effect
		var effect_data = to_dict()
		unit.status_effects.append(effect_data)

## Remove effect from unit
func remove_from_unit(unit: Unit) -> void:
	if not unit:
		return

	for i in range(unit.status_effects.size() - 1, -1, -1):
		var effect = unit.status_effects[i]
		if effect.get("id", "") == id:
			unit.status_effects.remove_at(i)
			break

## Tick effect (called each turn)
func tick() -> void:
	if duration > 0:
		duration -= 1

## Check if effect has expired
func is_expired() -> bool:
	return duration == 0

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"duration": duration,
		"max_duration": max_duration,
		"is_buff": is_buff,
		"stacks": stacks,
		"max_stacks": max_stacks,
		"is_stackable": is_stackable,
		"stat_modifiers": stat_modifiers.duplicate(),
		"immobilized": immobilized,
		"silenced": silenced,
		"stunned": stunned,
		"hidden": hidden
	}

## Deserialize from dictionary
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	duration = data.get("duration", -1)
	max_duration = data.get("max_duration", -1)
	is_buff = data.get("is_buff", true)
	stacks = data.get("stacks", 1)
	max_stacks = data.get("max_stacks", 1)
	is_stackable = data.get("is_stackable", false)
	stat_modifiers = data.get("stat_modifiers", {})
	immobilized = data.get("immobilized", false)
	silenced = data.get("silenced", false)
	stunned = data.get("stunned", false)
	hidden = data.get("hidden", false)

## Private helper methods

func _find_existing_effect(unit: Unit) -> Dictionary:
	for effect in unit.status_effects:
		if effect.get("id", "") == id:
			return effect
	return {}

## Static factory methods for common effects

static func create_buff(effect_id: String, effect_name: String, stat_mods: Dictionary, turns: int) -> StatusEffect:
	var effect = StatusEffect.new()
	effect.id = effect_id
	effect.name = effect_name
	effect.duration = turns
	effect.max_duration = turns
	effect.is_buff = true
	effect.stat_modifiers = stat_mods
	return effect

static func create_debuff(effect_id: String, effect_name: String, stat_mods: Dictionary, turns: int) -> StatusEffect:
	var effect = StatusEffect.new()
	effect.id = effect_id
	effect.name = effect_name
	effect.duration = turns
	effect.max_duration = turns
	effect.is_buff = false
	effect.stat_modifiers = stat_mods
	return effect

static func create_immobilize(effect_id: String, effect_name: String, turns: int) -> StatusEffect:
	var effect = StatusEffect.new()
	effect.id = effect_id
	effect.name = effect_name
	effect.duration = turns
	effect.max_duration = turns
	effect.is_buff = false
	effect.immobilized = true
	return effect

static func create_stun(effect_id: String, effect_name: String, turns: int) -> StatusEffect:
	var effect = StatusEffect.new()
	effect.id = effect_id
	effect.name = effect_name
	effect.duration = turns
	effect.max_duration = turns
	effect.is_buff = false
	effect.stunned = true
	effect.immobilized = true
	effect.silenced = true
	return effect
