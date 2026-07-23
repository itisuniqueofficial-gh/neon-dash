extends Node
## AchievementManager
##
## Defines the achievement catalogue and evaluates progress against player
## statistics and run events. Achievement state (unlocked flag + progress) is
## stored in the save profile under `achievements`.
##
## Each achievement is data-driven: an id, title, description, a statistic key
## to watch, a target value, and a coin reward. This keeps adding achievements
## a pure data change with no new code paths.
##
## Registered as the `AchievementManager` autoload.

# id -> definition
var catalogue: Dictionary = {}


func _ready() -> void:
	_build_catalogue()
	EventBus.statistic_changed.connect(_on_statistic_changed)
	EventBus.run_ended.connect(_on_run_ended)


func _build_catalogue() -> void:
	catalogue = {
		"first_steps": _def("first_steps", "First Steps", "Finish your first run.",
			StatisticsManager.RUNS, 1, 50),
		"marathoner": _def("marathoner", "Marathoner", "Run 10,000 metres in total.",
			StatisticsManager.TOTAL_DISTANCE, 10000, 250),
		"coin_hoarder": _def("coin_hoarder", "Coin Hoarder", "Collect 1,000 coins.",
			StatisticsManager.TOTAL_COINS, 1000, 200),
		"gem_collector": _def("gem_collector", "Gem Collector", "Collect 100 gems.",
			StatisticsManager.TOTAL_GEMS, 100, 300),
		"acrobat": _def("acrobat", "Acrobat", "Jump 500 times.",
			StatisticsManager.TOTAL_JUMPS, 500, 150),
		"close_call": _def("close_call", "Close Call", "Pull off 50 near misses.",
			StatisticsManager.NEAR_MISSES, 50, 200),
		"power_player": _def("power_player", "Power Player", "Use 100 power-ups.",
			StatisticsManager.TOTAL_POWERUPS, 100, 200),
		"long_hauler": _def("long_hauler", "Long Hauler", "Reach 2,000 m in a single run.",
			StatisticsManager.LONGEST_RUN, 2000, 500),
		"veteran": _def("veteran", "Veteran", "Complete 100 runs.",
			StatisticsManager.RUNS, 100, 500),
	}
	# Ensure every achievement has a state entry.
	var store := _store()
	for id in catalogue.keys():
		if not store.has(id):
			store[id] = {"unlocked": false, "progress": 0}


func _def(id: String, title: String, desc: String, stat_key: String, target: int, reward: int) -> Dictionary:
	return {"id": id, "title": title, "description": desc,
		"stat_key": stat_key, "target": target, "reward": reward}


func _store() -> Dictionary:
	if not SaveManager.data.has("achievements"):
		SaveManager.data["achievements"] = {}
	return SaveManager.data["achievements"]


func is_unlocked(id: String) -> bool:
	return bool(_store().get(id, {}).get("unlocked", false))


func get_progress(id: String) -> int:
	return int(_store().get(id, {}).get("progress", 0))


## Returns an array of definition dictionaries merged with live state, for UI.
func list_for_ui() -> Array:
	var out: Array = []
	for id in catalogue.keys():
		var d: Dictionary = catalogue[id].duplicate()
		d["unlocked"] = is_unlocked(id)
		d["progress"] = mini(get_progress(id), int(d["target"]))
		out.append(d)
	return out


func _on_statistic_changed(key: String, value: Variant) -> void:
	for id in catalogue.keys():
		var def: Dictionary = catalogue[id]
		if def["stat_key"] == key and not is_unlocked(id):
			_update(id, int(value))


func _on_run_ended(_result: Dictionary) -> void:
	# Re-evaluate every achievement against current stats at run end as a safety
	# net for events that may not have fired incrementally.
	for id in catalogue.keys():
		if not is_unlocked(id):
			var def: Dictionary = catalogue[id]
			_update(id, int(StatisticsManager.get_stat(def["stat_key"])))


func _update(id: String, current: int) -> void:
	var def: Dictionary = catalogue[id]
	var store := _store()
	store[id]["progress"] = current
	EventBus.achievement_progress.emit(id, current, int(def["target"]))
	if current >= int(def["target"]):
		store[id]["unlocked"] = true
		SaveManager.add_coins(int(def["reward"]))
		SaveManager.mark_dirty()
		AudioManager.play_sfx("unlock")
		EventBus.achievement_unlocked.emit(id)
	SaveManager.mark_dirty()
