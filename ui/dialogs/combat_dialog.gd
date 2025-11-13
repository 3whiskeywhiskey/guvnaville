extends Control
## CombatDialog - Combat result controller
## Displays combat results and statistics

signal dialog_closed()

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var outcome_label: Label = $Panel/VBoxContainer/OutcomeLabel
@onready var attacker_casualties_label: Label = $Panel/VBoxContainer/StatsContainer/AttackerCasualtiesLabel
@onready var defender_casualties_label: Label = $Panel/VBoxContainer/StatsContainer/DefenderCasualtiesLabel
@onready var loot_label: Label = $Panel/VBoxContainer/LootLabel
@onready var experience_label: Label = $Panel/VBoxContainer/ExperienceLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var auto_close_timer: float = 5.0  # Auto-close after 5 seconds
var elapsed_time: float = 0.0

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time >= auto_close_timer:
		_close_dialog()

## Show combat result
func show_result(result: Dictionary) -> void:
	# Set title based on outcome
	if title_label and result.has("outcome"):
		match result["outcome"]:
			"attacker_victory":
				title_label.text = "VICTORY!"
			"defender_victory":
				title_label.text = "DEFEAT"
			"draw":
				title_label.text = "STALEMATE"
			_:
				title_label.text = "Combat Result"

	# Set outcome label
	if outcome_label and result.has("outcome"):
		outcome_label.text = "Outcome: " + result["outcome"].capitalize().replace("_", " ")

	# Set casualties
	if attacker_casualties_label and result.has("attacker_casualties"):
		attacker_casualties_label.text = "Attacker Casualties: %d" % result["attacker_casualties"]

	if defender_casualties_label and result.has("defender_casualties"):
		defender_casualties_label.text = "Defender Casualties: %d" % result["defender_casualties"]

	# Set loot
	if loot_label and result.has("loot"):
		var loot_text = "Loot: "
		var loot_dict = result["loot"]
		if loot_dict.is_empty():
			loot_text += "None"
		else:
			var loot_parts = []
			for resource in loot_dict:
				loot_parts.append("%s: %d" % [resource.capitalize(), loot_dict[resource]])
			loot_text += ", ".join(loot_parts)
		loot_label.text = loot_text

	# Set experience
	if experience_label and result.has("experience_gained"):
		experience_label.text = "Experience Gained: %d" % result["experience_gained"]

	# Show dialog
	show()

## Handle close button pressed
func _on_close_pressed() -> void:
	_close_dialog()

## Close dialog
func _close_dialog() -> void:
	dialog_closed.emit()
	queue_free()
