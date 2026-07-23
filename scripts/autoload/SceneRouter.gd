extends Node
## SceneRouter
##
## Centralises scene changes with a simple fade transition, so navigation is
## consistent and gameplay never has to call `get_tree().change_scene_*`
## directly. Also unpauses the tree on every transition to avoid getting stuck
## in a paused state after a menu.
##
## Registered as the `SceneRouter` autoload.

const FADE_TIME: float = 0.25

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer.add_child(_fade_rect)


## Changes to `scene_path` with a fade-out/fade-in. Ignores re-entrant calls.
func goto(scene_path: String) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneRouter: scene not found: " + scene_path)
		return
	_busy = true
	get_tree().paused = false

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_TIME)
	await tween.finished

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter: failed to change scene (%d)" % err)

	var tween_in := create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, FADE_TIME)
	await tween_in.finished
	_busy = false


## Convenience wrappers for the common destinations.
func goto_main_menu() -> void:
	goto(Constants.SCENE_MAIN_MENU)


func goto_game() -> void:
	goto(Constants.SCENE_GAME)


func goto_settings() -> void:
	goto(Constants.SCENE_SETTINGS)
