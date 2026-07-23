# Architecture

This document describes the high-level structure of Neon Dash and how the
pieces fit together. For rationale on specific technical choices see
[TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md); for gameplay balance see
[GAME_DESIGN.md](GAME_DESIGN.md).

## Guiding principles

1. **Offline-first.** No networking, no accounts, no backend. Everything runs
   and persists on-device.
2. **Decoupling via signals.** Systems communicate through a global `EventBus`
   rather than holding references to each other. This keeps managers and
   gameplay nodes independently testable and replaceable.
3. **No per-frame allocations.** All frequently spawned entities are pooled.
   A steady-state run allocates nothing, which is essential for stable frame
   times on low-end Android.
4. **Data-driven content.** Characters, skins, achievements and missions are
   described as data, so extending content rarely requires new code paths.
5. **Config over constants-in-code.** Tunable values live in `Constants.gd`.

## Layered view

```
┌─────────────────────────────────────────────────────────────┐
│                          UI Layer                            │
│  Splash · Loading · MainMenu · Settings · Store · HUD · ...  │
└───────────────▲───────────────────────────────▲─────────────┘
                │ reads state / calls            │ listens
                │                                │
┌───────────────┴───────────────────────────────┴─────────────┐
│                      Autoload Managers                       │
│  GameManager · SaveManager · SettingsManager · AudioManager  │
│  Statistics · Achievements · Missions · DailyReward · Pool   │
│  SceneRouter · Localization · Constants                      │
└───────────────▲───────────────────────────────▲─────────────┘
                │            EventBus            │
                │   (global signal hub, no       │
                │    direct cross-references)     │
┌───────────────┴───────────────────────────────┴─────────────┐
│                       Gameplay Layer                         │
│  GameController · Player · ChunkManager · Chunk              │
│  Obstacle · Collectible · PowerUp(Pickup/Controller)         │
│  CameraRig · TouchInput                                      │
└──────────────────────────────────────────────────────────────┘
```

## Autoloads (singletons)

Registered in `project.godot`, loaded in dependency order:

| Autoload | Responsibility |
|---|---|
| `Constants` | Central tunable values + helper math (lanes, difficulty). |
| `EventBus` | Global signals; the only cross-system communication channel. |
| `Localization` | Loads `translations.csv` at runtime; registers translations. |
| `SaveManager` | Persistent profile; atomic save with backup + corruption recovery. |
| `SettingsManager` | User preferences; applies audio bus volumes + locale. |
| `AudioManager` | Music cross-fade, pooled SFX voices, haptics. |
| `GameManager` | Run lifecycle + scoring authority. |
| `PoolManager` | Generic object pool for spawned scenes. |
| `AchievementManager` | Achievement catalogue + progress evaluation. |
| `MissionManager` | Daily mission generation + tracking. |
| `StatisticsManager` | Lifetime counters feeding UI + achievements/missions. |
| `DailyRewardManager` | Offline daily-login streak rewards. |
| `SceneRouter` | Fade transitions + scene navigation. |

## Runtime flow

1. **Boot** — `Splash` → `Loading` (threaded pre-warm of gameplay scenes) →
   `MainMenu`.
2. **Play** — `MainMenu` routes to `Game.tscn`. `GameController` starts the run
   through `GameManager.start_run()`.
3. **Frame loop** — `ChunkManager._physics_process` asks `GameManager.advance()`
   for the distance travelled this frame, scrolls all chunks toward the player,
   recycles chunks that fall behind, and spawns new ones ahead. The `Player`
   handles lane changes, jumps and slides. Collisions are reported by obstacle
   `Area3D` callbacks.
4. **Game over** — `GameManager.end_run()` commits currency and stats to the
   save, emits `run_ended`, and `GameOverMenu` shows the result.

## The scrolling model

The player stays near the world origin. The **world moves toward the player**:
each chunk is translated on +Z each frame by the current speed. When a chunk
passes behind the player it is cleared (its pooled contents returned) and a new
chunk is spawned at the far end. This keeps the player's transform simple and
makes collision volumes stationary relative to the camera.

## Testing seams

Because systems talk through the `EventBus` and logic lives in small,
dependency-light classes (`UnlockService`, `Constants`, manager methods),
most behaviour is unit-testable without stepping physics. Scene integrity is
guarded by an integration smoke test that instantiates every `.tscn`.
See [TESTING.md](TESTING.md).
