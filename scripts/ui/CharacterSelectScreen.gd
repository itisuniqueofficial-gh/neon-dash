extends Control
class_name CharacterSelectScreen
## CharacterSelectScreen
##
## Lists all characters from the Catalog, showing which are owned, selected, or
## purchasable. Buttons either select an owned character or attempt to buy a
## locked one via UnlockService, then refresh the list. Rows are built at
## runtime so adding a character to the Catalog needs no scene edits.

@export var list_container: VBoxContainer


func _ready() -> void:
	EventBus.character_unlocked.connect(func(_id): _rebuild())
	EventBus.character_selected.connect(func(_id): _rebuild())
	_rebuild()


func _rebuild() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	var selected: String = SaveManager.data.get("selected_character", "runner_default")
	for def in Catalog.characters():
		list_container.add_child(_make_row(def, selected))


func _make_row(def: Dictionary, selected: String) -> Control:
	var row := HBoxContainer.new()
	var swatch := ColorRect.new()
	swatch.color = def["color"]
	swatch.custom_minimum_size = Vector2(48, 48)
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = def["name"]
	name_label.custom_minimum_size = Vector2(180, 0)
	row.add_child(name_label)

	var btn := Button.new()
	var id: String = def["id"]
	if id == selected:
		btn.text = tr("SELECTED")
		btn.disabled = true
	elif UnlockService.is_character_unlocked(id):
		btn.text = tr("SELECT")
		btn.pressed.connect(func(): UnlockService.select_character(id))
	else:
		btn.text = _price_text(def)
		btn.pressed.connect(func(): _try_buy(id))
	row.add_child(btn)
	return row


func _price_text(def: Dictionary) -> String:
	if int(def.get("cost_gems", 0)) > 0:
		return "%d ◆" % int(def["cost_gems"])
	return "%d ⬤" % int(def["cost_coins"])


func _try_buy(id: String) -> void:
	var result := UnlockService.unlock_character(id)
	if result == UnlockService.Result.SUCCESS:
		UnlockService.select_character(id)
	else:
		AudioManager.play_sfx("button", 0.7)
	_rebuild()


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
