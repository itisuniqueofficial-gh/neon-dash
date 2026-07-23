extends Node
## SettingsManager
##
## Owns user preferences that are distinct from gameplay progress: audio
## volumes, mute flags, vibration, control scheme, graphics quality and locale.
## Persisted to its own file (separate from the save profile) so settings and
## progress can be reset independently. Applies audio bus volumes immediately
## on change.
##
## Registered as the `SettingsManager` autoload.

var settings: Dictionary = {}


func default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"music_muted": false,
		"sfx_muted": false,
		"vibration": true,
		"screen_shake": true,
		"show_fps": false,
		"high_contrast": false,
		"control_scheme": "swipe",   # "swipe" | "buttons" | "tilt"
		"graphics_quality": "auto",  # "low" | "high" | "auto"
		"locale": "en",
	}


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings() -> void:
	settings = default_settings()
	if FileAccess.file_exists(Constants.SETTINGS_PATH):
		var f := FileAccess.open(Constants.SETTINGS_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				for key in parsed.keys():
					if settings.has(key):
						settings[key] = parsed[key]


func save_settings() -> void:
	var f := FileAccess.open(Constants.SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SettingsManager: failed to write settings file.")
		return
	f.store_string(JSON.stringify(settings, "\t"))
	f.close()


func get_value(key: String, fallback: Variant = null) -> Variant:
	return settings.get(key, fallback)


## Sets a setting, applies its side effect, persists, and broadcasts the change.
func set_value(key: String, value: Variant) -> void:
	if not settings.has(key):
		push_warning("SettingsManager: unknown setting '%s'" % key)
	settings[key] = value
	_apply_one(key)
	save_settings()
	EventBus.settings_changed.emit(key, value)
	if key == "locale":
		EventBus.locale_changed.emit(value)


## Applies every setting to the engine (called at boot).
func apply_all() -> void:
	for key in settings.keys():
		_apply_one(key)


func _apply_one(key: String) -> void:
	match key:
		"master_volume":
			_set_bus_volume(Constants.BUS_MASTER, settings[key], false)
		"music_volume":
			_set_bus_volume(Constants.BUS_MUSIC, settings[key], settings.get("music_muted", false))
		"sfx_volume":
			_set_bus_volume(Constants.BUS_SFX, settings[key], settings.get("sfx_muted", false))
		"music_muted":
			_set_bus_volume(Constants.BUS_MUSIC, settings.get("music_volume", 1.0), settings[key])
		"sfx_muted":
			_set_bus_volume(Constants.BUS_SFX, settings.get("sfx_volume", 1.0), settings[key])
		"locale":
			TranslationServer.set_locale(String(settings[key]))


## Converts a 0..1 linear volume into decibels and applies it to an audio bus.
func _set_bus_volume(bus_name: String, linear: float, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, muted or linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))


func is_vibration_enabled() -> bool:
	return bool(settings.get("vibration", true))


func is_screen_shake_enabled() -> bool:
	return bool(settings.get("screen_shake", true))
