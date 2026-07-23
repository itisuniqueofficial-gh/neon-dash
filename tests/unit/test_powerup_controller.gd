extends GutTest
## Unit tests for PowerUpController, focused on the Slow-Motion power-up's
## global time_scale side effect and its guaranteed restoration.

var _controller: PowerUpController


func before_each() -> void:
	_controller = PowerUpController.new()
	add_child_autofree(_controller)
	await wait_frames(1)
	Engine.time_scale = 1.0


func after_each() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU


func test_slow_motion_lowers_time_scale() -> void:
	EventBus.powerup_activated.emit(Constants.PowerUp.SLOW_MOTION, 5.0)
	assert_almost_eq(Engine.time_scale, Constants.POWERUP_SLOW_MOTION_SCALE, 0.001)
	assert_true(_controller.is_active(Constants.PowerUp.SLOW_MOTION))


func test_time_scale_restored_on_run_end() -> void:
	EventBus.powerup_activated.emit(Constants.PowerUp.SLOW_MOTION, 5.0)
	assert_lt(Engine.time_scale, 1.0)
	EventBus.run_ended.emit({"score": 0, "distance": 0.0, "coins": 0, "gems": 0})
	assert_almost_eq(Engine.time_scale, 1.0, 0.001, "Never leave the game slowed")


func test_run_start_resets_time_scale() -> void:
	Engine.time_scale = 0.4
	EventBus.run_started.emit()
	assert_almost_eq(Engine.time_scale, 1.0, 0.001)


func test_remaining_reports_active_duration() -> void:
	EventBus.powerup_activated.emit(Constants.PowerUp.MAGNET, 8.0)
	assert_almost_eq(_controller.remaining(Constants.PowerUp.MAGNET), 8.0, 0.001)
	assert_eq(_controller.remaining(Constants.PowerUp.SHIELD), 0.0)
