extends PanelContainer
## NotificationItem - Single notification display

@onready var type_icon: Label = $HBoxContainer/TypeIcon
@onready var message_label: Label = $HBoxContainer/MessageLabel

func set_notification(message: String, type: String) -> void:
	if message_label:
		message_label.text = message

	if type_icon:
		match type:
			"info":
				type_icon.text = "[i]"
			"warning":
				type_icon.text = "[!]"
			"error":
				type_icon.text = "[X]"
			"success":
				type_icon.text = "[✓]"
			_:
				type_icon.text = "[i]"

	# Set color based on type
	match type:
		"warning":
			modulate = Color(1.0, 1.0, 0.7)
		"error":
			modulate = Color(1.0, 0.7, 0.7)
		"success":
			modulate = Color(0.7, 1.0, 0.7)
		_:
			modulate = Color(1.0, 1.0, 1.0)
