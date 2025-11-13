extends Node
## IntegrationCoordinator - Phase 3 Integration Layer
## Coordinates communication between all game systems
## Replaces mocks with real system integrations
##
## This script acts as the glue that connects:
## - Core Foundation
## - Game Systems (Map, Units, Combat, Economy, Culture, Events)
## - AI System
## - UI/Rendering Systems

# Preload all system classes to ensure class_name registration
const _MapData = preload("res://systems/map/map_data.gd")
const _UnitManager = preload("res://systems/units/unit_manager.gd")
const _CombatResolver = preload("res://systems/combat/combat_resolver.gd")
const _ResourceManager = preload("res://systems/economy/resource_manager.gd")
const _ProductionSystem = preload("res://systems/economy/production_system.gd")
const _TradeSystem = preload("res://systems/economy/trade_system.gd")
const _ScavengingSystem = preload("res://systems/economy/scavenging_system.gd")
const _PopulationSystem = preload("res://systems/economy/population_system.gd")
const _CultureTree = preload("res://systems/culture/culture_tree.gd")
const _CultureEffects = preload("res://systems/culture/culture_effects.gd")
const _EventManager = preload("res://systems/events/event_manager.gd")
const _FogOfWar = preload("res://systems/map/fog_of_war.gd")
const _MovementSystem = preload("res://systems/map/movement_system.gd")
const _FactionAI = preload("res://systems/ai/faction_ai.gd")
const _AIAction = preload("res://systems/ai/ai_action.gd")

# ============================================================================
# SYSTEM REFERENCES
# ============================================================================

# Core systems (autoloads - accessed directly)
# - EventBus
# - DataLoader
# - SaveManager
# - TurnManager
# - GameManager
# - UIManager

# Game system instances (created on demand)
var map_data: MapData = null
var unit_manager: UnitManager = null
var combat_resolver: CombatResolver = null
var resource_manager: ResourceManager = null
var production_system: ProductionSystem = null
var trade_system: TradeSystem = null
var scavenging_system: ScavengingSystem = null
var population_system: PopulationSystem = null
var culture_tree: CultureTree = null
var culture_effects: CultureEffects = null
var event_manager: EventManager = null
var fog_of_war: FogOfWar = null
var movement_system: MovementSystem = null

# AI systems
var faction_ais: Dictionary = {}  # faction_id -> FactionAI

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("[IntegrationCoordinator] Initializing Phase 3 integration...")

	# Connect to core events
	_connect_to_events()

	print("[IntegrationCoordinator] Ready for integration")

func _connect_to_events() -> void:
	"""Connect to EventBus signals to coordinate systems"""
	EventBus.game_started.connect(_on_game_started)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.unit_created.connect(_on_unit_created)
	EventBus.unit_moved.connect(_on_unit_moved)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.building_completed.connect(_on_building_completed)
	EventBus.event_triggered.connect(_on_event_triggered)

# ============================================================================
# GAME INITIALIZATION
# ============================================================================

func _on_game_started(game_state) -> void:
	"""Initialize all game systems when a new game starts"""
	print("[IntegrationCoordinator] Game started - initializing systems")

	# Initialize map system
	_initialize_map_system(game_state)

	# Initialize unit system
	_initialize_unit_system(game_state)

	# Initialize combat system
	_initialize_combat_system()

	# Initialize economy systems
	_initialize_economy_systems()

	# Initialize culture system
	_initialize_culture_system()

	# Initialize event system
	_initialize_event_system(game_state)

	# Initialize AI for all AI factions
	_initialize_ai_systems(game_state)

	print("[IntegrationCoordinator] All systems initialized")

func _initialize_map_system(game_state) -> void:
	"""Initialize map and fog of war"""
	print("[IntegrationCoordinator] Initializing map system...")

	# Create map if not exists
	if not map_data:
		map_data = MapData.new()

	# Initialize with game world state or generate new
	var map_size = game_state.game_settings.get("map_size", 200)
	map_data.initialize(map_size, map_size, 3)

	# Initialize fog of war
	fog_of_war = FogOfWar.new()
	fog_of_war.initialize(map_data, game_state.factions.size())

	# Initialize movement system
	movement_system = MovementSystem.new()

	print("[IntegrationCoordinator] Map system initialized (%dx%d tiles)" % [map_size, map_size])

func _initialize_unit_system(game_state) -> void:
	"""Initialize unit management"""
	print("[IntegrationCoordinator] Initializing unit system...")

	unit_manager = UnitManager.new()

	# Create starting units for each faction
	for faction in game_state.factions:
		var start_pos = Vector3i(faction.faction_id * 10, faction.faction_id * 10, 1)

		# Each faction starts with 2 militia units
		for i in range(2):
			var unit_pos = start_pos + Vector3i(i, 0, 0)
			var unit = unit_manager.create_unit("militia", faction.faction_id, unit_pos)
			if unit:
				print("[IntegrationCoordinator]   Created militia for faction %d at %s" % [faction.faction_id, unit_pos])

	print("[IntegrationCoordinator] Unit system initialized (%d units)" % unit_manager.get_all_units().size())

func _initialize_combat_system() -> void:
	"""Initialize combat resolver"""
	print("[IntegrationCoordinator] Initializing combat system...")

	combat_resolver = CombatResolver.new()

	print("[IntegrationCoordinator] Combat system initialized")

func _initialize_economy_systems() -> void:
	"""Initialize all economy-related systems"""
	print("[IntegrationCoordinator] Initializing economy systems...")

	resource_manager = ResourceManager.new()
	production_system = ProductionSystem.new()
	trade_system = TradeSystem.new()
	scavenging_system = ScavengingSystem.new()
	population_system = PopulationSystem.new()

	print("[IntegrationCoordinator] Economy systems initialized")

func _initialize_culture_system() -> void:
	"""Initialize culture progression"""
	print("[IntegrationCoordinator] Initializing culture system...")

	culture_tree = CultureTree.new()
	culture_effects = CultureEffects.new()

	print("[IntegrationCoordinator] Culture system initialized")

func _initialize_event_system(game_state) -> void:
	"""Initialize event management"""
	print("[IntegrationCoordinator] Initializing event system...")

	event_manager = EventManager.new()
	event_manager.initialize(game_state)

	print("[IntegrationCoordinator] Event system initialized")

func _initialize_ai_systems(game_state) -> void:
	"""Initialize AI for all non-player factions"""
	print("[IntegrationCoordinator] Initializing AI systems...")

	faction_ais.clear()

	for faction in game_state.factions:
		if not faction.is_player:
			var ai = FactionAI.new(faction.faction_id, faction.ai_personality)
			faction_ais[faction.faction_id] = ai
			print("[IntegrationCoordinator]   Created %s AI for faction %d" % [faction.ai_personality, faction.faction_id])

	print("[IntegrationCoordinator] AI systems initialized (%d AI factions)" % faction_ais.size())

# ============================================================================
# TURN PROCESSING
# ============================================================================

func _on_turn_started(turn_number: int, faction_id: int) -> void:
	"""Process start of turn for a faction"""
	print("[IntegrationCoordinator] Turn %d started for faction %d" % [turn_number, faction_id])

	var game_state = GameManager.current_state
	if not game_state:
		push_error("[IntegrationCoordinator] No active game state")
		return

	var faction = game_state.get_faction(faction_id)
	if not faction:
		push_error("[IntegrationCoordinator] Invalid faction: %d" % faction_id)
		return

	# Process turn start
	_process_turn_start(faction, game_state)

	# If AI faction, plan and execute AI actions
	if not faction.is_player and faction_ais.has(faction_id):
		_process_ai_turn(faction_id, game_state)

func _process_turn_start(faction, game_state) -> void:
	"""Process beginning of turn for a faction"""

	# Economy: Add resource income
	if resource_manager:
		var income = {
			"scrap": 10 + faction.population.current * 2,
			"food": 5 + faction.population.current,
		}
		faction.resources.add_resources(income)
		print("[IntegrationCoordinator]   Faction %d income: +%d scrap, +%d food" % [faction.faction_id, income.scrap, income.food])

	# Economy: Process production queue
	if production_system:
		production_system.process_production(faction, 1)

	# Population: Process growth
	if population_system:
		population_system.process_turn(faction)

	# Culture: Add culture points
	var culture_income = 5 + faction.population.current
	faction.culture.points += culture_income

	# Events: Check for triggered events
	if event_manager:
		var events = event_manager.check_triggers(game_state, faction)
		if events and events.size() > 0:
			for event in events:
				EventBus.event_triggered.emit(event, faction.faction_id)

	# Update fog of war for faction units
	if fog_of_war and unit_manager:
		var faction_units = unit_manager.get_units_by_faction(faction.faction_id)
		for unit in faction_units:
			fog_of_war.update_unit_visibility(faction.faction_id, unit.position, 3)

func _process_ai_turn(faction_id: int, game_state) -> void:
	"""Let AI plan and execute actions for this turn"""
	var ai = faction_ais.get(faction_id)
	if not ai:
		return

	print("[IntegrationCoordinator]   AI faction %d planning turn..." % faction_id)

	# AI plans turn
	var actions = ai.plan_turn(faction_id, game_state)

	print("[IntegrationCoordinator]   AI faction %d planned %d actions" % [faction_id, actions.size()])

	# Execute AI actions
	for action in actions:
		_execute_ai_action(faction_id, action, game_state)

func _execute_ai_action(faction_id: int, action, game_state) -> void:
	"""Execute a single AI action"""
	# This is a simplified action executor
	# Real implementation would be more sophisticated

	match action.type:
		AIAction.ActionType.BUILD_UNIT:
			if production_system:
				var faction = game_state.get_faction(faction_id)
				production_system.add_to_queue(faction, "unit", action.unit_type)

		AIAction.ActionType.BUILD_BUILDING:
			if production_system:
				var faction = game_state.get_faction(faction_id)
				production_system.add_to_queue(faction, "building", action.building_type)

		AIAction.ActionType.MOVE_UNIT:
			if movement_system and unit_manager and map_data:
				var unit = unit_manager.get_unit(action.unit_id)
				if unit:
					var path = movement_system.find_path(map_data, unit.position, action.target_position)
					if path:
						movement_system.move_unit_along_path(unit, path, map_data)

		AIAction.ActionType.ATTACK:
			# Combat handled by combat system
			pass

		_:
			# Other actions...
			pass

func _on_turn_ended(turn_number: int) -> void:
	"""Process end of turn"""
	print("[IntegrationCoordinator] Turn %d ended" % turn_number)

	# Process any end-of-turn effects
	# (Most processing happens in turn_started)

# ============================================================================
# UNIT EVENTS
# ============================================================================

func _on_unit_created(unit_id: int, unit_type: String, faction_id: int, position: Vector3i) -> void:
	"""Handle unit creation"""
	print("[IntegrationCoordinator] Unit created: %s (faction %d) at %s" % [unit_type, faction_id, position])

	# Update fog of war
	if fog_of_war:
		fog_of_war.update_unit_visibility(faction_id, position, 3)

func _on_unit_moved(unit_id: int, from: Vector3i, to: Vector3i) -> void:
	"""Handle unit movement"""

	# Update fog of war
	if fog_of_war and unit_manager:
		var unit = unit_manager.get_unit(unit_id)
		if unit:
			fog_of_war.update_unit_visibility(unit.faction_id, to, 3)

# ============================================================================
# COMBAT EVENTS
# ============================================================================

func _on_combat_started(attacker_ids: Array, defender_ids: Array) -> void:
	"""Handle combat initiation"""
	print("[IntegrationCoordinator] Combat started: %d attackers vs %d defenders" % [attacker_ids.size(), defender_ids.size()])

	if not combat_resolver or not unit_manager:
		return

	# Get units
	var attackers = []
	var defenders = []

	for id in attacker_ids:
		var unit = unit_manager.get_unit(id)
		if unit:
			attackers.append(unit)

	for id in defender_ids:
		var unit = unit_manager.get_unit(id)
		if unit:
			defenders.append(unit)

	# Resolve combat
	var result = combat_resolver.auto_resolve(attackers, defenders)

	# Emit combat ended
	EventBus.combat_ended.emit(result)

func _on_combat_ended(result: Dictionary) -> void:
	"""Handle combat resolution"""
	print("[IntegrationCoordinator] Combat ended: %s" % result.get("outcome", "unknown"))

	# Show combat result in UI
	if UIManager:
		UIManager.show_combat_result(result)

	# Process loot
	if result.has("loot") and result.has("winner_faction_id"):
		var game_state = GameManager.current_state
		if game_state:
			var faction = game_state.get_faction(result.winner_faction_id)
			if faction and resource_manager:
				faction.resources.add_resources(result.loot)

# ============================================================================
# ECONOMY EVENTS
# ============================================================================

func _on_building_completed(faction_id: int, building_type: String) -> void:
	"""Handle building completion"""
	print("[IntegrationCoordinator] Building completed: %s (faction %d)" % [building_type, faction_id])

	# Apply building effects
	var game_state = GameManager.current_state
	if game_state:
		var faction = game_state.get_faction(faction_id)
		if faction:
			# Add building to faction's buildings list
			faction.buildings.append(building_type)

# ============================================================================
# EVENT SYSTEM
# ============================================================================

func _on_event_triggered(event_data: Dictionary, faction_id: int) -> void:
	"""Handle event triggering"""
	print("[IntegrationCoordinator] Event triggered: %s (faction %d)" % [event_data.get("title", "Unknown"), faction_id])

	# Show event dialog in UI (only for player faction)
	if faction_id == 0 and UIManager:
		UIManager.show_event_dialog(event_data)

# ============================================================================
# CLEANUP
# ============================================================================

func cleanup() -> void:
	"""Clean up all system instances"""
	print("[IntegrationCoordinator] Cleaning up systems...")

	map_data = null
	unit_manager = null
	combat_resolver = null
	resource_manager = null
	production_system = null
	trade_system = null
	scavenging_system = null
	population_system = null
	culture_tree = null
	culture_effects = null
	event_manager = null
	fog_of_war = null
	movement_system = null
	faction_ais.clear()

	print("[IntegrationCoordinator] Cleanup complete")
