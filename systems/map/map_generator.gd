class_name MapGenerator
extends RefCounted

## Procedural city map generator
## Generates coherent city maps with districts, roads, unique features, and multi-layer structure

const MapTile = preload("res://systems/map/tile.gd")
const MapData = preload("res://systems/map/map_data.gd")

## Configuration for map generation
class GenerationConfig:
	var width: int = 200
	var height: int = 200
	var seed_value: int = 0
	var rng: RandomNumberGenerator

	# Downtown settings
	var downtown_center: Vector2
	var downtown_radius: float = 30.0
	var max_density_distance: float = 100.0  # Distance where density reaches minimum

	# District probabilities
	var residential_weight: float = 0.5
	var commercial_weight: float = 0.2
	var industrial_weight: float = 0.2
	var park_weight: float = 0.1

	# Road network settings
	var major_road_spacing: int = 20  # Grid spacing for major roads
	var minor_road_density: float = 0.3  # Probability of minor roads

	# Unique features (probabilities)
	var unique_features: Dictionary = {
		"airport": 0.6,
		"seaport": 0.4,
		"train_station": 0.8,
		"steelworks": 0.5,
		"automotive_plant": 0.5,
		"chemical_plant": 0.4,
		"power_plant": 0.7,
		"museum": 0.6,
		"tv_station": 0.5,
		"radio_station": 0.6,
		"newspaper_printer": 0.5,
		"university": 0.6,
		"hospital": 0.7,
		"sports_stadium": 0.5
	}

	# Terrain features
	var river_probability: float = 0.4
	var beach_probability: float = 0.3

	# Underground settings
	var subway_lines: int = 3  # Number of subway lines
	var tunnel_density: float = 0.2  # Density of utility tunnels

	# Elevated settings
	var tall_building_density: float = 0.3  # In high-density areas
	var bridge_probability: float = 0.4  # Between adjacent tall buildings

	# Hostile units
	var raider_gang_count: int = 15
	var rogue_robot_count: int = 10

	func _init(seed_val: int = 0):
		seed_value = seed_val
		rng = RandomNumberGenerator.new()
		rng.seed = seed_value
		downtown_center = Vector2(width / 2.0, height / 2.0)

## Zone types for district generation
enum ZoneType {
	RESIDENTIAL_LOW,
	RESIDENTIAL_MEDIUM,
	RESIDENTIAL_HIGH,
	COMMERCIAL,
	INDUSTRIAL_GENERIC,
	INDUSTRIAL_SPECIALIZED,
	PARK,
	DOWNTOWN
}

## Generated map data
class GeneratedMapData:
	var tiles: Dictionary = {}  # Vector3i -> MapTile
	var zones: Dictionary = {}  # Vector2i -> ZoneType
	var roads: Array[Vector2i] = []
	var unique_locations: Array[Dictionary] = []  # {type: String, position: Vector3i}
	var subway_network: Array[Array] = []  # Array of subway lines (arrays of Vector3i)
	var tall_buildings: Array[Vector3i] = []
	var bridges: Array[Dictionary] = []  # {from: Vector3i, to: Vector3i}
	var terrain_features: Array[Dictionary] = []  # {type: String, positions: Array[Vector2i]}
	var hostile_spawns: Array[Dictionary] = []  # {type: String, position: Vector3i}

var config: GenerationConfig
var map_data: GeneratedMapData
var noise: FastNoiseLite

## Generate a complete city map
func generate_city_map(width: int, height: int, seed_value: int) -> MapData:
	print("MapGenerator: Starting city generation with seed ", seed_value)

	# Initialize configuration
	config = GenerationConfig.new(seed_value)
	config.width = width
	config.height = height
	config.downtown_center = Vector2(width / 2.0, height / 2.0)

	map_data = GeneratedMapData.new()

	# Setup noise generator
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05

	# Generation phases
	print("MapGenerator: Phase 1 - Terrain features")
	_generate_terrain_features()

	print("MapGenerator: Phase 2 - District zones")
	_generate_districts()

	print("MapGenerator: Phase 3 - Road network")
	_generate_road_network()

	print("MapGenerator: Phase 4 - Ground level buildings")
	_place_buildings()

	print("MapGenerator: Phase 5 - Unique locations")
	_place_unique_locations()

	print("MapGenerator: Phase 6 - Underground layer")
	_generate_underground_layer()

	print("MapGenerator: Phase 7 - Elevated layer")
	_generate_elevated_layer()

	print("MapGenerator: Phase 8 - Hostile units")
	_spawn_hostile_units()

	# Convert to MapData
	print("MapGenerator: Converting to MapData format")
	var result = _convert_to_map_data()

	print("MapGenerator: Generation complete!")
	return result

## Phase 1: Generate terrain features (rivers, beaches)
func _generate_terrain_features() -> void:
	# Rivers
	if config.rng.randf() < config.river_probability:
		var river = _generate_river()
		map_data.terrain_features.append({
			"type": "river",
			"positions": river
		})

	# Beaches (along edges)
	if config.rng.randf() < config.beach_probability:
		var beach = _generate_beach()
		map_data.terrain_features.append({
			"type": "beach",
			"positions": beach
		})

func _generate_river() -> Array[Vector2i]:
	var river: Array[Vector2i] = []

	# Simple river: start from one edge, meander across map
	var start_edge = config.rng.randi_range(0, 3)  # 0=north, 1=east, 2=south, 3=west
	var x: int
	var y: int

	match start_edge:
		0:  # North edge
			x = config.rng.randi_range(config.width / 4, 3 * config.width / 4)
			y = 0
		2:  # South edge
			x = config.rng.randi_range(config.width / 4, 3 * config.width / 4)
			y = config.height - 1
		1:  # East edge
			x = config.width - 1
			y = config.rng.randi_range(config.height / 4, 3 * config.height / 4)
		3:  # West edge
			x = 0
			y = config.rng.randi_range(config.height / 4, 3 * config.height / 4)

	var pos = Vector2i(x, y)
	var direction = _get_river_target_direction(start_edge)
	var width = config.rng.randi_range(2, 4)

	# Meander across the map
	for i in range(max(config.width, config.height)):
		# Add river tiles with width
		for dx in range(-width / 2, width / 2 + 1):
			for dy in range(-width / 2, width / 2 + 1):
				var river_pos = Vector2i(pos.x + dx, pos.y + dy)
				if _is_valid_position(river_pos):
					river.append(river_pos)

		# Move in general direction with meandering
		var meander = Vector2(config.rng.randf_range(-0.5, 0.5), config.rng.randf_range(-0.5, 0.5))
		direction = (direction + meander).normalized()

		pos += Vector2i(roundi(direction.x), roundi(direction.y))

		# Check if we've reached the opposite edge
		if pos.x < 0 or pos.x >= config.width or pos.y < 0 or pos.y >= config.height:
			break

	return river

func _get_river_target_direction(start_edge: int) -> Vector2:
	match start_edge:
		0: return Vector2(0, 1)  # North -> South
		2: return Vector2(0, -1)  # South -> North
		1: return Vector2(-1, 0)  # East -> West
		3: return Vector2(1, 0)  # West -> East
	return Vector2(0, 1)

func _generate_beach() -> Array[Vector2i]:
	var beach: Array[Vector2i] = []

	# Pick a random edge
	var edge = config.rng.randi_range(0, 3)
	var beach_width = config.rng.randi_range(3, 6)
	var beach_length = config.rng.randi_range(config.width / 3, 2 * config.width / 3)

	match edge:
		0:  # North edge
			var start_x = config.rng.randi_range(0, config.width - beach_length)
			for x in range(start_x, start_x + beach_length):
				for y in range(beach_width):
					beach.append(Vector2i(x, y))
		2:  # South edge
			var start_x = config.rng.randi_range(0, config.width - beach_length)
			for x in range(start_x, start_x + beach_length):
				for y in range(config.height - beach_width, config.height):
					beach.append(Vector2i(x, y))
		1:  # East edge
			var start_y = config.rng.randi_range(0, config.height - beach_length)
			for y in range(start_y, start_y + beach_length):
				for x in range(config.width - beach_width, config.width):
					beach.append(Vector2i(x, y))
		3:  # West edge
			var start_y = config.rng.randi_range(0, config.height - beach_length)
			for y in range(start_y, start_y + beach_length):
				for x in range(beach_width):
					beach.append(Vector2i(x, y))

	return beach

## Phase 2: Generate districts with density gradient
func _generate_districts() -> void:
	for y in range(config.height):
		for x in range(config.width):
			var pos = Vector2i(x, y)

			# Skip if this is a terrain feature
			if _is_terrain_feature(pos):
				continue

			# Calculate density based on distance from downtown
			var distance = pos.distance_to(config.downtown_center)
			var density = _calculate_density(distance)

			# Determine zone type based on density and noise
			var zone_type = _determine_zone_type(pos, density)
			map_data.zones[pos] = zone_type

func _calculate_density(distance: float) -> float:
	# Density decreases with distance from downtown
	# 1.0 at center, 0.0 at max_density_distance
	var density = 1.0 - clamp(distance / config.max_density_distance, 0.0, 1.0)

	# Apply noise for organic variation
	var noise_value = (noise.get_noise_2d(distance * 0.1, distance * 0.1) + 1.0) / 2.0
	density = density * 0.7 + noise_value * 0.3  # 70% gradient, 30% noise

	return clamp(density, 0.0, 1.0)

func _determine_zone_type(pos: Vector2i, density: float) -> ZoneType:
	var noise_value = noise.get_noise_2d(pos.x, pos.y)

	# Downtown core (very high density)
	if density > 0.9:
		return ZoneType.DOWNTOWN

	# High density (mix of high-rise residential and commercial)
	elif density > 0.7:
		if noise_value > 0.3:
			return ZoneType.COMMERCIAL
		else:
			return ZoneType.RESIDENTIAL_HIGH

	# Medium density
	elif density > 0.4:
		if noise_value > 0.4:
			return ZoneType.COMMERCIAL
		elif noise_value > 0.0:
			return ZoneType.RESIDENTIAL_MEDIUM
		elif noise_value > -0.4:
			return ZoneType.INDUSTRIAL_GENERIC
		else:
			return ZoneType.PARK

	# Low density (suburban/industrial/parks)
	elif density > 0.2:
		if noise_value > 0.3:
			return ZoneType.RESIDENTIAL_LOW
		elif noise_value > -0.2:
			return ZoneType.INDUSTRIAL_GENERIC
		else:
			return ZoneType.PARK

	# Rural/outskirts
	else:
		if noise_value > 0.5:
			return ZoneType.RESIDENTIAL_LOW
		elif noise_value > 0.0:
			return ZoneType.PARK
		else:
			return ZoneType.INDUSTRIAL_GENERIC

## Phase 3: Generate coherent road network
func _generate_road_network() -> void:
	# Major roads (grid pattern)
	_generate_major_roads()

	# Minor roads (connecting blocks)
	_generate_minor_roads()

	# Circular downtown roads
	_generate_downtown_loops()

func _generate_major_roads() -> void:
	# Vertical major roads
	for x in range(0, config.width, config.major_road_spacing):
		for y in range(config.height):
			var pos = Vector2i(x, y)
			if not _is_terrain_feature(pos):
				map_data.roads.append(pos)

	# Horizontal major roads
	for y in range(0, config.height, config.major_road_spacing):
		for x in range(config.width):
			var pos = Vector2i(x, y)
			if not _is_terrain_feature(pos):
				map_data.roads.append(pos)

func _generate_minor_roads() -> void:
	# Add minor roads within blocks
	for y in range(0, config.height, config.major_road_spacing):
		for x in range(0, config.width, config.major_road_spacing):
			_fill_block_with_roads(Vector2i(x, y))

func _fill_block_with_roads(block_origin: Vector2i) -> void:
	var block_size = config.major_road_spacing

	# Vertical minor roads
	for offset_x in range(5, block_size, 10):
		var x = block_origin.x + offset_x
		if x >= config.width:
			continue

		for offset_y in range(block_size):
			var y = block_origin.y + offset_y
			if y >= config.height:
				continue

			var pos = Vector2i(x, y)
			if config.rng.randf() < config.minor_road_density and not _is_terrain_feature(pos):
				map_data.roads.append(pos)

	# Horizontal minor roads
	for offset_y in range(5, block_size, 10):
		var y = block_origin.y + offset_y
		if y >= config.height:
			continue

		for offset_x in range(block_size):
			var x = block_origin.x + offset_x
			if x >= config.width:
				continue

			var pos = Vector2i(x, y)
			if config.rng.randf() < config.minor_road_density and not _is_terrain_feature(pos):
				map_data.roads.append(pos)

func _generate_downtown_loops() -> void:
	# Create circular roads around downtown center
	var radii = [15, 25, 35]

	for radius in radii:
		var circumference = 2 * PI * radius
		var step = 360.0 / circumference

		for angle_deg in range(0, 360, int(step)):
			var angle_rad = deg_to_rad(angle_deg)
			var x = int(config.downtown_center.x + cos(angle_rad) * radius)
			var y = int(config.downtown_center.y + sin(angle_rad) * radius)
			var pos = Vector2i(x, y)

			if _is_valid_position(pos) and not _is_terrain_feature(pos):
				map_data.roads.append(pos)

## Phase 4: Place buildings on ground level
func _place_buildings() -> void:
	for zone_pos in map_data.zones.keys():
		# Skip roads and terrain features
		if _is_road(zone_pos) or _is_terrain_feature(zone_pos):
			continue

		var zone_type = map_data.zones[zone_pos]
		var tile_type = _zone_to_tile_type(zone_type)

		# Create ground level tile
		var tile_3d = Vector3i(zone_pos.x, zone_pos.y, 1)
		var tile = _create_tile(tile_3d, tile_type)
		map_data.tiles[tile_3d] = tile

func _zone_to_tile_type(zone_type: ZoneType) -> MapTile.TileType:
	match zone_type:
		ZoneType.RESIDENTIAL_LOW:
			return MapTile.TileType.RESIDENTIAL
		ZoneType.RESIDENTIAL_MEDIUM:
			return MapTile.TileType.RESIDENTIAL
		ZoneType.RESIDENTIAL_HIGH:
			return MapTile.TileType.RESIDENTIAL
		ZoneType.COMMERCIAL:
			return MapTile.TileType.COMMERCIAL
		ZoneType.INDUSTRIAL_GENERIC:
			return MapTile.TileType.INDUSTRIAL
		ZoneType.INDUSTRIAL_SPECIALIZED:
			return MapTile.TileType.INDUSTRIAL
		ZoneType.PARK:
			return MapTile.TileType.PARK
		ZoneType.DOWNTOWN:
			return MapTile.TileType.COMMERCIAL

	return MapTile.TileType.RESIDENTIAL

## Phase 5: Place unique locations
func _place_unique_locations() -> void:
	for feature_name in config.unique_features.keys():
		var probability = config.unique_features[feature_name]

		if config.rng.randf() < probability:
			var location = _find_suitable_location_for_feature(feature_name)
			if location != Vector3i(-1, -1, -1):
				map_data.unique_locations.append({
					"type": feature_name,
					"position": location
				})

func _find_suitable_location_for_feature(feature_name: String) -> Vector3i:
	# Different features have different placement requirements
	var attempts = 100

	for i in range(attempts):
		var x = config.rng.randi_range(10, config.width - 10)
		var y = config.rng.randi_range(10, config.height - 10)
		var pos_2d = Vector2i(x, y)
		var pos_3d = Vector3i(x, y, 1)

		# Skip roads and terrain features
		if _is_road(pos_2d) or _is_terrain_feature(pos_2d):
			continue

		# Check if there's space (3x3 area)
		if not _has_clear_area(pos_2d, 3):
			continue

		# Feature-specific placement
		match feature_name:
			"airport":
				# Needs large clear area on outskirts
				if pos_2d.distance_to(config.downtown_center) < 60:
					continue
				if not _has_clear_area(pos_2d, 8):
					continue

			"seaport":
				# Must be near water (beach or river)
				if not _is_near_water(pos_2d, 5):
					continue

			"train_station":
				# Should be near downtown but not in the center
				var distance = pos_2d.distance_to(config.downtown_center)
				if distance < 20 or distance > 50:
					continue

			"steelworks", "automotive_plant", "chemical_plant", "power_plant":
				# Industrial areas, away from downtown
				if pos_2d.distance_to(config.downtown_center) < 40:
					continue
				var zone = map_data.zones.get(pos_2d, ZoneType.RESIDENTIAL_LOW)
				if zone != ZoneType.INDUSTRIAL_GENERIC:
					continue

			"museum", "tv_station", "radio_station", "newspaper_printer":
				# Downtown or commercial areas
				var distance = pos_2d.distance_to(config.downtown_center)
				if distance > 50:
					continue

			"university", "hospital":
				# Medium density areas
				var distance = pos_2d.distance_to(config.downtown_center)
				if distance < 20 or distance > 70:
					continue

			"sports_stadium":
				# Needs large area, medium distance from downtown
				var distance = pos_2d.distance_to(config.downtown_center)
				if distance < 30 or distance > 60:
					continue
				if not _has_clear_area(pos_2d, 6):
					continue

		return pos_3d

	return Vector3i(-1, -1, -1)

## Phase 6: Generate underground layer (subways and utility tunnels)
func _generate_underground_layer() -> void:
	# Generate subway lines
	for i in range(config.subway_lines):
		var line = _generate_subway_line(i)
		map_data.subway_network.append(line)

	# Generate utility tunnels
	_generate_utility_tunnels()

func _generate_subway_line(line_index: int) -> Array:
	var line: Array = []

	# Each subway line connects downtown to outskirts
	var start_pos = config.downtown_center + Vector2(
		config.rng.randf_range(-20, 20),
		config.rng.randf_range(-20, 20)
	)

	# Pick a direction toward an edge
	var angle = line_index * (360.0 / config.subway_lines) + config.rng.randf_range(-30, 30)
	var direction = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))

	var current_pos = start_pos
	var distance_traveled = 0.0
	var max_distance = 100.0

	while distance_traveled < max_distance:
		var pos_2d = Vector2i(roundi(current_pos.x), roundi(current_pos.y))
		var pos_3d = Vector3i(pos_2d.x, pos_2d.y, 0)  # Underground layer

		if _is_valid_position(pos_2d):
			line.append(pos_3d)

			# Create tunnel tile
			if not map_data.tiles.has(pos_3d):
				var tile = _create_tile(pos_3d, MapTile.TileType.INFRASTRUCTURE)
				tile.terrain = MapTile.TerrainType.TUNNEL
				map_data.tiles[pos_3d] = tile

		# Move along the line with slight variation
		var variation = Vector2(config.rng.randf_range(-0.3, 0.3), config.rng.randf_range(-0.3, 0.3))
		current_pos += (direction + variation).normalized() * 2.0
		distance_traveled += 2.0

	return line

func _generate_utility_tunnels() -> void:
	# Connect major buildings with utility tunnels
	for y in range(0, config.height, 15):
		for x in range(0, config.width, 15):
			if config.rng.randf() < config.tunnel_density:
				_create_tunnel_segment(Vector2i(x, y))

func _create_tunnel_segment(start: Vector2i) -> void:
	var length = config.rng.randi_range(5, 15)
	var direction = Vector2i(
		config.rng.randi_range(-1, 1),
		config.rng.randi_range(-1, 1)
	)

	if direction == Vector2i.ZERO:
		direction = Vector2i(1, 0)

	var current = start
	for i in range(length):
		var pos_3d = Vector3i(current.x, current.y, 0)

		if _is_valid_position(current):
			if not map_data.tiles.has(pos_3d):
				var tile = _create_tile(pos_3d, MapTile.TileType.INFRASTRUCTURE)
				tile.terrain = MapTile.TerrainType.TUNNEL
				map_data.tiles[pos_3d] = tile

		current += direction

## Phase 7: Generate elevated layer (tall buildings and bridges)
func _generate_elevated_layer() -> void:
	# Place tall buildings in high-density areas
	for zone_pos in map_data.zones.keys():
		var zone_type = map_data.zones[zone_pos]
		var distance = zone_pos.distance_to(config.downtown_center)

		# Only in high-density areas
		if distance > 50:
			continue

		if zone_type == ZoneType.DOWNTOWN or zone_type == ZoneType.RESIDENTIAL_HIGH or zone_type == ZoneType.COMMERCIAL:
			if config.rng.randf() < config.tall_building_density:
				var pos_3d = Vector3i(zone_pos.x, zone_pos.y, 2)  # Elevated layer
				map_data.tall_buildings.append(pos_3d)

				# Create rooftop tile
				var tile = _create_tile(pos_3d, MapTile.TileType.RUINS)
				tile.terrain = MapTile.TerrainType.ROOFTOP
				map_data.tiles[pos_3d] = tile

	# Create bridges between adjacent tall buildings
	_generate_bridges()

func _generate_bridges() -> void:
	for building_pos in map_data.tall_buildings:
		# Check adjacent positions for other tall buildings
		var neighbors = [
			Vector3i(building_pos.x + 1, building_pos.y, 2),
			Vector3i(building_pos.x - 1, building_pos.y, 2),
			Vector3i(building_pos.x, building_pos.y + 1, 2),
			Vector3i(building_pos.x, building_pos.y - 1, 2),
			Vector3i(building_pos.x + 1, building_pos.y + 1, 2),
			Vector3i(building_pos.x + 1, building_pos.y - 1, 2),
			Vector3i(building_pos.x - 1, building_pos.y + 1, 2),
			Vector3i(building_pos.x - 1, building_pos.y - 1, 2),
		]

		for neighbor_pos in neighbors:
			if map_data.tall_buildings.has(neighbor_pos):
				if config.rng.randf() < config.bridge_probability:
					# Check if bridge doesn't already exist
					var bridge_exists = false
					for bridge in map_data.bridges:
						if (bridge["from"] == building_pos and bridge["to"] == neighbor_pos) or \
						   (bridge["from"] == neighbor_pos and bridge["to"] == building_pos):
							bridge_exists = true
							break

					if not bridge_exists:
						map_data.bridges.append({
							"from": building_pos,
							"to": neighbor_pos
						})

## Phase 8: Spawn hostile units
func _spawn_hostile_units() -> void:
	# Raider gangs
	for i in range(config.raider_gang_count):
		var spawn_pos = _find_hostile_spawn_location("raider")
		if spawn_pos != Vector3i(-1, -1, -1):
			map_data.hostile_spawns.append({
				"type": "raider_gang",
				"position": spawn_pos,
				"count": config.rng.randi_range(3, 8)
			})

	# Rogue robots
	for i in range(config.rogue_robot_count):
		var spawn_pos = _find_hostile_spawn_location("robot")
		if spawn_pos != Vector3i(-1, -1, -1):
			map_data.hostile_spawns.append({
				"type": "rogue_robot",
				"position": spawn_pos,
				"count": config.rng.randi_range(1, 4)
			})

func _find_hostile_spawn_location(enemy_type: String) -> Vector3i:
	var attempts = 50

	for i in range(attempts):
		var x = config.rng.randi_range(5, config.width - 5)
		var y = config.rng.randi_range(5, config.height - 5)
		var pos_2d = Vector2i(x, y)
		var pos_3d = Vector3i(x, y, 1)

		# Not on roads
		if _is_road(pos_2d):
			continue

		# Raiders prefer buildings, robots prefer industrial areas
		var zone = map_data.zones.get(pos_2d, ZoneType.PARK)

		match enemy_type:
			"raider":
				# Raiders in medium-density areas
				var distance = pos_2d.distance_to(config.downtown_center)
				if distance < 30 or distance > 80:
					continue
			"robot":
				# Robots in industrial or downtown areas
				if zone != ZoneType.INDUSTRIAL_GENERIC and zone != ZoneType.DOWNTOWN:
					continue

		# Check not too close to other hostiles
		var too_close = false
		for spawn in map_data.hostile_spawns:
			if spawn["position"].distance_to(pos_3d) < 15:
				too_close = true
				break

		if not too_close:
			return pos_3d

	return Vector3i(-1, -1, -1)

## Convert generated data to MapData format
func _convert_to_map_data() -> MapData:
	var result = MapData.new()
	result.initialize(config.width, config.height, 3)

	# Set all generated tiles
	for pos in map_data.tiles.keys():
		var tile = map_data.tiles[pos]
		result.set_tile(pos, tile)

	# Set road tiles
	for road_pos in map_data.roads:
		var pos_3d = Vector3i(road_pos.x, road_pos.y, 1)
		var tile = _create_tile(pos_3d, MapTile.TileType.STREET)
		tile.terrain = MapTile.TerrainType.STREET
		result.set_tile(pos_3d, tile)

	# Set terrain feature tiles
	for feature in map_data.terrain_features:
		var terrain_type = MapTile.TerrainType.WATER if feature["type"] == "river" else MapTile.TerrainType.WATER
		for pos_2d in feature["positions"]:
			var pos_3d = Vector3i(pos_2d.x, pos_2d.y, 1)
			var tile = _create_tile(pos_3d, MapTile.TileType.PARK)
			tile.terrain = terrain_type
			tile.is_water = true
			result.set_tile(pos_3d, tile)

	return result

## Utility functions
func _create_tile(position: Vector3i, tile_type: MapTile.TileType) -> MapTile:
	var tile = MapTile.new(position)
	tile.tile_type = tile_type

	# Set terrain type based on tile type
	match tile_type:
		MapTile.TileType.STREET:
			tile.terrain = MapTile.TerrainType.STREET
			tile.movement_cost = 1
		MapTile.TileType.RESIDENTIAL, MapTile.TileType.COMMERCIAL, MapTile.TileType.INDUSTRIAL:
			tile.terrain = MapTile.TerrainType.BUILDING
			tile.movement_cost = 2
			tile.cover_value = 2
			tile.has_building = true
		MapTile.TileType.PARK:
			tile.terrain = MapTile.TerrainType.OPEN_GROUND
			tile.movement_cost = 1
		MapTile.TileType.INFRASTRUCTURE:
			tile.terrain = MapTile.TerrainType.TUNNEL
			tile.movement_cost = 2
		MapTile.TileType.RUINS:
			# For elevated/rooftop tiles
			if position.z == 2:
				tile.terrain = MapTile.TerrainType.ROOFTOP
				tile.movement_cost = 2
				tile.cover_value = 3
			else:
				tile.terrain = MapTile.TerrainType.RUBBLE
				tile.movement_cost = 2
				tile.cover_value = 1

	# Set scavenge value
	tile.scavenge_value = config.rng.randf_range(0, 50)

	return tile

func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < config.width and pos.y >= 0 and pos.y < config.height

func _is_road(pos: Vector2i) -> bool:
	return map_data.roads.has(pos)

func _is_terrain_feature(pos: Vector2i) -> bool:
	for feature in map_data.terrain_features:
		if feature["positions"].has(pos):
			return true
	return false

func _is_near_water(pos: Vector2i, max_distance: int) -> bool:
	for feature in map_data.terrain_features:
		if feature["type"] == "river" or feature["type"] == "beach":
			for water_pos in feature["positions"]:
				if pos.distance_to(water_pos) <= max_distance:
					return true
	return false

func _has_clear_area(center: Vector2i, size: int) -> bool:
	for dx in range(-size / 2, size / 2 + 1):
		for dy in range(-size / 2, size / 2 + 1):
			var check_pos = Vector2i(center.x + dx, center.y + dy)
			if not _is_valid_position(check_pos):
				return false
			if _is_road(check_pos) or _is_terrain_feature(check_pos):
				return false
			# Check if already has a unique location nearby
			for location in map_data.unique_locations:
				var location_2d = Vector2i(location["position"].x, location["position"].y)
				if location_2d.distance_to(check_pos) < size * 2:
					return false
	return true
