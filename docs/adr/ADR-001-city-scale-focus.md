# ADR-001: Single City Focus vs. Multiple Cities/Regions

## Status
**Accepted**

## Context
Traditional 4X games feature expansion across vast territories - continents, planets, or galaxies. For a post-apocalyptic game, we must decide whether to follow this model (multiple cities/regions) or focus on a single city at much higher granularity.

### Options Considered

#### Option A: Multiple Cities/Regions (Traditional 4X)
- Players expand across multiple ruined cities or regions
- Each city is abstracted into a single tile or small cluster
- Larger strategic scope, familiar to 4X players
- More territory to conquer and manage

#### Option B: Single City Focus (Chosen)
- Entire game takes place within one metropolitan area
- Individual streets, buildings, and blocks are tiles
- Higher tactical and strategic granularity
- Every location can be handcrafted and unique

## Decision
**We will focus the entire game on a single city with street/building-level granularity.**

## Rationale

### Uniqueness and Scarcity
A single city allows us to make **every location matter**. There's only ONE major hospital, ONE university, ONE power plant. This creates meaningful scarcity - in a multi-city game, losing a hospital in one city is recoverable; in a single city, it's a strategic catastrophe.

### Handcrafted Content
With ~200x200 tiles representing one city, we can:
- Name every significant location
- Give each point of interest unique bonuses and history
- Create environmental storytelling for every district
- Design tactical combat scenarios that leverage specific geography

This would be impossible across multiple cities without procedural generation (which dilutes uniqueness).

### Thematic Coherence
Post-apocalyptic fiction (Metro 2033, The Road, Mad Max) often focuses on intimate, localized struggles. A single city creates:
- Personal stakes (you know every district, every resource)
- Territorial identity (neighborhoods become meaningful)
- Cultural coherence (you're building ONE society, not managing an empire)
- Narrative focus (uncover THIS city's apocalypse story)

### Strategic Depth Without Complexity Bloat
Rather than managing dozens of abstracted cities, players make deep strategic choices about:
- Which specific buildings to control
- How to route supply lines through dangerous streets
- Whether to destroy or preserve valuable structures in combat
- Which faction controls which district

This creates strategic depth through **meaningful** complexity, not scope.

### Urban Warfare Specialization
Focusing on a city enables:
- Building-to-building combat systems
- Verticality (underground/ground/elevated)
- Chokepoints, ambushes, siege mechanics
- Environmental hazards unique to urban ruins
- Infrastructure warfare (destroy bridges, tunnel through buildings)

These mechanics would be superficial in a multi-city game but become core pillars here.

### Performance and Scope
A single city is achievable for our development scope:
- 40,000 tiles (200x200) is manageable for pathfinding and AI
- Content creation is feasible (vs. generating multiple unique cities)
- Players can learn and master the map (like StarCraft players master specific maps)
- Development can focus on depth over breadth

## Consequences

### Positive
- Every location feels unique and important
- Players develop intimate knowledge of the game map
- Territorial competition is intense and personal
- Urban warfare can be a core mechanic
- Handcrafted content enables environmental storytelling
- Development scope is realistic
- Supports "every decision matters" design principle

### Negative
- Less traditional 4X "expansion" feel
- Map must be replayable despite being static
  - *Mitigation*: Randomized starting positions, events, and faction behaviors
- Players might worry about "limited" content
  - *Mitigation*: Deep systems create emergent gameplay
- No exploration of "unknown" territory after initial playthroughs
  - *Mitigation*: Discovery events, hidden bunkers, and secrets provide exploration

### Technical Implications
- Need robust urban tile system with verticality
- AI must handle street-level tactics and strategy
- Map editor must support detailed location crafting
- Performance optimization for dense urban environment
- Fog of war and vision systems for street-level play

### Design Implications
- Victory conditions must work without "empire building"
- Cultural system becomes primary differentiation between factions
- Resource scarcity is a core design pillar
- Replayability comes from different cultural paths and faction interactions, not map variety
- Tutorial must emphasize what makes this different from traditional 4X

## Related Decisions
- ADR-002: Unique Resources vs. Abundant Generic Resources
- ADR-005: Tile Granularity and Verticality
- ADR-008: Map Generation vs. Handcrafted Map (TBD)

## References
- *Metro 2033* series: Single-location post-apocalyptic depth
- *Frostpunk*: Single-city survival strategy
- *Battle Brothers*: Handcrafted world with emergent gameplay
- *Into the Breach*: Tactical depth in small spaces

## Date
2025-11-12

## Authors
Design Team
