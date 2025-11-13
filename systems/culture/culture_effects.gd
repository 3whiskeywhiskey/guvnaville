class_name CultureEffects
extends RefCounted

## Culture effects calculation and application system
##
## Handles:
## - Aggregating effects from multiple unlocked nodes
## - Calculating synergy bonuses
## - Applying effect modifiers to base values
## - Extracting unlocked content (units, buildings, policies)

## Synergy definition structure
## Array of dictionaries with:
## - id: Unique synergy identifier
## - name: Display name
## - description: Effect description
## - required_nodes: Array of node IDs that must all be unlocked
## - effects: Dictionary of bonus effects
var synergy_definitions: Array[Dictionary] = []


## Set synergy definitions
## @param synergies: Array of synergy definition dictionaries
func set_synergy_definitions(synergies: Array[Dictionary]) -> void:
	synergy_definitions = synergies


## Calculate aggregated effects from all unlocked nodes
## @param nodes: Array of unlocked CultureNode objects
## @return: Dictionary of total effects with all bonuses summed
func calculate_total_effects(nodes: Array[CultureNode]) -> Dictionary:
	var total_effects: Dictionary = {}

	# Aggregate effects from all nodes
	for node in nodes:
		for effect_key in node.effects:
			# Skip special abilities array (handled separately)
			if effect_key == "special_abilities":
				continue

			var effect_value = node.get_effect_value(effect_key, 0.0)

			if total_effects.has(effect_key):
				total_effects[effect_key] += effect_value
			else:
				total_effects[effect_key] = effect_value

	# Collect all special abilities
	var all_abilities: Array[Dictionary] = []
	for node in nodes:
		if node.effects.has("special_abilities"):
			var abilities = node.effects["special_abilities"]
			if abilities is Array:
				for ability in abilities:
					if ability is Dictionary:
						all_abilities.append(ability)

	if not all_abilities.is_empty():
		total_effects["special_abilities"] = all_abilities

	return total_effects


## Calculate synergy bonuses based on unlocked nodes
## @param unlocked_nodes: Array of unlocked node IDs
## @param synergies: Array of synergy definition dictionaries (optional, uses stored if not provided)
## @return: Array of active synergy dictionaries with bonuses
func calculate_synergy_bonuses(
	unlocked_nodes: Array[String],
	synergies: Array[Dictionary] = []
) -> Array[Dictionary]:
	var active_synergies: Array[Dictionary] = []

	# Use provided synergies or fall back to stored definitions
	var synergies_to_check = synergies if not synergies.is_empty() else synergy_definitions

	for synergy in synergies_to_check:
		if not synergy.has("required_nodes") or not synergy.has("effects"):
			continue

		var required_nodes = synergy["required_nodes"]
		if not required_nodes is Array:
			continue

		# Check if all required nodes are unlocked
		var all_required_unlocked = true
		for required_id in required_nodes:
			if required_id not in unlocked_nodes:
				all_required_unlocked = false
				break

		# If synergy is active, add it to results
		if all_required_unlocked:
			active_synergies.append(synergy)

	return active_synergies


## Get aggregated effects including synergy bonuses
## @param nodes: Array of unlocked CultureNode objects
## @param unlocked_node_ids: Array of unlocked node IDs (for synergy calculation)
## @return: Dictionary with total effects including synergies
func calculate_total_effects_with_synergies(
	nodes: Array[CultureNode],
	unlocked_node_ids: Array[String]
) -> Dictionary:
	# Start with base effects
	var total_effects = calculate_total_effects(nodes)

	# Add synergy bonuses
	var active_synergies = calculate_synergy_bonuses(unlocked_node_ids)
	for synergy in active_synergies:
		if synergy.has("effects"):
			var synergy_effects = synergy["effects"]
			if synergy_effects is Dictionary:
				for effect_key in synergy_effects:
					if effect_key == "special_abilities":
						continue

					var bonus_value = synergy_effects[effect_key]
					if bonus_value is float or bonus_value is int:
						if total_effects.has(effect_key):
							total_effects[effect_key] += float(bonus_value)
						else:
							total_effects[effect_key] = float(bonus_value)

	return total_effects


## Apply culture effects to calculate modified value
## @param base_value: Original value before modifiers
## @param effect_key: Effect type (e.g., "unit_attack_bonus")
## @param effects: Culture effects dictionary
## @return: Modified value after applying culture effects
func get_effect_modifier(
	base_value: float,
	effect_key: String,
	effects: Dictionary
) -> float:
	if not effects.has(effect_key):
		return base_value

	var modifier = effects[effect_key]
	if not (modifier is float or modifier is int):
		return base_value

	var modifier_value = float(modifier)

	# Handle different effect types
	if effect_key.ends_with("_bonus"):
		# Multiplicative bonus (e.g., 0.25 = +25%)
		return base_value * (1.0 + modifier_value)
	elif effect_key.ends_with("_reduction"):
		# Cost reduction (e.g., 0.15 = -15% cost)
		return base_value * (1.0 - modifier_value)
	elif effect_key.ends_with("_mult") or effect_key.ends_with("_multiplier"):
		# Direct multiplier
		return base_value * modifier_value
	else:
		# Flat addition (e.g., research_speed_bonus)
		return base_value + modifier_value


## Extract all unlocked units, buildings, and policies
## @param nodes: Array of unlocked CultureNode objects
## @return: Dictionary with keys "units", "buildings", "policies" (arrays of IDs)
func get_unlocked_content(nodes: Array[CultureNode]) -> Dictionary:
	var unlocked = {
		"units": [],
		"buildings": [],
		"policies": [],
		"special": []
	}

	for node in nodes:
		# Add units
		if node.unlocks.has("units"):
			var units = node.unlocks["units"]
			if units is Array:
				for unit_id in units:
					if unit_id is String and unit_id not in unlocked["units"]:
						unlocked["units"].append(unit_id)

		# Add buildings
		if node.unlocks.has("buildings"):
			var buildings = node.unlocks["buildings"]
			if buildings is Array:
				for building_id in buildings:
					if building_id is String and building_id not in unlocked["buildings"]:
						unlocked["buildings"].append(building_id)

		# Add policies
		if node.unlocks.has("policies"):
			var policies = node.unlocks["policies"]
			if policies is Array:
				for policy_id in policies:
					if policy_id is String and policy_id not in unlocked["policies"]:
						unlocked["policies"].append(policy_id)

		# Add special unlocks
		if node.unlocks.has("special"):
			var special = node.unlocks["special"]
			if special is Array:
				for special_id in special:
					if special_id is String and special_id not in unlocked["special"]:
						unlocked["special"].append(special_id)

	return unlocked


## Get all unique effect keys from nodes
## @param nodes: Array of CultureNode objects
## @return: Array of unique effect keys
func get_all_effect_keys(nodes: Array[CultureNode]) -> Array[String]:
	var keys: Array[String] = []

	for node in nodes:
		for effect_key in node.effects:
			if effect_key != "special_abilities" and effect_key not in keys:
				keys.append(effect_key)

	return keys


## Merge two effect dictionaries (for combining base and synergy effects)
## @param base_effects: Base effects dictionary
## @param additional_effects: Effects to add
## @return: Merged effects dictionary
func merge_effects(base_effects: Dictionary, additional_effects: Dictionary) -> Dictionary:
	var merged = base_effects.duplicate(true)

	for key in additional_effects:
		if key == "special_abilities":
			# Merge ability arrays
			if not merged.has(key):
				merged[key] = []
			var base_abilities = merged[key] if merged[key] is Array else []
			var add_abilities = additional_effects[key] if additional_effects[key] is Array else []
			for ability in add_abilities:
				if ability not in base_abilities:
					base_abilities.append(ability)
			merged[key] = base_abilities
		else:
			# Sum numeric values
			var value = additional_effects[key]
			if value is float or value is int:
				if merged.has(key):
					merged[key] += float(value)
				else:
					merged[key] = float(value)

	return merged


## Check if a specific synergy is active
## @param synergy_id: Synergy identifier
## @param unlocked_nodes: Array of unlocked node IDs
## @return: true if synergy requirements are met
func is_synergy_active(synergy_id: String, unlocked_nodes: Array[String]) -> bool:
	for synergy in synergy_definitions:
		if synergy.get("id", "") == synergy_id:
			if synergy.has("required_nodes"):
				var required = synergy["required_nodes"]
				if required is Array:
					for node_id in required:
						if node_id not in unlocked_nodes:
							return false
					return true
	return false


## Get synergy definition by ID
## @param synergy_id: Synergy identifier
## @return: Synergy dictionary or empty dict if not found
func get_synergy_by_id(synergy_id: String) -> Dictionary:
	for synergy in synergy_definitions:
		if synergy.get("id", "") == synergy_id:
			return synergy
	return {}


## Calculate effect contribution per node
## @param nodes: Array of unlocked CultureNode objects
## @return: Dictionary mapping node IDs to their effect contributions
func calculate_node_contributions(nodes: Array[CultureNode]) -> Dictionary:
	var contributions: Dictionary = {}

	for node in nodes:
		var node_effects: Dictionary = {}
		for effect_key in node.effects:
			if effect_key != "special_abilities":
				node_effects[effect_key] = node.get_effect_value(effect_key, 0.0)

		contributions[node.id] = node_effects

	return contributions
