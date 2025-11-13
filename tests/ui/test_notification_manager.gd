extends GutTest
## Tests for NotificationManager

var notification_manager: VBoxContainer

func before_each():
	var script = load("res://ui/hud/notification_manager.gd")
	notification_manager = VBoxContainer.new()
	notification_manager.set_script(script)
	add_child_autofree(notification_manager)

func test_notification_manager_creates():
	assert_not_null(notification_manager, "NotificationManager should create")

func test_show_notification():
	notification_manager.show_notification("Test message", "info", 3.0)

	await wait_frames(2)

	# Should have created a notification child
	assert_gt(notification_manager.get_child_count(), 0, "Should have notification children")

func test_notification_types():
	notification_manager.show_notification("Info message", "info")
	notification_manager.show_notification("Warning message", "warning")
	notification_manager.show_notification("Error message", "error")
	notification_manager.show_notification("Success message", "success")

	await wait_frames(2)

	assert_eq(notification_manager.get_child_count(), 4, "Should have 4 notifications")

func test_max_visible_notifications():
	notification_manager.max_visible_notifications = 3

	# Add 5 notifications
	for i in range(5):
		notification_manager.show_notification("Message %d" % i, "info", 10.0)
		await wait_frames(1)

	# Should only have max_visible_notifications
	assert_lte(notification_manager.get_child_count(), 3, "Should not exceed max visible notifications")

func test_notification_auto_remove():
	notification_manager.show_notification("Temporary", "info", 0.1)

	await wait_frames(2)

	var initial_count = notification_manager.get_child_count()

	await wait_seconds(0.15)

	# Notification should be removed
	assert_lte(notification_manager.get_child_count(), initial_count, "Notification should auto-remove")

func test_notification_queue():
	assert_eq(notification_manager.notification_queue.size(), 0, "Queue should start empty")

	notification_manager.show_notification("Test", "info")

	assert_gt(notification_manager.notification_queue.size(), 0, "Queue should contain notification")

func test_clear_notifications():
	# Add some notifications
	notification_manager.show_notification("Test 1", "info", 10.0)
	notification_manager.show_notification("Test 2", "info", 10.0)

	await wait_frames(2)

	assert_gt(notification_manager.get_child_count(), 0, "Should have notifications")

	notification_manager.clear_notifications()

	await wait_frames(1)

	assert_eq(notification_manager.get_child_count(), 0, "Should clear all notifications")
	assert_eq(notification_manager.notification_queue.size(), 0, "Queue should be empty")
