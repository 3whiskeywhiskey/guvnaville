extends Node

## GameManager - Orchestrates high-level game flow
##
## This singleton manages the current game state and provides methods
## for starting, loading, saving, and ending games.

# ============================================================================
# PROPERTIES
# ============================================================================

## Current game state (null if no game active)
var current_state: GameState = null

## True if a game is currently in progress
var is_game_active: bool = false

## True if the game is paused
var is_paused: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("[GameManager] Initialized")

# ============================================================================
# GAME LIFECYCLE
# ============================================================================

## Start a new game with the provided settings
func start_new_game(settings: Dictionary) -> GameState:
	print("[GameManager] Starting new game...")

	# Validate settings
	if not _validate_settings(settings):
		push_error("[GameManager] Invalid game settings")
		return null

	# Check if data is loaded
	if not DataLoader.is_data_loaded:
		print("[GameManager] Loading game data first...")
		if not DataLoader.load_game_data():
			push_error("[GameManager] Failed to load game data")
			return null

	# Create new game state
	current_state = GameState.new()

	# Apply settings
	current_state.game_settings = settings.duplicate(true)

	# Set random seed
	var seed_value = settings.get("map_seed", randi())
	current_state.random_seed = seed_value
	seed(seed_value)

	# Initialize turn state
	current_state.turn_number = 1
	current_state.turn_state.current_turn = 1

	# Create factions
	var num_factions = settings.get("num_factions", 2)
	var player_faction_id = settings.get("player_faction_id", 0)

	for i in range(num_factions):
		var faction = FactionState.new(
			i,
			"Faction %d" % i,
			i == player_faction_id
		)

		# Set AI personality for AI factions
		if not faction.is_player:
			var personalities = ["aggressive", "defensive", "economic", "balanced"]
			faction.ai_personality = personalities[i % personalities.size()]

		current_state.add_faction(faction)

	# Initialize world (basic setup - full map generation will come later)
	_initialize_world(current_state)

	# Mark game as active
	is_game_active = true
	is_paused = false

	# Emit game started signal
	EventBus.game_started.emit(current_state)

	print("[GameManager] New game started with %d factions" % num_factions)

	return current_state

## Load a saved game
func load_game(save_name: String) -> GameState:
	print("[GameManager] Loading game: %s" % save_name)

	# Load from SaveManager
	var loaded_state = SaveManager.load_game(save_name)

	if loaded_state == null:
		push_error("[GameManager] Failed to load game: %s" % save_name)
		return null

	# Validate loaded state
	if not loaded_state.validate():
		push_error("[GameManager] Loaded game state is invalid")
		return null

	# Set as current state
	current_state = loaded_state
	is_game_active = true
	is_paused = false

	# Emit game loaded signal
	EventBus.game_loaded.emit(current_state)

	print("[GameManager] Game loaded successfully (Turn %d)" % current_state.turn_number)

	return current_state

## Save the current game
func save_game(save_name: String) -> bool:
	if not is_game_active or current_state == null:
		push_error("[GameManager] No active game to save")
		return false

	print("[GameManager] Saving game: %s" % save_name)

	var success = SaveManager.save_game(save_name, current_state)

	if success:
		print("[GameManager] Game saved successfully")
	else:
		push_error("[GameManager] Failed to save game")

	return success

## End the current game
func end_game(victory_type: String, winning_faction: int) -> void:
	print("[GameManager] Game ended - Victory type: %s, Winner: %d" % [victory_type, winning_faction])

	# Emit game ended signal
	EventBus.game_ended.emit(victory_type, winning_faction)

	# Clean up
	is_game_active = false
	is_paused = false
	current_state = null

## Pause the game
func pause_game() -> void:
	if not is_game_active:
		push_warning("[GameManager] Cannot pause - no active game")
		return

	is_paused = true
	EventBus.game_paused.emit()
	print("[GameManager] Game paused")

## Resume the game
func resume_game() -> void:
	if not is_game_active:
		push_warning("[GameManager] Cannot resume - no active game")
		return

	is_paused = false
	EventBus.game_resumed.emit()
	print("[GameManager] Game resumed")

## Get a specific faction
func get_faction(faction_id: int) -> FactionState:
	if current_state == null:
		return null
	return current_state.get_faction(faction_id)

# ============================================================================
# PRIVATE METHODS
# ============================================================================

func _validate_settings(settings: Dictionary) -> bool:
	# Check required fields
	if not settings.has("num_factions"):
		push_error("[GameManager] Settings missing 'num_factions'")
		return false

	var num_factions = settings["num_factions"]
	if num_factions < 1 or num_factions > 8:
		push_error("[GameManager] Invalid num_factions: %d (must be 1-8)" % num_factions)
		return false

	# Check difficulty
	var difficulty = settings.get("difficulty", "normal")
	var valid_difficulties = ["easy", "normal", "hard", "brutal"]
	if not difficulty in valid_difficulties:
		push_error("[GameManager] Invalid difficulty: %s" % difficulty)
		return false

	# Check player faction ID
	var player_faction_id = settings.get("player_faction_id", 0)
	if player_faction_id < 0 or player_faction_id >= num_factions:
		push_error("[GameManager] Invalid player_faction_id: %d" % player_faction_id)
		return false

	return true

func _initialize_world(game_state: GameState) -> void:
	# Basic world initialization
	# Full map generation will be implemented in the Map System module

	var world = game_state.world_state

	# Create a small test map
	for x in range(10):
		for y in range(10):
			var pos = Vector3i(x, y, 1)
			var tile = Tile.new(pos, "residential", "rubble")
			tile.scavenge_value = randi() % 100
			world.set_tile(pos, tile)

	print("[GameManager] Initialized world with %d tiles" % world.tiles.size())

	# Initialize fog of war for all factions
	for faction in game_state.factions:
		world.fog_of_war[faction.faction_id] = []

		# Give each faction visibility around their starting position
		var start_pos = Vector3i(faction.faction_id * 2, faction.faction_id * 2, 1)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var visible_pos = start_pos + Vector3i(dx, dy, 0)
				if world.is_valid_position(visible_pos):
					world.set_visibility(faction.faction_id, visible_pos, true)
