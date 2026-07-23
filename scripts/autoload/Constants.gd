extends Node
## Constants
##
## Central, single source of truth for all tunable game values. No gameplay
## script should hardcode numbers that belong here. Grouped by domain to keep
## the file navigable. Values are documented inline; see
## docs/GAME_DESIGN.md for the rationale behind balance numbers.
##
## This is an autoload (singleton) registered as `Constants` in project.godot.

# --- Meta -------------------------------------------------------------------
const GAME_TITLE: String = "Neon Dash"
const GAME_VERSION: String = "0.1.0"
const SAVE_FORMAT_VERSION: int = 1

# --- Lanes ------------------------------------------------------------------
## Three-lane runner. Lane 0 is left, 1 is center, 2 is right.
const LANE_COUNT: int = 3
const LANE_WIDTH: float = 3.0            ## World units between lane centers.
const LANE_CHANGE_SPEED: float = 14.0    ## How fast the player lerps between lanes.

# --- Player movement --------------------------------------------------------
const GRAVITY: float = 55.0
const JUMP_VELOCITY: float = 18.0
const SLIDE_DURATION: float = 0.7        ## Seconds the slide pose lasts.
const PLAYER_START_SPEED: float = 12.0   ## Forward units/second at run start.
const PLAYER_MAX_SPEED: float = 34.0
const PLAYER_ACCELERATION: float = 0.35  ## Units/second added per second.
const COYOTE_TIME: float = 0.10          ## Grace window to still jump after leaving ground.
const JUMP_BUFFER_TIME: float = 0.12     ## Buffer an early jump press.

# --- Difficulty scaling -----------------------------------------------------
## Difficulty ramps with distance. Obstacle density and speed both scale.
const DIFFICULTY_DISTANCE_STEP: float = 500.0  ## Distance per difficulty tier.
const MAX_DIFFICULTY_TIER: int = 12
const OBSTACLE_BASE_GAP: float = 18.0    ## Min world units between obstacle rows at tier 0.
const OBSTACLE_MIN_GAP: float = 7.0      ## Floor gap at max tier.

# --- World / chunks ---------------------------------------------------------
const CHUNK_LENGTH: float = 30.0         ## World units per chunk.
const CHUNKS_AHEAD: int = 6              ## Chunks kept spawned ahead of player.
const CHUNKS_BEHIND: int = 2             ## Chunks kept behind before recycling.
const CHUNK_POOL_SIZE: int = 12

# --- Collectibles -----------------------------------------------------------
const COIN_VALUE: int = 1
const GEM_VALUE: int = 1
const COIN_MAGNET_RADIUS: float = 5.0
const COIN_POOL_SIZE: int = 64
const OBSTACLE_POOL_SIZE: int = 48

# --- Power-ups --------------------------------------------------------------
enum PowerUp { NONE, MAGNET, SHIELD, DOUBLE_COINS, SPEED_BOOST, HEAD_START }
const POWERUP_MAGNET_DURATION: float = 8.0
const POWERUP_SHIELD_DURATION: float = 6.0
const POWERUP_DOUBLE_COINS_DURATION: float = 10.0
const POWERUP_SPEED_BOOST_DURATION: float = 5.0
const POWERUP_SPEED_BOOST_MULTIPLIER: float = 1.6

# --- Scoring ----------------------------------------------------------------
## Distance contributes to score continuously; coins/gems add discrete points.
const SCORE_PER_METER: float = 1.0
const SCORE_PER_COIN: int = 10
const SCORE_PER_GEM: int = 50

# --- Economy ----------------------------------------------------------------
const GEM_TO_COIN_RATE: int = 100       ## 1 gem == 100 coins of purchasing power.
const DAILY_REWARD_BASE: int = 50       ## Coins on day 1 of the streak.
const DAILY_REWARD_STEP: int = 25       ## Extra coins per consecutive day.
const DAILY_REWARD_MAX_DAY: int = 7

# --- Camera -----------------------------------------------------------------
const CAMERA_SHAKE_DECAY: float = 5.0
const CAMERA_SHAKE_MAX_OFFSET: float = 0.6
const CAMERA_SHAKE_MAX_ROLL: float = 0.08

# --- Persistence paths ------------------------------------------------------
const SAVE_PATH: String = "user://savegame.json"
const SAVE_BACKUP_PATH: String = "user://savegame.bak.json"
const SETTINGS_PATH: String = "user://settings.json"

# --- Physics layers (bit values, mirror project.godot layer_names) ----------
const LAYER_PLAYER: int = 1 << 0
const LAYER_OBSTACLE: int = 1 << 1
const LAYER_COLLECTIBLE: int = 1 << 2
const LAYER_GROUND: int = 1 << 3
const LAYER_POWERUP: int = 1 << 4

# --- Scene routes -----------------------------------------------------------
const SCENE_SPLASH: String = "res://scenes/boot/Splash.tscn"
const SCENE_LOADING: String = "res://scenes/boot/Loading.tscn"
const SCENE_MAIN_MENU: String = "res://scenes/ui/MainMenu.tscn"
const SCENE_GAME: String = "res://scenes/game/Game.tscn"
const SCENE_SETTINGS: String = "res://scenes/ui/Settings.tscn"
const SCENE_CHARACTER_SELECT: String = "res://scenes/ui/CharacterSelect.tscn"
const SCENE_ACHIEVEMENTS: String = "res://scenes/ui/Achievements.tscn"
const SCENE_STATISTICS: String = "res://scenes/ui/Statistics.tscn"
const SCENE_STORE: String = "res://scenes/ui/Store.tscn"
const SCENE_CREDITS: String = "res://scenes/ui/Credits.tscn"

# --- Audio bus names --------------------------------------------------------
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"


## Returns the world-space X coordinate for a given lane index.
func lane_to_x(lane_index: int) -> float:
	var clamped := clampi(lane_index, 0, LANE_COUNT - 1)
	var center := float(LANE_COUNT - 1) / 2.0
	return (float(clamped) - center) * LANE_WIDTH


## Computes the current difficulty tier (0..MAX) from distance travelled.
func difficulty_tier(distance: float) -> int:
	return clampi(int(distance / DIFFICULTY_DISTANCE_STEP), 0, MAX_DIFFICULTY_TIER)


## Returns the obstacle gap (world units) for a given difficulty tier.
func obstacle_gap_for_tier(tier: int) -> float:
	var t := clampi(tier, 0, MAX_DIFFICULTY_TIER)
	var factor := float(t) / float(MAX_DIFFICULTY_TIER)
	return lerpf(OBSTACLE_BASE_GAP, OBSTACLE_MIN_GAP, factor)
