extends Node
## SaveManager
##
## Owns the persistent player profile: currency, high score, progression,
## unlocks, statistics, achievements and missions state. Responsibilities:
##   - Provide a single in-memory `data` dictionary that other managers read.
##   - Persist atomically to disk (write temp -> validate -> replace) with a
##     rolling backup, so a crash mid-write can never brick the save.
##   - Recover gracefully from corrupted or missing files by falling back to
##     the backup, then to a fresh default profile.
##   - Migrate older save formats forward via `SAVE_FORMAT_VERSION`.
##
## Registered as the `SaveManager` autoload. It must load before managers that
## depend on it (ordering handled in project.godot).

var data: Dictionary = {}
var _dirty: bool = false
var _autosave_accumulator: float = 0.0
const AUTOSAVE_INTERVAL: float = 15.0


func _ready() -> void:
	load_game()
	# Persist on quit / app suspend so Android task-switching never loses data.
	get_tree().set_auto_accept_quit(false)


func _process(delta: float) -> void:
	if _dirty:
		_autosave_accumulator += delta
		if _autosave_accumulator >= AUTOSAVE_INTERVAL:
			save_game()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_CRASH:
			if _dirty:
				save_game()
			if what == NOTIFICATION_WM_CLOSE_REQUEST:
				get_tree().quit()


## Returns a freshly initialised default profile. Kept in one place so schema
## changes are easy to audit.
func default_data() -> Dictionary:
	return {
		"format_version": Constants.SAVE_FORMAT_VERSION,
		"coins": 0,
		"gems": 0,
		"high_score": 0,
		"best_distance": 0.0,
		"total_distance": 0.0,
		"total_coins_collected": 0,
		"total_gems_collected": 0,
		"total_runs": 0,
		"selected_character": "runner_default",
		"selected_skin": "default",
		"unlocked_characters": ["runner_default"],
		"unlocked_skins": ["default"],
		"unlocked_powerup_levels": {},
		"achievements": {},  # id -> { unlocked: bool, progress: int }
		"missions": {},  # daily mission state
		"statistics": {},  # arbitrary counters
		"daily_reward":
		{
			"last_claim_unix": 0,
			"streak": 0,
		},
		"created_unix": int(Time.get_unix_time_from_system()),
	}


## Loads the save file. Falls back to backup, then defaults. Never throws.
func load_game() -> void:
	var loaded := _read_json(Constants.SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_json(Constants.SAVE_BACKUP_PATH)
		if not loaded.is_empty():
			push_warning("SaveManager: primary save missing/corrupt, recovered from backup.")
			EventBus.save_corrupted_recovered.emit()
	if loaded.is_empty():
		data = default_data()
		save_game()
	else:
		data = _migrate(loaded)
	EventBus.save_loaded.emit()
	EventBus.currency_changed.emit(get_coins(), get_gems())


## Atomically writes the current data to disk with a backup rotation.
func save_game() -> bool:
	# Rotate current save to backup before overwriting.
	if FileAccess.file_exists(Constants.SAVE_PATH):
		_copy_file(Constants.SAVE_PATH, Constants.SAVE_BACKUP_PATH)

	var tmp_path := Constants.SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		var reason := "cannot open temp save (%d)" % FileAccess.get_open_error()
		push_error("SaveManager: " + reason)
		EventBus.save_failed.emit(reason)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

	# Validate the temp file parses before promoting it to the real save.
	if _read_json(tmp_path).is_empty():
		EventBus.save_failed.emit("temp save failed validation")
		return false

	var da := DirAccess.open("user://")
	if da != null:
		da.remove(Constants.SAVE_PATH)
		da.rename(tmp_path, Constants.SAVE_PATH)
	_dirty = false
	_autosave_accumulator = 0.0
	EventBus.save_completed.emit()
	return true


## Marks the save dirty so it will be flushed by the autosave timer or on quit.
func mark_dirty() -> void:
	_dirty = true


# --- Convenience accessors --------------------------------------------------


func get_coins() -> int:
	return int(data.get("coins", 0))


func get_gems() -> int:
	return int(data.get("gems", 0))


## Adds coins (can be negative to spend). Returns final balance, never below 0.
func add_coins(amount: int) -> int:
	data["coins"] = maxi(0, get_coins() + amount)
	mark_dirty()
	EventBus.currency_changed.emit(get_coins(), get_gems())
	return get_coins()


func add_gems(amount: int) -> int:
	data["gems"] = maxi(0, get_gems() + amount)
	mark_dirty()
	EventBus.currency_changed.emit(get_coins(), get_gems())
	return get_gems()


## Attempts to spend `cost` coins. Returns true on success (sufficient funds).
func spend_coins(cost: int) -> bool:
	if get_coins() < cost:
		return false
	add_coins(-cost)
	return true


func spend_gems(cost: int) -> bool:
	if get_gems() < cost:
		return false
	add_gems(-cost)
	return true


func get_high_score() -> int:
	return int(data.get("high_score", 0))


## Records a run's results, updating bests. Returns true if a new high score.
func record_run(score: int, distance: float) -> bool:
	data["total_runs"] = int(data.get("total_runs", 0)) + 1
	data["total_distance"] = float(data.get("total_distance", 0.0)) + distance
	var new_high := false
	if score > get_high_score():
		data["high_score"] = score
		new_high = true
	if distance > float(data.get("best_distance", 0.0)):
		data["best_distance"] = distance
	mark_dirty()
	return new_high


func reset_all() -> void:
	data = default_data()
	save_game()
	EventBus.save_loaded.emit()
	EventBus.currency_changed.emit(get_coins(), get_gems())


# --- Internal helpers -------------------------------------------------------


## Reads and parses a JSON file. Returns {} on any error (missing/corrupt).
func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	if text.strip_edges().is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _copy_file(from: String, to: String) -> void:
	var da := DirAccess.open("user://")
	if da != null:
		da.copy(from, to)


## Migrates an older save dictionary to the current schema. Missing keys are
## backfilled from defaults so new fields never crash older profiles.
func _migrate(loaded: Dictionary) -> Dictionary:
	var version := int(loaded.get("format_version", 0))
	var base := default_data()
	# Deep-merge: keep loaded values, add any missing default keys.
	for key in base.keys():
		if not loaded.has(key):
			loaded[key] = base[key]
	if version < Constants.SAVE_FORMAT_VERSION:
		loaded["format_version"] = Constants.SAVE_FORMAT_VERSION
	return loaded
