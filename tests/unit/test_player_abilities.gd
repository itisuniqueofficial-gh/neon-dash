extends GutTest
## Unit tests for the v0.2.0 player abilities: double jump, dash and the
## interaction of invincibility with hits.

var _player: Player


func before_each() -> void:
	_player = (load("res://scenes/gameplay/Player.tscn") as PackedScene).instantiate() as Player
	add_child_autofree(_player)
	await wait_frames(1)


func after_each() -> void:
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU
	Engine.time_scale = 1.0


# --- Double jump ------------------------------------------------------------


func test_starts_with_full_air_jumps() -> void:
	assert_eq(_player.air_jumps_remaining(), Constants.MAX_AIR_JUMPS)


func test_air_jump_consumes_a_charge() -> void:
	_player._do_air_jump()
	assert_eq(_player.air_jumps_remaining(), Constants.MAX_AIR_JUMPS - 1)


# --- Dash -------------------------------------------------------------------


func test_dash_starts_and_goes_on_cooldown() -> void:
	GameManager.start_run()
	var speed_before := GameManager.speed
	_player.dash()
	assert_true(_player.is_dashing())
	assert_false(_player.dash_ready(), "Dash should be on cooldown right after use")
	assert_gt(GameManager.speed, speed_before, "Dash adds a speed burst")


func test_dash_ignored_while_on_cooldown() -> void:
	GameManager.start_run()
	_player.dash()
	var speed_after_first := GameManager.speed
	_player.dash()  # second dash should be a no-op (still cooling down)
	assert_eq(GameManager.speed, speed_after_first)


func test_dash_grants_iframes() -> void:
	GameManager.start_run()
	_player.dash()
	assert_true(_player.is_invincible(), "Dash grants brief invulnerability")
	_player.hit("block")
	assert_true(_player.is_alive(), "A dashing player ignores a hit")


# --- Invincibility power-up -------------------------------------------------


func test_invincibility_ignores_hits() -> void:
	GameManager.start_run()
	EventBus.powerup_activated.emit(Constants.PowerUp.INVINCIBILITY, 6.0)
	assert_true(_player.is_invincible())
	_player.hit("block")
	assert_true(_player.is_alive())
	EventBus.powerup_expired.emit(Constants.PowerUp.INVINCIBILITY)
	assert_false(_player.is_invincible())


# --- Appearance -------------------------------------------------------------


func test_apply_appearance_sets_override_material() -> void:
	SaveManager.data["selected_skin"] = "gold"
	_player.apply_appearance()
	var mat := _player.mesh_instance.get_surface_override_material(0)
	assert_not_null(mat, "Appearance applies a surface override material")
	if mat is StandardMaterial3D:
		var gold: Dictionary = Catalog.find_skin("gold")
		assert_almost_eq((mat as StandardMaterial3D).albedo_color.r, float(gold["color"].r), 0.05)
