extends Node

## SaveManager - Handles game save/load with integrity verification
##
## This singleton manages saving and loading game states with checksum
## verification to ensure save file integrity.

# ============================================================================
# PROPERTIES
# ============================================================================

## Platform-specific save directory
var save_directory: String = ""

## Whether autosaves are enabled
var autosave_enabled: bool = true

## Number of turns between autosaves
var autosave_interval: int = 5

## Save file version
const SAVE_VERSION = "1.0.0"

## Save file extension
const SAVE_EXTENSION = ".json"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	save_directory = _get_save_directory()
	print("[SaveManager] Save directory: %s" % save_directory)

	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(save_directory):
		DirAccess.make_dir_recursive_absolute(save_directory)

# ============================================================================
# SAVE/LOAD
# ============================================================================

## Save a game state to disk
func save_game(save_name: String, game_state: GameState) -> bool:
	if save_name.is_empty():
		push_error("[SaveManager] Save name cannot be empty")
		return false

	if game_state == null:
		push_error("[SaveManager] Cannot save null game state")
		return false

	# Sanitize save name
	var sanitized_name = _sanitize_filename(save_name)
	var file_path = save_directory.path_join(sanitized_name + SAVE_EXTENSION)

	print("[SaveManager] Saving game to: %s" % file_path)

	# Serialize game state
	var game_data = game_state.to_dict()

	# Create save file structure
	var save_data = {
		"version": SAVE_VERSION,
		"save_name": save_name,
		"timestamp": Time.get_datetime_string_from_system(),
		"turn_number": game_state.turn_number,
		"game_state": game_data,
		"checksums": _calculate_checksums(game_data)
	}

	# Convert to JSON
	var json_string = JSON.stringify(save_data, "\t")

	# Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to open file for writing: %s" % file_path)
		return false

	file.store_string(json_string)
	file.close()

	print("[SaveManager] Game saved successfully")
	return true

## Load a game state from disk
func load_game(save_name: String) -> GameState:
	if save_name.is_empty():
		push_error("[SaveManager] Save name cannot be empty")
		return null

	# Sanitize save name
	var sanitized_name = _sanitize_filename(save_name)
	var file_path = save_directory.path_join(sanitized_name + SAVE_EXTENSION)

	if not FileAccess.file_exists(file_path):
		push_error("[SaveManager] Save file not found: %s" % file_path)
		return null

	print("[SaveManager] Loading game from: %s" % file_path)

	# Read file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Failed to open file for reading: %s" % file_path)
		return null

	var json_string = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("[SaveManager] JSON parse error at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message()
		])
		return null

	var save_data = json.data

	# Verify version
	var version = save_data.get("version", "")
	if version != SAVE_VERSION:
		push_warning("[SaveManager] Save file version mismatch: %s vs %s" % [version, SAVE_VERSION])
		# Could implement migration here

	# Verify checksums
	var game_data = save_data.get("game_state", {})
	var stored_checksums = save_data.get("checksums", {})
	var calculated_checksums = _calculate_checksums(game_data)

	if stored_checksums.get("game_state", "") != calculated_checksums.get("game_state", ""):
		push_error("[SaveManager] Checksum mismatch - save file may be corrupted")
		return null

	# Deserialize game state
	var game_state = GameState.new()
	game_state.from_dict(game_data)

	print("[SaveManager] Game loaded successfully")
	return game_state

## List all available save files
func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []

	var dir = DirAccess.open(save_directory)
	if dir == null:
		push_error("[SaveManager] Cannot open save directory: %s" % save_directory)
		return saves

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			var full_path = save_directory.path_join(file_name)
			var save_info = _get_save_info(full_path)
			if not save_info.is_empty():
				saves.append(save_info)

		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort by timestamp (newest first)
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	return saves

## Delete a save file
func delete_save(save_name: String) -> bool:
	if save_name.is_empty():
		push_error("[SaveManager] Save name cannot be empty")
		return false

	var sanitized_name = _sanitize_filename(save_name)
	var file_path = save_directory.path_join(sanitized_name + SAVE_EXTENSION)

	if not FileAccess.file_exists(file_path):
		push_error("[SaveManager] Save file not found: %s" % file_path)
		return false

	var dir = DirAccess.open(save_directory)
	if dir == null:
		push_error("[SaveManager] Cannot open save directory")
		return false

	var error = dir.remove(file_path)
	if error != OK:
		push_error("[SaveManager] Failed to delete save file: %s" % file_path)
		return false

	print("[SaveManager] Deleted save file: %s" % file_path)
	return true

## Get the save directory path
func get_save_directory() -> String:
	return save_directory

## Verify save file integrity using checksums
func verify_save_integrity(save_name: String) -> bool:
	var sanitized_name = _sanitize_filename(save_name)
	var file_path = save_directory.path_join(sanitized_name + SAVE_EXTENSION)

	if not FileAccess.file_exists(file_path):
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return false

	var save_data = json.data
	var game_data = save_data.get("game_state", {})
	var stored_checksums = save_data.get("checksums", {})
	var calculated_checksums = _calculate_checksums(game_data)

	return stored_checksums.get("game_state", "") == calculated_checksums.get("game_state", "")

## Create an autosave (overwrites previous autosave)
func create_autosave(game_state: GameState) -> bool:
	return save_game("autosave", game_state)

# ============================================================================
# PRIVATE METHODS
# ============================================================================

func _get_save_directory() -> String:
	# Use user data directory
	return OS.get_user_data_dir().path_join("saves")

func _sanitize_filename(filename: String) -> String:
	# Remove or replace invalid filename characters
	var sanitized = filename
	var invalid_chars = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]

	for char in invalid_chars:
		sanitized = sanitized.replace(char, "_")

	return sanitized

func _calculate_checksums(data: Dictionary) -> Dictionary:
	# Calculate SHA-256 hash of the serialized data
	var json_string = JSON.stringify(data)
	var hash = json_string.sha256_text()

	return {
		"game_state": hash,
		"world_state": hash  # Could calculate separate hashes for different sections
	}

func _get_save_info(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var save_data = json.data

	var file_name = file_path.get_file().trim_suffix(SAVE_EXTENSION)

	return {
		"name": save_data.get("save_name", file_name),
		"timestamp": save_data.get("timestamp", ""),
		"turn_number": save_data.get("turn_number", 0),
		"factions": save_data.get("game_state", {}).get("factions", []).size(),
		"file_size": FileAccess.get_file_as_bytes(file_path).size()
	}
