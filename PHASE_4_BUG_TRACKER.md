# Phase 4 Bug Tracker

**Last Updated:** 2025-11-13
**Status:** In Progress

## Summary
- **Total Bugs Found:** 5
- **Critical (P0):** 1
- **High (P1):** 2
- **Medium (P2):** 2
- **Low (P3):** 0
- **Bugs Fixed:** 4
- **Bugs Remaining:** 1 (P2 - acceptable as-is)

---

## Critical Bugs (P0 - Must fix for MVP)

### Game-Breaking / Crashes

- [x] **BUG-001: DataLoader file paths are incorrect - Game cannot load any data**
  - **Priority:** P0
  - **Location:** /home/user/guvnaville/core/autoload/data_loader.gd (lines 40-47)
  - **Steps to Reproduce:**
    1. Start a new game
    2. DataLoader attempts to load game data
    3. All file loads fail with "File not found" warnings
  - **Expected Behavior:** DataLoader should successfully load units, buildings, events, culture tree, and locations from JSON files
  - **Actual Behavior:** DataLoader looks for files at wrong paths:
    - Expects: "res://data/units.json" -> Actual: "res://data/units/units.json"
    - Expects: "res://data/buildings.json" -> Actual: "res://data/buildings/buildings.json"
    - Expects: "res://data/culture_tree.json" -> Actual: "res://data/culture/culture_tree.json"
    - Expects: "res://data/events.json" -> Actual: "res://data/events/events.json"
    - Expects: "res://data/unique_locations.json" -> Actual: "res://data/world/locations.json"
    - Expects: "res://data/tiles.json" -> File does not exist (fallback to defaults works)
    - Expects: "res://data/resources.json" -> File does not exist
  - **Root Cause:** File path constants don't match actual directory structure. Project has subdirectories (units/, buildings/, etc.) but DataLoader expects flat structure.
  - **Fix:** Updated file path constants in data_loader.gd lines 41-45 to match actual directory structure
  - **Test:** All data files should now load successfully on game start
  - **Status:** FIXED

### Data Corruption / Save Issues
<!-- No bugs found in this category -->

---

## High Priority Bugs (P1 - Should fix for MVP)

### Core Gameplay Issues

- [x] **BUG-002: GameManager doesn't reset current_state on game end**
  - **Priority:** P1
  - **Location:** /home/user/guvnaville/core/autoload/game_manager.gd (line 141-150)
  - **Steps to Reproduce:**
    1. Start a game (current_state is set)
    2. End the game via GameManager.end_game()
    3. Check is_game_active (false) and current_state (still set, not null)
  - **Expected Behavior:** Both is_game_active should be false AND current_state should be null after game ends
  - **Actual Behavior:** is_game_active is set to false, but current_state is not nulled
  - **Root Cause:** Missing line: `current_state = null` in end_game() method
  - **Fix:** Added `current_state = null` at line 150 in game_manager.gd
  - **Test:** Verify current_state is null after end_game() is called
  - **Status:** FIXED

- [x] **BUG-003: Missing resources.json file - ResourceManager cannot validate resource types**
  - **Priority:** P1
  - **Location:** Data loading system
  - **Steps to Reproduce:**
    1. DataLoader attempts to load resources.json
    2. File does not exist
    3. ResourceManager has hardcoded RESOURCE_TYPES array
  - **Expected Behavior:** Resource definitions should be loaded from JSON and used by ResourceManager
  - **Actual Behavior:** resources.json file does not exist; resource types are hardcoded in ResourceManager
  - **Root Cause:** Missing data file (design inconsistency)
  - **Fix:** Made resources.json optional in _load_resources() method (line 228), similar to tiles.json. System falls back to hardcoded types in ResourceManager.
  - **Test:** Verify resource system works correctly with hardcoded types
  - **Status:** FIXED

### UI Blockers
<!-- No bugs found in this category -->

### AI Instability
<!-- No bugs found in this category -->

---

## Medium Priority Bugs (P2 - Nice to fix)

### Visual/Polish Issues
<!-- No bugs found in this category -->

### Balance Issues

- [x] **BUG-004: CombatCalculator casualty percentage logic potentially reversed for DEFENDER_DECISIVE_VICTORY**
  - **Priority:** P2
  - **Location:** /home/user/guvnaville/systems/combat/combat_calculator.gd (line 191)
  - **Steps to Reproduce:**
    1. Run combat where defender wins decisively
    2. Check casualty percentages for winner vs loser
    3. Logic may be backwards (winner gets high casualties, loser gets low)
  - **Expected Behavior:** Winner (defender) should get low casualties (10%), loser (attacker) should get high casualties (60-80%)
  - **Actual Behavior:** Code returns high casualties if is_winner==true, low if is_winner==false (reversed)
  - **Root Cause:** Line 191: `return randf_range(CASUALTY_DECISIVE_LOSER_MIN, CASUALTY_DECISIVE_LOSER_MAX) if is_winner else CASUALTY_DECISIVE_WINNER`
  - **Fix:** Reversed the logic at line 192 in combat_calculator.gd: `return CASUALTY_DECISIVE_WINNER if is_winner else randf_range(CASUALTY_DECISIVE_LOSER_MIN, CASUALTY_DECISIVE_LOSER_MAX)`
  - **Test:** Unit test should verify correct casualty percentages for all combat outcomes
  - **Status:** FIXED

### Minor Gameplay Issues

- [ ] **BUG-005: Missing tiles.json file - Using fallback default tiles**
  - **Priority:** P2
  - **Location:** Data loading system
  - **Steps to Reproduce:**
    1. DataLoader attempts to load tiles.json
    2. File does not exist
    3. Fallback to _create_default_tiles() is used
  - **Expected Behavior:** Tile definitions should be loaded from JSON
  - **Actual Behavior:** tiles.json file does not exist; using hardcoded defaults
  - **Root Cause:** Missing data file (acceptable for MVP as fallback works)
  - **Fix:** Create tiles.json file with proper tile definitions OR keep fallback as intended behavior
  - **Test:** Verify tile system works correctly with defaults
  - **Status:** Open (acceptable as-is, fallback works)

---

## Low Priority Bugs (P3 - Post-MVP)

### Edge Cases
<!-- No bugs found in this category -->

### Quality of Life
<!-- No bugs found in this category -->

---

## Testing Checklist

### Core Systems
- [ ] GameManager (start, save, load, quit)
- [ ] TurnManager (turn processing, phase transitions)
- [ ] DataLoader (all JSON files load)
- [ ] SaveManager (save/load, corruption handling)
- [ ] EventBus (signal delivery)

### Game Systems
- [ ] Map System (boundaries, invalid positions)
- [ ] Unit System (movement, abilities, edge cases)
- [ ] Combat System (targets, HP, morale)
- [ ] Economy System (resources, overflow, shortages)
- [ ] Culture System (prerequisites, effects)
- [ ] Event System (triggers, consequences)

### AI Systems
- [ ] AI decision making (no crashes/stalls)
- [ ] AI vs AI games (50+ turns)
- [ ] AI personalities (distinct behaviors)

### UI Systems
- [ ] All buttons/interactions work
- [ ] Edge cases (empty states, max values)
- [ ] Screen transitions
- [ ] Dialogs and popups

---

## Bug Entry Template

```markdown
- [ ] BUG-XXX: [Short Description]
  - **Priority:** P0/P1/P2/P3
  - **Location:** [file:line or system]
  - **Steps to Reproduce:**
    1. Step one
    2. Step two
  - **Expected Behavior:** [What should happen]
  - **Actual Behavior:** [What actually happens]
  - **Root Cause:** [Analysis of why it happens]
  - **Fix:** [Description of fix or commit link]
  - **Test:** [Regression test added]
  - **Status:** Open/In Progress/Fixed/Won't Fix
```
