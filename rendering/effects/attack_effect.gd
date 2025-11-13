## AttackEffect - Visual effects for combat
## Plays attack animations between positions
class_name AttackEffect
extends Node2D

const TILE_SIZE: int = 64
const PROJECTILE_SPEED: float = 500.0  # pixels per second
const EXPLOSION_DURATION: float = 0.3

signal animation_complete()

## Play melee attack animation
func play_melee_attack(from: Vector3i, to: Vector3i) -> void:
	var from_screen = _tile_to_screen_center(from)
	var to_screen = _tile_to_screen_center(to)

	# Create flash effect
	var flash = ColorRect.new()
	flash.size = Vector2(TILE_SIZE, TILE_SIZE)
	flash.position = to_screen - Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	flash.color = Color(1, 1, 1, 0.6)
	add_child(flash)

	# Animate flash
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	await tween.finished

	flash.queue_free()
	animation_complete.emit()

## Play ranged attack with projectile
func play_ranged_attack(from: Vector3i, to: Vector3i) -> void:
	var from_screen = _tile_to_screen_center(from)
	var to_screen = _tile_to_screen_center(to)

	# Create projectile
	var projectile = _create_projectile()
	projectile.position = from_screen
	add_child(projectile)

	# Animate projectile movement
	var distance = from_screen.distance_to(to_screen)
	var duration = distance / PROJECTILE_SPEED

	var tween = create_tween()
	tween.tween_property(projectile, "position", to_screen, duration)
	await tween.finished

	projectile.queue_free()

	# Play hit effect
	await play_explosion(to)

	animation_complete.emit()

## Play explosion effect
func play_explosion(at: Vector3i) -> void:
	var pos_screen = _tile_to_screen_center(at)

	# Create explosion circle
	var explosion = ColorRect.new()
	explosion.size = Vector2(TILE_SIZE, TILE_SIZE)
	explosion.position = pos_screen - Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	explosion.color = Color(1, 0.5, 0, 0.8)
	add_child(explosion)

	# Animate explosion
	var tween = create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(2, 2), EXPLOSION_DURATION)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, EXPLOSION_DURATION)
	await tween.finished

	explosion.queue_free()

## Create projectile visual
func _create_projectile() -> ColorRect:
	var projectile = ColorRect.new()
	projectile.size = Vector2(8, 8)
	projectile.pivot_offset = Vector2(4, 4)
	projectile.color = Color.YELLOW
	return projectile

## Convert tile position to screen center
func _tile_to_screen_center(tile_pos: Vector3i) -> Vector2:
	return Vector2(
		tile_pos.x * TILE_SIZE + TILE_SIZE / 2,
		tile_pos.y * TILE_SIZE + TILE_SIZE / 2
	)
