extends SceneTree

# Content Validation Script for Ashes to Empire
# Validates all JSON data files for schema compliance and references

var validation_results = {
	"locations": {"count": 0, "errors": []},
	"events": {"count": 0, "errors": []},
	"units": {"count": 0, "errors": []},
	"buildings": {"count": 0, "errors": []},
	"culture": {"count": 0, "errors": []}
}

func _init():
	print("=== Content Validation Starting ===\n")

	validate_locations()
	validate_events()
	validate_units()
	validate_buildings()
	validate_culture_tree()

	print_results()
	quit()

func validate_locations():
	print("Validating locations...")
	var file = FileAccess.open("res://data/world/locations.json", FileAccess.READ)
	if not file:
		validation_results.locations.errors.append("Cannot open locations.json")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result != OK:
		validation_results.locations.errors.append("JSON parse error")
		return

	var data = json.get_data()
	if not data.has("locations"):
		validation_results.locations.errors.append("Missing 'locations' array")
		return

	validation_results.locations.count = data.locations.size()

	# Validate each location
	var ids = []
	for loc in data.locations:
		if not loc.has("id") or not loc.has("name") or not loc.has("type") or not loc.has("description"):
			validation_results.locations.errors.append("Location missing required fields: " + str(loc.get("id", "unknown")))

		# Check for duplicate IDs
		if loc.id in ids:
			validation_results.locations.errors.append("Duplicate location ID: " + loc.id)
		ids.append(loc.id)

		# Validate type enum
		var valid_types = ["ruins", "bunker", "military_base", "research_facility", "industrial_complex",
			"hospital", "power_plant", "airport", "seaport", "mine", "farm", "city_ruins",
			"monument", "vault", "wasteland_anomaly", "radioactive_zone", "natural_resource",
			"settlement_site", "infrastructure"]
		if not loc.type in valid_types:
			validation_results.locations.errors.append("Invalid location type: " + loc.type + " for " + loc.id)

	print("  Locations validated: " + str(validation_results.locations.count))

func validate_events():
	print("Validating events...")
	var file = FileAccess.open("res://data/events/events.json", FileAccess.READ)
	if not file:
		validation_results.events.errors.append("Cannot open events.json")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result != OK:
		validation_results.events.errors.append("JSON parse error")
		return

	var data = json.get_data()
	if not data.has("events"):
		validation_results.events.errors.append("Missing 'events' array")
		return

	validation_results.events.count = data.events.size()

	# Validate each event
	var ids = []
	for event in data.events:
		if not event.has("id") or not event.has("name") or not event.has("choices") or not event.has("rarity"):
			validation_results.events.errors.append("Event missing required fields: " + str(event.get("id", "unknown")))

		# Check for duplicate IDs
		if event.id in ids:
			validation_results.events.errors.append("Duplicate event ID: " + event.id)
		ids.append(event.id)

		# Validate choices array
		if event.has("choices") and (event.choices.size() < 1 or event.choices.size() > 4):
			validation_results.events.errors.append("Event has invalid number of choices: " + event.id)

	print("  Events validated: " + str(validation_results.events.count))

func validate_units():
	print("Validating units...")
	var file = FileAccess.open("res://data/units/units.json", FileAccess.READ)
	if not file:
		validation_results.units.errors.append("Cannot open units.json")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result != OK:
		validation_results.units.errors.append("JSON parse error")
		return

	var data = json.get_data()
	if not data.has("units"):
		validation_results.units.errors.append("Missing 'units' array")
		return

	validation_results.units.count = data.units.size()

	# Validate each unit
	var ids = []
	for unit in data.units:
		if not unit.has("id") or not unit.has("name") or not unit.has("type") or not unit.has("stats"):
			validation_results.units.errors.append("Unit missing required fields: " + str(unit.get("id", "unknown")))

		# Check for duplicate IDs
		if unit.id in ids:
			validation_results.units.errors.append("Duplicate unit ID: " + unit.id)
		ids.append(unit.id)

		# Validate stats
		if unit.has("stats"):
			var required_stats = ["hp", "attack", "defense", "movement", "cost"]
			for stat in required_stats:
				if not unit.stats.has(stat):
					validation_results.units.errors.append("Unit missing stat '" + stat + "': " + unit.id)

	print("  Units validated: " + str(validation_results.units.count))

func validate_buildings():
	print("Validating buildings...")
	var file = FileAccess.open("res://data/buildings/buildings.json", FileAccess.READ)
	if not file:
		validation_results.buildings.errors.append("Cannot open buildings.json")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result != OK:
		validation_results.buildings.errors.append("JSON parse error")
		return

	var data = json.get_data()
	if not data.has("buildings"):
		validation_results.buildings.errors.append("Missing 'buildings' array")
		return

	validation_results.buildings.count = data.buildings.size()

	# Validate each building
	var ids = []
	for building in data.buildings:
		if not building.has("id") or not building.has("name") or not building.has("type") or not building.has("cost"):
			validation_results.buildings.errors.append("Building missing required fields: " + str(building.get("id", "unknown")))

		# Check for duplicate IDs
		if building.id in ids:
			validation_results.buildings.errors.append("Duplicate building ID: " + building.id)
		ids.append(building.id)

	print("  Buildings validated: " + str(validation_results.buildings.count))

func validate_culture_tree():
	print("Validating culture tree...")
	var file = FileAccess.open("res://data/culture/culture_tree.json", FileAccess.READ)
	if not file:
		validation_results.culture.errors.append("Cannot open culture_tree.json")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result != OK:
		validation_results.culture.errors.append("JSON parse error")
		return

	var data = json.get_data()
	if not data.has("culture_tree"):
		validation_results.culture.errors.append("Missing 'culture_tree' object")
		return

	var tree = data.culture_tree
	var axes = ["military", "economic", "social", "technological"]
	var total_nodes = 0

	for axis in axes:
		if not tree.has(axis):
			validation_results.culture.errors.append("Missing axis: " + axis)
		else:
			total_nodes += tree[axis].size()

	validation_results.culture.count = total_nodes
	print("  Culture nodes validated: " + str(total_nodes))

func print_results():
	print("\n=== Validation Results ===\n")
	print("Locations: " + str(validation_results.locations.count) + " total")
	if validation_results.locations.errors.size() > 0:
		print("  ERRORS:")
		for error in validation_results.locations.errors:
			print("    - " + error)
	else:
		print("  ✓ No errors")

	print("\nEvents: " + str(validation_results.events.count) + " total")
	if validation_results.events.errors.size() > 0:
		print("  ERRORS:")
		for error in validation_results.events.errors:
			print("    - " + error)
	else:
		print("  ✓ No errors")

	print("\nUnits: " + str(validation_results.units.count) + " total")
	if validation_results.units.errors.size() > 0:
		print("  ERRORS:")
		for error in validation_results.units.errors:
			print("    - " + error)
	else:
		print("  ✓ No errors")

	print("\nBuildings: " + str(validation_results.buildings.count) + " total")
	if validation_results.buildings.errors.size() > 0:
		print("  ERRORS:")
		for error in validation_results.buildings.errors:
			print("    - " + error)
	else:
		print("  ✓ No errors")

	print("\nCulture Nodes: " + str(validation_results.culture.count) + " total")
	if validation_results.culture.errors.size() > 0:
		print("  ERRORS:")
		for error in validation_results.culture.errors:
			print("    - " + error)
	else:
		print("  ✓ No errors")

	print("\n=== Validation Complete ===")
