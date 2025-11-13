extends VBoxContainer
## NotificationManager - Notification system
## Displays temporary notification messages to the player

const NOTIFICATION_SCENE = preload("res://ui/hud/notification_item.tscn")

var notification_queue: Array = []
var max_visible_notifications: int = 5

func _ready() -> void:
	pass

## Display notification message
func show_notification(message: String, type: String = "info", duration: float = 3.0) -> void:
	# Create notification
	var notification_data = {
		"message": message,
		"type": type,
		"duration": duration,
		"timestamp": Time.get_ticks_msec() / 1000.0
	}

	notification_queue.append(notification_data)
	_display_notification(notification_data)

## Display notification visually
func _display_notification(data: Dictionary) -> void:
	# Remove oldest if too many
	while get_child_count() >= max_visible_notifications:
		var oldest = get_child(0)
		if oldest:
			oldest.queue_free()

	# Create notification UI element
	var notification_item: PanelContainer
	if NOTIFICATION_SCENE:
		notification_item = NOTIFICATION_SCENE.instantiate()
	else:
		# Fallback if scene not available
		notification_item = PanelContainer.new()
		var label = Label.new()
		notification_item.add_child(label)

	add_child(notification_item)

	# Set notification content
	if notification_item.has_method("set_notification"):
		notification_item.set_notification(data["message"], data["type"])
	else:
		var label = notification_item.get_child(0) if notification_item.get_child_count() > 0 else null
		if label and label is Label:
			label.text = data["message"]

	# Auto-remove after duration
	if data["duration"] > 0:
		await get_tree().create_timer(data["duration"]).timeout
		if notification_item and is_instance_valid(notification_item):
			notification_item.queue_free()

## Clear all notifications
func clear_notifications() -> void:
	for child in get_children():
		child.queue_free()
	notification_queue.clear()
