extends Area3D
class_name Collectible
## Collectible
##
## Base class for pickups (coins, gems). Detects the player via Area3D overlap,
## grants its reward through the EventBus, then returns itself to the object
## pool. Supports an optional magnet mode where the pickup homes toward the
## player when a magnet power-up is active.
##
## Subclasses set `kind` and `value` and may override `_on_collected`.

enum Kind { COIN, GEM }

@export var kind: Kind = Kind.COIN
@export var value: int = 1
@export var spin_speed: float = 2.0
@export var mesh_instance: MeshInstance3D

var _collected: bool = false
var _magnet_target: Node3D = null
var _scene_path_hint: String = ""


func _ready() -> void:
	collision_layer = Constants.LAYER_COLLECTIBLE
	collision_mask = Constants.LAYER_PLAYER
	monitoring = true
	add_to_group("collectible")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func pool_reset() -> void:
	_collected = false
	_magnet_target = null
	monitoring = true
	rotation = Vector3.ZERO
	scale = Vector3.ONE


func _process(delta: float) -> void:
	if _collected:
		return
	if mesh_instance:
		mesh_instance.rotate_y(spin_speed * delta)
	if _magnet_target and is_instance_valid(_magnet_target):
		global_position = global_position.move_toward(
			_magnet_target.global_position, Constants.PLAYER_MAX_SPEED * 1.5 * delta
		)


## Enables magnet homing toward `target` (called by the magnet power-up logic).
func attract_to(target: Node3D) -> void:
	_magnet_target = target


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	monitoring = false
	_on_collected()


## Grants the reward. Overridable by subclasses for special behaviour.
func _on_collected() -> void:
	match kind:
		Kind.COIN:
			SaveManager.data["total_coins_collected"] = (
				int(SaveManager.data.get("total_coins_collected", 0)) + value
			)
			EventBus.coin_collected.emit(value, GameManager.run_coins + value)
			AudioManager.play_sfx("coin", randf_range(0.95, 1.1))
		Kind.GEM:
			SaveManager.data["total_gems_collected"] = (
				int(SaveManager.data.get("total_gems_collected", 0)) + value
			)
			EventBus.gem_collected.emit(value, GameManager.run_gems + value)
			AudioManager.play_sfx("gem")
	_despawn()


func _despawn() -> void:
	PoolManager.release(self)
