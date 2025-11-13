## Unit tests for SpriteLoader
extends GutTest

const SpriteLoader = preload("res://rendering/sprite_loader.gd")

var sprite_loader: SpriteLoader

func before_each():
	sprite_loader = SpriteLoader.new()
	add_child_autofree(sprite_loader)

func after_each():
	if sprite_loader:
		sprite_loader.clear_cache()

func test_load_tile_sprites_caches_results():
	# First load
	var start_time = Time.get_ticks_msec()
	var tiles1 = sprite_loader.load_tile_sprites()
	var first_load_time = Time.get_ticks_msec() - start_time

	assert_gt(tiles1.size(), 0, "Should load tile sprites")

	# Second load (cached)
	start_time = Time.get_ticks_msec()
	var tiles2 = sprite_loader.load_tile_sprites()
	var second_load_time = Time.get_ticks_msec() - start_time

	# Cached load should be much faster (< 10x faster at least)
	assert_lt(second_load_time, max(first_load_time / 5, 1), "Second load should be cached and faster")
	assert_eq(tiles1, tiles2, "Should return same cached dictionary")

func test_load_unit_sprites_caches_results():
	# First load
	var start_time = Time.get_ticks_msec()
	var units1 = sprite_loader.load_unit_sprites()
	var first_load_time = Time.get_ticks_msec() - start_time

	assert_gt(units1.size(), 0, "Should load unit sprites")

	# Second load (cached)
	start_time = Time.get_ticks_msec()
	var units2 = sprite_loader.load_unit_sprites()
	var second_load_time = Time.get_ticks_msec() - start_time

	# Cached load should be much faster
	assert_lt(second_load_time, max(first_load_time / 5, 1), "Second load should be cached and faster")
	assert_eq(units1, units2, "Should return same cached dictionary")

func test_get_tile_sprite_returns_valid_texture():
	var texture = sprite_loader.get_tile_sprite("residential")

	assert_not_null(texture, "Should return a texture")
	assert_true(texture is Texture2D, "Should be a Texture2D")

func test_get_tile_sprite_unknown_type_returns_default():
	var texture = sprite_loader.get_tile_sprite("unknown_type_xyz")

	assert_not_null(texture, "Should return default texture")
	assert_true(texture is Texture2D, "Should be a Texture2D")

func test_get_unit_sprite_returns_valid_texture():
	var texture = sprite_loader.get_unit_sprite("soldier", 0)

	assert_not_null(texture, "Should return a texture")
	assert_true(texture is Texture2D, "Should be a Texture2D")

func test_get_unit_sprite_faction_variants():
	var faction0 = sprite_loader.get_unit_sprite("soldier", 0)
	var faction1 = sprite_loader.get_unit_sprite("soldier", 1)

	assert_not_null(faction0, "Faction 0 sprite should exist")
	assert_not_null(faction1, "Faction 1 sprite should exist")
	# Note: Sprites will be different due to faction hue shifts

func test_clear_cache_removes_cached_sprites():
	sprite_loader.load_tile_sprites()
	sprite_loader.load_unit_sprites()

	sprite_loader.clear_cache()

	# After clearing, loading should take time again
	var start_time = Time.get_ticks_msec()
	sprite_loader.load_tile_sprites()
	var load_time = Time.get_ticks_msec() - start_time

	# Should take some time (not instant from cache)
	assert_gt(load_time, 0, "Should take time to reload after cache clear")

func test_preload_all_assets_loads_everything():
	var loaded = false
	sprite_loader.assets_loaded.connect(func(): loaded = true)

	sprite_loader.preload_all_assets()
	await wait_seconds(0.5)

	assert_true(loaded, "Should emit assets_loaded signal")

	# Verify both tile and unit sprites are loaded
	var tiles = sprite_loader.get_tile_sprite("residential")
	var units = sprite_loader.get_unit_sprite("soldier", 0)

	assert_not_null(tiles, "Tiles should be loaded")
	assert_not_null(units, "Units should be loaded")

func test_placeholder_textures_have_correct_size():
	var texture = sprite_loader.get_tile_sprite("residential")

	assert_eq(texture.get_width(), 64, "Tile texture should be 64x64")
	assert_eq(texture.get_height(), 64, "Tile texture should be 64x64")

func test_tile_types_coverage():
	var tile_types = ["residential", "commercial", "industrial", "military",
					  "street", "park", "rubble", "default"]

	for tile_type in tile_types:
		var texture = sprite_loader.get_tile_sprite(tile_type)
		assert_not_null(texture, "Should have sprite for type: %s" % tile_type)

func test_unit_types_coverage():
	var unit_types = ["militia", "soldier", "scout", "medic", "default"]

	for unit_type in unit_types:
		var texture = sprite_loader.get_unit_sprite(unit_type, 0)
		assert_not_null(texture, "Should have sprite for type: %s" % unit_type)
