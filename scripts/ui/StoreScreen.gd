extends Control
class_name StoreScreen
## StoreScreen
##
## Offline store for spending earned coins/gems on skins and consumable-style
## boosts. Since the game has no backend or IAP, all purchases use in-game
## currency only. Skins are unlocked via UnlockService; the head-start boost is
## a persistent flag consumed at run start.

@export var list_container: VBoxContainer
@export var coins_label: Label
@export var gems_label: Label


func _ready() -> void:
	EventBus.currency_changed.connect(func(_c, _g): _refresh_header(); _rebuild())
	EventBus.skin_unlocked.connect(func(_id): _rebuild())
	_refresh_header()
	_rebuild()


func _refresh_header() -> void:
	if coins_label: coins_label.text = str(SaveManager.get_coins())
	if gems_label: gems_label.text = str(SaveManager.get_gems())


func _rebuild() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = tr("SKINS")
	list_container.add_child(header)
	for def in Catalog.skins():
		list_container.add_child(_make_skin_row(def))


func _make_skin_row(def: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var swatch := ColorRect.new()
	swatch.color = def["color"]
	swatch.custom_minimum_size = Vector2(48, 48)
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = def["name"]
	name_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_label)

	var id: String = def["id"]
	var btn := Button.new()
	if UnlockService.is_skin_unlocked(id):
		btn.text = tr("OWNED")
		btn.disabled = true
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
	var result := UnlockService.unlock_skin(id)
	if result != UnlockService.Result.SUCCESS:
		AudioManager.play_sfx("button", 0.7)
	_refresh_header()
	_rebuild()


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
