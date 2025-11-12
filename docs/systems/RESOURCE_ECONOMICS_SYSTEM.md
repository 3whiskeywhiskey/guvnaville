# Resource & Economics System

## Overview
The economy in **Ashes to Empire** is based on controlling unique pre-war infrastructure and managing scarce post-collapse resources. Unlike traditional 4X games where you build identical farms and mines, here you fight for THE hospital, THE power plant, THE factory.

## Resource Categories

### Strategic Resources (Location-Based)
These come from controlling unique locations and cannot be stockpiled - they provide ongoing benefits.

#### Knowledge
- **Source**: Libraries, universities, research labs, data centers
- **Effect**: Research points per turn
- **Importance**: Unlocks technologies, cultural advancements, victory paths

#### Production Capacity
- **Source**: Factories, workshops, manufacturing plants, industrial districts
- **Effect**: Production points per turn
- **Importance**: Build units, buildings, wonders faster

#### Medical Capability
- **Source**: Hospitals, clinics, pharmaceutical labs, medical schools
- **Effect**: Medicine production, population growth rate, reduced mortality
- **Importance**: Population health, growth, veteran unit recovery

#### Agricultural Capacity
- **Source**: Vertical farms, greenhouses, aquaponics facilities, food warehouses
- **Effect**: Food production per turn
- **Importance**: Population sustenance, growth, happiness

#### Energy Generation
- **Source**: Solar arrays, geothermal plants, old reactors, wind farms, hydro dams
- **Effect**: Power points per turn
- **Importance**: Powers advanced buildings, vehicles, industry

#### Cultural Influence
- **Source**: Museums, monuments, broadcast stations, theaters, stadiums
- **Effect**: Culture points per turn, influence spread
- **Importance**: Cultural victory, population happiness, soft power

### Stockpiled Resources (Consumable)
These are collected, stored, and consumed. They accumulate in your stockpile.

#### Scrap Metal
- **Sources**:
  - Scavenging ruins (base 5 per turn)
  - Demolishing buildings
  - Defeating enemy units (loot)
  - Scrapyards (unique locations, +10/turn)
- **Uses**:
  - Build units (10-200 scrap each)
  - Construct buildings (50-500 scrap each)
  - Trade with other factions
  - Upgrade facilities
- **Storage**: Unlimited
- **Importance**: Universal building material, most versatile resource

#### Food
- **Sources**:
  - Agricultural facilities (varies by facility)
  - Scavenging abandoned stores (one-time finds)
  - Hunting/fishing (if you control parks/waterfront)
  - Trade
- **Consumption**:
  - 1 food per pop per turn
  - Armies in field require food supply
- **Storage**: Unlimited but spoils at 5% per turn if over capacity
- **Importance**: Population survival and growth
- **Starvation**: If food reaches 0, population starves (-10% per turn until food restored)

#### Medicine
- **Sources**:
  - Medical facilities (varies)
  - Pharmaceutical warehouses (unique locations)
  - Scavenging hospitals and pharmacies
  - Trade
- **Uses**:
  - Reduce population mortality (-2% death rate per medicine/turn spent)
  - Heal wounded units
  - Cure radiation sickness
  - Build medical units
  - Respond to plague events
- **Storage**: Unlimited
- **Importance**: Population health and growth rate

#### Ammunition
- **Sources**:
  - Armories (unique locations, +20/turn)
  - Ammunition factories (requires components, produces 10/turn)
  - Military bases (unique locations)
  - Scavenging police stations and military sites
  - Trade
- **Uses**:
  - Build military units (10-80 ammo each)
  - Resupply units in combat
  - Required for sustained warfare
- **Storage**: Unlimited
- **Importance**: Military capability - without ammo, can't build most military units

#### Fuel
- **Sources**:
  - Refineries (unique locations, +5/turn if powered)
  - Fuel depots (one-time scavenging finds, 50-200 fuel)
  - Oil wells (extremely rare, +3/turn)
  - Trade (very expensive)
- **Uses**:
  - Power vehicles (2-5 fuel per turn)
  - Emergency power generation (10 fuel = 1 turn of power for city)
  - Build vehicles
  - Some industrial processes
- **Storage**: Unlimited but highly explosive (lose 50% if fuel depot destroyed)
- **Importance**: Enables vehicle warfare, extremely valuable and scarce

#### Components (Advanced Parts)
- **Sources**:
  - Electronics factories (unique locations, +3/turn if powered)
  - Scavenging tech companies, data centers
  - Disassembling advanced pre-war equipment
  - Trade
- **Uses**:
  - Build advanced units (vehicles, specialists)
  - Construct high-tech buildings
  - Research certain technologies
  - Upgrade facilities
- **Storage**: Unlimited
- **Importance**: Gates advanced gameplay, relatively rare

#### Clean Water
- **Sources**:
  - Water treatment plants (unique locations, +50/turn)
  - Wells (if non-irradiated, +10/turn)
  - Rain collection systems (+5/turn)
  - Rivers/lakes (if purified, +20/turn)
- **Consumption**:
  - 2 water per pop per turn
  - Required for agriculture (1 water per food produced)
  - Some industrial processes
- **Storage**: Limited (100 + 50 per water tower built)
- **Importance**: Absolutely critical - more important than food early game
- **Dehydration**: If water reaches 0, population dies at -20% per turn

### Special Resources (Quest/Event Items)

#### Pre-War Data Archives
- Unlock specific technologies immediately
- Found through exploration and events
- One-time use items

#### Artifacts & Relics
- Cultural value, can display in museums (+culture)
- Some have unique effects (ancient power armor, AI cores, etc.)
- Quest objectives for some victory paths

#### Genetic Samples
- Required for bio-technology research
- Found in specific labs and facilities
- Limited quantity

## Production System

### Production Points
Each controlled tile/building generates production points (PP):
- **Workshop**: 5 PP/turn
- **Factory**: 20 PP/turn
- **Industrial District**: 50 PP/turn
- **Civilian populations**: 1 PP per 2 pops (people working)

Production points are spent to build:
- **Units**: 50-800 PP each
- **Buildings**: 100-2000 PP each
- **Wonders**: 5000-20000 PP each
- **Infrastructure**: 50-500 PP each

### Production Queue
- Each settlement has a production queue
- Items built sequentially (first-in-first-out)
- Can rush production with resources (pay 2× scrap cost for instant completion)
- Can cancel production (refund 50% of invested PP)

### Production Modifiers

**Cultural Bonuses**:
- Collectivism: +25% production
- Industrial Focus: +15% production
- Warlord State: Military units -25% cost

**Building Bonuses**:
- Factory: +20 PP/turn base
- Engineer Guild: +15% production city-wide
- Power Grid: +10% production if powered

**Penalties**:
- Unhappy population: -20% production
- No power: -30% production for advanced buildings
- Under siege: -50% production

## Economic Management

### Per-Turn Economy Overview

**Income Phase** (Resources gained):
1. Unique locations provide benefits
2. Pops consume food and water
3. Stockpiled resources accumulate
4. Trade routes deliver goods
5. Scavenging teams bring in finds

**Consumption Phase** (Resources spent):
1. Population consumes food/water
2. Vehicles consume fuel
3. Production spends resources
4. Unit maintenance (if using advanced rules)

**Net Result**: Stockpile updated, alerts for shortages

### Resource Stockpile Display
```
┌─────────────────────────────────────┐
│ RESOURCE STOCKPILE                  │
├─────────────────────────────────────┤
│ Scrap:      450  (+25/turn)         │
│ Food:       200  (-15/turn) ⚠️       │
│ Medicine:    80  (+5/turn)          │
│ Ammunition: 150  (-10/turn)         │
│ Fuel:        20  (-5/turn) ⚠️⚠️      │
│ Components:  30  (+2/turn)          │
│ Water:      180  (-20/turn)         │
├─────────────────────────────────────┤
│ Production: 75 PP/turn              │
│ Research:   12 RP/turn              │
│ Culture:     8 CP/turn              │
└─────────────────────────────────────┘
```
⚠️ = Low stockpile warning
⚠️⚠️ = Critical shortage (will run out in <3 turns)

### Resource Shortages

**Food Shortage**:
- Population starves: -10% per turn
- Happiness: -20
- Unrest increases
- Migration away from your faction

**Water Shortage** (Worse):
- Population dies: -20% per turn
- Immediate crisis
- Cities can fall within 2-3 turns
- Desperation events trigger

**Ammunition Shortage**:
- Can't build most military units
- Units can't resupply after combat
- Combat effectiveness reduced
- Vulnerable to attack

**Fuel Shortage**:
- Vehicles become immobile
- Must abandon or store vehicles
- Can't build new vehicles
- Industrial penalties

**Medicine Shortage**:
- Population mortality increases (+5% per turn)
- Can't heal wounded units
- Plague events become catastrophic
- Population growth stops

## Trade System

### Trade Routes
- Establish trade route between your settlement and another faction
- Requires: Safe path (no hostile territory blocking)
- Each route can trade 1-3 resource types
- Routes can be raided by third parties
- Trade generates income for both parties (+10% bonus to traded goods)

### Trade Agreement Example
```
Trade Agreement: You ↔ The Vault Collective

You Give:     20 Food/turn
You Receive:  15 Medicine/turn

Duration: 20 turns (renewable)
Trade Route Security: 85% (5% chance of raid per turn)
```

### Black Market
- Illegal trading hub (if you control "Black Market" unique location)
- Can buy ANY resource, but at 3× normal price
- Can sell ANY resource for 1.5× normal value
- Attracts criminal element (-1 happiness, +1 scrap income)
- Risky but flexible

### Resource Trading Rates (Standard)
- 1 Medicine = 2 Food
- 1 Ammunition = 2 Scrap
- 1 Component = 5 Scrap
- 1 Fuel = 8 Scrap
- 1 Food = 1 Scrap

These rates fluctuate based on supply/demand.

## Scavenging System

### Scavenging Teams
- Assign pops as "Scavengers" (specialist role)
- Each scavenger can work a ruin tile
- Generates random resources each turn

### Scavenging Yields

**Residential Ruins** (Low Yield):
- 60% chance: 5 scrap
- 25% chance: 10 scrap
- 10% chance: 3 food (canned goods)
- 5% chance: Event trigger (survivor found, booby trap, etc.)

**Commercial Ruins** (Medium Yield):
- 40% chance: 10 scrap
- 30% chance: 5 food
- 20% chance: 5 components
- 10% chance: Artifact/rare item

**Industrial Ruins** (High Yield):
- 50% chance: 20 scrap
- 30% chance: 10 components
- 15% chance: 5 ammunition
- 5% chance: Rare blueprint/technology

**Medical Ruins** (Specialized):
- 40% chance: 10 medicine
- 30% chance: 5 components (medical equipment)
- 20% chance: 10 scrap
- 10% chance: Medical research data

**Military Ruins** (Specialized):
- 50% chance: 20 ammunition
- 25% chance: 10 scrap
- 15% chance: Military equipment (weapons, armor)
- 10% chance: Military intelligence/maps

### Scavenging Depletion
- Each tile has "scavenge value" (0-100)
- Each scavenging attempt reduces value by 5-10
- When value reaches 0, tile is "picked clean" (yields only 1-2 scrap thereafter)
- Encourages expansion to find fresh ruins

### Scavenging Dangers
- 5% chance per scavenge: Hazard encountered
  - **Collapse**: Lose scavenger, gain nothing
  - **Radiation**: Scavenger irradiated (-20 HP, needs medicine)
  - **Feral Creatures**: Combat encounter
  - **Booby Trap**: Lose scavenger
  - **Raider Ambush**: Combat encounter

### Cultural Scavenging Bonuses
- **Preservationist**: +50% scavenging yields, +10% find rare items
- **Raider Culture**: +25% scavenging speed, immune to booby traps
- **Primitivist**: -50% scavenging yields (reject old world goods)

## Population Economics

### Population Growth
```
Population Growth Rate = Base Rate (2%)
  + Food Surplus Bonus (0.5% per 10 food surplus)
  + Medicine Bonus (1% if spending medicine)
  + Happiness Bonus (0-2% based on happiness)
  - Mortality Rate (1-10% based on conditions)
```

**Example**:
- Base: 2%
- Food surplus: 30 (+1.5%)
- Medicine spent: +1%
- Happy population: +2%
- Low mortality: -2%
- **Net Growth: 4.5% per turn**

With 50 pops, that's 2.25 new pops per turn (rounded).

### Pop Assignment
Pops can be assigned to:
- **Unassigned** (Default): Generate 0.5 PP, consume food/water
- **Workers**: Generate 1 PP per pop
- **Scavengers**: Scavenge ruins for resources
- **Soldiers**: Becomes military unit (no longer generates PP)
- **Specialists**: Requires training, generates special bonuses
  - **Scholars**: +2 research per scholar
  - **Artisans**: +1 culture per artisan
  - **Engineers**: +2 production per engineer
  - **Medics**: +1 medicine per medic

### Pop Happiness
Affects productivity and loyalty:
- **Ecstatic** (90+): +20% production, +2% growth, no unrest
- **Happy** (70-89): +10% production, +1% growth
- **Content** (50-69): No bonuses or penalties
- **Unhappy** (30-49): -10% production, -1% growth, minor unrest
- **Miserable** (<30): -30% production, -3% growth, rebellion risk

**Happiness Factors**:
- Food surplus: +10
- Medicine available: +10
- Cultural buildings: +5-20
- Victory/success: +10
- Under attack: -20
- Starvation: -50
- Cultural policies: varies

## Infrastructure Economics

### Road Networks
- Roads connect settlements and resources
- Enable trade routes
- Faster unit movement (+2 movement on roads)
- Cost: 50 PP + 20 scrap per road tile
- Can be destroyed in warfare

### Power Grids
- Connect power sources to cities
- Enable advanced buildings
- Cost: 100 PP + 30 components per grid connection
- Vulnerable to sabotage
- Provides city-wide bonuses when powered

### Fortifications
- Walls, bunkers, watchtowers
- Defensive bonuses
- Cost: 150 PP + 50 scrap per fortification
- Can be sieged and destroyed

## Wonder Projects

### Economic Wonders

**The Forge** (Super Factory)
- Cost: 10,000 PP, 2,000 scrap, 500 components
- Time: 50 turns
- Benefit: +100 PP/turn, can build 2 units simultaneously
- Requirement: Control 3+ industrial sites

**The Bazaar** (Trade Hub)
- Cost: 5,000 PP, 1,000 scrap
- Time: 30 turns
- Benefit: +50% trade income, black market access, -25% resource trading costs
- Requirement: 5+ active trade routes

**The Greenhouse Arcology** (Super Farm)
- Cost: 8,000 PP, 1,500 scrap, 300 components
- Time: 40 turns
- Benefit: +200 food/turn, immune to starvation events, +3% population growth
- Requirement: Control 2+ agricultural sites

**The Promethean Reactor** (Power Plant)
- Cost: 15,000 PP, 3,000 scrap, 1,000 components
- Time: 60 turns
- Benefit: Unlimited power for entire faction, +30% production, enables energy weapons
- Requirement: Technocracy culture, control nuclear plant site

## Economic Victory Strategy

For **Diplomatic Victory** (The New Order):
1. Control trade-critical resources (food, medicine, ammunition)
2. Establish trade routes with all factions
3. Build The Bazaar wonder
4. Use economic leverage for diplomatic influence
5. Become indispensable to all factions

Economic dominance = diplomatic power.

## Economic Balance Philosophy

### Scarcity Creates Conflict
- Not enough food to go around? Fight for farms or trade.
- Only one major power plant? Whoever controls it has advantage.
- Ammunition running low? Can't sustain war.

### Interdependence Encourages Diplomacy
- No one faction can be fully self-sufficient
- Trade is essential, not optional
- Economic alliances are powerful

### Resource Diversity Enables Strategies
- Military strategy: Prioritize ammunition and scrap
- Cultural strategy: Prioritize cultural sites and happiness
- Tech strategy: Prioritize research facilities and components
- All viable with right resource control

## Economic UI & Feedback

### Resource Alert System
- Pop-up when resource drops below 20% capacity
- Warning when consumption exceeds production
- Suggestion to build/capture specific locations
- Trade recommendations

### Economic Advisor
- AI analyzes your economy
- Recommends: "You need more food production - consider attacking The Green Faith's farms or establishing a trade route"
- Identifies inefficiencies
- Suggests optimal pop assignments

### Economic Victory Tracker
For Exodus victory, tracks:
- Current resources vs. required resources
- Estimated turns to completion
- Production rate vs. required rate
- Recommendations to speed up

## Example Economic Scenario

**Turn 45 - Resource Crisis**

You control:
- 1 hospital (+5 medicine/turn)
- 2 factories (+40 PP/turn)
- 1 scrapyard (+10 scrap/turn)
- NO agricultural sites (importing food via trade)

Your stockpile:
- Food: 15 (-30/turn from consumption, +25/turn from trade) = **-5/turn**
- Medicine: 50 (+5/turn)
- Scrap: 200 (+10/turn)
- Ammunition: 80 (-5/turn from military)

**Problem**: Food is running out in 3 turns.

**Options**:
1. **Attack** The Green Faith to capture their vertical farm (military solution)
2. **Trade** medicine for food with The Vault Collective (diplomatic solution)
3. **Rush build** a greenhouse using your scrap reserves (economic solution)
4. **Reduce population** by drafting pops into military (dark solution)

Each choice has consequences:
- Attack: War, but solves food permanently if you win
- Trade: Peaceful, but dependent on them, costs medicine
- Build: Expensive, takes time, but self-sufficient
- Draft: Reduces consumption, but loses economic productivity

**This is the core economic gameplay loop** - managing scarcity through strategic choices.

---

*Economics in Ashes to Empire is about tough choices in a world of scarcity. Every resource matters. Every trade-off has weight. Survival requires strategy.*
