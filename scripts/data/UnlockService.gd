extends RefCounted
class_name UnlockService
## UnlockService
##
## Pure logic for unlocking and selecting characters/skins against the player's
## currency in SaveManager. Kept static and side-effect-light so it is trivially
## unit-testable. UI screens call these methods and react to the returned
## result and the currency/unlock signals emitted via the EventBus.

enum Result { SUCCESS, ALREADY_OWNED, INSUFFICIENT_FUNDS, NOT_FOUND }


static func is_character_unlocked(id: String) -> bool:
	return id in SaveManager.data.get("unlocked_characters", [])


static func is_skin_unlocked(id: String) -> bool:
	return id in SaveManager.data.get("unlocked_skins", [])


## Attempts to purchase a character. Returns a Result enum value.
static func unlock_character(id: String) -> Result:
	var def := Catalog.find_character(id)
	if def.is_empty():
		return Result.NOT_FOUND
	if is_character_unlocked(id):
		return Result.ALREADY_OWNED
	return _purchase(def, "unlocked_characters", func(): EventBus.character_unlocked.emit(id))


static func unlock_skin(id: String) -> Result:
	var def := Catalog.find_skin(id)
	if def.is_empty():
		return Result.NOT_FOUND
	if is_skin_unlocked(id):
		return Result.ALREADY_OWNED
	return _purchase(def, "unlocked_skins", func(): EventBus.skin_unlocked.emit(id))


static func select_character(id: String) -> bool:
	if not is_character_unlocked(id):
		return false
	SaveManager.data["selected_character"] = id
	SaveManager.mark_dirty()
	EventBus.character_selected.emit(id)
	return true


static func select_skin(id: String) -> bool:
	if not is_skin_unlocked(id):
		return false
	SaveManager.data["selected_skin"] = id
	SaveManager.mark_dirty()
	return true


## Shared purchase path: checks funds, debits, records the unlock, notifies.
static func _purchase(def: Dictionary, list_key: String, on_success: Callable) -> Result:
	var cost_coins := int(def.get("cost_coins", 0))
	var cost_gems := int(def.get("cost_gems", 0))
	if cost_gems > 0:
		if SaveManager.get_gems() < cost_gems:
			return Result.INSUFFICIENT_FUNDS
		SaveManager.spend_gems(cost_gems)
	else:
		if SaveManager.get_coins() < cost_coins:
			return Result.INSUFFICIENT_FUNDS
		SaveManager.spend_coins(cost_coins)
	var list: Array = SaveManager.data.get(list_key, [])
	list.append(def["id"])
	SaveManager.data[list_key] = list
	SaveManager.mark_dirty()
	AudioManager.play_sfx("unlock")
	on_success.call()
	return Result.SUCCESS
