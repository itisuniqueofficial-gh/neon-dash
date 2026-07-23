# Testing

Neon Dash uses the [GUT](https://github.com/bitwes/Gut) (Godot Unit Test)
framework. Tests live in `tests/` and are split into three suites.

## Layout

```
tests/
  unit/          Fast, isolated logic tests (no physics stepping)
  integration/   Cross-system tests + scene-load smoke test
  performance/   Pooling throughput + leak guards
```

## Running tests

GUT is installed into `addons/gut/` (CI clones it automatically; locally,
install it via the Asset Library or `git clone`):

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

The runner exits non-zero if any test fails, so it doubles as a CI gate.
Configuration is in `.gutconfig.json`.

## What is covered

| Area (required) | Test file |
|---|---|
| Player | `unit/test_player.gd` |
| Obstacle spawning | `integration/test_spawning.gd` |
| Coin collection | `integration/test_collision.gd` |
| Save system (+ corruption recovery) | `unit/test_save_manager.gd` |
| Settings | `unit/test_settings_manager.gd` |
| Collision | `integration/test_collision.gd` |
| Scoring | `unit/test_scoring.gd` |
| Loading (all scenes instantiate) | `integration/test_scene_loading.gd` |
| Performance | `performance/test_performance.gd` |

Additional coverage: `test_constants.gd`, `test_pool_manager.gd`,
`test_unlock_service.gd`, `test_daily_reward.gd`, `test_achievements.gd`.

## Testing philosophy

- **No flaky physics in CI.** Collision/collection tests call the overlap
  callbacks directly with a stand-in player in the `"player"` group, so results
  are deterministic without stepping the physics server.
- **Scene integrity as a first-class check.** `test_scene_loading.gd`
  instantiates every `.tscn`. Because we author scenes as text without opening
  the editor, this is the primary guard against broken scene/script wiring.
- **State isolation.** Tests that mutate the global save/settings snapshot and
  restore them in `before_each`/`after_each`, and always unpause the tree.

## Writing a new test

```gdscript
extends GutTest

func test_something() -> void:
    assert_eq(2 + 2, 4)
```

Prefix files with `test_` and methods with `test_`. Use `before_each` /
`after_each` to isolate state. Prefer asserting on `EventBus` signals
(`watch_signals` / `assert_signal_emitted`) to verify cross-system behaviour.
