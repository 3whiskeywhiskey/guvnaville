# UI System Interface Contract

**Module**: UI System (`ui/`)
**Layer**: 4 (Presentation Layer)
**Agent**: Agent 9
**Version**: 1.0
**Last Updated**: 2025-11-12

---

## Executive Summary

The UI System provides all player-facing interfaces, screens, dialogs, and HUD elements. It is a **read-only consumer** of game state, receiving updates via EventBus signals and displaying information to the player. The UI System handles user input and translates it into commands for the game systems.

### Key Characteristics
- **Read-Only**: Never directly modifies game state
- **Event-Driven**: Updates via EventBus signals
- **Modular**: Screens, HUD, and dialogs are independent components
- **Responsive**: Updates within 16ms (60 FPS target)
- **Accessible**: Supports keyboard-only navigation

---

## Module Overview

### Purpose
Provide intuitive, responsive user interfaces for all game interactions including menus, HUD, dialogs, and input handling.

### Responsibilities
1. **Screen Management**: Main menu, game screen, settings, and screen transitions
2. **HUD Display**: Real-time display of resources, turn counter, notifications
3. **Dialog Management**: Event popups, combat results, production queues
4. **Input Handling**: Keyboard, mouse, and input action processing
5. **State Visualization**: Connect UI elements to game state (read-only)
6. **User Feedback**: Visual/audio feedback for player actions

### Dependencies
- **Core Foundation** (Layer 0): GameState, EventBus, TurnManager
- **Map System** (Layer 1): MapData, Tile information (read-only)
- **Unit System** (Layer 2): Unit information (read-only)
- **Combat System** (Layer 2): CombatResult data (read-only)
- **Economy System** (Layer 2): Resource data (read-only)
- **Culture System** (Layer 1): Culture tree data (read-only)
- **Event System** (Layer 1): EventInstance data (read-only)

**Dependency Type**: Read-only access to all game systems via EventBus signals

---

## Module Structure

```
ui/
├── screens/
│   ├── main_menu.gd           # Main menu controller
│   ├── main_menu.tscn         # Main menu scene
│   ├── game_screen.gd         # Main game screen controller
│   ├── game_screen.tscn       # Main game screen scene
│   ├── settings.gd            # Settings controller
│   └── settings.tscn          # Settings scene
│
├── hud/
│   ├── resource_bar.gd        # Resource display controller
│   ├── resource_bar.tscn      # Resource display scene
│   ├── turn_indicator.gd      # Turn counter controller
│   ├── turn_indicator.tscn    # Turn counter scene
│   ├── minimap.gd             # Minimap controller
│   ├── minimap.tscn           # Minimap scene
│   └── notification_manager.gd # Notification system
│
├── dialogs/
│   ├── event_dialog.gd        # Event popup controller
│   ├── event_dialog.tscn      # Event popup scene
│   ├── combat_dialog.gd       # Combat result controller
│   ├── combat_dialog.tscn     # Combat result scene
│   ├── production_dialog.gd   # Production queue controller
│   └── production_dialog.tscn # Production queue scene
│
├── ui_manager.gd              # Main UI orchestrator (singleton)
├── input_handler.gd           # Input action handler
└── theme/
    └── game_theme.tres        # UI theme resource
```

---

## Public API

### UIManager (Singleton)

Main UI orchestration singleton, accessible globally as `UIManager`.

#### Initialization

```gdscript
func initialize(game_state: GameState) -> void
```
**Description**: Initialize UI system with game state reference
**Parameters**:
- `game_state` (GameState): Reference to current game state (read-only)

**Usage**:
```gdscript
UIManager.initialize(GameManager.game_state)
```

**Events Emitted**: None
**Performance**: < 50ms
**Error Conditions**:
- Errors if called twice without cleanup
- Validates game_state is not null

---

#### Screen Management

```gdscript
func show_main_menu() -> void
```
**Description**: Display main menu screen
**Parameters**: None
**Returns**: None
**Side Effects**: Hides current screen, shows main menu
**Events Emitted**: `screen_changed("main_menu")`
**Performance**: < 16ms (single frame)

---

```gdscript
func show_game_screen() -> void
```
**Description**: Display main game screen with HUD
**Parameters**: None
**Returns**: None
**Side Effects**: Hides current screen, shows game screen, initializes HUD
**Events Emitted**: `screen_changed("game")`
**Performance**: < 50ms (initial load), < 16ms (subsequent)

---

```gdscript
func show_settings(return_to_screen: String = "main_menu") -> void
```
**Description**: Display settings screen
**Parameters**:
- `return_to_screen` (String): Screen to return to on close (default: "main_menu")

**Returns**: None
**Events Emitted**: `screen_changed("settings")`
**Performance**: < 16ms

---

```gdscript
func transition_to_screen(screen_name: String, transition_type: String = "fade") -> void
```
**Description**: Transition to a screen with animation
**Parameters**:
- `screen_name` (String): Name of screen ("main_menu", "game", "settings")
- `transition_type` (String): Transition animation ("fade", "slide", "instant")

**Returns**: None
**Events Emitted**: `screen_changed(screen_name)`
**Performance**: < 500ms (with animation), < 16ms (instant)

---

#### Game Initialization

```gdscript
func start_new_game(settings: Dictionary) -> void
```
**Description**: Initialize UI for new game session
**Parameters**:
- `settings` (Dictionary): Game settings from new game dialog
  ```gdscript
  {
    "difficulty": String,      # "easy", "normal", "hard"
    "map_size": String,        # "small", "normal", "large"
    "ai_opponents": int,       # 1-8
    "starting_faction": String # Faction ID
  }
  ```

**Returns**: None
**Side Effects**:
- Transitions to game screen
- Initializes HUD with starting resources
- Resets notification queue

**Events Emitted**: `game_started(settings)`
**Performance**: < 100ms
**Error Conditions**: Validates all required settings keys present

---

```gdscript
func load_game(save_name: String) -> bool
```
**Description**: Initialize UI for loaded game
**Parameters**:
- `save_name` (String): Name of save file to load

**Returns**:
- `bool`: True if successful, false if load failed

**Side Effects**:
- Transitions to game screen
- Updates HUD with loaded state
- Displays notification of successful load

**Events Emitted**: `game_loaded(save_name)`
**Performance**: < 200ms
**Error Conditions**:
- Returns false if save file doesn't exist
- Returns false if save file is corrupted
- Displays error dialog on failure

---

#### HUD Updates

```gdscript
func update_hud(game_state: GameState) -> void
```
**Description**: Update all HUD elements with current game state
**Parameters**:
- `game_state` (GameState): Current game state (read-only)

**Returns**: None
**Side Effects**: Updates resource bar, turn indicator, minimap
**Events Emitted**: None
**Performance**: < 5ms (critical path, called every frame)
**Notes**: Should be called sparingly; prefer event-driven updates

---

```gdscript
func update_resources(faction_id: int, resources: Dictionary) -> void
```
**Description**: Update resource display for specific faction
**Parameters**:
- `faction_id` (int): Faction ID (0 = player)
- `resources` (Dictionary): Resource stockpiles
  ```gdscript
  {
    "scrap": int,
    "food": int,
    "medicine": int,
    "ammunition": int,
    "fuel": int,
    "components": int,
    "water": int
  }
  ```

**Returns**: None
**Side Effects**: Updates resource bar display
**Events Emitted**: None
**Performance**: < 2ms
**Notes**: Typically called via EventBus signal, not directly

---

```gdscript
func update_turn_indicator(turn_number: int, phase: String, active_faction: int) -> void
```
**Description**: Update turn counter and phase indicator
**Parameters**:
- `turn_number` (int): Current turn number
- `phase` (String): Current phase ("movement", "combat", "economy", "end")
- `active_faction` (int): Currently active faction ID

**Returns**: None
**Side Effects**: Updates turn display, highlights active phase
**Events Emitted**: None
**Performance**: < 1ms

---

#### Dialogs

```gdscript
func show_event_dialog(event: EventInstance) -> void
```
**Description**: Display event dialog with choices
**Parameters**:
- `event` (EventInstance): Event data structure
  ```gdscript
  {
    "id": String,
    "title": String,
    "description": String,
    "image": String,           # Optional image path
    "choices": Array[Dictionary] # Array of choice options
  }
  ```

**Returns**: None
**Side Effects**: Pauses game, shows dialog, waits for player choice
**Events Emitted**: `event_dialog_opened(event.id)`
**Performance**: < 16ms
**User Interaction**: Blocks until player selects choice

---

```gdscript
func show_combat_result(result: CombatResult) -> void
```
**Description**: Display combat result summary
**Parameters**:
- `result` (CombatResult): Combat result data
  ```gdscript
  {
    "outcome": String,         # "attacker_victory", "defender_victory", "draw"
    "attacker_casualties": int,
    "defender_casualties": int,
    "loot": Dictionary,        # Resources gained
    "location": Vector3i,      # Combat location
    "experience_gained": int
  }
  ```

**Returns**: None
**Side Effects**: Shows dialog, auto-closes after timeout or player dismisses
**Events Emitted**: `combat_dialog_shown(result.location)`
**Performance**: < 16ms

---

```gdscript
func show_production_queue(faction_id: int) -> void
```
**Description**: Display production queue dialog
**Parameters**:
- `faction_id` (int): Faction ID to show queue for (0 = player)

**Returns**: None
**Side Effects**: Shows dialog with production items, allows reordering
**Events Emitted**: `production_dialog_opened(faction_id)`
**Performance**: < 16ms
**User Interaction**: Blocks until player closes dialog

---

#### Notifications

```gdscript
func show_notification(message: String, type: String = "info", duration: float = 3.0) -> void
```
**Description**: Display temporary notification message
**Parameters**:
- `message` (String): Notification text
- `type` (String): Notification type ("info", "warning", "error", "success")
- `duration` (float): Display duration in seconds (0 = permanent until dismissed)

**Returns**: None
**Side Effects**: Adds notification to queue, displays in HUD
**Events Emitted**: `notification_shown(message, type)`
**Performance**: < 1ms
**Notes**: Queue system prevents notification spam

---

```gdscript
func show_tooltip(text: String, position: Vector2) -> void
```
**Description**: Display tooltip at mouse position
**Parameters**:
- `text` (String): Tooltip text
- `position` (Vector2): Screen position to display tooltip

**Returns**: None
**Side Effects**: Shows tooltip, auto-hides on mouse move
**Events Emitted**: None
**Performance**: < 1ms

---

```gdscript
func hide_tooltip() -> void
```
**Description**: Hide currently displayed tooltip
**Parameters**: None
**Returns**: None
**Performance**: < 1ms

---

#### Cleanup

```gdscript
func cleanup() -> void
```
**Description**: Clean up UI system, disconnect signals
**Parameters**: None
**Returns**: None
**Side Effects**: Disconnects all EventBus signals, clears references
**Performance**: < 10ms

---

### InputHandler

Handles all player input and translates to game commands.

```gdscript
class_name InputHandler
extends Node
```

#### Input Processing

```gdscript
func process_input(event: InputEvent) -> void
```
**Description**: Process input event and dispatch actions
**Parameters**:
- `event` (InputEvent): Godot input event

**Returns**: None
**Side Effects**: May emit action signals to game systems
**Events Emitted**: Various action signals (see Input Actions section)
**Performance**: < 1ms per event

---

```gdscript
func is_action_enabled(action: String) -> bool
```
**Description**: Check if input action is currently enabled
**Parameters**:
- `action` (String): Input action name

**Returns**:
- `bool`: True if action is enabled

**Notes**: Some actions disabled during dialogs or animations

---

```gdscript
func set_input_mode(mode: String) -> void
```
**Description**: Set input mode (affects which actions are active)
**Parameters**:
- `mode` (String): Input mode ("menu", "game", "dialog", "disabled")

**Returns**: None
**Side Effects**: Enables/disables specific input actions

---

## Input Actions

Input actions defined in Godot's Input Map (`project.godot`):

### Camera Controls

| Action | Key Binding | Mouse | Description |
|--------|-------------|-------|-------------|
| `camera_pan_up` | W, Up Arrow | - | Pan camera north |
| `camera_pan_down` | S, Down Arrow | - | Pan camera south |
| `camera_pan_left` | A, Left Arrow | - | Pan camera west |
| `camera_pan_right` | D, Right Arrow | - | Pan camera east |
| `camera_zoom_in` | +, Numpad + | Wheel Up | Zoom camera in |
| `camera_zoom_out` | -, Numpad - | Wheel Down | Zoom camera out |
| `camera_pan` | - | Middle Mouse Drag | Pan camera with mouse |

### Selection & Commands

| Action | Key Binding | Mouse | Description |
|--------|-------------|-------|-------------|
| `select_tile` | - | Left Click | Select tile or unit |
| `multi_select` | Shift | Shift + Left Click | Add to selection |
| `deselect` | Esc | Right Click | Clear selection |
| `confirm_action` | Enter, Space | - | Confirm current action |
| `cancel_action` | Esc | Right Click | Cancel current action |

### Game Controls

| Action | Key Binding | Mouse | Description |
|--------|-------------|-------|-------------|
| `end_turn` | Space, Enter | End Turn Button | End current turn |
| `open_menu` | Esc | - | Open pause menu |
| `quick_save` | F5 | - | Quick save game |
| `quick_load` | F9 | - | Quick load game |

### UI Navigation

| Action | Key Binding | Mouse | Description |
|--------|-------------|-------|-------------|
| `ui_up` | Up Arrow, W | - | Navigate up in menus |
| `ui_down` | Down Arrow, S | - | Navigate down in menus |
| `ui_left` | Left Arrow, A | - | Navigate left in menus |
| `ui_right` | Right Arrow, D | - | Navigate right in menus |
| `ui_accept` | Enter, Space | Left Click | Accept/select |
| `ui_cancel` | Esc, Backspace | Right Click | Cancel/back |

### Hotkeys

| Action | Key Binding | Description |
|--------|-------------|-------------|
| `toggle_production` | P | Open production queue |
| `toggle_culture` | C | Open culture tree |
| `toggle_diplomacy` | B | Open diplomacy screen |
| `toggle_minimap` | M | Toggle minimap |
| `next_unit` | Tab | Cycle to next unit |
| `prev_unit` | Shift + Tab | Cycle to previous unit |

---

## EventBus Signals

The UI System listens to these signals from EventBus:

### Game State Signals

```gdscript
signal game_started(settings: Dictionary)
signal game_loaded(save_name: String)
signal game_saved(save_name: String)
signal game_over(winner: int, victory_type: String)
```

**Handler**: `UIManager._on_game_state_changed()`
**Response**: Update screen state, show notifications

---

### Turn Signals

```gdscript
signal turn_started(turn_number: int, phase: String)
signal turn_ended(turn_number: int)
signal phase_changed(old_phase: String, new_phase: String)
signal faction_turn_started(faction_id: int)
```

**Handler**: `TurnIndicator._on_turn_updated()`
**Response**: Update turn counter, phase indicator

---

### Resource Signals

```gdscript
signal resource_changed(faction_id: int, resource_type: String, amount: int, delta: int)
signal resource_shortage(faction_id: int, resource_type: String, deficit: int)
signal resources_updated(faction_id: int, resources: Dictionary)
```

**Handler**: `ResourceBar._on_resource_changed()`
**Response**: Update resource display, show warnings for shortages

---

### Event Signals

```gdscript
signal event_triggered(event: EventInstance)
signal event_choice_made(event_id: String, choice_id: int)
signal event_completed(event_id: String, outcome: Dictionary)
```

**Handler**: `EventDialog._on_event_triggered()`
**Response**: Show event dialog, present choices

---

### Combat Signals

```gdscript
signal combat_started(attacker: Array, defender: Array, location: Vector3i)
signal combat_resolved(result: CombatResult)
signal unit_damaged(unit_id: String, damage: int, current_hp: int)
signal unit_destroyed(unit_id: String, location: Vector3i)
```

**Handler**: `CombatDialog._on_combat_resolved()`
**Response**: Show combat result dialog

---

### Production Signals

```gdscript
signal production_started(faction_id: int, item: Dictionary)
signal production_completed(faction_id: int, item: Dictionary)
signal production_queue_changed(faction_id: int, queue: Array)
```

**Handler**: `ProductionDialog._on_production_updated()`
**Response**: Update production queue display

---

### Map Signals

```gdscript
signal tile_captured(position: Vector3i, old_owner: int, new_owner: int)
signal tile_scavenged(position: Vector3i, resources: Dictionary)
signal fog_of_war_updated(faction_id: int, revealed_tiles: Array)
```

**Handler**: `Minimap._on_map_changed()`
**Response**: Update minimap display

---

### Culture Signals

```gdscript
signal culture_node_unlocked(faction_id: int, node_id: String)
signal culture_points_changed(faction_id: int, points: int, delta: int)
```

**Handler**: `UIManager._on_culture_changed()`
**Response**: Show notification, update culture UI if open

---

### UI-Emitted Signals

The UI System emits these signals to game systems:

```gdscript
signal action_requested(action_type: String, params: Dictionary)
signal tile_selected(position: Vector3i)
signal unit_move_requested(unit_id: String, destination: Vector3i)
signal unit_attack_requested(attacker_id: String, target_id: String)
signal end_turn_requested()
signal event_choice_selected(event_id: String, choice_id: int)
```

---

## Data Structures

### EventInstance

```gdscript
class EventInstance:
    var id: String
    var type: String               # "random", "cultural", "diplomatic", "discovery", "crisis"
    var title: String
    var description: String
    var image_path: String         # Optional
    var choices: Array[EventChoice]
    var triggered_turn: int
    var faction_id: int           # Affected faction
```

### EventChoice

```gdscript
class EventChoice:
    var choice_id: int
    var text: String
    var requirements: Dictionary   # Conditions to show this choice
    var disabled: bool             # If requirements not met
    var disabled_reason: String    # Why choice is disabled
```

### CombatResult

```gdscript
class CombatResult:
    var outcome: String            # "attacker_victory", "defender_victory", "draw"
    var location: Vector3i
    var attacker_casualties: int
    var defender_casualties: int
    var attacker_units_remaining: int
    var defender_units_remaining: int
    var loot: Dictionary           # Resources gained
    var experience_gained: int
    var morale_change: int
```

### NotificationData

```gdscript
class NotificationData:
    var message: String
    var type: String               # "info", "warning", "error", "success"
    var duration: float            # Display duration in seconds
    var timestamp: float           # When notification was created
    var icon: String               # Icon texture path
    var dismissible: bool          # Can player manually dismiss
```

---

## Performance Requirements

### Update Frequencies

| Component | Update Frequency | Max Time |
|-----------|------------------|----------|
| HUD Elements | Every frame | 2ms |
| Resource Bar | On signal only | 1ms |
| Turn Indicator | On turn change | 1ms |
| Minimap | On map change | 5ms |
| Dialogs | On demand | 16ms |
| Tooltips | On hover | 1ms |
| Notifications | On event | 1ms |

### Memory Constraints

- **Total UI Memory**: < 100MB
- **Texture Atlas**: < 50MB
- **Font Cache**: < 10MB
- **UI Node Tree**: < 500 nodes active simultaneously

### Responsiveness

- **Input Lag**: < 16ms (one frame)
- **Dialog Open**: < 50ms
- **Screen Transition**: < 500ms (with animation)
- **Notification Display**: < 5ms

---

## Testing Requirements

### Unit Tests (Target: 70% Coverage)

```gdscript
# tests/ui/test_ui_manager.gd
func test_show_main_menu()
func test_show_game_screen()
func test_transition_between_screens()
func test_start_new_game()
func test_load_game_success()
func test_load_game_failure()
```

```gdscript
# tests/ui/test_resource_bar.gd
func test_resource_display_updates()
func test_resource_shortage_warning()
func test_resource_animation()
```

```gdscript
# tests/ui/test_dialogs.gd
func test_event_dialog_display()
func test_event_choice_selection()
func test_combat_result_display()
func test_production_queue_display()
```

```gdscript
# tests/ui/test_input_handler.gd
func test_camera_pan_input()
func test_tile_selection()
func test_end_turn_input()
func test_keyboard_navigation()
func test_input_mode_switching()
```

### Integration Tests

```gdscript
# tests/integration/test_ui_game_integration.gd
func test_ui_updates_on_resource_change()
func test_ui_updates_on_turn_change()
func test_event_dialog_workflow()
func test_full_turn_with_ui()
```

### UI Tests (Automated)

```gdscript
# tests/ui/test_ui_automation.gd
func test_click_new_game_button()
func test_navigate_menus_with_keyboard()
func test_dialog_accept_cancel()
func test_tooltip_show_hide()
```

### Manual Testing Checklist

- [ ] All screens navigate correctly
- [ ] HUD updates in real-time
- [ ] Dialogs display and accept input
- [ ] Input feels responsive
- [ ] Keyboard navigation works
- [ ] Tooltips appear correctly
- [ ] Notifications don't spam
- [ ] No UI crashes or freezes
- [ ] Text is readable at all resolutions
- [ ] UI scales correctly (1080p, 1440p, 4K)

---

## Integration Points

### With Core Foundation

```gdscript
# Access game state (read-only)
var game_state = GameManager.game_state

# Listen to EventBus
EventBus.resource_changed.connect(_on_resource_changed)
EventBus.turn_started.connect(_on_turn_started)

# Request actions via EventBus
EventBus.action_requested.emit("end_turn", {})
```

### With Map System

```gdscript
# Get tile information for tooltips
var tile = MapData.get_tile(position)
UIManager.show_tooltip(tile.get_description(), mouse_pos)

# Update minimap
Minimap.render_tiles(MapData.get_visible_tiles(player_faction))
```

### With Unit System

```gdscript
# Display unit information
var unit = UnitManager.get_unit(unit_id)
show_unit_panel(unit)

# Request unit movement
EventBus.unit_move_requested.emit(unit_id, destination)
```

### With Combat System

```gdscript
# Display combat result
EventBus.combat_resolved.connect(_on_combat_resolved)

func _on_combat_resolved(result: CombatResult):
    show_combat_result(result)
```

### With Economy System

```gdscript
# Display resources
EventBus.resources_updated.connect(_on_resources_updated)

func _on_resources_updated(faction_id: int, resources: Dictionary):
    if faction_id == player_faction_id:
        update_resources(faction_id, resources)
```

### With Culture System

```gdscript
# Display culture progression
EventBus.culture_node_unlocked.connect(_on_culture_unlocked)

func _on_culture_unlocked(faction_id: int, node_id: String):
    if faction_id == player_faction_id:
        show_notification("Culture node unlocked: " + node_id, "success")
```

### With Event System

```gdscript
# Display events
EventBus.event_triggered.connect(_on_event_triggered)

func _on_event_triggered(event: EventInstance):
    show_event_dialog(event)

# Send player choice back
func _on_choice_selected(choice_id: int):
    EventBus.event_choice_selected.emit(current_event.id, choice_id)
```

---

## Error Handling

### Error Conditions

| Error | Cause | Handling |
|-------|-------|----------|
| Invalid screen name | `transition_to_screen()` with unknown screen | Log error, stay on current screen |
| Null game state | `initialize()` without valid game state | Assert and fail, show error dialog |
| Missing resource | Load texture/font fails | Use fallback resource, log warning |
| Dialog timeout | Dialog open but no response | Auto-close after 30s, log warning |
| Input spam | Too many inputs in short time | Throttle inputs, ignore extras |
| Signal not connected | EventBus signal handler missing | Log warning, continue without update |

### Error Recovery

```gdscript
func safe_show_dialog(dialog_scene: PackedScene) -> void:
    if dialog_scene == null:
        push_error("Dialog scene is null")
        show_notification("Failed to open dialog", "error")
        return

    var instance = dialog_scene.instantiate()
    if instance == null:
        push_error("Failed to instantiate dialog")
        show_notification("Failed to open dialog", "error")
        return

    add_child(instance)
```

---

## Localization Support

### Text Externalization

All UI strings must use localization keys:

```gdscript
# Good
button.text = tr("UI_MAIN_MENU_NEW_GAME")

# Bad
button.text = "New Game"
```

### Localization Keys Structure

```
UI_MAIN_MENU_*          # Main menu strings
UI_HUD_*                # HUD strings
UI_DIALOG_*             # Dialog strings
UI_NOTIFICATION_*       # Notification strings
UI_TOOLTIP_*            # Tooltip strings
```

### Example Localization File

```csv
keys,en,es,fr
UI_MAIN_MENU_NEW_GAME,New Game,Nueva Partida,Nouvelle Partie
UI_MAIN_MENU_LOAD_GAME,Load Game,Cargar Partida,Charger Partie
UI_HUD_TURN,Turn,Turno,Tour
UI_NOTIFICATION_TURN_ENDED,Turn ended,Turno terminado,Tour terminé
```

---

## Accessibility Features

### Keyboard Navigation

- All UI elements accessible via Tab key
- Focus indicators clearly visible
- Logical tab order (top-to-bottom, left-to-right)
- Keyboard shortcuts for all common actions

### Visual Accessibility

- High contrast mode support
- Colorblind-friendly color schemes
- Adjustable text size
- Clear visual feedback for interactions

### Audio Cues (Future)

- Sound effects for important actions
- Audio feedback for notifications
- Screen reader support (stretch goal)

---

## Dependencies Summary

### Required Modules

| Module | Purpose | Access Type |
|--------|---------|-------------|
| Core Foundation | Game state, EventBus | Read-only |
| Map System | Tile data, fog of war | Read-only |
| Unit System | Unit data | Read-only |
| Combat System | Combat results | Read-only |
| Economy System | Resource data | Read-only |
| Culture System | Culture tree | Read-only |
| Event System | Event data | Read-only |

### Optional Modules

| Module | Purpose | Fallback |
|--------|---------|----------|
| Rendering System | Minimap rendering | Static minimap |
| Audio System | UI sound effects | Silent mode |

---

## Implementation Notes

### Scene Organization

Each UI component should be a self-contained scene with its own controller script:

```
resource_bar.tscn
├── ResourceBar (Control)
    ├── ResourceBarController (Script)
    ├── ScrapLabel (Label)
    ├── FoodLabel (Label)
    └── ...
```

### Signal Flow

```
EventBus Signal → UI Component → Update Display
User Input → InputHandler → EventBus Signal → Game System
```

### Theme Consistency

All UI elements must use the game theme (`theme/game_theme.tres`):
- Consistent colors
- Consistent fonts
- Consistent button styles
- Consistent spacing

### Performance Optimization

- Use texture atlases for UI elements
- Minimize node count (use Labels, not RichTextLabel unless needed)
- Cache tooltip text generation
- Throttle minimap updates (max 10 FPS)
- Use `set_process(false)` for hidden UI elements

---

## Future Enhancements (Post-MVP)

1. **Advanced Minimap**: Fog of war, unit icons, faction colors
2. **Detailed Unit Panels**: Equipment, abilities, experience
3. **Culture Tree Visualizer**: Interactive graph of culture nodes
4. **Diplomacy Screen**: Full diplomatic interface
5. **Statistics Screen**: Charts, graphs, historical data
6. **Replay System**: View combat replays
7. **Mod Support**: Custom UI themes and layouts
8. **Multiplayer UI**: Hot-seat mode support

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-12 | Initial interface contract |

---

## Approval

**Status**: Awaiting Review
**Reviewers**: Integration Coordinator, Agent 1 (Core), Agent 10 (Rendering)

---

## Questions for Review

1. Are all required UI elements covered?
2. Is the signal-based update approach appropriate?
3. Should dialogs block game processing or run async?
4. What's the preferred approach for minimap rendering (UI-side or Rendering module)?
5. Should we support gamepad input in MVP?

---

**End of Interface Contract**
