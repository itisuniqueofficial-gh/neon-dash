extends Control
class_name PauseMenu
## PauseMenu
##
## Overlay shown while a run is paused. Offers resume, restart and quit-to-menu.
## Runs with PROCESS_MODE_ALWAYS (set in the scene) so its buttons work while
## the tree is paused.


func _on_resume_pressed() -> void:
	AudioManager.play_sfx("button")
	var gc := get_tree().get_first_node_in_group("game_controller")
	if gc and gc.has_method("toggle_pause"):
		gc.toggle_pause()


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().paused = false
	SceneRouter.goto_game()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().paused = false
	SceneRouter.goto_main_menu()
