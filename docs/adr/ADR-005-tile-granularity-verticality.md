# ADR-005: Tile Granularity and Verticality

## Status
**Accepted**

## Context
With a single-city focus, we must define the size/scale of each map tile and whether to implement verticality (multiple levels). This determines tactical depth, visual clarity, and technical complexity.

### Tile Scale Options

#### Option A: Large Tiles (City Districts)
- Each tile = entire district (~500m²)
- 50x50 grid for whole city
- Abstract, high-level strategy
- Like Civilization city management

#### Option B: Medium Tiles (City Blocks)
- Each tile = city block (~100m²)
- 100x100 grid for whole city
- Balance between detail and scope
- Standard 4X scale

#### Option C: Small Tiles (Buildings/Streets) - Chosen
- Each tile = building or street (~50m²)
- 200x200 grid for whole city
- High tactical granularity
- Deep urban warfare

### Verticality Options

#### Option A: Flat Map
- Single ground level only
- Simpler to implement and visualize
- Standard for most strategy games

#### Option B: Full 3D
- Unlimited vertical levels
- Maximum flexibility
- Very complex to implement and control

#### Option C: Three-Level System (Chosen)
- Underground, Ground, Elevated
- Tactical depth without overwhelming complexity
- Represents urban warfare realistically

## Decision
**We will use small tiles (~50m² each) on a 200x200 grid with three vertical levels (underground, ground, elevated).**

## Rationale

### Tile Granularity: Small Scale (~50m²)

#### Tactical Richness
Small tiles enable:
- **Building-to-building warfare**: Each building is tactical terrain
- **Street fighting**: Roads and alleys are meaningful
- **Chokepoints**: Bridges, intersections, narrow passages matter
- **Flanking maneuvers**: Room for tactical positioning
- **Siege warfare**: Surrounding specific buildings

At larger scales, these tactics are abstracted away. At smaller scales, they become core gameplay.

#### Unique Location Design
With ~40,000 tiles, we can have:
- **200+ major unique locations**: Hospitals, factories, monuments
- **1000+ minor points of interest**: Shops, houses, landmarks
- **Environmental storytelling**: Every district tells a story
- **Handcrafted scenarios**: Specific tactical challenges

Large tiles would limit unique locations. Small tiles enable density.

#### Urban Authenticity
Real cities have:
- Dense building clusters
- Narrow streets and alleys
- Specific landmarks (single buildings that matter)
- Neighborhood character

Small tiles capture this reality. You're not managing abstract "downtown district" - you're fighting for City Hall at 5th and Main.

#### Expansion Pacing
With 40,000 tiles:
- Controlling 500 tiles = 1.25% of city (small foothold)
- Controlling 5,000 tiles = 12.5% of city (major faction)
- Controlling 20,000 tiles = 50% of city (dominant power)

This provides granular progression. Every few turns you can expand meaningfully without enormous swings.

#### Performance Feasibility
Modern strategy games handle this scale:
- *Total War* battles: 10,000+ unit pathfinding
- *Civilization VI*: Large maps with thousands of tiles
- *Cities: Skylines*: Entire cities simulated

200x200 = 40,000 tiles is ambitious but achievable with:
- Efficient pathfinding (A*, flow fields)
- Fog of war limiting active simulation
- Turn-based (no real-time pressure)
- LOD (level of detail) for distant tiles

### Verticality: Three-Level System

#### Underground Level
Represents:
- **Subway tunnels**: Fast movement, avoid surface dangers
- **Sewers**: Infiltration routes, hidden movement
- **Bunkers**: Defensive positions, shelters
- **Basement complexes**: Storage, hideouts
- **Underground parking**: Vehicle storage
- **Natural caves**: Radiation-free zones?

Gameplay:
- Hidden movement (enemies can't see underground units)
- Flanking opportunities (emerge behind enemy lines)
- Defensive fallback (retreat underground to safety)
- Unique resources (deep bunkers, subway stations)
- Dangers (flooding, collapse, feral creatures)

#### Ground Level
Represents:
- **Streets and roads**: Standard movement
- **Buildings**: Most structures
- **Parks and plazas**: Open areas
- **Ruins**: Destroyed structures

Gameplay:
- Primary battlefield
- Most resources and locations
- Standard combat and movement
- Environmental hazards (rubble, radiation)

#### Elevated Level
Represents:
- **Multi-story buildings**: Second floor and up
- **Bridges and overpasses**: High roads
- **Rooftops**: Sniper positions
- **Skywalks**: Pre-war elevated walkways
- **Towers**: Observation and defense

Gameplay:
- Elevation advantage in combat (+25% attack)
- Sniper positions (longer range from elevation)
- Observation (see farther from high ground)
- Harder to reach (must climb or use stairs)
- Bridge control (choke points over streets)

#### Vertical Movement
Units can move between levels:
- **Stairs/Ladders**: 1-2 movement points to change level
- **Elevators**: Fast vertical movement (if powered)
- **Ropes/Climbing**: Slow but flexible
- **Collapsed access**: Some levels inaccessible without clearing

Different unit types have different vertical mobility:
- **Infantry**: Can use stairs, ladders, ropes
- **Vehicles**: Ground level only (usually)
- **Scouts**: Extra vertical mobility
- **Engineers**: Can build new vertical access

#### Vertical Combat
- **Height advantage**: +25% attack from above
- **Suppression from above**: Pin down ground units
- **Undermining**: Destroy supports, collapse buildings
- **Aerial bombardment**: Drop things from elevated positions
- **Flooding**: Water flows down (tactical use of underground flooding)

### Visual Representation

#### Isometric View (Preferred)
- Shows all three levels simultaneously
- Clear spatial relationships
- Traditional strategy game view
- Can toggle level visibility

#### Layer Switching
- UI buttons to focus on specific level
- Dim other levels when focusing
- Highlight units on selected level
- Minimap shows all levels with color coding

#### Indicators
- **Visual markers**: Icons showing units on other levels
- **Shadows**: Units underground cast no shadow
- **Elevation tint**: Higher = lighter, lower = darker
- **Access points**: Stairs, tunnels clearly marked

### Map Design Implications

#### District Variation
Different districts have different vertical profiles:

**Downtown** (skyscrapers):
- Heavy elevated level content
- Many multi-story buildings
- Skywalks connecting structures
- Underground parking and tunnels

**Residential** (suburbs):
- Mostly ground level
- Some basements (underground)
- Occasional 2-story houses (elevated)
- Simple vertical structure

**Industrial** (factories):
- Mix of all levels
- Large ground-level facilities
- Underground storage/bunkers
- Elevated catwalks and control rooms

**Old Town** (historic):
- Ground level emphasis
- Ancient tunnels and catacombs underground
- Low buildings (1-2 stories)
- Cultural landmarks

**Transit Hub** (station):
- Extensive underground (subway)
- Ground level concourse
- Elevated platforms and tracks
- Critical strategic location

#### Handcrafted Vertical Scenarios
Designer can create:
- **The Subway Wars**: Entire battles in tunnel networks
- **Rooftop Snipers**: Elevated defensive positions
- **Bunker Assaults**: Fighting down into underground facilities
- **Bridge Battles**: Fighting for elevated crossings
- **Tunnel Flanks**: Emerging from sewers behind enemy lines

## Consequences

### Positive
- Deep tactical combat with meaningful positioning
- Environmental storytelling through detailed map
- Unique locations can be specific buildings
- Vertical gameplay creates novel strategies
- High replayability through tactical variety
- Urban warfare feels authentic
- Supports "every tile matters" design goal
- Flanking, ambushes, and siege mechanics shine

### Negative
- High complexity for new players
  - *Mitigation*: Tutorial, gradual introduction, clear UI
- Performance challenges with 40,000 tiles
  - *Mitigation*: Optimization, turn-based helps, LOD systems
- Visual clarity with three levels
  - *Mitigation*: Layer toggling, clear indicators, good camera
- AI must handle vertical tactics
  - *Mitigation*: Pathfinding considers all levels, AI uses simple vertical rules
- More content creation (must design 40,000 tiles)
  - *Mitigation*: Tile templates, procedural assistance, focus detail on key areas

### Technical Implications
- 3D pathfinding (A* across three levels)
- Visibility system accounts for elevation
- Combat calculations include elevation bonuses
- Map editor supports vertical tile placement
- Save system stores three-level state
- Performance optimization critical
- Camera system shows verticality clearly

### Design Implications
- Map design is critical and time-intensive
- Must balance vertical density by district
- Tutorial must explain verticality
- Units need vertical mobility attributes
- Some abilities specific to levels (underground stealth, elevated sniping)
- Events can affect specific levels (flood underground, air strike elevated)

## Technical Implementation

### Tile Data Structure
```
Tile {
  position: {x, y, z}  // z = -1 (underground), 0 (ground), 1 (elevated)
  type: enum (street, building, tunnel, rubble, etc.)
  terrain_features: [] (cover, hazard, resource)
  movement_cost: int
  defense_bonus: int
  vertical_access: {
    has_stairs: bool
    has_ladder: bool
    has_elevator: bool
    elevator_powered: bool
  }
  occupying_unit: Unit | null
  controlled_by: Faction | null
  unique_location: UniqueLocation | null
}
```

### Pathfinding
- A* algorithm with 3D coordinate space
- Movement costs account for level changes
- Visibility raycasting checks vertical obstructions
- Flow fields for large-scale movement

### Rendering
- Isometric projection
- Layer opacity controls
- Minimap with level color-coding
- Unit elevation indicators

## Accessibility & Usability

### Learning Curve
- Tutorial introduces levels gradually:
  1. Ground combat only (first 10 turns)
  2. Introduce underground tunnels (turns 11-20)
  3. Introduce elevated positions (turns 21-30)
  4. Full vertical tactics (turn 31+)

### Visual Clarity
- Colorblind-safe level indicators
- Strong contrast between levels
- Outline units on different levels
- Camera rotation to see obscured areas
- Toggle layers on/off easily

### Simplified Mode (Optional)
- Option to disable verticality for accessibility
- Converts all tiles to ground level
- Easier for new players or preference
- Achievement/balance separate

## Map Size Justification

### Why 200x200?
- **Not too small**: 100x100 = 10,000 tiles feels cramped for 8 factions
- **Not too large**: 300x300 = 90,000 tiles is overwhelming and performance-intensive
- **Sweet spot**: 40,000 tiles supports:
  - 8 factions with ~5,000 tiles each at endgame
  - Dense urban environment
  - Room for no-man's-land and contested zones
  - Achievable performance targets

### Tile Density
- ~50% buildings (20,000 tiles)
- ~30% streets/roads (12,000 tiles)
- ~10% parks/plazas (4,000 tiles)
- ~10% special/rubble (4,000 tiles)

## Related Decisions
- ADR-001: Single City Focus (enables detailed tile design)
- ADR-004: Turn-Based Strategy (handles complex tile calculations)
- ADR-007: Combat System Design (TBD - verticality affects combat)

## References
- *XCOM 2*: Multi-level tactical combat
- *Phoenix Point*: Verticality in turn-based tactics
- *Into the Breach*: Perfect information on small, detailed grid
- *Frostpunk*: City management at building scale
- *Metro 2033*: Underground tunnel warfare inspiration

## Date
2025-11-12

## Authors
Design Team
