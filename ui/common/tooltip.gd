extends PanelContainer
class_name Tooltip

## A customizable tooltip that can display text and keyboard shortcuts
## Automatically positions itself near the mouse cursor

signal tooltip_shown()
signal tooltip_hidden()

@export var show_delay: float = 0.5  # Delay before showing tooltip
@export var max_width: int = 400
@export var padding: int = 10

@onready var label: RichTextLabel = $MarginContainer/Label

var timer: Timer
var target_control: Control = null
var is_visible_flag: bool = false

func _ready() -> void:
	# Initially hidden
	hide()
	modulate.a = 0.0

	# Setup timer for delayed show
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_show_timer_timeout)
	add_child(timer)

	# Setup label
	if label:
		label.bbcode_enabled = true
		label.fit_content = true
		label.custom_minimum_size.x = 0
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func show_tooltip(text: String, position_hint: Vector2 = Vector2.ZERO) -> void:
	"""Show tooltip with given text at optional position"""
	if text.is_empty():
		return

	# Set text
	label.text = text

	# Start timer
	timer.start(show_delay)

	# Store position for when timer fires
	if position_hint != Vector2.ZERO:
		set_position_near(position_hint)
	else:
		set_position_near(get_global_mouse_position())

func hide_tooltip() -> void:
	"""Hide the tooltip"""
	timer.stop()

	if is_visible_flag:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(hide)
		is_visible_flag = false
		tooltip_hidden.emit()

func _on_show_timer_timeout() -> void:
	"""Show tooltip after delay"""
	if not is_visible_flag:
		show()
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
		is_visible_flag = true
		tooltip_shown.emit()

func set_position_near(pos: Vector2) -> void:
	"""Position tooltip near given position without going offscreen"""
	# Wait for size to be calculated
	await get_tree().process_frame

	var viewport_size := get_viewport_rect().size
	var tooltip_size := size

	# Default offset from cursor
	var offset := Vector2(15, 15)

	var final_pos := pos + offset

	# Keep within viewport bounds
	if final_pos.x + tooltip_size.x > viewport_size.x:
		final_pos.x = pos.x - tooltip_size.x - offset.x

	if final_pos.y + tooltip_size.y > viewport_size.y:
		final_pos.y = pos.y - tooltip_size.y - offset.y

	# Ensure not negative
	final_pos.x = max(padding, final_pos.x)
	final_pos.y = max(padding, final_pos.y)

	global_position = final_pos

func format_tooltip(title: String, description: String, shortcut: String = "") -> String:
	"""Format a tooltip with title, description, and optional keyboard shortcut"""
	var text := "[b]%s[/b]\n\n%s" % [title, description]

	if not shortcut.is_empty():
		text += "\n\n[i]Shortcut: %s[/i]" % shortcut

	return text

## Autoload Tooltip Manager
class_name TooltipManager
extends Node

## Global tooltip manager singleton
## Manages a single tooltip instance that can be shown by any control

var tooltip_instance: Tooltip = null
var tooltip_scene := preload("res://ui/common/tooltip.tscn")

func _ready() -> void:
	# Create tooltip instance
	tooltip_instance = tooltip_scene.instantiate()
	add_child(tooltip_instance)

	# Move to high layer
	tooltip_instance.z_index = 1000

func show_tooltip(text: String, position: Vector2 = Vector2.ZERO) -> void:
	"""Show tooltip globally"""
	if tooltip_instance:
		tooltip_instance.show_tooltip(text, position)

func hide_tooltip() -> void:
	"""Hide tooltip globally"""
	if tooltip_instance:
		tooltip_instance.hide_tooltip()

func register_control(control: Control, tooltip_text: String) -> void:
	"""Register a control to show tooltip on hover"""
	if not control:
		return

	# Connect mouse signals
	if not control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control, tooltip_text))

	if not control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.connect(_on_control_mouse_exited)

func _on_control_mouse_entered(control: Control, text: String) -> void:
	"""Show tooltip when mouse enters control"""
	var pos := control.get_global_rect().position
	pos.y += control.get_global_rect().size.y
	show_tooltip(text, pos)

func _on_control_mouse_exited() -> void:
	"""Hide tooltip when mouse exits control"""
	hide_tooltip()
