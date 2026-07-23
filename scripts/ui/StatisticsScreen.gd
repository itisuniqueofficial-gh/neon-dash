extends Control
class_name StatisticsScreen
## StatisticsScreen
##
## Displays lifetime statistics from StatisticsManager plus a few derived
## profile figures (coins/gems balance, high score). Read-only.

@export var list_container: VBoxContainer


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	var rows := [
		[tr("HIGH_SCORE"), str(SaveManager.get_high_score())],
		[tr("BEST_DISTANCE"), "%d m" % int(SaveManager.data.get("best_distance", 0.0))],
		[tr("TOTAL_RUNS"), str(int(StatisticsManager.get_stat(StatisticsManager.RUNS)))],
		[tr("TOTAL_DISTANCE"), "%d m" % int(StatisticsManager.get_stat(StatisticsManager.TOTAL_DISTANCE))],
		[tr("COINS"), str(SaveManager.get_coins())],
		[tr("GEMS"), str(SaveManager.get_gems())],
		[tr("TOTAL_JUMPS"), str(int(StatisticsManager.get_stat(StatisticsManager.TOTAL_JUMPS)))],
		[tr("NEAR_MISSES"), str(int(StatisticsManager.get_stat(StatisticsManager.NEAR_MISSES)))],
		[tr("POWERUPS_USED"), str(int(StatisticsManager.get_stat(StatisticsManager.TOTAL_POWERUPS)))],
	]
	for r in rows:
		var row := HBoxContainer.new()
		var key := Label.new()
		key.text = r[0]
		key.custom_minimum_size = Vector2(240, 0)
		var val := Label.new()
		val.text = r[1]
		row.add_child(key)
		row.add_child(val)
		list_container.add_child(row)


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
