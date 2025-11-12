# Ashes to Empire - Game Design Documentation

## Overview

**Ashes to Empire** is a Fallout-esque post-apocalyptic 4X strategy game with grand strategy elements, set entirely within a single ruined metropolitan city. Players compete for control of irreplaceable pre-war resources while building unique cultures from the radioactive ashes of civilization.

**Core Concept**: *"Civilization meets Fallout at street-level"*

---

## Documentation Index

### 📋 Core Design

#### [Game Design Document](GAME_DESIGN_DOCUMENT.md)
Complete vision and overview of the game including:
- Core pillars and vision
- Gameplay loops (early/mid/late game)
- Victory conditions
- Core mechanics overview
- Art direction and atmosphere
- Player experience goals

**Start here** for the big picture.

---

### 🏛️ Architectural Decision Records (ADRs)

Critical design decisions with rationale and consequences:

#### [ADR-001: City-Scale Focus](adr/ADR-001-city-scale-focus.md)
**Decision**: Focus on single city at building/street scale vs. multiple cities
- Why one city creates deeper strategy
- How granularity enables unique locations
- Performance and scope considerations

#### [ADR-002: Unique Resources System](adr/ADR-002-unique-resources-system.md)
**Decision**: Unique, handcrafted locations vs. generic renewable resources
- Post-apocalyptic authenticity through scarcity
- How uniqueness drives conflict
- Asymmetric gameplay through resource control

#### [ADR-003: Emergent Culture System](adr/ADR-003-emergent-culture-system.md)
**Decision**: Player-driven cultural evolution vs. pre-defined civilizations
- Four cultural axes (Governance, Belief, Technology, Social)
- 256+ possible culture combinations
- How choices create unique faction identities

#### [ADR-004: Turn-Based Strategy](adr/ADR-004-turn-based-strategy.md)
**Decision**: Turn-based with simultaneous resolution vs. real-time
- Managing cognitive complexity
- Strategic depth over reflexes
- Simultaneous turns for fairness

#### [ADR-005: Tile Granularity and Verticality](adr/ADR-005-tile-granularity-verticality.md)
**Decision**: 200x200 grid with three vertical levels
- Small tiles (~50m²) for tactical richness
- Underground, Ground, Elevated levels
- Urban warfare mechanics

#### [ADR-006: Victory Conditions](adr/ADR-006-victory-conditions.md)
**Decision**: Six distinct victory paths
- Territorial Supremacy, Cultural Ascendancy, Technological Singularity
- The New Order (diplomatic), The Exodus, Raider King
- How victories align with cultures

---

### ⚙️ Game Systems

#### [Combat System](systems/COMBAT_SYSTEM.md)
Complete tactical and strategic combat mechanics:
- **Unit Types**: 10+ unique units (Militia, Soldiers, Vehicles, Specialists)
- **Tactical Combat**: Turn-based battles with terrain, cover, elevation
- **Urban Warfare**: Buildings, verticality, chokepoints, siege mechanics
- **Auto-Resolve**: Quick resolution for minor battles
- **Special Mechanics**: Morale, retreat, flanking, collateral damage

#### [Resource & Economics System](systems/RESOURCE_ECONOMICS_SYSTEM.md)
Comprehensive economic design:
- **Strategic Resources**: Knowledge, Production, Medical, Agricultural, Energy, Culture
- **Stockpiled Resources**: Scrap, Food, Medicine, Ammunition, Fuel, Components, Water
- **Scavenging System**: Depletion mechanics, yields, dangers
- **Trade System**: Routes, black markets, resource trading
- **Population Economics**: Growth, assignment, specialists, happiness
- **Wonder Projects**: Massive economic buildings

---

### 🎭 Factions & Content

#### [Factions](FACTIONS.md)
Eight unique AI factions with full design:

1. **The Vault Collective** - Preservationist technocrats
   - Democratic bunker society with pre-war archives
   - Research-focused, cautious expansion

2. **The Rust Brothers** - Mechanist engineer cult
   - Machine worshippers, vehicle specialists
   - Trade and industry focus

3. **The Green Faith** - Eco-primitivist mystics
   - Nature reclamation, sustainable agriculture
   - Defensive, highest food production

4. **The Corporate Remnant** - Ruthless mega-corp survivors
   - Efficiency-obsessed, hierarchical
   - Economic dominance strategy

5. **The Free City** - Democratic survivor coalition
   - Rebuilding civil society and governance
   - Cultural and diplomatic focus

6. **The Crimson Horde** - Brutal raider confederation
   - Strength-based hierarchy, constant aggression
   - Raiding and conquest focus

7. **The Old Guard** - Military/police remnants
   - Trying to restore order and law
   - Professional military, defensive strategy

8. **The Children of Atom** - Radiation-worshipping cultists
   - Immune to radiation, fanatical
   - Cultural conversion through faith

Each faction includes:
- Starting location and resources
- Cultural tendencies and bonuses
- Unique units and abilities
- Personality and diplomatic style
- Victory path preferences
- Leaders and story hooks

---

#### [Unique Locations Catalog](UNIQUE_LOCATIONS.md)
200+ handcrafted strategic locations:

**Tiered System**:
- **Tier 4**: Wonder Sites (8-10) - Game-changing unique locations
- **Tier 3**: Major Locations (40-50) - Critical strategic objectives
- **Tier 2**: Significant Locations (60-80) - Important but not unique
- **Tier 1**: Minor Locations (80-100) - Common but valuable

**Location Categories**:
- **Medical**: Hospitals, clinics, pharmaceutical labs
- **Industrial**: Factories, workshops, scrapyards
- **Knowledge**: Universities, libraries, research facilities
- **Agricultural**: Farms, greenhouses, food warehouses
- **Energy**: Power plants, solar arrays, reactors
- **Cultural**: Museums, theaters, broadcast stations, City Hall
- **Military**: Bases, armories, training grounds
- **Infrastructure**: Water treatment, spaceport, bridges

**Examples**:
- Central Medical Center (Tier 4): +30 medicine/turn, +15% pop growth
- Detroit Steel Complex (Tier 4): Can build tanks, +100 PP/turn
- University Campus (Tier 4): +15 research/turn, unlocks all tech paths
- Nuclear Power Plant (Tier 4): +50 power/turn but extreme risk

Includes capture mechanics, hazards, synergies, and strategic value.

---

### 📖 Gameplay Guide

#### [Gameplay Guide](GAMEPLAY_GUIDE.md)
Complete tutorial and strategy guide:

**Tutorial Campaign** (Turns 1-50):
- Turn 1-5: Immediate survival (water, food, security)
- Turn 6-15: Establishing territory (first contact, buildings)
- Turn 16-30: Cultural awakening (first choices, strategic goals)
- Turn 31-50: Expanding empire (Tier 3 locations, crises)

**Strategy Guides**:
- Territorial Supremacy (military conquest)
- Cultural Ascendancy (soft power)
- Technological Singularity (research race)
- The New Order (diplomatic unification)
- The Exodus (escape to space)
- Raider King (rule through fear)

**Advanced Tactics**:
- Urban warfare mastery
- Economic optimization
- Diplomatic maneuvering
- Common mistakes to avoid

**Reference**:
- Hotkeys and interface tips
- Difficulty levels
- Achievements and challenges

---

## Key Design Principles

### 1. Scarcity Creates Stories
Every resource location is unique and handcrafted. There's only ONE major hospital, ONE university, ONE tank factory. This scarcity forces conflict, trade, and meaningful territorial decisions.

### 2. Culture Emerges from Gameplay
Your faction's identity develops through your choices, not pre-defined traits. Will you become techno-scavengers, neo-feudal warlords, or democratic rebuilders? Your actions define you.

### 3. Every Tile Matters
At street/building scale (200x200 grid), every location is significant. One building can change the strategic picture. Urban combat is tactical and meaningful.

### 4. The Weight of the Past
Pre-war infrastructure drives everything. Understanding and controlling the old world's remnants is key to building the new world - or repeating its mistakes.

### 5. Systems Interact Meaningfully
Combat affects economy, culture affects diplomacy, resources drive conflict. Everything connects. Player choices ripple through all systems.

---

## Quick Reference

### Victory Conditions
1. **Territorial Supremacy**: Control 60% of strategic locations
2. **Cultural Ascendancy**: 75% cultural adoption, 10,000 culture points
3. **Technological Singularity**: Complete tech tree, build Prometheus Project
4. **The New Order**: Allied with 5+ factions, control City Hall, unify city
5. **The Exodus**: Build generation ship at Spaceport, escape dying world
6. **Raider King**: Vassalize/destroy all factions, rule through fear

### Core Resources
**Strategic**: Knowledge, Production, Medical, Agricultural, Energy, Culture
**Stockpiled**: Scrap, Food, Medicine, Ammunition, Fuel, Components, Water

### Culture Axes
1. **Governance**: Autocratic, Democratic, Collectivist, Tribal
2. **Belief**: Secular, Spiritual, Materialist, Nihilist
3. **Technology**: Preservationist, Innovationist, Primitivist, Transhumanist
4. **Social**: Egalitarian, Hierarchical, Meritocratic, Familial

### Map Scale
- **Grid**: 200x200 tiles (40,000 tiles total)
- **Tile Size**: ~50m² (half a city block)
- **Vertical Levels**: Underground, Ground, Elevated
- **City Size**: ~10km² metropolitan area

---

## Development Status

**Status**: Design Documentation Complete ✅

**Completed Documentation**:
- ✅ Game Design Document
- ✅ 6 Architectural Decision Records
- ✅ Combat System Design
- ✅ Resource & Economics System
- ✅ 8 Faction Designs
- ✅ 200+ Unique Location Catalog
- ✅ Complete Gameplay Guide

**Next Steps** (Implementation):
- Technical architecture design
- Engine selection/development
- Art pipeline and visual design
- Prototype core systems
- Playtesting and balance

---

## Design Philosophy

*"We wanted to create a game where every decision matters, every resource has a story, and every playthrough creates a unique narrative. The city isn't just a setting - it's a character. Its ruins tell the story of what was lost, and your choices determine what rises from the ashes."*

### What Makes This Different?

**From Traditional 4X Games**:
- Single city focus (not empire-spanning)
- Every resource location unique (not generic)
- Culture emerges from choices (not pre-defined civs)
- Street-level tactics (not abstract armies)

**From Other Post-Apocalyptic Games**:
- Strategic empire-building (not just survival)
- Urban grand strategy (not wasteland wandering)
- Political/cultural depth (not just combat)
- Multiple victory paths (not just "survive")

**From City Builders**:
- Competitive 4X (not peaceful city management)
- Military conquest option (not just building)
- Unique locations (not place-anywhere buildings)
- Scarcity and conflict (not abundance)

---

## Inspirations

### Games
- **Civilization Series**: Core 4X mechanics
- **Fallout 1 & 2**: Tone, setting, dark humor
- **Frostpunk**: Survival pressure, moral choices
- **Into the Breach**: Tight tactical combat
- **Old World**: Event-driven narrative
- **Aurora 4X**: Deep systems complexity
- **Crusader Kings**: Culture and character

### Media
- **Metro 2033**: Urban post-apocalyptic survival
- **The Road**: Bleakness and hope
- **A Canticle for Leibowitz**: Post-apocalyptic rebirth
- **Mad Max**: Scarcity and unique resources

---

## Contact & Contribution

This is a design document for a game concept. All documentation is subject to change based on prototyping, playtesting, and technical constraints.

For questions, suggestions, or collaboration inquiries, see the main repository.

---

*"From the ashes of the old world, what will you build?"*

**Ashes to Empire** - A post-apocalyptic 4X strategy game where every choice shapes your civilization's future.
