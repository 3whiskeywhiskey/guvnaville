extends SceneTree
## Data Validation Script for Ashes to Empire
## Validates all game data JSON files against their schemas
## Usage: godot --headless --script scripts/validate_data.gd

const SCHEMA_PATH = "res://data/schemas/"
const DATA_PATHS = {
	"units": "res://data/units/units.json",
	"buildings": "res://data/buildings/buildings.json",
	"culture": "res://data/culture/culture_tree.json",
	"events": "res://data/events/events.json",
	"locations": "res://data/world/locations.json"
}

var validation_errors: Array[String] = []
var validation_warnings: Array[String] = []
var files_validated: int = 0
var total_items_validated: int = 0


func _init() -> void:
	print("=".repeat(70))
	print("  ASHES TO EMPIRE - Data Validation")
	print("=".repeat(70))
	print()

	validate_all_data()

	print_results()

	# Exit with appropriate code
	if validation_errors.size() > 0:
		quit(1)
	else:
		quit(0)


func validate_all_data() -> void:
	"""Validate all game data files."""
	print("Validating game data files...")
	print()

	# Validate units
	validate_units()

	# Validate buildings
	validate_buildings()

	# Validate culture tree
	validate_culture_tree()

	# Validate events
	validate_events()

	# Validate locations
	validate_locations()


func validate_units() -> void:
	"""Validate unit data."""
	print("[ Validating Units ]")
	var data = load_json_file(DATA_PATHS["units"])
	if data == null:
		return

	if not data.has("units"):
		add_error("Units file missing 'units' array")
		return

	var units: Array = data["units"]
	print("  Found %d units" % units.size())

	for unit in units:
		validate_unit(unit)

	files_validated += 1
	total_items_validated += units.size()
	print()


func validate_unit(unit: Dictionary) -> void:
	"""Validate a single unit definition."""
	var unit_id = unit.get("id", "UNKNOWN")

	# Required fields
	if not validate_required_fields(unit, ["id", "name", "type", "stats", "description"], "Unit[%s]" % unit_id):
		return

	# Validate ID format
	if not unit_id.match("^[a-z_]+$"):
		add_error("Unit[%s]: Invalid ID format (must be lowercase with underscores)" % unit_id)

	# Validate type
	var valid_types = ["infantry", "ranged", "support", "specialist", "heavy"]
	if not unit["type"] in valid_types:
		add_error("Unit[%s]: Invalid type '%s' (must be one of: %s)" % [unit_id, unit["type"], ", ".join(valid_types)])

	# Validate stats
	var stats = unit["stats"]
	if not validate_required_fields(stats, ["hp", "attack", "defense", "movement", "cost"], "Unit[%s].stats" % unit_id):
		return

	# Validate stat ranges
	validate_range(stats, "hp", 1, 1000, "Unit[%s].stats" % unit_id)
	validate_range(stats, "attack", 0, 100, "Unit[%s].stats" % unit_id)
	validate_range(stats, "defense", 0, 100, "Unit[%s].stats" % unit_id)
	validate_range(stats, "movement", 1, 10, "Unit[%s].stats" % unit_id)

	# Validate cost
	var cost = stats.get("cost", {})
	if cost.is_empty():
		add_warning("Unit[%s]: No production cost defined" % unit_id)


func validate_buildings() -> void:
	"""Validate building data."""
	print("[ Validating Buildings ]")
	var data = load_json_file(DATA_PATHS["buildings"])
	if data == null:
		return

	if not data.has("buildings"):
		add_error("Buildings file missing 'buildings' array")
		return

	var buildings: Array = data["buildings"]
	print("  Found %d buildings" % buildings.size())

	for building in buildings:
		validate_building(building)

	files_validated += 1
	total_items_validated += buildings.size()
	print()


func validate_building(building: Dictionary) -> void:
	"""Validate a single building definition."""
	var building_id = building.get("id", "UNKNOWN")

	# Required fields
	if not validate_required_fields(building, ["id", "name", "type", "cost", "description"], "Building[%s]" % building_id):
		return

	# Validate ID format
	if not building_id.match("^[a-z_]+$"):
		add_error("Building[%s]: Invalid ID format (must be lowercase with underscores)" % building_id)

	# Validate type
	var valid_types = ["infrastructure", "production", "military", "research", "cultural", "defensive"]
	if not building["type"] in valid_types:
		add_error("Building[%s]: Invalid type '%s'" % [building_id, building["type"]])

	# Validate cost
	var cost = building.get("cost", {})
	if not cost.has("scrap"):
		add_error("Building[%s]: Missing scrap cost" % building_id)


func validate_culture_tree() -> void:
	"""Validate culture tree data."""
	print("[ Validating Culture Tree ]")
	var data = load_json_file(DATA_PATHS["culture"])
	if data == null:
		return

	if not data.has("culture_tree"):
		add_error("Culture tree file missing 'culture_tree' object")
		return

	var culture_tree = data["culture_tree"]
	var axes = ["military", "economic", "social", "technological"]

	var total_nodes = 0
	for axis in axes:
		if not culture_tree.has(axis):
			add_error("Culture tree missing axis: %s" % axis)
			continue

		var nodes: Array = culture_tree[axis]
		print("  %s axis: %d nodes" % [axis.capitalize(), nodes.size()])

		for node in nodes:
			validate_culture_node(node, axis)
			total_nodes += 1

	files_validated += 1
	total_items_validated += total_nodes
	print()


func validate_culture_node(node: Dictionary, expected_axis: String) -> void:
	"""Validate a single culture node."""
	var node_id = node.get("id", "UNKNOWN")

	# Required fields
	if not validate_required_fields(node, ["id", "name", "axis", "tier", "cost", "effects", "description"], "CultureNode[%s]" % node_id):
		return

	# Validate ID format
	if not node_id.match("^[a-z_]+$"):
		add_error("CultureNode[%s]: Invalid ID format" % node_id)

	# Validate axis matches
	if node["axis"] != expected_axis:
		add_error("CultureNode[%s]: Axis mismatch (expected %s, got %s)" % [node_id, expected_axis, node["axis"]])

	# Validate tier
	validate_range(node, "tier", 1, 5, "CultureNode[%s]" % node_id)

	# Validate cost
	if node["cost"] < 1:
		add_error("CultureNode[%s]: Cost must be at least 1" % node_id)


func validate_events() -> void:
	"""Validate event data."""
	print("[ Validating Events ]")
	var data = load_json_file(DATA_PATHS["events"])
	if data == null:
		return

	if not data.has("events"):
		add_error("Events file missing 'events' array")
		return

	var events: Array = data["events"]
	print("  Found %d events" % events.size())

	for event in events:
		validate_event(event)

	files_validated += 1
	total_items_validated += events.size()
	print()


func validate_event(event: Dictionary) -> void:
	"""Validate a single event definition."""
	var event_id = event.get("id", "UNKNOWN")

	# Required fields
	if not validate_required_fields(event, ["id", "name", "description", "choices", "rarity"], "Event[%s]" % event_id):
		return

	# Validate ID format
	if not event_id.match("^[a-z_]+$"):
		add_error("Event[%s]: Invalid ID format" % event_id)

	# Validate rarity
	var valid_rarities = ["common", "uncommon", "rare", "epic", "unique"]
	if not event["rarity"] in valid_rarities:
		add_error("Event[%s]: Invalid rarity '%s'" % [event_id, event["rarity"]])

	# Validate choices
	var choices = event.get("choices", [])
	if choices.size() == 0:
		add_error("Event[%s]: Must have at least one choice" % event_id)
	elif choices.size() > 4:
		add_warning("Event[%s]: Has %d choices (max recommended: 4)" % [event_id, choices.size()])

	for choice in choices:
		if not choice.has("id") or not choice.has("text") or not choice.has("consequences"):
			add_error("Event[%s]: Choice missing required fields" % event_id)


func validate_locations() -> void:
	"""Validate location data."""
	print("[ Validating Locations ]")
	var data = load_json_file(DATA_PATHS["locations"])
	if data == null:
		return

	if not data.has("locations"):
		add_error("Locations file missing 'locations' array")
		return

	var locations: Array = data["locations"]
	print("  Found %d locations" % locations.size())

	# Track location types for diversity check
	var type_counts = {}

	for location in locations:
		validate_location(location)
		var loc_type = location.get("type", "unknown")
		type_counts[loc_type] = type_counts.get(loc_type, 0) + 1

	# Report type diversity
	print("  Location type diversity:")
	for loc_type in type_counts.keys():
		print("    - %s: %d" % [loc_type, type_counts[loc_type]])

	files_validated += 1
	total_items_validated += locations.size()
	print()


func validate_location(location: Dictionary) -> void:
	"""Validate a single location definition."""
	var loc_id = location.get("id", "UNKNOWN")

	# Required fields
	if not validate_required_fields(location, ["id", "name", "type", "description"], "Location[%s]" % loc_id):
		return

	# Validate ID format
	if not loc_id.match("^[a-z_]+$"):
		add_error("Location[%s]: Invalid ID format" % loc_id)

	# Validate type
	var valid_types = [
		"ruins", "bunker", "military_base", "research_facility", "industrial_complex",
		"hospital", "power_plant", "airport", "seaport", "mine", "farm", "city_ruins",
		"monument", "vault", "wasteland_anomaly", "radioactive_zone", "natural_resource",
		"settlement_site", "infrastructure"
	]
	if not location["type"] in valid_types:
		add_error("Location[%s]: Invalid type '%s'" % [loc_id, location["type"]])

	# Validate danger level
	if location.has("danger_level"):
		validate_range(location, "danger_level", 1, 5, "Location[%s]" % loc_id)


## Helper Functions

func load_json_file(path: String) -> Variant:
	"""Load and parse a JSON file."""
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		add_error("Failed to open file: %s (Error: %s)" % [path, error_string(FileAccess.get_open_error())])
		return null

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		add_error("Failed to parse JSON in %s: %s at line %d" % [path, json.get_error_message(), json.get_error_line()])
		return null

	return json.data


func validate_required_fields(dict: Dictionary, fields: Array, context: String) -> bool:
	"""Validate that all required fields are present."""
	var valid = true
	for field in fields:
		if not dict.has(field):
			add_error("%s: Missing required field '%s'" % [context, field])
			valid = false
	return valid


func validate_range(dict: Dictionary, field: String, min_val: float, max_val: float, context: String) -> void:
	"""Validate that a numeric field is within range."""
	if not dict.has(field):
		return

	var value = dict[field]
	if not (value is int or value is float):
		add_error("%s.%s: Expected number, got %s" % [context, field, type_string(typeof(value))])
		return

	if value < min_val or value > max_val:
		add_error("%s.%s: Value %s out of range [%s, %s]" % [context, field, value, min_val, max_val])


func add_error(message: String) -> void:
	"""Add a validation error."""
	validation_errors.append(message)
	print("  [ERROR] %s" % message)


func add_warning(message: String) -> void:
	"""Add a validation warning."""
	validation_warnings.append(message)
	print("  [WARN] %s" % message)


func print_results() -> void:
	"""Print validation results summary."""
	print()
	print("=".repeat(70))
	print("  VALIDATION RESULTS")
	print("=".repeat(70))
	print()
	print("Files validated: %d" % files_validated)
	print("Total items validated: %d" % total_items_validated)
	print()
	print("Errors: %d" % validation_errors.size())
	print("Warnings: %d" % validation_warnings.size())
	print()

	if validation_errors.size() == 0:
		print("[SUCCESS] All data files validated successfully!")
	else:
		print("[FAILURE] Validation failed with %d errors" % validation_errors.size())
		print()
		print("Summary of errors:")
		for error in validation_errors:
			print("  - %s" % error)

	if validation_warnings.size() > 0:
		print()
		print("Warnings:")
		for warning in validation_warnings:
			print("  - %s" % warning)

	print()
	print("=".repeat(70))
