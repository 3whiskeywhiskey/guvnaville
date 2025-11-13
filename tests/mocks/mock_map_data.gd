## MockMapData - Mock implementation of MapData for testing
class_name MockMapData
extends RefCounted

var _tiles: Dictionary = {}
var _map_size: Vector3i = Vector3i(200, 200, 3)

func _init(size: Vector3i = Vector3i(200, 200, 3)):
	_map_size = size
	_generate_test_tiles()

func _generate_test_tiles() -> void:
	for x in range(_map_size.x):
		for y in range(_map_size.y):
			for z in range(_map_size.z):
				var pos = Vector3i(x, y, z)
				_tiles[pos] = MockTile.new(pos)

func get_tile(position: Vector3i):
	if position.x < 0 or position.x >= _map_size.x or \
	   position.y < 0 or position.y >= _map_size.y or \
	   position.z < 0 or position.z >= _map_size.z:
		return null

	return _tiles.get(position)

func get_map_size() -> Vector3i:
	return _map_size

func is_position_valid(position: Vector3i) -> bool:
	return position.x >= 0 and position.x < _map_size.x and \
		   position.y >= 0 and position.y < _map_size.y and \
		   position.z >= 0 and position.z < _map_size.z

func get_tiles_in_radius(center: Vector3i, radius: int, same_level_only: bool = true) -> Array:
	var result = []

	for x in range(max(0, center.x - radius), min(_map_size.x, center.x + radius + 1)):
		for y in range(max(0, center.y - radius), min(_map_size.y, center.y + radius + 1)):
			var dist = abs(x - center.x) + abs(y - center.y)
			if dist <= radius:
				if same_level_only:
					var pos = Vector3i(x, y, center.z)
					if pos in _tiles:
						result.append(_tiles[pos])
				else:
					for z in range(_map_size.z):
						var pos = Vector3i(x, y, z)
						if pos in _tiles:
							result.append(_tiles[pos])

	return result

class MockTile:
	var position: Vector3i
	var tile_type: String = "default"
	var owner_id: int = -1
	var is_passable: bool = true

	func _init(pos: Vector3i):
		position = pos

		# Vary tile types for testing
		var types = ["residential", "commercial", "industrial", "street", "park"]
		tile_type = types[pos.x % types.size()]
