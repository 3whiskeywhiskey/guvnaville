extends GutTest

# Sample test to verify GUT setup is working correctly
# This test should always pass and serves as a smoke test

func before_all():
	gut.p("Starting test suite")

func after_all():
	gut.p("Test suite completed")

func before_each():
	pass

func after_each():
	pass

func test_assertion_true():
	assert_true(true, "This assertion should always pass")

func test_assertion_false():
	assert_false(false, "This assertion should always pass")

func test_equality():
	assert_eq(1 + 1, 2, "Basic math should work")
	assert_eq("hello", "hello", "String equality should work")

func test_inequality():
	assert_ne(1, 2, "Different numbers should not be equal")
	assert_ne("hello", "world", "Different strings should not be equal")

func test_null_checks():
	var null_var = null
	var not_null_var = "something"
	assert_null(null_var, "Variable should be null")
	assert_not_null(not_null_var, "Variable should not be null")

func test_array_operations():
	var arr = [1, 2, 3, 4, 5]
	assert_eq(arr.size(), 5, "Array should have 5 elements")
	assert_true(arr.has(3), "Array should contain 3")
	assert_false(arr.has(10), "Array should not contain 10")

func test_dictionary_operations():
	var dict = {"key1": "value1", "key2": "value2"}
	assert_true(dict.has("key1"), "Dictionary should have key1")
	assert_eq(dict["key1"], "value1", "key1 should map to value1")

func test_greater_and_lesser():
	assert_gt(10, 5, "10 should be greater than 5")
	assert_lt(5, 10, "5 should be less than 10")
	assert_ge(10, 10, "10 should be greater than or equal to 10")
	assert_le(5, 5, "5 should be less than or equal to 5")
