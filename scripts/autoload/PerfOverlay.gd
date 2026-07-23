extends CanvasLayer
## PerfOverlay
##
## A lightweight, always-on-top FPS / frame-time overlay, shown only when the
## `show_fps` setting is enabled. It exists for QA and performance work: it is
## visible on every screen (menus and gameplay) and survives pause
## (PROCESS_MODE_ALWAYS). It performs no per-frame allocations — the label text
## is refreshed a few times per second, not every frame.
##
## Registered as the `PerfOverlay` autoload.

const REFRESH_INTERVAL: float = 0.25

var _label: Label
var _accum: float = 0.0


func _ready() -> void:
	layer = 127
	process_mode = Node.PROCESS_MODE_ALWAYS

	_label = Label.new()
	_label.name = "FpsLabel"
	_label.anchor_left = 1.0
	_label.anchor_right = 1.0
	_label.offset_left = -150.0
	_label.offset_top = 4.0
	_label.offset_right = -6.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)

	_apply_visibility()
	EventBus.settings_changed.connect(_on_settings_changed)


func _process(delta: float) -> void:
	if not visible:
		return
	_accum += delta
	if _accum < REFRESH_INTERVAL:
		return
	_accum = 0.0
	var fps := Engine.get_frames_per_second()
	var frame_ms := 1000.0 / maxf(float(fps), 1.0)
	_label.text = "%d FPS  (%.1f ms)" % [fps, frame_ms]


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "show_fps":
		_apply_visibility()


func _apply_visibility() -> void:
	visible = bool(SettingsManager.get_value("show_fps", false))
