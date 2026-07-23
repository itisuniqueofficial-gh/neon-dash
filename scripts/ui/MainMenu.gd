extends Control
class_name MainMenu
## MainMenu
##
## Hub screen. Shows the player's currency and best score, exposes navigation
## to Play, Store, Characters, Achievements, Statistics, Settings and Credits,
## and surfaces the daily reward when one is available.

@export var coins_label: Label
@export var gems_label: Label
@export var high_score_label: Label
@export var daily_reward_button: BaseButton


func _ready() -> void:
	AudioManager.play_music("menu")
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.daily_reward_claimed.connect(func(_d, _a): _refresh())
	_refresh()
	if daily_reward_button:
		daily_reward_button.visible = DailyRewardManager.is_available()


func _refresh() -> void:
	if coins_label:
		coins_label.text = str(SaveManager.get_coins())
	if gems_label:
		gems_label.text = str(SaveManager.get_gems())
	if high_score_label:
		high_score_label.text = tr("HIGH_SCORE") + ": " + str(SaveManager.get_high_score())


func _on_currency_changed(_coins: int, _gems: int) -> void:
	_refresh()


func _btn(sfx: bool = true) -> void:
	if sfx:
		AudioManager.play_sfx("button")


func _on_play_pressed() -> void:
	_btn()
	SceneRouter.goto_game()


func _on_settings_pressed() -> void:
	_btn()
	SceneRouter.goto(Constants.SCENE_SETTINGS)


func _on_store_pressed() -> void:
	_btn()
	SceneRouter.goto(Constants.SCENE_STORE)


func _on_characters_pressed() -> void:
	_btn()
	SceneRouter.goto(Constants.SCENE_CHARACTER_SELECT)


func _on_achievements_pressed() -> void:
	_btn()
	SceneRouter.goto(Constants.SCENE_ACHIEVEMENTS)


func _on_statistics_pressed() -> void:
	_btn()
	SceneRouter.goto(Constants.SCENE_STATISTICS)


func _on_credits_pressed() -> void:
	_btn()
	SceneRouter.goto(Constants.SCENE_CREDITS)


func _on_daily_reward_pressed() -> void:
	_btn()
	var amount := DailyRewardManager.claim()
	if amount > 0:
		AudioManager.play_sfx("unlock")
	if daily_reward_button:
		daily_reward_button.visible = false
	_refresh()


func _on_quit_pressed() -> void:
	_btn()
	SaveManager.save_game()
	get_tree().quit()
