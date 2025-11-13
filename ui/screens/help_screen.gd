extends Control
class_name HelpScreen

## In-game help system with searchable content
## Provides comprehensive information about game mechanics

@onready var tab_container: TabContainer = $PanelContainer/VBoxContainer/TabContainer
@onready var search_box: LineEdit = $PanelContainer/VBoxContainer/SearchBox
@onready var close_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/CloseButton

var help_content: Dictionary = {}

func _ready() -> void:
	# Load help content
	_load_help_content()

	# Connect signals
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if search_box:
		search_box.text_changed.connect(_on_search_changed)

	# Setup keyboard shortcut
	set_process_input(true)

func _input(event: InputEvent) -> void:
	"""Handle keyboard shortcuts"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

func _load_help_content() -> void:
	"""Load help content for each tab"""
	help_content = {
		"getting_started": _get_getting_started_content(),
		"resources": _get_resources_content(),
		"units": _get_units_content(),
		"culture": _get_culture_content(),
		"events": _get_events_content(),
		"ai": _get_ai_content(),
		"shortcuts": _get_shortcuts_content(),
		"faq": _get_faq_content()
	}

	# Populate tabs
	_populate_tabs()

func _populate_tabs() -> void:
	"""Populate tab content"""
	if not tab_container:
		return

	# Clear existing tabs
	for child in tab_container.get_children():
		child.queue_free()

	# Create tabs
	_add_tab("Getting Started", help_content["getting_started"])
	_add_tab("Resources & Economy", help_content["resources"])
	_add_tab("Units & Combat", help_content["units"])
	_add_tab("Culture System", help_content["culture"])
	_add_tab("Events", help_content["events"])
	_add_tab("AI Opponents", help_content["ai"])
	_add_tab("Keyboard Shortcuts", help_content["shortcuts"])
	_add_tab("FAQ", help_content["faq"])

func _add_tab(title: String, content: String) -> void:
	"""Add a tab with content"""
	var scroll := ScrollContainer.new()
	scroll.name = title

	var rich_text := RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = content
	rich_text.fit_content = true
	rich_text.custom_minimum_size = Vector2(600, 400)

	scroll.add_child(rich_text)
	tab_container.add_child(scroll)

func _on_search_changed(search_text: String) -> void:
	"""Filter content based on search"""
	# TODO: Implement search functionality
	pass

func _on_close_pressed() -> void:
	"""Close help screen"""
	queue_free()

# Help content functions

func _get_getting_started_content() -> String:
	return """[b][font_size=24]Getting Started[/font_size][/b]

[b]What is Guvnaville?[/b]
Guvnaville is a turn-based strategy game set in a post-apocalyptic city. You lead a faction competing for resources, territory, and survival against AI opponents.

[b]Your First Game[/b]
1. Start a new game from the main menu
2. Follow the tutorial (recommended for first-time players)
3. Select your faction's starting units
4. Begin exploring and scavenging

[b]Victory Conditions[/b]
Win by achieving one of these goals:
• [b]Domination[/b]: Eliminate all other factions
• [b]Economic[/b]: Accumulate the most resources
• [b]Cultural[/b]: Complete the culture tree
• [b]Survival[/b]: Last the longest (endurance mode)

[b]Basic Controls[/b]
• [b]Left Click[/b]: Select units/tiles
• [b]Right Click[/b]: Context menu
• [b]WASD/Arrows[/b]: Pan camera
• [b]Mouse Wheel[/b]: Zoom
• [b]Space/Enter[/b]: End turn
• [b]F1[/b]: Help (this screen)
• [b]ESC[/b]: Menu/Cancel
"""

func _get_resources_content() -> String:
	return """[b][font_size=24]Resources & Economy[/font_size][/b]

[b]Resource Types[/b]

[b]Food[/b]
• Keeps population fed
• Consumed each turn
• Found: Residential areas
• Low food = population decline

[b]Water[/b]
• Essential for survival
• Consumed each turn
• Found: Parks, water sources
• Critical shortage causes rapid population loss

[b]Materials[/b]
• Used for construction
• Found: Industrial areas
• Required for buildings and units

[b]Scrap Metal[/b]
• Raw material
• Can be refined to materials
• Found: Ruins, debris
• Valuable for trading

[b]Fuel[/b]
• Powers vehicles
• Enables long-distance movement
• Found: Gas stations, industrial areas

[b]Medicine[/b]
• Keeps population healthy
• Treats injuries
• Found: Hospitals, pharmacies

[b]Electronics[/b]
• Advanced technology
• Required for upgrades
• Found: Commercial areas

[b]Components[/b]
• High-tech parts
• Used for advanced buildings
• Found: Electronic stores, labs

[b]Ammunition[/b]
• Consumed in combat
• Required for ranged attacks
• Found: Military sites, gun stores

[b]Weapons[/b]
• Equips combat units
• Improves effectiveness
• Found: Military sites, police stations

[b]Gathering Resources[/b]
• [b]Scavenging[/b]: Search locations for resources
• [b]Production[/b]: Produce resources at buildings
• [b]Trading[/b]: Exchange with other factions
• [b]Events[/b]: Random discoveries

[b]Resource Management Tips[/b]
• Always maintain food/water reserves
• Diversify resource sources
• Don't hoard - use resources to grow
• Trade excess for needed resources
• Plan ahead for production costs
"""

func _get_units_content() -> String:
	return """[b][font_size=24]Units & Combat[/font_size][/b]

[b]Unit Types[/b]

[b]Scavengers[/b]
• Fast movement
• Good at finding resources
• Weak in combat
• Best for: Resource gathering

[b]Soldiers[/b]
• Strong in combat
• Slower movement
• Can capture locations
• Best for: Fighting, defense

[b]Builders[/b]
• Construct buildings
• Repair structures
• Weak in combat
• Best for: Expansion

[b]Traders[/b]
• Negotiate trades
• Good at avoiding conflict
• Can establish trade routes
• Best for: Diplomacy, economy

[b]Scouts[/b]
• Very fast
• Reveals fog of war
• Weak in combat
• Best for: Exploration

[b]Movement[/b]
• Units have movement points each turn
• Different terrain costs different amounts
• Streets: 1 point per tile
• Ruins: 2 points per tile
• Difficult terrain: 3+ points per tile

[b]Combat Basics[/b]
1. Move unit adjacent to enemy
2. Select Attack action
3. Combat is automatically resolved

[b]Combat Factors[/b]
• [b]Unit Strength[/b]: Attack vs Defense
• [b]Health[/b]: Damaged units less effective
• [b]Terrain[/b]: High ground gives bonuses
• [b]Equipment[/b]: Weapons improve damage
• [b]Experience[/b]: Veterans fight better

[b]Combat Tips[/b]
• Don't attack when outnumbered
• Use terrain to your advantage
• Heal units between battles
• Protect weak units
• Focus fire on strong enemies

[b]Special Abilities[/b]
Some units have special abilities:
• [b]Ambush[/b]: Extra damage on first strike
• [b]Fortify[/b]: Increased defense when stationary
• [b]Heal[/b]: Restore health to nearby units
• [b]Scout[/b]: Increased vision range
"""

func _get_culture_content() -> String:
	return """[b][font_size=24]Culture System[/font_size][/b]

[b]What is Culture?[/b]
Culture represents your faction's development and specialization. Earn Culture Points by completing actions, then spend them on upgrades.

[b]Earning Culture Points[/b]
• Scavenging locations
• Winning battles
• Constructing buildings
• Completing events
• Trading with factions
• Surviving turns

[b]Culture Branches[/b]

[b]Military Branch[/b]
• Improved combat units
• Better weapons and armor
• Faster unit production
• Advanced tactics

[b]Economic Branch[/b]
• Increased resource gathering
• Better trade deals
• Reduced production costs
• Resource efficiency bonuses

[b]Technology Branch[/b]
• Advanced buildings
• Better equipment
• Unlock special units
• Research bonuses

[b]Survival Branch[/b]
• Faster population growth
• Better food efficiency
• Health bonuses
• Disaster resistance

[b]Strategy Tips[/b]
• [b]Specialize[/b]: Focus on one branch for strong bonuses
• [b]Balance[/b]: Spread points for versatility
• [b]Adapt[/b]: Choose based on game situation
• [b]Plan ahead[/b]: Some upgrades require prerequisites

[b]Culture Tree Navigation[/b]
• Click Culture button to open tree
• Hover over nodes to see details
• Click to purchase (if you have points)
• Prerequisites shown with arrows
• Completed nodes highlighted
"""

func _get_events_content() -> String:
	return """[b][font_size=24]Events[/font_size][/b]

[b]What are Events?[/b]
Random events occur throughout the game, presenting challenges and opportunities. Your choices matter!

[b]Event Types[/b]

[b]Resource Events[/b]
• Discovery of caches
• Resource shortages
• Trading opportunities
• Example: Find abandoned warehouse

[b]Combat Events[/b]
• Raider attacks
• Bandit encounters
• Faction conflicts
• Example: Ambush on patrol

[b]Social Events[/b]
• Refugees arrive
• Internal disputes
• Faction relations
• Example: Refugees seek shelter

[b]Environmental Events[/b]
• Weather changes
• Natural disasters
• Contamination
• Example: Toxic storm approaching

[b]Making Choices[/b]
Most events offer choices:
• Each choice has consequences
• Consider short-term vs long-term
• Some choices require resources
• Your culture affects available options

[b]Event Tips[/b]
• Read carefully before choosing
• Consider your current situation
• Some events chain into others
• Choices affect faction reputation
• Keep resources for emergencies
"""

func _get_ai_content() -> String:
	return """[b][font_size=24]AI Opponents[/font_size][/b]

[b]AI Personalities[/b]

[b]Aggressive[/b]
• Attacks frequently
• Expands rapidly
• Weak economy
• Strategy: Fortify defenses, counter-attack

[b]Defensive[/b]
• Builds strong bases
• Rarely attacks
• Slow expansion
• Strategy: Aggressive expansion before they fortify

[b]Economic[/b]
• Focuses on resources
• Avoids combat
• Strong late game
• Strategy: Attack early, disrupt economy

[b]Balanced[/b]
• Adapts to situations
• Unpredictable
• Well-rounded
• Strategy: Stay flexible, watch for patterns

[b]Diplomatic[/b]
• Seeks alliances
• Proposes trades
• Avoids conflict
• Strategy: Trade or ignore them

[b]AI Behavior[/b]
• Takes turns after player
• Follows same rules
• Can make mistakes
• Responds to player actions
• Remembers past interactions

[b]Dealing with AI[/b]
• [b]Trading[/b]: Propose fair deals
• [b]Diplomacy[/b]: Build reputation
• [b]Warfare[/b]: Strike when weak
• [b]Espionage[/b]: Watch their actions

[b]Difficulty Levels[/b]
• [b]Easy[/b]: AI makes mistakes, weak economy
• [b]Normal[/b]: Fair challenge, balanced AI
• [b]Hard[/b]: Smart AI, resource bonuses
• [b]Expert[/b]: Very smart, significant bonuses
"""

func _get_shortcuts_content() -> String:
	return """[b][font_size=24]Keyboard Shortcuts[/font_size][/b]

[b]Essential Controls[/b]
[b]Space / Enter[/b] - End Turn
[b]ESC[/b] - Open Menu / Cancel
[b]F1[/b] - Help Screen
[b]F5[/b] - Quick Save
[b]F9[/b] - Quick Load

[b]Camera Controls[/b]
[b]W / Up Arrow[/b] - Pan North
[b]A / Left Arrow[/b] - Pan West
[b]S / Down Arrow[/b] - Pan South
[b]D / Right Arrow[/b] - Pan East
[b]+ / Mouse Wheel Up[/b] - Zoom In
[b]- / Mouse Wheel Down[/b] - Zoom Out
[b]Home[/b] - Reset Camera

[b]Unit Controls[/b]
[b]Tab[/b] - Cycle Through Units
[b]Shift+Tab[/b] - Cycle Backward
[b]M[/b] - Move Unit
[b]A[/b] - Attack
[b]S[/b] - Scavenge
[b]F[/b] - Fortify
[b]H[/b] - Heal

[b]UI Controls[/b]
[b]C[/b] - Open Culture Tree
[b]B[/b] - Open Building Menu
[b]T[/b] - Open Trade Dialog
[b]I[/b] - Open Inventory
[b]N[/b] - Next Notification

[b]Selection Controls[/b]
[b]Left Click[/b] - Select Unit/Tile
[b]Right Click[/b] - Context Menu
[b]Ctrl+Left Click[/b] - Add to Selection
[b]Shift+Left Click[/b] - Range Selection
[b]Ctrl+A[/b] - Select All Units

[b]Quick Actions[/b]
[b]Delete[/b] - Disband Unit
[b]P[/b] - Pause Game
[b].[/b] - Skip Unit Turn
[b]Ctrl+Z[/b] - Undo (if available)

[b]Debug[/b] (if enabled)
[b]F12[/b] - Toggle Debug Info
[b]Ctrl+D[/b] - Toggle Developer Console
"""

func _get_faq_content() -> String:
	return """[b][font_size=24]Frequently Asked Questions[/font_size][/b]

[b]Q: How do I win the game?[/b]
A: Achieve one of the victory conditions: Domination (eliminate all factions), Economic (accumulate most resources), Cultural (complete culture tree), or Survival (last the longest).

[b]Q: Why can't I scavenge a location?[/b]
A: Locations have limited scavenge opportunities. Once depleted, they can't be scavenged again. Look for fresh locations.

[b]Q: How do I heal units?[/b]
A: Units heal slowly each turn if not in combat. Use medic units or rest in cities for faster healing. Medicine resources speed recovery.

[b]Q: What happens if I run out of food?[/b]
A: Your population will decline each turn without food. This reduces your action capacity and can lead to game over. Always maintain food reserves!

[b]Q: How do I trade with AI factions?[/b]
A: Send a trader unit to an AI settlement and select the Trade action. Propose fair deals for better success rates.

[b]Q: Can I undo my moves?[/b]
A: Generally no, but you can reload a save if needed. Use F5 to quick save before risky actions.

[b]Q: Why won't my unit move?[/b]
A: Units may be out of movement points, blocked by enemies, or the path may be invalid. Check terrain costs and obstacles.

[b]Q: How do I see enemy units?[/b]
A: Only units in your vision range are visible. Use scouts to reveal fog of war and discover enemies.

[b]Q: What's the best strategy?[/b]
A: It depends on your playstyle! Aggressive expansion, economic buildup, and balanced approaches can all work.

[b]Q: How do I report bugs?[/b]
A: See RELEASE_NOTES for bug reporting information. Include save files and screenshots if possible.

[b]Q: Will there be updates?[/b]
A: Check the project repository for the development roadmap and planned features.
"""
