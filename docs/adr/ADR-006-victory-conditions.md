# ADR-006: Victory Conditions Design

## Status
**Accepted**

## Context
Victory conditions define how players win and shape the entire gameplay experience. Traditional 4X games use variations of Domination, Science, Culture, and Diplomacy victories. We must design victory conditions that fit our post-apocalyptic city setting and encourage different playstyles.

### Design Requirements
- Support multiple viable playstyles
- Reflect post-apocalyptic themes
- Align with culture system
- Create interesting endgame scenarios
- Prevent "inevitable victory" staleness
- Be achievable within 12-15 hour campaigns (~150-200 turns)

## Victory Conditions

### 1. Territorial Supremacy (Domination)

**Objective**: Control 60% of the city's strategic locations

**Description**: Through military might or strategic maneuvering, establish absolute control over the majority of the city's critical infrastructure and resources.

**Requirements**:
- Control 60% of unique strategic locations (hospitals, factories, power plants, etc.)
- Maintain control for 10 consecutive turns (to prevent last-minute swings)
- Must control at least one location in each district (prevents ignoring entire areas)

**Optimal Culture Paths**:
- Military Dictatorship (Governance)
- Darwinist Empire (Belief)
- Any Technology path
- Meritocratic or Hierarchical (Social)

**Gameplay Style**:
- Military-focused expansion
- Strategic resource denial
- Defensive fortifications
- Aggressive diplomacy or warfare
- Focus on production and military units

**Endgame**: Large-scale urban warfare battles for contested districts, desperate alliances against the dominant faction.

---

### 2. Cultural Ascendancy (Cultural Victory)

**Objective**: Achieve cultural dominance through soft power and influence

**Description**: Build such a compelling society that other factions voluntarily adopt your culture, absorb refugees who seek your way of life, and spread your influence across the entire city.

**Requirements**:
- Accumulate 10,000 Culture Points
- Have your culture adopted by 75% of the city's total population (including other factions' pops)
- Control all cultural landmarks (museums, monuments, broadcast stations)
- Complete the "Cultural Monument" wonder project

**Cultural Influence Mechanic**:
- Adjacent tiles to your territory gain your cultural influence
- Broadcast stations extend influence range
- Population migrates toward higher-culture factions
- Other factions may voluntarily adopt your cultural policies

**Optimal Culture Paths**:
- New Republic or Pure Collectivism (Governance)
- Any Belief path with cultural bonuses
- Preservationist (for museums) or Innovationist
- Universal Brotherhood or Apex Culture (Social)

**Gameplay Style**:
- Focus on happiness and population growth
- Build cultural buildings and wonders
- Protect cultural sites
- Diplomatic alliances
- Peaceful expansion and soft power projection

**Endgame**: Other factions peacefully integrate, cultural festivals and monuments built, the city unified under your cultural banner.

---

### 3. Technological Singularity (Science Victory)

**Objective**: Achieve breakthrough post-war technology through research dominance

**Description**: By controlling pre-war research facilities and dedicating your society to technological advancement, achieve a breakthrough that transcends the post-apocalyptic world.

**Requirements**:
- Complete the entire technology tree (all research paths maxed)
- Control at least 3 major research facilities (universities, labs)
- Complete the "Prometheus Project" wonder (represents technological breakthrough)
- Generate 500 cumulative research points

**Breakthrough Options** (player chooses one):
- **AI Awakening**: Restore pre-war artificial intelligence
- **Fusion Power**: Unlimited clean energy
- **Genetic Cure**: Eliminate radiation and mutation
- **Quantum Computing**: Transcendent computational ability

**Optimal Culture Paths**:
- Technocracy (Belief)
- Preservationist or Transhumanist (Technology)
- Democratic or Meritocratic (helps research)
- Any Social path

**Gameplay Style**:
- Prioritize research facilities
- Protect scientists and scholars
- Invest in education and knowledge
- Trade for research resources
- Peaceful or defensive military (focus on research)

**Endgame**: Massive wonder project, dramatic breakthrough event, other factions react with awe or fear.

---

### 4. The New Order (Diplomatic Victory)

**Objective**: Establish a functioning city-wide government with all factions acknowledging your leadership

**Description**: Through diplomacy, economic interdependence, and political maneuvering, convince or coerce all other factions to join a unified city government under your leadership.

**Requirements**:
- Achieve "Allied" status with at least 5 of 7 other factions
- Have active trade agreements with all surviving factions
- Control City Hall (unique location granting diplomatic bonuses)
- Host the "Grand Council" event (requires all factions to attend)
- Pass a vote establishing you as "First Among Equals"

**Diplomatic Power**:
- Gained through trade volume, military strength, cultural influence
- Spent on diplomatic actions and votes
- Economic interdependence increases your influence

**Optimal Culture Paths**:
- New Republic or Syndicalist Union (Governance)
- Merchant Republic (Belief)
- Any Technology path
- Egalitarian or Familial (Social)

**Gameplay Style**:
- Heavy diplomacy and trade
- Balanced military (strong enough to be respected)
- Economic focus
- Careful faction relationship management
- Strategic marriages/alliances

**Endgame**: Grand council scene, dramatic votes, political intrigue, peaceful unification or political dominance.

---

### 5. The Exodus (Alternative Victory)

**Objective**: Abandon the dying city by building and launching a generation ship

**Description**: Conclude that the city is doomed and invest everything in an escape plan - construct a massive generation ship to seek a new world.

**Requirements**:
- Control the Spaceport (unique location, heavily contested)
- Accumulate enormous resources:
  - 10,000 production points invested
  - 5,000 scrap metal
  - 2,000 components
  - 1,000 fuel
- Complete "Generation Ship" wonder project (takes 50 turns)
- Maintain control of Spaceport during entire construction
- Have at least 50 population to crew the ship

**Optimal Culture Paths**:
- Any Governance (though dictatorships can sacrifice more)
- Secular or Materialist (Belief)
- Innovationist or Transhumanist (Technology)
- Meritocratic (Social)

**Gameplay Style**:
- Resource hoarding and production focus
- Defensive warfare (protect the Spaceport)
- Sacrifice population happiness for production
- Must fend off other factions who want to steal/destroy ship
- Trade for missing resources

**Endgame**: Desperate defense of the Spaceport, moral choice (who gets to leave?), dramatic launch sequence, bittersweet ending (you "won" but abandoned everyone else).

**Unique Aspect**: Other factions can see your progress and will react:
- Allied factions may ask to join the exodus
- Rival factions may attack to stop you
- Some factions may try to build their own ship (competition)

---

### 6. Raider King (Alternative Victory)

**Objective**: Become the supreme warlord through fear, plunder, and total dominance

**Description**: Embrace raider culture fully - you don't build a new civilization, you rule the ashes through strength alone.

**Requirements**:
- Adopt "Raider Culture" → "Darwinist Empire" culture path
- Defeat all other factions militarily (eliminate or vassalize)
- Control 40% of city through force
- Accumulate 5,000 plunder points (from looting and raiding)
- Other factions must pay you tribute or be destroyed

**Unique Mechanic - Vassalization**:
- Defeated factions can become vassals instead of being eliminated
- Vassals pay tribute but keep some autonomy
- Must keep vassals weak enough they can't rebel

**Optimal Culture Paths**:
- Warlord State or Tribal (Governance)
- Darwinist Empire or Nihilist (Belief)
- Primitivist or Innovationist (Technology)
- Hierarchical (Social)

**Gameplay Style**:
- Constant warfare
- Raiding and looting focus
- Intimidation and fear tactics
- No need for cultural or research development
- Pure military and combat focus

**Endgame**: Rule through fear, throne built from wreckage, other factions as tributaries or destroyed.

**Risk**: Vassals can rebel if you weaken, coalition warfare against you, isolation.

---

## Victory Condition Design Principles

### 1. Multiple Paths to Each Victory
- Science victory possible through trade OR conquest of research facilities
- Cultural victory possible through soft power OR broadcast dominance
- Diplomatic victory possible through economics OR military respect

### 2. Culture Alignment
Each victory condition aligns with certain culture paths but isn't exclusive:
- Military cultures lean toward Territorial Supremacy
- Democratic cultures lean toward Cultural Ascendancy or New Order
- Technocratic cultures lean toward Technological Singularity
- Raider cultures lean toward Raider King
- But any culture can pursue any victory with different strategies

### 3. Victory Visibility
- All players can see others' progress toward victory
- UI shows "Victory Progress" for each faction
- Creates tension: "The Vault Collective is 75% to science victory!"
- Allows reactive gameplay: "We must stop their research or we lose"

### 4. Victory Interference
Players can actively sabotage others' victory attempts:
- **Science**: Raid research facilities, assassinate scientists
- **Cultural**: Cultural warfare, propaganda, destroy monuments
- **Territorial**: Recapture key locations
- **Diplomatic**: Break alliances, economic sanctions
- **Exodus**: Sabotage construction, siege Spaceport
- **Raider King**: Form defensive coalition

### 5. Point of No Return
Each victory has a "point of no return" where victory becomes very likely but not guaranteed:
- Prevents anti-climactic "I won 50 turns ago but game continues"
- Creates dramatic final pushes
- Allows comeback mechanics if leader stumbles

### 6. Victory Timing
Target victory turns:
- **Fast Game** (100 turns): Raider King, Territorial Supremacy
- **Medium Game** (150 turns): Cultural Ascendancy, New Order
- **Long Game** (200 turns): Technological Singularity, Exodus

Different playstyles have different pacing.

### 7. Moral Weight
Victories have different moral implications:
- **Exodus**: Abandoning the city (morally ambiguous)
- **Raider King**: Ruling through fear (dark ending)
- **Cultural Ascendancy**: Peaceful unity (hopeful ending)
- **New Order**: Democratic cooperation (idealistic ending)
- **Singularity**: Technological transcendence (uncertain ending)
- **Territorial**: Military dominance (pragmatic ending)

Player's choice reflects their values and story.

## Victory Conditions & Replayability

Different cultures pursuing different victories creates massive variety:
- Democratic Territorial Supremacy (peaceful annexation)
- Raider Cultural Victory (cultural conquest through fear)
- Technocratic Exodus (scientists flee doomed world)
- Primitivist New Order (return to simple governance)

Each combination creates unique narratives and strategies.

## Consequences

### Positive
- Six distinct victory paths support diverse playstyles
- Culture system integrates with victory conditions
- Victories are visible and interruptible (creates drama)
- Different victory timings create pacing variety
- Moral weight gives victories narrative significance
- Replayability through victory/culture combinations
- Endgame scenarios are dramatic and distinct

### Negative
- Balancing six victory conditions is complex
  - *Mitigation*: Extensive playtesting, community feedback
- Players might optimize to "easiest" victory
  - *Mitigation*: All victories require similar time investment with different strategies
- AI must pursue victories intelligently
  - *Mitigation*: AI personality determines preferred victory, simple decision trees
- New players might be overwhelmed by options
  - *Mitigation*: Tutorial recommends victory based on starting position

### Technical Implications
- Victory progress tracking for all factions
- UI showing victory progress
- Wonder project system
- Vassalization system (for Raider King)
- Cultural influence spreading mechanics
- Diplomatic power system
- End-game cinematics for each victory

### Design Implications
- Game balance must ensure all victories viable
- Map design must support all victory types (research facilities, cultural sites, Spaceport, etc.)
- Events should interact with victory progress
- Tutorial should explain victory conditions clearly
- Achievements for each victory type
- Ending slides/narrative for each victory

## Victory Condition Interaction Matrix

| Victory Type | How It's Helped By | How It's Hurt By |
|--------------|-------------------|------------------|
| Territorial | Military strength, production | Coalition warfare, overextension |
| Cultural | Happiness, cultural buildings, population | Cultural warfare, monument destruction |
| Science | Research facilities, peaceful development | Facility raids, scientist assassination |
| New Order | Trade, alliances, diplomacy | War declarations, broken treaties |
| Exodus | Resources, production, Spaceport control | Sabotage, resource denial, sieges |
| Raider King | Military strength, fear | Defensive coalitions, vassals rebelling |

## Endings & Narrative

Each victory has unique ending sequence:

### Territorial Supremacy
- Cinematic of flag raised over city center
- Map showing your complete control
- Narrative: "Through strength and strategy, you united the ruins under one banner."
- Other factions: Defeated, absorbed, or fled

### Cultural Ascendancy
- Cinematic of cultural festival in city square
- People of all former factions celebrating together
- Narrative: "Your culture became so compelling that others embraced it willingly."
- Other factions: Culturally integrated, peaceful

### Technological Singularity
- Cinematic of breakthrough moment (depends on chosen path)
- City transforming with new technology
- Narrative: "You transcended the limits of the old world and built something new."
- Other factions: Awed, fearful, or hopeful

### The New Order
- Cinematic of Grand Council meeting
- All faction leaders pledging cooperation
- Narrative: "Through diplomacy and cooperation, you rebuilt civilization itself."
- Other factions: Allied, independent but unified

### The Exodus
- Cinematic of generation ship launching
- Bittersweet music
- Narrative: "You escaped the dying world, but left countless souls behind."
- Other factions: Envious, angry, or building their own ships

### Raider King
- Cinematic of your throne in ruins
- Vassals bringing tribute
- Narrative: "You rule the ashes through fear and strength. The weak serve the strong."
- Other factions: Destroyed or vassalized

## Related Decisions
- ADR-003: Emergent Culture System (culture affects victory paths)
- ADR-002: Unique Resources (resources required for victories)
- ADR-001: Single City Focus (enables specific victory conditions)

## References
- *Civilization* series: Multiple victory condition model
- *Stellaris*: Different endgame crises and victories
- *Frostpunk*: Moral weight of victory conditions
- *Old World*: Ambition system and victory goals

## Date
2025-11-12

## Authors
Design Team
