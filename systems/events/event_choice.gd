extends Node
class_name EventChoiceResolver

## Event Choice Resolution System
## Validates choices and resolves probabilistic outcomes

var _trigger_evaluator: EventTriggerEvaluator

func _init():
	_trigger_evaluator = EventTriggerEvaluator.new()

## Validate if choice is available
## @param choice: Choice to validate
## @param faction_id: Faction making choice
## @param game_state: Current game state
## @returns: Dictionary with {available: bool, reason: String}
func validate_choice(choice: EventChoice, faction_id: int, game_state) -> Dictionary:
	if choice.requirements.is_empty():
		return {"available": true, "reason": ""}

	# Check all requirements
	for requirement in choice.requirements:
		if not _trigger_evaluator.check_requirement(requirement, faction_id, game_state):
			var reason = _get_requirement_failure_reason(requirement, faction_id, game_state)
			return {"available": false, "reason": reason}

	return {"available": true, "reason": ""}

## Get human-readable reason for requirement failure
func _get_requirement_failure_reason(requirement: EventRequirement, faction_id: int, game_state) -> String:
	match requirement.type:
		EventRequirement.RequirementType.RESOURCE:
			return "Requires %d %s" % [requirement.value, requirement.parameter]

		EventRequirement.RequirementType.CULTURE_NODE:
			return "Requires culture node: %s" % requirement.parameter

		EventRequirement.RequirementType.BUILDING:
			return "Requires building: %s" % requirement.parameter

		EventRequirement.RequirementType.UNIT_TYPE:
			return "Requires unit type: %s" % requirement.parameter

		EventRequirement.RequirementType.TERRITORY_SIZE:
			return "Requires %d controlled tiles" % requirement.value

		EventRequirement.RequirementType.TURN_NUMBER:
			return "Requires turn %d or later" % requirement.value

		EventRequirement.RequirementType.CUSTOM_FLAG:
			return "Requires: %s" % requirement.parameter

		_:
			return "Requirements not met"

## Resolve probabilistic outcomes
## @param choice: Choice with multiple outcomes
## @returns: Array[EventConsequence] - selected consequences
func resolve_probabilistic_choice(choice: EventChoice) -> Array[EventConsequence]:
	if not choice.probabilistic or choice.probability_weights.is_empty():
		# Not probabilistic, return all outcomes
		return choice.outcomes

	# Select outcome set based on weighted probabilities
	var total_weight = 0.0
	for weight in choice.probability_weights:
		total_weight += weight

	var roll = randf() * total_weight
	var cumulative = 0.0

	for i in range(choice.probability_weights.size()):
		cumulative += choice.probability_weights[i]
		if roll <= cumulative:
			# This outcome was selected
			# For now, return all outcomes (in a full implementation,
			# we'd have multiple outcome sets to choose from)
			return choice.outcomes

	# Fallback to first outcome
	return choice.outcomes

## Validate all choices for an event instance
## @param event_instance: Event instance to validate
## @param faction_id: Faction making choice
## @param game_state: Current game state
## @returns: void - updates choice availability in place
func validate_all_choices(event_instance: EventInstance, faction_id: int, game_state) -> void:
	for choice in event_instance.choices:
		var validation = validate_choice(choice, faction_id, game_state)
		choice.is_available = validation["available"]
		choice.unavailable_reason = validation["reason"]

## Get available choices for an event
## @param event_instance: Event instance to check
## @param faction_id: Faction making choice
## @param game_state: Current game state
## @returns: Array[EventChoice] - only available choices
func get_available_choices(event_instance: EventInstance, faction_id: int, game_state) -> Array[EventChoice]:
	validate_all_choices(event_instance, faction_id, game_state)

	var available: Array[EventChoice] = []
	for choice in event_instance.choices:
		if choice.is_available:
			available.append(choice)

	return available

## Select best choice for AI (simple heuristic)
## @param event_instance: Event instance
## @param faction_id: AI faction
## @param game_state: Current game state
## @returns: int - index of selected choice, or -1 if none available
func ai_select_choice(event_instance: EventInstance, faction_id: int, game_state) -> int:
	validate_all_choices(event_instance, faction_id, game_state)

	# Simple heuristic: prefer choices that give resources
	var best_choice_idx = -1
	var best_score = -999999.0

	for i in range(event_instance.choices.size()):
		var choice = event_instance.choices[i]
		if not choice.is_available:
			continue

		var score = _evaluate_choice_for_ai(choice, faction_id, game_state)
		if score > best_score:
			best_score = score
			best_choice_idx = i

	# If no good choice found, pick first available
	if best_choice_idx == -1:
		for i in range(event_instance.choices.size()):
			if event_instance.choices[i].is_available:
				return i

	return best_choice_idx

## Evaluate choice value for AI
func _evaluate_choice_for_ai(choice: EventChoice, faction_id: int, game_state) -> float:
	var score = 0.0

	for consequence in choice.outcomes:
		match consequence.type:
			EventConsequence.ConsequenceType.RESOURCE_CHANGE:
				# Positive resources = good
				if typeof(consequence.value) == TYPE_INT or typeof(consequence.value) == TYPE_FLOAT:
					score += float(consequence.value) * 1.0

			EventConsequence.ConsequenceType.SPAWN_UNIT:
				# Units are valuable
				if typeof(consequence.value) == TYPE_INT:
					score += float(consequence.value) * 20.0

			EventConsequence.ConsequenceType.MORALE_CHANGE:
				# Morale is important
				if typeof(consequence.value) == TYPE_INT:
					score += float(consequence.value) * 2.0

			EventConsequence.ConsequenceType.CULTURE_POINTS:
				# Culture is valuable
				if typeof(consequence.value) == TYPE_INT:
					score += float(consequence.value) * 1.5

			EventConsequence.ConsequenceType.RELATIONSHIP_CHANGE:
				# Reputation matters
				if typeof(consequence.value) == TYPE_INT:
					score += float(consequence.value) * 1.0

			_:
				# Other consequences have neutral value
				pass

	return score
