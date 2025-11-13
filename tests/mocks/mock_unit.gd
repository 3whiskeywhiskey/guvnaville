## MockUnit - Mock implementation of Unit for testing
class_name MockUnit
extends RefCounted

var id: int
var type: String = "soldier"
var faction_id: int = 0
var position: Vector3i = Vector3i.ZERO
var current_hp: int = 100
var max_hp: int = 100
var morale: int = 50

func _init(unit_id: int, unit_position: Vector3i, unit_faction: int = 0):
	id = unit_id
	position = unit_position
	faction_id = unit_faction

func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"faction_id": faction_id,
		"position": position,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"morale": morale
	}
