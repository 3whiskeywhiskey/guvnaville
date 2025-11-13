#!/usr/bin/env python3
import json

# Load existing buildings
with open('/home/user/guvnaville/data/buildings/buildings.json', 'r') as f:
    data = json.load(f)

# New buildings to add
new_buildings = [
    {
        "id": "training_grounds",
        "name": "Training Facility",
        "type": "military",
        "cost": {"scrap": 120, "fuel": 40},
        "production": {},
        "effects": {"unit_production_bonus": 0.2},
        "description": "Dedicated facility for military training. Produces better soldiers faster.",
        "construction_time": 3,
        "requirements": {"buildings": ["barracks"]},
        "tags": ["military", "training"]
    },
    {
        "id": "garage",
        "name": "Vehicle Garage",
        "type": "production",
        "cost": {"scrap": 150, "fuel": 60},
        "production": {},
        "effects": {},
        "description": "Repair and maintain vehicles. Required for mechanized units.",
        "construction_time": 4,
        "requirements": {"culture_nodes": ["vehicle_warfare"]},
        "tags": ["military", "vehicles"]
    },
    {
        "id": "library",
        "name": "Library",
        "type": "cultural",
        "cost": {"scrap": 100},
        "production": {"culture_points": 3},
        "effects": {},
        "description": "Preserve knowledge and educate survivors. Generates culture points.",
        "construction_time": 3,
        "requirements": {"culture_nodes": ["education_system"]},
        "tags": ["cultural", "education"]
    },
    {
        "id": "radio_station",
        "name": "Radio Tower",
        "type": "cultural",
        "cost": {"scrap": 80, "fuel": 40},
        "production": {"culture_points": 2},
        "effects": {"vision_range_bonus": 3},
        "description": "Broadcast station for communication and propaganda. Extends vision range.",
        "construction_time": 2,
        "requirements": {"culture_nodes": ["old_world_knowledge"]},
        "tags": ["communications", "cultural"]
    },
    {
        "id": "greenhouse",
        "name": "Hydroponic Greenhouse",
        "type": "production",
        "cost": {"scrap": 90, "medicine": 20},
        "production": {"food": 8},
        "effects": {},
        "description": "Advanced indoor farming. Produces food efficiently regardless of weather.",
        "construction_time": 3,
        "requirements": {"culture_nodes": ["sustainable_agriculture"]},
        "tags": ["food", "advanced"]
    },
    {
        "id": "refinery",
        "name": "Fuel Refinery",
        "type": "production",
        "cost": {"scrap": 180, "fuel": 50},
        "production": {"fuel": 10},
        "effects": {},
        "description": "Process crude oil and convert salvage into usable fuel.",
        "construction_time": 5,
        "requirements": {"buildings": ["workshop"], "culture_nodes": ["engineering_corps"]},
        "tags": ["fuel", "industrial"]
    },
    {
        "id": "kennel",
        "name": "War Dog Kennel",
        "type": "military",
        "cost": {"scrap": 60, "food": 40},
        "production": {},
        "effects": {},
        "description": "Breed and train war dogs for security and combat.",
        "construction_time": 2,
        "requirements": {},
        "tags": ["military", "animals"]
    },
    {
        "id": "solar_farm",
        "name": "Solar Array",
        "type": "production",
        "cost": {"scrap": 200},
        "production": {"fuel": 12},
        "effects": {},
        "description": "Banks of solar panels generate clean energy. Requires sunlight.",
        "construction_time": 4,
        "requirements": {"culture_nodes": ["power_generation"]},
        "tags": ["fuel", "renewable"]
    },
    {
        "id": "distillery",
        "name": "Alcohol Distillery",
        "type": "production",
        "cost": {"scrap": 70, "food": 30},
        "production": {"medicine": 4, "fuel": 3},
        "effects": {},
        "description": "Produce alcohol for medical and fuel uses. Boosts morale.",
        "construction_time": 2,
        "requirements": {"buildings": ["farm"]},
        "maintenance_cost": {"food": 5},
        "tags": ["medicine", "fuel"]
    },
    {
        "id": "bunker",
        "name": "Underground Bunker",
        "type": "defensive",
        "cost": {"scrap": 250},
        "production": {},
        "effects": {"defense_bonus": 30, "population_capacity": 20},
        "description": "Fortified underground shelter. Protects population during attacks.",
        "construction_time": 6,
        "requirements": {"buildings": ["workshop"]},
        "tags": ["defensive", "shelter"]
    },
    {
        "id": "factory",
        "name": "Industrial Factory",
        "type": "production",
        "cost": {"scrap": 300, "fuel": 100},
        "production": {"scrap": 15},
        "effects": {},
        "description": "Large-scale production facility. Generates significant scrap resources.",
        "construction_time": 7,
        "requirements": {"buildings": ["workshop"], "culture_nodes": ["industrial_revival"]},
        "maintenance_cost": {"fuel": 10},
        "tags": ["industrial", "scrap"]
    },
    {
        "id": "water_purifier",
        "name": "Water Purification Plant",
        "type": "infrastructure",
        "cost": {"scrap": 130, "medicine": 30},
        "production": {"medicine": 6},
        "effects": {"happiness_bonus": 10},
        "description": "Clean water supply improves health and morale.",
        "construction_time": 3,
        "requirements": {"culture_nodes": ["engineering_corps"]},
        "tags": ["infrastructure", "medicine"]
    },
    {
        "id": "recycling_center",
        "name": "Recycling Plant",
        "type": "production",
        "cost": {"scrap": 110},
        "production": {"scrap": 8},
        "effects": {},
        "description": "Sort and process waste into usable materials.",
        "construction_time": 3,
        "requirements": {},
        "tags": ["scrap", "efficiency"]
    },
    {
        "id": "school",
        "name": "School",
        "type": "cultural",
        "cost": {"scrap": 90},
        "production": {"culture_points": 4},
        "effects": {"happiness_bonus": 5},
        "description": "Educate the next generation. Builds hope for the future.",
        "construction_time": 3,
        "requirements": {"culture_nodes": ["education_system"]},
        "tags": ["cultural", "education"]
    },
    {
        "id": "trade_post",
        "name": "Trading Post",
        "type": "infrastructure",
        "cost": {"scrap": 100},
        "production": {"scrap": 5},
        "effects": {},
        "description": "Hub for trade with other factions. Generates passive income.",
        "construction_time": 2,
        "requirements": {"culture_nodes": ["trade_networks"]},
        "tags": ["economic", "trade"]
    },
    {
        "id": "armory",
        "name": "Armory",
        "type": "military",
        "cost": {"scrap": 140, "fuel": 50},
        "production": {},
        "effects": {"unit_production_bonus": 0.15},
        "description": "Weapons storage and maintenance. Improves military effectiveness.",
        "construction_time": 4,
        "requirements": {"buildings": ["barracks"]},
        "tags": ["military", "weapons"]
    },
    {
        "id": "lab",
        "name": "Research Laboratory",
        "type": "research",
        "cost": {"scrap": 180, "medicine": 40},
        "production": {"culture_points": 6},
        "effects": {},
        "description": "Advanced research facility. Unlocks old-world technology.",
        "construction_time": 5,
        "requirements": {"culture_nodes": ["old_world_knowledge", "scientific_method"]},
        "tags": ["research", "tech"]
    },
    {
        "id": "prison",
        "name": "Detention Center",
        "type": "infrastructure",
        "cost": {"scrap": 120},
        "production": {},
        "effects": {"defense_bonus": 10},
        "description": "Hold prisoners and maintain order. Deters crime.",
        "construction_time": 3,
        "requirements": {"culture_nodes": ["law_and_order"]},
        "tags": ["security", "control"]
    },
    {
        "id": "monument",
        "name": "Victory Monument",
        "type": "cultural",
        "cost": {"scrap": 200},
        "production": {"culture_points": 8},
        "effects": {"happiness_bonus": 15},
        "description": "Commemorative structure celebrating achievements. Inspires citizens.",
        "construction_time": 5,
        "requirements": {"culture_nodes": ["propaganda_machine"]},
        "max_per_settlement": 3,
        "tags": ["cultural", "morale"]
    },
    {
        "id": "brewery",
        "name": "Brewery",
        "type": "production",
        "cost": {"scrap": 80, "food": 30},
        "production": {"food": 5},
        "effects": {"happiness_bonus": 8},
        "description": "Produce alcohol and beverages. Boosts morale significantly.",
        "construction_time": 2,
        "requirements": {"buildings": ["farm"]},
        "maintenance_cost": {"food": 3},
        "tags": ["food", "morale"]
    },
    {
        "id": "observation_tower",
        "name": "Watchtower",
        "type": "defensive",
        "cost": {"scrap": 60},
        "production": {},
        "effects": {"vision_range_bonus": 2, "defense_bonus": 5},
        "description": "Elevated observation post. Early warning of threats.",
        "construction_time": 2,
        "requirements": {},
        "max_per_settlement": 4,
        "tags": ["defensive", "vision"]
    },
    {
        "id": "headquarters",
        "name": "Command Headquarters",
        "type": "cultural",
        "cost": {"scrap": 220, "fuel": 60},
        "production": {"culture_points": 5},
        "effects": {},
        "description": "Central command structure. Coordinates faction-wide operations.",
        "construction_time": 5,
        "requirements": {"culture_nodes": ["organized_governance"]},
        "max_per_settlement": 1,
        "tags": ["cultural", "command"]
    }
]

# Add new buildings to existing data
data["buildings"].extend(new_buildings)

# Save back to file
with open('/home/user/guvnaville/data/buildings/buildings.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f"Added {len(new_buildings)} buildings. Total now: {len(data['buildings'])}")
