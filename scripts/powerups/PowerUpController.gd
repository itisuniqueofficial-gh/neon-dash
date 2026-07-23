extends Node
class_name PowerUpController
## PowerUpController
##
## Owns the lifecycle of timed power-ups within a run. Listens for activation
## events, tracks remaining time per power-up type, and emits expiry when the
## timer elapses. Re-activating an already-active power-up refreshes its timer.
##
## The magnet power-up additionally makes nearby collectibles home toward the
## player; this controller performs that attraction each frame.

@export var player_path: NodePath

var _player: Node3D
var _active: Dictionary = {}          ## power_type -> remaining seconds


func _ready() -> void:
	_player = get_node_or_null(player_path)
	EventBus.powerup_activated.connect(_on_activated)
	EventBus.run_started.connect(func(): _active.clear())


func _process(delta: float) -> void:
	if _active.is_empty():
		return
	var expired: Array = []
	for type in _active.keys():
		_active[type] = float(_active[type]) - delta
		if _active[type] <= 0.0:
			expired.append(type)
	for type in expired:
		_active.erase(type)
		EventBus.powerup_expired.emit(type)

	if _active.has(Constants.PowerUp.MAGNET):
		_apply_magnet()


func is_active(type: int) -> bool:
	return _active.has(type)


func remaining(type: int) -> float:
	return float(_active.get(type, 0.0))


func _on_activated(type: int, duration: float) -> void:
	_active[type] = duration


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
