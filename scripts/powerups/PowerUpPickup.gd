extends Area3D
class_name PowerUpPickup
## PowerUpPickup
##
## A collectible that activates a timed power-up on the player/run. The active
## effect and its countdown are owned by PowerUpController (attached to the
## Game scene); this node only signals activation and then despawns.

@export var power_type: int = Constants.PowerUp.MAGNET
@export var mesh_instance: MeshInstance3D
@export var spin_speed: float = 1.5

var _collected: bool = false


func _ready() -> void:
	collision_layer = Constants.LAYER_POWERUP
	collision_mask = Constants.LAYER_PLAYER
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func pool_reset() -> void:
	_collected = false
	monitoring = true


func _process(delta: float) -> void:
	if mesh_instance and not _collected:
		mesh_instance.rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	monitoring = false
	var duration := _duration_for(power_type)
	EventBus.powerup_activated.emit(power_type, duration)
	AudioManager.play_sfx("powerup")
	AudioManager.vibrate(30)
	PoolManager.release(self)


func _duration_for(type: int) -> float:
	match type:
		Constants.PowerUp.MAGNET:
			return Constants.POWERUP_MAGNET_DURATION
		Constants.PowerUp.SHIELD:
			return Constants.POWERUP_SHIELD_DURATION
		Constants.PowerUp.DOUBLE_COINS:
			return Constants.POWERUP_DOUBLE_COINS_DURATION
		Constants.PowerUp.SPEED_BOOST:
			return Constants.POWERUP_SPEED_BOOST_DURATION
		_:
			return 5.0
