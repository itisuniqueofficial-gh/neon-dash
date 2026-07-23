extends Node3D
class_name ChunkManager
## ChunkManager
##
## Drives the endless world. Responsibilities:
##   - Keep a rolling window of chunks spawned ahead of the player.
##   - Scroll all active chunks toward the player at the current run speed
##     (the player itself stays near the origin).
##   - Procedurally populate each new chunk with obstacles, coins, gems and the
##     occasional power-up, scaled by the current difficulty tier and always
##     leaving at least one traversable lane so runs are fair.
##   - Recycle chunks (and their contents) back to the object pools once they
##     pass behind the player.
##
## All spawning goes through PoolManager, so a steady-state run performs no
## per-frame allocations.

@export var chunk_scene: PackedScene
@export var coin_scene: PackedScene
@export var gem_scene: PackedScene
@export var obstacle_scene: PackedScene
@export var powerup_scene: PackedScene
@export var collectibles_root: Node3D  ## Reparent target for magnet queries.

const CHUNK_PATH := "res://scenes/world/Chunk.tscn"
const COIN_PATH := "res://scenes/collectibles/Coin.tscn"
const GEM_PATH := "res://scenes/collectibles/Gem.tscn"
const OBSTACLE_PATH := "res://scenes/obstacles/Obstacle.tscn"
const POWERUP_PATH := "res://scenes/powerups/PowerUp.tscn"

var _active_chunks: Array[Chunk] = []
var _spawn_z: float = 0.0  ## World Z at which the next chunk's far edge sits.
var _distance_since_powerup: float = 0.0
var _rng := RandomNumberGenerator.new()
var _running: bool = false


func _ready() -> void:
	_rng.randomize()
	_prewarm_pools()
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)


func _prewarm_pools() -> void:
	PoolManager.prewarm(CHUNK_PATH, Constants.CHUNK_POOL_SIZE)
	PoolManager.prewarm(COIN_PATH, Constants.COIN_POOL_SIZE)
	PoolManager.prewarm(GEM_PATH, 16)
	PoolManager.prewarm(OBSTACLE_PATH, Constants.OBSTACLE_POOL_SIZE)
	PoolManager.prewarm(POWERUP_PATH, 4)


## (Re)builds the initial straight, obstacle-free runway then the world.
func reset_world() -> void:
	for c in _active_chunks:
		c.clear()
		PoolManager.release(c)
	_active_chunks.clear()
	_spawn_z = 0.0
	_distance_since_powerup = 0.0
	# First few chunks are a safe runway (no obstacles) so the player can settle.
	for i in Constants.CHUNKS_AHEAD:
		_spawn_chunk(i < 2)


func _physics_process(delta: float) -> void:
	if not _running:
		return
	var step := GameManager.advance(delta)
	if step <= 0.0:
		return
	_scroll(step)


## Moves all chunks toward the player and recycles/spawns as needed.
func _scroll(step: float) -> void:
	for c in _active_chunks:
		c.position.z += step
	# The player sits at z=0; a chunk whose far edge is well behind is recycled.
	while (
		not _active_chunks.is_empty()
		and (
			_active_chunks[0].position.z - Constants.CHUNK_LENGTH
			> Constants.CHUNK_LENGTH * Constants.CHUNKS_BEHIND
		)
	):
		var old: Chunk = _active_chunks.pop_front()
		old.clear()
		PoolManager.release(old)
		_spawn_z -= Constants.CHUNK_LENGTH
		_spawn_chunk(false)


## Spawns a new chunk at the far end. `safe` skips hazard population.
func _spawn_chunk(safe: bool) -> void:
	var chunk := PoolManager.acquire(CHUNK_PATH) as Chunk
	if chunk == null:
		return
	add_child(chunk)
	# Place chunk so its centre is at the far edge of the current window.
	chunk.position = Vector3(0, 0, -_spawn_z - Constants.CHUNK_LENGTH * 0.5)
	_spawn_z += Constants.CHUNK_LENGTH
	_active_chunks.append(chunk)
	if not safe:
		_populate(chunk)


## Procedurally fills a chunk with a fair mix of hazards and rewards.
func _populate(chunk: Chunk) -> void:
	var tier := GameManager.difficulty_tier
	var gap := Constants.obstacle_gap_for_tier(tier)
	var rows := int(Constants.CHUNK_LENGTH / gap)
	var half := Constants.CHUNK_LENGTH * 0.5

	for row in rows:
		var local_z := half - (float(row) + 0.5) * gap
		# Choose how many lanes to block; never block all three.
		var blocked := _pick_blocked_lanes(tier)
		for lane in Constants.LANE_COUNT:
			var x := Constants.lane_to_x(lane)
			if lane in blocked:
				_spawn_obstacle(chunk, Vector3(x, 0.0, local_z))
			elif _rng.randf() < 0.55:
				_spawn_coin_line(chunk, x, local_z)
			elif _rng.randf() < 0.05:
				_spawn_gem(chunk, Vector3(x, 1.0, local_z))

	# Occasional power-up, distance-gated so they don't cluster.
	_distance_since_powerup += Constants.CHUNK_LENGTH
	if _distance_since_powerup >= 120.0 and _rng.randf() < 0.5:
		_distance_since_powerup = 0.0
		var lane := _rng.randi_range(0, Constants.LANE_COUNT - 1)
		_spawn_powerup(chunk, Vector3(Constants.lane_to_x(lane), 1.2, 0.0))


## Picks which lanes to block for a row, guaranteeing at least one open lane.
func _pick_blocked_lanes(tier: int) -> Array:
	var max_block := 1
	if tier >= 4:
		max_block = 2  # allow blocking two lanes at higher tiers
	var count := _rng.randi_range(0, max_block)
	if count == 0:
		return []
	var lanes := [0, 1, 2]
	lanes.shuffle()
	return lanes.slice(0, count)


func _spawn_obstacle(chunk: Chunk, local_pos: Vector3) -> void:
	var obs := PoolManager.acquire(OBSTACLE_PATH) as Obstacle
	if obs == null:
		return
	# Randomly assign an avoidable type so jumping/sliding stay relevant.
	var roll := _rng.randf()
	if roll < 0.25:
		obs.obstacle_type = Obstacle.ObstacleType.JUMP_OVER
	elif roll < 0.45:
		obs.obstacle_type = Obstacle.ObstacleType.SLIDE_UNDER
	else:
		obs.obstacle_type = Obstacle.ObstacleType.FULL
	chunk.add_item(obs, local_pos)


func _spawn_coin_line(chunk: Chunk, x: float, center_z: float) -> void:
	for i in range(-1, 2):
		var coin := PoolManager.acquire(COIN_PATH)
		if coin == null:
			return
		chunk.add_item(coin, Vector3(x, 0.8, center_z + float(i) * 1.5))


func _spawn_gem(chunk: Chunk, local_pos: Vector3) -> void:
	var gem := PoolManager.acquire(GEM_PATH)
	if gem != null:
		chunk.add_item(gem, local_pos)


func _spawn_powerup(chunk: Chunk, local_pos: Vector3) -> void:
	var pu := PoolManager.acquire(POWERUP_PATH) as PowerUpPickup
	if pu == null:
		return
	var types := [
		Constants.PowerUp.MAGNET,
		Constants.PowerUp.SHIELD,
		Constants.PowerUp.DOUBLE_COINS,
		Constants.PowerUp.SPEED_BOOST
	]
	pu.power_type = types[_rng.randi_range(0, types.size() - 1)]
	chunk.add_item(pu, local_pos)


func active_chunk_count() -> int:
	return _active_chunks.size()


func _on_run_started() -> void:
	reset_world()
	_running = true


func _on_run_ended(_result: Dictionary) -> void:
	_running = false
