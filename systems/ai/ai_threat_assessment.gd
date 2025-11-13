## AIThreatAssessment - Internal threat tracking for AI decision-making
##
## Tracks the threat level of other factions, including military strength,
## economic power, proximity, and diplomatic relations. Used to inform
## AI strategic decisions.
##
## @contract: AI System Interface v1.0
## @agent: Agent 7

class_name AIThreatAssessment
extends RefCounted

## Diplomatic relationship types
enum Relationship {
	HOSTILE,     # Active conflict or very negative relations
	NEUTRAL,     # No strong relationship
	FRIENDLY,    # Positive relations, potential ally
	ALLY         # Formal alliance
}

## Faction being assessed
var faction_id: int

## Estimated military power (0-100)
var military_strength: float

## Estimated economic power (0-100)
var economic_strength: float

## Overall threat level (0-100)
var threat_level: float

## Distance in tiles to nearest border
var distance: int

## Diplomatic relationship status
var relationship: Relationship

## Recent hostile/friendly actions (for tracking behavior)
var recent_actions: Array[String]


## Constructor
func _init(p_faction_id: int) -> void:
	faction_id = p_faction_id
	military_strength = 50.0
	economic_strength = 50.0
	threat_level = 50.0
	distance = 999
	relationship = Relationship.NEUTRAL
	recent_actions = []


## Updates threat assessment based on game state
func update_assessment(
	new_military: float,
	new_economic: float,
	new_distance: int,
	new_relationship: Relationship
) -> void:
	military_strength = clampf(new_military, 0.0, 100.0)
	economic_strength = clampf(new_economic, 0.0, 100.0)
	distance = max(0, new_distance)
	relationship = new_relationship

	# Calculate overall threat level
	_recalculate_threat()


## Recalculates overall threat level based on factors
func _recalculate_threat() -> void:
	var threat: float = 0.0

	# Military strength is primary threat factor
	threat += military_strength * 0.5

	# Economic strength indicates future threat
	threat += economic_strength * 0.2

	# Proximity increases threat
	if distance < 10:
		threat += 30.0
	elif distance < 20:
		threat += 15.0
	elif distance < 50:
		threat += 5.0

	# Relationship modifier
	match relationship:
		Relationship.HOSTILE:
			threat *= 1.5
		Relationship.NEUTRAL:
			threat *= 1.0
		Relationship.FRIENDLY:
			threat *= 0.5
		Relationship.ALLY:
			threat *= 0.1

	threat_level = clampf(threat, 0.0, 100.0)


## Records a recent action by this faction
func record_action(action_description: String) -> void:
	recent_actions.append(action_description)

	# Keep only last 10 actions
	if recent_actions.size() > 10:
		recent_actions.pop_front()


## Returns true if this faction is considered a major threat
func is_major_threat() -> bool:
	return threat_level > 70.0


## Returns true if this faction is hostile or very threatening
func is_hostile() -> bool:
	return relationship == Relationship.HOSTILE or threat_level > 80.0


## Returns string representation for debugging
func to_string() -> String:
	var rel_name = Relationship.keys()[relationship]
	return "ThreatAssessment(faction=%d, threat=%.1f, military=%.1f, economic=%.1f, distance=%d, rel=%s)" % [
		faction_id, threat_level, military_strength, economic_strength, distance, rel_name
	]
