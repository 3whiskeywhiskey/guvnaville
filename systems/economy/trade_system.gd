extends Node
class_name TradeSystem

## Trade System - manages trade routes between factions
## Part of the Economy System (Workstream 2.5)
##
## This class manages:
## - Trade route creation and management
## - Resource transfers between factions
## - Trade route security and raiding
## - Route expiration and cancellation

# Signals
signal trade_route_created(route_id: int, from_faction: int, to_faction: int, resources: Dictionary)
signal trade_completed(from_faction: int, to_faction: int, resources_exchanged: Dictionary)
signal trade_route_raided(route_id: int, raider_faction: int, resources_lost: Dictionary)
signal trade_route_cancelled(route_id: int, from_faction: int, to_faction: int)

# Trade route class
class TradeRoute:
	var route_id: int
	var from_faction: int
	var to_faction: int
	var resources_offered: Dictionary  # {"food": 20, "medicine": 5}
	var resources_received: Dictionary # {"scrap": 30}
	var duration_turns: int     # Remaining turns (-1 = permanent)
	var security_level: float   # 0.0-1.0, chance of successful delivery
	var active: bool = true     # Whether route is currently operational

	func _init(id: int, from: int, to: int, offered: Dictionary, received: Dictionary, duration: int = -1):
		route_id = id
		from_faction = from
		to_faction = to
		resources_offered = offered
		resources_received = received
		duration_turns = duration
		security_level = 0.85  # Default security level

	func to_dict() -> Dictionary:
		return {
			"route_id": route_id,
			"from_faction": from_faction,
			"to_faction": to_faction,
			"resources_offered": resources_offered,
			"resources_received": resources_received,
			"duration_turns": duration_turns,
			"security_level": security_level,
			"active": active
		}

	static func from_dict(data: Dictionary) -> TradeRoute:
		var route = TradeRoute.new(
			data.get("route_id", 0),
			data.get("from_faction", 0),
			data.get("to_faction", 0),
			data.get("resources_offered", {}),
			data.get("resources_received", {}),
			data.get("duration_turns", -1)
		)
		route.security_level = data.get("security_level", 0.85)
		route.active = data.get("active", true)
		return route

# Data storage
var _trade_routes: Dictionary = {}  # route_id -> TradeRoute
var _next_route_id: int = 0
var _resource_manager: ResourceManager = null

## Sets the resource manager reference
func set_resource_manager(manager: ResourceManager) -> void:
	_resource_manager = manager

## Establishes a trade route between two factions
## Parameters:
##   from_faction: int - Faction offering resources
##   to_faction: int - Faction receiving resources
##   resources_offered: Dictionary - Resources to send: {"food": 20}
##   resources_received: Dictionary - Resources to receive: {"scrap": 30}
##   duration: int - Number of turns (-1 for permanent)
## Returns: int - Trade route ID (>= 0) if successful, -1 if failed
## Emits: trade_route_created
func create_trade_route(from_faction: int, to_faction: int,
                        resources_offered: Dictionary,
                        resources_received: Dictionary,
                        duration: int = -1) -> int:
	# Validate factions
	if from_faction < 0 or to_faction < 0:
		push_error("TradeSystem: Invalid faction IDs")
		return -1

	if from_faction == to_faction:
		push_error("TradeSystem: Cannot trade with self")
		return -1

	# Validate resources
	if resources_offered.is_empty() or resources_received.is_empty():
		push_error("TradeSystem: Trade must include resources on both sides")
		return -1

	# Create route
	var route_id = _next_route_id
	_next_route_id += 1

	var route = TradeRoute.new(
		route_id,
		from_faction,
		to_faction,
		resources_offered.duplicate(),
		resources_received.duplicate(),
		duration
	)

	_trade_routes[route_id] = route

	# Emit signal
	var resources_info = {
		"offered": resources_offered,
		"received": resources_received
	}
	trade_route_created.emit(route_id, from_faction, to_faction, resources_info)

	return route_id

## Processes all active trade routes (called once per turn)
## Parameters:
##   faction_id: int - Optional filter for specific faction
func process_trade_routes(faction_id: int = -1) -> void:
	if _resource_manager == null:
		push_error("TradeSystem: Resource manager not set")
		return

	var routes_to_remove = []

	for route_id in _trade_routes.keys():
		var route = _trade_routes[route_id]

		# Skip if not active
		if not route.active:
			continue

		# Filter by faction if specified
		if faction_id >= 0:
			if route.from_faction != faction_id and route.to_faction != faction_id:
				continue

		# Check security (chance of successful delivery)
		var roll = randf()
		if roll > route.security_level:
			# Route was raided
			var resources_lost = route.resources_offered.duplicate()
			trade_route_raided.emit(route_id, -1, resources_lost)
			# Reduce security level after raid
			route.security_level = max(0.3, route.security_level - 0.1)
			continue

		# Execute trade
		var success = _execute_trade(route)

		if success:
			# Emit trade completed
			var resources_exchanged = {
				"offered": route.resources_offered,
				"received": route.resources_received
			}
			trade_completed.emit(route.from_faction, route.to_faction, resources_exchanged)

			# Update duration
			if route.duration_turns > 0:
				route.duration_turns -= 1
				if route.duration_turns == 0:
					routes_to_remove.append(route_id)

	# Remove expired routes
	for route_id in routes_to_remove:
		cancel_trade_route(route_id)

## Executes a single trade exchange
func _execute_trade(route: TradeRoute) -> bool:
	# Try to consume resources from offering faction
	if not _resource_manager.consume_resources(route.from_faction, route.resources_offered):
		# Can't afford to trade right now
		return false

	# Add received resources to offering faction
	_resource_manager.add_resources(route.from_faction, route.resources_received)

	# Try to consume resources from receiving faction (payment)
	if not _resource_manager.consume_resources(route.to_faction, route.resources_received):
		# Receiving faction can't pay - refund the offered resources
		_resource_manager.add_resources(route.from_faction, route.resources_offered)
		return false

	# Add offered resources to receiving faction
	_resource_manager.add_resources(route.to_faction, route.resources_offered)

	return true

## Cancels an active trade route
## Parameters:
##   route_id: int - The trade route to cancel
## Returns: bool - true if cancelled successfully, false if route doesn't exist
## Emits: trade_route_cancelled
func cancel_trade_route(route_id: int) -> bool:
	if not _trade_routes.has(route_id):
		return false

	var route = _trade_routes[route_id]
	trade_route_cancelled.emit(route_id, route.from_faction, route.to_faction)
	_trade_routes.erase(route_id)

	return true

## Retrieves all active trade routes involving a faction
## Parameters:
##   faction_id: int - The faction to query (use -1 for all routes)
## Returns: Array - Array of TradeRoute dictionaries
func get_trade_routes(faction_id: int = -1) -> Array:
	var result = []

	for route_id in _trade_routes.keys():
		var route = _trade_routes[route_id]

		if faction_id < 0 or route.from_faction == faction_id or route.to_faction == faction_id:
			result.append(route.to_dict())

	return result

## Gets a specific trade route by ID
## Parameters:
##   route_id: int - The route to query
## Returns: Dictionary - Route data, or empty dictionary if not found
func get_trade_route(route_id: int) -> Dictionary:
	if not _trade_routes.has(route_id):
		return {}

	return _trade_routes[route_id].to_dict()

## Sets the security level for a trade route
## Parameters:
##   route_id: int - The route to modify
##   security: float - Security level (0.0 - 1.0)
func set_route_security(route_id: int, security: float) -> void:
	if not _trade_routes.has(route_id):
		return

	_trade_routes[route_id].security_level = clamp(security, 0.0, 1.0)

## Pauses or resumes a trade route
## Parameters:
##   route_id: int - The route to modify
##   is_active: bool - Whether the route should be active
func set_route_active(route_id: int, is_active: bool) -> void:
	if not _trade_routes.has(route_id):
		return

	_trade_routes[route_id].active = is_active

## Gets the total number of active trade routes
func get_active_route_count() -> int:
	var count = 0
	for route_id in _trade_routes.keys():
		if _trade_routes[route_id].active:
			count += 1
	return count

## Gets the number of trade routes for a specific faction
func get_faction_route_count(faction_id: int) -> int:
	var count = 0
	for route_id in _trade_routes.keys():
		var route = _trade_routes[route_id]
		if route.from_faction == faction_id or route.to_faction == faction_id:
			count += 1
	return count

## Calculates net trade flow for a faction
## Returns a dictionary of resources gained/lost per turn from trade
func get_net_trade_flow(faction_id: int) -> Dictionary:
	var net_flow = {}

	for route_id in _trade_routes.keys():
		var route = _trade_routes[route_id]
		if not route.active:
			continue

		# Resources offered (negative)
		if route.from_faction == faction_id:
			for resource_type in route.resources_offered.keys():
				var amount = route.resources_offered[resource_type]
				net_flow[resource_type] = net_flow.get(resource_type, 0) - amount

			# Resources received (positive)
			for resource_type in route.resources_received.keys():
				var amount = route.resources_received[resource_type]
				net_flow[resource_type] = net_flow.get(resource_type, 0) + amount

		# Resources received as the to_faction (positive for what they get, negative for what they pay)
		if route.to_faction == faction_id:
			for resource_type in route.resources_offered.keys():
				var amount = route.resources_offered[resource_type]
				net_flow[resource_type] = net_flow.get(resource_type, 0) + amount

			# Resources paid (negative)
			for resource_type in route.resources_received.keys():
				var amount = route.resources_received[resource_type]
				net_flow[resource_type] = net_flow.get(resource_type, 0) - amount

	return net_flow

## Serializes trade system state
func save_state() -> Dictionary:
	var routes_data = []
	for route_id in _trade_routes.keys():
		routes_data.append(_trade_routes[route_id].to_dict())

	return {
		"routes": routes_data,
		"next_route_id": _next_route_id
	}

## Restores trade system state
func load_state(state: Dictionary) -> void:
	_trade_routes.clear()

	if state.has("next_route_id"):
		_next_route_id = state["next_route_id"]

	if state.has("routes"):
		for route_data in state["routes"]:
			var route = TradeRoute.from_dict(route_data)
			_trade_routes[route.route_id] = route
