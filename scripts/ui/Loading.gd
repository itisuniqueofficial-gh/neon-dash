extends Control
## Loading
##
## Warms up heavy resources (gameplay scenes) via threaded background loading so
## the first run starts without a hitch, then routes to the main menu. Shows a
## progress bar driven by ResourceLoader's load progress.

@export var progress_bar: ProgressBar
@export var status_label: Label

# Scenes to warm before entering the menu/game.
var _to_load: Array[String] = [
	Constants.SCENE_GAME,
	"res://scenes/collectibles/Coin.tscn",
	"res://scenes/obstacles/Obstacle.tscn",
	"res://scenes/world/Chunk.tscn",
]
var _index: int = 0


func _ready() -> void:
	if status_label:
		status_label.text = tr("LOADING")
	if _to_load.is_empty():
		_finish()
	else:
		_start_next()


func _process(_delta: float) -> void:
	if _index >= _to_load.size():
		return
	var path := _to_load[_index]
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(path, progress)
	var frac := (float(_index) + (progress[0] if not progress.is_empty() else 0.0)) \
		/ float(_to_load.size())
	if progress_bar:
		progress_bar.value = frac * 100.0
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(path)   # cache it
		_index += 1
		if _index >= _to_load.size():
			_finish()
		else:
			_start_next()
	elif status == ResourceLoader.THREAD_LOAD_FAILED \
			or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		# Skip a resource that cannot be loaded rather than blocking forever.
		_index += 1
		if _index >= _to_load.size():
			_finish()
		else:
			_start_next()


func _start_next() -> void:
	var path := _to_load[_index]
	if ResourceLoader.exists(path):
		ResourceLoader.load_threaded_request(path)
	else:
		_index += 1
		if _index >= _to_load.size():
			_finish()


func _finish() -> void:
	SceneRouter.goto(Constants.SCENE_MAIN_MENU)
