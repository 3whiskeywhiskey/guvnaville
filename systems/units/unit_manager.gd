class_name UnitManager
extends Node

## Unit Manager - Manages unit lifecycle and registry
## Part of Workstream 2.3: GameUnit System

# Unit registry (id -> GameUnit)
var _units: Dictionary = {}

# Spatial index (position -> Array[GameUnit])
var _spatial_index: Dictionary = {}

# Faction index (faction_id -> Array[GameUnit])
var _faction_index: Dictionary = {}

# Reference to UnitFactory
var _factory: GameUnitFactory = null

# Mock EventBus for testing (will be replaced with real EventBus)
var _event_bus = null

## Initialize manager
func _ready():
	# Create factory if not injected
	if not _factory:
		_factory = UnitFactory.new()
		add_child(_factory)

## Set factory (for dependency injection in tests)
func set_factory(factory: GameUnitFactory) -> void:
	_factory = factory

## Set event bus (for dependency injection)
func set_event_bus(event_bus) -> void:
	_event_bus = event_bus

## Create a new unit
func create_unit(
	unit_type: String,
	faction_id: int,
	position: Vector3i,
	customization: Dictionary = {}
) -> GameUnit:
	# Validate inputs
	if not _factory or not _factory.has_unit_type(unit_type):
		push_warning("UnitManager: Unknown unit type '%s'" % unit_type)
		return null

	if faction_id < 0:
		push_warning("UnitManager: Invalid faction_id %d" % faction_id)
		return null

	# Check if position is already occupied by enemy
	var units_at_pos = get_units_at_position(position)
	for existing_unit in units_at_pos:
		if existing_unit.faction_id != faction_id:
			push_warning("UnitManager: Position occupied by enemy unit")
			return null

	# Create unit from template
	var unit = _factory.create_from_template(unit_type, faction_id, position, customization)

	if not unit:
		push_warning("UnitManager: Failed to create unit from template")
		return null

	# Register unit
	_register_unit(unit)

	# Emit event
	_emit_event("unit_created", [unit.id, unit_type, position, faction_id])

	return unit

## Destroy a unit
func destroy_unit(unit_id: int, cause: String = "") -> void:
	if not _units.has(unit_id):
		push_warning("UnitManager: GameUnit %d not found for destruction" % unit_id)
		return

	var unit = _units[unit_id]
	var position = unit.position
	var faction_id = unit.faction_id

	# Unregister unit
	_unregister_unit(unit)

	# Emit events
	_emit_event("unit_died", [unit_id, position, faction_id, cause])
	_emit_event("unit_destroyed", [unit_id])

## Get unit by ID
func get_unit(unit_id: int) -> GameUnit:
	return _units.get(unit_id, null)

## Get all units at a position
func get_units_at_position(position: Vector3i) -> Array[GameUnit]:
	var pos_key = _position_to_key(position)
	if _spatial_index.has(pos_key):
		return _spatial_index[pos_key].duplicate()
	return []

## Get all units belonging to a faction
func get_units_by_faction(faction_id: int) -> Array[GameUnit]:
	if _faction_index.has(faction_id):
		return _faction_index[faction_id].duplicate()
	return []

## Get units within radius of center position
func get_units_in_radius(
	center: Vector3i,
	radius: int,
	faction_id: int = -1
) -> Array[GameUnit]:
	var result: Array[GameUnit] = []

	for unit in _units.values():
		var distance = _calculate_distance(center, unit.position)
		if distance <= radius:
			if faction_id < 0 or unit.faction_id == faction_id:
				result.append(unit)

	return result

## Get all active units
func get_all_units() -> Array[GameUnit]:
	var result: Array[GameUnit] = []
	result.assign(_units.values())
	return result

## Check if unit exists
func unit_exists(unit_id: int) -> bool:
	return _units.has(unit_id)

## Apply damage to a unit
func damage_unit(unit_id: int, damage: int, source: String = "") -> void:
	if not _units.has(unit_id):
		push_warning("UnitManager: GameUnit %d not found for damage" % unit_id)
		return

	var unit = _units[unit_id]
	var actual_damage = unit.take_damage(damage)

	_emit_event("unit_damaged", [unit_id, actual_damage, unit.current_hp])

	# Check for death
	if unit.current_hp <= 0:
		destroy_unit(unit_id, "combat")

## Heal a unit
func heal_unit(unit_id: int, amount: int, source: String = "") -> void:
	if not _units.has(unit_id):
		push_warning("UnitManager: GameUnit %d not found for healing" % unit_id)
		return

	var unit = _units[unit_id]
	var actual_heal = unit.heal(amount)

	_emit_event("unit_healed", [unit_id, actual_heal, unit.current_hp])

## Modify unit morale
func modify_morale(unit_id: int, delta: int, reason: String = "") -> void:
	if not _units.has(unit_id):
		push_warning("UnitManager: GameUnit %d not found for morale modification" % unit_id)
		return

	var unit = _units[unit_id]
	var old_morale = unit.morale
	unit.modify_morale(delta)

	_emit_event("unit_morale_changed", [unit_id, old_morale, unit.morale])

	# Check for routing
	if unit.morale <= 0 and old_morale > 0:
		_emit_event("unit_routed", [unit_id])

## Add experience to unit
func add_experience(unit_id: int, xp: int, source: String = "") -> void:
	if not _units.has(unit_id):
		push_warning("UnitManager: GameUnit %d not found for XP" % unit_id)
		return

	var unit = _units[unit_id]
	var old_rank = unit.rank
	var promoted = unit.add_experience(xp)

	_emit_event("unit_gained_xp", [unit_id, xp, unit.experience])

	if promoted:
		_emit_event("unit_promoted", [unit_id, old_rank, unit.rank])

## Set unit position directly (no movement validation)
func set_position(unit_id: int, new_position: Vector3i) -> bool:
	if not _units.has(unit_id):
		return false

	var unit = _units[unit_id]
	var old_position = unit.position

	# Update spatial index
	_remove_from_spatial_index(unit)
	unit.position = new_position
	_add_to_spatial_index(unit)

	_emit_event("unit_teleported", [unit_id, old_position, new_position])

	return true

## Add status effect to unit
func add_status_effect(unit_id: int, effect: Dictionary) -> void:
	if not _units.has(unit_id):
		push_warning("UnitManager: GameUnit %d not found for status effect" % unit_id)
		return

	var unit = _units[unit_id]
	unit.status_effects.append(effect)

	var effect_id = effect.get("id", "unknown")
	_emit_event("unit_status_applied", [unit_id, effect_id])

## Remove status effect from unit
func remove_status_effect(unit_id: int, effect_id: String) -> void:
	if not _units.has(unit_id):
		return

	var unit = _units[unit_id]
	for i in range(unit.status_effects.size() - 1, -1, -1):
		var effect = unit.status_effects[i]
		if effect.get("id", "") == effect_id:
			unit.status_effects.remove_at(i)
			_emit_event("unit_status_removed", [unit_id, effect_id])
			break

## Tick status effects for a unit (called each turn)
func tick_status_effects(unit_id: int) -> void:
	if not _units.has(unit_id):
		return

	var unit = _units[unit_id]
	unit._tick_status_effects()

## Reset all units for new turn
func reset_turn_state_all() -> void:
	for unit in _units.values():
		unit.reset_turn_state()
		_emit_event("unit_turn_started", [unit.id])

## Reset specific unit for new turn
func reset_turn_state(unit_id: int) -> void:
	if not _units.has(unit_id):
		return

	var unit = _units[unit_id]
	unit.reset_turn_state()
	_emit_event("unit_turn_started", [unit_id])

## Clear all units (for testing)
func clear_all_units() -> void:
	_units.clear()
	_spatial_index.clear()
	_faction_index.clear()

## Get unit count
func get_unit_count() -> int:
	return _units.size()

## Get unit count by faction
func get_faction_unit_count(faction_id: int) -> int:
	if _faction_index.has(faction_id):
		return _faction_index[faction_id].size()
	return 0

## Private helper methods

func _register_unit(unit: GameUnit) -> void:
	# Add to main registry
	_units[unit.id] = unit

	# Add to spatial index
	_add_to_spatial_index(unit)

	# Add to faction index
	_add_to_faction_index(unit)

func _unregister_unit(unit: GameUnit) -> void:
	# Remove from main registry
	_units.erase(unit.id)

	# Remove from spatial index
	_remove_from_spatial_index(unit)

	# Remove from faction index
	_remove_from_faction_index(unit)

func _add_to_spatial_index(unit: GameUnit) -> void:
	var pos_key = _position_to_key(unit.position)
	if not _spatial_index.has(pos_key):
		_spatial_index[pos_key] = []
	_spatial_index[pos_key].append(unit)

func _remove_from_spatial_index(unit: GameUnit) -> void:
	var pos_key = _position_to_key(unit.position)
	if _spatial_index.has(pos_key):
		var units_at_pos = _spatial_index[pos_key]
		var idx = units_at_pos.find(unit)
		if idx >= 0:
			units_at_pos.remove_at(idx)
		if units_at_pos.is_empty():
			_spatial_index.erase(pos_key)

func _add_to_faction_index(unit: GameUnit) -> void:
	if not _faction_index.has(unit.faction_id):
		_faction_index[unit.faction_id] = []
	_faction_index[unit.faction_id].append(unit)

func _remove_from_faction_index(unit: GameUnit) -> void:
	if _faction_index.has(unit.faction_id):
		var faction_units = _faction_index[unit.faction_id]
		var idx = faction_units.find(unit)
		if idx >= 0:
			faction_units.remove_at(idx)
		if faction_units.is_empty():
			_faction_index.erase(unit.faction_id)

func _position_to_key(pos: Vector3i) -> String:
	return "%d,%d,%d" % [pos.x, pos.y, pos.z]

func _calculate_distance(pos1: Vector3i, pos2: Vector3i) -> int:
	# Manhattan distance for grid-based movement
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y) + abs(pos1.z - pos2.z)

func _emit_event(event_name: String, args: Array) -> void:
	# Use EventBus if available, otherwise just print for debugging
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
			_:
				push_warning("Too many args for event: " + event_name)
