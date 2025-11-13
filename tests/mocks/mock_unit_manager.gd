## MockUnitManager - Mock implementation of UnitManager for testing
class_name MockUnitManager
extends RefCounted

var _units: Dictionary = {}  # id -> MockUnit
var _next_id: int = 1

func create_unit(unit_type: String, faction_id: int, position: Vector3i) -> MockUnit:
	var unit = MockUnit.new(_next_id, position, faction_id)
	unit.type = unit_type
	_units[_next_id] = unit
	_next_id += 1
	return unit

func get_unit(unit_id: int):
	return _units.get(unit_id)

func get_all_units() -> Array:
	return _units.values()

func get_units_by_faction(faction_id: int) -> Array:
	var result = []
	for unit in _units.values():
		if unit.faction_id == faction_id:
			result.append(unit)
	return result

func destroy_unit(unit_id: int) -> void:
	_units.erase(unit_id)
