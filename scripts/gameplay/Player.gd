extends CharacterBody3D
class_name Player
## Player
##
## The runner. The world scrolls toward the player (see ChunkManager), so the
## player's own motion is limited to three discrete lanes on the X axis plus
## vertical jump/slide on the Y axis. Forward "distance" is owned by
## GameManager, not by this node's position.
##
## Input is abstracted so the same code serves keyboard (desktop/CI) and touch
## (Android). Touch gestures are translated to the same intents by TouchInput
## and delivered through public methods (`move_left`, `jump`, etc.).
##
## Collision with obstacles is reported by obstacle Area3D nodes calling
## `hit()`. Coins/power-ups call their own collect logic against this body.

signal lane_changed(lane: int)

@export var collision_shape: CollisionShape3D
@export var mesh_instance: MeshInstance3D

var current_lane: int = 1  ## Start in the centre lane.
var _target_x: float = 0.0
var _vertical_velocity: float = 0.0
var _is_jumping: bool = false
var _is_sliding: bool = false
var _slide_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _alive: bool = true
var _shielded: bool = false
var _invincible: bool = false  ## Timed invulnerability (INVINCIBILITY power-up).
var _air_jumps_used: int = 0  ## Mid-air jumps used since last grounded.
var _dash_timer: float = 0.0  ## Remaining dash time (>0 == dashing).
var _dash_cooldown_timer: float = 0.0

var _default_shape_height: float = 2.0
var _mesh_base_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	add_to_group("player")
	collision_layer = Constants.LAYER_PLAYER
	collision_mask = Constants.LAYER_GROUND
	# Resolve node references defensively: hand-authored scenes may not always
	# wire the exported NodePaths, and these are required for slide/appearance.
	if mesh_instance == null:
		mesh_instance = get_node_or_null("Mesh")
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape3D")
	_target_x = Constants.lane_to_x(current_lane)
	global_position.x = _target_x
	if mesh_instance:
		_mesh_base_scale = mesh_instance.scale
	apply_appearance()
	EventBus.powerup_activated.connect(_on_powerup_activated)
	EventBus.powerup_expired.connect(_on_powerup_expired)


func _physics_process(delta: float) -> void:
	if not _alive or not GameManager.is_playing():
		return
	_read_input()
	_tick_timers(delta)
	_apply_lane_motion(delta)
	_apply_vertical_motion(delta)
	move_and_slide()


func _read_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		move_left()
	if Input.is_action_just_pressed("move_right"):
		move_right()
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = Constants.JUMP_BUFFER_TIME
	if Input.is_action_just_pressed("slide"):
		slide()
	if Input.is_action_just_pressed("dash"):
		dash()


func _tick_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = Constants.COYOTE_TIME
		_is_jumping = false
		_air_jumps_used = 0
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)
	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - delta)

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
		if _coyote_timer > 0.0:
			_do_jump()
		elif _air_jumps_used < Constants.MAX_AIR_JUMPS:
			_do_air_jump()

	if _is_sliding:
		_slide_timer -= delta
		if _slide_timer <= 0.0:
			_end_slide()


func _apply_lane_motion(delta: float) -> void:
	_target_x = Constants.lane_to_x(current_lane)
	var new_x: float = move_toward(
		global_position.x, _target_x, Constants.LANE_CHANGE_SPEED * delta
	)
	velocity.x = (new_x - global_position.x) / maxf(delta, 0.0001)


func _apply_vertical_motion(delta: float) -> void:
	if not is_on_floor():
		_vertical_velocity -= Constants.GRAVITY * delta
	elif _vertical_velocity < 0.0:
		_vertical_velocity = 0.0
	velocity.y = _vertical_velocity
	velocity.z = 0.0


# --- Public input intents (also used by touch controls & tests) -------------


func move_left() -> void:
	if current_lane > 0:
		current_lane -= 1
		lane_changed.emit(current_lane)
		AudioManager.play_sfx("slide", 1.2)


func move_right() -> void:
	if current_lane < Constants.LANE_COUNT - 1:
		current_lane += 1
		lane_changed.emit(current_lane)
		AudioManager.play_sfx("slide", 1.2)


func jump() -> void:
	_jump_buffer_timer = Constants.JUMP_BUFFER_TIME


func _do_jump() -> void:
	_vertical_velocity = Constants.JUMP_VELOCITY
	_is_jumping = true
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	if _is_sliding:
		_end_slide()
	StatisticsManager.increment(StatisticsManager.TOTAL_JUMPS)
	AudioManager.play_sfx("jump")
	AudioManager.vibrate(20)


## Performs a mid-air (double) jump. Consumes one air-jump charge.
func _do_air_jump() -> void:
	_vertical_velocity = Constants.AIR_JUMP_VELOCITY
	_air_jumps_used += 1
	_jump_buffer_timer = 0.0
	StatisticsManager.increment(StatisticsManager.TOTAL_JUMPS)
	AudioManager.play_sfx("jump", 1.25)
	AudioManager.vibrate(15)
	EventBus.camera_shake_requested.emit(0.15)


## Triggers a dash: a brief forward burst with invulnerability, gated by a
## cooldown. Safe to call any time; a no-op while on cooldown or not running.
func dash() -> void:
	if _dash_cooldown_timer > 0.0 or _dash_timer > 0.0 or not _alive:
		return
	if not GameManager.is_playing():
		return
	_dash_timer = Constants.DASH_DURATION
	_dash_cooldown_timer = Constants.DASH_COOLDOWN
	GameManager.add_speed(Constants.DASH_SPEED_BONUS)
	EventBus.camera_shake_requested.emit(0.3)
	AudioManager.play_sfx("powerup", 1.4)
	AudioManager.vibrate(25)


func is_dashing() -> bool:
	return _dash_timer > 0.0


func dash_ready() -> bool:
	return _dash_cooldown_timer <= 0.0


## Applies the selected character/skin colour to the runner mesh, so cosmetic
## unlocks are reflected in-game. Falls back silently if data is unavailable.
func apply_appearance() -> void:
	if mesh_instance == null:
		return
	var color := _resolve_appearance_color()
	var mat := mesh_instance.get_active_material(0)
	if mat is StandardMaterial3D:
		var unique := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		unique.albedo_color = color
		unique.emission_enabled = true
		unique.emission = color
		mesh_instance.set_surface_override_material(0, unique)


## Resolves the display colour from the selected skin, then character.
func _resolve_appearance_color() -> Color:
	var skin_id := String(SaveManager.data.get("selected_skin", "default"))
	var skin := Catalog.find_skin(skin_id)
	if not skin.is_empty() and skin_id != "default":
		return skin.get("color", Color(0, 0.9, 1))
	var char_id := String(SaveManager.data.get("selected_character", "runner_default"))
	var ch := Catalog.find_character(char_id)
	if not ch.is_empty():
		return ch.get("color", Color(0, 0.9, 1))
	return Color(0, 0.9, 1)


func slide() -> void:
	if _is_sliding:
		return
	_is_sliding = true
	_slide_timer = Constants.SLIDE_DURATION
	# Shrink the collision profile so the player fits under obstacles.
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var cap := collision_shape.shape as CapsuleShape3D
		_default_shape_height = cap.height
		cap.height = _default_shape_height * 0.5
		collision_shape.position.y = -_default_shape_height * 0.25
	if mesh_instance:
		mesh_instance.scale = Vector3(
			_mesh_base_scale.x, _mesh_base_scale.y * 0.5, _mesh_base_scale.z
		)
	StatisticsManager.increment(StatisticsManager.TOTAL_SLIDES)
	AudioManager.play_sfx("slide")


func _end_slide() -> void:
	_is_sliding = false
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		(collision_shape.shape as CapsuleShape3D).height = _default_shape_height
		collision_shape.position.y = 0.0
	if mesh_instance:
		mesh_instance.scale = _mesh_base_scale


## Called by obstacles when the player collides with them. A shield absorbs one
## hit; otherwise the run ends.
func hit(obstacle_id: String = "obstacle") -> void:
	if not _alive:
		return
	# Timed invincibility and the dash's i-frames ignore hits entirely.
	if _invincible or _dash_timer > 0.0:
		EventBus.near_miss.emit(obstacle_id)
		return
	if _shielded:
		_shielded = false
		EventBus.powerup_expired.emit(Constants.PowerUp.SHIELD)
		EventBus.camera_shake_requested.emit(0.4)
		AudioManager.play_sfx("hit")
		return
	_alive = false
	EventBus.obstacle_hit.emit(obstacle_id)
	EventBus.camera_shake_requested.emit(1.0)
	AudioManager.play_sfx("hit")
	AudioManager.vibrate(120)
	GameManager.end_run("collision")


## Restores the player to a playable state after a revive.
func revive() -> void:
	_alive = true
	_shielded = true  # brief protection after reviving
	_vertical_velocity = 0.0
	current_lane = 1
	global_position.x = Constants.lane_to_x(current_lane)


func is_alive() -> bool:
	return _alive


func is_sliding() -> bool:
	return _is_sliding


func is_invincible() -> bool:
	return _invincible or _dash_timer > 0.0


## Remaining mid-air jumps before the player must land (for tests/HUD).
func air_jumps_remaining() -> int:
	return Constants.MAX_AIR_JUMPS - _air_jumps_used


func _on_powerup_activated(type: int, _duration: float) -> void:
	if type == Constants.PowerUp.SHIELD:
		_shielded = true
	elif type == Constants.PowerUp.INVINCIBILITY:
		_invincible = true


func _on_powerup_expired(type: int) -> void:
	if type == Constants.PowerUp.SHIELD:
		_shielded = false
	elif type == Constants.PowerUp.INVINCIBILITY:
		_invincible = false
