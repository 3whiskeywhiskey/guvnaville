extends Resource
class_name EventData

## Event system data structures
## This file contains all data classes used by the event system

## ============================================================================
## EventRequirement - Represents a condition that must be met
## ============================================================================
class_name EventRequirement
extends Resource

enum RequirementType {
	RESOURCE,           # Has X amount of resource
	CULTURE_NODE,       # Has unlocked culture node
	BUILDING,           # Owns building type
	UNIT_TYPE,          # Has unit type available
	TERRITORY_SIZE,     # Controls X tiles
	FACTION_RELATIONSHIP, # Relationship level with faction
	TURN_NUMBER,        # Game turn >= X
	EVENT_COMPLETED,    # Previous event completed
	CUSTOM_FLAG         # Custom game flag set
}

var type: RequirementType
var parameter: String = ""      # Resource name, building ID, etc.
var value: Variant = null       # Required amount/value
var comparison: String = ">="   # >=, <=, ==, !=

func _init(p_type: RequirementType = RequirementType.RESOURCE, p_parameter: String = "", p_value: Variant = null, p_comparison: String = ">="):
	type = p_type
	parameter = p_parameter
	value = p_value
	comparison = p_comparison

func to_dict() -> Dictionary:
	return {
		"type": type,
		"parameter": parameter,
		"value": value,
		"comparison": comparison
	}

static func from_dict(data: Dictionary) -> EventRequirement:
	var req = EventRequirement.new()
	if data.has("type"):
		if typeof(data["type"]) == TYPE_STRING:
			req.type = RequirementType[data["type"]]
		else:
			req.type = data["type"]
	req.parameter = data.get("parameter", "")
	req.value = data.get("value", null)
	req.comparison = data.get("comparison", ">=")
	return req


## ============================================================================
## EventConsequence - Represents an effect applied when a choice is made
## ============================================================================
class_name EventConsequence
extends Resource

enum ConsequenceType {
	RESOURCE_CHANGE,    # Add/remove resources
	SPAWN_UNIT,         # Create unit at location
	DESTROY_UNIT,       # Remove unit
	ADD_BUILDING,       # Construct building
	DAMAGE_BUILDING,    # Damage/destroy building
	CULTURE_POINTS,     # Add culture points
	MORALE_CHANGE,      # Change faction morale
	RELATIONSHIP_CHANGE, # Change diplomacy
	QUEUE_EVENT,        # Add another event to queue
	SET_FLAG,           # Set custom game flag
	GRANT_ABILITY,      # Unlock special ability
	MODIFY_STAT         # Modify unit/building stats
}

var type: ConsequenceType
var target: String = ""         # What this affects
var value: Variant = null       # Amount/data
var duration: int = -1          # -1 = permanent, else turn count
var description: String = ""    # Human-readable description

func _init(p_type: ConsequenceType = ConsequenceType.RESOURCE_CHANGE, p_target: String = "", p_value: Variant = null, p_description: String = ""):
	type = p_type
	target = p_target
	value = p_value
	description = p_description
	duration = -1

func to_dict() -> Dictionary:
	return {
		"type": type,
		"target": target,
		"value": value,
		"duration": duration,
		"description": description
	}

static func from_dict(data: Dictionary) -> EventConsequence:
	var cons = EventConsequence.new()
	if data.has("type"):
		if typeof(data["type"]) == TYPE_STRING:
			cons.type = ConsequenceType[data["type"]]
		else:
			cons.type = data["type"]
	cons.target = data.get("target", "")
	cons.value = data.get("value", null)
	cons.duration = data.get("duration", -1)
	cons.description = data.get("description", "")
	return cons


## ============================================================================
## EventChoice - Represents a player/AI choice in an event
## ============================================================================
class_name EventChoice
extends Resource

var text: String = ""                           # Choice display text
var choice_id: String = ""                      # Internal identifier
var requirements: Array[EventRequirement] = []  # Requirements to enable
var is_available: bool = true                   # Calculated availability
var unavailable_reason: String = ""             # Why unavailable
var outcomes: Array[EventConsequence] = []      # Consequences
var probabilistic: bool = false                 # Multiple outcomes?
var probability_weights: Array[float] = []      # Weights if probabilistic

func _init(p_choice_id: String = "", p_text: String = ""):
	choice_id = p_choice_id
	text = p_text
	is_available = true

func to_dict() -> Dictionary:
	var req_array = []
	for req in requirements:
		req_array.append(req.to_dict())

	var outcome_array = []
	for outcome in outcomes:
		outcome_array.append(outcome.to_dict())

	return {
		"choice_id": choice_id,
		"text": text,
		"requirements": req_array,
		"is_available": is_available,
		"unavailable_reason": unavailable_reason,
		"outcomes": outcome_array,
		"probabilistic": probabilistic,
		"probability_weights": probability_weights
	}

static func from_dict(data: Dictionary) -> EventChoice:
	var choice = EventChoice.new()
	choice.choice_id = data.get("id", data.get("choice_id", ""))
	choice.text = data.get("text", "")
	choice.probabilistic = data.get("probabilistic", false)
	choice.probability_weights = data.get("probability_weights", [])

	# Parse requirements
	if data.has("requirements"):
		var reqs = data["requirements"]
		if typeof(reqs) == TYPE_DICTIONARY:
			# Old format from JSON
			if reqs.has("culture_nodes"):
				for node in reqs["culture_nodes"]:
					var req = EventRequirement.new(EventRequirement.RequirementType.CULTURE_NODE, node, true, "==")
					choice.requirements.append(req)
			if reqs.has("resources"):
				for resource_type in reqs["resources"]:
					var amount = reqs["resources"][resource_type]
					var req = EventRequirement.new(EventRequirement.RequirementType.RESOURCE, resource_type, amount, ">=")
					choice.requirements.append(req)
			if reqs.has("units"):
				for unit_type in reqs["units"]:
					var req = EventRequirement.new(EventRequirement.RequirementType.UNIT_TYPE, unit_type, 1, ">=")
					choice.requirements.append(req)
		elif typeof(reqs) == TYPE_ARRAY:
			for req_data in reqs:
				choice.requirements.append(EventRequirement.from_dict(req_data))

	# Parse outcomes/consequences
	if data.has("consequences"):
		var cons_data = data["consequences"]
		choice.outcomes = _parse_consequences(cons_data)
	elif data.has("outcomes"):
		if typeof(data["outcomes"]) == TYPE_ARRAY and data["outcomes"].size() > 0:
			if typeof(data["outcomes"][0]) == TYPE_ARRAY:
				# Probabilistic outcomes - multiple outcome sets
				# We'll handle this in the resolver, just store the first set for now
				choice.outcomes = _parse_consequences(data["outcomes"][0][0] if data["outcomes"].size() > 0 and data["outcomes"][0].size() > 0 else {})
			else:
				choice.outcomes = _parse_consequences(data["outcomes"])

	return choice

static func _parse_consequences(cons_data) -> Array[EventConsequence]:
	var result: Array[EventConsequence] = []

	if typeof(cons_data) == TYPE_DICTIONARY:
		# Parse from event JSON format
		if cons_data.has("resource_changes"):
			for resource_type in cons_data["resource_changes"]:
				var amount = cons_data["resource_changes"][resource_type]
				var cons = EventConsequence.new(
					EventConsequence.ConsequenceType.RESOURCE_CHANGE,
					resource_type,
					amount,
					"Gained %d %s" % [amount, resource_type] if amount > 0 else "Lost %d %s" % [-amount, resource_type]
				)
				result.append(cons)

		if cons_data.has("spawn_units"):
			for unit_data in cons_data["spawn_units"]:
				var cons = EventConsequence.new(
					EventConsequence.ConsequenceType.SPAWN_UNIT,
					unit_data["unit_type"],
					unit_data["count"],
					"Spawned %d %s" % [unit_data["count"], unit_data["unit_type"]]
				)
				result.append(cons)

		if cons_data.has("morale_change"):
			var cons = EventConsequence.new(
				EventConsequence.ConsequenceType.MORALE_CHANGE,
				"morale",
				cons_data["morale_change"],
				"Morale changed by %d" % cons_data["morale_change"]
			)
			result.append(cons)

		if cons_data.has("reputation_change"):
			var cons = EventConsequence.new(
				EventConsequence.ConsequenceType.RELATIONSHIP_CHANGE,
				"reputation",
				cons_data["reputation_change"],
				"Reputation changed by %d" % cons_data["reputation_change"]
			)
			result.append(cons)

		if cons_data.has("trigger_event"):
			var cons = EventConsequence.new(
				EventConsequence.ConsequenceType.QUEUE_EVENT,
				cons_data["trigger_event"],
				0,
				"Triggered follow-up event: %s" % cons_data["trigger_event"]
			)
			result.append(cons)

		if cons_data.has("unlock_building"):
			var cons = EventConsequence.new(
				EventConsequence.ConsequenceType.ADD_BUILDING,
				cons_data["unlock_building"],
				1,
				"Unlocked building: %s" % cons_data["unlock_building"]
			)
			result.append(cons)

		if cons_data.has("narrative_text"):
			# Store narrative text as a custom consequence
			var cons = EventConsequence.new(
				EventConsequence.ConsequenceType.SET_FLAG,
				"narrative",
				cons_data["narrative_text"],
				cons_data["narrative_text"]
			)
			result.append(cons)

	elif typeof(cons_data) == TYPE_ARRAY:
		for item in cons_data:
			result.append(EventConsequence.from_dict(item))

	return result


## ============================================================================
## EventTrigger - Represents conditions that cause an event to fire
## ============================================================================
class_name EventTrigger
extends Resource

enum TriggerType {
	TURN_NUMBER,        # Specific turn or turn range
	RESOURCE_THRESHOLD, # Resource amount crosses threshold
	TERRITORY_SIZE,     # Controls X tiles
	CULTURE_UNLOCK,     # Unlocked culture node
	BUILDING_BUILT,     # Built specific building
	UNIT_LOST,          # Lost unit in combat
	LOCATION_CAPTURED,  # Captured unique location
	RELATIONSHIP_LEVEL, # Diplomacy level reached
	RANDOM_CHANCE,      # Pure RNG each turn
	EVENT_CHAIN         # Previous event triggered
}

var type: TriggerType
var conditions: Array[EventRequirement] = []
var chance: float = 1.0         # 0.0-1.0 probability if conditions met

func _init(p_type: TriggerType = TriggerType.RANDOM_CHANCE, p_chance: float = 1.0):
	type = p_type
	chance = p_chance

func to_dict() -> Dictionary:
	var cond_array = []
	for cond in conditions:
		cond_array.append(cond.to_dict())

	return {
		"type": type,
		"conditions": cond_array,
		"chance": chance
	}

static func from_dict(data: Dictionary) -> EventTrigger:
	var trigger = EventTrigger.new()
	if data.has("type"):
		if typeof(data["type"]) == TYPE_STRING:
			trigger.type = TriggerType[data["type"]]
		else:
			trigger.type = data["type"]
	trigger.chance = data.get("chance", 1.0)

	if data.has("conditions") and typeof(data["conditions"]) == TYPE_ARRAY:
		for cond_data in data["conditions"]:
			trigger.conditions.append(EventRequirement.from_dict(cond_data))

	return trigger


## ============================================================================
## EventDefinition - Defines an event template from data
## ============================================================================
class_name EventDefinition
extends Resource

var event_id: String = ""
var title: String = ""
var description: String = ""
var category: String = "random"  # random, cultural, diplomatic, discovery, crisis, quest
var rarity: String = "common"    # common, uncommon, rare, epic, unique
var triggers: Array[EventTrigger] = []
var choices: Array[EventChoice] = []
var base_priority: int = 50
var repeatable: bool = false
var cooldown_turns: int = 0
var image_path: String = ""
var metadata: Dictionary = {}
var tags: Array = []

func _init(p_event_id: String = ""):
	event_id = p_event_id

func to_dict() -> Dictionary:
	var trigger_array = []
	for trigger in triggers:
		trigger_array.append(trigger.to_dict())

	var choice_array = []
	for choice in choices:
		choice_array.append(choice.to_dict())

	return {
		"event_id": event_id,
		"title": title,
		"description": description,
		"category": category,
		"rarity": rarity,
		"triggers": trigger_array,
		"choices": choice_array,
		"base_priority": base_priority,
		"repeatable": repeatable,
		"cooldown_turns": cooldown_turns,
		"image_path": image_path,
		"metadata": metadata,
		"tags": tags
	}

static func from_dict(data: Dictionary) -> EventDefinition:
	var event_def = EventDefinition.new()
	event_def.event_id = data.get("id", data.get("event_id", ""))
	event_def.title = data.get("name", data.get("title", ""))
	event_def.description = data.get("description", "")
	event_def.category = data.get("category", "random")
	event_def.rarity = data.get("rarity", "common")
	event_def.base_priority = data.get("base_priority", 50)
	event_def.repeatable = data.get("repeatable", true)
	event_def.cooldown_turns = data.get("cooldown_turns", 0)
	event_def.image_path = data.get("image_path", "")
	event_def.metadata = data.get("metadata", {})
	event_def.tags = data.get("tags", [])

	# Parse triggers
	if data.has("triggers"):
		var triggers_data = data["triggers"]
		if typeof(triggers_data) == TYPE_DICTIONARY:
			# Old format - convert to new format
			var trigger = EventTrigger.new(EventTrigger.TriggerType.RANDOM_CHANCE, 1.0)

			if triggers_data.has("turn_range"):
				var turn_range = triggers_data["turn_range"]
				var req = EventRequirement.new(
					EventRequirement.RequirementType.TURN_NUMBER,
					"turn",
					turn_range.get("min", 0),
					">="
				)
				trigger.conditions.append(req)

			if triggers_data.has("required_buildings"):
				for building in triggers_data["required_buildings"]:
					var req = EventRequirement.new(
						EventRequirement.RequirementType.BUILDING,
						building,
						1,
						">="
					)
					trigger.conditions.append(req)

			if triggers_data.has("required_culture_nodes"):
				for node in triggers_data["required_culture_nodes"]:
					var req = EventRequirement.new(
						EventRequirement.RequirementType.CULTURE_NODE,
						node,
						true,
						"=="
					)
					trigger.conditions.append(req)

			if triggers_data.has("resource_thresholds"):
				for resource_type in triggers_data["resource_thresholds"]:
					var amount = triggers_data["resource_thresholds"][resource_type]
					var param_name = resource_type.replace("_min", "").replace("_max", "")
					var req = EventRequirement.new(
						EventRequirement.RequirementType.RESOURCE,
						param_name,
						amount,
						">=" if resource_type.ends_with("_min") else "<="
					)
					trigger.conditions.append(req)

			if triggers_data.has("faction_state"):
				var faction_state = triggers_data["faction_state"]
				for key in faction_state:
					var req = EventRequirement.new(
						EventRequirement.RequirementType.CUSTOM_FLAG,
						key,
						faction_state[key],
						"=="
					)
					trigger.conditions.append(req)

			if triggers_data.has("location_type"):
				var req = EventRequirement.new(
					EventRequirement.RequirementType.CUSTOM_FLAG,
					"location_type",
					triggers_data["location_type"],
					"=="
				)
				trigger.conditions.append(req)

			event_def.triggers.append(trigger)
		elif typeof(triggers_data) == TYPE_ARRAY:
			for trigger_data in triggers_data:
				event_def.triggers.append(EventTrigger.from_dict(trigger_data))

	# Parse choices
	if data.has("choices"):
		for choice_data in data["choices"]:
			event_def.choices.append(EventChoice.from_dict(choice_data))

	return event_def


## ============================================================================
## EventInstance - Runtime instance of an event
## ============================================================================
class_name EventInstance
extends Resource

var id: int = -1
var event_id: String = ""
var faction_id: int = -1
var title: String = ""
var description: String = ""
var choices: Array[EventChoice] = []
var trigger_turn: int = -1
var queued_turn: int = -1
var priority: int = 0
var image_path: String = ""
var metadata: Dictionary = {}

func _init(p_id: int = -1, p_event_id: String = ""):
	id = p_id
	event_id = p_event_id

func to_dict() -> Dictionary:
	var choice_array = []
	for choice in choices:
		choice_array.append(choice.to_dict())

	return {
		"id": id,
		"event_id": event_id,
		"faction_id": faction_id,
		"title": title,
		"description": description,
		"choices": choice_array,
		"trigger_turn": trigger_turn,
		"queued_turn": queued_turn,
		"priority": priority,
		"image_path": image_path,
		"metadata": metadata
	}

static func from_dict(data: Dictionary) -> EventInstance:
	var instance = EventInstance.new()
	instance.id = data.get("id", -1)
	instance.event_id = data.get("event_id", "")
	instance.faction_id = data.get("faction_id", -1)
	instance.title = data.get("title", "")
	instance.description = data.get("description", "")
	instance.trigger_turn = data.get("trigger_turn", -1)
	instance.queued_turn = data.get("queued_turn", -1)
	instance.priority = data.get("priority", 0)
	instance.image_path = data.get("image_path", "")
	instance.metadata = data.get("metadata", {})

	if data.has("choices"):
		for choice_data in data["choices"]:
			instance.choices.append(EventChoice.from_dict(choice_data))

	return instance
