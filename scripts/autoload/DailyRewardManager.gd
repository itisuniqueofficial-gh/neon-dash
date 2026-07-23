extends Node
## DailyRewardManager
##
## Offline daily-login reward with a streak. Uses device local calendar days
## (not wall-clock seconds) so a reward becomes available once per new day.
## The streak grows on consecutive days and resets if a day is skipped, capping
## at `DAILY_REWARD_MAX_DAY`. Reward amount scales with the streak day.
##
## State is stored in the save profile under `daily_reward`:
##   { last_claim_stamp: String, streak: int }
##
## Registered as the `DailyRewardManager` autoload.


func _ready() -> void:
	# Announce availability shortly after boot so menus can show a badge.
	call_deferred("_emit_availability")


func _store() -> Dictionary:
	if not SaveManager.data.has("daily_reward"):
		SaveManager.data["daily_reward"] = {"last_claim_stamp": "", "streak": 0}
	return SaveManager.data["daily_reward"]


func _today_stamp() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


func _yesterday_stamp() -> String:
	var unix := Time.get_unix_time_from_system() - 86400
	var d := Time.get_date_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## True if a reward can be claimed today (not yet claimed this calendar day).
func is_available() -> bool:
	return _store().get("last_claim_stamp", "") != _today_stamp()


## The streak day (1..MAX) that would apply if claimed now.
func pending_day() -> int:
	var store := _store()
	var streak := int(store.get("streak", 0))
	if store.get("last_claim_stamp", "") == _yesterday_stamp():
		streak += 1
	else:
		streak = 1
	return clampi(streak, 1, Constants.DAILY_REWARD_MAX_DAY)


## Coin amount for a given streak day.
func reward_for_day(day: int) -> int:
	var d := clampi(day, 1, Constants.DAILY_REWARD_MAX_DAY)
	return Constants.DAILY_REWARD_BASE + (d - 1) * Constants.DAILY_REWARD_STEP


## Claims today's reward if available. Returns the coins granted (0 if already
## claimed today).
func claim() -> int:
	if not is_available():
		return 0
	var day := pending_day()
	var amount := reward_for_day(day)
	var store := _store()
	store["streak"] = day
	store["last_claim_stamp"] = _today_stamp()
	SaveManager.add_coins(amount)
	SaveManager.mark_dirty()
	EventBus.daily_reward_claimed.emit(day, amount)
	return amount


func _emit_availability() -> void:
	if is_available():
		var day := pending_day()
		EventBus.daily_reward_available.emit(day, reward_for_day(day))
