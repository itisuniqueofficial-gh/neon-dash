extends Node
## MissionManager
##
## Generates and tracks a rotating set of daily missions (offline). Missions
## are short-term goals such as "collect 50 coins" or "run 1000 m". They reset
## once per calendar day (device local time) and award coins on completion.
##
## Mission state lives in the save profile under `missions`:
##   { day_stamp: String, active: Array[Dictionary] }
## where each active mission is
##   { id, template, description, target, progress, reward, completed }
##
## Registered as the `MissionManager` autoload.

const MISSIONS_PER_DAY: int = 3

# Templates missions are generated from. Each maps to a statistic delta measured
# within the current day via a baseline snapshot.
var _templates: Array = [
	{"id": "coins", "stat": StatisticsManager.TOTAL_COINS, "desc": "Collect %d coins", "target": 50, "reward": 100},
	{"id": "distance", "stat": StatisticsManager.TOTAL_DISTANCE, "desc": "Run %d metres", "target": 1500, "reward": 120},
	{"id": "runs", "stat": StatisticsManager.RUNS, "desc": "Complete %d runs", "target": 3, "reward": 80},
	{"id": "gems", "stat": StatisticsManager.TOTAL_GEMS, "desc": "Collect %d gems", "target": 5, "reward": 150},
	{"id": "jumps", "stat": StatisticsManager.TOTAL_JUMPS, "desc": "Jump %d times", "target": 40, "reward": 60},
	{"id": "powerups", "stat": StatisticsManager.TOTAL_POWERUPS, "desc": "Use %d power-ups", "target": 3, "reward": 90},
]


func _ready() -> void:
	_ensure_today()
	EventBus.statistic_changed.connect(_on_statistic_changed)


func _store() -> Dictionary:
	if not SaveManager.data.has("missions"):
		SaveManager.data["missions"] = {}
	return SaveManager.data["missions"]


func _today_stamp() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## Ensures today's missions exist; regenerates them at the start of a new day.
func _ensure_today() -> void:
	var store := _store()
	if store.get("day_stamp", "") != _today_stamp():
		_generate()


func _generate() -> void:
	var store := _store()
	var pool := _templates.duplicate()
	pool.shuffle()
	var active: Array = []
	for i in mini(MISSIONS_PER_DAY, pool.size()):
		var t: Dictionary = pool[i]
		active.append({
			"id": t["id"],
			"stat": t["stat"],
			"description": t["desc"] % t["target"],
			"target": t["target"],
			"baseline": StatisticsManager.get_stat(t["stat"]),
			"progress": 0,
			"reward": t["reward"],
			"completed": false,
		})
	store["day_stamp"] = _today_stamp()
	store["active"] = active
	SaveManager.mark_dirty()
	EventBus.missions_refreshed.emit()


func list_active() -> Array:
	_ensure_today()
	return _store().get("active", [])


func _on_statistic_changed(key: String, _value: Variant) -> void:
	_ensure_today()
	var active: Array = _store().get("active", [])
	for m in active:
		if m["stat"] == key and not m["completed"]:
			var delta := StatisticsManager.get_stat(key) - float(m["baseline"])
			m["progress"] = int(clampf(delta, 0, float(m["target"])))
			if m["progress"] >= int(m["target"]):
				m["completed"] = true
				SaveManager.add_coins(int(m["reward"]))
				EventBus.mission_completed.emit(m["id"], int(m["reward"]))
			SaveManager.mark_dirty()
