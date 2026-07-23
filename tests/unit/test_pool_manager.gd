extends GutTest
## Unit tests for PoolManager: acquire/release lifecycle and counters.

const COIN := "res://scenes/collectibles/Coin.tscn"


func test_prewarm_creates_free_instances() -> void:
	PoolManager.prewarm(COIN, 8)
	assert_gte(PoolManager.free_count(COIN), 8)


func test_acquire_decrements_free_increments_active() -> void:
	PoolManager.prewarm(COIN, 4)
	var free_before := PoolManager.free_count(COIN)
	var obj := PoolManager.acquire(COIN)
	assert_not_null(obj)
	assert_eq(PoolManager.free_count(COIN), free_before - 1)
	assert_gte(PoolManager.active_count(COIN), 1)
	PoolManager.release(obj)


func test_release_returns_instance_to_pool() -> void:
	PoolManager.prewarm(COIN, 4)
	var obj := PoolManager.acquire(COIN)
	var active_before := PoolManager.active_count(COIN)
	PoolManager.release(obj)
	assert_eq(PoolManager.active_count(COIN), active_before - 1)


func test_acquire_grows_pool_when_empty() -> void:
	# Drain the pool then acquire once more; it must still return an instance.
	var drained: Array = []
	while PoolManager.free_count(COIN) > 0:
		drained.append(PoolManager.acquire(COIN))
	var extra := PoolManager.acquire(COIN)
	assert_not_null(extra, "Pool grows on demand instead of returning null")
	PoolManager.release(extra)
	for d in drained:
		PoolManager.release(d)


func test_acquire_invalid_scene_returns_null() -> void:
	assert_null(PoolManager.acquire("res://does/not/exist.tscn"))
