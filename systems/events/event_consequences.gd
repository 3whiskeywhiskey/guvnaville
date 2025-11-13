extends Node
class_name EventConsequenceApplicator

## Event Consequence Application System
## Applies event consequences to game state

signal consequence_applied(consequence_type: String, target: String, value: Variant)

## Apply all consequences from a choice
## @param consequences: Array of consequences to apply
## @param faction_id: Target faction
## @param game_state: Current game state
## @returns: Dictionary describing what was applied
func apply_consequences(consequences: Array[EventConsequence], faction_id: int, game_state) -> Dictionary:
	var results = {
		"success": true,
		"applied": [],
		"failed": [],
		"narrative": ""
	}

	for consequence in consequences:
		var result = apply_consequence(consequence, faction_id, game_state)
		if result["success"]:
			results["applied"].append(result)
		else:
			results["failed"].append(result)
			results["success"] = false

		# Collect narrative text
		if result.has("narrative") and result["narrative"] != "":
			if results["narrative"] != "":
				results["narrative"] += "\n\n"
			results["narrative"] += result["narrative"]

	return results

## Apply single consequence
## @param consequence: Consequence to apply
## @param faction_id: Target faction
## @param game_state: Current game state
## @returns: Dictionary describing result
func apply_consequence(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var result = {
		"success": false,
		"type": consequence.type,
		"target": consequence.target,
		"value": consequence.value,
		"description": consequence.description,
		"narrative": ""
	}

	match consequence.type:
		EventConsequence.ConsequenceType.RESOURCE_CHANGE:
			result = _apply_resource_change(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.SPAWN_UNIT:
			result = _apply_spawn_unit(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.MORALE_CHANGE:
			result = _apply_morale_change(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.CULTURE_POINTS:
			result = _apply_culture_points(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.RELATIONSHIP_CHANGE:
			result = _apply_relationship_change(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.QUEUE_EVENT:
			result = _apply_queue_event(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.SET_FLAG:
			result = _apply_set_flag(consequence, faction_id, game_state)

		EventConsequence.ConsequenceType.ADD_BUILDING:
			result = _apply_add_building(consequence, faction_id, game_state)

		_:
			result["success"] = false
			result["description"] = "Unsupported consequence type: %s" % consequence.type
			push_warning("EventConsequenceApplicator: Unsupported consequence type: %s" % consequence.type)

	consequence_applied.emit(str(consequence.type), consequence.target, consequence.value)
	return result

## Apply resource change
func _apply_resource_change(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	var resource_type = consequence.target
	var amount = int(consequence.value) if typeof(consequence.value) == TYPE_INT or typeof(consequence.value) == TYPE_FLOAT else 0

	# Initialize resources if needed
	if not "resources" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["resources"] = {}
		else:
			faction.resources = {}

	var resources = faction["resources"] if typeof(faction) == TYPE_DICTIONARY else faction.resources

	# Initialize resource if not present
	if not resource_type in resources:
		resources[resource_type] = 0

	# Apply change
	var old_amount = resources[resource_type]
	resources[resource_type] = max(0, resources[resource_type] + amount)
	var actual_change = resources[resource_type] - old_amount

	var description = ""
	if amount > 0:
		description = "Gained %d %s" % [actual_change, resource_type]
	else:
		description = "Lost %d %s" % [-actual_change, resource_type]

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.RESOURCE_CHANGE,
		"target": resource_type,
		"value": actual_change,
		"old_value": old_amount,
		"new_value": resources[resource_type],
		"description": description,
		"narrative": consequence.description
	}

## Apply spawn unit
func _apply_spawn_unit(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	var unit_type = consequence.target
	var count = int(consequence.value) if typeof(consequence.value) == TYPE_INT else 1

	# Initialize units array if needed
	if not "units" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["units"] = []
		else:
			faction.units = []

	var units = faction["units"] if typeof(faction) == TYPE_DICTIONARY else faction.units

	# Add units
	for i in range(count):
		var unit = {"type": unit_type, "id": "unit_%d_%d" % [faction_id, units.size()]}
		units.append(unit)

	var description = "Spawned %d %s unit(s)" % [count, unit_type]

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.SPAWN_UNIT,
		"target": unit_type,
		"value": count,
		"description": description,
		"narrative": consequence.description
	}

## Apply morale change
func _apply_morale_change(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	var amount = int(consequence.value) if typeof(consequence.value) == TYPE_INT else 0

	# Initialize morale if needed
	if not "morale" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["morale"] = 50
		else:
			faction.morale = 50

	var old_morale = faction["morale"] if typeof(faction) == TYPE_DICTIONARY else faction.morale
	var new_morale = clamp(old_morale + amount, 0, 100)

	if typeof(faction) == TYPE_DICTIONARY:
		faction["morale"] = new_morale
	else:
		faction.morale = new_morale

	var description = "Morale changed by %d (now %d)" % [amount, new_morale]

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.MORALE_CHANGE,
		"target": "morale",
		"value": amount,
		"old_value": old_morale,
		"new_value": new_morale,
		"description": description,
		"narrative": consequence.description
	}

## Apply culture points
func _apply_culture_points(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	var amount = int(consequence.value) if typeof(consequence.value) == TYPE_INT else 0

	# Initialize culture points if needed
	if not "culture_points" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["culture_points"] = 0
		else:
			faction.culture_points = 0

	var old_points = faction["culture_points"] if typeof(faction) == TYPE_DICTIONARY else faction.culture_points
	var new_points = max(0, old_points + amount)

	if typeof(faction) == TYPE_DICTIONARY:
		faction["culture_points"] = new_points
	else:
		faction.culture_points = new_points

	var description = "Gained %d culture points" % amount

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.CULTURE_POINTS,
		"target": consequence.target,
		"value": amount,
		"old_value": old_points,
		"new_value": new_points,
		"description": description,
		"narrative": consequence.description
	}

## Apply relationship change
func _apply_relationship_change(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	var amount = int(consequence.value) if typeof(consequence.value) == TYPE_INT else 0

	# Initialize reputation if needed
	if not "reputation" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["reputation"] = 0
		else:
			faction.reputation = 0

	var old_rep = faction["reputation"] if typeof(faction) == TYPE_DICTIONARY else faction.reputation
	var new_rep = old_rep + amount

	if typeof(faction) == TYPE_DICTIONARY:
		faction["reputation"] = new_rep
	else:
		faction.reputation = new_rep

	var description = "Reputation changed by %d (now %d)" % [amount, new_rep]

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.RELATIONSHIP_CHANGE,
		"target": "reputation",
		"value": amount,
		"old_value": old_rep,
		"new_value": new_rep,
		"description": description,
		"narrative": consequence.description
	}

## Apply queue event (for event chains)
func _apply_queue_event(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	# Store the event to be queued in game state
	if not "queued_events" in game_state:
		if typeof(game_state) == TYPE_DICTIONARY:
			game_state["queued_events"] = []
		else:
			game_state.queued_events = []

	var queued_events = game_state["queued_events"] if typeof(game_state) == TYPE_DICTIONARY else game_state.queued_events

	var event_data = {
		"event_id": consequence.target,
		"faction_id": faction_id,
		"delay_turns": int(consequence.value) if typeof(consequence.value) == TYPE_INT else 0
	}
	queued_events.append(event_data)

	var description = "Queued event: %s" % consequence.target

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.QUEUE_EVENT,
		"target": consequence.target,
		"value": consequence.value,
		"description": description,
		"narrative": consequence.description
	}

## Apply set flag
func _apply_set_flag(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	# Initialize flags if needed
	if not "flags" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["flags"] = {}
		else:
			faction.flags = {}

	var flags = faction["flags"] if typeof(faction) == TYPE_DICTIONARY else faction.flags

	# Special handling for narrative text
	if consequence.target == "narrative":
		# This is narrative text, not a flag to set
		return {
			"success": true,
			"type": EventConsequence.ConsequenceType.SET_FLAG,
			"target": "narrative",
			"value": consequence.value,
			"description": "",
			"narrative": str(consequence.value)
		}

	# Set the flag
	flags[consequence.target] = consequence.value

	var description = "Set flag: %s = %s" % [consequence.target, consequence.value]

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.SET_FLAG,
		"target": consequence.target,
		"value": consequence.value,
		"description": description,
		"narrative": consequence.description
	}

## Apply add building
func _apply_add_building(consequence: EventConsequence, faction_id: int, game_state) -> Dictionary:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return {"success": false, "description": "Faction not found"}

	# Initialize buildings array if needed
	if not "buildings" in faction:
		if typeof(faction) == TYPE_DICTIONARY:
			faction["buildings"] = []
		else:
			faction.buildings = []

	var buildings = faction["buildings"] if typeof(faction) == TYPE_DICTIONARY else faction.buildings

	# Add building
	var building = {"type": consequence.target, "id": "building_%d_%d" % [faction_id, buildings.size()]}
	buildings.append(building)

	var description = "Unlocked building: %s" % consequence.target

	return {
		"success": true,
		"type": EventConsequence.ConsequenceType.ADD_BUILDING,
		"target": consequence.target,
		"value": consequence.value,
		"description": description,
		"narrative": consequence.description
	}

## Validate consequences can be applied
## @param consequences: Array of consequences
## @param faction_id: Target faction
## @param game_state: Current game state
## @returns: bool - true if all can be applied
func validate_consequences(consequences: Array[EventConsequence], faction_id: int, game_state) -> bool:
	# For now, all consequences can be applied
	# In a full implementation, we'd check if resources can be spent, etc.
	var faction = _get_faction(faction_id, game_state)
	return faction != null

## Get faction from game state
func _get_faction(faction_id: int, game_state):
	if game_state == null:
		return null

	if "factions" in game_state:
		var factions = game_state["factions"] if typeof(game_state["factions"]) == TYPE_ARRAY else game_state.factions
		if faction_id >= 0 and faction_id < factions.size():
			return factions[faction_id]

	return null
