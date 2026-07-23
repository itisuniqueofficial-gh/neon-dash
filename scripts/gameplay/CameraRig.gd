extends Node3D
class_name CameraRig
## CameraRig
##
## Follows the player and applies trauma-based screen shake. "Trauma" is a
## 0..1 value that decays over time; the actual shake offset scales with
## trauma squared for a punchy feel that fades smoothly. Shake respects the
## user's "screen_shake" accessibility setting.
##
## Listens on EventBus.camera_shake_requested so any system can request shake
## without a direct reference to the camera.

@export var camera: Camera3D
@export var base_offset: Vector3 = Vector3(0, 4.5, 9.0)
@export var look_at_offset: Vector3 = Vector3(0, 1.5, -6.0)

var _trauma: float = 0.0
var _time: float = 0.0
var _base_position: Vector3


func _ready() -> void:
	_base_position = position
	EventBus.camera_shake_requested.connect(add_trauma)


func _process(delta: float) -> void:
	_time += delta
	if _trauma <= 0.0:
		if camera:
			camera.h_offset = move_toward(camera.h_offset, 0.0, delta)
			camera.v_offset = move_toward(camera.v_offset, 0.0, delta)
		return
	_trauma = maxf(0.0, _trauma - Constants.CAMERA_SHAKE_DECAY * delta * 0.2)
	var shake := _trauma * _trauma
	if camera:
		camera.h_offset = Constants.CAMERA_SHAKE_MAX_OFFSET * shake * _noise(0.0)
		camera.v_offset = Constants.CAMERA_SHAKE_MAX_OFFSET * shake * _noise(1.0)
		rotation.z = Constants.CAMERA_SHAKE_MAX_ROLL * shake * _noise(2.0)


## Adds shake trauma (clamped to 1). Ignored if screen shake is disabled.
func add_trauma(amount: float) -> void:
	if not SettingsManager.is_screen_shake_enabled():
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Cheap pseudo-noise in [-1, 1] from time; distinct seeds per axis.
func _noise(seed_offset: float) -> float:
	return (
		sin((_time + seed_offset) * 57.0 + seed_offset * 13.0) * cos((_time + seed_offset) * 31.0)
	)
