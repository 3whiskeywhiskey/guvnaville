# Godot 4.5.1 Compatibility Report
## Type Hint Preload Requirements

**Generated:** 2025-11-13
**Godot Version:** 4.5.1
**Issue:** Custom class_name types used in type hints require preload statements

---

## Summary

This report identifies all .gd files in the Guvnaville codebase that use custom class_name types in type hints WITHOUT properly preloading them first. Godot 4.5.1 requires that custom classes be preloaded before being used in type hints.

**Total Files Requiring Fixes:** 13 files
**Total Custom Classes Missing Preloads:** 20+ instances

---

## Files Requiring Fixes

### 1. /home/user/guvnaville/systems/ai/faction_ai.gd

**Missing Preloads:**
- `GoalPlanner` - Used at line 29
- `UtilityScorer` - Used at line 32
- `TacticalAI` - Used at line 35
- `AIAction` - Used at lines 71, 103, 122, 305, 307, etc.
- `AIThreatAssessment` - Used at line 323
- `AggressivePersonality` - Referenced at line 284
- `DefensivePersonality` - Referenced at line 286
- `EconomicPersonality` - Referenced at line 288

**Fix Required:**
Add these preload statements at the top of the file (after class_name):
```gdscript
const GoalPlanner = preload("res://systems/ai/goal_planner.gd")
const UtilityScorer = preload("res://systems/ai/utility_scorer.gd")
const TacticalAI = preload("res://systems/ai/tactical_ai.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")
const AIThreatAssessment = preload("res://systems/ai/ai_threat_assessment.gd")
const AggressivePersonality = preload("res://systems/ai/personalities/aggressive.gd")
const DefensivePersonality = preload("res://systems/ai/personalities/defensive.gd")
const EconomicPersonality = preload("res://systems/ai/personalities/economic.gd")
```

---

### 2. /home/user/guvnaville/systems/ai/goal_planner.gd

**Missing Preloads:**
- `AIGoal` - Used at lines 73, 89, 100, 116, etc.

**Fix Required:**
```gdscript
const AIGoal = preload("res://systems/ai/ai_goal.gd")
```

---

### 3. /home/user/guvnaville/systems/ai/utility_scorer.gd

**Missing Preloads:**
- `AIGoal` - Used at line 216
- `AIThreatAssessment` - Used at line 250

**Fix Required:**
```gdscript
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIThreatAssessment = preload("res://systems/ai/ai_threat_assessment.gd")
```

---

### 4. /home/user/guvnaville/systems/ai/tactical_ai.gd

**Missing Preloads:**
- `UtilityScorer` - Used at line 13

**Fix Required:**
```gdscript
const UtilityScorer = preload("res://systems/ai/utility_scorer.gd")
```

---

### 5. /home/user/guvnaville/systems/ai/personalities/aggressive.gd

**Missing Preloads:**
- `AIGoal` - Used at lines 35-42
- `AIAction` - Used at lines 88-102

**Fix Required:**
```gdscript
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")
```

---

### 6. /home/user/guvnaville/systems/ai/personalities/defensive.gd

**Missing Preloads:**
- `AIGoal` - Used at lines 35-42
- `AIAction` - Used at lines 88-102

**Fix Required:**
```gdscript
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")
```

---

### 7. /home/user/guvnaville/systems/ai/personalities/economic.gd

**Missing Preloads:**
- `AIGoal` - Used at lines 35-42
- `AIAction` - Used at lines 84-106

**Fix Required:**
```gdscript
const AIGoal = preload("res://systems/ai/ai_goal.gd")
const AIAction = preload("res://systems/ai/ai_action.gd")
```

---

### 8. /home/user/guvnaville/systems/combat/combat_resolver.gd

**Missing Preloads:**
- `CombatResult` - Used at line 32
- `CombatCalculator` - Used at lines 43-44
- `MoraleSystem` - Used at line 178
- `LootCalculator` - Used at line 228

**Fix Required:**
```gdscript
const CombatResult = preload("res://systems/combat/combat_result.gd")
const CombatCalculator = preload("res://systems/combat/combat_calculator.gd")
const MoraleSystem = preload("res://systems/combat/morale_system.gd")
const LootCalculator = preload("res://systems/combat/loot_calculator.gd")
```

---

### 9. /home/user/guvnaville/systems/combat/combat_calculator.gd

**Missing Preloads:**
- `CombatModifiers` - Used at line 38
- `CombatResult` - Used at lines 182-193

**Fix Required:**
```gdscript
const CombatModifiers = preload("res://systems/combat/combat_modifiers.gd")
const CombatResult = preload("res://systems/combat/combat_result.gd")
```

---

### 10. /home/user/guvnaville/systems/combat/morale_system.gd

**Missing Preloads:**
- `MoraleCheckResult` - Used at line 53
- `CombatModifiersCalculator` - Used at line 61

**Fix Required:**
```gdscript
const MoraleCheckResult = preload("res://systems/combat/morale_check_result.gd")
const CombatModifiersCalculator = preload("res://systems/combat/combat_modifiers_calculator.gd")
```

---

### 11. /home/user/guvnaville/systems/combat/loot_calculator.gd

**Missing Preloads:**
- `CombatResult` - Used at line 195

**Fix Required:**
```gdscript
const CombatResult = preload("res://systems/combat/combat_result.gd")
```

---

### 12. /home/user/guvnaville/systems/combat/tactical_combat.gd

**Missing Preloads:**
- `CombatResolver` - Used at line 105
- `CombatResult` - Used at lines 113, 236

**Fix Required:**
```gdscript
const CombatResolver = preload("res://systems/combat/combat_resolver.gd")
const CombatResult = preload("res://systems/combat/combat_result.gd")
```

---

### 13. /home/user/guvnaville/systems/combat/combat_modifiers_calculator.gd

**Missing Preloads:**
- `CombatModifiers` - Used at line 40

**Fix Required:**
```gdscript
const CombatModifiers = preload("res://systems/combat/combat_modifiers.gd")
```

---

### 14. /home/user/guvnaville/systems/map/map_data.gd

**Missing Preloads:**
- `MapTile` - Used at lines 30, 123, 155, 201, 235, etc.

**Fix Required:**
```gdscript
const MapTile = preload("res://systems/map/tile.gd")
```

**Note:** The file refers to `MapMapTile` on line 30 which appears to be a typo - should be `MapTile`.

---

## Files Already Fixed (Have Proper Preloads)

✅ `/home/user/guvnaville/ui/map/map_view.gd`
✅ `/home/user/guvnaville/ui/screens/game_screen.gd`
✅ `/home/user/guvnaville/core/integration_coordinator.gd`
✅ `/home/user/guvnaville/ui/map/tile_renderer.gd`
✅ `/home/user/guvnaville/ui/map/unit_renderer.gd`

---

## Base Class Definitions (No Fixes Needed)

These files define class_name but don't use other custom classes:
- `/home/user/guvnaville/systems/ai/ai_action.gd`
- `/home/user/guvnaville/systems/ai/ai_goal.gd`
- `/home/user/guvnaville/systems/ai/ai_threat_assessment.gd`
- `/home/user/guvnaville/systems/combat/combat_result.gd`
- `/home/user/guvnaville/systems/combat/combat_modifiers.gd`
- `/home/user/guvnaville/systems/combat/morale_check_result.gd`
- `/home/user/guvnaville/ui/map/camera_controller.gd`

---

## Preload Pattern

The correct pattern for Godot 4.5.1 compatibility is:

```gdscript
## FileName - Description
class_name ClassName
extends BaseClass

# Preload dependencies for Godot 4.5.1 compatibility
const CustomClass1 = preload("res://path/to/custom_class1.gd")
const CustomClass2 = preload("res://path/to/custom_class2.gd")

# Now you can use CustomClass1 and CustomClass2 in type hints
var my_var: CustomClass1
func my_func(param: CustomClass2) -> CustomClass1:
    pass
```

---

## Recommended Fix Order

1. **Fix base dependencies first** (no circular dependencies):
   - systems/combat/combat_modifiers_calculator.gd
   - systems/combat/loot_calculator.gd
   - systems/ai/tactical_ai.gd
   - systems/ai/goal_planner.gd
   - systems/ai/utility_scorer.gd
   - systems/ai/personalities/*.gd

2. **Fix intermediate files**:
   - systems/combat/morale_system.gd
   - systems/combat/combat_calculator.gd
   - systems/combat/tactical_combat.gd

3. **Fix top-level files**:
   - systems/combat/combat_resolver.gd
   - systems/ai/faction_ai.gd
   - systems/map/map_data.gd

---

## Testing After Fixes

After applying these fixes:

1. Run the project in Godot 4.5.1
2. Check for any type hint errors in the output
3. Run the test suite to ensure functionality is preserved
4. Verify CI pipeline passes

---

## Notes

- All preload paths should use `res://` prefix
- Preload statements should be placed after `class_name` and `extends`
- Group preloads together and comment them for clarity
- Test files in `/tests/` directory were excluded from this scan
- Addon files in `/addons/` directory were excluded from this scan

---

**End of Report**
