extends Node
class_name UIPolish

## Utility functions for adding visual polish to UI elements
## Provides animations, transitions, and visual feedback

## Add hover effect to button
static func add_button_hover_effect(button: Button) -> void:
	if not button:
		return

	button.mouse_entered.connect(func():
		var tween := button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	)

	button.mouse_exited.connect(func():
		var tween := button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
	)

	button.pressed.connect(func():
		var tween := button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	)

## Add fade in animation to control
static func fade_in(control: Control, duration: float = 0.3) -> void:
	if not control:
		return

	control.modulate.a = 0.0
	control.show()

	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(control, "modulate:a", 1.0, duration)

## Add fade out animation to control
static func fade_out(control: Control, duration: float = 0.3, hide_after: bool = true) -> void:
	if not control:
		return

	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(control, "modulate:a", 0.0, duration)

	if hide_after:
		tween.tween_callback(control.hide)

## Add slide in animation from direction
static func slide_in(control: Control, direction: Vector2, duration: float = 0.4) -> void:
	if not control:
		return

	var original_pos := control.position
	control.position += direction * 100

	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "position", original_pos, duration)

## Add bounce animation
static func bounce(control: Control) -> void:
	if not control:
		return

	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(control, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(control, "scale", Vector2(1.0, 1.0), 0.3)

## Add shake animation (for errors or warnings)
static func shake(control: Control, intensity: float = 10.0, duration: float = 0.5) -> void:
	if not control:
		return

	var original_pos := control.position
	var tween := control.create_tween()

	for i in range(8):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(control, "position", original_pos + offset, duration / 8)

	tween.tween_property(control, "position", original_pos, duration / 8)

## Add pulse animation (for notifications)
static func pulse(control: Control, scale: float = 1.2, duration: float = 0.5) -> void:
	if not control:
		return

	var tween := control.create_tween()
	tween.set_loops()
	tween.tween_property(control, "scale", Vector2(scale, scale), duration / 2)
	tween.tween_property(control, "scale", Vector2(1.0, 1.0), duration / 2)

## Stop all animations on control
static func stop_animations(control: Control) -> void:
	if not control:
		return

	# Kill all tweens on this control
	var tree := control.get_tree()
	if tree:
		tree.call_group("tweens", "kill")

## Add loading spinner animation
static func add_spinner(control: Control) -> void:
	if not control:
		return

	var tween := control.create_tween()
	tween.set_loops()
	tween.tween_property(control, "rotation_degrees", 360.0, 1.0)

## Flash animation (for highlighting)
static func flash(control: Control, color: Color = Color.WHITE, count: int = 3, duration: float = 0.2) -> void:
	if not control:
		return

	var original_color := control.modulate
	var tween := control.create_tween()

	for i in range(count):
		tween.tween_property(control, "modulate", color, duration / 2)
		tween.tween_property(control, "modulate", original_color, duration / 2)

## Add smooth transition between scenes
static func transition_out(control: Control, callback: Callable) -> void:
	if not control:
		callback.call()
		return

	fade_out(control, 0.5, false)
	await control.get_tree().create_timer(0.5).timeout
	callback.call()

## Add confirmation animation (checkmark effect)
static func confirm_animation(control: Control) -> void:
	if not control:
		return

	# Brief green flash and scale
	var original_color := control.modulate
	var tween := control.create_tween()

	tween.tween_property(control, "modulate", Color(0, 1, 0, 1), 0.1)
	tween.parallel().tween_property(control, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(control, "modulate", original_color, 0.2)
	tween.parallel().tween_property(control, "scale", Vector2(1.0, 1.0), 0.2)

## Add error animation (red flash and shake)
static func error_animation(control: Control) -> void:
	if not control:
		return

	# Red flash
	var original_color := control.modulate
	var tween := control.create_tween()
	tween.tween_property(control, "modulate", Color(1, 0, 0, 1), 0.1)
	tween.tween_property(control, "modulate", original_color, 0.2)

	# Shake
	shake(control, 5.0, 0.3)

## Add typing effect to label
static func typing_effect(label: Label, text: String, speed: float = 0.05) -> void:
	if not label:
		return

	label.text = ""
	label.visible_characters = 0

	for i in range(text.length()):
		await label.get_tree().create_timer(speed).timeout
		label.text = text.substr(0, i + 1)
