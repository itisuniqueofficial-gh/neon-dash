extends GutTest
## Integration tests for collection and collision behaviour. Rather than relying
## on physics stepping (non-deterministic in headless CI), these exercise the
## overlap callbacks directly with a stand-in player node in the "player" group.

const COIN := "res://scenes/collectibles/Coin.tscn"
const OBSTACLE := "res://scenes/obstacles/Obstacle.tscn"


func _make_fake_player() -> Node3D:
	var p := Node3D.new()
	p.add_to_group("player")
	add_child_autofree(p)
	return p


func test_coin_emits_collected_and_releases() -> void:
	GameManager.start_run()
	var coin := (load(COIN) as PackedScene).instantiate()
	add_child_autofree(coin)
	coin.set_meta(PoolManager.META_SCENE_PATH, COIN)

	watch_signals(EventBus)
	var player := _make_fake_player()
	coin._on_body_entered(player)

	assert_signal_emitted(EventBus, "coin_collected")
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU


func test_coin_only_collected_once() -> void:
	GameManager.start_run()
	var coin := (load(COIN) as PackedScene).instantiate()
	add_child_autofree(coin)
	coin.set_meta(PoolManager.META_SCENE_PATH, COIN)
	var player := _make_fake_player()

	var before := GameManager.run_coins
	coin._on_body_entered(player)
	coin._on_body_entered(player)  # second overlap must be ignored
	assert_eq(GameManager.run_coins - before, 1, "Coin grants exactly once")
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU


func test_full_obstacle_reports_hit() -> void:
	var obs := (load(OBSTACLE) as PackedScene).instantiate() as Obstacle
	obs.obstacle_type = Obstacle.ObstacleType.FULL
	add_child_autofree(obs)

	# Spawn the player far from the obstacle so the physics server does not fire
	# body_entered automatically; we drive the callback manually and
	# deterministically below.
	var player := (load("res://scenes/gameplay/Player.tscn") as PackedScene).instantiate() as Player
	player.position = Vector3(100, 1, 100)
	add_child_autofree(player)
	await wait_frames(2)

	watch_signals(EventBus)
	obs._on_body_entered(player)
	assert_signal_emitted(EventBus, "obstacle_hit")
