# Migration to 90s DOS Game Aesthetic
## Architecture Alternatives & Migration Strategy

**Document Version:** 1.0
**Date:** 2025-11-13
**Current Engine:** Godot 4.5.1
**Target Aesthetic:** 90s DOS Game Experience

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [90s DOS Aesthetic Overview](#90s-dos-aesthetic-overview)
3. [Potential Architecture Alternatives](#potential-architecture-alternatives)
4. [Recommended Approaches](#recommended-approaches)
5. [Migration Concerns & Challenges](#migration-concerns--challenges)
6. [Migration Strategies](#migration-strategies)
7. [Effort Estimates](#effort-estimates)
8. [Risk Assessment](#risk-assessment)
9. [Decision Matrix](#decision-matrix)
10. [Next Steps](#next-steps)

---

## Executive Summary

This document explores alternatives to Godot for achieving an authentic 90s DOS game aesthetic for **Guvnaville (Ashes to Empire)**. The current codebase consists of **41,000+ lines of GDScript** across 160 files, implementing a production-ready turn-based 4X strategy game.

**Key Findings:**
- **5 viable architectural approaches** identified, ranging from low-level (custom C/SDL2) to high-level (Pico-8, web-based)
- **Recommended:** Hybrid approach using **Raylib** or **SDL2** for optimal balance of authenticity and development speed
- **Migration complexity:** Moderate to High (3-6 months estimated)
- **Primary challenge:** Rewriting game logic from GDScript to C/C++/Rust while preserving 41,000+ lines of functionality
- **Opportunity:** Authentic DOS aesthetic with modern conveniences (cross-platform, modern tooling)

---

## 90s DOS Aesthetic Overview

### Visual Characteristics

**Resolution Options:**
- **320x200** (Mode 13h) - Classic DOS resolution, 256 colors
- **640x480** (VGA) - Higher resolution DOS mode
- **640x350** (EGA) - Older DOS mode, 16 colors
- **Text Mode** (80x25, 80x50) - ASCII/ANSI art

**Color Palettes:**
- **VGA 256-color palette** (Mode 13h)
- **EGA 16-color palette**
- **CGA 4-color palette** (for extreme retro)
- Custom palettes with palette cycling effects

**Visual Techniques:**
- Pixel art sprites (8x8, 16x16, 32x32)
- Dithering for pseudo-transparency
- Palette animation (water, fire effects)
- ASCII/ANSI art for UI elements
- Fixed-width bitmap fonts (VGA, EGA fonts)
- No anti-aliasing or filtering
- Nearest-neighbor scaling

### Technical Characteristics

**Performance Profile:**
- Software rendering (no GPU acceleration)
- Fixed-point arithmetic (no floating-point on 386)
- Direct frame buffer access
- Simple sprite blitting
- Minimal memory usage (<640KB base, <16MB extended)

**Audio:**
- PC Speaker beeps
- AdLib/SoundBlaster FM synthesis
- MOD/S3M/XM tracker music
- Low sample rate digitized sound effects

**Input:**
- Keyboard-first design
- Mouse support (optional, via DOS mouse driver)
- Joystick support (game port)

### Inspirational DOS Games (Strategy Genre)

1. **Civilization (1991)** - Turn-based strategy, VGA graphics
2. **Master of Orion (1993)** - 4X space strategy
3. **X-COM: UFO Defense (1994)** - Tactical strategy
4. **Dune II (1992)** - Real-time strategy pioneer
5. **Syndicate (1993)** - Isometric tactics
6. **Betrayal at Krondor (1993)** - RPG/Strategy hybrid

---

## Potential Architecture Alternatives

### Option 1: Custom Engine with SDL2 (C/C++)

**Overview:**
Build a custom DOS-style engine using SDL2 for cross-platform compatibility while maintaining authentic DOS rendering techniques.

**Technology Stack:**
- **Language:** C or C++
- **Framework:** SDL2 (Simple DirectMedia Layer)
- **Rendering:** Software rendering to SDL_Surface, then blit to screen
- **Audio:** SDL_mixer (with MOD/S3M support)
- **Build System:** CMake
- **Platform:** Windows, Linux, macOS (via SDL2 abstraction)

**Architecture:**

```
┌─────────────────────────────────────────────┐
│           SDL2 Abstraction Layer            │
│  (Window, Input, Audio, Timer, Threading)   │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│         Custom DOS-Style Renderer            │
│  - 320x200 framebuffer (8-bit indexed)      │
│  - VGA palette management                   │
│  - Sprite blitting engine                   │
│  - Tile rendering system                    │
│  - Nearest-neighbor upscaling               │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│            Game Engine Core                  │
│  - Game state management                    │
│  - Turn manager                             │
│  - Event system (C callbacks/function ptrs) │
│  - Save/load (binary or JSON)               │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│          Game Systems (Ported)               │
│  - Map generation                           │
│  - Combat resolver                          │
│  - Economy system                           │
│  - AI personalities                         │
│  - Event system                             │
│  - Culture tree                             │
└─────────────────────────────────────────────┘
```

**Pros:**
- ✅ Full control over rendering pipeline (authentic DOS look)
- ✅ High performance (C/C++ compiled code)
- ✅ Cross-platform via SDL2
- ✅ Active community and extensive documentation
- ✅ Can use modern tooling (VSCode, GDB, CMake)
- ✅ Easy to implement VGA palette effects

**Cons:**
- ❌ Requires rewriting 41,000+ lines from GDScript to C/C++
- ❌ Manual memory management (error-prone)
- ❌ No built-in scene graph or UI system
- ❌ Longer development time
- ❌ More complex debugging

**Best For:** Teams with C/C++ experience wanting maximum authenticity and performance.

---

### Option 2: Raylib (C/C++/Rust/Go)

**Overview:**
Raylib is a simple, easy-to-use game programming library inspired by XNA/MonoGame, perfect for retro aesthetics.

**Technology Stack:**
- **Language:** C, C++, Rust (raylib-rs), or Go (raylib-go)
- **Framework:** Raylib
- **Rendering:** Built-in 2D rendering with shader support
- **Audio:** Built-in audio engine
- **Build System:** CMake or Cargo (for Rust)

**Architecture:**

```
┌─────────────────────────────────────────────┐
│              Raylib API                      │
│  (Graphics, Audio, Input, Text, Shapes)     │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│        DOS-Style Rendering Layer             │
│  - RenderTexture2D (320x200)                │
│  - Palette shader (256-color emulation)     │
│  - Pixel-perfect rendering                  │
│  - CRT shader (optional)                    │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│         Game State & Logic Layer             │
│  - State machines                           │
│  - Turn management                          │
│  - ECS pattern (optional)                   │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│          Game Systems (Ported)               │
│  (Same as SDL2 option)                      │
└─────────────────────────────────────────────┘
```

**Pros:**
- ✅ Simpler API than SDL2 (easier learning curve)
- ✅ Built-in functions for common game tasks
- ✅ Excellent retro game support (many examples)
- ✅ Multiple language bindings (C, C++, Rust, Go, Python)
- ✅ Shader support for palette effects
- ✅ Active development and community
- ✅ Cross-platform (Windows, Linux, macOS, Web via Emscripten)
- ✅ Smaller codebase than SDL2

**Cons:**
- ❌ Still requires rewriting logic to C/C++/Rust
- ❌ Less mature than SDL2
- ❌ Fewer third-party tools/plugins
- ❌ No built-in UI system (must build custom)

**Best For:** Teams wanting a balance between ease of use and DOS authenticity, especially if considering Rust.

**Rust Advantage:**
Using Raylib with Rust (raylib-rs) offers:
- Memory safety without garbage collection
- Modern language features (pattern matching, enums, traits)
- Excellent tooling (Cargo, rustfmt, clippy)
- Easier refactoring than C/C++

---

### Option 3: Pico-8 / TIC-80 Fantasy Console

**Overview:**
Fantasy consoles that emulate imaginary 80s/90s-style game systems with strict limitations.

**Technology Stack:**
- **Language:** Lua (Pico-8) or Lua/JS/Python (TIC-80)
- **Framework:** Pico-8 or TIC-80
- **Resolution:** 128x128 (Pico-8) or 240x136 (TIC-80)
- **Colors:** 16 (Pico-8) or 16 (TIC-80)
- **Distribution:** Web, Windows, Linux, macOS

**Architecture:**

```
┌─────────────────────────────────────────────┐
│         Fantasy Console API                  │
│  (Drawing, Sprites, Map, Sound, Music)      │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│       Game Loop (Lua Callbacks)              │
│  - _init() - Setup                          │
│  - _update() - Game logic (30/60 FPS)       │
│  - _draw() - Rendering                      │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│      Simplified Game Systems                 │
│  - Reduced scope due to constraints         │
│  - Smaller maps (128x128 or 240x136)        │
│  - Simplified AI                            │
│  - Limited units/buildings                  │
└─────────────────────────────────────────────┘
```

**Pros:**
- ✅ Authentic retro aesthetic by design
- ✅ Extremely simple API
- ✅ Fast prototyping
- ✅ Lua is easier than C/C++
- ✅ Built-in sprite/map editors
- ✅ Built-in sound/music tools
- ✅ Web export built-in
- ✅ Active community with many examples

**Cons:**
- ❌ **Severe limitations:** 128x128 or 240x136 resolution
- ❌ **Token limit:** Pico-8 has 8192 token limit (code size)
- ❌ **Color limit:** Only 16 colors
- ❌ **Map size:** Limited to small maps
- ❌ **Not suitable for complex 4X games** like Guvnaville
- ❌ Would require massive scope reduction
- ❌ No flexibility to break limits

**Best For:** Tiny games, prototypes, game jams. **NOT recommended** for Guvnaville due to scope.

---

### Option 4: ASCII/ANSI Terminal-Based (ncurses, BearLibTerminal)

**Overview:**
Pure text-mode interface using ASCII/ANSI art, like classic roguelikes (NetHack, Dwarf Fortress).

**Technology Stack:**
- **Language:** C, C++, Python, Rust
- **Framework:** ncurses, BearLibTerminal, or libtcod
- **Rendering:** Terminal text cells (80x25, 80x50, 120x40)
- **Colors:** 16-color ANSI or 256-color extended
- **Platform:** Cross-platform terminals

**Architecture:**

```
┌─────────────────────────────────────────────┐
│       Terminal Abstraction Layer             │
│  (ncurses / BearLibTerminal / libtcod)      │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│          ASCII Rendering Engine              │
│  - Character-based tile rendering           │
│  - Color pair management                    │
│  - Box-drawing characters for UI            │
│  - CP437 character set (DOS)                │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│            Game Logic Layer                  │
│  (Same systems as current, adapted)         │
└─────────────────────────────────────────────┘
```

**Pros:**
- ✅ Ultra-authentic DOS text-mode aesthetic
- ✅ Extremely lightweight
- ✅ Runs in any terminal
- ✅ Nostalgic appeal for roguelike fans
- ✅ Simple rendering (just characters)
- ✅ Fast development for UI

**Cons:**
- ❌ Limited visual expressiveness (no pixel art)
- ❌ Less intuitive for non-roguelike players
- ❌ Mouse support varies by library
- ❌ May not appeal to broader audience
- ❌ Accessibility concerns (color blindness)

**Best For:** Roguelike-style games or developers wanting extreme simplicity. **Viable** for Guvnaville if willing to embrace ASCII aesthetic.

**Example:**
```
┌────── GUVNAVILLE: Turn 42 ─────────────────────────┐
│ Scrap: 250 ⚙  Food: 180 ⚏  Fuel: 45 ⛽            │
├────────────────────────────────────────────────────┤
│                                                    │
│  . . # # # # . . ~ ~ . . . . . . . . . . . . . .  │
│  . . # # @ # . . ~ ~ . . M . . . . . # # # . . .  │
│  # # # B # . . . . . . . . . . . . . # H # . . .  │
│  # S # # . . . . . . . . . . U . . . # # # . . .  │
│  . . . . . . . . . . . . . . . . . . . . . . . .  │
│                                                    │
│  @ = Your HQ    M = Militia    S = Shelter        │
│  B = Barracks   H = Enemy HQ   U = Enemy Unit     │
│  # = Ruins      ~ = Water      . = Wasteland      │
│                                                    │
│  [M]ove  [A]ttack  [B]uild  [Space] End Turn      │
└────────────────────────────────────────────────────┘
```

---

### Option 5: Web-Based (Canvas + JavaScript/TypeScript)

**Overview:**
HTML5 Canvas with JavaScript/TypeScript, using retro rendering techniques and palette shaders.

**Technology Stack:**
- **Language:** TypeScript or JavaScript
- **Framework:** Custom or lightweight (Phaser 3, PixiJS, or pure Canvas)
- **Rendering:** 2D Canvas API with palette shader
- **Audio:** Web Audio API or Howler.js
- **Build:** Vite, Webpack, or Parcel
- **Platform:** Browser (Chrome, Firefox, Safari)

**Architecture:**

```
┌─────────────────────────────────────────────┐
│         Browser APIs                         │
│  (Canvas, WebGL, Audio, Input, Storage)     │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│      Retro Rendering Pipeline                │
│  - Low-res canvas (320x200)                 │
│  - Palette quantization shader (WebGL)      │
│  - Nearest-neighbor scaling                 │
│  - CRT shader (optional)                    │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│         Game Engine (TypeScript)             │
│  - State management (Redux/MobX)            │
│  - ECS or OOP architecture                  │
│  - Event system                             │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│      Game Systems (Ported from GDScript)     │
│  - TypeScript has similar syntax to GDScript│
│  - JSON data can be reused directly         │
└─────────────────────────────────────────────┘
```

**Pros:**
- ✅ Easiest deployment (just a URL)
- ✅ TypeScript syntax similar to GDScript (easier porting)
- ✅ No installation required for players
- ✅ Cross-platform by default
- ✅ Can reuse JSON data files directly
- ✅ Hot reloading during development
- ✅ Large ecosystem (npm packages)
- ✅ Modern dev tools (VS Code, browser DevTools)

**Cons:**
- ❌ Performance limited by JavaScript (slower than C/C++)
- ❌ Requires internet connection (unless PWA)
- ❌ No native desktop feel
- ❌ Save system limited to LocalStorage/IndexedDB
- ❌ Browser compatibility issues

**Best For:** Teams wanting rapid development and maximum accessibility. **Strong candidate** due to TypeScript/GDScript similarity.

**Migration Path:**
1. Port GDScript classes to TypeScript (syntax is very similar)
2. Reuse JSON data files directly
3. Implement Canvas rendering with palette shader
4. Port systems one at a time, testing incrementally

---

## Recommended Approaches

### Recommendation #1: Raylib with Rust (⭐ Primary Recommendation)

**Why Raylib + Rust:**

1. **Optimal Balance:**
   - Modern language with safety guarantees
   - Simple API for DOS-style rendering
   - Cross-platform support
   - Strong performance

2. **DOS Aesthetic Implementation:**
   ```rust
   // Create 320x200 render texture
   let mut render_target = load_render_texture(&rl, 320, 200);

   // Render game to low-res texture
   rl.begin_texture_mode(&render_target);
   draw_game_state(&game_state);
   rl.end_texture_mode();

   // Scale to window with nearest-neighbor
   rl.begin_drawing();
   draw_texture_ex(
       render_target.texture,
       Vector2::zero(),
       0.0,
       scale,
       WHITE,
   );
   rl.end_drawing();
   ```

3. **Migration Strategy:**
   - **Phase 1:** Core types and state (Unit, Tile, GameState) → Rust structs
   - **Phase 2:** Rendering system with Raylib
   - **Phase 3:** Game systems (map, combat, economy)
   - **Phase 4:** AI and events
   - **Phase 5:** UI and polish

4. **Estimated Timeline:** 4-6 months with 1 developer

**Pros Over Other Options:**
- ✅ Memory safety (no segfaults, no leaks)
- ✅ Simpler than raw SDL2
- ✅ Better performance than web
- ✅ More flexible than Pico-8
- ✅ More visual than ASCII

---

### Recommendation #2: Web-Based TypeScript (⭐ Runner-Up)

**Why Web + TypeScript:**

1. **Easiest Migration Path:**
   - GDScript → TypeScript is mostly straightforward
   - Reuse all JSON data files
   - Similar OOP patterns

2. **Example Migration:**

**GDScript (current):**
```gdscript
class_name Unit
extends Node

var unit_type: String
var hp: int
var position: Vector2i

func move_to(target: Vector2i) -> bool:
    if can_move_to(target):
        position = target
        return true
    return false
```

**TypeScript (migrated):**
```typescript
class Unit {
    unitType: string;
    hp: number;
    position: Vector2;

    moveTo(target: Vector2): boolean {
        if (this.canMoveTo(target)) {
            this.position = target;
            return true;
        }
        return false;
    }
}
```

3. **DOS Rendering:**
```typescript
// Create low-res canvas
const gameCanvas = document.createElement('canvas');
gameCanvas.width = 320;
gameCanvas.height = 200;
const ctx = gameCanvas.getContext('2d');

// Disable smoothing for pixelated look
ctx.imageSmoothingEnabled = false;

// Render game
renderGameState(ctx, gameState);

// Scale to screen
const screenCtx = screenCanvas.getContext('2d');
screenCtx.imageSmoothingEnabled = false;
screenCtx.drawImage(gameCanvas, 0, 0, screenWidth, screenHeight);
```

4. **Estimated Timeline:** 3-4 months with 1 developer

**Pros Over Rust:**
- ✅ Faster development
- ✅ Easier debugging
- ✅ Instant deployment
- ✅ Familiar syntax from GDScript

**Cons vs Rust:**
- ❌ Lower performance
- ❌ Requires browser

---

### Recommendation #3: SDL2 with C (For Purists)

**Why SDL2 + C:**

Maximum authenticity - closest to actual DOS development experience with modern cross-platform support.

**Estimated Timeline:** 6-8 months with 1 developer (longest due to C complexity)

---

## Migration Concerns & Challenges

### Challenge 1: Codebase Size

**Current:** 41,000+ lines of GDScript across 160 files

**Impact:**
- Complete rewrite required for any non-GDScript option
- High risk of introducing bugs
- Extensive testing needed

**Mitigation:**
- Incremental migration (port systems one at a time)
- Comprehensive unit tests
- Keep Godot version running for comparison testing
- Consider hybrid approach (Godot for prototyping, new engine for final)

---

### Challenge 2: Loss of Godot Features

**Godot Features Currently Used:**
- Scene system
- Signal/event system
- Built-in UI nodes
- Animation system
- Resource management
- Inspector/editor

**Impact:**
- Must manually implement equivalents
- UI development becomes much harder
- No visual scene editor

**Mitigation:**
- Use data-driven design (JSON for everything)
- Build custom tools (level editor, data editor)
- Keep UI simple (DOS aesthetic helps here)

---

### Challenge 3: Data Migration

**Current Data:**
- 22 unit definitions (JSON)
- 32 building definitions (JSON)
- 50+ events (JSON)
- 30+ culture nodes (JSON)
- Map generation data (JSON)

**Impact:**
- ✅ **Low** - JSON is universal, can reuse directly
- May need schema adjustments for new type system

**Mitigation:**
- Write schema converters
- Validate all data in new system
- Add comprehensive data tests

---

### Challenge 4: Testing Infrastructure

**Current:** GUT (Godot Unit Test) framework with 42+ tests

**Impact:**
- Must rebuild test infrastructure in new language
- All tests must be rewritten

**Mitigation:**
- Use language-native test frameworks:
  - **Rust:** cargo test (built-in)
  - **C/C++:** Catch2, Unity, Google Test
  - **TypeScript:** Jest, Vitest
- Port tests incrementally as systems are migrated
- Keep integration tests to verify equivalence

---

### Challenge 5: Performance Considerations

**Current Performance:**
- 70-80 FPS rendering
- 2-3 second turn processing (8 AI factions)
- ~1GB memory usage

**Target Performance (DOS-style):**
- 60 FPS (or 30 FPS for authentic DOS feel)
- <5 second turn processing
- <100MB memory (DOS-authentic)

**Considerations:**
- C/C++/Rust will be faster than Godot for logic
- Software rendering may be slower than GPU rendering
- Trade-offs between authenticity and smoothness

**Mitigation:**
- Profile early and often
- Optimize hot paths
- Consider hybrid rendering (low-res GPU-accelerated)

---

### Challenge 6: Cross-Platform Support

**Current:** Godot exports to Windows, macOS, Linux easily

**New Options:**
- **SDL2/Raylib:** Cross-platform by design (easy)
- **Web:** Universal (easiest)
- **ncurses:** Platform-specific terminal issues
- **Pico-8:** Built-in cross-platform

**Mitigation:**
- Choose framework with strong cross-platform support
- Test on all platforms regularly
- Use CI/CD for automated builds

---

### Challenge 7: Asset Pipeline

**Current:** Godot imports and manages assets automatically

**New Pipeline Needs:**
- Sprite sheet tools
- Tile map editors
- Font conversion (TTF → bitmap)
- Palette management tools
- Sound effect tools (MOD/S3M/XM)

**Mitigation:**
- Use existing tools:
  - **Aseprite** for pixel art
  - **Tiled** for maps
  - **MilkyTracker** for music
  - **Piskel** (free alternative)
- Build custom import scripts

---

### Challenge 8: Development Velocity

**Current:** Godot provides rapid iteration with hot reloading

**New Reality:**
- Compile times (C/C++/Rust)
- Manual asset pipeline
- No visual editor

**Mitigation:**
- Use hot reloading where possible:
  - **Web:** Instant (Vite HMR)
  - **Rust:** cargo-watch
  - **C/C++:** ccache, unity builds
- Data-driven design (change JSON, no recompile)
- Good editor integration (rust-analyzer, clangd)

---

### Challenge 9: Team Skills

**Current Skills:** GDScript, Godot ecosystem

**Required Skills:**
- **Raylib/Rust:** Rust programming, ownership/borrowing
- **SDL2/C:** C programming, manual memory management
- **Web/TS:** TypeScript, web APIs, bundlers
- **ncurses:** Terminal programming

**Mitigation:**
- Training period (2-4 weeks)
- Start with small prototype
- Pair programming for knowledge transfer

---

## Migration Strategies

### Strategy A: Clean Slate Rewrite

**Approach:** Start from scratch, rebuild game in new engine.

**Process:**
1. Set up new project structure
2. Implement core rendering
3. Port data types (Unit, Tile, etc.)
4. Port game systems one by one
5. Port UI last
6. Add polish and effects

**Timeline:** 4-6 months

**Pros:**
- ✅ Clean architecture
- ✅ No legacy code
- ✅ Opportunity to refactor

**Cons:**
- ❌ High risk (no playable game for months)
- ❌ Difficult to compare with original
- ❌ All-or-nothing approach

**Best For:** Small teams with clear vision and time.

---

### Strategy B: Incremental System Migration

**Approach:** Port one system at a time, testing as you go.

**Process:**
1. Build core framework (rendering, input, state)
2. Port map system → test standalone
3. Port unit system → test with map
4. Port combat system → test with units
5. Continue until all systems ported
6. Integrate everything
7. Port UI and polish

**Timeline:** 5-7 months

**Pros:**
- ✅ Lower risk (always have working prototype)
- ✅ Easy to compare with Godot version
- ✅ Testable at each step

**Cons:**
- ❌ Longer timeline
- ❌ May build disposable integration code
- ❌ Requires disciplined process

**Best For:** Risk-averse teams, solo developers.

---

### Strategy C: Hybrid Approach (Godot for Tools)

**Approach:** Keep Godot for level editor/tools, export data for new engine.

**Process:**
1. Build new game engine
2. Keep Godot project for level editing
3. Export maps/data from Godot → JSON
4. Import in new engine
5. Eventually phase out Godot

**Timeline:** 4-5 months

**Pros:**
- ✅ Leverage Godot's editor strengths
- ✅ Faster content creation
- ✅ Smooth transition

**Cons:**
- ❌ Maintaining two codebases temporarily
- ❌ Export/import pipeline overhead

**Best For:** Content-heavy games, teams that value tooling.

---

### Strategy D: Prototype First, Then Decide

**Approach:** Build small prototypes in multiple engines, then commit.

**Process:**
1. Week 1-2: Raylib prototype (basic map + unit rendering)
2. Week 3-4: Web/TypeScript prototype
3. Week 5-6: SDL2 prototype (if team has C experience)
4. Compare and choose
5. Full migration with chosen engine

**Timeline:** 6 weeks prototyping + 3-5 months migration

**Pros:**
- ✅ Informed decision
- ✅ Discover issues early
- ✅ Team learns new technologies

**Cons:**
- ❌ Upfront time investment
- ❌ May delay project

**Best For:** Teams with time, uncertain about best option.

---

## Effort Estimates

### Effort Breakdown by System (for Raylib/Rust)

| System | Current Lines (GDScript) | Estimated Lines (Rust) | Effort (Days) | Risk |
|--------|--------------------------|------------------------|---------------|------|
| **Core Types** (Unit, Tile, Building, Resource) | ~2,000 | ~1,500 | 5 | Low |
| **State Management** (GameState, WorldState, FactionState) | ~1,500 | ~1,200 | 4 | Low |
| **Event System** (replacing EventBus) | ~800 | ~600 | 3 | Medium |
| **Data Loader** (JSON parsing, validation) | ~1,000 | ~800 | 3 | Low |
| **Map System** (generation, spatial queries, fog of war) | ~3,000 | ~2,500 | 10 | Medium |
| **Rendering** (tile renderer, unit renderer, sprites) | ~2,500 | ~2,000 | 12 | High |
| **Camera & Input** | ~800 | ~600 | 3 | Low |
| **Unit System** (movement, abilities, status effects) | ~3,500 | ~3,000 | 12 | Medium |
| **Combat System** (resolver, morale, modifiers) | ~4,000 | ~3,500 | 14 | High |
| **Economy System** (resources, production, trade) | ~3,000 | ~2,500 | 10 | Medium |
| **Culture System** | ~2,000 | ~1,800 | 7 | Low |
| **AI System** (personalities, goal planning, tactical) | ~5,000 | ~4,500 | 18 | High |
| **Event System** (dynamic events, choices, triggers) | ~2,500 | ~2,200 | 8 | Medium |
| **Save/Load System** | ~1,200 | ~1,000 | 4 | Medium |
| **Turn Management** | ~1,000 | ~800 | 3 | Low |
| **UI System** (HUD, dialogs, menus, tooltips) | ~6,000 | ~5,000 | 20 | High |
| **Tutorial System** | ~1,500 | ~1,200 | 5 | Low |
| **Polish & Effects** | ~1,000 | ~800 | 6 | Medium |
| **Testing & QA** | ~2,000 | ~2,000 | 15 | Medium |
| **Integration & Debugging** | N/A | N/A | 10 | High |
| **Documentation** | N/A | N/A | 5 | Low |

**Total Estimated Effort:** ~156 days (~7 months at 20 days/month)

**Adjusted for Learning Curve & Risk:** 180-210 days (~8-10 months)

---

### Effort by Alternative

| Alternative | Effort (Months) | Complexity | Learning Curve |
|-------------|-----------------|------------|----------------|
| **Raylib + Rust** | 6-8 | Medium-High | Medium |
| **SDL2 + C** | 8-10 | High | Low (if C experience) |
| **Web + TypeScript** | 4-6 | Medium | Low (similar to GDScript) |
| **Pico-8** | 2-3 | Low | Very Low |
| **ncurses + C** | 5-7 | Medium | Medium |

---

## Risk Assessment

### High-Risk Areas

1. **AI System Migration** (5,000 lines)
   - Complex decision-making logic
   - Personality systems
   - Risk: Logic errors could break AI behavior
   - Mitigation: Extensive testing, AI vs AI matches

2. **Combat System** (4,000 lines)
   - Many edge cases
   - Morale calculations
   - Risk: Balance changes, bugs in combat resolution
   - Mitigation: Unit tests for all scenarios, comparison testing

3. **Rendering System** (2,500 lines)
   - Performance-critical
   - DOS aesthetic implementation
   - Risk: Poor performance, visual bugs
   - Mitigation: Early prototyping, profiling

4. **UI System** (6,000 lines)
   - No built-in UI framework (unlike Godot)
   - Must build from scratch
   - Risk: Time sink, poor UX
   - Mitigation: Simplify UI, use immediate-mode GUI, focus on keyboard

### Medium-Risk Areas

5. **Map Generation** (procedural algorithm)
   - Complex algorithm
   - Risk: Different results than Godot version
   - Mitigation: Port algorithm exactly, compare outputs

6. **Save/Load System**
   - Serialization format changes
   - Risk: Incompatible saves
   - Mitigation: Version saves, provide converter

### Low-Risk Areas

7. **Data Migration** (JSON files)
   - Low risk, JSON is universal
   - Mitigation: Schema validation

8. **Core Types** (structs/classes)
   - Straightforward translation
   - Mitigation: Property-based testing

---

## Decision Matrix

### Scoring Criteria (1-5, 5 is best)

| Criteria | Weight | Raylib+Rust | SDL2+C | Web+TS | Pico-8 | ncurses |
|----------|--------|-------------|--------|--------|--------|---------|
| **DOS Authenticity** | 25% | 5 | 5 | 4 | 5 | 5 |
| **Development Speed** | 20% | 3 | 2 | 5 | 5 | 3 |
| **Performance** | 15% | 5 | 5 | 3 | 4 | 5 |
| **Ease of Migration** | 20% | 3 | 2 | 4 | 1 | 3 |
| **Cross-Platform** | 10% | 5 | 5 | 5 | 5 | 3 |
| **Scope Fit** | 10% | 5 | 5 | 5 | 1 | 4 |
| **TOTAL SCORE** | 100% | **4.1** | **3.7** | **4.3** | **3.5** | **3.9** |

### Weighted Scores

1. **Web + TypeScript: 4.3** ⭐ (Best for speed & ease)
2. **Raylib + Rust: 4.1** ⭐ (Best for authenticity + safety)
3. **ncurses: 3.9** (Niche appeal)
4. **SDL2 + C: 3.7** (Maximum control, slower dev)
5. **Pico-8: 3.5** (Too limited for scope)

---

## Next Steps

### Phase 1: Decision & Planning (Week 1-2)

1. **Review this document** with team
2. **Decide on architecture** (recommend: Raylib+Rust or Web+TS)
3. **Set up development environment**
4. **Define success criteria**

### Phase 2: Prototype (Week 3-6)

1. **Build minimal prototype:**
   - 320x200 rendering
   - Basic tile map
   - Unit sprite rendering
   - Keyboard input
2. **Test DOS aesthetic** (screenshots, feel)
3. **Performance benchmark** (can we hit 60 FPS?)
4. **Go/No-Go decision**

### Phase 3: Core Migration (Month 2-3)

1. Port core types and state
2. Port data loader
3. Port map system
4. Build rendering pipeline
5. **Milestone:** Viewable map with units

### Phase 4: Systems Migration (Month 4-6)

1. Port movement and combat
2. Port economy and production
3. Port turn management
4. Port AI (basic version)
5. **Milestone:** Playable game loop

### Phase 5: Polish & Parity (Month 7-8)

1. Port remaining systems (events, culture)
2. Build UI (HUD, dialogs, menus)
3. Port tutorial
4. Add DOS-style effects (palette cycling, CRT shader)
5. **Milestone:** Feature parity with Godot version

### Phase 6: Release (Month 9)

1. Beta testing
2. Bug fixes
3. Performance optimization
4. Documentation
5. **Release v2.0** - DOS Edition

---

## Conclusion

Migrating Guvnaville from Godot to a DOS-aesthetic engine is **feasible but significant** undertaking. The recommended approach is:

**Primary Recommendation:** **Raylib + Rust**
- Optimal balance of authenticity, performance, and safety
- 6-8 month timeline
- Modern tooling with retro aesthetic

**Alternative Recommendation:** **Web + TypeScript**
- Fastest migration path (4-6 months)
- Easiest syntax translation from GDScript
- Maximum accessibility

**Key Success Factors:**
1. Start with prototype to validate approach
2. Migrate incrementally, testing each system
3. Maintain test coverage throughout
4. Keep scope focused on core 4X gameplay
5. Embrace DOS limitations (simpler can be better)

**Final Thought:**
A 90s DOS aesthetic can actually **simplify** the project by removing pressure for high-fidelity graphics, allowing focus on deep strategy gameplay. The migration is an opportunity to refine and streamline the codebase while achieving a unique, nostalgic visual style that stands out in the modern indie game landscape.

---

## Appendix A: Code Comparison Examples

### Example 1: Unit Structure

**Current (GDScript):**
```gdscript
class_name Unit
extends Node

var unit_type: String
var faction_id: int
var hp: int
var max_hp: int
var attack: int
var defense: int
var movement: int
var position: Vector2i

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    if hp == 0:
        die()
```

**Rust:**
```rust
pub struct Unit {
    pub unit_type: String,
    pub faction_id: u8,
    pub hp: i32,
    pub max_hp: i32,
    pub attack: i32,
    pub defense: i32,
    pub movement: i32,
    pub position: Vector2i,
}

impl Unit {
    pub fn take_damage(&mut self, amount: i32) {
        self.hp = (self.hp - amount).max(0);
        if self.hp == 0 {
            self.die();
        }
    }
}
```

**TypeScript:**
```typescript
class Unit {
    unitType: string;
    factionId: number;
    hp: number;
    maxHp: number;
    attack: number;
    defense: number;
    movement: number;
    position: Vector2i;

    takeDamage(amount: number): void {
        this.hp = Math.max(0, this.hp - amount);
        if (this.hp === 0) {
            this.die();
        }
    }
}
```

---

### Example 2: DOS Rendering

**Raylib (Rust):**
```rust
// Create 320x200 render target
let mut render_target = rl.load_render_texture(&thread, 320, 200);

// Game loop
while !rl.window_should_close() {
    // Render to low-res buffer
    {
        let mut d = rl.begin_texture_mode(&thread, &mut render_target);
        d.clear_background(Color::BLACK);

        // Draw tiles
        for y in 0..25 {
            for x in 0..40 {
                let tile = map.get_tile(x, y);
                d.draw_texture(&tile.sprite, x * 8, y * 8, Color::WHITE);
            }
        }
    }

    // Scale to screen
    let mut d = rl.begin_drawing(&thread);
    d.clear_background(Color::BLACK);
    d.draw_texture_ex(
        &render_target.texture,
        Vector2::zero(),
        0.0,
        3.0, // 3x scale (320x200 -> 960x600)
        Color::WHITE,
    );
}
```

**Web (TypeScript):**
```typescript
// Create low-res canvas
const gameCanvas = document.createElement('canvas');
gameCanvas.width = 320;
gameCanvas.height = 200;
const gameCtx = gameCanvas.getContext('2d')!;
gameCtx.imageSmoothingEnabled = false;

// Create display canvas
const screenCanvas = document.getElementById('screen') as HTMLCanvasElement;
const screenCtx = screenCanvas.getContext('2d')!;
screenCtx.imageSmoothingEnabled = false;

// Game loop
function render() {
    // Draw to low-res canvas
    gameCtx.fillStyle = '#000000';
    gameCtx.fillRect(0, 0, 320, 200);

    // Draw tiles
    for (let y = 0; y < 25; y++) {
        for (let x = 0; x < 40; x++) {
            const tile = map.getTile(x, y);
            gameCtx.drawImage(tile.sprite, x * 8, y * 8);
        }
    }

    // Scale to screen (3x = 960x600)
    screenCtx.drawImage(gameCanvas, 0, 0, 960, 600);

    requestAnimationFrame(render);
}
```

---

### Example 3: Event System

**Current (GDScript with EventBus):**
```gdscript
# Emit event
EventBus.unit_moved.emit(unit, old_pos, new_pos)

# Listen for event
func _ready():
    EventBus.unit_moved.connect(_on_unit_moved)

func _on_unit_moved(unit: Unit, old_pos: Vector2i, new_pos: Vector2i):
    print("Unit moved from ", old_pos, " to ", new_pos)
```

**Rust (with custom event system):**
```rust
// Define event
pub enum GameEvent {
    UnitMoved { unit_id: u32, old_pos: Vector2i, new_pos: Vector2i },
}

// Event dispatcher
pub struct EventBus {
    listeners: HashMap<TypeId, Vec<Box<dyn Fn(&GameEvent)>>>,
}

// Emit event
event_bus.emit(GameEvent::UnitMoved {
    unit_id: unit.id,
    old_pos,
    new_pos,
});

// Listen
event_bus.on_unit_moved(|event| {
    if let GameEvent::UnitMoved { unit_id, old_pos, new_pos } = event {
        println!("Unit {} moved from {:?} to {:?}", unit_id, old_pos, new_pos);
    }
});
```

---

## Appendix B: Tool Recommendations

### Development Tools

**Raylib + Rust:**
- **IDE:** VS Code with rust-analyzer
- **Build:** Cargo
- **Testing:** cargo test
- **Profiling:** perf, cargo-flamegraph
- **Debugging:** GDB, LLDB

**Web + TypeScript:**
- **IDE:** VS Code
- **Build:** Vite
- **Testing:** Vitest or Jest
- **Profiling:** Chrome DevTools
- **Debugging:** Chrome DevTools

### Asset Tools

- **Pixel Art:** Aseprite ($20), Piskel (free), GIMP
- **Tile Maps:** Tiled (free)
- **Fonts:** TheDraw, ASCII Paint
- **Music:** MilkyTracker (free MOD tracker)
- **SFX:** SFXR, Bfxr (free chiptune generators)
- **Palettes:** Lospec (free palette database)

---

## Appendix C: Resources & References

### Learning Resources

**Raylib:**
- Official site: https://www.raylib.com/
- Raylib-rs (Rust): https://github.com/raysan5/raylib-rs
- Examples: https://www.raylib.com/examples.html

**DOS Graphics Programming:**
- "256-Color VGA Programming in C" by David Brackeen
- Mode 13h tutorials
- DOSBox source code

**Retro Game Development:**
- "Game Engine Black Book: Wolfenstein 3D" by Fabien Sanglard
- "Game Engine Black Book: DOOM" by Fabien Sanglard
- /r/retrogamedev subreddit

**Rust for Games:**
- "Hands-on Rust" by Herbert Wolverson
- "Game Development with Rust and WebAssembly" by Eric Smith

---

**Document End**
