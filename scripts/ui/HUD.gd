extends CanvasLayer
class_name HUD
## HUD
##
## In-game heads-up display. Shows live score, distance, coin/gem counts, the
## active power-up indicator and (on touch devices) optional on-screen control
## buttons. It is a pure view: it only listens to EventBus signals and never
## mutates game state, except forwarding button presses to the player.

@export var score_label: Label
@export var distance_label: Label
@export var coins_label: Label
@export var powerup_bar: ProgressBar
@export var buttons_container: Control
@export var player_path: NodePath

var _player: Player
var _powerup_total: float = 0.0
var _powerup_type: int = Constants.PowerUp.NONE


func _ready() -> void:
	_player = get_node_or_null(player_path)
	EventBus.score_updated.connect(_on_score)
	EventBus.distance_updated.connect(_on_distance)
	EventBus.coin_collected.connect(_on_coin)
	EventBus.gem_collected.connect(_on_gem)
	EventBus.powerup_activated.connect(_on_powerup_activated)
	EventBus.powerup_expired.connect(_on_powerup_expired)
	# Only show touch buttons on mobile with the "buttons" scheme.
	if buttons_container:
		var use_buttons := OS.has_feature("mobile") \
			and SettingsManager.get_value("control_scheme") == "buttons"
		buttons_container.visible = use_buttons
	if powerup_bar:
		powerup_bar.visible = false
	_refresh_currency()


func _process(_delta: float) -> void:
	if _powerup_type != Constants.PowerUp.NONE and powerup_bar and powerup_bar.visible:
		powerup_bar.value = maxf(0.0, powerup_bar.value - _delta_ratio())


func _delta_ratio() -> float:
	return 0.0  # progress is set from PowerUpController via _on_powerup_activated tween


func _on_score(score: int) -> void:
	if score_label:
		score_label.text = tr("SCORE") + ": " + str(score)


func _on_distance(distance: float) -> void:
	if distance_label:
		distance_label.text = str(int(distance)) + " m"


func _on_coin(_amount: int, _total: int) -> void:
	_refresh_currency()


func _on_gem(_amount: int, _total: int) -> void:
	_refresh_currency()


func _refresh_currency() -> void:
	if coins_label:
		coins_label.text = str(GameManager.run_coins) + " / " + str(GameManager.run_gems) + " ◆"


func _on_powerup_activated(type: int, duration: float) -> void:
	_powerup_type = type
	_powerup_total = duration
	if powerup_bar:
		powerup_bar.visible = true
		powerup_bar.max_value = duration
		powerup_bar.value = duration
		var tween := create_tween()
		tween.tween_property(powerup_bar, "value", 0.0, duration)


func _on_powerup_expired(type: int) -> void:
	if type == _powerup_type:
		_powerup_type = Constants.PowerUp.NONE
		if powerup_bar:
			powerup_bar.visible = false


# --- Touch button handlers (connected in the scene) -------------------------
func _on_left_pressed() -> void:
	if _player: _player.move_left()

func _on_right_pressed() -> void:
	if _player: _player.move_right()

func _on_jump_pressed() -> void:
	if _player: _player.jump()

func _on_slide_pressed() -> void:
	if _player: _player.slide()

func _on_pause_pressed() -> void:
	var gc := get_tree().get_first_node_in_group("game_controller")
	if gc and gc.has_method("toggle_pause"):
		gc.toggle_pause()
