class_name CombatResult
extends Resource

## Represents the outcome of a resolved combat encounter
##
## This class stores all information about a combat resolution including
## casualties, survivors, loot, experience, and morale effects.

enum CombatOutcome {
	ATTACKER_DECISIVE_VICTORY,  ## Attacker wins decisively (1.5x+ strength)
	ATTACKER_VICTORY,           ## Attacker wins (1.0-1.5x strength)
	STALEMATE,                  ## No clear winner (0.9-1.1x ratio)
	DEFENDER_VICTORY,           ## Defender wins (1.0-1.5x strength)
	DEFENDER_DECISIVE_VICTORY,  ## Defender wins decisively (1.5x+ strength)
	RETREAT                     ## One side retreated before conclusion
}

## Combat outcome type
var outcome: CombatOutcome = CombatOutcome.STALEMATE

## Units destroyed/damaged on attacker side
var attacker_casualties: Array = []

## Units destroyed/damaged on defender side
var defender_casualties: Array = []

## Units that survived on attacker side
var attacker_survivors: Array = []

## Units that survived on defender side
var defender_survivors: Array = []

## Resources gained by winner
var loot: Dictionary = {}

## XP per unit {unit_id: int}
var experience_gained: Dictionary = {}

## Where combat occurred
var location: Vector3i = Vector3i.ZERO

## Combat duration in seconds
var duration: float = 0.0

## Calculated attacker strength
var attacker_strength: float = 0.0

## Calculated defender strength
var defender_strength: float = 0.0

## attacker_strength / defender_strength
var strength_ratio: float = 1.0

## Total morale damage to attackers
var attacker_morale_loss: int = 0

## Total morale damage to defenders
var defender_morale_loss: int = 0

## Units that retreated
var retreated_units: Array = []

## Applied terrain bonuses/penalties
var terrain_modifiers: Dictionary = {}


func _init():
	loot = {
		"scrap": 0,
		"food": 0,
		"medicine": 0,
		"ammunition": 0,
		"fuel": 0,
		"components": 0,
		"special_items": []
	}


## Creates a string representation of the combat result
func to_string() -> String:
	var outcome_str = CombatOutcome.keys()[outcome]
	return "CombatResult(outcome=%s, attacker_strength=%.1f, defender_strength=%.1f, ratio=%.2f)" % [
		outcome_str, attacker_strength, defender_strength, strength_ratio
	]


## Serializes combat result to dictionary for save/load
func to_dict() -> Dictionary:
	return {
		"outcome": outcome,
		"attacker_casualties": attacker_casualties.map(func(u): return u.id if u.has("id") else str(u)),
		"defender_casualties": defender_casualties.map(func(u): return u.id if u.has("id") else str(u)),
		"attacker_survivors": attacker_survivors.map(func(u): return u.id if u.has("id") else str(u)),
		"defender_survivors": defender_survivors.map(func(u): return u.id if u.has("id") else str(u)),
		"loot": loot,
		"experience_gained": experience_gained,
		"location": {"x": location.x, "y": location.y, "z": location.z},
		"duration": duration,
		"attacker_strength": attacker_strength,
		"defender_strength": defender_strength,
		"strength_ratio": strength_ratio,
		"attacker_morale_loss": attacker_morale_loss,
		"defender_morale_loss": defender_morale_loss,
		"terrain_modifiers": terrain_modifiers
	}
