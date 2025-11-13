class_name UnitFactory
extends Node

## Unit Factory - Creates units from JSON data templates
## Part of Workstream 2.3: Unit System

# Unit templates loaded from data files
var _unit_templates: Dictionary = {}

# Next available unit ID
var _next_unit_id: int = 1

# Data file path
const UNIT_DATA_PATH = "res://data/units/units.json"

## Initialize factory and load unit data
func _ready():
	load_unit_data()

## Load unit definitions from JSON file
func load_unit_data(data_path: String = UNIT_DATA_PATH) -> bool:
	if not FileAccess.file_exists(data_path):
		push_error("Unit data file not found: " + data_path)
		return false

	var file = FileAccess.open(data_path, FileAccess.READ)
	if not file:
		push_error("Failed to open unit data file: " + data_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse unit data JSON: " + data_path)
		return false

	var data = json.get_data()

	if not data is Dictionary or not data.has("units"):
		push_error("Invalid unit data format")
		return false

	# Load all unit templates
	_unit_templates.clear()
	for unit_data in data["units"]:
		if unit_data.has("id"):
			_unit_templates[unit_data["id"]] = unit_data

	print("UnitFactory: Loaded %d unit templates" % _unit_templates.size())
	return true

## Create unit from template
func create_from_template(
	template_name: String,
	faction_id: int,
	position: Vector3i,
	overrides: Dictionary = {}
) -> Unit:
	if not _unit_templates.has(template_name):
		push_error("Unit template not found: " + template_name)
		return null

	var template = _unit_templates[template_name]
	var unit = Unit.new()

	# Assign unique ID
	unit.id = _next_unit_id
	_next_unit_id += 1

	# Set basic properties
	unit.type = template_name
	unit.faction_id = faction_id
	unit.position = position
	unit.name = _generate_unit_name(template, faction_id)

	# Set stats from template
	_apply_template_stats(unit, template)

	# Apply any custom overrides
	_apply_overrides(unit, overrides)

	# Initialize turn state
	unit.movement_remaining = unit.stats.movement
	unit.actions_remaining = 1

	return unit

## Get raw unit template data
func get_unit_template(template_name: String) -> Dictionary:
	return _unit_templates.get(template_name, {})

## Get all available unit types
func get_available_unit_types(faction_id: int = -1) -> Array[String]:
	var types: Array[String] = []

	for template_id in _unit_templates.keys():
		var template = _unit_templates[template_id]

		# Check prerequisites
		if _check_prerequisites(template, faction_id):
			types.append(template_id)

	return types

## Get all unit template IDs
func get_all_unit_types() -> Array[String]:
	var types: Array[String] = []
	types.assign(_unit_templates.keys())
	return types

## Check if a unit type exists
func has_unit_type(template_name: String) -> bool:
	return _unit_templates.has(template_name)

## Reset unit ID counter (for testing)
func reset_id_counter(start_id: int = 1) -> void:
	_next_unit_id = start_id

## Private helper methods

func _apply_template_stats(unit: Unit, template: Dictionary) -> void:
	var stats_data = template.get("stats", {})

	# Create UnitStats
	unit.stats = UnitStats.new()

	# Set HP
	unit.max_hp = stats_data.get("hp", 100)
	unit.current_hp = unit.max_hp

	# Set base morale
	unit.morale = stats_data.get("morale", 50)
	unit.stats.morale_base = unit.morale

	# Set combat stats
	unit.stats.attack = stats_data.get("attack", 10)
	unit.stats.defense = stats_data.get("defense", 5)
	unit.stats.armor = stats_data.get("armor", 0)
	unit.armor = unit.stats.armor

	# Set movement stats
	unit.stats.movement = stats_data.get("movement", 3)
	unit.stats.vision_range = stats_data.get("vision_range", 2)

	# Set movement type based on unit type
	var unit_type = template.get("type", "infantry")
	unit.stats.movement_type = _get_movement_type(unit_type)

	# Set range (default 1 for melee)
	unit.stats.range = stats_data.get("range", 1)

	# Load abilities from template
	_load_abilities(unit, template)

func _get_movement_type(type_string: String) -> UnitStats.MovementType:
	match type_string:
		"infantry", "support", "specialist", "heavy", "ranged":
			return UnitStats.MovementType.INFANTRY
		"wheeled":
			return UnitStats.MovementType.WHEELED
		"tracked":
			return UnitStats.MovementType.TRACKED
		"airborne":
			return UnitStats.MovementType.AIRBORNE
		_:
			return UnitStats.MovementType.INFANTRY

func _load_abilities(unit: Unit, template: Dictionary) -> void:
	var abilities_data = template.get("abilities", [])

	for ability_data in abilities_data:
		# Store ability data as dictionary for now
		# Will be converted to proper Ability objects once ability system is implemented
		var ability = {
			"id": ability_data.get("id", ""),
			"name": ability_data.get("name", ""),
			"description": ability_data.get("description", ""),
			"cooldown": ability_data.get("cooldown", 0),
			"current_cooldown": 0
		}
		unit.abilities.append(ability)

func _apply_overrides(unit: Unit, overrides: Dictionary) -> void:
	# Apply custom stat overrides
	if overrides.has("max_hp"):
		unit.max_hp = overrides["max_hp"]
		unit.current_hp = unit.max_hp

	if overrides.has("morale"):
		unit.morale = overrides["morale"]

	if overrides.has("name"):
		unit.name = overrides["name"]

	if overrides.has("rank"):
		unit.rank = overrides["rank"]
		unit._apply_rank_bonuses()

	if overrides.has("experience"):
		unit.experience = overrides["experience"]
		unit._check_promotion()

	# Apply stat overrides
	if overrides.has("stats"):
		var stat_overrides = overrides["stats"]
		if stat_overrides.has("attack"):
			unit.stats.attack = stat_overrides["attack"]
		if stat_overrides.has("defense"):
			unit.stats.defense = stat_overrides["defense"]
		if stat_overrides.has("movement"):
			unit.stats.movement = stat_overrides["movement"]
		if stat_overrides.has("vision_range"):
			unit.stats.vision_range = stat_overrides["vision_range"]

func _generate_unit_name(template: Dictionary, faction_id: int) -> String:
	var base_name = template.get("name", "Unit")
	return "%s #%d" % [base_name, _next_unit_id]

func _check_prerequisites(template: Dictionary, faction_id: int) -> bool:
	# For MVP, we'll just check if prerequisites exist
	# Full prerequisite checking would require integration with culture/building systems

	if not template.has("prerequisites"):
		return true

	var prereqs = template["prerequisites"]

	# If prerequisites exist but faction_id is invalid, assume they're not met
	if faction_id < 0:
		return prereqs.is_empty()

	# For testing purposes, allow all units if faction_id is valid
	# Real implementation would check against faction's unlocked buildings/culture nodes
	return true

## Get unit cost from template
func get_unit_cost(template_name: String) -> Dictionary:
	if not _unit_templates.has(template_name):
		return {}

	var template = _unit_templates[template_name]
	var stats = template.get("stats", {})
	return stats.get("cost", {})

## Get unit production time
func get_production_time(template_name: String) -> int:
	if not _unit_templates.has(template_name):
		return 1

	var template = _unit_templates[template_name]
	return template.get("production_time", 1)
