extends GutTest

## Unit tests for TradeSystem
## Tests trade route creation, processing, and resource transfers

var trade_system: TradeSystem
var resource_manager: ResourceManager
var faction_a = 1
var faction_b = 2

func before_each():
	resource_manager = ResourceManager.new()
	resource_manager.initialize_faction(faction_a)
	resource_manager.initialize_faction(faction_b)

	trade_system = TradeSystem.new()
	trade_system.set_resource_manager(resource_manager)

func after_each():
	trade_system.free()
	resource_manager.free()

# Test: Create trade route
func test_create_trade_route():
	var offered = {"food": 20}
	var received = {"scrap": 30}

	var route_id = trade_system.create_trade_route(faction_a, faction_b, offered, received, 10)

	assert_gte(route_id, 0, "Should return valid route ID")

	var routes = trade_system.get_trade_routes(faction_a)
	assert_eq(routes.size(), 1, "Faction A should have 1 route")
	assert_eq(routes[0]["from_faction"], faction_a, "Route should be from faction A")
	assert_eq(routes[0]["to_faction"], faction_b, "Route should be to faction B")

# Test: Create trade route emits signal
func test_create_trade_route_emits_signal():
	watch_signals(trade_system)

	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 30},
		10
	)

	assert_signal_emitted(trade_system, "trade_route_created")
	var signal_params = get_signal_parameters(trade_system, "trade_route_created")
	assert_eq(signal_params[0], route_id, "Signal should include route_id")
	assert_eq(signal_params[1], faction_a, "Signal should include from_faction")
	assert_eq(signal_params[2], faction_b, "Signal should include to_faction")

# Test: Create trade route with invalid factions fails
func test_create_trade_route_invalid_factions():
	var route_id = trade_system.create_trade_route(
		faction_a, faction_a,  # Same faction
		{"food": 20},
		{"scrap": 30}
	)

	assert_eq(route_id, -1, "Should fail for same faction")

	route_id = trade_system.create_trade_route(
		-1, faction_b,  # Invalid faction
		{"food": 20},
		{"scrap": 30}
	)

	assert_eq(route_id, -1, "Should fail for invalid faction")

# Test: Create trade route with empty resources fails
func test_create_trade_route_empty_resources():
	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{},  # Empty offered
		{"scrap": 30}
	)

	assert_eq(route_id, -1, "Should fail with empty resources")

# Test: Process trade routes with sufficient resources
func test_process_trade_routes_success():
	watch_signals(trade_system)

	# Give both factions resources
	resource_manager.add_resources(faction_a, {"food": 100})
	resource_manager.add_resources(faction_b, {"scrap": 100})

	trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	# Process trade
	trade_system.process_trade_routes()

	# Faction A should have: 80 food (+15 scrap)
	assert_eq(resource_manager.get_resource(faction_a, "food"), 80, "Faction A food should decrease")
	assert_eq(resource_manager.get_resource(faction_a, "scrap"), 15, "Faction A should receive scrap")

	# Faction B should have: 85 scrap (+20 food)
	assert_eq(resource_manager.get_resource(faction_b, "scrap"), 85, "Faction B scrap should decrease")
	assert_eq(resource_manager.get_resource(faction_b, "food"), 20, "Faction B should receive food")

	assert_signal_emitted(trade_system, "trade_completed")

# Test: Process trade routes with insufficient resources
func test_process_trade_routes_insufficient():
	# Faction A has resources, but Faction B doesn't
	resource_manager.add_resources(faction_a, {"food": 100})
	resource_manager.add_resources(faction_b, {"scrap": 5})  # Not enough

	trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	# Process trade
	trade_system.process_trade_routes()

	# Trade should fail, no resources transferred
	assert_eq(resource_manager.get_resource(faction_a, "food"), 100, "Faction A food unchanged")
	assert_eq(resource_manager.get_resource(faction_a, "scrap"), 0, "Faction A should not receive scrap")
	assert_eq(resource_manager.get_resource(faction_b, "scrap"), 5, "Faction B scrap unchanged")

# Test: Process trade routes for specific faction
func test_process_trade_routes_specific_faction():
	resource_manager.add_resources(faction_a, {"food": 100})
	resource_manager.add_resources(faction_b, {"scrap": 100})

	trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	# Process only faction A's routes
	trade_system.process_trade_routes(faction_a)

	# Should still execute the trade
	assert_eq(resource_manager.get_resource(faction_a, "food"), 80)
	assert_eq(resource_manager.get_resource(faction_a, "scrap"), 15)

# Test: Cancel trade route
func test_cancel_trade_route():
	watch_signals(trade_system)

	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	var success = trade_system.cancel_trade_route(route_id)

	assert_true(success, "Cancellation should succeed")
	assert_signal_emitted(trade_system, "trade_route_cancelled")

	var routes = trade_system.get_trade_routes(faction_a)
	assert_eq(routes.size(), 0, "Route should be removed")

# Test: Cancel invalid route
func test_cancel_invalid_route():
	var success = trade_system.cancel_trade_route(999)

	assert_false(success, "Should fail for invalid route")

# Test: Get trade routes for faction
func test_get_trade_routes_for_faction():
	trade_system.create_trade_route(faction_a, faction_b, {"food": 20}, {"scrap": 15})
	trade_system.create_trade_route(faction_b, faction_a, {"scrap": 10}, {"food": 8})

	var routes_a = trade_system.get_trade_routes(faction_a)
	assert_eq(routes_a.size(), 2, "Faction A should have 2 routes")

	var routes_b = trade_system.get_trade_routes(faction_b)
	assert_eq(routes_b.size(), 2, "Faction B should have 2 routes")

# Test: Get all trade routes
func test_get_all_trade_routes():
	trade_system.create_trade_route(faction_a, faction_b, {"food": 20}, {"scrap": 15})
	trade_system.create_trade_route(faction_b, faction_a, {"scrap": 10}, {"food": 8})

	var all_routes = trade_system.get_trade_routes(-1)
	assert_eq(all_routes.size(), 2, "Should return all routes")

# Test: Get specific trade route
func test_get_trade_route():
	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	var route = trade_system.get_trade_route(route_id)

	assert_not_null(route, "Route should not be null")
	assert_eq(route["route_id"], route_id, "Route ID should match")
	assert_eq(route["from_faction"], faction_a, "From faction should match")

	var invalid_route = trade_system.get_trade_route(999)
	assert_eq(invalid_route.size(), 0, "Invalid route should return empty dict")

# Test: Trade route duration expires
func test_trade_route_duration():
	resource_manager.add_resources(faction_a, {"food": 1000})
	resource_manager.add_resources(faction_b, {"scrap": 1000})

	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15},
		2  # Duration: 2 turns
	)

	# Process turn 1
	trade_system.process_trade_routes()
	var routes = trade_system.get_trade_routes(faction_a)
	assert_eq(routes.size(), 1, "Route should still exist after turn 1")

	# Process turn 2
	trade_system.process_trade_routes()
	routes = trade_system.get_trade_routes(faction_a)
	assert_eq(routes.size(), 0, "Route should be removed after expiry")

# Test: Permanent trade route
func test_permanent_trade_route():
	resource_manager.add_resources(faction_a, {"food": 1000})
	resource_manager.add_resources(faction_b, {"scrap": 1000})

	trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15},
		-1  # Permanent
	)

	# Process multiple turns
	for i in range(10):
		trade_system.process_trade_routes()

	var routes = trade_system.get_trade_routes(faction_a)
	assert_eq(routes.size(), 1, "Permanent route should not expire")

# Test: Set route security
func test_set_route_security():
	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	trade_system.set_route_security(route_id, 0.95)

	var route = trade_system.get_trade_route(route_id)
	assert_almost_eq(route["security_level"], 0.95, 0.01, "Security should be set")

# Test: Set route active/inactive
func test_set_route_active():
	resource_manager.add_resources(faction_a, {"food": 100})
	resource_manager.add_resources(faction_b, {"scrap": 100})

	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15}
	)

	# Deactivate route
	trade_system.set_route_active(route_id, false)

	# Process trade - should not execute
	trade_system.process_trade_routes()

	assert_eq(resource_manager.get_resource(faction_a, "food"), 100, "Food should not change")
	assert_eq(resource_manager.get_resource(faction_b, "scrap"), 100, "Scrap should not change")

# Test: Get active route count
func test_get_active_route_count():
	var route1 = trade_system.create_trade_route(faction_a, faction_b, {"food": 20}, {"scrap": 15})
	var route2 = trade_system.create_trade_route(faction_b, faction_a, {"scrap": 10}, {"food": 8})

	assert_eq(trade_system.get_active_route_count(), 2, "Should have 2 active routes")

	trade_system.set_route_active(route1, false)
	assert_eq(trade_system.get_active_route_count(), 1, "Should have 1 active route")

# Test: Get faction route count
func test_get_faction_route_count():
	trade_system.create_trade_route(faction_a, faction_b, {"food": 20}, {"scrap": 15})
	trade_system.create_trade_route(faction_b, faction_a, {"scrap": 10}, {"food": 8})

	assert_eq(trade_system.get_faction_route_count(faction_a), 2, "Faction A should have 2 routes")
	assert_eq(trade_system.get_faction_route_count(faction_b), 2, "Faction B should have 2 routes")

# Test: Get net trade flow
func test_get_net_trade_flow():
	trade_system.create_trade_route(faction_a, faction_b, {"food": 20}, {"scrap": 15})
	trade_system.create_trade_route(faction_b, faction_a, {"scrap": 10}, {"food": 8})

	var flow_a = trade_system.get_net_trade_flow(faction_a)

	# Faction A: gives 20 food, receives 15 scrap, gives 10 scrap (payment), receives 8 food
	# Net: food = -20 + 8 = -12, scrap = +15 - 10 = +5
	assert_eq(flow_a.get("food", 0), -12, "Food flow should be -12")
	assert_eq(flow_a.get("scrap", 0), 5, "Scrap flow should be +5")

# Test: Save and load state
func test_save_load_state():
	var route_id = trade_system.create_trade_route(
		faction_a, faction_b,
		{"food": 20},
		{"scrap": 15},
		10
	)
	trade_system.set_route_security(route_id, 0.75)

	var state = trade_system.save_state()

	var new_system = TradeSystem.new()
	new_system.load_state(state)

	var routes = new_system.get_trade_routes(faction_a)
	assert_eq(routes.size(), 1, "Route should be restored")
	assert_eq(routes[0]["from_faction"], faction_a, "From faction should match")
	assert_eq(routes[0]["duration_turns"], 10, "Duration should be restored")
	assert_almost_eq(routes[0]["security_level"], 0.75, 0.01, "Security should be restored")

	new_system.free()

# Test: Multiple simultaneous routes
func test_multiple_simultaneous_routes():
	resource_manager.add_resources(faction_a, {"food": 1000, "medicine": 1000})
	resource_manager.add_resources(faction_b, {"scrap": 1000, "fuel": 1000})

	trade_system.create_trade_route(faction_a, faction_b, {"food": 20}, {"scrap": 15})
	trade_system.create_trade_route(faction_a, faction_b, {"medicine": 10}, {"fuel": 5})

	trade_system.process_trade_routes()

	# Faction A should lose food and medicine, gain scrap and fuel
	assert_eq(resource_manager.get_resource(faction_a, "food"), 980)
	assert_eq(resource_manager.get_resource(faction_a, "medicine"), 990)
	assert_eq(resource_manager.get_resource(faction_a, "scrap"), 15)
	assert_eq(resource_manager.get_resource(faction_a, "fuel"), 5)
