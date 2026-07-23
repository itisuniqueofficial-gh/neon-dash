extends GutTest
## Unit tests for UnlockService: purchase, ownership and selection logic.

var _backup: Dictionary


func before_each() -> void:
	_backup = SaveManager.data.duplicate(true)
	SaveManager.data = SaveManager.default_data()


func after_each() -> void:
	SaveManager.data = _backup


func test_default_character_is_unlocked() -> void:
	assert_true(UnlockService.is_character_unlocked("runner_default"))


func test_cannot_unlock_without_funds() -> void:
	var result := UnlockService.unlock_character("runner_ember")
	assert_eq(result, UnlockService.Result.INSUFFICIENT_FUNDS)
	assert_false(UnlockService.is_character_unlocked("runner_ember"))


func test_unlock_with_enough_coins() -> void:
	SaveManager.add_coins(10000)
	var result := UnlockService.unlock_character("runner_ember")
	assert_eq(result, UnlockService.Result.SUCCESS)
	assert_true(UnlockService.is_character_unlocked("runner_ember"))


func test_unlock_already_owned() -> void:
	var result := UnlockService.unlock_character("runner_default")
	assert_eq(result, UnlockService.Result.ALREADY_OWNED)


func test_unlock_unknown_returns_not_found() -> void:
	var result := UnlockService.unlock_character("no_such_character")
	assert_eq(result, UnlockService.Result.NOT_FOUND)


func test_select_requires_ownership() -> void:
	assert_false(UnlockService.select_character("runner_midnight"))
	assert_true(UnlockService.select_character("runner_default"))
	assert_eq(SaveManager.data["selected_character"], "runner_default")


func test_gem_purchase_spends_gems() -> void:
	SaveManager.add_gems(100)
	var result := UnlockService.unlock_character("runner_aurora")
	assert_eq(result, UnlockService.Result.SUCCESS)
	assert_lt(SaveManager.get_gems(), 100)
