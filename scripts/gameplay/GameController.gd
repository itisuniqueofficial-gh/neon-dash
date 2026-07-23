extends Node3D
class_name GameController
## GameController
##
## Root controller for the gameplay scene. It wires together the player, chunk
## manager, camera, power-up controller and HUD, starts the run, and handles
## pause input and the game-over hand-off. It keeps orchestration logic out of
## the individual systems, which communicate through the EventBus.

@export var chunk_manager: ChunkManager
@export var pause_menu: CanvasItem
@export var game_over_menu: CanvasItem

var _started: bool = false


func _ready() -> void:
	add_to_group("game_controller")
	EventBus.run_ended.connect(_on_run_ended)
	if pause_menu:
		pause_menu.visible = false
	if game_over_menu:
		game_over_menu.visible = false
	# Defer start one frame so all children (pools) have completed _ready.
	call_deferred("_begin")


func _begin() -> void:
	if _started:
		return
	_started = true
	GameManager.start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and GameManager.is_playing():
		toggle_pause()


func toggle_pause() -> void:
	if GameManager.state == GameManager.State.PLAYING:
		GameManager.pause_run()
		if pause_menu:
			pause_menu.visible = true
	elif GameManager.state == GameManager.State.PAUSED:
		GameManager.resume_run()
		if pause_menu:
			pause_menu.visible = false


func _on_run_ended(_result: Dictionary) -> void:
	if game_over_menu:
		game_over_menu.visible = true
