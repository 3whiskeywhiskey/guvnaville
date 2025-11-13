extends RefCounted
class_name GameResource

## GameResource - Data class for resource definitions
##
## Represents a type of resource in the game (not an instance).
## Used to define resource properties like scrap, components, ammo, etc.

# ============================================================================
# PROPERTIES
# ============================================================================

## Resource type identifier (e.g., "scrap", "components", "ammo")
var resource_type: String = ""

## Human-readable display name
var display_name: String = ""

## Description of the resource
var description: String = ""

## Path to the icon asset
var icon_path: String = ""

## Whether this resource is stockpiled
var is_stockpiled: bool = true

## Whether this resource is strategic (limited, valuable)
var is_strategic: bool = false

## Base trade value
var base_value: int = 1

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(
	p_resource_type: String = "",
	p_display_name: String = "",
	p_description: String = ""
) -> void:
	resource_type = p_resource_type
	display_name = p_display_name
	description = p_description

# ============================================================================
# SERIALIZATION
# ============================================================================

## Serialize resource to dictionary
func to_dict() -> Dictionary:
	return {
		"resource_type": resource_type,
		"display_name": display_name,
		"description": description,
		"icon_path": icon_path,
		"is_stockpiled": is_stockpiled,
		"is_strategic": is_strategic,
		"base_value": base_value
	}

## Deserialize resource from dictionary
func from_dict(data: Dictionary) -> void:
	resource_type = data.get("resource_type", "")
	display_name = data.get("display_name", "")
	description = data.get("description", "")
	icon_path = data.get("icon_path", "")
	is_stockpiled = data.get("is_stockpiled", true)
	is_strategic = data.get("is_strategic", false)
	base_value = data.get("base_value", 1)
