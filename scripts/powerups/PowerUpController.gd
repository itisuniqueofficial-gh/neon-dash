extends Node
class_name PowerUpController
## PowerUpController
##
## Owns the lifecycle of timed power-ups within a run. Listens for activation
## events, tracks remaining time per power-up type, and emits expiry when the
## timer elapses. Re-activating an already-active power-up refreshes its timer.
##
## Timers count down in REAL time (not scaled game time) so that the
## Slow-Motion power-up — which lowers `Engine.time_scale` — does not extend its
## own duration or that of other active power-ups. The delta is clamped so a
## pause (during which this node does not process) cannot cause a large jump on
## resume.
##
## Responsibilities beyond timing:
##   - Magnet: pulls nearby collectibles toward the player each frame.
##   - Slow Motion: applies/removes `Engine.time_scale`, always restoring it on
##     expiry, run end, or when a new run starts (fail-safe).

@export var player_path: NodePath

var _player: Node3D
var _active: Dictionary = {}  ## power_type -> remaining real seconds
var _last_ms: int = 0


func _ready() -> void:
	_player = get_node_or_null(player_path)
	EventBus.powerup_activated.connect(_on_activated)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	# Real-time delta, clamped so a pause gap cannot over-count.
	var rdelta: float = 0.0 if _last_ms == 0 else clampf((now - _last_ms) / 1000.0, 0.0, 0.1)
	_last_ms = now

	if _active.is_empty():
		return

	var expired: Array = []
	for type in _active.keys():
		_active[type] = float(_active[type]) - rdelta
		if _active[type] <= 0.0:
			expired.append(type)
	for type in expired:
		_active.erase(type)
		_on_expired(type)
		EventBus.powerup_expired.emit(type)

	if _active.has(Constants.PowerUp.MAGNET):
		_apply_magnet()


func is_active(type: int) -> bool:
	return _active.has(type)


func remaining(type: int) -> float:
	return float(_active.get(type, 0.0))


func _on_activated(type: int, duration: float) -> void:
	_active[type] = duration
	if type == Constants.PowerUp.SLOW_MOTION:
		Engine.time_scale = Constants.POWERUP_SLOW_MOTION_SCALE


## Reverses any global side effects when a power-up ends.
func _on_expired(type: int) -> void:
	if type == Constants.PowerUp.SLOW_MOTION:
		Engine.time_scale = 1.0


func _on_run_started() -> void:
	_active.clear()
	_last_ms = 0
	Engine.time_scale = 1.0  # fail-safe reset


func _on_run_ended(_result: Dictionary) -> void:
	_active.clear()
	Engine.time_scale = 1.0  # never leave the game in slow motion


## Pulls collectibles within the magnet radius toward the player.
func _apply_magnet() -> void:
	if _player == null:
		return
	var r2 := Constants.COIN_MAGNET_RADIUS * Constants.COIN_MAGNET_RADIUS
	for node in get_tree().get_nodes_in_group("collectible"):
		if node is Collectible and node.is_inside_tree():
			var c := node as Collectible
			var d2: float = (c.global_position - _player.global_position).length_squared()
			if d2 <= r2:
				c.attract_to(_player)
