class_name MovementSystem
extends Node

## Movement System - Handles unit movement with terrain costs
## Part of Workstream 2.3: Unit System

# Reference to UnitManager
var _unit_manager: UnitManager = null

# Reference to MapData (stubbed for testing)
var _map_data = null

# Mock EventBus for events
var _event_bus = null

# Movement cost cache (position -> cost)
var _reachable_cache: Dictionary = {}

# Terrain movement costs by movement type
const TERRAIN_COSTS = {
	"plains": {
		UnitStats.MovementType.INFANTRY: 1,
		UnitStats.MovementType.WHEELED: 1,
		UnitStats.MovementType.TRACKED: 1,
		UnitStats.MovementType.AIRBORNE: 1
	},
	"forest": {
		UnitStats.MovementType.INFANTRY: 2,
		UnitStats.MovementType.WHEELED: 3,
		UnitStats.MovementType.TRACKED: 2,
		UnitStats.MovementType.AIRBORNE: 1
	},
	"hills": {
		UnitStats.MovementType.INFANTRY: 2,
		UnitStats.MovementType.WHEELED: 3,
		UnitStats.MovementType.TRACKED: 2,
		UnitStats.MovementType.AIRBORNE: 1
	},
	"mountains": {
		UnitStats.MovementType.INFANTRY: 3,
		UnitStats.MovementType.WHEELED: 0,  # Impassable
		UnitStats.MovementType.TRACKED: 3,
		UnitStats.MovementType.AIRBORNE: 1
	},
	"water": {
		UnitStats.MovementType.INFANTRY: 0,  # Impassable
		UnitStats.MovementType.WHEELED: 0,   # Impassable
		UnitStats.MovementType.TRACKED: 0,   # Impassable
		UnitStats.MovementType.AIRBORNE: 1
	},
	"road": {
		UnitStats.MovementType.INFANTRY: 1,
		UnitStats.MovementType.WHEELED: 1,
		UnitStats.MovementType.TRACKED: 1,
		UnitStats.MovementType.AIRBORNE: 1
	},
	"ruins": {
		UnitStats.MovementType.INFANTRY: 2,
		UnitStats.MovementType.WHEELED: 2,
		UnitStats.MovementType.TRACKED: 2,
		UnitStats.MovementType.AIRBORNE: 1
	}
}

## Initialize movement system
func _ready():
	pass

## Set unit manager (dependency injection)
func set_unit_manager(manager: UnitManager) -> void:
	_unit_manager = manager

## Set map data (dependency injection)
func set_map_data(map_data) -> void:
	_map_data = map_data

## Set event bus (dependency injection)
func set_event_bus(event_bus) -> void:
	_event_bus = event_bus

## Move unit to target position
func move_unit(unit_id: int, target_position: Vector3i) -> bool:
	if not _unit_manager:
		push_error("MovementSystem: UnitManager not set")
		return false

	var unit = _unit_manager.get_unit(unit_id)
	if not unit:
		push_warning("MovementSystem: Unit %d not found" % unit_id)
		_emit_event("unit_move_failed", [unit_id, target_position, "unit_not_found"])
		return false

	# Check if unit can move
	if not unit.can_move():
		_emit_event("unit_move_failed", [unit_id, target_position, "cannot_move"])
		return false

	# Check if destination is valid
	if not can_move_to(unit_id, target_position):
		_emit_event("unit_move_failed", [unit_id, target_position, "invalid_destination"])
		return false

	# Calculate movement cost
	var path = _find_path(unit.position, target_position, unit.stats.movement_type)
	if path.is_empty():
		_emit_event("unit_move_failed", [unit_id, target_position, "no_path"])
		return false

	var total_cost = _calculate_path_cost(unit, path)

	# Check if unit has enough movement
	if total_cost > unit.movement_remaining:
		_emit_event("unit_move_failed", [unit_id, target_position, "insufficient_movement"])
		return false

	# Move the unit
	var old_position = unit.position
	_unit_manager.set_position(unit_id, target_position)

	# Update unit movement state
	unit.movement_remaining -= total_cost
	unit.has_moved = true

	# Clear reachable cache for this unit
	_reachable_cache.erase(unit_id)

	# Emit move event
	_emit_event("unit_moved", [unit_id, old_position, target_position])

	return true

## Check if unit can move to target position
func can_move_to(unit_id: int, target_position: Vector3i) -> bool:
	if not _unit_manager:
		return false

	var unit = _unit_manager.get_unit(unit_id)
	if not unit:
		return false

	# Check if unit can move at all
	if not unit.can_move():
		return false

	# Check if destination is the same as current position
	if unit.position == target_position:
		return false

	# Check if destination is occupied by enemy
	var units_at_target = _unit_manager.get_units_at_position(target_position)
	for other_unit in units_at_target:
		if other_unit.faction_id != unit.faction_id:
			return false  # Enemy occupied

	# Check if path exists
	var path = _find_path(unit.position, target_position, unit.stats.movement_type)
	if path.is_empty():
		return false

	# Check if unit has enough movement points
	var cost = _calculate_path_cost(unit, path)
	if cost > unit.movement_remaining:
		return false

	return true

## Get movement cost between adjacent tiles
func get_movement_cost(unit: Unit, from: Vector3i, to: Vector3i) -> int:
	# Check if tiles are adjacent
	var distance = abs(to.x - from.x) + abs(to.y - from.y) + abs(to.z - from.z)
	if distance != 1:
		return 0  # Not adjacent

	# Get terrain type at destination
	var terrain_type = _get_terrain_type(to)

	# Get movement type
	var movement_type = unit.stats.movement_type

	# Get base cost
	var base_cost = _get_terrain_cost(terrain_type, movement_type)

	# Apply status effect modifiers
	var modifier = 1.0
	for effect in unit.status_effects:
		if effect.has("movement_cost_modifier"):
			modifier *= effect["movement_cost_modifier"]

	return int(base_cost * modifier)

## Get all reachable tiles for a unit
func get_reachable_tiles(unit_id: int) -> Array[Vector3i]:
	# Check cache first
	if _reachable_cache.has(unit_id):
		return _reachable_cache[unit_id].duplicate()

	if not _unit_manager:
		return []

	var unit = _unit_manager.get_unit(unit_id)
	if not unit:
		return []

	var reachable: Array[Vector3i] = []
	var movement_points = unit.movement_remaining

	# BFS to find all reachable tiles
	var visited = {}
	var queue = []
	queue.append({"pos": unit.position, "cost": 0})
	visited[_position_to_key(unit.position)] = 0

	while not queue.is_empty():
		var current = queue.pop_front()
		var current_pos = current["pos"]
		var current_cost = current["cost"]

		# Add to reachable list
		if current_pos != unit.position:
			reachable.append(current_pos)

		# Check all adjacent tiles
		var neighbors = _get_adjacent_positions(current_pos)
		for neighbor in neighbors:
			var move_cost = get_movement_cost(unit, current_pos, neighbor)

			# Skip if impassable
			if move_cost == 0:
				continue

			var new_cost = current_cost + move_cost

			# Skip if too expensive
			if new_cost > movement_points:
				continue

			var neighbor_key = _position_to_key(neighbor)

			# Skip if already visited with lower cost
			if visited.has(neighbor_key) and visited[neighbor_key] <= new_cost:
				continue

			# Check if tile is occupied by enemy
			var occupied_by_enemy = false
			var units_at_neighbor = _unit_manager.get_units_at_position(neighbor)
			for other_unit in units_at_neighbor:
				if other_unit.faction_id != unit.faction_id:
					occupied_by_enemy = true
					break

			if not occupied_by_enemy:
				visited[neighbor_key] = new_cost
				queue.append({"pos": neighbor, "cost": new_cost})

	# Cache result
	_reachable_cache[unit_id] = reachable.duplicate()

	return reachable

## Reset movement points for a unit
func reset_movement(unit_id: int) -> void:
	if not _unit_manager:
		return

	var unit = _unit_manager.get_unit(unit_id)
	if not unit:
		return

	unit.movement_remaining = unit.get_effective_movement()

	# Clear cache
	_reachable_cache.erase(unit_id)

## Clear all movement caches
func clear_cache() -> void:
	_reachable_cache.clear()

## Private helper methods

func _find_path(start: Vector3i, goal: Vector3i, movement_type: UnitStats.MovementType) -> Array[Vector3i]:
	# Stub pathfinding - for MVP, just check if goal is adjacent or use simple A*
	# Real implementation would query MapData.find_path()

	if _map_data and _map_data.has_method("find_path"):
		return _map_data.find_path(start, goal, movement_type)

	# Simple A* pathfinding for testing
	return _simple_astar(start, goal, movement_type)

func _simple_astar(start: Vector3i, goal: Vector3i, movement_type: UnitStats.MovementType) -> Array[Vector3i]:
	# Very simple A* implementation for testing
	var open_set = [start]
	var came_from = {}
	var g_score = {_position_to_key(start): 0}
	var f_score = {_position_to_key(start): _heuristic(start, goal)}

	while not open_set.is_empty():
		# Find node with lowest f_score
		var current = open_set[0]
		var current_key = _position_to_key(current)
		var lowest_f = f_score.get(current_key, INF)

		for node in open_set:
			var node_key = _position_to_key(node)
			var node_f = f_score.get(node_key, INF)
			if node_f < lowest_f:
				current = node
				current_key = node_key
				lowest_f = node_f

		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in _get_adjacent_positions(current):
			var terrain = _get_terrain_type(neighbor)
			var cost = _get_terrain_cost(terrain, movement_type)

			if cost == 0:  # Impassable
				continue

			var neighbor_key = _position_to_key(neighbor)
			var tentative_g = g_score.get(current_key, INF) + cost

			if tentative_g < g_score.get(neighbor_key, INF):
				came_from[neighbor_key] = current
				g_score[neighbor_key] = tentative_g
				f_score[neighbor_key] = tentative_g + _heuristic(neighbor, goal)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []  # No path found

func _reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = [current]
	var current_key = _position_to_key(current)

	while came_from.has(current_key):
		current = came_from[current_key]
		current_key = _position_to_key(current)
		path.insert(0, current)

	return path

func _heuristic(pos: Vector3i, goal: Vector3i) -> int:
	# Manhattan distance
	return abs(pos.x - goal.x) + abs(pos.y - goal.y) + abs(pos.z - goal.z)

func _calculate_path_cost(unit: Unit, path: Array[Vector3i]) -> int:
	if path.size() < 2:
		return 0

	var total_cost = 0
	for i in range(path.size() - 1):
		total_cost += get_movement_cost(unit, path[i], path[i + 1])

	return total_cost

func _get_adjacent_positions(pos: Vector3i) -> Array[Vector3i]:
	var adjacent: Array[Vector3i] = []

	# 4-directional movement (no diagonals)
	adjacent.append(Vector3i(pos.x + 1, pos.y, pos.z))
	adjacent.append(Vector3i(pos.x - 1, pos.y, pos.z))
	adjacent.append(Vector3i(pos.x, pos.y + 1, pos.z))
	adjacent.append(Vector3i(pos.x, pos.y - 1, pos.z))

	# For 3D movement, also check z-axis
	adjacent.append(Vector3i(pos.x, pos.y, pos.z + 1))
	adjacent.append(Vector3i(pos.x, pos.y, pos.z - 1))

	return adjacent

func _get_terrain_type(pos: Vector3i) -> String:
	# Stub - query MapData for actual terrain
	if _map_data and _map_data.has_method("get_terrain_type"):
		return _map_data.get_terrain_type(pos)

	# Default to plains for testing
	return "plains"

func _get_terrain_cost(terrain_type: String, movement_type: UnitStats.MovementType) -> int:
	if not TERRAIN_COSTS.has(terrain_type):
		return 1  # Default cost

	var costs = TERRAIN_COSTS[terrain_type]
	return costs.get(movement_type, 1)

func _position_to_key(pos: Vector3i) -> String:
	return "%d,%d,%d" % [pos.x, pos.y, pos.z]

func _emit_event(event_name: String, args: Array) -> void:
	if _event_bus and _event_bus.has_signal(event_name):
		match args.size():
			0:
				_event_bus.emit_signal(event_name)
			1:
				_event_bus.emit_signal(event_name, args[0])
			2:
				_event_bus.emit_signal(event_name, args[0], args[1])
			3:
				_event_bus.emit_signal(event_name, args[0], args[1], args[2])
			4:
				_event_bus.emit_signal(event_name, args[0], args[1], args[2], args[3])
