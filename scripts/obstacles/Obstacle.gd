extends Area3D
class_name Obstacle
## Obstacle
##
## A hazard the player must avoid by switching lanes, jumping, or sliding.
## Detects the player through Area3D overlap and calls `Player.hit()`. Also
## reports "near misses" when the player passes very close without colliding,
## which feeds the scoring juice and achievements.
##
## Obstacle variety is expressed via `obstacle_type`, which controls how it can
## be avoided; the ChunkManager uses this to place obstacles fairly.

enum ObstacleType { FULL, JUMP_OVER, SLIDE_UNDER }

@export var obstacle_type: ObstacleType = ObstacleType.FULL
@export var obstacle_id: String = "block"
@export var mesh_instance: MeshInstance3D

var _resolved: bool = false  ## True once hit/near-miss has been decided.
var _player_ref: Node3D = null


func _ready() -> void:
	collision_layer = Constants.LAYER_OBSTACLE
	collision_mask = Constants.LAYER_PLAYER
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func pool_reset() -> void:
	_resolved = false
	_player_ref = null
	monitoring = true
	rotation = Vector3.ZERO


func _on_body_entered(body: Node3D) -> void:
	if _resolved or not body.is_in_group("player"):
		return
	var player := body as Player
	if player == null:
		return
	# Respect avoidance rules: a jump clears a JUMP_OVER, a slide clears a
	# SLIDE_UNDER. FULL obstacles must be dodged laterally.
	if obstacle_type == ObstacleType.SLIDE_UNDER and player.is_sliding():
		_register_near_miss()
		return
	if obstacle_type == ObstacleType.JUMP_OVER and not player.is_on_floor():
		_register_near_miss()
		return
	_resolved = true
	player.hit(obstacle_id)


func _register_near_miss() -> void:
	if _resolved:
		return
	_resolved = true
	StatisticsManager.increment(StatisticsManager.OBSTACLES_DODGED)
	EventBus.near_miss.emit(obstacle_id)


func _despawn() -> void:
	PoolManager.release(self)
