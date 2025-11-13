extends Control
## TurnIndicator - Turn counter controller
## Shows current turn number, phase, and active faction

@onready var turn_label: Label = $VBoxContainer/TurnLabel
@onready var phase_label: Label = $VBoxContainer/PhaseLabel
@onready var faction_label: Label = $VBoxContainer/FactionLabel

var current_turn: int = 1
var current_phase: String = "movement"
var active_faction: int = 0

func _ready() -> void:
	update_display()

## Update turn counter with new values
func update_turn(turn_number: int, phase: String, faction_id: int) -> void:
	current_turn = turn_number
	current_phase = phase
	active_faction = faction_id
	update_display()

## Update turn display
func update_display() -> void:
	if turn_label:
		turn_label.text = "Turn %d" % current_turn

	if phase_label:
		var phase_name = current_phase.capitalize()
		phase_label.text = "Phase: %s" % phase_name

	if faction_label:
		var faction_name = _get_faction_name(active_faction)
		faction_label.text = "Active: %s" % faction_name

## Get faction name from ID
func _get_faction_name(faction_id: int) -> String:
	if faction_id == 0:
		return "Player"
	else:
		return "AI %d" % faction_id

## Handle turn start signal from EventBus
func _on_turn_started(turn_number: int, faction_id: int) -> void:
	update_turn(turn_number, current_phase, faction_id)

## Handle phase change signal from EventBus
func _on_phase_changed(old_phase: String, new_phase: String) -> void:
	current_phase = new_phase
	update_display()
