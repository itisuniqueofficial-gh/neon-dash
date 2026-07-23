extends GutTest
## Performance tests. These are guard-rails, not micro-benchmarks: they assert
## that high-churn pooling stays within a generous time budget and does not leak
## instances, which protects the 60 FPS target on low-end Android devices.

const COIN := "res://scenes/collectibles/Coin.tscn"
const OBSTACLE := "res://scenes/obstacles/Obstacle.tscn"


func test_pool_churn_is_leak_free() -> void:
	PoolManager.prewarm(COIN, 64)
	var start_active := PoolManager.active_count(COIN)
	# Simulate many frames of acquire/release cycles.
	for cycle in 500:
		var batch: Array = []
		for i in 20:
			batch.append(PoolManager.acquire(COIN))
		for obj in batch:
			PoolManager.release(obj)
	assert_eq(
		PoolManager.active_count(COIN),
		start_active,
		"All acquired instances must be returned (no leak)"
	)


func test_pool_acquire_release_within_budget() -> void:
	PoolManager.prewarm(OBSTACLE, 48)
	var iterations := 10000
	var start := Time.get_ticks_usec()
	for i in iterations:
		var o := PoolManager.acquire(OBSTACLE)
		PoolManager.release(o)
	var elapsed_ms := (Time.get_ticks_usec() - start) / 1000.0
	gut.p("Pool churn %d iterations took %.2f ms" % [iterations, elapsed_ms])
	# Very generous ceiling; real hardware is far faster. Catches O(n) regressions.
	assert_lt(elapsed_ms, 2000.0, "Pooling should be cheap")


func test_prewarm_reuses_without_reallocating() -> void:
	PoolManager.prewarm(COIN, 32)
	var free_after_prewarm := PoolManager.free_count(COIN)
	var a := PoolManager.acquire(COIN)
	PoolManager.release(a)
	assert_eq(
		PoolManager.free_count(COIN),
		free_after_prewarm,
		"Acquire+release should not change the total pool size"
	)
