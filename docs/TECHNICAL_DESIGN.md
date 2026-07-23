# Technical Design

Detailed technical decisions and their rationale. Complements
[ARCHITECTURE.md](ARCHITECTURE.md).

## Engine & rendering

- **Godot 4.3**, Forward+ renderer on desktop with the **Mobile** renderer used
  on Android (`renderer/rendering_method.mobile="mobile"`). The Mobile backend
  is tuned for tile-based mobile GPUs and keeps bandwidth low.
- **ETC2/ASTC** VRAM texture compression enabled for Android.
- **Landscape** orientation, `canvas_items` stretch with `expand` aspect so the
  UI scales cleanly across phone aspect ratios.

## Persistence

- Save data is JSON at `user://savegame.json`. JSON (not binary) is chosen for
  debuggability and forward-compatibility.
- **Atomic writes:** we write to `savegame.json.tmp`, validate it parses, then
  rename it over the real file. The previous file is first copied to
  `savegame.bak.json`. A crash mid-write therefore never corrupts the live save.
- **Corruption recovery:** on load, a failed parse falls back to the backup,
  then to a fresh default profile — the game never fails to start.
- **Schema migration:** `format_version` gates migrations; missing keys are
  backfilled from `default_data()` so older saves keep working.
- **Autosave:** dirty state is flushed every 15 s and on
  `WM_CLOSE_REQUEST`/`APPLICATION_PAUSED` (Android task switch) so progress
  survives the app being backgrounded.

Settings live in a separate `settings.json` so preferences and progress reset
independently.

## Object pooling

`PoolManager` is a generic pool keyed by scene path. Pooled nodes may implement
`pool_reset()` to restore clean state on release. Inactive instances are parked
in a detached container with `PROCESS_MODE_DISABLED` so they neither render nor
process. Pools are pre-warmed at run start (`ChunkManager._prewarm_pools`) so
the first seconds of a run don't allocate. This is the single most important
performance decision for holding 60 FPS on low-end hardware.

## World streaming

- Chunks are fixed-length (`CHUNK_LENGTH`) `Node3D` segments.
- A rolling window of `CHUNKS_AHEAD` chunks is kept live; chunks more than
  `CHUNKS_BEHIND` behind the player are recycled.
- Obstacles/collectibles are children of their chunk, so recycling a chunk
  releases all of its contents in one place (`Chunk.clear()`).
- **Fairness guarantee:** the populator never blocks all three lanes in a row
  (`_pick_blocked_lanes` always leaves ≥1 open lane), so every generated layout
  is solvable.

## Input abstraction

Player intents (`move_left`, `move_right`, `jump`, `slide`) are public methods.
- **Desktop/CI:** keyboard actions in `Player._read_input()`.
- **Android:** `TouchInput` converts swipes/taps into the same intents; the HUD
  optionally shows on-screen buttons for the "buttons" control scheme.

This means the same gameplay code is exercised by unit tests (which call the
intent methods directly) and by both input methods.

## Scoring & difficulty

- Score = `distance * SCORE_PER_METER + coins * SCORE_PER_COIN + gems * SCORE_PER_GEM`.
- Speed accelerates from `PLAYER_START_SPEED` toward `PLAYER_MAX_SPEED`.
- Difficulty tier is a function of distance; it shrinks the obstacle gap and
  allows more lanes to be blocked at higher tiers.

## Audio

`AudioManager` owns one music player (with tween-based cross-fade) and a small
ring of SFX voices to avoid per-shot node allocation. Streams are resolved by
logical name and cached; a missing stream degrades to a no-op so development
never blocks on absent audio files. Bus volumes are driven by `SettingsManager`
via `linear_to_db`.

## Localization

Translations load at **runtime** from `localization/translations.csv` into
`Translation` objects registered with `TranslationServer`. This avoids the
editor-only `.translation` import step, keeping the project fully buildable from
source in CI. UI strings use `tr("KEY")`.

## Coding standards

- One class per file; `class_name` where the type is referenced elsewhere.
- Every script has a top-of-file doc comment describing its responsibility.
- No magic numbers in gameplay code — use `Constants`.
- Prefer signals over direct references across system boundaries.
- Static typing throughout for editor checks and performance.
