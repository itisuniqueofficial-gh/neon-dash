extends RefCounted
class_name Catalog
## Catalog
##
## Static, data-driven definitions of purchasable/unlockable content
## (characters and skins). Kept as plain dictionaries so the store and
## character-select screens can render and price items without bespoke code.
## In a larger project these would be `.tres` resources under `resources/`;
## they are inlined here so the game is fully functional out of the box.


## Returns the list of character definitions.
static func characters() -> Array:
	return [
		{
			"id": "runner_default",
			"name": "Neon Runner",
			"color": Color(0, 0.9, 1),
			"cost_coins": 0,
			"cost_gems": 0,
			"default": true,
			"desc": "The original neon sprinter."
		},
		{
			"id": "runner_ember",
			"name": "Ember",
			"color": Color(1, 0.4, 0.1),
			"cost_coins": 1500,
			"cost_gems": 0,
			"default": false,
			"desc": "Leaves a trail of sparks."
		},
		{
			"id": "runner_violet",
			"name": "Violet",
			"color": Color(0.7, 0.2, 1),
			"cost_coins": 3000,
			"cost_gems": 0,
			"default": false,
			"desc": "Fast and flashy."
		},
		{
			"id": "runner_aurora",
			"name": "Aurora",
			"color": Color(0.2, 1, 0.6),
			"cost_coins": 0,
			"cost_gems": 25,
			"default": false,
			"desc": "Premium shimmering runner."
		},
		{
			"id": "runner_midnight",
			"name": "Midnight",
			"color": Color(0.3, 0.3, 0.5),
			"cost_coins": 6000,
			"cost_gems": 0,
			"default": false,
			"desc": "Stealthy and sleek."
		},
	]


## Returns the list of skin definitions (colour overrides for the runner).
static func skins() -> Array:
	return [
		{
			"id": "default",
			"name": "Classic",
			"color": Color(0, 0.9, 1),
			"cost_coins": 0,
			"cost_gems": 0,
			"default": true
		},
		{
			"id": "gold",
			"name": "Gold",
			"color": Color(1, 0.84, 0.2),
			"cost_coins": 2000,
			"cost_gems": 0,
			"default": false
		},
		{
			"id": "toxic",
			"name": "Toxic",
			"color": Color(0.5, 1, 0.1),
			"cost_coins": 2500,
			"cost_gems": 0,
			"default": false
		},
		{
			"id": "royal",
			"name": "Royal",
			"color": Color(0.6, 0.1, 0.9),
			"cost_coins": 0,
			"cost_gems": 15,
			"default": false
		},
	]


static func find_character(id: String) -> Dictionary:
	for c in characters():
		if c["id"] == id:
			return c
	return {}


static func find_skin(id: String) -> Dictionary:
	for s in skins():
		if s["id"] == id:
			return s
	return {}
