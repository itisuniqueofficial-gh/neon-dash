extends GutTest
## Integration tests for procedural world spawning via ChunkManager.

var _cm: ChunkManager


func before_each() -> void:
	_cm = ChunkManager.new()
	add_child_autofree(_cm)
	await wait_frames(2)   # allow _ready + pool prewarm


func after_each() -> void:
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU


func test_reset_world_spawns_full_window() -> void:
	_cm.reset_world()
	assert_eq(_cm.active_chunk_count(), Constants.CHUNKS_AHEAD,
		"A fresh world keeps CHUNKS_AHEAD chunks live")


func test_scrolling_recycles_chunks() -> void:
	GameManager.start_run()
	_cm.reset_world()
	var initial := _cm.active_chunk_count()
	# Scroll far enough to push several chunks behind the player.
	for i in 240:
		_cm._scroll(Constants.CHUNK_LENGTH * 0.1)
	# The rolling window size stays roughly constant (chunks are recycled, not
	# accumulated), proving the pool is reused rather than leaking.
	assert_almost_eq(_cm.active_chunk_count(), initial, 2,
		"Window size stays bounded while scrolling")


func test_obstacle_scene_pool_is_prewarmed() -> void:
	assert_gt(PoolManager.free_count(ChunkManager.OBSTACLE_PATH)
		+ PoolManager.active_count(ChunkManager.OBSTACLE_PATH), 0,
		"Obstacle pool is populated at startup")
