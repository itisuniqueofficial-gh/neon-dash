extends Node
## AudioManager
##
## Central audio playback service. Provides:
##   - A single music player with cross-fade between tracks.
##   - A small pool of reusable SFX players so overlapping sounds don't
##     allocate new nodes during gameplay.
##   - Vibration (haptics) on Android, gated by the user setting.
##
## Sounds are referenced by logical name; the actual stream is resolved from
## `_sfx_library` / `_music_library`. Missing streams degrade gracefully to a
## no-op so the game never crashes on a missing asset during development.
##
## Registered as the `AudioManager` autoload.

const SFX_VOICES: int = 8
const MUSIC_FADE_TIME: float = 1.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _current_music_name: String = ""

# Logical name -> resource path. Paths are lazily loaded and cached.
var _sfx_library: Dictionary = {
	"coin": "res://assets/audio/sfx/coin.wav",
	"gem": "res://assets/audio/sfx/gem.wav",
	"jump": "res://assets/audio/sfx/jump.wav",
	"slide": "res://assets/audio/sfx/slide.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"powerup": "res://assets/audio/sfx/powerup.wav",
	"button": "res://assets/audio/sfx/button.wav",
	"unlock": "res://assets/audio/sfx/unlock.wav",
	"gameover": "res://assets/audio/sfx/gameover.wav",
}
var _music_library: Dictionary = {
	"menu": "res://assets/audio/music/menu.ogg",
	"gameplay": "res://assets/audio/music/gameplay.ogg",
}
var _stream_cache: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = Constants.BUS_MUSIC
	add_child(_music_player)

	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = Constants.BUS_SFX
		add_child(p)
		_sfx_players.append(p)


## Plays a one-shot sound effect by logical name using the next free voice.
func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	var stream := _resolve(_sfx_library, sfx_name)
	if stream == null:
		return
	var player := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


## Plays music, cross-fading from any currently playing track. No-op if the
## requested track is already playing.
func play_music(music_name: String) -> void:
	if music_name == _current_music_name and _music_player.playing:
		return
	var stream := _resolve(_music_library, music_name)
	if stream == null:
		return
	_current_music_name = music_name
	if stream is AudioStream:
		(stream as AudioStream).set("loop", true)
	if _music_player.playing:
		_fade_to(stream)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()


## Fades the current music out over `MUSIC_FADE_TIME` and stops.
func stop_music() -> void:
	if not _music_player.playing:
		return
	_current_music_name = ""
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_TIME)
	tween.tween_callback(_music_player.stop)


## Triggers device vibration for `ms` milliseconds if vibration is enabled.
func vibrate(ms: int = 40) -> void:
	if not SettingsManager.is_vibration_enabled():
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _fade_to(new_stream: AudioStream) -> void:
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_TIME * 0.5)
	tween.tween_callback(func() -> void:
		_music_player.stream = new_stream
		_music_player.play())
	tween.tween_property(_music_player, "volume_db", 0.0, MUSIC_FADE_TIME * 0.5)


## Resolves a logical name to a cached AudioStream, or null if unavailable.
func _resolve(library: Dictionary, key: String) -> AudioStream:
	if not library.has(key):
		return null
	var path: String = library[key]
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path)
	if res is AudioStream:
		_stream_cache[path] = res
		return res
	return null
