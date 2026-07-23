extends Node3D
class_name Chunk
## Chunk
##
## A fixed-length segment of track. Chunks are pooled and recycled by the
## ChunkManager: as the world scrolls toward the player, a chunk that passes
## behind the player is cleared and re-used at the far end. Each chunk owns the
## obstacles, coins, gems and power-ups spawned onto it and is responsible for
## returning them to their pools when cleared.
##
## The chunk exposes lane "slots" along its length that the ChunkManager fills.

## Items spawned onto this chunk (kept so we can release them on clear).
var _spawned: Array[Node] = []
@export var ground_mesh: MeshInstance3D


func pool_reset() -> void:
	clear()
	position = Vector3.ZERO


## Attaches a pooled gameplay item at a local position within this chunk.
func add_item(item: Node3D, local_pos: Vector3) -> void:
	add_child(item)
	item.position = local_pos
	_spawned.append(item)


## Releases every spawned item back to the pool and empties the chunk.
func clear() -> void:
	for item in _spawned:
		if is_instance_valid(item):
			PoolManager.release(item)
	_spawned.clear()


## Returns the number of live items on this chunk (used by tests/metrics).
func item_count() -> int:
	return _spawned.size()
