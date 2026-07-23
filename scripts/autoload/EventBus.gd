extends Node
## EventBus
##
## Global, decoupled signal hub. Systems emit and listen here instead of
## holding hard references to each other, which keeps managers and gameplay
## nodes loosely coupled and independently testable.
##
## Convention: emitters call `EventBus.<signal>.emit(...)`; listeners connect in
## `_ready()` and disconnect automatically when freed. Keep payloads primitive
## (ints, strings, dictionaries) so signals stay serialisation-friendly.
##
## Registered as the `EventBus` autoload.

# --- Run lifecycle ----------------------------------------------------------
signal run_started
signal run_paused
signal run_resumed
signal run_ended(result: Dictionary)  ## { score, distance, coins, gems }
signal player_died(cause: String)
signal player_revived

# --- Gameplay events --------------------------------------------------------
signal coin_collected(amount: int, total_run: int)
signal gem_collected(amount: int, total_run: int)
signal powerup_activated(type: int, duration: float)
signal powerup_expired(type: int)
signal obstacle_hit(obstacle_id: String)
signal near_miss(obstacle_id: String)
signal distance_updated(distance: float)
signal score_updated(score: int)
signal speed_changed(speed: float)
signal difficulty_changed(tier: int)

# --- Camera / juice ---------------------------------------------------------
signal camera_shake_requested(strength: float)

# --- Meta / progression -----------------------------------------------------
signal achievement_unlocked(id: String)
signal achievement_progress(id: String, current: int, target: int)
signal mission_completed(id: String, reward: int)
signal missions_refreshed
signal daily_reward_available(day: int, amount: int)
signal daily_reward_claimed(day: int, amount: int)
signal character_unlocked(id: String)
signal character_selected(id: String)
signal skin_unlocked(id: String)
signal currency_changed(coins: int, gems: int)
signal statistic_changed(key: String, value: Variant)

# --- Persistence ------------------------------------------------------------
signal save_completed
signal save_failed(reason: String)
signal save_loaded
signal save_corrupted_recovered

# --- Settings ---------------------------------------------------------------
signal settings_changed(key: String, value: Variant)
signal locale_changed(locale: String)
