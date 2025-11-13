## UnitRenderer - Renders a single unit sprite
## Handles unit visualization, health bars, and animations
class_name UnitRenderer
extends Node2D

# Constants
const TILE_SIZE: int = 64
const HEALTH_BAR_WIDTH: int = 48
const HEALTH_BAR_HEIGHT: int = 6

# Unit data
var unit_id: int
var unit_type: String
var faction_id: int
var current_position: Vector3i

# Visual components
var _sprite: Sprite2D
var _health_bar_bg: ColorRect
var _health_bar_fg: ColorRect
var _status_container: HBoxContainer
var _sprite_loader: SpriteLoader

# Animation state
var _is_animating: bool = false
var _animation_tween: Tween

## Initialize unit renderer with unit data
func initialize(unit_data, sprite_loader: SpriteLoader) -> void:
	_sprite_loader = sprite_loader

	# Extract unit properties
	unit_id = _get_property(unit_data, "id", 0)
	unit_type = _get_property(unit_data, "type", "soldier")
	faction_id = _get_property(unit_data, "faction_id", 0)
	current_position = _get_property(unit_data, "position", Vector3i.ZERO)

	_create_sprite()
	_create_health_bar()
	_create_status_container()

	# Position at tile
	position = _tile_to_screen_position(current_position)

	# Set z_index based on elevation
	z_index = 10 + current_position.z

## Update unit position with optional animation
func update_position(new_position: Vector3i, animate: bool = true) -> void:
	if animate and not _is_animating:
		await _animate_movement(new_position)
	else:
		current_position = new_position
		position = _tile_to_screen_position(new_position)
		z_index = 10 + new_position.z

## Update health bar display
func update_health(current_hp: int, max_hp: int) -> void:
	if _health_bar_fg:
		var health_ratio = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
		_health_bar_fg.size.x = HEALTH_BAR_WIDTH * health_ratio

		# Change color based on health
		if health_ratio > 0.6:
			_health_bar_fg.color = Color.GREEN
		elif health_ratio > 0.3:
			_health_bar_fg.color = Color.YELLOW
		else:
			_health_bar_fg.color = Color.RED

## Display status effect icons above unit
func show_status_effects(effects: Array) -> void:
	if not _status_container:
		return

	# Clear existing status icons
	for child in _status_container.get_children():
		child.queue_free()

	# Add new status icons
	for effect in effects:
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(16, 16)
		# TODO: Load actual status effect icons
		_status_container.add_child(icon)

## Play unit animation
func play_animation(anim_name: String) -> void:
	# For MVP, just do simple visual feedback
	match anim_name:
		"idle":
			modulate = Color.WHITE
		"walk":
			_play_walk_animation()
		"attack":
			_play_attack_animation()
		"hit":
			_play_hit_animation()
		"death":
			_play_death_animation()

## Set unit visibility
func set_unit_visible(is_visible: bool) -> void:
	visible = is_visible

## Create the unit sprite
func _create_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _sprite_loader.get_unit_sprite(unit_type, faction_id)
	_sprite.centered = true
	_sprite.position = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	add_child(_sprite)

## Create health bar UI
func _create_health_bar() -> void:
	# Background
	_health_bar_bg = ColorRect.new()
	_health_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	_health_bar_bg.position = Vector2(
		(TILE_SIZE - HEALTH_BAR_WIDTH) / 2,
		TILE_SIZE - HEALTH_BAR_HEIGHT - 4
	)
	_health_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(_health_bar_bg)

	# Foreground (health)
	_health_bar_fg = ColorRect.new()
	_health_bar_fg.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	_health_bar_fg.position = _health_bar_bg.position
	_health_bar_fg.color = Color.GREEN
	add_child(_health_bar_fg)

## Create status effect container
func _create_status_container() -> void:
	_status_container = HBoxContainer.new()
	_status_container.position = Vector2(TILE_SIZE / 2 - 24, -20)
	add_child(_status_container)

## Animate unit movement
func _animate_movement(target_position: Vector3i) -> void:
	_is_animating = true

	var target_screen_pos = _tile_to_screen_position(target_position)

	if _animation_tween:
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.tween_property(self, "position", target_screen_pos, 0.3) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)

	await _animation_tween.finished

	current_position = target_position
	z_index = 10 + target_position.z
	_is_animating = false

## Play walk animation (simple bob)
func _play_walk_animation() -> void:
	if _animation_tween:
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.tween_property(_sprite, "position:y", TILE_SIZE / 2 - 4, 0.15)
	_animation_tween.tween_property(_sprite, "position:y", TILE_SIZE / 2, 0.15)

## Play attack animation (quick forward movement)
func _play_attack_animation() -> void:
	if _animation_tween:
		_animation_tween.kill()

	var original_pos = _sprite.position

	_animation_tween = create_tween()
	_animation_tween.tween_property(_sprite, "position:x", original_pos.x + 8, 0.1)
	_animation_tween.tween_property(_sprite, "position:x", original_pos.x, 0.1)

## Play hit animation (flash red)
func _play_hit_animation() -> void:
	if _animation_tween:
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.tween_property(_sprite, "modulate", Color.RED, 0.1)
	_animation_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)

## Play death animation (fade out)
func _play_death_animation() -> void:
	if _animation_tween:
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await _animation_tween.finished
	queue_free()

## Convert tile position to screen position
func _tile_to_screen_position(tile_pos: Vector3i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)

## Get property from unit data (handles both dictionary and object)
func _get_property(data, property: String, default_value):
	if data == null:
		return default_value

	if data is Dictionary:
		return data.get(property, default_value)

	if property in data:
		return data.get(property)

	return default_value
