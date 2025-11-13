extends Control
## ProductionDialog - Production queue controller
## Displays and manages production queue

signal dialog_closed()
signal queue_reordered(new_queue: Array)

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var queue_list: ItemList = $Panel/VBoxContainer/QueueList
@onready var add_button: Button = $Panel/VBoxContainer/ButtonsContainer/AddButton
@onready var remove_button: Button = $Panel/VBoxContainer/ButtonsContainer/RemoveButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var current_faction_id: int = 0
var production_queue: Array = []

func _ready() -> void:
	if add_button:
		add_button.pressed.connect(_on_add_pressed)
	if remove_button:
		remove_button.pressed.connect(_on_remove_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if queue_list:
		queue_list.item_selected.connect(_on_item_selected)

## Show production queue for faction
func show_queue(faction_id: int, queue: Array = []) -> void:
	current_faction_id = faction_id
	production_queue = queue.duplicate()

	if title_label:
		if faction_id == 0:
			title_label.text = "Production Queue - Player"
		else:
			title_label.text = "Production Queue - AI %d" % faction_id

	_refresh_queue_display()
	show()

## Refresh queue display
func _refresh_queue_display() -> void:
	if not queue_list:
		return

	queue_list.clear()

	for item in production_queue:
		var item_text = ""
		if item is Dictionary:
			var item_name = item.get("name", "Unknown")
			var turns_remaining = item.get("turns_remaining", 0)
			item_text = "%s (%d turns)" % [item_name, turns_remaining]
		else:
			item_text = str(item)

		queue_list.add_item(item_text)

## Handle item selected
func _on_item_selected(index: int) -> void:
	if remove_button:
		remove_button.disabled = false

## Handle add button pressed
func _on_add_pressed() -> void:
	# TODO: Show production item selection dialog
	# For now, add a placeholder item
	production_queue.append({
		"name": "New Item",
		"turns_remaining": 5
	})
	_refresh_queue_display()
	queue_reordered.emit(production_queue)

## Handle remove button pressed
func _on_remove_pressed() -> void:
	if not queue_list:
		return

	var selected = queue_list.get_selected_items()
	if selected.size() > 0:
		var index = selected[0]
		if index >= 0 and index < production_queue.size():
			production_queue.remove_at(index)
			_refresh_queue_display()
			queue_reordered.emit(production_queue)

	if remove_button:
		remove_button.disabled = true

## Handle close button pressed
func _on_close_pressed() -> void:
	_close_dialog()

## Close dialog
func _close_dialog() -> void:
	dialog_closed.emit()
	queue_free()
