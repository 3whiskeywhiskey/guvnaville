extends Node

## DataLoader - Loads and validates all JSON game data
##
## This singleton loads unit types, buildings, culture trees, events,
## unique locations, and other game data from JSON files.

# ============================================================================
# PROPERTIES
# ============================================================================

## All unit type definitions {unit_type: definition}
var unit_types: Dictionary = {}

## All building type definitions {building_type: definition}
var building_types: Dictionary = {}

## Culture tree structures {axis: tree_data}
var culture_trees: Dictionary = {}

## All event definitions
var event_definitions: Array = []

## Unique location data
var unique_locations: Array = []

## Tile type definitions {tile_type: definition}
var tile_types: Dictionary = {}

## Resource definitions {resource_type: definition}
var resource_definitions: Dictionary = {}

## True if data has been loaded successfully
var is_data_loaded: bool = false

# ============================================================================
# DATA PATHS
# ============================================================================

const DATA_DIR = "res://data/"
const UNITS_FILE = "units.json"
const BUILDINGS_FILE = "buildings.json"
const CULTURE_FILE = "culture_tree.json"
const EVENTS_FILE = "events.json"
const LOCATIONS_FILE = "unique_locations.json"
const TILES_FILE = "tiles.json"
const RESOURCES_FILE = "resources.json"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Data will be loaded on demand or during game initialization
	pass

# ============================================================================
# DATA LOADING
# ============================================================================

## Load all game data from JSON files
func load_game_data() -> bool:
	print("[DataLoader] Loading game data...")

	var success = true

	# Load units
	if not _load_units():
		success = false

	# Load buildings
	if not _load_buildings():
		success = false

	# Load resources
	if not _load_resources():
		success = false

	# Load tiles
	if not _load_tiles():
		success = false

	# Load culture trees
	if not _load_culture():
		success = false

	# Load events
	if not _load_events():
		success = false

	# Load unique locations
	if not _load_locations():
		success = false

	is_data_loaded = success

	if success:
		print("[DataLoader] All game data loaded successfully")
	else:
		push_error("[DataLoader] Failed to load some game data")

	return success

## Reload all game data (for hot-reloading during development)
func reload_data() -> bool:
	print("[DataLoader] Reloading game data...")
	unit_types.clear()
	building_types.clear()
	culture_trees.clear()
	event_definitions.clear()
	unique_locations.clear()
	tile_types.clear()
	resource_definitions.clear()
	is_data_loaded = false

	return load_game_data()

## Validate all loaded data
func validate_data() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# Check that we have data
	if unit_types.is_empty():
		errors.append("No unit types loaded")

	if building_types.is_empty():
		warnings.append("No building types loaded")

	if resource_definitions.is_empty():
		errors.append("No resource definitions loaded")

	# Validate unit types have required fields
	for unit_type in unit_types:
		var def = unit_types[unit_type]
		if not def.has("name"):
			errors.append("Unit type '%s' missing 'name' field" % unit_type)
		if not def.has("attack"):
			errors.append("Unit type '%s' missing 'attack' field" % unit_type)

	# Validate building types
	for building_type in building_types:
		var def = building_types[building_type]
		if not def.has("name"):
			errors.append("Building type '%s' missing 'name' field" % building_type)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings
	}

# ============================================================================
# DATA QUERIES
# ============================================================================

## Get unit definition by type
func get_unit_definition(unit_type: String) -> Dictionary:
	return unit_types.get(unit_type, {})

## Get building definition by type
func get_building_definition(building_type: String) -> Dictionary:
	return building_types.get(building_type, {})

## Get resource definition by type
func get_resource_definition(resource_type: String) -> Dictionary:
	return resource_definitions.get(resource_type, {})

## Get tile definition by type
func get_tile_definition(tile_type: String) -> Dictionary:
	return tile_types.get(tile_type, {})

# ============================================================================
# PRIVATE LOADING METHODS
# ============================================================================

func _load_units() -> bool:
	var path = DATA_DIR + UNITS_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No units data found at %s" % path)
		return false

	# Handle both array and object format
	if data is Array:
		for unit_def in data:
			var unit_id = unit_def.get("id", "")
			if unit_id != "":
				unit_types[unit_id] = unit_def
	elif data is Dictionary and data.has("units"):
		var units_array = data["units"]
		for unit_def in units_array:
			var unit_id = unit_def.get("id", "")
			if unit_id != "":
				unit_types[unit_id] = unit_def

	print("[DataLoader] Loaded %d unit types" % unit_types.size())
	return true

func _load_buildings() -> bool:
	var path = DATA_DIR + BUILDINGS_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No buildings data found at %s" % path)
		return false

	# Handle both array and object format
	if data is Array:
		for building_def in data:
			var building_id = building_def.get("id", "")
			if building_id != "":
				building_types[building_id] = building_def
	elif data is Dictionary and data.has("buildings"):
		var buildings_array = data["buildings"]
		for building_def in buildings_array:
			var building_id = building_def.get("id", "")
			if building_id != "":
				building_types[building_id] = building_def

	print("[DataLoader] Loaded %d building types" % building_types.size())
	return true

func _load_resources() -> bool:
	var path = DATA_DIR + RESOURCES_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No resources data found at %s" % path)
		return false

	# Handle both array and object format
	if data is Array:
		for resource_def in data:
			var resource_id = resource_def.get("id", "")
			if resource_id != "":
				resource_definitions[resource_id] = resource_def
	elif data is Dictionary and data.has("resources"):
		var resources_array = data["resources"]
		for resource_def in resources_array:
			var resource_id = resource_def.get("id", "")
			if resource_id != "":
				resource_definitions[resource_id] = resource_def

	print("[DataLoader] Loaded %d resource types" % resource_definitions.size())
	return true

func _load_tiles() -> bool:
	var path = DATA_DIR + TILES_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No tiles data found at %s" % path)
		# Tiles are optional, create defaults
		_create_default_tiles()
		return true

	# Handle both array and object format
	if data is Array:
		for tile_def in data:
			var tile_id = tile_def.get("id", "")
			if tile_id != "":
				tile_types[tile_id] = tile_def
	elif data is Dictionary and data.has("tiles"):
		var tiles_array = data["tiles"]
		for tile_def in tiles_array:
			var tile_id = tile_def.get("id", "")
			if tile_id != "":
				tile_types[tile_id] = tile_def

	print("[DataLoader] Loaded %d tile types" % tile_types.size())
	return true

func _load_culture() -> bool:
	var path = DATA_DIR + CULTURE_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No culture tree data found at %s" % path)
		return false

	culture_trees = data
	print("[DataLoader] Loaded culture tree data")
	return true

func _load_events() -> bool:
	var path = DATA_DIR + EVENTS_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No events data found at %s" % path)
		return true  # Events are optional

	# Handle both array and object format
	if data is Array:
		event_definitions = data
	elif data is Dictionary and data.has("events"):
		event_definitions = data["events"]

	print("[DataLoader] Loaded %d events" % event_definitions.size())
	return true

func _load_locations() -> bool:
	var path = DATA_DIR + LOCATIONS_FILE
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("[DataLoader] No unique locations data found at %s" % path)
		return true  # Locations are optional

	# Handle both array and object format
	if data is Array:
		unique_locations = data
	elif data is Dictionary and data.has("locations"):
		unique_locations = data["locations"]

	print("[DataLoader] Loaded %d unique locations" % unique_locations.size())
	return true

func _load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("[DataLoader] File not found: %s" % path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open file: %s" % path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("[DataLoader] JSON parse error in %s at line %d: %s" % [
			path,
			json.get_error_line(),
			json.get_error_message()
		])
		return {}

	return json.data

func _create_default_tiles() -> void:
	# Create basic tile types if none are loaded
	tile_types = {
		"residential": {
			"id": "residential",
			"name": "Residential",
			"movement_cost": 1,
			"defense_bonus": 0
		},
		"commercial": {
			"id": "commercial",
			"name": "Commercial",
			"movement_cost": 1,
			"defense_bonus": 0
		},
		"industrial": {
			"id": "industrial",
			"name": "Industrial",
			"movement_cost": 1,
			"defense_bonus": 0
		},
		"rubble": {
			"id": "rubble",
			"name": "Rubble",
			"movement_cost": 2,
			"defense_bonus": 1
		}
	}
	print("[DataLoader] Created %d default tile types" % tile_types.size())
