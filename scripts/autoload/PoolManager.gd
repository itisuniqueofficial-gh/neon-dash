extends Node
## PoolManager
##
## Generic object pool for frequently spawned/despawned scenes (obstacles,
## coins, gems, chunks, particles). Reusing instances avoids per-frame
## allocations and GC-style spikes during gameplay, which is critical for a
## stable 60 FPS on low-end Android hardware.
##
## Usage:
##   PoolManager.prewarm("res://scenes/collectibles/Coin.tscn", 64)
##   var coin = PoolManager.acquire("res://scenes/collectibles/Coin.tscn")
##   ... use coin ...
##   PoolManager.release(coin)
##
## Pooled nodes must implement (optionally) `pool_reset()` which is called on
## release to restore a clean state. `_scene_path` is stamped onto each node so
## `release` knows which pool to return it to.
##
## Registered as the `PoolManager` autoload.

const META_SCENE_PATH := "_pool_scene_path"

# scene_path -> { scene: PackedScene, free: Array[Node], in_use: int }
var _pools: Dictionary = {}
var _parent: Node


func _ready() -> void:
	# Detached container so pooled-but-inactive nodes are not processed.
	_parent = Node.new()
	_parent.name = "PooledObjects"
	add_child(_parent)


## Ensures a pool exists for `scene_path` and pre-instantiates `count` nodes.
func prewarm(scene_path: String, count: int) -> void:
	var pool := _ensure_pool(scene_path)
	if pool.is_empty():
		return
	while pool["free"].size() < count:
		var inst := _instantiate(scene_path)
		if inst == null:
			return
		_deactivate(inst)
		pool["free"].append(inst)


## Returns a ready-to-use instance, growing the pool on demand. May return null
## only if the scene path cannot be loaded.
func acquire(scene_path: String) -> Node:
	var pool := _ensure_pool(scene_path)
	if pool.is_empty():
		return null
	var inst: Node
	if pool["free"].is_empty():
		inst = _instantiate(scene_path)
		if inst == null:
			return null
	else:
		inst = pool["free"].pop_back()
	pool["in_use"] = int(pool["in_use"]) + 1
	inst.set_meta(META_SCENE_PATH, scene_path)
	if inst.has_method("pool_reset"):
		inst.call("pool_reset")
	inst.process_mode = Node.PROCESS_MODE_INHERIT
	if inst is CanvasItem:
		(inst as CanvasItem).visible = true
	return inst


## Returns an instance to its pool. Safe to call once per acquired node.
func release(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node.has_meta(META_SCENE_PATH):
		node.queue_free()
		return
	var scene_path: String = node.get_meta(META_SCENE_PATH)
	var pool: Dictionary = _pools.get(scene_path, {})
	if pool.is_empty():
		node.queue_free()
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	_deactivate(node)
	pool["free"].append(node)
	pool["in_use"] = maxi(0, int(pool["in_use"]) - 1)


## Number of live (acquired) instances for a scene — used by tests and metrics.
func active_count(scene_path: String) -> int:
	var pool: Dictionary = _pools.get(scene_path, {})
	return int(pool.get("in_use", 0)) if not pool.is_empty() else 0


func free_count(scene_path: String) -> int:
	var pool: Dictionary = _pools.get(scene_path, {})
	return pool["free"].size() if not pool.is_empty() else 0


func _ensure_pool(scene_path: String) -> Dictionary:
	if _pools.has(scene_path):
		return _pools[scene_path]
	if not ResourceLoader.exists(scene_path):
		push_error("PoolManager: scene not found: " + scene_path)
		return {}
	var scene := ResourceLoader.load(scene_path)
	if not (scene is PackedScene):
		push_error("PoolManager: not a PackedScene: " + scene_path)
		return {}
	var pool := {"scene": scene, "free": [] as Array[Node], "in_use": 0}
	_pools[scene_path] = pool
	return pool


func _instantiate(scene_path: String) -> Node:
	var pool: Dictionary = _pools.get(scene_path, {})
	if pool.is_empty():
		return null
	var scene: PackedScene = pool["scene"]
	return scene.instantiate()


## Parks a node in the detached container and stops it processing.
func _deactivate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	_parent.add_child(node)
