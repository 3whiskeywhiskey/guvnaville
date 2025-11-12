# Game Data Documentation

## Overview

This directory contains all game data for **Ashes to Empire** in JSON format. All data files are validated against JSON schemas to ensure consistency and correctness.

## Directory Structure

```
data/
├── schemas/           # JSON Schema definitions
│   ├── unit_schema.json
│   ├── building_schema.json
│   ├── culture_node_schema.json
│   ├── event_schema.json
│   └── location_schema.json
├── units/            # Unit definitions
│   └── units.json
├── buildings/        # Building definitions
│   └── buildings.json
├── culture/          # Culture tree data
│   └── culture_tree.json
├── events/           # Dynamic events
│   └── events.json
└── world/            # World locations
    └── locations.json
```

## Data Files

### Units (`units/units.json`)
**Count**: 10 unit types

Unit types included:
1. **Militia** - Basic infantry, cheap but weak
2. **Soldier** - Trained fighters, backbone of armies
3. **Scout** - Fast reconnaissance units with extended vision
4. **Engineer** - Support units for repairs and construction
5. **Medic** - Healing specialists that boost morale
6. **Heavy Trooper** - Elite heavily armored units
7. **Sniper** - Precision ranged attackers
8. **Raider** - Aggressive looters with pillaging abilities
9. **Trader** - Economic specialists for trade routes
10. **Tech Specialist** - Technology experts with advanced abilities

**Key Stats**: HP, Attack, Defense, Movement, Cost, Morale, Vision Range
**Features**: Abilities, Prerequisites, Production Time

### Buildings (`buildings/buildings.json`)
**Count**: 10 building types

Building types included:
1. **Shelter** - Basic housing for population
2. **Workshop** - Scrap production and crafting
3. **Hydroponic Farm** - Food production
4. **Medical Clinic** - Healthcare and medicine production
5. **Watchtower** - Defense and vision extension
6. **Trade Market** - Economic hub with culture generation
7. **Barracks** - Military training facility
8. **Research Laboratory** - Culture and technology advancement
9. **Storage Depot** - Resource capacity increase
10. **Defensive Wall** - Strong fortification

**Categories**: Infrastructure, Production, Military, Research, Cultural, Defensive
**Features**: Production bonuses, Effects, Requirements, Maintenance costs

### Culture Tree (`culture/culture_tree.json`)
**Structure**: 4 development axes

#### Military Axis (6 nodes)
- Militia Training → Organized Warfare → (Marksmanship / Heavy Arms) → Combined Arms
- Alternative: Raider Doctrine (mutually exclusive with Organized Warfare)

#### Economic Axis (6 nodes)
- Salvage Operations → (Agricultural Recovery / Trade Networks / Industrial Recycling) → Market Economy → Resource Efficiency

#### Social Axis (6 nodes)
- Community Organizing → (Healthcare / Strongman Rule / Democratic Council / Education) → Cultural Revival
- Mutually exclusive choices between Strongman Rule and Democratic Council

#### Technological Axis (6 nodes)
- Basic Repairs → (Engineering Corps / Scientific Method) → (Old World Knowledge / Power Generation) → Advanced Manufacturing

**Total Culture Nodes**: 24
**Features**: Prerequisites, Stat modifiers, Unit/Building unlocks, Special abilities, Mutually exclusive choices

### Events (`events/events.json`)
**Count**: 20 dynamic events

Event categories:
- **Combat**: Raider attacks, mutant incursions, spy infiltration, border clashes
- **Economic**: Salvage finds, trade opportunities, refugee crises, merchant caravans
- **Social**: Leadership challenges, wanderer arrivals, power struggles, festivals
- **Environmental**: Nuclear winter, solar storms, radiation auroras, disease outbreaks
- **Technological**: Ancient bunkers, old world data, library discoveries
- **Story**: Unique narrative events with long-term consequences

**Rarity Tiers**: Common (7), Uncommon (9), Rare (3), Epic (1)
**Features**: Triggers, Multiple choices, Consequences, Event chains, Requirements

### Locations (`world/locations.json`)
**Count**: 50 unique locations (sample of full 200+ catalog)

#### Location Types Distribution:
- **Military** (8): Bases, bunkers, depots, forts, prisons
- **Industrial** (7): Factories, refineries, plants, rail yards
- **Research** (5): Labs, universities, data centers, observatories
- **Natural** (4): Oases, parks, sanctuaries, preserves
- **Infrastructure** (4): Power plants, water treatment, broadcast stations, bridges
- **Ruins** (6): Cities, suburbs, malls, stadiums, subway tunnels
- **Resource Sites** (5): Mines, quarries, farms, oil refineries
- **Monuments** (4): Iconic landmarks with cultural significance
- **Special** (7): Vaults, anomalies, hospitals, airports, seaports

#### Danger Levels:
- Level 1 (Low): 14 locations
- Level 2 (Moderate): 16 locations
- Level 3 (Medium): 11 locations
- Level 4 (High): 6 locations
- Level 5 (Extreme): 3 locations

**Features**:
- Resource generation (scrap, food, medicine, fuel)
- Special abilities and bonuses
- Defender units
- Capture requirements
- Settlement viability
- Strategic importance

## Resource Types

All game data uses these core resources:
- **Scrap**: Construction material and general currency
- **Food**: Population sustenance
- **Medicine**: Healthcare and population growth
- **Fuel**: Power and advanced operations
- **Culture Points**: Technology/culture advancement

## Validation

All data files validate against their JSON schemas. Run validation with:

```bash
godot --headless --script scripts/validate_data.gd
```

The validation script checks:
- Required fields presence
- Data types correctness
- Value ranges (stats, tiers, costs)
- ID format consistency
- Enum value validity
- Structural integrity

## Design Principles

1. **Balance**: Units and buildings have clear roles and trade-offs
2. **Thematic Consistency**: Post-apocalyptic setting reflected in all content
3. **Strategic Depth**: Multiple viable strategies through culture tree choices
4. **Narrative Integration**: Events and locations tell environmental stories
5. **Scalability**: Data structure supports easy expansion and modding

## Expansion Plans

Future data additions (Phase 4):
- Expand to 20 total unit types
- Expand to 30 total building types
- Complete 200+ unique locations catalog
- Add 50+ additional events
- Add more culture tree branches and synergies

## Modding Support

All game data is in easily editable JSON format:
- Clear schema documentation
- Validation tools included
- Extensible structure for custom content
- No hardcoded game logic

## Credits

**Data Design**: Agent Data (Phase 1, Workstream 1B)
**Date**: 2025-11-12
**Version**: 1.0 (MVP Data Set)
