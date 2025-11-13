# Procedural City Map Generation

## Overview

Guvnaville features a procedural city map generation system that creates unique, coherent urban environments for every playthrough. Each generated city includes diverse districts, infrastructure, unique locations, and hostile encounters, providing significant replay value.

## Key Features

### 1. **Density Gradient System**
Maps feature a realistic density gradient from a high-density downtown core to rural outskirts:
- **Downtown** (90-100% density): Dense commercial and high-rise areas
- **High Density** (70-90%): Mix of commercial and high-rise residential
- **Medium Density** (40-70%): Commercial, medium residential, industrial, parks
- **Low Density** (20-40%): Suburban residential, industrial, parks
- **Rural** (0-20%): Sparse development, mostly open space

### 2. **Multi-Layer Structure**

The map uses a 3-layer system (200x200x3 tiles):

#### Ground Level (z=1)
- Primary gameplay layer
- Buildings, streets, parks
- Most units and combat occurs here

#### Underground Level (z=0)
- Subway lines connecting downtown to outskirts
- Utility tunnel networks
- Alternative travel routes
- Strategic value for factions with appropriate technology

#### Elevated Level (z=2)
- Rooftops of tall buildings in high-density areas
- Bridges connecting adjacent tall buildings
- Superior vision and defensive positions
- Safer supply routes in dangerous downtown areas
- Requires investment to build bridge networks

### 3. **District Types**

Maps are divided into several zone types:

- **Downtown**: Central high-rise district
- **Commercial**: Shopping, offices, services
- **Residential (Low/Medium/High)**: Housing of varying densities
- **Industrial (Generic)**: Standard factories and warehouses
- **Industrial (Specialized)**: Unique industrial facilities (see below)
- **Parks**: Green spaces and recreation areas

### 4. **Coherent Road Network**

Roads are generated using a multi-tier system:
- **Major Roads**: Grid pattern every ~20 tiles, creating city blocks
- **Minor Roads**: Connecting roads within blocks
- **Downtown Loops**: Circular roads around the city center
- All roads avoid terrain features like rivers and beaches

### 5. **Unique Features**

Not every map has all features, creating replay value. Features are placed probabilistically:

#### Transport Hubs
- **Airport** (60% chance): Aviation fuel, parts, enables air travel
- **Seaport** (40% chance): Maritime trade, requires water adjacency
- **Train Station** (80% chance): Rail access, locomotive parts

#### Specialized Industry
- **Steelworks** (50% chance): Steel production, heavy weapons tech
- **Automotive Plant** (50% chance): Vehicle manufacturing, armored cars
- **Chemical Plant** (40% chance): Chemicals, pharmaceuticals, weapons
- **Power Plant** (70% chance): Electricity generation, power restoration

#### Cultural & Media
- **Museum** (60% chance): Historical knowledge, cultural preservation
- **TV Station** (50% chance): Broadcasting, propaganda, surveillance
- **Radio Station** (60% chance): Communications, emergency broadcasts
- **Newspaper Printer** (50% chance): Printed media, literacy programs

#### Civic Buildings
- **University** (60% chance): Research, specialized training
- **Hospital** (70% chance): Medical supplies, advanced medicine
- **Sports Stadium** (50% chance): Mass gatherings, fortified base potential

### 6. **Terrain Features**

#### Rivers (40% chance)
- Meander across the map from one edge to another
- Width: 2-4 tiles
- Alternative travel for factions with boats
- Strategic crossing points

#### Beaches (30% chance)
- Located along map edges
- Length: 33-66% of edge
- Width: 3-6 tiles
- Naval access points

### 7. **Hostile Units**

Maps are populated with hostile units that pose early-game threats but don't respawn:

- **Raider Gangs** (~15 groups): 3-8 units each, medium-density areas
- **Rogue Robots** (~10 groups): 1-4 units each, industrial/downtown areas

These create initial challenges and scavenging opportunities but can be cleared permanently.

## Resource System

Each unique feature provides exclusive resources that shape faction development:

### Technology Enablers
Unique features unlock technology trees:
- Airport → Air travel, reconnaissance
- Seaport → Naval operations, fishing
- Steelworks → Advanced metallurgy, armored vehicles
- University → Advanced research, innovation culture
- Hospital → Advanced medicine, surgery

### Cultural Impact
Features influence faction culture:
- Museums → Educated, traditional values
- Media Buildings → Media-savvy, influential
- Sports Stadium → Athletic, communal
- University → Scientific, progressive

See `/data/world/unique_features.json` for complete resource definitions.

## Generation Algorithm

### Phase 1: Terrain Features
1. Generate river (if rolled)
2. Generate beach (if rolled)

### Phase 2: District Generation
1. Calculate density based on distance from downtown center
2. Apply noise for organic variation
3. Assign zone types based on density and noise

### Phase 3: Road Network
1. Generate major road grid
2. Fill blocks with minor roads
3. Add circular downtown loops
4. Avoid terrain features

### Phase 4: Building Placement
1. Place buildings within zones
2. Respect roads and terrain features
3. Set tile types and properties

### Phase 5: Unique Locations
1. Roll for each unique feature
2. Find suitable placement (feature-dependent)
3. Verify space availability
4. Mark tiles as unique locations

### Phase 6: Underground Layer
1. Generate subway lines (typically 3)
2. Connect downtown to outskirts
3. Generate utility tunnel networks
4. Create tunnel tiles

### Phase 7: Elevated Layer
1. Place tall buildings in high-density areas
2. Generate bridges between adjacent buildings
3. Create rooftop tiles

### Phase 8: Hostile Spawns
1. Place raider gangs in medium-density areas
2. Place rogue robots in industrial areas
3. Ensure minimum spacing between spawns

## Configuration

Map generation is highly configurable via `GenerationConfig`:

```gdscript
var config = GenerationConfig.new(seed_value)
config.downtown_radius = 30.0
config.max_density_distance = 100.0
config.major_road_spacing = 20
config.subway_lines = 3
config.raider_gang_count = 15
config.rogue_robot_count = 10
# ... and many more parameters
```

## Implementation

### Core Files
- `/systems/map/map_generator.gd`: Main generator class
- `/systems/map/map_data.gd`: Map storage and queries
- `/systems/map/tile.gd`: Individual tile data
- `/data/world/unique_features.json`: Feature definitions

### Integration Points
- `IntegrationCoordinator._initialize_map_system()`: Called on game start
- `GameManager.start_new_game()`: Provides seed and settings

### Usage Example

```gdscript
var generator = MapGenerator.new()
var map_data = generator.generate_city_map(200, 200, seed_value)
```

## Balancing Considerations

### Early Game
- Hostile units provide initial challenge
- Scavenging yields resources from ruins
- Basic buildings available without special resources

### Mid Game
- Controlling unique features unlocks new technologies
- Underground/elevated layers become relevant
- Faction territories expand

### Late Game
- Bridge networks create safe elevated routes
- Control of multiple unique features provides advantages
- Map knowledge becomes strategic asset

## Future Enhancements

Potential improvements to the generation system:

1. **Procedural Building Interiors**: Generate explorable building layouts
2. **Faction Starting Positions**: Intelligent placement based on faction type
3. **Dynamic Weather Zones**: Regional weather patterns
4. **Historical Events**: Remnants of pre-collapse events affecting map
5. **Map Themes**: Variations (industrial city, resort town, tech hub)
6. **Vertical Expansion**: More layers (deep underground, skyscrapers)
7. **Dynamic Destruction**: Buildings can be destroyed and rebuilt

## Performance

Generation is optimized for the 200x200x3 grid (120,000 tiles):
- Single-threaded generation completes in < 1 second
- Minimal memory overhead
- Results cached in MapData structure
- Spatial queries optimized with flat array

## Debugging

Enable debug output in MapGenerator:
```gdscript
print("MapGenerator: Starting city generation with seed ", seed_value)
```

Useful debugging commands:
- Check unique features: `map_data.unique_locations`
- Check hostile spawns: `map_data.hostile_spawns`
- Visualize zones: Export `map_data.zones` to image
- Verify roads: Count tiles with `TileType.STREET`

## References

- **Design Document**: `/docs/DESIGN.md`
- **Map System Architecture**: `/systems/map/README.md`
- **Unique Features**: `/data/world/unique_features.json`
- **Integration Guide**: `/docs/INTEGRATION.md`
