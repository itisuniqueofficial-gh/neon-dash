extends Control
class_name CreditsScreen
## CreditsScreen
##
## Static acknowledgements: engine, contributors, asset licences and a link to
## the full credits in docs/CREDITS.md. Purely informational.


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
