extends Control
## EventDialog - Event popup controller
## Displays events and player choices

signal choice_selected(choice_id: int)

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var current_event: Dictionary = {}

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

## Show event dialog with choices
func show_event(event: Dictionary) -> void:
	current_event = event

	# Set title and description
	if title_label and event.has("title"):
		title_label.text = event["title"]

	if description_label and event.has("description"):
		description_label.text = event["description"]

	# Clear existing choices
	if choices_container:
		for child in choices_container.get_children():
			child.queue_free()

		# Add choice buttons
		if event.has("choices"):
			for i in range(event["choices"].size()):
				var choice = event["choices"][i]
				var button = Button.new()
				button.text = choice.get("text", "Choice %d" % (i + 1))
				button.custom_minimum_size = Vector2(0, 40)

				# Disable if requirements not met
				if choice.get("disabled", false):
					button.disabled = true
					button.tooltip_text = choice.get("disabled_reason", "Requirements not met")

				button.pressed.connect(_on_choice_pressed.bind(i))
				choices_container.add_child(button)

	# Show dialog
	show()

## Handle choice button pressed
func _on_choice_pressed(choice_id: int) -> void:
	choice_selected.emit(choice_id)

	# Emit event choice to EventBus if available
	# EventBus.event_choice_selected.emit(current_event.get("id", ""), choice_id)

	# Close dialog
	_close_dialog()

## Handle close button pressed
func _on_close_pressed() -> void:
	_close_dialog()

## Close dialog
func _close_dialog() -> void:
	queue_free()
