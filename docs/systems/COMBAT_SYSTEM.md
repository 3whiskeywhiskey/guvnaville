# Combat System

## Overview
Combat in **Ashes to Empire** combines strategic army positioning with tactical turn-based battles. Urban warfare at street and building scale creates unique tactical challenges where terrain, verticality, and environmental hazards are as important as unit strength.

## Combat Initiation

### When Combat Occurs
- Unit moves into tile occupied by enemy unit
- Unit attacks adjacent enemy unit
- Enemy unit enters your controlled zone of control (ZoC)
- Siege warfare (surrounding enemy position)

### Combat Resolution Options

#### Auto-Resolve
- System calculates outcome based on unit stats, terrain, and modifiers
- Shows predicted outcome before committing
- Fast resolution for minor skirmishes
- Some randomness (±15% variance)
- No player input during battle

#### Tactical Battle
- Enters tactical combat screen
- Full turn-based tactical control
- Terrain and positioning matter
- Can retreat if escape route exists
- Takes more time but offers more control

**Player Choice**: Game asks which mode for each battle. Can set "always auto-resolve weak enemies" in settings.

## Unit Attributes

### Core Stats

**Hit Points (HP)**
- Represents unit health
- Infantry: 50-100 HP
- Vehicles: 150-300 HP
- Special units: Varies
- At 0 HP, unit is destroyed

**Attack**
- Base damage dealt to enemies
- Modified by terrain, elevation, range
- Example: Soldiers = 20 attack

**Defense**
- Damage reduction
- Modified by cover, armor, culture
- Example: Heavy Infantry = 15 defense

**Range**
- Attack distance in tiles
- Melee: 1 tile
- Rifles: 3 tiles
- Snipers: 6 tiles
- Vehicles: Varies

**Movement**
- Tiles moved per turn
- Militia: 3 movement
- Soldiers: 4 movement
- Scouts: 6 movement
- Vehicles: 8 movement (on roads)
- Reduced by difficult terrain

**Morale**
- Unit effectiveness and retreat threshold
- 0-100 scale
- Below 30: Unit may retreat
- Affected by: casualties, leadership, culture, situation
- Restored by: rest, victory, propaganda

### Special Attributes

**Armor**
- Reduces all damage by percentage
- Heavy Infantry: 25% armor
- Vehicles: 40-60% armor
- Negated by armor-piercing weapons

**Stealth**
- Harder to detect
- Scouts: +2 stealth
- Underground units: +5 stealth
- Can ambush from stealth

**Detection**
- Ability to spot stealthed units
- Snipers: +3 detection
- Watchtowers: +5 detection
- Counters enemy stealth

**Special Abilities**
- Unit-specific powers
- Engineers: Build fortifications, demolish buildings
- Medics: Heal adjacent units
- Snipers: Overwatch (attack moving enemies)
- Scouts: Reveal large area
- Culture-specific abilities

## Unit Types

### Basic Infantry

**Militia**
- Cost: 50 production, 10 scrap
- HP: 50 | Attack: 12 | Defense: 5 | Range: 1 | Movement: 3
- Cheap defenders, weak in offense
- Available from start
- Garrison bonus: +5 defense in controlled buildings

**Scavengers**
- Cost: 75 production, 15 scrap
- HP: 60 | Attack: 15 | Defense: 6 | Range: 2 | Movement: 5
- Fast, lightly armed
- Special: +50% loot from defeated enemies, +2 stealth
- Good for raiding and scouting

**Raiders**
- Cost: 100 production, 20 scrap, 10 ammo
- HP: 70 | Attack: 18 | Defense: 8 | Range: 2 | Movement: 5
- Offensive infantry
- Special: +25% attack vs civilians, intimidation aura (-1 enemy morale in 2 tiles)
- Requires "Raider Culture" or similar

**Soldiers**
- Cost: 150 production, 30 scrap, 20 ammo
- HP: 80 | Attack: 20 | Defense: 10 | Range: 3 | Movement: 4
- Professional balanced military
- Special: +3 morale, can entrench (+5 defense, -2 movement)
- Requires military training facility

**Heavy Infantry**
- Cost: 250 production, 50 scrap, 30 ammo, 10 components
- HP: 100 | Attack: 25 | Defense: 15 | Range: 2 | Movement: 3
- Armor: 25%
- Slow but powerful
- Special: Can breach fortifications
- Requires advanced military facility

### Specialist Infantry

**Snipers**
- Cost: 200 production, 40 scrap, 40 ammo
- HP: 50 | Attack: 30 | Defense: 6 | Range: 6 | Movement: 4
- Detection: +3
- Special: Overwatch (shoot at moving enemies), +50% attack from elevated positions
- Requires marksman training

**Engineers**
- Cost: 175 production, 45 scrap, 15 components
- HP: 60 | Attack: 10 | Defense: 8 | Range: 1 | Movement: 3
- Special: Build fortifications (3 turns), demolish buildings (5 turns), repair vehicles
- Non-combat support unit

**Medics**
- Cost: 150 production, 30 scrap, 20 medicine
- HP: 50 | Attack: 8 | Defense: 8 | Range: 1 | Movement: 4
- Special: Heal adjacent units (+20 HP/turn), prevent casualties (-50% death rate)
- Critical support unit

**Scouts**
- Cost: 100 production, 20 scrap
- HP: 55 | Attack: 14 | Defense: 7 | Range: 2 | Movement: 6
- Stealth: +2 | Detection: +2
- Special: Reveal 5-tile radius, can move after attacking
- Information warfare unit

### Vehicles (Rare, Fuel-Dependent)

**Motorcycles**
- Cost: 200 production, 50 scrap, 30 components, 20 fuel
- HP: 80 | Attack: 16 | Defense: 8 | Range: 2 | Movement: 10
- Fast raiding unit
- Special: Can disengage without penalty
- Fuel consumption: 2 per turn
- Ground level only

**Armored Cars**
- Cost: 400 production, 100 scrap, 60 components, 40 fuel
- HP: 180 | Attack: 28 | Defense: 20 | Range: 4 | Movement: 8
- Armor: 40%
- Mobile firepower
- Fuel consumption: 3 per turn
- Ground level only, roads preferred

**Tanks** (Extremely Rare)
- Cost: 800 production, 200 scrap, 150 components, 80 fuel
- HP: 300 | Attack: 45 | Defense: 30 | Range: 5 | Movement: 6
- Armor: 60%
- Devastating but expensive
- Fuel consumption: 5 per turn
- Requires tank factory (unique location)
- Can demolish buildings
- Ground level only

### Culture-Specific Units

**Technocracy: Cybernetic Soldiers**
- Enhanced soldiers with implants
- +20% all stats, immunity to morale loss
- Requires Transhumanist culture

**Raider Culture: Berserkers**
- Fanatical melee fighters
- Massive attack bonus, weak defense, fearless
- +100% attack when charging, no retreat

**Primitivist: Guerrilla Fighters**
- Master of ambush and terrain
- +50% attack from stealth, +3 stealth
- Reduced cost

**Preservationist: Archaeo-Tech Guardians**
- Equipped with restored pre-war gear
- Powered armor, energy weapons
- Very expensive, very powerful

**Democratic: People's Militia**
- Highly motivated citizen defenders
- Weak in offense, strong in defense (+10 defense in own territory)
- Very cheap

## Tactical Combat

### Battle Map
- 20x20 tile tactical map (subset of strategic map)
- Preserves terrain from strategic map (buildings, streets, elevation)
- Both sides deploy units on opposite edges
- Objective: Defeat enemy or hold position

### Turn Order
- Initiative: Based on unit movement stat + random roll
- Highest initiative acts first
- Alternating activations (1 unit per side)
- When all units acted, new round begins

### Actions Per Turn
Each unit can perform **TWO** actions from:
- **Move**: Move up to movement range
- **Attack**: Attack enemy in range
- **Overwatch**: Defensive stance, shoot at moving enemies (ends turn)
- **Hunker Down**: +10 defense until next turn (ends turn)
- **Use Ability**: Special unit ability (varies)
- **Reload**: Restore ammunition for next attack
- **Climb/Descend**: Change vertical level (costs both actions)

**Combined Actions**: Can move + attack, or attack + move (if range allows)

### Combat Resolution Formula

```
Attacker's Effective Attack = Base Attack × Terrain Modifier × Elevation Modifier × Cultural Bonuses

Defender's Effective Defense = Base Defense + Cover Bonus + Armor + Cultural Bonuses

Damage Dealt = Attacker's Effective Attack - Defender's Effective Defense

Damage Dealt = Max(Damage Dealt, 5)  // Minimum 5 damage
Damage Dealt = Damage Dealt × Random(0.85, 1.15)  // ±15% variance

Defender HP = Defender HP - Damage Dealt
```

### Terrain Modifiers

**Cover Bonus**
- No cover: +0 defense
- Light cover (rubble, cars): +5 defense
- Heavy cover (buildings, walls): +10 defense
- Fortifications: +15 defense

**Elevation Bonus**
- Attacker higher than defender: +25% attack
- Attacker lower than defender: -15% attack
- Same elevation: No modifier

**Environmental Hazards**
- **Radiation Zone**: -5 HP per turn to all units without protection
- **Rubble/Debris**: -2 movement cost, can collapse (5% chance per unit)
- **Fire**: -10 HP per turn, spreads to adjacent tiles
- **Flooding**: -3 movement, drowning risk for prone units
- **Darkness**: -2 attack for all units (benefits stealth)

### Urban Combat Mechanics

**Building Occupation**
- Units inside buildings gain +10 defense (heavy cover)
- Can shoot from windows (no penalty)
- Vulnerable to building collapse
- Can set up ambushes

**Breaching**
- Heavy infantry or engineers can breach fortified buildings
- Takes 1 turn, creates opening
- Defenders inside can shoot at breaching unit

**Building Collapse**
- Buildings damaged by combat can collapse
- Chance based on damage dealt to building
- Collapses kill/wound units inside
- Creates rubble (light cover, difficult terrain)

**Flanking**
- Attacking enemy from side or rear: +15% attack
- Underground units can emerge behind enemy lines
- Scouts can spot flanking opportunities

**Siege Mechanics**
- Surrounding enemy position (4+ adjacent tiles controlled)
- Besieged units: -10 HP per turn (starvation/attrition)
- Besieged units have -3 morale per turn
- Can break siege by attacking or being relieved

**Suppression**
- Units with multi-turn attacks can suppress enemies
- Suppressed units: -5 attack, -2 movement
- Prevents enemy from moving freely

### Morale & Retreat

**Morale Checks**
Units check morale when:
- Losing 50% HP
- Friendly unit destroyed nearby
- Outnumbered 3:1
- Leader unit destroyed

**Morale Effects**
- High morale (80+): +10% attack
- Normal morale (30-79): No effect
- Low morale (10-29): -10% attack, may retreat
- Broken morale (<10): Unit retreats immediately

**Retreat**
- Unit flees toward friendly territory
- Takes opportunity attacks (free attacks from enemies)
- Can rally if reaches safety
- Some cultures never retreat (Berserkers, etc.)

### Victory Conditions

**Tactical Victory**
- Destroy all enemy units
- Reduce enemy morale to 0 (mass retreat)
- Hold objective for 5 turns (scenario-specific)

**Strategic Consequences**
- Victory: Gain control of tile, loot resources, +morale
- Defeat: Lose units, lose tile control, -morale
- Pyrrhic Victory: Won but heavy casualties, -morale

## Strategic Combat (Auto-Resolve)

### Calculation
```
Attacker Strength = Sum of (Unit Attack × HP Percentage × Terrain Modifier)
Defender Strength = Sum of (Unit Defense × HP Percentage × Terrain Modifier × Fortification Bonus)

If Attacker Strength > Defender Strength × 1.5:
  Attacker decisive victory (defender heavy casualties)
Else If Attacker Strength > Defender Strength:
  Attacker victory (mutual casualties)
Else If Attacker Strength ≈ Defender Strength:
  Stalemate (both sides take casualties, no winner)
Else If Defender Strength > Attacker Strength:
  Defender victory (attacker retreats)
Else:
  Defender decisive victory (attacker routed)
```

### Casualties
Based on strength ratio:
- Decisive victory: Winner loses 10% HP, loser loses 60-80% HP
- Victory: Winner loses 25% HP, loser loses 50% HP
- Stalemate: Both lose 30% HP

### Loot
- Winner loots defeated units: +scrap, +ammunition, +equipment
- Scavenger units: +50% loot
- Raider culture: +25% loot

## Special Combat Scenarios

### Ambush
- Stealthed units attacking revealed enemies
- +50% attack on first strike
- Enemy can't retaliate first turn
- Good for scouts and raiders

### Night Combat
- Occurs if battle happens during night phase (optional rule)
- All units: -2 attack
- Stealth units: +3 stealth
- Flares can illuminate areas

### Underground Combat
- Battles in tunnels and sewers
- No elevation bonuses
- Limited sightlines (2-3 tiles)
- Claustrophobic, brutal
- Engineers can collapse tunnels

### Building Defense
- Defender in multi-story building
- Each floor must be cleared
- Vertical combat (attacker climbs, defender shoots down)
- Can retreat to higher floors
- Can collapse building (last resort)

### Vehicle Combat
- Vehicles powerful vs. infantry in open terrain
- Vulnerable in urban areas (ambushes, molotovs)
- Can't enter buildings
- Can demolish obstacles
- Fuel limits operational range

## Combat-Related Systems

### Unit Experience
Units gain XP from combat:
- Kill enemy unit: +50 XP
- Survive battle: +10 XP
- Victory: +20 XP

**Promotion Thresholds**:
- Veteran (100 XP): +10% attack, +10% defense
- Elite (250 XP): +20% attack, +20% defense, +1 ability
- Legendary (500 XP): +30% attack, +30% defense, +2 abilities

### Supply Lines
- Units away from friendly territory need supply
- Supply provided by roads to friendly cities
- Unsupplied units: -5 HP per turn, -2 attack
- Raider culture ignores supply (lives off the land/loot)
- Engineers can build supply depots

### Fortifications
- Engineers can build:
  - **Barricades** (1 turn): +5 defense
  - **Bunkers** (3 turns): +10 defense, protects from ranged
  - **Minefields** (2 turns): Damages attackers
  - **Watchtowers** (3 turns): +5 detection, extended vision

### Fog of War
- Can only see tiles within unit vision range
- Buildings and terrain block line of sight
- Enemy units outside vision are hidden
- Scouts and watchtowers extend vision
- Some cultures have enhanced/reduced vision

### Collateral Damage
- Combat destroys buildings and infrastructure
- Heavy combat: 10-30% chance to destroy tile
- Tanks and explosives: Higher destruction chance
- Destroyed tiles lose bonuses
- Can rebuild but costs resources

## Cultural Combat Bonuses

### Military Dictatorship
- All units: +15% attack, +1 morale
- Faster unit production: -25% cost

### Raider Culture
- All units: +25% loot, intimidation aura
- Berserker units unlocked

### Technocracy
- Cybernetic units unlocked
- +10% defense (advanced armor)

### Primitivist
- Guerrilla fighters unlocked
- +2 stealth all units in natural terrain

### Democratic
- People's militia unlocked
- +10% defense in own territory (fighting for freedom)

### Collectivism
- +25% unit production (mass mobilization)
- Units fight harder together (+5% attack when adjacent to allies)

## Combat UI Elements

### Strategic Map
- Unit icons show type and HP
- Movement paths projected
- Enemy threat range highlighted
- Combat strength comparison shown before attacking

### Tactical Map
- Clear vision of all units
- Movement range highlighted
- Attack range shown
- Cover indicators
- Elevation markers
- Environmental hazards visible
- Turn order display

### Combat Log
- All combat events recorded
- Can review post-battle
- Shows damage dealt/taken
- Identifies kill shots

## Balance Considerations

### Rock-Paper-Scissors
- Infantry > Snipers (close range)
- Snipers > Vehicles (precision shots)
- Vehicles > Infantry (firepower)
- Engineers > Fortifications
- Scouts > Stealth

### Cost-Effectiveness
- Militia: Cheap garrison
- Soldiers: Balanced workhorse
- Heavy Infantry: Breakthrough power
- Vehicles: Shock and awe (if you can fuel them)
- Specialists: Support force multipliers

### Terrain Dependence
- Open areas: Vehicles dominate
- Urban dense areas: Infantry excels
- Elevated positions: Snipers rule
- Underground: Scouts and light infantry

## Example Combat Scenario

**Situation**: Player attacks enemy-controlled hospital (unique location)

**Forces**:
- Attacker: 3 Soldiers, 1 Sniper, 1 Medic
- Defender: 2 Militia, 2 Soldiers (entrenched in hospital building)

**Tactical Battle**:
1. Sniper takes elevated position on nearby building
2. Sniper shoots at defenders in windows
3. Soldiers advance using rubble as cover
4. Defenders shoot from hospital (heavy cover bonus)
5. Medic heals wounded soldiers
6. Soldiers breach hospital ground floor
7. Brutal room-to-room combat
8. Defenders retreat to second floor
9. Attacker clears second floor
10. Victory: Hospital captured

**Outcome**:
- Attacker: 1 soldier killed, others wounded (60% HP avg)
- Defender: 1 militia killed, rest retreated
- Hospital damaged but functional
- Player gains control of hospital (+medicine production)

---

*This combat system emphasizes tactical thinking, terrain usage, and meaningful choices while maintaining the gritty, desperate feel of post-apocalyptic warfare.*
