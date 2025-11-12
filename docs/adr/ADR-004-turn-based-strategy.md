# ADR-004: Turn-Based vs. Real-Time Strategy

## Status
**Accepted**

## Context
Strategy games use either turn-based (Civilization, XCOM) or real-time (StarCraft, Age of Empires) systems. Some use hybrid approaches (Paradox games' real-time with pause). We must decide which model best serves our post-apocalyptic city 4X design.

### Options Considered

#### Option A: Real-Time Strategy (RTS)
- Continuous gameplay without turns
- Emphasis on fast decision-making and multitasking
- Common in traditional strategy games
- Action-oriented, tests player reflexes

#### Option B: Real-Time with Pause
- Real-time but can pause to issue orders
- Combines planning with continuous action
- Used by Paradox grand strategy games
- Reduces pressure while maintaining flow

#### Option C: Turn-Based Strategy (Chosen)
- Players alternate turns, each making decisions before resolving
- Emphasis on planning and strategic thinking
- Common in 4X and tactical games
- Thoughtful, low-pressure gameplay

## Decision
**We will use turn-based strategy with simultaneous resolution (all factions plan, then all resolve).**

## Rationale

### Cognitive Complexity Management
Our game has high systemic complexity:
- Unique resource locations to evaluate
- Culture tree decisions with long-term consequences
- Tactical urban combat on multi-level terrain
- Diplomatic relations with 8 factions
- Economic management (production, resources, population)
- Event chains with meaningful choices

**Turn-based gameplay allows players to process this complexity** without real-time pressure. Each decision can be thoughtful rather than reactive.

### Strategic Depth Over Reflexes
Post-apocalyptic city rebuilding is about:
- "Which district should I expand into?"
- "Should I trade medicine for ammunition?"
- "Can I afford to war with the Vault Collective?"
- "How do I navigate this moral dilemma?"

These are **strategic questions**, not reflex tests. Turn-based gameplay emphasizes strategy over APM (actions per minute), aligning with our design goals.

### Tactical Combat Integration
Urban combat features:
- Building-to-building tactical positioning
- Verticality (underground/ground/elevated)
- Ambush mechanics and siege warfare
- Environmental hazards and destructible terrain

Turn-based combat allows players to:
- Carefully position units for maximum advantage
- Plan multi-turn tactical operations
- React to enemy movements thoughtfully
- Appreciate tactical nuance without time pressure

Games like *Into the Breach* and *XCOM* demonstrate how turn-based systems create deep tactical gameplay.

### Respect for Player Time
Turn-based allows:
- **Save anywhere, anytime**: Stop mid-turn without penalty
- **Think at your own pace**: No forced reaction time
- **Accessibility**: Players with slower reaction times aren't disadvantaged
- **Async multiplayer potential**: Players can take turns asynchronously

For a complex game requiring significant cognitive load, respecting player time and pace is critical.

### Event & Narrative Integration
Our game features:
- Rich event chains with meaningful choices
- Moral dilemmas affecting faction culture
- Discovery of pre-war secrets and lore
- Character-driven narratives

Turn-based gameplay allows:
- Events to pause the game for consideration
- Players to read and appreciate writing
- Complex multi-option choices without time pressure
- Narrative moments to land with impact

Real-time games struggle with narrative pacing (must pause constantly or players ignore story).

### AI Development Feasibility
Turn-based AI is:
- Easier to develop and debug
- Can "think" during player turn without slowdown
- Doesn't need real-time pathfinding and collision
- Can make complex evaluations without performance constraints

For a small development team, turn-based AI is significantly more achievable than competent RTS AI.

### Genre Expectations
4X games are traditionally turn-based:
- Civilization series
- Old World
- Gladius - Relics of War
- Age of Wonders series

Players expecting a 4X game expect turn-based gameplay. RTS would be genre-breaking (not inherently bad, but mismatched with our goals).

### Simultaneous Resolution
We use **simultaneous turns** rather than alternating:
- All factions plan their turn simultaneously
- All actions resolve at once
- Prevents "first player advantage"
- Creates tension: "What will my opponents do?"
- Faster multiplayer (no waiting for each faction)

Similar to *Diplomacy* board game or *Neptune's Pride*.

### Turn Structure

#### Planning Phase
Players can:
- Move units (movement orders given, not executed yet)
- Queue production
- Make diplomatic offers
- Toggle policies
- Spend culture points
- Scout and explore
- Plan attacks

#### Resolution Phase
All actions resolve simultaneously:
1. **Diplomacy**: Trade and agreements finalized
2. **Movement**: All units move simultaneously
3. **Combat**: All battles resolve
4. **Production**: All cities produce
5. **Events**: Random and scripted events trigger
6. **Economy**: Resources collected, population grows
7. **Culture**: Culture points accumulated

#### Reaction Phase
After resolution, players see:
- Combat results
- Enemy movements (if visible)
- Events requiring response
- New information from scouting

Then next turn begins.

### Turn Length

#### Early Game: Quick Turns
- Turns 1-50: Representing days
- Focus on immediate survival
- Rapid decision-making
- Limited scope

#### Mid Game: Weekly Turns
- Turns 51-150: Representing weeks
- Established factions
- Medium-term planning
- Resource accumulation

#### Late Game: Monthly Turns
- Turns 151+: Representing months
- Grand strategy
- Long-term projects
- Victory condition pushes

**Alternative**: Fixed turn length (each turn = 1 week), ~200 turn campaigns

## Consequences

### Positive
- Players can handle complex strategic decisions thoughtfully
- Tactical combat has depth and nuance
- Narrative and events can be appreciated
- Accessible to players of all skill levels
- AI development is feasible
- Save anywhere functionality
- Async multiplayer potential
- Aligns with 4X genre expectations
- "Every decision matters" is possible when decisions are deliberate

### Negative
- Less "excitement" than real-time action
  - *Mitigation*: Dramatic events, tense combat, compelling narrative
- Potential for slow pacing if turns drag
  - *Mitigation*: Clear turn structure, time limits in multiplayer
- Some players prefer real-time strategy
  - *Mitigation*: Genre is clearly communicated, we target 4X audience
- Simultaneous resolution can be confusing for new players
  - *Mitigation*: Tutorial, combat prediction UI, clear feedback

### Technical Implications
- Turn-based engine architecture
- Simultaneous resolution system
- Clear phase delineation in UI
- Prediction systems (show expected combat outcomes)
- Replay system (show what happened during resolution)
- AI processes during player turn
- Multiplayer turn timer system

### Design Implications
- Balance isn't dependent on player reflexes
- Can have high complexity without overwhelming players
- Events can be deep and meaningful
- Tutorial can be thorough without pacing issues
- Combat can be tactically rich
- Need to prevent "optimal turn" tedium through variety
- Turn structure must be clear and consistent

## Turn Optimization

### Preventing Tedium

#### Late Game Turn Bloat
Problem: Managing many units and cities becomes tedious.

Solutions:
- **Automation Options**: Auto-explore scouts, auto-defend units
- **Stacking**: Multiple similar units can stack and move together
- **Templates**: Save production queues and policies
- **Governors**: Assign AI control of specific districts

#### Empty Turns
Problem: Sometimes nothing meaningful to do.

Solutions:
- **Events**: Regular random and scripted events keep turns interesting
- **Auto-End Turn**: If no actions available, turn auto-ends
- **Turn Summary**: Show what changed (enemy movements, completed production)

#### Turn Timer (Multiplayer)
- 90 seconds per turn (adjustable)
- Extra time bank for complex turns (10 minutes total)
- Async mode: 24-hour turn timer

## Combat Resolution

### Tactical Battles
When combat occurs:
- Enters tactical combat screen
- Turn-based tactical combat (like XCOM)
- Terrain and positioning matter
- Can retreat from combat (if escape route available)
- Results affect strategic map

### Quick Resolution
For minor battles or player choice:
- Auto-resolve option based on unit stats
- Show predicted outcome before committing
- Good for clearing up minor skirmishes

## Related Decisions
- ADR-003: Emergent Culture System (complex decisions need turn-based)
- ADR-005: Tile Granularity (tactical gameplay suits turn-based)
- ADR-007: Combat System Design (TBD)

## References
- *Civilization* series: Gold standard of turn-based 4X
- *Into the Breach*: Perfect turn-based tactical combat
- *XCOM* series: Tactical depth with turn-based systems
- *Old World*: Modern turn-based 4X innovations
- *Neptune's Pride*: Simultaneous resolution in strategy games

## Date
2025-11-12

## Authors
Design Team
