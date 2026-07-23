extends GutTest
## Unit tests for SettingsManager: defaults, get/set and volume application.

var _backup: Dictionary


func before_each() -> void:
	_backup = SettingsManager.settings.duplicate(true)
	SettingsManager.settings = SettingsManager.default_settings()


func after_each() -> void:
	SettingsManager.settings = _backup
	SettingsManager.apply_all()


func test_defaults_present() -> void:
	var d := SettingsManager.default_settings()
	assert_has(d, "music_volume")
	assert_has(d, "vibration")
	assert_has(d, "locale")


func test_set_and_get_value() -> void:
	SettingsManager.set_value("music_volume", 0.5)
	assert_almost_eq(float(SettingsManager.get_value("music_volume")), 0.5, 0.001)


func test_vibration_toggle_reflected_in_helper() -> void:
	SettingsManager.set_value("vibration", false)
	assert_false(SettingsManager.is_vibration_enabled())
	SettingsManager.set_value("vibration", true)
	assert_true(SettingsManager.is_vibration_enabled())


func test_screen_shake_helper() -> void:
	SettingsManager.set_value("screen_shake", false)
	assert_false(SettingsManager.is_screen_shake_enabled())


func test_unknown_key_returns_fallback() -> void:
	assert_eq(SettingsManager.get_value("does_not_exist", 42), 42)
