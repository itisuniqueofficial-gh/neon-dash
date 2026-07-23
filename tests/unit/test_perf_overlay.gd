extends GutTest
## Unit test for the PerfOverlay autoload: its visibility tracks the `show_fps`
## setting live.

var _prev: bool


func before_each() -> void:
	_prev = bool(SettingsManager.get_value("show_fps", false))


func after_each() -> void:
	SettingsManager.set_value("show_fps", _prev)


func test_overlay_follows_show_fps_setting() -> void:
	SettingsManager.set_value("show_fps", true)
	assert_true(PerfOverlay.visible, "Overlay shows when show_fps is enabled")
	SettingsManager.set_value("show_fps", false)
	assert_false(PerfOverlay.visible, "Overlay hides when show_fps is disabled")
