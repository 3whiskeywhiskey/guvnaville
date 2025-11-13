extends GutTest

## Unit Tests for UnitFactory
## Tests unit creation from JSON templates

var factory: UnitFactory

func before_each():
	factory = UnitFactory.new()
	# Load unit data
	factory.load_unit_data()

func after_each():
	factory.queue_free()
	factory = null

# Data Loading Tests

func test_factory_loads_unit_data():
	assert_gt(factory.get_all_unit_types().size(), 0, "Should load unit templates")

func test_factory_has_militia():
	assert_true(factory.has_unit_type("militia"), "Should have militia unit type")

func test_factory_has_soldier():
	assert_true(factory.has_unit_type("soldier"), "Should have soldier unit type")

func test_get_unit_template():
	var template = factory.get_unit_template("militia")

	assert_false(template.is_empty(), "Should return template")
	assert_eq(template.get("id", ""), "militia", "Template should be militia")
	assert_true(template.has("stats"), "Template should have stats")

func test_get_invalid_template():
	var template = factory.get_unit_template("nonexistent")

	assert_true(template.is_empty(), "Should return empty dict for invalid type")

# Unit Creation Tests

func test_create_militia_from_template():
	var unit = factory.create_from_template("militia", 1, Vector3i(5, 5, 0))

	assert_not_null(unit, "Should create unit")
	assert_eq(unit.type, "militia", "Unit type should be militia")
	assert_eq(unit.faction_id, 1, "Faction ID should be 1")
	assert_eq(unit.position, Vector3i(5, 5, 0), "Position should match")
	assert_gt(unit.id, 0, "Should have valid ID")

func test_create_soldier_from_template():
	var unit = factory.create_from_template("soldier", 2, Vector3i(10, 10, 0))

	assert_not_null(unit, "Should create unit")
	assert_eq(unit.type, "soldier", "Unit type should be soldier")
	assert_eq(unit.faction_id, 2, "Faction ID should be 2")

func test_create_invalid_unit_type():
	var unit = factory.create_from_template("invalid_type", 1, Vector3i(0, 0, 0))

	assert_null(unit, "Should return null for invalid type")

func test_unit_has_unique_id():
	var unit1 = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))
	var unit2 = factory.create_from_template("militia", 1, Vector3i(1, 1, 0))

	assert_ne(unit1.id, unit2.id, "Units should have unique IDs")

func test_unit_id_increments():
	factory.reset_id_counter(100)

	var unit1 = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))
	var unit2 = factory.create_from_template("militia", 1, Vector3i(1, 1, 0))

	assert_eq(unit1.id, 100, "First unit should have ID 100")
	assert_eq(unit2.id, 101, "Second unit should have ID 101")

# Stat Application Tests

func test_militia_stats():
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))

	assert_not_null(unit.stats, "Should have stats")
	assert_eq(unit.max_hp, 50, "Militia should have 50 HP")
	assert_eq(unit.current_hp, 50, "Should start at full HP")
	assert_eq(unit.stats.attack, 8, "Militia should have 8 attack")
	assert_eq(unit.stats.defense, 5, "Militia should have 5 defense")
	assert_eq(unit.stats.movement, 3, "Militia should have 3 movement")

func test_soldier_stats():
	var unit = factory.create_from_template("soldier", 1, Vector3i(0, 0, 0))

	assert_eq(unit.max_hp, 80, "Soldier should have 80 HP")
	assert_eq(unit.stats.attack, 15, "Soldier should have 15 attack")
	assert_eq(unit.stats.defense, 12, "Soldier should have 12 defense")

func test_unit_has_morale():
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))

	assert_eq(unit.morale, 40, "Militia should have 40 morale")

# Ability Loading Tests

func test_soldier_has_abilities():
	var unit = factory.create_from_template("soldier", 1, Vector3i(0, 0, 0))

	assert_gt(unit.abilities.size(), 0, "Soldier should have abilities")

func test_militia_has_no_abilities():
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))

	assert_eq(unit.abilities.size(), 0, "Militia should have no abilities")

# Customization Tests

func test_override_max_hp():
	var overrides = {"max_hp": 200}
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0), overrides)

	assert_eq(unit.max_hp, 200, "Max HP should be overridden")
	assert_eq(unit.current_hp, 200, "Current HP should match")

func test_override_name():
	var overrides = {"name": "Elite Squad"}
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0), overrides)

	assert_eq(unit.name, "Elite Squad", "Name should be overridden")

func test_override_rank():
	var overrides = {"rank": Unit.UnitRank.VETERAN}
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0), overrides)

	assert_eq(unit.rank, Unit.UnitRank.VETERAN, "Rank should be overridden")

func test_override_experience():
	var overrides = {"experience": 350}
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0), overrides)

	assert_eq(unit.experience, 350, "Experience should be overridden")
	assert_eq(unit.rank, Unit.UnitRank.VETERAN, "Should be promoted based on XP")

func test_override_stats():
	var overrides = {
		"stats": {
			"attack": 50,
			"defense": 40,
			"movement": 10
		}
	}
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0), overrides)

	assert_eq(unit.stats.attack, 50, "Attack should be overridden")
	assert_eq(unit.stats.defense, 40, "Defense should be overridden")
	assert_eq(unit.stats.movement, 10, "Movement should be overridden")

# Turn State Initialization Tests

func test_unit_starts_with_movement():
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))

	assert_eq(unit.movement_remaining, unit.stats.movement, "Should start with full movement")

func test_unit_starts_with_action():
	var unit = factory.create_from_template("militia", 1, Vector3i(0, 0, 0))

	assert_eq(unit.actions_remaining, 1, "Should start with 1 action")

# Utility Tests

func test_get_available_unit_types():
	var types = factory.get_available_unit_types(1)

	assert_gt(types.size(), 0, "Should have available unit types")
	assert_true(types.has("militia"), "Should include militia")

func test_get_all_unit_types():
	var types = factory.get_all_unit_types()

	assert_gt(types.size(), 0, "Should have unit types")
	assert_true(types.has("militia"), "Should include militia")
	assert_true(types.has("soldier"), "Should include soldier")

func test_get_unit_cost():
	var cost = factory.get_unit_cost("militia")

	assert_false(cost.is_empty(), "Should have cost data")
	assert_true(cost.has("scrap"), "Should have scrap cost")
	assert_true(cost.has("food"), "Should have food cost")

func test_get_production_time():
	var time = factory.get_production_time("militia")

	assert_eq(time, 1, "Militia should have production time of 1")

	time = factory.get_production_time("soldier")
	assert_eq(time, 2, "Soldier should have production time of 2")
