extends CanvasLayer

## Tutorial overlay UI that displays tutorial messages and highlights UI elements

@onready var dimmer: ColorRect = $Dimmer
@onready var highlight_rect: ColorRect = $HighlightRect
@onready var message_panel: PanelContainer = $MessagePanel
@onready var title_label: Label = $MessagePanel/VBoxContainer/Title
@onready var message_label: RichTextLabel = $MessagePanel/VBoxContainer/Message
@onready var previous_button: Button = $MessagePanel/VBoxContainer/ButtonContainer/PreviousButton
@onready var skip_button: Button = $MessagePanel/VBoxContainer/ButtonContainer/SkipButton
@onready var next_button: Button = $MessagePanel/VBoxContainer/ButtonContainer/NextButton
@onready var arrow: Polygon2D = $Arrow

var tutorial_manager: TutorialManager = null
var current_highlighted_node: Control = null

func _ready() -> void:
	# Initially hidden
	hide()

	# Connect to tutorial manager if it exists
	if has_node("/root/TutorialManager"):
		tutorial_manager = get_node("/root/TutorialManager")
		tutorial_manager.tutorial_started.connect(_on_tutorial_started)
		tutorial_manager.tutorial_step_changed.connect(_on_tutorial_step_changed)
		tutorial_manager.tutorial_completed.connect(_on_tutorial_completed)
		tutorial_manager.tutorial_skipped.connect(_on_tutorial_skipped)
		tutorial_manager.set_overlay(self)

func _on_tutorial_started() -> void:
	"""Show overlay when tutorial starts"""
	show()

func _on_tutorial_step_changed(step: TutorialStep) -> void:
	"""Update UI for new tutorial step"""
	if not step:
		return

	# Update text
	title_label.text = step.title
	message_label.text = step.message

	# Update buttons
	previous_button.disabled = tutorial_manager.current_step_index == 0
	next_button.disabled = step.wait_for_action != ""

	if step.wait_for_action != "":
		next_button.text = "Waiting..."
	else:
		next_button.text = "Next"

	# Handle highlighting
	if step.highlight_element != "":
		highlight_element(step.highlight_element)
	else:
		clear_highlight()

	# Handle arrow
	if step.show_arrow:
		show_arrow(step.arrow_position)
	else:
		hide_arrow()

	# Show the overlay
	show()

func _on_tutorial_completed() -> void:
	"""Hide overlay when tutorial completes"""
	hide()
	clear_highlight()

func _on_tutorial_skipped() -> void:
	"""Hide overlay when tutorial is skipped"""
	hide()
	clear_highlight()

func highlight_element(element_path: String) -> void:
	"""Highlight a UI element"""
	clear_highlight()

	# Try to find the node
	var node: Control = null

	# First try absolute path
	if has_node(element_path):
		node = get_node(element_path)
	else:
		# Try relative to game screen
		var game_screen := get_tree().current_scene
		if game_screen and game_screen.has_node(element_path):
			node = game_screen.get_node(element_path)

	if not node or not node is Control:
		push_warning("Could not find UI element to highlight: " + element_path)
		return

	current_highlighted_node = node

	# Calculate highlight rect position
	var global_rect := node.get_global_rect()
	highlight_rect.position = global_rect.position
	highlight_rect.size = global_rect.size
	highlight_rect.visible = true

	# Dim everything except highlighted element
	dimmer.visible = true

	# Position message panel to avoid overlapping highlight
	position_message_panel(global_rect)

func clear_highlight() -> void:
	"""Clear any highlighted elements"""
	highlight_rect.visible = false
	current_highlighted_node = null
	dimmer.visible = false

func position_message_panel(avoid_rect: Rect2) -> void:
	"""Position message panel to avoid overlapping with highlighted element"""
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := message_panel.size

	# Default to center
	var pos := Vector2(
		(viewport_size.x - panel_size.x) / 2,
		(viewport_size.y - panel_size.y) / 2
	)

	# If highlighting something at top, move panel to bottom
	if avoid_rect.position.y < viewport_size.y / 2:
		pos.y = viewport_size.y - panel_size.y - 20
	else:
		# Otherwise move to top
		pos.y = 20

	message_panel.position = pos

func show_arrow(pos: Vector2) -> void:
	"""Show an arrow pointing to a position"""
	arrow.position = pos
	arrow.visible = true

func hide_arrow() -> void:
	"""Hide the arrow"""
	arrow.visible = false

func _on_previous_button_pressed() -> void:
	"""Go to previous tutorial step"""
	if tutorial_manager:
		tutorial_manager.previous_step()

func _on_next_button_pressed() -> void:
	"""Go to next tutorial step"""
	if tutorial_manager:
		tutorial_manager.next_step()

func _on_skip_button_pressed() -> void:
	"""Skip the tutorial"""
	if tutorial_manager:
		# Show confirmation dialog
		var dialog := ConfirmationDialog.new()
		dialog.dialog_text = "Are you sure you want to skip the tutorial? You can replay it later from the main menu."
		dialog.confirmed.connect(_confirm_skip)
		add_child(dialog)
		dialog.popup_centered()

func _confirm_skip() -> void:
	"""Confirm tutorial skip"""
	if tutorial_manager:
		tutorial_manager.skip_tutorial()
