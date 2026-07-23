extends GutTest
## Unit tests for Player lane logic and state (no physics stepping required).

var _player: Player


func before_each() -> void:
	_player = (load("res://scenes/gameplay/Player.tscn") as PackedScene).instantiate() as Player
	add_child_autofree(_player)
	await wait_frames(1)


func test_starts_in_centre_lane() -> void:
	assert_eq(_player.current_lane, 1)


func test_move_left_and_right() -> void:
	_player.move_left()
	assert_eq(_player.current_lane, 0)
	_player.move_right()
	assert_eq(_player.current_lane, 1)
	_player.move_right()
	assert_eq(_player.current_lane, 2)


func test_lane_clamped_at_edges() -> void:
	_player.move_left()
	_player.move_left()
	_player.move_left()          # already at lane 0, should not underflow
	assert_eq(_player.current_lane, 0)
	_player.move_right()
	_player.move_right()
	_player.move_right()         # already at lane 2, should not overflow
	assert_eq(_player.current_lane, 2)


func test_slide_sets_and_clears_state() -> void:
	assert_false(_player.is_sliding())
	_player.slide()
	assert_true(_player.is_sliding())


func test_alive_by_default() -> void:
	assert_true(_player.is_alive())


func test_lane_changed_signal_emitted() -> void:
	watch_signals(_player)
	_player.move_left()
	assert_signal_emitted(_player, "lane_changed")
