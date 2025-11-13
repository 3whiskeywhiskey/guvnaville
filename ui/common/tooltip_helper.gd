extends Node
class_name TooltipHelper

## Helper functions for adding tooltips to UI elements
## This can be used throughout the game to easily add tooltip functionality

static func add_tooltip(control: Control, text: String) -> void:
	"""Add tooltip to a control"""
	if not control:
		return

	# Store tooltip text in metadata
	control.set_meta("tooltip_text", text)

	# Connect signals if not already connected
	if not control.mouse_entered.is_connected(_on_tooltip_mouse_entered):
		control.mouse_entered.connect(_on_tooltip_mouse_entered.bind(control))

	if not control.mouse_exited.is_connected(_on_tooltip_mouse_exited):
		control.mouse_exited.connect(_on_tooltip_mouse_exited.bind(control))

static func _on_tooltip_mouse_entered(control: Control) -> void:
	"""Show tooltip when mouse enters control"""
	if not control or not control.has_meta("tooltip_text"):
		return

	var text: String = control.get_meta("tooltip_text")
	if text.is_empty():
		return

	# Get global position of control
	var pos := control.get_global_rect().position
	pos.y += control.get_global_rect().size.y + 5

	# Show through UIManager if available
	if has_node("/root/UIManager"):
		var ui_manager = get_node("/root/UIManager")
		if ui_manager.has_method("show_tooltip"):
			ui_manager.show_tooltip(text, pos)

static func _on_tooltip_mouse_exited(control: Control) -> void:
	"""Hide tooltip when mouse exits control"""
	# Hide through UIManager if available
	if has_node("/root/UIManager"):
		var ui_manager = get_node("/root/UIManager")
		if ui_manager.has_method("hide_tooltip"):
			ui_manager.hide_tooltip()

static func format_tooltip_with_shortcut(title: String, description: String, shortcut: String = "") -> String:
	"""Format a tooltip with title, description, and optional keyboard shortcut"""
	var text := "[b]%s[/b]\n\n%s" % [title, description]

	if not shortcut.is_empty():
		text += "\n\n[i]Shortcut: [color=yellow]%s[/color][/i]" % shortcut

	return text

static func add_resource_tooltip(control: Control, resource_name: String, description: String) -> void:
	"""Add a resource-specific tooltip"""
	var text := "[b]%s[/b]\n\n%s\n\n[i]Gain by scavenging, trading, or production.[/i]" % [resource_name, description]
	add_tooltip(control, text)

## Tooltip definitions for common UI elements
class TooltipTexts:
	# Main Menu tooltips
	const NEW_GAME := "Start a new game of Guvnaville. You'll lead a faction in the post-apocalyptic ruins."
	const LOAD_GAME := "Load a previously saved game and continue your campaign."
	const SETTINGS := "Adjust game settings including graphics, audio, and controls."
	const QUIT := "Exit Guvnaville and return to desktop."
	const TUTORIAL := "Replay the tutorial to learn game mechanics."

	# Resource tooltips
	const FOOD := "Food keeps your population fed. Consumed each turn. Found in residential areas."
	const MATERIALS := "Materials are used for building structures and producing units. Found in industrial areas."
	const FUEL := "Fuel powers vehicles and generators. Essential for advanced operations."
	const MEDICINE := "Medicine keeps your population healthy and treats injuries."
	const ELECTRONICS := "Electronics are advanced components used for technology."
	const WEAPONS := "Weapons equip combat units and improve their effectiveness."
	const WATER := "Water is essential for survival. Consumed by population each turn."
	const SCRAP := "Scrap metal can be refined into materials or traded."
	const COMPONENTS := "Components are used for advanced buildings and equipment."
	const AMMUNITION := "Ammunition is consumed during combat. Required for ranged attacks."

	# Game action tooltips
	const END_TURN := "End your turn and allow AI opponents to act. Resources will be consumed and produced."
	const SAVE_GAME := "Save your current game progress. You can have multiple save files."
	const LOAD_SAVE := "Load a saved game and return to that point."
	const SCAVENGE := "Search this location for resources. Each location has limited scavenge opportunities."
	const MOVE_UNIT := "Move the selected unit to a new location. Units have limited movement per turn."
	const ATTACK := "Attack an enemy unit. Combat is resolved based on unit strength and terrain."
	const BUILD := "Construct a building at this location. Requires resources and time."
	const PRODUCE := "Add a unit or building to the production queue. Takes multiple turns."
	const TRADE := "Negotiate a trade with another faction. Exchange resources for mutual benefit."

	# HUD tooltips
	const TURN_INDICATOR := "Shows the current turn number and active player. Each turn represents one day."
	const MINIMAP := "Overview of the entire map. Click to quickly navigate. Shows faction territories."
	const NOTIFICATION := "Recent game events and alerts. Click to dismiss or view details."
	const CULTURE_BUTTON := "Open the culture tree to spend culture points on upgrades and abilities."
	const HELP_BUTTON := "Open the help screen with game information and controls."

	# Dialog tooltips
	const CONFIRM := "Confirm this action and close the dialog."
	const CANCEL := "Cancel this action and return to the game."
	const CLOSE := "Close this window and return to the game."

	# Unit tooltips
	const UNIT_HEALTH := "Current health of this unit. Units with low health are less effective in combat."
	const UNIT_MOVEMENT := "Movement points remaining this turn. Different terrain costs different amounts."
	const UNIT_ATTACK := "Attack strength of this unit. Higher values deal more damage."
	const UNIT_DEFENSE := "Defense strength of this unit. Higher values reduce incoming damage."

	# Building tooltips
	const BUILDING_HEALTH := "Building integrity. Damaged buildings provide fewer benefits."
	const BUILDING_PRODUCTION := "Current production queue. Items are produced in order."
	const BUILDING_GARRISON := "Units stationed in this building. Garrisoned units defend the building."
