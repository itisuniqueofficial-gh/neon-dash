extends GutTest
## Unit tests for DailyRewardManager streak and reward math.

var _backup: Dictionary


func before_each() -> void:
	_backup = SaveManager.data.duplicate(true)
	SaveManager.data = SaveManager.default_data()


func after_each() -> void:
	SaveManager.data = _backup


func test_reward_available_on_fresh_profile() -> void:
	assert_true(DailyRewardManager.is_available())


func test_reward_scales_with_day() -> void:
	assert_eq(DailyRewardManager.reward_for_day(1), Constants.DAILY_REWARD_BASE)
	assert_gt(DailyRewardManager.reward_for_day(3), DailyRewardManager.reward_for_day(1))


func test_reward_is_capped() -> void:
	var capped := DailyRewardManager.reward_for_day(999)
	var at_max := DailyRewardManager.reward_for_day(Constants.DAILY_REWARD_MAX_DAY)
	assert_eq(capped, at_max)


func test_claim_grants_coins_and_blocks_second_claim() -> void:
	var before := SaveManager.get_coins()
	var granted := DailyRewardManager.claim()
	assert_gt(granted, 0)
	assert_eq(SaveManager.get_coins(), before + granted)
	assert_false(DailyRewardManager.is_available(), "Only one claim per day")
	assert_eq(DailyRewardManager.claim(), 0)
