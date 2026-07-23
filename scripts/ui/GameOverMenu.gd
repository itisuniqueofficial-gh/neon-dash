extends Control
class_name GameOverMenu
## GameOverMenu
##
## Shown when a run ends. Displays the run's score, distance and rewards,
## flags a new high score, and offers restart or return-to-menu. Populated from
## the `run_ended` result payload delivered over the EventBus.

@export var score_label: Label
@export var distance_label: Label
@export var reward_label: Label
@export var high_score_label: Label
@export var new_best_badge: CanvasItem


func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)
	if new_best_badge:
		new_best_badge.visible = false


func _on_run_ended(result: Dictionary) -> void:
	if score_label:
		score_label.text = tr("SCORE") + ": " + str(result.get("score", 0))
	if distance_label:
		distance_label.text = tr("DISTANCE") + ": " + str(int(result.get("distance", 0.0))) + " m"
	if reward_label:
		reward_label.text = "+%d ⬤   +%d ◆" % [result.get("coins", 0), result.get("gems", 0)]
	if high_score_label:
		high_score_label.text = tr("HIGH_SCORE") + ": " + str(SaveManager.get_high_score())
	if new_best_badge:
		new_best_badge.visible = bool(result.get("new_high_score", false))


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_game()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
