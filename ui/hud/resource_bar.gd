extends Control
## ResourceBar - Resource display controller
## Shows current resource stockpiles for the player faction

@onready var scrap_label: Label = $HBoxContainer/ScrapLabel
@onready var food_label: Label = $HBoxContainer/FoodLabel
@onready var medicine_label: Label = $HBoxContainer/MedicineLabel
@onready var ammunition_label: Label = $HBoxContainer/AmmunitionLabel
@onready var fuel_label: Label = $HBoxContainer/FuelLabel
@onready var components_label: Label = $HBoxContainer/ComponentsLabel
@onready var water_label: Label = $HBoxContainer/WaterLabel

var current_resources: Dictionary = {
	"scrap": 0,
	"food": 0,
	"medicine": 0,
	"ammunition": 0,
	"fuel": 0,
	"components": 0,
	"water": 0
}

func _ready() -> void:
	update_display()

## Update resource display with new values
func update_resources(resources: Dictionary) -> void:
	current_resources = resources.duplicate()
	update_display()

## Update resource display
func update_display() -> void:
	if scrap_label:
		scrap_label.text = "Scrap: %d" % current_resources.get("scrap", 0)
	if food_label:
		food_label.text = "Food: %d" % current_resources.get("food", 0)
	if medicine_label:
		medicine_label.text = "Medicine: %d" % current_resources.get("medicine", 0)
	if ammunition_label:
		ammunition_label.text = "Ammo: %d" % current_resources.get("ammunition", 0)
	if fuel_label:
		fuel_label.text = "Fuel: %d" % current_resources.get("fuel", 0)
	if components_label:
		components_label.text = "Parts: %d" % current_resources.get("components", 0)
	if water_label:
		water_label.text = "Water: %d" % current_resources.get("water", 0)

## Handle resource change signal from EventBus
func _on_resource_changed(faction_id: int, resource_type: String, amount: int, new_total: int) -> void:
	if faction_id == 0:  # Player faction
		if current_resources.has(resource_type):
			current_resources[resource_type] = new_total
			update_display()

## Handle resource shortage signal
func _on_resource_shortage(faction_id: int, resource_type: String, deficit: int) -> void:
	if faction_id == 0:  # Player faction
		# Flash the resource label or show warning
		# TODO: Add visual warning feedback
		pass
