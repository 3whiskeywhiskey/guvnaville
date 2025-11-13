extends Node
class_name EventManager

## Event Management System
## Coordinates event loading, queuing, triggering, and resolution

## Signals
signal event_triggered(faction_id: int, event_id: String, event_instance: EventInstance)
signal event_choice_made(faction_id: int, event_id: String, choice_index: int)
signal event_consequences_applied(faction_id: int, event_id: String, consequences: Dictionary)
signal event_chain_started(faction_id: int, chain_id: String)
signal event_queued(faction_id: int, event_id: String, trigger_turn: int)
signal event_dequeued(faction_id: int, event_id: String, reason: String)

## Components
var _trigger_evaluator: EventTriggerEvaluator
var _choice_resolver: EventChoiceResolver
var _consequence_applicator: EventConsequenceApplicator

## Event storage
var _event_definitions: Dictionary = {}  # event_id -> EventDefinition
var _event_queue: Array = []  # Array of queued event instances
var _active_instances: Dictionary = {}  # instance_id -> EventInstance
var _faction_history: Dictionary = {}  # faction_id -> Array[event_id]
var _faction_cooldowns: Dictionary = {}  # faction_id -> {event_id: turn_available}
var _next_instance_id: int = 0

## Initialize components
func _init():
	_trigger_evaluator = EventTriggerEvaluator.new()
	_choice_resolver = EventChoiceResolver.new()
	_consequence_applicator = EventConsequenceApplicator.new()

func _ready():
	# Connect consequence signals
	_consequence_applicator.consequence_applied.connect(_on_consequence_applied)

## Load events from data array
## @param data: Array of event definition dictionaries
## @returns: void
func load_events(data: Array) -> void:
	_event_definitions.clear()

	for event_data in data:
		if typeof(event_data) != TYPE_DICTIONARY:
			push_warning("EventManager: Invalid event data type")
			continue

		var event_def = EventDefinition.from_dict(event_data)
		if event_def.event_id == "":
			push_warning("EventManager: Event missing ID, skipping")
			continue

		_event_definitions[event_def.event_id] = event_def

	print("EventManager: Loaded %d event definitions" % _event_definitions.size())

## Load events from JSON file
## @param file_path: Path to JSON file
## @returns: bool - true if successful
func load_events_from_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("EventManager: Event file not found: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("EventManager: Failed to open event file: %s" % file_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("EventManager: Failed to parse JSON: %s" % file_path)
		return false

	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY and data.has("events"):
		load_events(data["events"])
		return true
	elif typeof(data) == TYPE_ARRAY:
		load_events(data)
		return true
	else:
		push_error("EventManager: Invalid JSON structure in: %s" % file_path)
		return false

## Queue an event to be presented to a faction
## @param event_id: ID of event to queue
## @param faction_id: Target faction
## @param delay_turns: Turns to wait before presenting (0 = this turn)
## @returns: void
func queue_event(event_id: String, faction_id: int, delay_turns: int = 0) -> void:
	if not _event_definitions.has(event_id):
		push_warning("EventManager: Cannot queue unknown event: %s" % event_id)
		return

	var event_def = _event_definitions[event_id]

	# Check if event is on cooldown
	if _is_on_cooldown(event_id, faction_id):
		var cooldown_turn = _faction_cooldowns[faction_id][event_id]
		push_warning("EventManager: Event %s on cooldown for faction %d until turn %d" % [event_id, faction_id, cooldown_turn])
		return

	# Create event instance
	var instance = EventInstance.new(_next_instance_id, event_id)
	_next_instance_id += 1

	instance.faction_id = faction_id
	instance.title = event_def.title
	instance.description = event_def.description
	instance.priority = event_def.base_priority
	instance.image_path = event_def.image_path
	instance.metadata = event_def.metadata.duplicate()
	instance.queued_turn = -1  # Will be set when we have game state
	instance.trigger_turn = -1 + delay_turns  # Will be updated with current turn

	# Deep copy choices
	for choice in event_def.choices:
		var choice_copy = EventChoice.new(choice.choice_id, choice.text)
		choice_copy.requirements = choice.requirements.duplicate()
		choice_copy.outcomes = choice.outcomes.duplicate()
		choice_copy.probabilistic = choice.probabilistic
		choice_copy.probability_weights = choice.probability_weights.duplicate()
		instance.choices.append(choice_copy)

	# Add to queue
	_event_queue.append(instance)
	_active_instances[instance.id] = instance

	# Sort queue by priority (higher first)
	_event_queue.sort_custom(func(a, b): return a.priority > b.priority)

	event_queued.emit(faction_id, event_id, instance.trigger_turn)

## Check which events should trigger for a faction
## @param faction_id: Faction to check
## @param game_state: Current game state
## @returns: Array of event IDs that should trigger
func check_triggers(faction_id: int, game_state) -> Array[String]:
	var triggered_events: Array[String] = []

	for event_id in _event_definitions:
		var event_def = _event_definitions[event_id]

		# Check if already fired and non-repeatable
		if not event_def.repeatable and _has_fired(event_id, faction_id):
			continue

		# Check if on cooldown
		if _is_on_cooldown(event_id, faction_id):
			continue

		# Evaluate triggers
		if _trigger_evaluator.evaluate_triggers(event_def, faction_id, game_state):
			triggered_events.append(event_id)

	return triggered_events

## Present an event to a faction and create an instance
## @param event_id: Event definition ID
## @param faction_id: Target faction
## @returns: EventInstance ready for presentation
func present_event(event_id: String, faction_id: int) -> EventInstance:
	if not _event_definitions.has(event_id):
		push_warning("EventManager: Cannot present unknown event: %s" % event_id)
		return null

	var event_def = _event_definitions[event_id]

	# Create instance
	var instance = EventInstance.new(_next_instance_id, event_id)
	_next_instance_id += 1

	instance.faction_id = faction_id
	instance.title = event_def.title
	instance.description = event_def.description
	instance.priority = event_def.base_priority
	instance.image_path = event_def.image_path
	instance.metadata = event_def.metadata.duplicate()

	# Deep copy choices
	for choice in event_def.choices:
		var choice_copy = EventChoice.new(choice.choice_id, choice.text)
		choice_copy.requirements = choice.requirements.duplicate()
		choice_copy.outcomes = choice.outcomes.duplicate()
		choice_copy.probabilistic = choice.probabilistic
		choice_copy.probability_weights = choice.probability_weights.duplicate()
		instance.choices.append(choice_copy)

	_active_instances[instance.id] = instance

	# Record in history
	_add_to_history(event_id, faction_id)

	event_triggered.emit(faction_id, event_id, instance)

	return instance

## Record a choice made for an event instance
## @param event_instance_id: Runtime instance ID
## @param choice_index: Index of selected choice
## @returns: void
func make_choice(event_instance_id: int, choice_index: int) -> void:
	if not _active_instances.has(event_instance_id):
		push_warning("EventManager: Unknown event instance: %d" % event_instance_id)
		return

	var instance = _active_instances[event_instance_id]

	if choice_index < 0 or choice_index >= instance.choices.size():
		push_warning("EventManager: Invalid choice index: %d for event %s" % [choice_index, instance.event_id])
		return

	event_choice_made.emit(instance.faction_id, instance.event_id, choice_index)

## Apply consequences of a choice
## @param event_id: Event definition ID
## @param choice_index: Index of selected choice
## @param faction_id: Faction making choice
## @returns: Dictionary of applied consequences for feedback
func apply_consequences(event_id: String, choice_index: int, faction_id: int) -> Dictionary:
	# This is a simplified version - in full implementation,
	# we'd need the game_state parameter
	push_warning("EventManager: apply_consequences called without game_state")
	return {"success": false, "error": "game_state required"}

## Apply consequences with game state
## @param event_instance_id: Runtime instance ID
## @param choice_index: Index of selected choice
## @param game_state: Current game state
## @returns: Dictionary of applied consequences
func apply_consequences_with_state(event_instance_id: int, choice_index: int, game_state) -> Dictionary:
	if not _active_instances.has(event_instance_id):
		return {"success": false, "error": "Event instance not found"}

	var instance = _active_instances[event_instance_id]

	if choice_index < 0 or choice_index >= instance.choices.size():
		return {"success": false, "error": "Invalid choice index"}

	var choice = instance.choices[choice_index]

	# Resolve probabilistic outcomes if needed
	var consequences_to_apply = _choice_resolver.resolve_probabilistic_choice(choice)

	# Apply consequences
	var results = _consequence_applicator.apply_consequences(
		consequences_to_apply,
		instance.faction_id,
		game_state
	)

	# Handle event chains (queued events)
	if game_state.has("queued_events"):
		var queued_events = game_state["queued_events"] if typeof(game_state) == TYPE_DICTIONARY else game_state.queued_events
		for event_data in queued_events:
			queue_event(event_data["event_id"], event_data["faction_id"], event_data["delay_turns"])
		# Clear the queued events
		if typeof(game_state) == TYPE_DICTIONARY:
			game_state["queued_events"] = []
		else:
			game_state.queued_events = []

	# Set cooldown if needed
	var event_def = _event_definitions[instance.event_id]
	if event_def.cooldown_turns > 0:
		_set_cooldown(instance.event_id, instance.faction_id, event_def.cooldown_turns, game_state)

	event_consequences_applied.emit(instance.faction_id, instance.event_id, results)

	# Clean up instance
	_active_instances.erase(event_instance_id)

	return results

## Process event queue for current turn
## @param current_turn: Current turn number
## @returns: Array of EventInstances that should be presented this turn
func process_event_queue(current_turn: int) -> Array[EventInstance]:
	var events_to_present: Array[EventInstance] = []

	# Update trigger turns for queued events
	for instance in _event_queue:
		if instance.queued_turn == -1:
			instance.queued_turn = current_turn
			instance.trigger_turn = current_turn

	# Find events that should fire this turn
	var i = 0
	while i < _event_queue.size():
		var instance = _event_queue[i]

		if instance.trigger_turn <= current_turn:
			events_to_present.append(instance)
			_event_queue.remove_at(i)

			# Record in history
			_add_to_history(instance.event_id, instance.faction_id)
		else:
			i += 1

	return events_to_present

## Get event definition by ID
## @param event_id: Event definition ID
## @returns: EventDefinition or null if not found
func get_event_definition(event_id: String) -> EventDefinition:
	return _event_definitions.get(event_id, null)

## Get active event instance by ID
## @param instance_id: Runtime instance ID
## @returns: EventInstance or null if not found
func get_event_instance(instance_id: int) -> EventInstance:
	return _active_instances.get(instance_id, null)

## Clear event history (for testing)
## @returns: void
func clear_history() -> void:
	_faction_history.clear()
	_faction_cooldowns.clear()
	_event_queue.clear()
	_active_instances.clear()
	_next_instance_id = 0

## Get faction's event history
## @param faction_id: Faction to query
## @returns: Array of event IDs that have fired for this faction
func get_faction_event_history(faction_id: int) -> Array[String]:
	if not _faction_history.has(faction_id):
		return []
	return _faction_history[faction_id].duplicate()

## Get all event definitions
## @returns: Dictionary of event_id -> EventDefinition
func get_all_event_definitions() -> Dictionary:
	return _event_definitions.duplicate()

## Get event queue size
## @returns: int - number of queued events
func get_queue_size() -> int:
	return _event_queue.size()

## Validate choice availability for instance
## @param event_instance_id: Runtime instance ID
## @param game_state: Current game state
## @returns: void - updates choices in place
func validate_choices(event_instance_id: int, game_state) -> void:
	if not _active_instances.has(event_instance_id):
		return

	var instance = _active_instances[event_instance_id]
	_choice_resolver.validate_all_choices(instance, instance.faction_id, game_state)

## AI select choice for event
## @param event_instance_id: Runtime instance ID
## @param game_state: Current game state
## @returns: int - selected choice index
func ai_select_choice(event_instance_id: int, game_state) -> int:
	if not _active_instances.has(event_instance_id):
		return -1

	var instance = _active_instances[event_instance_id]
	return _choice_resolver.ai_select_choice(instance, instance.faction_id, game_state)

## Private: Check if event has fired for faction
func _has_fired(event_id: String, faction_id: int) -> bool:
	if not _faction_history.has(faction_id):
		return false
	return event_id in _faction_history[faction_id]

## Private: Add event to faction history
func _add_to_history(event_id: String, faction_id: int) -> void:
	if not _faction_history.has(faction_id):
		_faction_history[faction_id] = []
	if not event_id in _faction_history[faction_id]:
		_faction_history[faction_id].append(event_id)

## Private: Check if event is on cooldown
func _is_on_cooldown(event_id: String, faction_id: int) -> bool:
	if not _faction_cooldowns.has(faction_id):
		return false
	if not _faction_cooldowns[faction_id].has(event_id):
		return false

	# Cooldown is stored as turn number when available again
	# We don't have current turn here, so return true if cooldown exists
	return true

## Private: Set event cooldown
func _set_cooldown(event_id: String, faction_id: int, cooldown_turns: int, game_state) -> void:
	if not _faction_cooldowns.has(faction_id):
		_faction_cooldowns[faction_id] = {}

	var current_turn = 0
	if game_state.has("current_turn"):
		current_turn = game_state["current_turn"] if typeof(game_state) == TYPE_DICTIONARY else game_state.current_turn
	elif game_state.has("turn_number"):
		current_turn = game_state["turn_number"] if typeof(game_state) == TYPE_DICTIONARY else game_state.turn_number

	_faction_cooldowns[faction_id][event_id] = current_turn + cooldown_turns

## Private: Signal handler for consequences
func _on_consequence_applied(consequence_type: String, target: String, value: Variant) -> void:
	# Could be used for logging or debugging
	pass
