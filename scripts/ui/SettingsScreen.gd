extends Control
class_name SettingsScreen
## SettingsScreen
##
## Lets the player adjust audio volumes, toggles (vibration, screen shake,
## FPS display, high contrast), the control scheme and locale. Reads current
## values from SettingsManager on open and writes changes back immediately, so
## every change is persisted and applied without an explicit "save" step.

@export var music_slider: Range
@export var sfx_slider: Range
@export var master_slider: Range
@export var vibration_check: BaseButton
@export var shake_check: BaseButton
@export var fps_check: BaseButton
@export var contrast_check: BaseButton
@export var scheme_option: OptionButton
@export var locale_option: OptionButton


func _ready() -> void:
	_load_into_ui()


func _load_into_ui() -> void:
	if master_slider: master_slider.value = SettingsManager.get_value("master_volume") * 100.0
	if music_slider: music_slider.value = SettingsManager.get_value("music_volume") * 100.0
	if sfx_slider: sfx_slider.value = SettingsManager.get_value("sfx_volume") * 100.0
	if vibration_check: vibration_check.button_pressed = SettingsManager.get_value("vibration")
	if shake_check: shake_check.button_pressed = SettingsManager.get_value("screen_shake")
	if fps_check: fps_check.button_pressed = SettingsManager.get_value("show_fps")
	if contrast_check: contrast_check.button_pressed = SettingsManager.get_value("high_contrast")


func _on_master_changed(v: float) -> void:
	SettingsManager.set_value("master_volume", v / 100.0)

func _on_music_changed(v: float) -> void:
	SettingsManager.set_value("music_volume", v / 100.0)

func _on_sfx_changed(v: float) -> void:
	SettingsManager.set_value("sfx_volume", v / 100.0)
	AudioManager.play_sfx("button")

func _on_vibration_toggled(on: bool) -> void:
	SettingsManager.set_value("vibration", on)

func _on_shake_toggled(on: bool) -> void:
	SettingsManager.set_value("screen_shake", on)

func _on_fps_toggled(on: bool) -> void:
	SettingsManager.set_value("show_fps", on)

func _on_contrast_toggled(on: bool) -> void:
	SettingsManager.set_value("high_contrast", on)

func _on_scheme_selected(index: int) -> void:
	var schemes := ["swipe", "buttons", "tilt"]
	SettingsManager.set_value("control_scheme", schemes[clampi(index, 0, 2)])

func _on_locale_selected(index: int) -> void:
	var locales := ["en", "es", "fr", "de", "pt", "hi"]
	SettingsManager.set_value("locale", locales[clampi(index, 0, locales.size() - 1)])

func _on_reset_pressed() -> void:
	AudioManager.play_sfx("button")
	SettingsManager.settings = SettingsManager.default_settings()
	SettingsManager.apply_all()
	SettingsManager.save_settings()
	_load_into_ui()

func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.goto_main_menu()
