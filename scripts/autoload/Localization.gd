extends Node
## Localization
##
## Loads UI translations at runtime from `localization/translations.csv` and
## registers them with the TranslationServer. Loading from CSV at runtime (as
## opposed to Godot's editor-compiled `.translation` files) keeps the project
## fully buildable from source in CI without an editor import step, while still
## letting `tr("KEY")` work everywhere.
##
## CSV format (first row is the header):
##   key,en,es,fr,de,pt,hi
##   SCORE,Score,Puntuación,Score,Punktzahl,Pontuação,स्कोर
##
## Registered as the `Localization` autoload; loads before the UI needs it.

const CSV_PATH := "res://localization/translations.csv"

var _translations: Dictionary = {}   ## locale -> Translation


func _ready() -> void:
	_load_csv()
	# Apply the saved locale if settings are available, else default to English.
	var locale := "en"
	if Engine.has_singleton("SettingsManager") or get_node_or_null("/root/SettingsManager"):
		locale = String(SettingsManager.get_value("locale", "en"))
	TranslationServer.set_locale(locale)
	EventBus.locale_changed.connect(func(l): TranslationServer.set_locale(l))


func _load_csv() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		push_warning("Localization: %s not found; using raw keys." % CSV_PATH)
		return
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		return
	var header := f.get_csv_line()
	if header.size() < 2:
		return
	# Create a Translation per locale column.
	for col in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[col].strip_edges()
		_translations[header[col].strip_edges()] = t
	# Populate messages.
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.is_empty() or row[0].strip_edges().is_empty():
			continue
		var key := row[0].strip_edges()
		for col in range(1, mini(row.size(), header.size())):
			var loc := header[col].strip_edges()
			if _translations.has(loc):
				(_translations[loc] as Translation).add_message(key, row[col])
	f.close()
	for loc in _translations.keys():
		TranslationServer.add_translation(_translations[loc])


## Returns the list of locales that have loaded translations.
func available_locales() -> Array:
	return _translations.keys()
