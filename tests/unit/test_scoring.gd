extends GutTest
## Unit tests for GameManager scoring and run lifecycle.


func before_each() -> void:
	GameManager.start_run()


func after_each() -> void:
	# Ensure we never leave the tree paused between tests.
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU


func test_start_run_resets_state() -> void:
	assert_eq(GameManager.distance, 0.0)
	assert_eq(GameManager.run_coins, 0)
	assert_eq(GameManager.score, 0)
	assert_true(GameManager.is_playing())
	assert_almost_eq(GameManager.speed, Constants.PLAYER_START_SPEED, 0.001)


func test_advance_accumulates_distance() -> void:
	var moved := GameManager.advance(0.1)
	assert_gt(moved, 0.0)
	assert_gt(GameManager.distance, 0.0)


func test_advance_does_nothing_when_not_playing() -> void:
	GameManager.state = GameManager.State.GAME_OVER
	var moved := GameManager.advance(0.1)
	assert_eq(moved, 0.0)


func test_speed_never_exceeds_max() -> void:
	for i in 10000:
		GameManager.advance(0.1)
	assert_lte(GameManager.speed, Constants.PLAYER_MAX_SPEED + 0.001)


func test_coins_increase_score() -> void:
	var base := GameManager.score
	EventBus.coin_collected.emit(1, 1)  # routed to GameManager
	GameManager.advance(0.001)
	assert_gt(GameManager.run_coins, 0)


func test_pause_and_resume() -> void:
	GameManager.pause_run()
	assert_eq(GameManager.state, GameManager.State.PAUSED)
	assert_true(get_tree().paused)
	GameManager.resume_run()
	assert_eq(GameManager.state, GameManager.State.PLAYING)
	assert_false(get_tree().paused)
