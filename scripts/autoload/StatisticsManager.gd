extends Node
## StatisticsManager
##
## Tracks lifetime player statistics (counters and bests) that back the
## Statistics screen and feed achievements/missions. Statistics live inside the
## save profile under `statistics`, so they persist automatically.
##
## All updates flow through `increment` / `set_max`, which broadcast a
## `statistic_changed` event so listeners (achievements, UI) stay in sync.
##
## Registered as the `StatisticsManager` autoload.

# Known statistic keys. Using constants avoids typos across the codebase.
const RUNS := "runs"
const TOTAL_DISTANCE := "total_distance"
const TOTAL_COINS := "total_coins"
const TOTAL_GEMS := "total_gems"
const TOTAL_JUMPS := "total_jumps"
const TOTAL_SLIDES := "total_slides"
const TOTAL_POWERUPS := "total_powerups"
const NEAR_MISSES := "near_misses"
const LONGEST_RUN := "longest_run"
const BEST_SCORE := "best_score"
const OBSTACLES_DODGED := "obstacles_dodged"


func _ready() -> void:
	EventBus.coin_collected.connect(func(a, _t): increment(TOTAL_COINS, a))
	EventBus.gem_collected.connect(func(a, _t): increment(TOTAL_GEMS, a))
	EventBus.near_miss.connect(func(_id): increment(NEAR_MISSES))
	EventBus.powerup_activated.connect(func(_t, _d): increment(TOTAL_POWERUPS))
	EventBus.run_ended.connect(_on_run_ended)


func _store() -> Dictionary:
	if not SaveManager.data.has("statistics"):
		SaveManager.data["statistics"] = {}
	return SaveManager.data["statistics"]


func get_stat(key: String) -> float:
	return float(_store().get(key, 0))


## Adds `amount` to a counter statistic and broadcasts the new value.
func increment(key: String, amount: float = 1.0) -> void:
	var store := _store()
	store[key] = float(store.get(key, 0)) + amount
	SaveManager.mark_dirty()
	EventBus.statistic_changed.emit(key, store[key])


## Records a value only if it beats the stored maximum (for "best" stats).
func set_max(key: String, value: float) -> void:
	var store := _store()
	if value > float(store.get(key, 0)):
		store[key] = value
		SaveManager.mark_dirty()
		EventBus.statistic_changed.emit(key, value)


func _on_run_ended(result: Dictionary) -> void:
	increment(RUNS)
	increment(TOTAL_DISTANCE, result.get("distance", 0.0))
	set_max(LONGEST_RUN, result.get("distance", 0.0))
	set_max(BEST_SCORE, result.get("score", 0))
	SaveManager.mark_dirty()
