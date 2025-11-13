extends GutTest

## Unit tests for Tile class
##
## Tests tile creation, serialization, and helper methods
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# SETUP
# ============================================================================

var tile: Tile

func before_each():
	tile = Tile.new(Vector3i(10, 20, 1))

func after_each():
	tile = null

# ============================================================================
# INITIALIZATION TESTS
# ============================================================================

func test_tile_initialization():
	assert_not_null(tile, "Tile should be created")
	assert_eq(tile.position, Vector3i(10, 20, 1), "Position should be set correctly")
	assert_true(tile.is_valid_position(), "Position should be valid")

func test_tile_default_properties():
	var ground_tile = Tile.new(Vector3i(50, 50, 1))
	assert_eq(ground_tile.position.z, 1, "Ground level should be z=1")
	assert_eq(ground_tile.terrain, Tile.TerrainType.RUBBLE, "Ground level default terrain")
	assert_eq(ground_tile.tile_type, Tile.TileType.RUINS, "Ground level default type")

func test_tile_underground_defaults():
	var underground_tile = Tile.new(Vector3i(50, 50, 0))
	assert_eq(underground_tile.terrain, Tile.TerrainType.TUNNEL, "Underground should be tunnel")
	assert_eq(underground_tile.tile_type, Tile.TileType.INFRASTRUCTURE, "Underground should be infrastructure")

func test_tile_elevated_defaults():
	var elevated_tile = Tile.new(Vector3i(50, 50, 2))
	assert_eq(elevated_tile.terrain, Tile.TerrainType.ROOFTOP, "Elevated should be rooftop")

# ============================================================================
# ENUM TESTS
# ============================================================================

func test_tile_type_enum():
	assert_true(Tile.TileType.RESIDENTIAL >= 0, "RESIDENTIAL enum exists")
	assert_true(Tile.TileType.COMMERCIAL >= 0, "COMMERCIAL enum exists")
	assert_true(Tile.TileType.INDUSTRIAL >= 0, "INDUSTRIAL enum exists")
	assert_true(Tile.TileType.MILITARY >= 0, "MILITARY enum exists")
	assert_true(Tile.TileType.RUINS >= 0, "RUINS enum exists")

func test_terrain_type_enum():
	assert_true(Tile.TerrainType.OPEN_GROUND >= 0, "OPEN_GROUND enum exists")
	assert_true(Tile.TerrainType.BUILDING >= 0, "BUILDING enum exists")
	assert_true(Tile.TerrainType.RUBBLE >= 0, "RUBBLE enum exists")
	assert_true(Tile.TerrainType.WATER >= 0, "WATER enum exists")

# ============================================================================
# SERIALIZATION TESTS
# ============================================================================

func test_tile_to_dict():
	tile.tile_type = Tile.TileType.RESIDENTIAL
	tile.terrain = Tile.TerrainType.BUILDING
	tile.owner_id = 3
	tile.scavenge_value = 75.5
	tile.has_building = true
	tile.building_id = "barracks_01"

	var dict = tile.to_dict()

	assert_not_null(dict, "Dictionary should be created")
	assert_true(dict.has("position"), "Should have position")
	assert_eq(dict["position"]["x"], 10, "X position correct")
	assert_eq(dict["position"]["y"], 20, "Y position correct")
	assert_eq(dict["position"]["z"], 1, "Z position correct")
	assert_eq(dict["tile_type"], "RESIDENTIAL", "Tile type correct")
	assert_eq(dict["terrain"], "BUILDING", "Terrain correct")
	assert_eq(dict["owner_id"], 3, "Owner ID correct")
	assert_almost_eq(dict["scavenge_value"], 75.5, 0.01, "Scavenge value correct")
	assert_true(dict["has_building"], "Has building flag correct")
	assert_eq(dict["building_id"], "barracks_01", "Building ID correct")

func test_tile_from_dict():
	var dict = {
		"position": {"x": 15, "y": 25, "z": 2},
		"tile_type": "COMMERCIAL",
		"terrain": "RUBBLE",
		"owner_id": 5,
		"scavenge_value": 42.0,
		"has_building": false,
		"building_id": "",
		"movement_cost": 3,
		"cover_value": 1,
		"elevation": 5,
		"is_passable": true,
		"is_water": false,
		"unique_location_id": "test_location"
	}

	var restored = Tile.from_dict(dict)

	assert_not_null(restored, "Tile should be created from dict")
	assert_eq(restored.position, Vector3i(15, 25, 2), "Position restored")
	assert_eq(restored.tile_type, Tile.TileType.COMMERCIAL, "Tile type restored")
	assert_eq(restored.terrain, Tile.TerrainType.RUBBLE, "Terrain restored")
	assert_eq(restored.owner_id, 5, "Owner ID restored")
	assert_almost_eq(restored.scavenge_value, 42.0, 0.01, "Scavenge value restored")
	assert_false(restored.has_building, "Has building restored")
	assert_eq(restored.movement_cost, 3, "Movement cost restored")
	assert_eq(restored.cover_value, 1, "Cover value restored")
	assert_eq(restored.elevation, 5, "Elevation restored")
	assert_true(restored.is_passable, "Is passable restored")
	assert_false(restored.is_water, "Is water restored")
	assert_eq(restored.unique_location_id, "test_location", "Unique location ID restored")

func test_tile_serialization_round_trip():
	tile.tile_type = Tile.TileType.MILITARY
	tile.terrain = Tile.TerrainType.BUILDING
	tile.owner_id = 2
	tile.scavenge_value = 88.8

	var dict = tile.to_dict()
	var restored = Tile.from_dict(dict)

	assert_eq(restored.position, tile.position, "Position preserved")
	assert_eq(restored.tile_type, tile.tile_type, "Tile type preserved")
	assert_eq(restored.terrain, tile.terrain, "Terrain preserved")
	assert_eq(restored.owner_id, tile.owner_id, "Owner ID preserved")
	assert_almost_eq(restored.scavenge_value, tile.scavenge_value, 0.01, "Scavenge value preserved")

# ============================================================================
# HELPER METHOD TESTS
# ============================================================================

func test_get_defense_bonus():
	tile.cover_value = 2
	assert_eq(tile.get_defense_bonus(), 2, "Defense bonus should equal cover value")

func test_can_be_scavenged():
	tile.scavenge_value = 50.0
	assert_true(tile.can_be_scavenged(), "Tile with scavenge value can be scavenged")

	tile.scavenge_value = 0.0
	assert_false(tile.can_be_scavenged(), "Tile with no scavenge value cannot be scavenged")

func test_deplete_scavenge():
	tile.scavenge_value = 50.0

	var depleted = tile.deplete_scavenge(20.0)
	assert_almost_eq(depleted, 20.0, 0.01, "Should deplete 20.0")
	assert_almost_eq(tile.scavenge_value, 30.0, 0.01, "Scavenge value should decrease")

	depleted = tile.deplete_scavenge(50.0)
	assert_almost_eq(depleted, 30.0, 0.01, "Should deplete remaining 30.0")
	assert_almost_eq(tile.scavenge_value, 0.0, 0.01, "Scavenge value should be 0")

func test_deplete_scavenge_clamped():
	tile.scavenge_value = 10.0

	var depleted = tile.deplete_scavenge(50.0)
	assert_almost_eq(depleted, 10.0, 0.01, "Should only deplete available amount")
	assert_almost_eq(tile.scavenge_value, 0.0, 0.01, "Should clamp to 0")

func test_is_controlled():
	tile.owner_id = -1
	assert_false(tile.is_controlled(), "Neutral tile is not controlled")

	tile.owner_id = 0
	assert_true(tile.is_controlled(), "Faction-owned tile is controlled")

	tile.owner_id = 5
	assert_true(tile.is_controlled(), "Any faction ID >= 0 is controlled")

func test_is_neutral():
	tile.owner_id = -1
	assert_true(tile.is_neutral(), "Owner -1 is neutral")

	tile.owner_id = 0
	assert_false(tile.is_neutral(), "Owner 0 is not neutral")

func test_get_movement_penalty():
	tile.movement_cost = 1
	assert_almost_eq(tile.get_movement_penalty(), 1.0, 0.01, "Movement cost 1 = 1.0x penalty")

	tile.movement_cost = 2
	assert_almost_eq(tile.get_movement_penalty(), 2.0, 0.01, "Movement cost 2 = 2.0x penalty")

func test_is_valid_position():
	var valid_tile = Tile.new(Vector3i(0, 0, 0))
	assert_true(valid_tile.is_valid_position(), "0,0,0 is valid")

	var edge_tile = Tile.new(Vector3i(199, 199, 2))
	assert_true(edge_tile.is_valid_position(), "199,199,2 is valid (edge)")

	var invalid_tile = Tile.new(Vector3i(200, 0, 0))
	assert_false(invalid_tile.is_valid_position(), "200,0,0 is invalid (out of bounds)")

	var invalid_z_tile = Tile.new(Vector3i(0, 0, 3))
	assert_false(invalid_z_tile.is_valid_position(), "0,0,3 is invalid (z out of bounds)")

func test_to_string():
	tile.tile_type = Tile.TileType.RESIDENTIAL
	tile.terrain = Tile.TerrainType.BUILDING
	tile.owner_id = 3

	var string_repr = tile._to_string()
	assert_true(string_repr.contains("Tile"), "String should contain 'Tile'")
	assert_true(string_repr.contains("RESIDENTIAL"), "String should contain tile type")
	assert_true(string_repr.contains("BUILDING"), "String should contain terrain")

# ============================================================================
# PROPERTY TESTS
# ============================================================================

func test_tile_properties_settable():
	tile.tile_type = Tile.TileType.MEDICAL
	tile.terrain = Tile.TerrainType.WATER
	tile.owner_id = 7
	tile.scavenge_value = 99.9
	tile.has_building = true
	tile.building_id = "hospital_01"
	tile.movement_cost = 5
	tile.cover_value = 3
	tile.elevation = 10
	tile.is_passable = false
	tile.is_water = true
	tile.unique_location_id = "unique_loc"

	assert_eq(tile.tile_type, Tile.TileType.MEDICAL, "Tile type set")
	assert_eq(tile.terrain, Tile.TerrainType.WATER, "Terrain set")
	assert_eq(tile.owner_id, 7, "Owner ID set")
	assert_almost_eq(tile.scavenge_value, 99.9, 0.01, "Scavenge value set")
	assert_true(tile.has_building, "Has building set")
	assert_eq(tile.building_id, "hospital_01", "Building ID set")
	assert_eq(tile.movement_cost, 5, "Movement cost set")
	assert_eq(tile.cover_value, 3, "Cover value set")
	assert_eq(tile.elevation, 10, "Elevation set")
	assert_false(tile.is_passable, "Is passable set")
	assert_true(tile.is_water, "Is water set")
	assert_eq(tile.unique_location_id, "unique_loc", "Unique location ID set")

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

func test_empty_dict_deserialization():
	var empty_dict = {}
	var tile_from_empty = Tile.from_dict(empty_dict)

	assert_not_null(tile_from_empty, "Should create tile from empty dict")
	assert_eq(tile_from_empty.position, Vector3i.ZERO, "Should have default position")
	assert_eq(tile_from_empty.owner_id, -1, "Should have default owner")

func test_partial_dict_deserialization():
	var partial_dict = {
		"position": {"x": 5, "y": 10, "z": 1},
		"tile_type": "RUINS"
	}

	var tile_from_partial = Tile.from_dict(partial_dict)

	assert_eq(tile_from_partial.position, Vector3i(5, 10, 1), "Position set from partial dict")
	assert_eq(tile_from_partial.tile_type, Tile.TileType.RUINS, "Tile type set from partial dict")
	assert_eq(tile_from_partial.owner_id, -1, "Default owner for missing field")
