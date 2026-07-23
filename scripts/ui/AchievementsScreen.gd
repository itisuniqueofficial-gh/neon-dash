extends Control
class_name AchievementsScreen
## AchievementsScreen
##
## Renders the achievement catalogue with per-achievement progress bars and an
## unlocked/locked state, sourced from AchievementManager.list_for_ui(). Rebuilt
## live when an achievement unlocks or progresses.

@export var list_container: VBoxContainer


func _ready() -> void:
	EventBus.achievement_unlocked.connect(func(_id): _rebuild())
	EventBus.achievement_progress.connect(func(_i, _c, _t): _rebuild())
	_rebuild()


func _rebuild() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	for a in AchievementManager.list_for_ui():
		list_container.add_child(_make_row(a))


func _make_row(a: Dictionary) -> Control:
	var panel := VBoxContainer.new()
	var title := Label.new()
	var check := "✓ " if a["unlocked"] else ""
	title.text = "%s%s — %s" % [check, a["title"], a["description"]]
	panel.add_child(title)

	var bar := ProgressBar.new()
	bar.max_value = float(a["target"])
	bar.value = float(a["progress"])
	bar.custom_minimum_size = Vector2(0, 18)
	panel.add_child(bar)
	return panel


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
