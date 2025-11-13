extends Node

## TypesRegistry - Global type preloader for Godot 4.5.1 compatibility
##
## This autoload ensures all custom types are loaded before other scripts need them.
## In Godot 4.5.1, class_name registration timing changed, requiring explicit preloads.
## We load in dependency order: leaf types first, then types that depend on them.

# Core types (no dependencies)
const Tile = preload("res://core/types/tile.gd")
const Building = preload("res://core/types/building.gd")
const Unit = preload("res://core/types/unit.gd")
const GameResource = preload("res://core/types/game_resource.gd")

# State types (depend on core types) - load in dependency order
const TurnState = preload("res://core/state/turn_state.gd")
const FactionState = preload("res://core/state/faction_state.gd")
const WorldState = preload("res://core/state/world_state.gd")
const GameState = preload("res://core/state/game_state.gd")

func _ready() -> void:
	# Types are loaded by the preload statements above
	print("[TypesRegistry] All core types registered")
