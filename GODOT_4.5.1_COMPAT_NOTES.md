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

## Recommended Approach

### Option A: Use Godot 4.2.2 (Recommended)
- Download: https://godotengine.org/download/archive/4.2.2-stable/
- Game was designed for this version
- All fixes already made will still work
- No additional refactoring needed

### Option B: Full 4.5.1 Refactor
Required changes (~50-100 files):
1. Remove ALL type hints from variables/functions
2. Replace with dynamic typing or runtime checks
3. Update GUT addon to 4.5.1-compatible version
4. Test entire codebase

Estimated effort: 2-4 hours

### Option C: Hybrid Approach
1. Keep type hints in non-autoload files
2. Only remove hints from autoloads and their direct dependencies
3. Use preload + const pattern everywhere
4. Still requires touching ~20 files

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

## Next Steps After Phase 4 Merge
1. Review Phase 4 changes for new type hint usage
2. Decide: 4.2.2 vs full 4.5.1 refactor
3. If refactoring: Create systematic plan to remove type hints
4. Update project.godot version back to 4.2
5. Test with appropriate Godot version

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
