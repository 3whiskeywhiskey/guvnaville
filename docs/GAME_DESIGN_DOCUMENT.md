# Ashes to Empire: Game Design Document

## Core Vision

**Ashes to Empire** is a post-apocalyptic 4X strategy game set entirely within the ruins of a single metropolitan city. Players control a faction of survivors emerging from the collapse, competing for control of irreplaceable pre-war resources while building a new civilization from the radioactive ashes of the old world.

## High Concept

*"Civilization meets Fallout at street-level"* - A turn-based 4X strategy game where every tile matters, every resource is unique, and every decision shapes not just your territory but your culture, ideology, and the very identity of your post-apocalyptic society.

## Game Pillars

### 1. **Scarcity & Uniqueness**
Every resource location is handcrafted and unique. There's only ONE major hospital with advanced medical equipment, ONE university library with preserved knowledge, ONE industrial bakery with working ovens. Controlling these sites provides exclusive bonuses and capabilities that define your faction's strengths.

### 2. **Cultural Evolution**
Your faction isn't just expanding - it's defining itself. Choices in government, religion, technology, and social structure create a unique culture tree that unlocks abilities, units, and playstyles. Will you become techno-scavengers, neo-feudal warlords, or democratic rebuilders?

### 3. **Urban Warfare**
City-scale combat where every building, street, and sewer tunnel matters. Verticality, chokepoints, and environmental hazards create tactical depth. Urban ruins provide defensive bonuses but also dangers (collapse, radiation, feral creatures).

### 4. **The Weight of the Past**
The pre-war world haunts everything. Old government facilities, corporate secrets, military bunkers, and civilian infrastructure all tell stories and provide strategic options. Understanding the old world helps you build the new one - or repeat its mistakes.

## Core Gameplay Loop

### Early Game: Survival & Scavenging (Turns 1-50)
- Expand from your starting shelter
- Secure basic resources (clean water, food production, shelter materials)
- Scout unique locations and plan expansion routes
- Make first cultural choices that define your faction's identity
- Establish initial contact with other factions

### Mid Game: Consolidation & Culture (Turns 51-150)
- Compete for critical unique resources
- Develop your cultural tree with major choices (government, religion, technology path)
- Engage in diplomacy, trade, or warfare over key locations
- Build specialized districts reflecting your culture
- Research pre-war technology or develop post-war innovations

### Late Game: Dominance & Legacy (Turns 151+)
- Pursue victory conditions aligned with your culture
- Engage in large-scale urban warfare or diplomatic maneuvering
- Complete wonder projects (rebuilt landmarks, new monuments)
- Shape the entire city's future through your cultural dominance

## Victory Conditions

### Territorial Supremacy
Control 60% of the city's strategic locations (requires military dominance)

### Cultural Ascendancy
Have your culture adopted by 75% of the city's population through influence and soft power

### Technological Singularity
Achieve breakthrough post-war technology (requires controlling specific pre-war research facilities)

### The New Order
Establish a functioning city-wide government with all factions acknowledging your leadership (diplomatic/military hybrid)

### The Exodus
Build and launch a generation ship to escape the dying world (requires massive resource investment)

## Core Mechanics Overview

### Map Scale & Structure
- **City Size**: 200x200 tile grid representing approximately 10km² metropolitan area
- **Tile Scale**: Each tile = 50m² (half a city block, a large building, or a street section)
- **Verticality**: Buildings have multiple floors (up to 3 levels: underground, ground, elevated)
- **Districts**: Pre-defined zones (downtown, industrial, residential, etc.) with unique characteristics
- **Points of Interest**: 200+ unique, named locations with specific bonuses

### Resource System

#### Strategic Resources (Unique Locations)
- **Knowledge Sites**: Libraries, universities, research labs (unlock technologies)
- **Industrial Sites**: Factories, workshops, power plants (enable production)
- **Medical Sites**: Hospitals, pharmaceutical labs (health and population growth)
- **Agricultural Sites**: Greenhouses, vertical farms, aquaponics (food production)
- **Material Depots**: Warehouses, construction sites (building materials)
- **Energy Sources**: Solar arrays, geothermal, old reactors (power generation)
- **Cultural Sites**: Museums, monuments, broadcast stations (cultural influence)

#### Common Resources (Stockpiled)
- **Scrap Metal**: Basic construction and equipment
- **Food**: Population sustenance
- **Medicine**: Health and mortality reduction
- **Fuel**: Vehicle operation and power generation
- **Ammunition**: Military operations
- **Clean Water**: Essential for all operations
- **Components**: Advanced manufacturing

### Population & Society

#### Population Mechanics
- Population grows based on food, water, medicine, and housing
- Each pop unit represents ~100 people
- Pops can be assigned to work tiles, buildings, or specialized roles
- Happiness affects productivity, loyalty, and migration
- Pops can have specialists: Scavengers, Soldiers, Artisans, Scholars, etc.

#### Social Stratum
- **Survivors**: Basic workers, most population
- **Specialists**: Trained in specific skills
- **Veterans**: Experienced fighters and scavengers
- **Elites**: Leaders, scientists, master craftspeople
- Balance between strata affects faction stability

### Culture System

#### Culture Trees
Each faction develops along multiple cultural axes:

**Governance Path**
- Autocratic → Warlord State → Military Dictatorship
- Democratic → Town Council → New Republic
- Collectivist → Commune → Syndicalist Union
- Tribal → Clan Federation → Neo-Feudal Kingdom

**Belief System**
- Secular → Rationalist → Technocracy
- Spiritual → Ancestor Worship → Mystic Order
- Materialist → Merchant Republic → Corpo-State
- Nihilist → Raider Culture → Darwinist Empire

**Technology Philosophy**
- Preservationist → Archaeotech Collectors → Old World Restoration
- Innovationist → Wasteland Engineers → New Age Inventors
- Primitivist → Agrarian Society → Green Return
- Transhumanist → Cybernetic Integration → Post-Human Ascension

**Social Structure**
- Egalitarian → Equal Rights Movement → Universal Brotherhood
- Hierarchical → Caste System → Stratified Order
- Meritocratic → Achievement Society → Apex Culture
- Familial → Dynastic Houses → Blood Nobility

#### Culture Points
- Gained through cultural buildings, events, and unique resources
- Spent to unlock culture tree nodes
- Each node provides bonuses, unlocks units/buildings, or enables policies
- Combinations create unique faction identities

### Combat System

#### Unit Types
- **Militia**: Basic defenders, cheap, weak
- **Scavengers**: Fast, light, good at looting
- **Raiders**: Offensive infantry, good vs. civilians
- **Soldiers**: Professional military, balanced
- **Heavy Infantry**: Armored, slow, powerful
- **Snipers**: Long range, fragile
- **Engineers**: Build, repair, demolish
- **Vehicles**: Rare, powerful, fuel-dependent (motorcycles, armored cars, tanks)
- **Specialists**: Culture-specific unique units

#### Combat Resolution
- Turn-based tactical battles on strategic map
- Units have:
  - **HP**: Hit points (damage capacity)
  - **Attack**: Damage output
  - **Defense**: Damage reduction
  - **Range**: Attack distance
  - **Movement**: Tiles per turn
  - **Special Abilities**: Culture or type specific

#### Urban Combat Modifiers
- **Cover Bonus**: Buildings provide defense (+50%)
- **Elevation Bonus**: Higher ground provides attack bonus (+25%)
- **Ambush**: Units in buildings can surprise attackers
- **Siege Mechanics**: Surrounding buildings cuts supply (-10 HP/turn)
- **Collateral Damage**: Combat can destroy buildings and tiles
- **Underground Warfare**: Sewers and tunnels enable flanking

### Diplomacy & Factions

#### Relationship System
- **Allied**: Shared vision, can cross borders, mutual defense
- **Friendly**: Trade agreements, non-aggression
- **Neutral**: Basic interaction, borders respected
- **Rival**: Border tensions, trade restrictions
- **War**: Open conflict

#### Diplomatic Actions
- Trade resources or knowledge
- Form alliances or federations
- Demand tribute or territory
- Share map information
- Cultural exchange programs
- Non-aggression pacts
- Joint military operations

#### AI Factions
8 AI factions with unique starting positions, cultures, and personalities:
- **The Vault Collective**: Preservationist bunker society
- **The Rust Brothers**: Mechanist engineers and traders
- **The Green Faith**: Eco-mystics reclaiming nature
- **The Corporate Remnant**: Pre-war company survivors
- **The Free City**: Democratic survivor coalition
- **The Crimson Horde**: Raider confederation
- **The Old Guard**: Former military trying to restore order
- **The Children of Atom**: Radiation-worshipping cultists

### Technology & Research

#### Research System
- **Tech Points**: Generated by educated pops, libraries, and labs
- **Research Paths**:
  - **Scavenging**: Better resource extraction from ruins
  - **Industry**: Advanced manufacturing and construction
  - **Military**: Better units and tactics
  - **Agriculture**: Food production and sustainability
  - **Medicine**: Health and longevity
  - **Energy**: Power generation and efficiency
  - **Culture**: Influence and social cohesion

#### Discovery Mechanic
- Exploring unique locations can unlock special technologies
- Finding pre-war data archives provides research bonuses
- Reverse-engineering pre-war equipment
- Some technologies conflict with cultural choices

### Economics

#### Production System
- Cities produce **Production Points** based on workshops, factories, and workforce
- Production builds:
  - **Buildings**: Permanent improvements
  - **Units**: Military and civilian
  - **Wonders**: Massive projects providing victory points or unique bonuses
  - **Infrastructure**: Roads, walls, power grids

#### Trade System
- Establish trade routes between your settlements
- Trade with other factions for resources you lack
- Trade routes can be raided or blockaded
- Black markets provide illegal goods at high prices
- Merchant caravans (require protection in dangerous areas)

### Events & Narrative

#### Event Types
- **Random Events**: Radiation storms, building collapses, refugee arrivals
- **Cultural Events**: Festivals, disputes, discoveries
- **Faction Events**: Diplomatic incidents, internal politics
- **Discovery Events**: Finding bunkers, vaults, secrets
- **Crisis Events**: Plague outbreaks, famine, civil unrest

#### Narrative Layers
- **Personal Stories**: Named characters with their own arcs
- **Faction History**: Your decisions create your faction's story
- **City Mystery**: Uncover what caused the apocalypse
- **Moral Choices**: Events force difficult decisions with consequences

## Art Direction & Atmosphere

### Visual Style
- **Isometric or Hex Grid**: Clear, readable strategic view
- **Color Palette**: Desaturated with pops of color (rust reds, toxic greens, radiation yellow)
- **Pre-War vs. Post-War**: Visual contrast between preserved and ruined structures
- **Environmental Storytelling**: Every tile tells a story through details

### Audio Design
- **Ambient**: Wind through ruins, distant sounds, Geiger counter clicks
- **Music**: Lonely guitars, industrial percussion, retrofuture synths
- **UI Sounds**: Satisfying clicks, warning tones
- **Cultural Music**: Each faction has unique musical themes

### Tone
- **Dark but not Grimdark**: Hope exists but must be fought for
- **Darkly Humorous**: Fallout-style absurdist humor in events and descriptions
- **Nostalgic Melancholy**: The weight of the lost world
- **Human Resilience**: People adapting and surviving

## Technical Scope

### Platform
- PC (Windows, Mac, Linux)
- Turn-based allows for complex calculations
- Mod support encouraged

### UI/UX Priorities
- **Strategic Map**: Clear view of territory, resources, and threats
- **Info Density**: Lots of information without overwhelming
- **Culture Screen**: Visual tree showing your faction's development
- **Resource Management**: At-a-glance stockpile and production
- **Combat Interface**: Tactical clarity with unit abilities
- **Event Pop-ups**: Narrative moments with meaningful choices

### Accessibility
- Colorblind modes
- Scalable UI
- Comprehensive tooltips
- Multiple difficulty levels
- Tutorial campaign

## Inspirations & References

### Games
- **Civilization Series**: Core 4X mechanics
- **Fallout 1 & 2**: Tone, setting, dark humor
- **Frostpunk**: Survival pressure, moral choices, society building
- **Into the Breach**: Tight tactical combat
- **Old World**: Event-driven narrative, character focus
- **Aurora 4X**: Deep systems and complexity (reference for systems design)
- **Crusader Kings**: Culture and character development

### Media
- **Metro 2033**: Urban post-apocalyptic survival
- **The Road**: Bleakness and hope
- **A Canticle for Leibowitz**: Post-apocalyptic cultural rebirth
- **Mad Max**: Scarcity and unique resources

## Player Experience Goals

### Players Should Feel:
- **Every decision matters**: No filler choices
- **Attachment to their faction**: They created this culture
- **Tension from scarcity**: Resources are truly limited
- **Wonder at discovery**: Finding unique locations is exciting
- **Pride in accomplishment**: Building from ashes is meaningful
- **Replay value**: Different cultures create different games

### Player Stories:
- "I built a theocratic state worshipping the old machines"
- "I controlled the only hospital, so everyone had to negotiate with me"
- "My faction became raiders because we couldn't secure farmland"
- "I found a bunker that completely changed my strategy"
- "The final battle for the city center took 20 turns and destroyed half the district"

## Design Principles

1. **Unique > Generic**: Every location, resource, and choice should feel special
2. **Scarcity Creates Stories**: Limited resources force interesting decisions
3. **Culture Emerges from Gameplay**: Don't tell players their culture - let them build it
4. **The Ruins Have Meaning**: Every part of the pre-war world should matter strategically and narratively
5. **Systems Interact**: Combat affects economy, culture affects diplomacy, resources drive conflict
6. **Asymmetric but Balanced**: Factions play differently but have equal win potential
7. **Respect Player Time**: No grinding, every turn should have meaningful decisions
8. **Embrace the Tone**: Dark, funny, melancholic, and ultimately about human resilience

## Success Metrics

### Critical Path
- Players complete tutorial and understand core systems
- Players make meaningful cultural choices
- Players compete for unique resources
- Players achieve victory through their chosen path

### Engagement
- Average campaign completion: 12-15 hours
- Replay rate: 60%+ start second campaign
- Culture diversity: All culture paths equally chosen
- Combat engagement: 30-40% of gameplay

### Community
- Modding community creates custom scenarios
- Players share faction stories
- Community debates optimal strategies
- Accessibility features used by 20%+ players

---

*This is a living document. As development progresses, sections will be refined based on playtesting and technical constraints.*
