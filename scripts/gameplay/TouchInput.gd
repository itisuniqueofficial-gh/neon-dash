extends Node
class_name TouchInput
## TouchInput
##
## Translates touch-screen swipe gestures into player intents on Android:
##   - Swipe left/right  -> change lane
##   - Swipe up          -> jump
##   - Swipe down        -> slide
## A quick tap also triggers a jump for accessibility. Desktop/CI use keyboard
## actions in Player directly, so this node is a no-op there but harmless.
##
## The control scheme is read from SettingsManager; only "swipe" is wired here,
## with "buttons" handled by on-screen UI buttons in the HUD.

@export var player_path: NodePath

const SWIPE_THRESHOLD: float = 40.0     ## Min pixels to count as a swipe.
const TAP_MAX_DURATION: float = 0.2     ## Max seconds for a tap-to-jump.

var _player: Player
var _touch_start := Vector2.ZERO
var _touch_time: float = 0.0
var _tracking: bool = false


func _ready() -> void:
	_player = get_node_or_null(player_path)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_time = Time.get_ticks_msec() / 1000.0
			_tracking = true
		elif _tracking:
			_tracking = false
			_resolve_gesture(event.position)
	elif event is InputEventScreenDrag and _tracking:
		var delta: Vector2 = (event as InputEventScreenDrag).position - _touch_start
		if delta.length() >= SWIPE_THRESHOLD:
			_tracking = false
			_apply_swipe(delta)


func _resolve_gesture(end_pos: Vector2) -> void:
	var delta := end_pos - _touch_start
	var dt := Time.get_ticks_msec() / 1000.0 - _touch_time
	if delta.length() < SWIPE_THRESHOLD:
		if dt <= TAP_MAX_DURATION:
			_player.jump()      # quick tap = jump
		return
	_apply_swipe(delta)


func _apply_swipe(delta: Vector2) -> void:
	if absf(delta.x) > absf(delta.y):
		if delta.x > 0.0:
			_player.move_right()
		else:
			_player.move_left()
	else:
		if delta.y < 0.0:
			_player.jump()
		else:
			_player.slide()
