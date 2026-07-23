extends Control
## Splash
##
## First scene shown at launch. Displays the studio/game logo briefly, then
## routes to the Loading scene. Kept intentionally light so the app appears
## on screen as fast as possible (important for perceived launch performance).

@export var hold_time: float = 1.2
@export var title_label: Label


func _ready() -> void:
	if title_label:
		title_label.text = Constants.GAME_TITLE
		title_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	AudioManager.play_music("menu")
	await get_tree().create_timer(hold_time).timeout
	SceneRouter.goto(Constants.SCENE_LOADING)
