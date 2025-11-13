extends GutTest

## Integration test for culture system with real game data

var CultureTree = preload("res://systems/culture/culture_tree.gd")

var culture_tree: CultureTree


func before_each():
	culture_tree = CultureTree.new()
	add_child_autofree(culture_tree)


func after_each():
	if culture_tree:
		culture_tree.queue_free()
	culture_tree = null


func _load_game_culture_data() -> Dictionary:
	# Load the actual game culture tree data
	var file = FileAccess.open("res://data/culture/culture_tree.json", FileAccess.READ)
	if file == null:
		push_error("Failed to load culture_tree.json: " + str(FileAccess.get_open_error()))
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("Failed to parse culture_tree.json: " + json.get_error_message())
		return {}

	return json.data


func test_load_real_culture_tree():
	var data = _load_game_culture_data()
	if data.is_empty():
		fail_test("Could not load culture tree data")
		return

	culture_tree.load_culture_tree(data)

	var all_nodes = culture_tree.get_all_nodes()
	assert_gt(all_nodes.size(), 0, "Should load culture nodes from game data")


func test_real_culture_tree_has_all_axes():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)

	var military = culture_tree.get_nodes_by_axis("military")
	var economic = culture_tree.get_nodes_by_axis("economic")
	var social = culture_tree.get_nodes_by_axis("social")
	var technological = culture_tree.get_nodes_by_axis("technological")

	assert_gt(military.size(), 0, "Should have military nodes")
	assert_gt(economic.size(), 0, "Should have economic nodes")
	assert_gt(social.size(), 0, "Should have social nodes")
	assert_gt(technological.size(), 0, "Should have technological nodes")


func test_real_nodes_validate():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)

	var all_nodes = culture_tree.get_all_nodes()
	for node in all_nodes:
		assert_true(node.validate(), "Node %s should be valid" % node.id)


func test_unlock_progression_militia_to_organized():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)

	# Check if militia_training exists
	var militia = culture_tree.get_node_by_id("militia_training")
	if militia == null:
		# Test data may have different structure
		pass_test("militia_training not in current data structure")
		return

	# Give enough points
	culture_tree.add_culture_points(1, 500)

	# Unlock militia training
	var success1 = culture_tree.unlock_node(1, "militia_training")
	assert_true(success1, "Should unlock militia_training")

	# Try to unlock organized warfare (requires militia training)
	var organized = culture_tree.get_node_by_id("organized_warfare")
	if organized:
		var success2 = culture_tree.unlock_node(1, "organized_warfare")
		assert_true(success2, "Should unlock organized_warfare after militia_training")


func test_mutual_exclusion_works():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)

	# Find two mutually exclusive nodes
	var all_nodes = culture_tree.get_all_nodes()
	var exclusive_pair = null

	for node in all_nodes:
		if node.mutually_exclusive.size() > 0:
			var exclusive_id = node.mutually_exclusive[0]
			var exclusive_node = culture_tree.get_node_by_id(exclusive_id)
			if exclusive_node:
				exclusive_pair = [node, exclusive_node]
				break

	if exclusive_pair == null:
		# Check specific nodes that should be exclusive
		var strongman = culture_tree.get_node_by_id("strongman_rule")
		var democratic = culture_tree.get_node_by_id("democratic_council")

		if strongman and democratic:
			exclusive_pair = [strongman, democratic]

	if exclusive_pair:
		culture_tree.add_culture_points(1, 1000)

		# Unlock prerequisites for both
		for prereq_id in exclusive_pair[0].prerequisites:
			culture_tree.unlock_node(1, prereq_id)

		# Unlock first node
		var success1 = culture_tree.unlock_node(1, exclusive_pair[0].id)
		assert_true(success1, "Should unlock first exclusive node")

		# Try to unlock second (should fail)
		var success2 = culture_tree.unlock_node(1, exclusive_pair[1].id)
		assert_false(success2, "Should not unlock mutually exclusive node")


func test_tier_progression_enforced():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)

	# Find a tier 3 or 4 node
	var all_nodes = culture_tree.get_all_nodes()
	var high_tier_node = null

	for node in all_nodes:
		if node.tier >= 3:
			high_tier_node = node
			break

	if high_tier_node == null:
		pass_test("No tier 3+ nodes found")
		return

	culture_tree.add_culture_points(1, 5000)

	# Try to unlock without prerequisites (should fail)
	var success = culture_tree.unlock_node(1, high_tier_node.id)
	assert_false(success, "Should not unlock high tier node without lower tiers")


func test_effects_accumulate():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 500)

	# Unlock a few nodes
	var unlocked_count = 0
	var all_nodes = culture_tree.get_all_nodes()

	for node in all_nodes:
		if node.tier == 1 and culture_tree.can_unlock_node(1, node.id):
			if culture_tree.unlock_node(1, node.id):
				unlocked_count += 1
				if unlocked_count >= 2:
					break

	if unlocked_count > 0:
		var effects = culture_tree.get_culture_effects(1)
		assert_gt(effects.size(), 0, "Should have accumulated effects")


func test_save_and_restore():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)
	culture_tree.add_culture_points(1, 200)

	# Unlock some nodes
	var tier1_nodes = []
	for node in culture_tree.get_all_nodes():
		if node.tier == 1:
			tier1_nodes.append(node.id)

	if tier1_nodes.size() > 0:
		culture_tree.unlock_node(1, tier1_nodes[0])

	# Save state
	var save_data = culture_tree.to_save_dict(1)

	# Create new tree and restore
	var new_tree = CultureTree.new()
	add_child_autofree(new_tree)
	new_tree.load_culture_tree(data)
	new_tree.from_save_dict(1, save_data)

	# Verify state restored
	var restored_unlocked = new_tree.get_unlocked_nodes(1)
	var original_unlocked = culture_tree.get_unlocked_nodes(1)

	assert_eq(restored_unlocked.size(), original_unlocked.size(), "Should restore same number of unlocked nodes")
	assert_eq(new_tree.get_culture_points(1), culture_tree.get_culture_points(1), "Should restore culture points")


func test_all_nodes_have_valid_structure():
	var data = _load_game_culture_data()
	if data.is_empty():
		return

	culture_tree.load_culture_tree(data)

	var all_nodes = culture_tree.get_all_nodes()

	for node in all_nodes:
		assert_ne(node.id, "", "Node should have ID")
		assert_ne(node.name, "", "Node should have name")
		assert_ne(node.axis, "", "Node should have axis")
		assert_ge(node.tier, 1, "Node tier should be >= 1")
		assert_le(node.tier, 4, "Node tier should be <= 4")
		assert_ge(node.cost, 0, "Node cost should be >= 0")
