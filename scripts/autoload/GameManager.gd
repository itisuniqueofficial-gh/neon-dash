extends Node
## GameManager
##
## The run-time authority for a single play session. It owns transient run
## state (score, distance, coins/gems this run, current speed, active power-up)
## and the high-level run lifecycle: start -> playing -> paused -> game over.
##
## It deliberately holds NO references to gameplay nodes; it communicates
## through the EventBus. Gameplay systems push facts in (coin collected,
## distance advanced) and this manager derives score and broadcasts updates.
##
## Registered as the `GameManager` autoload.

enum State { BOOT, MENU, PLAYING, PAUSED, GAME_OVER }

var state: State = State.BOOT

# --- Transient per-run state ------------------------------------------------
var score: int = 0
var distance: float = 0.0
var run_coins: int = 0
var run_gems: int = 0
var speed: float = 0.0
var difficulty_tier: int = 0
var revived_this_run: bool = false

var _coin_multiplier: int = 1


func _ready() -> void:
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.gem_collected.connect(_on_gem_collected)
	EventBus.powerup_activated.connect(_on_powerup_activated)
	EventBus.powerup_expired.connect(_on_powerup_expired)


## Resets transient state and begins a run.
func start_run() -> void:
	score = 0
	distance = 0.0
	run_coins = 0
	run_gems = 0
	speed = Constants.PLAYER_START_SPEED
	difficulty_tier = 0
	revived_this_run = false
	_coin_multiplier = 1
	state = State.PLAYING
	get_tree().paused = false
	EventBus.run_started.emit()
	EventBus.score_updated.emit(score)
	AudioManager.play_music("gameplay")


## Advances the run each physics frame. `delta` is the frame time. Returns the
## distance travelled this frame so the world can scroll consistently.
func advance(delta: float) -> float:
	if state != State.PLAYING:
		return 0.0
	# Accelerate toward max speed.
	speed = minf(speed + Constants.PLAYER_ACCELERATION * delta, Constants.PLAYER_MAX_SPEED)
	var step := speed * delta
	distance += step
	score = int(distance * Constants.SCORE_PER_METER) \
		+ run_coins * Constants.SCORE_PER_COIN \
		+ run_gems * Constants.SCORE_PER_GEM

	var new_tier := Constants.difficulty_tier(distance)
	if new_tier != difficulty_tier:
		difficulty_tier = new_tier
		EventBus.difficulty_changed.emit(difficulty_tier)

	EventBus.distance_updated.emit(distance)
	EventBus.score_updated.emit(score)
	EventBus.speed_changed.emit(speed)
	return step


func pause_run() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	get_tree().paused = true
	EventBus.run_paused.emit()


func resume_run() -> void:
	if state != State.PAUSED:
		return
	state = State.PLAYING
	get_tree().paused = false
	EventBus.run_resumed.emit()


## Ends the run, commits currency and stats to the save, and broadcasts result.
func end_run(cause: String = "collision") -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	get_tree().paused = false

	SaveManager.add_coins(run_coins)
	SaveManager.add_gems(run_gems)
	var new_high := SaveManager.record_run(score, distance)

	var result := {
		"score": score,
		"distance": distance,
		"coins": run_coins,
		"gems": run_gems,
		"new_high_score": new_high,
		"cause": cause,
	}
	EventBus.player_died.emit(cause)
	EventBus.run_ended.emit(result)
	AudioManager.play_sfx("gameover")
	AudioManager.stop_music()
	SaveManager.save_game()


## Grants a one-time revive within a run (e.g., via rewarded continue).
func revive() -> void:
	if revived_this_run:
		return
	revived_this_run = true
	state = State.PLAYING
	get_tree().paused = false
	EventBus.player_revived.emit()


func is_playing() -> bool:
	return state == State.PLAYING


func _on_coin_collected(_amount: int, _total: int) -> void:
	run_coins += Constants.COIN_VALUE * _coin_multiplier


func _on_gem_collected(_amount: int, _total: int) -> void:
	run_gems += Constants.GEM_VALUE


func _on_powerup_activated(type: int, _duration: float) -> void:
	if type == Constants.PowerUp.DOUBLE_COINS:
		_coin_multiplier = 2
	elif type == Constants.PowerUp.SPEED_BOOST:
		speed = minf(speed * Constants.POWERUP_SPEED_BOOST_MULTIPLIER, Constants.PLAYER_MAX_SPEED)


func _on_powerup_expired(type: int) -> void:
	if type == Constants.PowerUp.DOUBLE_COINS:
		_coin_multiplier = 1
