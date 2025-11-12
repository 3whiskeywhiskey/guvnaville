# ADR-003: Emergent Culture System vs. Pre-Defined Factions

## Status
**Accepted**

## Context
Strategy games typically use either pre-defined civilizations with fixed bonuses (Civilization's civs) or completely symmetric factions. For a post-apocalyptic rebuilding game, we must decide how factions differentiate themselves and develop identity.

### Options Considered

#### Option A: Pre-Defined Factions with Fixed Bonuses
- Each faction has permanent traits (like Civ civs)
- Unique units, buildings, and bonuses from start
- Predictable playstyles
- Easy to balance and understand

#### Option B: Completely Symmetric Factions
- All factions start identical
- Differentiation comes only from player choices
- Maximum flexibility
- Can feel bland or samey

#### Option C: Emergent Culture System (Chosen)
- Factions start with minor cultural tendencies
- Major differentiation emerges through player choices
- Culture tree with multiple axes (government, belief, technology, social)
- Choices compound to create unique faction identities

## Decision
**We will use an emergent culture system where factions develop unique identities through gameplay choices rather than fixed at game start.**

## Rationale

### Thematic Alignment
Post-apocalyptic societies aren't born fully formed - they **emerge** from survival choices:
- Military faction → because they controlled the armory
- Technocracy → because they found a research bunker
- Raider culture → because they couldn't secure farmland
- Religious order → because a charismatic leader arose after a crisis

The culture system should reflect this emergent storytelling.

### Player Agency
Players should **create** their faction's identity, not just play a pre-made one:
- "I became raiders because my early expansion failed"
- "I chose democracy because I allied with the Free City"
- "I worship technology because I captured the research district"

This creates personal investment and unique stories.

### Replayability
With 4 culture axes (Government, Belief, Technology, Social), each with 3-4 major paths:
- 4 × 4 × 4 × 4 = **256 possible combinations**
- Each combination creates different playstyles
- No two playthroughs are identical

Pre-defined factions might have 8-12 options. Culture trees have hundreds.

### Reactive Gameplay
Culture choices respond to game state:
- Captured the hospital? → Can afford egalitarian healthcare policies
- Lost territory? → Military dictatorship becomes appealing
- Trading successfully? → Merchant republic makes sense
- Found a pre-war AI? → Transhumanism unlocks

This creates **meaningful** choices, not just build-order optimization.

### Cultural Drift vs. Cultural Lock-In
Early choices create tendencies, but aren't permanent:
- Can shift from democracy to autocracy during crisis
- Can embrace technology after rejecting it early
- Can reform raider culture into civilization
- Each shift has costs and story weight

This reflects real societal evolution and creates dramatic narratives.

### Asymmetric Balance
Instead of balancing 8 pre-made factions, we balance culture tree nodes:
- Each node has roughly equal power
- Combinations create synergies
- No single path is "best" - depends on resources controlled and game state
- Easier to balance and patch post-launch

### Faction Personality Preservation
While culture emerges, factions retain subtle starting characteristics:
- **The Vault Collective**: Slight preservationist tendency, +10% research start
- **The Rust Brothers**: Slight industrialist tendency, +1 scrap per turn
- **The Free City**: Slight democratic tendency, +1 happiness start

This gives flavor without constraining choices.

## Culture System Design

### Four Cultural Axes

#### 1. Governance Path (How power is organized)
```
Autocratic Branch:
├─ Strongman Rule (base)
├─ Warlord State (+25% military, -1 happiness)
└─ Military Dictatorship (+50% military, martial law policies)

Democratic Branch:
├─ Town Council (base)
├─ Representative Government (+2 happiness, slower decisions)
└─ New Republic (+4 happiness, diplomatic bonuses, cultural influence)

Collectivist Branch:
├─ Workers' Commune (base)
├─ Syndicalist Union (+25% production, shared resources)
└─ Pure Collectivism (+50% production, -1 freedom)

Tribal Branch:
├─ Clan Leadership (base)
├─ Clan Federation (+1 loyalty per clan, family bonuses)
└─ Neo-Feudal Kingdom (noble class, hierarchy bonuses)
```

#### 2. Belief System (What do you value?)
```
Secular Branch:
├─ Pragmatic Survival (base)
├─ Rationalist Society (+2 research, -superstition)
└─ Technocracy (scientists rule, +50% research, tech requirements for leaders)

Spiritual Branch:
├─ Folk Traditions (base)
├─ Ancestor Worship (+1 culture, +moral in defense)
└─ Mystic Order (psychic abilities?, radiation resistance, cultural bonuses)

Materialist Branch:
├─ Survivor's Pragmatism (base)
├─ Merchant Republic (+2 trade income, commercial policies)
└─ Corporate State (efficiency bonuses, stratified society)

Nihilist Branch:
├─ Survival of Fittest (base)
├─ Raider Culture (+25% loot, -diplomatic relations)
└─ Darwinist Empire (+50% combat, absorb defeated pops)
```

#### 3. Technology Philosophy (Relationship with the old world)
```
Preservationist Branch:
├─ Respect the Past (base)
├─ Archaeotech Collectors (better scavenging, repair bonuses)
└─ Old World Restoration (can rebuild pre-war tech, massive research bonuses)

Innovationist Branch:
├─ Learn and Adapt (base)
├─ Wasteland Engineers (new post-war inventions, improvised tech)
└─ New Age Inventors (unique post-apocalyptic tech tree, innovation bonuses)

Primitivist Branch:
├─ Simple Life (base)
├─ Agrarian Society (farming bonuses, happiness from nature)
└─ Green Return (nature reclamation, anti-technology, unique units)

Transhumanist Branch:
├─ Augmentation Ethics (base)
├─ Cybernetic Integration (cyborg units, enhanced specialists)
└─ Post-Human Ascension (transcend humanity, unique victory path)
```

#### 4. Social Structure (How society is organized)
```
Egalitarian Branch:
├─ Equal Treatment (base)
├─ Equal Rights Movement (+3 happiness, -stratification)
└─ Universal Brotherhood (no social classes, shared resources, unity bonuses)

Hierarchical Branch:
├─ Natural Order (base)
├─ Caste System (specialists more powerful but pops less happy)
└─ Stratified Order (extreme inequality, elite bonuses, unrest risk)

Meritocratic Branch:
├─ Earn Your Place (base)
├─ Achievement Society (specialists train faster, competition bonuses)
└─ Apex Culture (best rise to top, maximize specialist output)

Familial Branch:
├─ Family First (base)
├─ Dynastic Houses (family bonuses, inheritance systems)
└─ Blood Nobility (aristocracy, loyalty bonuses, hereditary rule)
```

### Culture Points & Progression

#### Earning Culture Points
- **Per Turn**: Base 1-3 depending on population and buildings
- **Events**: Cultural events grant points
- **Unique Locations**: Cultural sites (museums, monuments, broadcast stations)
- **Milestones**: First combat victory, first trade route, discoveries

#### Spending Culture Points
- Each node costs increasing amounts (base 50, tier 2 100, tier 3 200)
- Can only advance one tier at a time per axis
- Some nodes have prerequisites (need certain buildings/resources)
- Some nodes lock out others (can't be both democratic AND autocratic)

#### Cultural Drift Cost
- Switching branches mid-game costs double
- Causes temporary instability
- Narrative events explain the shift
- Some switches more expensive than others (democracy→dictatorship easier during crisis)

### Culture Bonuses

Culture bonuses affect:
- **Economic**: Production, research, resource generation
- **Military**: Unit strength, morale, special abilities
- **Diplomatic**: Relations, trade, influence
- **Social**: Happiness, population growth, loyalty
- **Special**: Unique units, buildings, policies, or mechanics

### Synergies & Anti-Synergies

#### Example Synergies
- **Technocracy + Preservationist** = "Neo-Academicians" (massive research from old-world sites)
- **Raider Culture + Darwinist** = "Apex Predators" (terrifying combat bonuses)
- **Democratic + Egalitarian** = "True Republic" (extreme happiness and cultural influence)
- **Mystic Order + Primitivist** = "Green Faith" (nature magic and anti-tech bonuses)

#### Example Anti-Synergies
- **Technocracy + Primitivist** = Conflict (which takes priority?)
  - *Resolution*: Can hold both but no synergy bonus, must choose eventual path
- **Democratic + Caste System** = Tension (democratic with rigid hierarchy?)
  - *Resolution*: Stability penalties unless addressed through policy
- **Raider + Merchant** = "Pirate Economy" (actually works but different from honest trade)

### Cultural Policies

Each major culture node unlocks 2-3 **policies** (toggled bonuses with trade-offs):
- **Martial Law** (Military Dictatorship): +25% defense, -2 happiness, military units can police
- **Open Archives** (New Republic): +cultural influence, +1 research, but enemies can see your tech
- **Ritual Combat** (Tribal): Replace some battles with duels, +morale but risky
- **Planned Economy** (Collectivism): +production but -flexibility in production changes
- **Wealth Stratification** (Corporate): Elites produce more, everyone else produces less

### Cultural Buildings

Culture paths unlock unique buildings:
- **Technocracy**: "Research Council Building" (+5 research, can designate specialist research projects)
- **Raider Culture**: "War Shrine" (+10% combat strength in surrounding tiles, intimidation bonus)
- **Democratic**: "Assembly Hall" (-unrest, can hold votes on policies)
- **Primitivist**: "Sacred Grove" (+happiness, removes radiation from tile over time)

## Consequences

### Positive
- Massive replayability (hundreds of culture combinations)
- Player agency in faction identity creation
- Stories emerge from choices ("we became raiders to survive")
- Reactive to game state (culture responds to circumstances)
- Easier to balance than fixed factions
- Modding community can add culture nodes easily
- No "wrong" culture path (all viable with right resources)

### Negative
- More complex than fixed factions
  - *Mitigation*: Clear UI, tooltips, tutorial
- Risk of "optimal" culture paths emerging
  - *Mitigation*: Balance patches, situational bonuses
- AI must handle culture choices intelligently
  - *Mitigation*: AI personality influences culture choices, weighted decision-making
- Analysis paralysis for new players
  - *Mitigation*: Recommended paths in tutorial, can't make culture choices until turn 20-30
- Harder to market ("play as 8 unique factions" simpler than "emergent culture")
  - *Mitigation*: Show example culture combinations, marketing around player stories

### Technical Implications
- Culture tree UI is critical to player experience
- Need culture point tracking and progression system
- Policy toggle system
- Cultural building unlock system
- AI culture evaluation and decision-making
- Save system must track culture progression

### Design Implications
- Tutorial must explain culture system without overwhelming
- Events should reference and react to player's culture
- Other factions react to your culture (respect? fear? disgust?)
- Victory conditions can interact with culture
- Culture should be visible (unit appearance, building style, UI flavor)
- Descriptions and flavor text vary by culture

## AI Behavior

### AI Culture Development
Each AI faction has personality influencing culture choices:
- **The Vault Collective**: Strongly prefers Preservationist + Technocracy
- **The Crimson Horde**: Strongly prefers Raider + Darwinist
- **The Free City**: Strongly prefers Democratic + Egalitarian
- But can adapt based on game state (free city might go autocratic if losing badly)

### AI Culture Evaluation
AI evaluates culture choices based on:
- Controlled resources (hospital → enables certain cultures)
- Military situation (losing → militaristic cultures)
- Diplomatic relations (allies → compatible cultures)
- Random variation (some chaos for unpredictability)

## Player Communication

### Visual Feedback
- Culture tree screen shows progression and available choices
- Faction shield/symbol evolves based on culture
- Unit appearance reflects culture (raiders look different from technocrats)
- Building architecture changes
- UI color scheme and flavor text adapts

### Narrative Integration
- Events reference your culture: "As a democratic society, how do you respond to refugees?"
- Other factions comment: "The raiders respect strength. Your diplomacy means nothing to them."
- Ending/victory screens describe your cultural legacy

## Related Decisions
- ADR-001: Single City Focus (enables deep culture systems)
- ADR-002: Unique Resources (resources influence culture choices)
- ADR-006: Victory Conditions (culture affects how you can win)

## References
- *Stellaris*: Ethics and civic system
- *Crusader Kings 3*: Culture and cultural evolution
- *Old World*: Character and dynasty systems
- *Humankind*: Culture combination system
- *Endless Legend*: Faction asymmetry

## Date
2025-11-12

## Authors
Design Team
