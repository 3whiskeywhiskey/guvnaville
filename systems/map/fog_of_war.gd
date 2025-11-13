extends RefCounted
class_name FogOfWar

## Per-faction visibility tracking system using efficient bit packing
##
## Manages fog of war state for all factions:
## - Tracks which tiles are visible (currently in sight)
## - Tracks which tiles are explored (have been seen before)
## - Uses bit packing for memory efficiency (2 bits per tile per faction)
## - Provides fast O(1) visibility queries
##
## Memory usage: ~90 KB for 9 factions × 120,000 tiles × 2 bits
##
## @version 1.0
## @author Agent 2 (Map System)

# ============================================================================
# CONSTANTS
# ============================================================================

const BITS_PER_TILE: int = 2  # 2 bits: [explored, visible]
const BIT_EXPLORED: int = 0x01  # First bit: has been explored
const BIT_VISIBLE: int = 0x02   # Second bit: currently visible

# ============================================================================
# PROPERTIES
# ============================================================================

## Map size
var _map_size: Vector3i = Vector3i.ZERO

## Number of factions
var _num_factions: int = 0

## Total number of tiles
var _total_tiles: int = 0

## Fog data for each faction (Dictionary: faction_id -> PackedByteArray)
## Using separate arrays per faction for better cache locality
var _fog_data: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(map_size: Vector3i, num_factions: int) -> void:
	"""
	Initializes fog of war for all factions.

	Args:
		map_size: Size of the map grid (200, 200, 3)
		num_factions: Number of factions (typically 9: player + 8 AI)
	"""
	_map_size = map_size
	_num_factions = num_factions
	_total_tiles = map_size.x * map_size.y * map_size.z

	# Initialize fog data for each faction
	# Each tile needs 2 bits, so we pack 4 tiles per byte
	var bytes_needed = (_total_tiles + 3) / 4  # Round up

	for faction_id in range(num_factions):
		var fog_array = PackedByteArray()
		fog_array.resize(bytes_needed)
		fog_array.fill(0)  # All tiles start unexplored and invisible
		_fog_data[faction_id] = fog_array

# ============================================================================
# POSITION CONVERSION
# ============================================================================

func _pos_to_tile_index(position: Vector3i) -> int:
	"""Converts 3D position to tile index."""
	return position.x + (position.y * _map_size.x) + (position.z * _map_size.x * _map_size.y)

func _is_valid_position(position: Vector3i) -> bool:
	"""Checks if position is within map bounds."""
	return (position.x >= 0 and position.x < _map_size.x and
			position.y >= 0 and position.y < _map_size.y and
			position.z >= 0 and position.z < _map_size.z)

func _is_valid_faction(faction_id: int) -> bool:
	"""Checks if faction ID is valid."""
	return faction_id >= 0 and faction_id < _num_factions

# ============================================================================
# BIT MANIPULATION
# ============================================================================

func _get_fog_bits(position: Vector3i, faction_id: int) -> int:
	"""
	Gets the 2-bit fog state for a tile.

	Returns:
		2-bit value: 0x00 (unexplored), 0x01 (explored), 0x02 (visible), 0x03 (explored+visible)
	"""
	if not _is_valid_position(position) or not _is_valid_faction(faction_id):
		return 0

	var tile_index = _pos_to_tile_index(position)
	var fog_array = _fog_data[faction_id]

	# Calculate byte and bit positions
	# Each byte stores 4 tiles (2 bits each)
	var byte_index = tile_index / 4
	var bit_offset = (tile_index % 4) * 2

	# Extract 2 bits
	var byte_value = fog_array[byte_index]
	return (byte_value >> bit_offset) & 0x03

func _set_fog_bits(position: Vector3i, faction_id: int, bits: int) -> void:
	"""
	Sets the 2-bit fog state for a tile.

	Args:
		position: Tile position
		faction_id: Faction ID
		bits: 2-bit value to set (0x00-0x03)
	"""
	if not _is_valid_position(position) or not _is_valid_faction(faction_id):
		return

	var tile_index = _pos_to_tile_index(position)
	var fog_array = _fog_data[faction_id]

	# Calculate byte and bit positions
	var byte_index = tile_index / 4
	var bit_offset = (tile_index % 4) * 2

	# Read current byte
	var byte_value = fog_array[byte_index]

	# Clear the 2 bits at offset
	var mask = ~(0x03 << bit_offset)
	byte_value = byte_value & mask

	# Set new bits
	byte_value = byte_value | ((bits & 0x03) << bit_offset)

	# Write back
	fog_array[byte_index] = byte_value

# ============================================================================
# VISIBILITY QUERIES
# ============================================================================

func is_tile_visible(position: Vector3i, faction_id: int) -> bool:
	"""
	Checks if a tile is currently visible to a faction.

	Performance: O(1), < 1ms

	Args:
		position: Tile position to check
		faction_id: Faction ID (0-8)

	Returns:
		true if visible, false if in fog of war or invalid parameters
	"""
	var bits = _get_fog_bits(position, faction_id)
	return (bits & BIT_VISIBLE) != 0

func is_tile_explored(position: Vector3i, faction_id: int) -> bool:
	"""
	Checks if a tile has ever been seen by a faction (even if not currently visible).

	Performance: O(1), < 1ms

	Args:
		position: Tile position to check
		faction_id: Faction ID (0-8)

	Returns:
		true if explored, false if never seen or invalid parameters
	"""
	var bits = _get_fog_bits(position, faction_id)
	return (bits & BIT_EXPLORED) != 0

# ============================================================================
# VISIBILITY UPDATES
# ============================================================================

func update_fog_of_war(faction_id: int, visible_positions: Array[Vector3i]) -> void:
	"""
	Updates the visible tiles for a faction.

	Marks all positions in visible_positions as visible and explored.
	All other positions are marked as not currently visible (but remain explored if they were).

	Performance: < 20ms per faction for typical visibility range

	Args:
		faction_id: Faction ID (0-8)
		visible_positions: All currently visible tile positions
	"""
	if not _is_valid_faction(faction_id):
		push_warning("FogOfWar: Invalid faction_id %d" % faction_id)
		return

	# Track newly explored tiles for event emission
	var newly_explored: Array[Vector3i] = []

	# First pass: Clear all visible flags (but keep explored flags)
	var fog_array = _fog_data[faction_id]
	for i in range(fog_array.size()):
		var byte_value = fog_array[i]
		# For each of the 4 tiles in this byte, keep explored bit but clear visible bit
		for j in range(4):
			var bit_offset = j * 2
			var tile_bits = (byte_value >> bit_offset) & 0x03

			# Keep explored bit, clear visible bit
			tile_bits = tile_bits & BIT_EXPLORED

			# Write back
			var mask = ~(0x03 << bit_offset)
			byte_value = (byte_value & mask) | (tile_bits << bit_offset)

		fog_array[i] = byte_value

	# Second pass: Set visible and explored for all visible positions
	for position in visible_positions:
		if not _is_valid_position(position):
			continue

		# Check if this tile was previously explored
		var was_explored = is_tile_explored(position, faction_id)

		# Set both explored and visible bits
		_set_fog_bits(position, faction_id, BIT_EXPLORED | BIT_VISIBLE)

		# Track if newly explored
		if not was_explored:
			newly_explored.append(position)

	# Emit event for newly explored tiles
	if newly_explored.size() > 0:
		_emit_fog_revealed(faction_id, newly_explored)

func reveal_area(faction_id: int, center: Vector3i, radius: int) -> void:
	"""
	Reveals an area around a position for a faction.

	Sets tiles as visible and explored in a circular area (Manhattan distance).

	Performance: < 15ms for radius 10

	Args:
		faction_id: Faction ID (0-8)
		center: Center of reveal area
		radius: Radius in tiles (Manhattan distance)
	"""
	if not _is_valid_faction(faction_id):
		push_warning("FogOfWar: Invalid faction_id %d" % faction_id)
		return

	if not _is_valid_position(center):
		push_warning("FogOfWar: Invalid center position %s" % center)
		return

	var newly_explored: Array[Vector3i] = []

	# Calculate bounding box
	var min_x = max(0, center.x - radius)
	var max_x = min(_map_size.x - 1, center.x + radius)
	var min_y = max(0, center.y - radius)
	var max_y = min(_map_size.y - 1, center.y + radius)

	# Iterate through bounding box and check Manhattan distance
	for z in range(_map_size.z):
		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				var pos = Vector3i(x, y, z)

				# Calculate Manhattan distance (2D only, ignore Z)
				var manhattan_dist = abs(pos.x - center.x) + abs(pos.y - center.y)

				if manhattan_dist <= radius:
					# Check if previously explored
					var was_explored = is_tile_explored(pos, faction_id)

					# Set both explored and visible
					_set_fog_bits(pos, faction_id, BIT_EXPLORED | BIT_VISIBLE)

					# Track if newly explored
					if not was_explored:
						newly_explored.append(pos)

	# Emit event for newly explored tiles
	if newly_explored.size() > 0:
		_emit_fog_revealed(faction_id, newly_explored)

func clear_fog_for_faction(faction_id: int) -> void:
	"""
	Reveals entire map for a faction (debug/cheat function).

	Sets all tiles as explored and visible.

	Performance: < 50ms

	Args:
		faction_id: Faction ID (0-8)
	"""
	if not _is_valid_faction(faction_id):
		push_warning("FogOfWar: Invalid faction_id %d" % faction_id)
		return

	# Set all bits to 0x03 (explored + visible)
	var fog_array = _fog_data[faction_id]
	for i in range(fog_array.size()):
		# Each byte stores 4 tiles, each with 2 bits
		# 0xFF = 0b11111111 = all tiles explored and visible
		fog_array[i] = 0xFF

	# Collect all positions for event
	var all_positions: Array[Vector3i] = []
	for z in range(_map_size.z):
		for y in range(_map_size.y):
			for x in range(_map_size.x):
				all_positions.append(Vector3i(x, y, z))

	_emit_fog_revealed(faction_id, all_positions)

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	"""
	Serializes fog of war data to dictionary.

	Returns:
		Dictionary containing fog data for all factions
	"""
	var data = {
		"map_size": {
			"x": _map_size.x,
			"y": _map_size.y,
			"z": _map_size.z
		},
		"num_factions": _num_factions,
		"fog_data": {}
	}

	# Convert PackedByteArray to regular array for JSON serialization
	for faction_id in _fog_data:
		var fog_array = _fog_data[faction_id]
		var array_data = []
		for i in range(fog_array.size()):
			array_data.append(fog_array[i])
		data["fog_data"][str(faction_id)] = array_data

	return data

static func from_dict(data: Dictionary) -> FogOfWar:
	"""
	Deserializes fog of war data from dictionary.

	Args:
		data: Dictionary containing fog data

	Returns:
		FogOfWar instance
	"""
	var map_size_data = data.get("map_size", {"x": 200, "y": 200, "z": 3})
	var map_size = Vector3i(
		map_size_data.get("x", 200),
		map_size_data.get("y", 200),
		map_size_data.get("z", 3)
	)
	var num_factions = data.get("num_factions", 9)

	var fog = FogOfWar.new(map_size, num_factions)

	# Restore fog data
	if data.has("fog_data"):
		var fog_data_dict = data["fog_data"]
		for faction_id_str in fog_data_dict:
			var faction_id = int(faction_id_str)
			var array_data = fog_data_dict[faction_id_str]

			if faction_id >= 0 and faction_id < num_factions:
				var fog_array = fog._fog_data[faction_id]
				for i in range(min(array_data.size(), fog_array.size())):
					fog_array[i] = array_data[i]

	return fog

# ============================================================================
# EVENT EMISSION (Mock - will be replaced with EventBus)
# ============================================================================

func _emit_fog_revealed(faction_id: int, positions: Array[Vector3i]) -> void:
	"""Emits fog_revealed event (mock for testing)."""
	# In production, this would be: EventBus.fog_revealed.emit(faction_id, positions)
	pass

# ============================================================================
# DEBUGGING
# ============================================================================

func get_visibility_stats(faction_id: int) -> Dictionary:
	"""
	Returns visibility statistics for a faction.

	Args:
		faction_id: Faction ID

	Returns:
		Dictionary with visibility statistics
	"""
	if not _is_valid_faction(faction_id):
		return {}

	var stats = {
		"faction_id": faction_id,
		"total_tiles": _total_tiles,
		"explored_tiles": 0,
		"visible_tiles": 0,
		"unexplored_tiles": 0,
		"explored_percentage": 0.0,
		"visible_percentage": 0.0
	}

	# Count tiles in each state
	for z in range(_map_size.z):
		for y in range(_map_size.y):
			for x in range(_map_size.x):
				var pos = Vector3i(x, y, z)
				var bits = _get_fog_bits(pos, faction_id)

				if (bits & BIT_EXPLORED) != 0:
					stats["explored_tiles"] += 1
				else:
					stats["unexplored_tiles"] += 1

				if (bits & BIT_VISIBLE) != 0:
					stats["visible_tiles"] += 1

	# Calculate percentages
	stats["explored_percentage"] = (stats["explored_tiles"] / float(_total_tiles)) * 100.0
	stats["visible_percentage"] = (stats["visible_tiles"] / float(_total_tiles)) * 100.0

	return stats

func get_memory_usage() -> Dictionary:
	"""
	Returns memory usage statistics.

	Returns:
		Dictionary with memory usage info
	"""
	var bytes_per_faction = (_total_tiles + 3) / 4
	var total_bytes = bytes_per_faction * _num_factions

	return {
		"bytes_per_faction": bytes_per_faction,
		"total_bytes": total_bytes,
		"total_kb": total_bytes / 1024.0,
		"num_factions": _num_factions,
		"total_tiles": _total_tiles,
		"bits_per_tile": BITS_PER_TILE
	}
