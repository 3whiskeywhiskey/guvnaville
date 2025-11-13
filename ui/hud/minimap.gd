extends Control
## Minimap - Minimap controller
## Shows basic minimap of the game world (simplified for MVP)

@onready var minimap_texture: TextureRect = $PanelContainer/MinimapTexture

var map_width: int = 200
var map_height: int = 200
var minimap_size: Vector2i = Vector2i(200, 200)

func _ready() -> void:
	_generate_placeholder_minimap()

## Generate placeholder minimap (basic grid)
func _generate_placeholder_minimap() -> void:
	if not minimap_texture:
		return

	var image = Image.create(minimap_size.x, minimap_size.y, false, Image.FORMAT_RGB8)

	# Fill with basic pattern
	for y in range(minimap_size.y):
		for x in range(minimap_size.x):
			var color = Color(0.3, 0.3, 0.3)
			# Checkerboard pattern
			if (x / 10 + y / 10) % 2 == 0:
				color = Color(0.4, 0.4, 0.4)
			image.set_pixel(x, y, color)

	var texture = ImageTexture.create_from_image(image)
	minimap_texture.texture = texture

## Update minimap with map data
func update_minimap(map_data: Dictionary) -> void:
	# TODO: Render actual map data
	# For now, keep placeholder
	pass

## Handle map change signal from EventBus
func _on_map_changed() -> void:
	# TODO: Update minimap when map changes
	pass

## Handle fog of war update
func _on_fog_updated(faction_id: int, revealed_tiles: Array) -> void:
	if faction_id == 0:  # Player faction
		# TODO: Update visible areas on minimap
		pass
