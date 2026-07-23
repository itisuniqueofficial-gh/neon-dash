extends GutTest
## Unit tests for AchievementManager progress tracking and unlocking.

var _backup: Dictionary


func before_each() -> void:
	_backup = SaveManager.data.duplicate(true)
	SaveManager.data = SaveManager.default_data()
	AchievementManager._build_catalogue()


func after_each() -> void:
	SaveManager.data = _backup


func test_catalogue_is_populated() -> void:
	assert_gt(AchievementManager.catalogue.size(), 0)
	assert_has(AchievementManager.catalogue, "first_steps")


func test_achievement_starts_locked() -> void:
	assert_false(AchievementManager.is_unlocked("marathoner"))


func test_progress_updates_from_statistic() -> void:
	# 'first_steps' watches the RUNS stat with target 1.
	AchievementManager._on_statistic_changed(StatisticsManager.RUNS, 1)
	assert_true(AchievementManager.is_unlocked("first_steps"))


func test_reward_granted_on_unlock() -> void:
	var before := SaveManager.get_coins()
	AchievementManager._on_statistic_changed(StatisticsManager.RUNS, 1)
	assert_gt(SaveManager.get_coins(), before, "Unlocking pays out its reward")


func test_list_for_ui_merges_state() -> void:
	var list := AchievementManager.list_for_ui()
	assert_gt(list.size(), 0)
	for a in list:
		assert_has(a, "unlocked")
		assert_has(a, "progress")
		assert_has(a, "target")
