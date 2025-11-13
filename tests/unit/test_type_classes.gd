extends GutTest

## Unit tests for type classes (Unit, Tile, Building, Resource)

# ============================================================================
# UNIT TESTS
# ============================================================================

func test_unit_creation():
	var unit = Unit.new("unit_1", "militia", 0, Vector3i(5, 5, 1))

	assert_eq(unit.unit_id, "unit_1", "Unit ID should be set")
	assert_eq(unit.unit_type, "militia", "Unit type should be set")
	assert_eq(unit.faction_id, 0, "Faction ID should be set")
	assert_eq(unit.position, Vector3i(5, 5, 1), "Position should be set")

func test_unit_serialization():
	var unit = Unit.new("unit_1", "militia", 0, Vector3i(5, 5, 1))
	unit.current_hp = 75
	unit.attack = 15
	unit.defense = 12
	unit.morale = 80
	unit.experience = 50
	unit.rank = 1
	unit.abilities.append("charge")

	var dict = unit.to_dict()

	assert_eq(dict["unit_id"], "unit_1", "Serialized unit_id")
	assert_eq(dict["current_hp"], 75, "Serialized HP")
	assert_eq(dict["rank"], 1, "Serialized rank")
	assert_true(dict["abilities"].has("charge"), "Serialized abilities")

func test_unit_deserialization():
	var data = {
		"unit_id": "unit_2",
		"unit_type": "scouts",
		"faction_id": 1,
		"position": {"x": 10, "y": 15, "z": 1},
		"max_hp": 80,
		"current_hp": 60,
		"attack": 12,
		"defense": 8,
		"movement": 5,
		"morale": 90,
		"experience": 100,
		"rank": 2,
		"abilities": ["stealth"],
		"status_effects": []
	}

	var unit = Unit.new()
	unit.from_dict(data)

	assert_eq(unit.unit_id, "unit_2", "Deserialized unit_id")
	assert_eq(unit.unit_type, "scouts", "Deserialized unit_type")
	assert_eq(unit.position, Vector3i(10, 15, 1), "Deserialized position")
	assert_eq(unit.current_hp, 60, "Deserialized HP")
	assert_eq(unit.rank, 2, "Deserialized rank")

func test_unit_round_trip():
	var original = Unit.new("unit_3", "soldiers", 2, Vector3i(20, 20, 2))
	original.current_hp = 85
	original.experience = 250
	original.rank = 2

	var dict = original.to_dict()
	var restored = Unit.new()
	restored.from_dict(dict)

	assert_eq(restored.unit_id, original.unit_id, "Round-trip unit_id")
	assert_eq(restored.current_hp, original.current_hp, "Round-trip HP")
	assert_eq(restored.experience, original.experience, "Round-trip experience")
	assert_eq(restored.rank, original.rank, "Round-trip rank")

func test_unit_take_damage():
	var unit = Unit.new("unit_4", "militia", 0, Vector3i.ZERO)
	unit.current_hp = 100

	unit.take_damage(30)
	assert_eq(unit.current_hp, 70, "Unit should take damage")

	unit.take_damage(100)
	assert_eq(unit.current_hp, 0, "Unit HP should not go below 0")

func test_unit_heal():
	var unit = Unit.new("unit_5", "militia", 0, Vector3i.ZERO)
	unit.max_hp = 100
	unit.current_hp = 50

	unit.heal(30)
	assert_eq(unit.current_hp, 80, "Unit should heal")

	unit.heal(50)
	assert_eq(unit.current_hp, 100, "Unit HP should not exceed max")

func test_unit_promotion():
	var unit = Unit.new("unit_6", "militia", 0, Vector3i.ZERO)
	unit.experience = 0
	unit.rank = 0

	unit.gain_experience(100)
	assert_eq(unit.rank, 1, "Unit should be promoted to rank 1")

	unit.gain_experience(200)
	assert_eq(unit.rank, 2, "Unit should be promoted to rank 2")

func test_unit_is_alive():
	var unit = Unit.new("unit_7", "militia", 0, Vector3i.ZERO)
	unit.current_hp = 50

	assert_true(unit.is_alive(), "Unit with HP should be alive")

	unit.current_hp = 0
	assert_false(unit.is_alive(), "Unit with 0 HP should be dead")

# ============================================================================
# TILE TESTS
# ============================================================================

func test_tile_creation():
	var tile = Tile.new(Vector3i(10, 10, 1)).setup("residential", "rubble")

	assert_eq(tile.position, Vector3i(10, 10, 1), "Tile position")
	assert_eq(tile.tile_type, "residential", "Tile type")
	assert_eq(tile.terrain_type, "rubble", "Terrain type")

func test_tile_serialization():
	var tile = Tile.new(Vector3i(5, 5, 1)).setup("commercial", "building")
	tile.owner = 2
	tile.building = "workshop_1"
	tile.units.append("unit_1")
	tile.scavenge_value = 75

	var dict = tile.to_dict()

	assert_eq(dict["position"]["x"], 5, "Serialized position X")
	assert_eq(dict["owner"], 2, "Serialized owner")
	assert_eq(dict["building"], "workshop_1", "Serialized building")
	assert_eq(dict["scavenge_value"], 75, "Serialized scavenge")

func test_tile_deserialization():
	var data = {
		"position": {"x": 15, "y": 20, "z": 2},
		"tile_type": "industrial",
		"terrain_type": "street",
		"owner": 1,
		"building": "",
		"units": ["unit_2", "unit_3"],
		"scavenge_value": 30,
		"visibility": {},
		"hazards": [],
		"movement_cost": 1,
		"defense_bonus": 0,
		"elevation": 1
	}

	var tile = Tile.new()
	tile.from_dict(data)

	assert_eq(tile.position, Vector3i(15, 20, 2), "Deserialized position")
	assert_eq(tile.tile_type, "industrial", "Deserialized tile_type")
	assert_eq(tile.owner, 1, "Deserialized owner")
	assert_eq(tile.units.size(), 2, "Deserialized units")

func test_tile_add_remove_unit():
	var tile = Tile.new(Vector3i.ZERO).setup("residential", "rubble")

	tile.add_unit("unit_1")
	assert_eq(tile.units.size(), 1, "Unit should be added")
	assert_true(tile.units.has("unit_1"), "Unit should be in list")

	tile.add_unit("unit_1")
	assert_eq(tile.units.size(), 1, "Duplicate unit should not be added")

	tile.remove_unit("unit_1")
	assert_eq(tile.units.size(), 0, "Unit should be removed")

func test_tile_scavenge():
	var tile = Tile.new(Vector3i.ZERO).setup("residential", "rubble")
	tile.scavenge_value = 50

	var depleted = tile.deplete_scavenge(30)
	assert_eq(depleted, 30, "Should deplete 30")
	assert_eq(tile.scavenge_value, 20, "Scavenge value should decrease")

	depleted = tile.deplete_scavenge(50)
	assert_eq(depleted, 20, "Should only deplete remaining amount")
	assert_eq(tile.scavenge_value, 0, "Scavenge should be 0")

func test_tile_visibility():
	var tile = Tile.new(Vector3i.ZERO).setup("residential", "rubble")

	tile.set_visibility(0, 2)
	assert_true(tile.is_visible_to(0), "Tile should be visible to faction 0")
	assert_eq(tile.get_visibility_level(0), 2, "Visibility level should be 2")

	assert_false(tile.is_visible_to(1), "Tile should not be visible to faction 1")

# ============================================================================
# BUILDING TESTS
# ============================================================================

func test_building_creation():
	var building = Building.new("bld_1", "workshop", 0, Vector3i(10, 10, 1))

	assert_eq(building.building_id, "bld_1", "Building ID")
	assert_eq(building.building_type, "workshop", "Building type")
	assert_eq(building.faction_id, 0, "Faction ID")
	assert_eq(building.position, Vector3i(10, 10, 1), "Position")

func test_building_serialization():
	var building = Building.new("bld_2", "barracks", 1, Vector3i(15, 15, 1))
	building.current_hp = 80
	building.is_operational = true
	building.garrison.append("unit_1")

	var dict = building.to_dict()

	assert_eq(dict["building_id"], "bld_2", "Serialized ID")
	assert_eq(dict["building_type"], "barracks", "Serialized type")
	assert_eq(dict["current_hp"], 80, "Serialized HP")
	assert_true(dict["is_operational"], "Serialized operational")

func test_building_damage():
	var building = Building.new("bld_3", "workshop", 0, Vector3i.ZERO)
	building.max_hp = 100
	building.current_hp = 100
	building.is_operational = true

	building.take_damage(50)
	assert_eq(building.current_hp, 50, "Building should take damage")
	assert_true(building.is_operational, "Building should still be operational")

	building.take_damage(30)
	assert_eq(building.current_hp, 20, "Building HP should decrease")
	assert_false(building.is_operational, "Building should be non-operational at < 30% HP")

func test_building_repair():
	var building = Building.new("bld_4", "workshop", 0, Vector3i.ZERO)
	building.max_hp = 100
	building.current_hp = 20
	building.is_operational = false

	building.repair(20)
	assert_eq(building.current_hp, 40, "Building should be repaired")
	assert_true(building.is_operational, "Building should become operational")

func test_building_garrison():
	var building = Building.new("bld_5", "barracks", 0, Vector3i.ZERO)

	assert_true(building.add_garrison("unit_1"), "Should add unit to garrison")
	assert_eq(building.get_garrison_count(), 1, "Garrison count should be 1")

	building.add_garrison("unit_2")
	building.add_garrison("unit_3")
	building.add_garrison("unit_4")
	building.add_garrison("unit_5")

	assert_eq(building.get_garrison_count(), 5, "Garrison count should be 5")
	assert_true(building.is_garrison_full(), "Garrison should be full")

	assert_false(building.add_garrison("unit_6"), "Should not add when full")

	assert_true(building.remove_garrison("unit_1"), "Should remove unit")
	assert_eq(building.get_garrison_count(), 4, "Garrison count should be 4")

# ============================================================================
# RESOURCE TESTS
# ============================================================================

func test_resource_creation():
	var resource = GameResource.new("scrap", "Scrap Metal", "Salvaged metal pieces")

	assert_eq(resource.resource_type, "scrap", "Resource type")
	assert_eq(resource.display_name, "Scrap Metal", "Display name")
	assert_eq(resource.description, "Salvaged metal pieces", "Description")

func test_resource_serialization():
	var resource = GameResource.new("components", "Components", "Pre-war electronic components")
	resource.is_strategic = true
	resource.base_value = 10

	var dict = resource.to_dict()

	assert_eq(dict["resource_type"], "components", "Serialized type")
	assert_eq(dict["display_name"], "Components", "Serialized name")
	assert_true(dict["is_strategic"], "Serialized strategic flag")
	assert_eq(dict["base_value"], 10, "Serialized base value")

func test_resource_deserialization():
	var data = {
		"resource_type": "ammo",
		"display_name": "Ammunition",
		"description": "Various caliber ammunition",
		"icon_path": "res://assets/icons/ammo.png",
		"is_stockpiled": true,
		"is_strategic": true,
		"base_value": 5
	}

	var resource = GameResource.new()
	resource.from_dict(data)

	assert_eq(resource.resource_type, "ammo", "Deserialized type")
	assert_eq(resource.display_name, "Ammunition", "Deserialized name")
	assert_true(resource.is_strategic, "Deserialized strategic")
