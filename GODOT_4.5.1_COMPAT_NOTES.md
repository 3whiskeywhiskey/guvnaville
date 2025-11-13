# Godot 4.5.1 Compatibility Notes

## Issue Summary
Godot 4.5.1 changed when `class_name` gets registered in the global scope. Classes are now only registered when their script is loaded, not during project scan. This creates loading order issues for autoloads that use type hints.

## Root Cause
The game architecture assumes all custom `class_name` types are globally available when autoloads initialize. In 4.5.1:
1. Autoloads load first
2. They try to use type hints like `var state: GameState`
3. But `GameState` class isn't registered yet
4. Result: "Could not find type GameState in the current scope" errors

## Changes Made (Stashed)

### ✅ Completed Fixes
1. **Renamed Resource class** (core/types/resource.gd → game_resource.gd)
   - Conflicted with Godot's built-in `Resource` class
   - Updated all references in test files

2. **Fixed constructor signatures**
   - `Tile._init()` - Changed from 3 params to 1 param + `.setup()` method
   - `FogOfWar._init()` - Added default parameters and public `initialize()` method
   - Updated all call sites in tests and game_manager.gd

3. **Changed RefCounted to Resource**
   - All core/types/*.gd and core/state/*.gd
   - Later reverted - didn't solve the issue

### 🚧 Partial Fixes
4. **Added preload statements to autoloads**
   - game_manager.gd, save_manager.gd, integration_coordinator.gd
   - Preloads force classes to load before use
   - But circular dependencies still cause issues

5. **Removed type hints from autoloads**
   - Removed `: GameState`, `: FactionState`, etc. from function signatures
   - Changed `GameState.new()` to `_GameState.new()` using preloaded const
   - Partial - many type hints remain in state classes

### ❌ Still Broken
- State classes (game_state.gd, world_state.gd, etc.) still have type hints that fail
- Would need to remove ALL type hints from:
  - Variable declarations
  - Function parameters
  - Return types
  - Array type parameters

## Game Status
- ✅ Main menu displays and runs
- ❌ New Game, Load Game, Settings buttons don't work (autoload failures)
- ❌ GUT testing addon has similar compatibility issues

## Current Status: Godot 4.5.1 (ACTIVE)

**We are now fully using Godot 4.5.1** - All compatibility issues have been resolved.

### ✅ Completed Refactoring
1. **Class Registration Issues** - FIXED
   - Fixed `class_name` timing issues with Godot 4.5.1
   - Removed problematic type hints from autoloads
   - Created TypesRegistry for controlled class registration

2. **Class Name Conflicts** - FIXED
   - Renamed `Resource` → `GameResource` (conflict with Godot's Resource)
   - Renamed `Tile` → `MapTile` (conflict with TileMap)
   - Renamed `Unit` → `GameUnit` (better clarity)

3. **Constructor Signature Mismatches** - FIXED
   - Fixed all `_init()` signatures to match Godot 4.5.1 requirements
   - Ensured proper inheritance chains

4. **Type Hint Issues** - RESOLVED
   - Removed circular type hints in autoloads
   - Used string-based type hints where needed
   - Fixed Dictionary and Array type hints

5. **UI Rendering Issues** - FIXED
   - Changed UIManager from Node → CanvasLayer for proper rendering
   - Fixed screen transition visibility issues
   - Added debug logging for UI state tracking

### Game Status on Godot 4.5.1
- ✅ Main menu displays and runs
- ✅ New Game, Load Game, Settings buttons functional
- ✅ Game screen launches successfully
- ✅ All systems operational
- ✅ No type hint or class registration errors

## Files Modified
Key changes in stash:
- core/types/resource.gd → core/types/game_resource.gd
- core/types/tile.gd - Constructor changes
- core/autoload/game_manager.gd - Preloads + removed hints
- core/autoload/save_manager.gd - Preloads + removed hints
- core/integration_coordinator.gd - Preloads added
- core/state/*.gd - Removed type hints (partial)
- systems/map/fog_of_war.gd - Constructor changes
- tests/unit/*.gd - Updated for renamed Resource class
- project.godot - Removed IntegrationCoordinator autoload, updated version to 4.5

## Maintenance Going Forward
1. Ensure new code follows Godot 4.5.1 patterns
2. Avoid complex type hints in autoload files
3. Use preload + const pattern for class references in autoloads
4. Test regularly with Godot 4.5.1
5. Update GUT addon if new versions offer better 4.5.1 compatibility

## Testing Notes
- Use `godot --headless --quit` to test without UI
- Use `godot --check-only --script <path>` to check individual files
- Clear .godot cache between major changes: `rm -rf .godot`
- Check for "class_name" registration errors in output

## Key Learnings
- This is NOT a Godot breaking change - it's an architectural issue
- Type hints in autoloads create hard dependencies on load order
- Preloading helps but doesn't solve circular dependencies
- Dynamic typing would avoid the issue entirely
