extends Node
class_name EventTriggerEvaluator

## Event Trigger Evaluation System
## Evaluates conditions to determine if events should fire

const RARITY_CHANCES := {
	"common": 0.60,
	"uncommon": 0.25,
	"rare": 0.12,
	"epic": 0.03,
	"unique": 0.01
}

## Evaluate if event should trigger
## @param event_def: Event definition to check
## @param faction_id: Faction to check for
## @param game_state: Current game state
## @returns: bool - true if should trigger
func evaluate_triggers(event_def: EventDefinition, faction_id: int, game_state) -> bool:
	# If no triggers, event can always fire (subject to rarity)
	if event_def.triggers.is_empty():
		return roll_rarity(event_def.rarity)

	# Check if any trigger condition set is met
	for trigger in event_def.triggers:
		if _evaluate_single_trigger(trigger, faction_id, game_state):
			# Trigger conditions met, now check rarity
			if roll_rarity(event_def.rarity):
				# Rarity check passed, now check trigger chance
				if randf() <= trigger.chance:
					return true

	return false

## Evaluate a single trigger
func _evaluate_single_trigger(trigger: EventTrigger, faction_id: int, game_state) -> bool:
	# All conditions in a trigger must be met
	for condition in trigger.conditions:
		if not check_requirement(condition, faction_id, game_state):
			return false
	return true

## Check if requirement is met
## @param requirement: Requirement to check
## @param faction_id: Faction to check for
## @param game_state: Current game state
## @returns: bool - true if requirement met
func check_requirement(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	if game_state == null:
		push_warning("EventTriggerEvaluator: game_state is null")
		return false

	match requirement.type:
		EventRequirement.RequirementType.RESOURCE:
			return _check_resource_requirement(requirement, faction_id, game_state)

		EventRequirement.RequirementType.CULTURE_NODE:
			return _check_culture_requirement(requirement, faction_id, game_state)

		EventRequirement.RequirementType.BUILDING:
			return _check_building_requirement(requirement, faction_id, game_state)

		EventRequirement.RequirementType.UNIT_TYPE:
			return _check_unit_requirement(requirement, faction_id, game_state)

		EventRequirement.RequirementType.TERRITORY_SIZE:
			return _check_territory_requirement(requirement, faction_id, game_state)

		EventRequirement.RequirementType.TURN_NUMBER:
			return _check_turn_requirement(requirement, game_state)

		EventRequirement.RequirementType.CUSTOM_FLAG:
			return _check_custom_flag(requirement, faction_id, game_state)

		_:
			push_warning("EventTriggerEvaluator: Unknown requirement type: %s" % requirement.type)
			return false

## Check resource requirement
func _check_resource_requirement(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return false

	var resource_amount = 0
	if "resources" in faction:
		var resources = faction["resources"] if typeof(faction["resources"]) == TYPE_DICTIONARY else faction.resources
		if requirement.parameter in resources:
			resource_amount = resources[requirement.parameter]

	return _compare_values(resource_amount, requirement.value, requirement.comparison)

## Check culture node requirement
func _check_culture_requirement(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return false

	if "culture_nodes" in faction:
		var culture_nodes = faction["culture_nodes"] if typeof(faction["culture_nodes"]) == TYPE_ARRAY else faction.culture_nodes
		return requirement.parameter in culture_nodes

	return false

## Check building requirement
func _check_building_requirement(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return false

	if "buildings" in faction:
		var buildings = faction["buildings"] if typeof(faction["buildings"]) == TYPE_ARRAY else faction.buildings
		var count = 0
		for building in buildings:
			var building_type = building["type"] if typeof(building) == TYPE_DICTIONARY else building.type
			if building_type == requirement.parameter:
				count += 1
		return _compare_values(count, requirement.value, requirement.comparison)

	return false

## Check unit type requirement
func _check_unit_requirement(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return false

	if "units" in faction:
		var units = faction["units"] if typeof(faction["units"]) == TYPE_ARRAY else faction.units
		var count = 0
		for unit in units:
			var unit_type = unit["type"] if typeof(unit) == TYPE_DICTIONARY else unit.type
			if unit_type == requirement.parameter:
				count += 1
		return _compare_values(count, requirement.value, requirement.comparison)

	return false

## Check territory size requirement
func _check_territory_requirement(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return false

	var territory_size = 0
	if "territory_size" in faction:
		territory_size = faction["territory_size"] if typeof(faction["territory_size"]) == TYPE_INT else faction.territory_size
	elif "controlled_tiles" in faction:
		var tiles = faction["controlled_tiles"] if typeof(faction["controlled_tiles"]) == TYPE_ARRAY else faction.controlled_tiles
		territory_size = tiles.size()

	return _compare_values(territory_size, requirement.value, requirement.comparison)

## Check turn number requirement
func _check_turn_requirement(requirement: EventRequirement, game_state) -> bool:
	var current_turn = 0
	if "current_turn" in game_state:
		current_turn = game_state["current_turn"] if typeof(game_state["current_turn"]) == TYPE_INT else game_state.current_turn
	elif "turn_number" in game_state:
		current_turn = game_state["turn_number"] if typeof(game_state["turn_number"]) == TYPE_INT else game_state.turn_number

	return _compare_values(current_turn, requirement.value, requirement.comparison)

## Check custom flag requirement
func _check_custom_flag(requirement: EventRequirement, faction_id: int, game_state) -> bool:
	var faction = _get_faction(faction_id, game_state)
	if faction == null:
		return false

	# Check faction-specific flags
	if "flags" in faction:
		var flags = faction["flags"] if typeof(faction["flags"]) == TYPE_DICTIONARY else faction.flags
		if requirement.parameter in flags:
			return _compare_values(flags[requirement.parameter], requirement.value, requirement.comparison)

	# Check for special flags
	match requirement.parameter:
		"at_war":
			if "at_war" in faction:
				var at_war = faction["at_war"] if typeof(faction["at_war"]) == TYPE_BOOL else faction.at_war
				return at_war == requirement.value
		"has_trade_routes":
			if "has_trade_routes" in faction:
				var has_routes = faction["has_trade_routes"] if typeof(faction["has_trade_routes"]) == TYPE_BOOL else faction.has_trade_routes
				return has_routes == requirement.value
		"settlement_count_min":
			if "settlement_count" in faction:
				var count = faction["settlement_count"] if typeof(faction["settlement_count"]) == TYPE_INT else faction.settlement_count
				return count >= requirement.value
		"location_type":
			# This would require checking the faction's current location context
			# For now, return true if the game state has this info
			if "current_location_type" in faction:
				var loc_type = faction["current_location_type"]
				return loc_type == requirement.value

	return false

## Get faction from game state
func _get_faction(faction_id: int, game_state):
	if "factions" in game_state:
		var factions = game_state["factions"] if typeof(game_state["factions"]) == TYPE_ARRAY else game_state.factions
		if faction_id >= 0 and faction_id < factions.size():
			return factions[faction_id]
	return null

## Compare values based on comparison operator
func _compare_values(actual: Variant, expected: Variant, comparison: String) -> bool:
	match comparison:
		">=":
			return actual >= expected
		"<=":
			return actual <= expected
		">":
			return actual > expected
		"<":
			return actual < expected
		"==":
			return actual == expected
		"!=":
			return actual != expected
		_:
			push_warning("EventTriggerEvaluator: Unknown comparison operator: %s" % comparison)
			return false

## Evaluate rarity roll
## @param rarity: Rarity string (common, uncommon, rare, epic, unique)
## @returns: bool - true if rarity check passed
func roll_rarity(rarity: String) -> bool:
	var chance = RARITY_CHANCES.get(rarity.to_lower(), 0.60)
	return randf() <= chance
