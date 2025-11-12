# ADR-002: Unique Resources vs. Abundant Generic Resources

## Status
**Accepted**

## Context
Resource systems in strategy games typically use generic, renewable resources (gold, wood, food) that can be harvested from multiple identical locations. We must decide how to handle resources in a post-apocalyptic city setting where pre-war infrastructure cannot be rebuilt.

### Options Considered

#### Option A: Traditional Generic Resources
- Multiple identical sources of each resource type
- Renewable resources (farms grow food, mines produce metal)
- Focus on production optimization and economic management
- Standard 4X resource model

#### Option B: Unique Strategic Locations (Chosen)
- Each major resource location is unique and irreplaceable
- Pre-war facilities cannot be rebuilt, only repaired/controlled
- Locations provide specific bonuses, not just generic resources
- Scarcity drives territorial competition

#### Option C: Hybrid System
- Mix of unique locations and generic resources
- Some resources renewable, others from unique sites
- Balanced complexity

## Decision
**We will use unique strategic locations as the primary resource system, supplemented by common stockpiled resources.**

## Rationale

### Post-Apocalyptic Authenticity
In a post-collapse world:
- You can't build a new hospital with advanced medical equipment
- You can't construct a nuclear power plant from scratch
- You can't create a university library with pre-war knowledge
- Pre-war infrastructure is **irreplaceable treasure**

This creates authentic scarcity. The old world's greatest achievements become the new world's most valuable prizes.

### Territorial Competition & Conflict
Unique resources create compelling strategic competition:
- "I need the hospital, but the Vault Collective controls it"
- "If I capture the solar array, I'll have a power monopoly"
- "The enemy has the only tank factory - we must destroy or capture it"

Generic resources lead to: "I'll just build another farm"
Unique resources lead to: "I must take THAT farm or die"

### Asymmetric Gameplay
Each playthrough is different based on which unique locations you control:
- Control the university → Research advantages
- Control the factory district → Production powerhouse
- Control the medical center → Population growth
- Control the armory → Military superiority

Players must adapt strategy to controlled resources rather than following a fixed build order.

### Meaningful Choices
Every territorial decision matters:
- Which district to expand into first
- Whether to trade or fight for a key location
- Whether to defend or abandon a resource when attacked
- How much to invest in securing vs. exploiting a location

Generic resources make these choices optimization problems. Unique resources make them strategic dilemmas.

### Environmental Storytelling
Unique locations enable rich storytelling:
- The Central Hospital: "Still has functioning MRI machines - the lead-lined walls protected the electronics from the EMP"
- The University District: "The library vault preserved thousands of books, but the combination was lost"
- Blackwater Power Plant: "The reactor still works, but radiation leaks make it deadly to approach"

Each location has history, personality, and narrative weight.

### Economic Differentiation
While strategic locations are unique, we maintain stockpiled common resources:
- **Food**: Produced by any farmland, consumed by population
- **Scrap**: Salvaged from ruins, used for basic construction
- **Ammunition**: Manufactured or found, consumed in combat
- **Medicine**: Produced at medical facilities or scavenged
- **Fuel**: Rare, valuable, enables vehicles

This creates two economic layers:
1. **Strategic Layer**: Unique locations (long-term competitive advantage)
2. **Tactical Layer**: Stockpiled resources (short-term operations)

### Balance Through Interdependence
No faction can control all unique resources, forcing:
- **Trade**: "I'll trade you medical supplies for ammunition"
- **Specialization**: "I'm the medical faction, everyone needs me"
- **Diplomacy**: "Alliance gives us complementary resources"
- **Raiding**: "I'll steal what I can't trade for"

Generic resources allow self-sufficiency. Unique resources enforce interdependence.

## Consequences

### Positive
- Every strategic location is important and memorable
- Territorial competition is intense and personal
- Diplomatic and trade systems are essential, not optional
- Replayability through different resource control patterns
- Asymmetric faction development
- Strong thematic coherence with post-apocalyptic setting
- Environmental storytelling opportunities

### Negative
- More complex to balance than generic resources
  - *Mitigation*: Playtesting and community feedback
- Requires handcrafted content for ~200+ unique locations
  - *Mitigation*: Content pipeline and clear design templates
- Players might feel "locked out" of strategies by resource distribution
  - *Mitigation*: Multiple paths to victory, trade systems, alternative locations with different bonuses
- Can create "snowball" effects if one faction captures key resources early
  - *Mitigation*: Defensive bonuses for smaller factions, sabotage mechanics, alliances

### Technical Implications
- Database of unique locations with specific attributes
- UI to show controlled strategic resources
- AI must evaluate unique location value and compete for them
- Save system must track unique location states
- Mod support must allow custom locations

### Design Implications
- Map design is critical - location placement affects game balance
- Each location needs design time: bonuses, narrative, visual identity
- Victory conditions can't rely on "out-producing" opponents
- Cultural bonuses can interact with specific resource types
- Combat has higher stakes (losing territory means losing irreplaceable assets)

### Balance Considerations

#### Preventing Monopolies
- Most resource types have 2-4 major locations (not just one)
- Alternative approaches: "No hospital? Use herbal medicine (cultural path)"
- Sabotage allows denying resources to enemies
- Cultural bonuses can compensate for missing resources

#### Starting Position Balance
- All factions start equidistant from high-value resources
- Starting positions provide different early advantages
- Tutorial scenario has balanced starting positions

#### Resource Tiers
- **Tier 1**: Basic survival (water, food) - multiple sources
- **Tier 2**: Development (workshops, clinics) - several sources
- **Tier 3**: Strategic (factories, labs, broadcast stations) - 2-3 sources
- **Tier 4**: Unique wonders (single location with massive bonuses)

## Implementation Strategy

### Phase 1: Core System
- Define resource location types and bonuses
- Implement capture and control mechanics
- Create UI for tracking controlled locations

### Phase 2: Content Creation
- Design and place 200+ unique locations
- Write descriptions and narrative for each
- Balance location bonuses through playtesting

### Phase 3: Economic Integration
- Connect locations to stockpiled resources
- Implement trade and diplomatic systems
- Create faction AI resource evaluation

### Phase 4: Advanced Features
- Sabotage and denial mechanics
- Resource location upgrades
- Wonder projects at key locations

## Example Unique Locations

### Medical Tier
- **St. Mary's Hospital** (Tier 3): +50% medicine production, +2 max population, unlocks "Surgeon" specialist
- **PharmaCorp Warehouse** (Tier 2): +30% medicine production, can trade medicine
- **Bio-Research Lab** (Tier 4): Unlocks bio-technology research, can cure radiation sickness

### Knowledge Tier
- **Central Library** (Tier 3): +3 research per turn, +1 culture, stores pre-war knowledge
- **University Campus** (Tier 4): +5 research per turn, unlocks "Scholar" specialist, enables all research paths
- **Elementary School** (Tier 2): +1 research per turn, improves education, +10% specialist training speed

### Industrial Tier
- **Detroit Steel Factory** (Tier 4): Can produce vehicles, +100% metal production
- **Downtown Workshop District** (Tier 3): +50% production, can build advanced structures
- **Auto Repair Shop** (Tier 2): Can repair vehicles, +25% production

## Related Decisions
- ADR-001: Single City Focus (enables unique location design)
- ADR-004: Turn-Based Strategy (allows complex resource evaluation)
- ADR-009: Trade and Diplomacy Systems (TBD)

## References
- *Dune: Imperium*: Unique location control in board game design
- *Total War* series: Settlement uniqueness
- *Stellaris*: Strategic resource system
- *Old World*: Unique city improvements

## Date
2025-11-12

## Authors
Design Team
