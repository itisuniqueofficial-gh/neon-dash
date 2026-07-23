# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-07-23

### Added

- **Double jump** — one mid-air jump before landing, with its own (slightly
  weaker) impulse and haptic/camera feedback.
- **Dash** — a short forward burst on a cooldown that grants brief
  invulnerability (i-frames); bound to Shift on desktop and a new on-screen
  **DASH** button in the touch "buttons" scheme.
- **New power-ups**: **Slow Motion** (lowers `Engine.time_scale`, always safely
  restored) and **Invincibility** (timed immunity to hits). Both are spawned by
  the world generator.
- **Character/skin appearance** is now applied to the runner mesh in-game, so
  cosmetic unlocks are visible during play.

### Changed

- `PowerUpController` now counts power-up durations in real time so Slow Motion
  no longer extends its own (or others') duration, and guarantees `time_scale`
  is reset on power-up expiry, run end and run start.
- `Player` resolves its mesh/collision node references defensively for
  robustness.

### Compatibility

- Save format unchanged (`format_version` 1); all additions are backward
  compatible. New `PowerUp` enum values are appended, preserving existing
  ordinals.

## [0.1.0] - 2026-07-23

### Added

- **Core gameplay:** three-lane endless runner with automatic forward motion,
  lane switching, jump (coyote time + input buffering) and slide.
- **Procedural world:** chunk-based streaming with object pooling, difficulty
  scaling, and a fairness guarantee that never blocks all lanes.
- **Obstacles:** FULL, JUMP_OVER and SLIDE_UNDER types with near-miss detection.
- **Economy:** coins and gems, corruption-safe local save with atomic writes,
  backup rotation and schema migration.
- **Power-ups:** Magnet, Shield, Double Coins, Speed Boost with timed effects.
- **Progression:** achievements, rotating daily missions, offline daily-reward
  streak, lifetime statistics, unlockable characters and skins via an in-game
  store (soft currency only, no IAP).
- **UI:** Splash, Loading (threaded pre-warm), Main Menu, Settings,
  Character Select, Store, Achievements, Statistics, Credits, HUD, Pause and
  Game Over screens.
- **Audio:** music cross-fade, pooled SFX voices, haptics.
- **Camera:** trauma-based screen shake (respects accessibility setting).
- **Settings:** audio mixing, vibration, screen shake, FPS display, high
  contrast, control scheme and language.
- **Localization:** runtime CSV translations for EN, ES, FR, DE, PT, HI.
- **Tests:** GUT unit/integration/performance suites, including a scene-load
  smoke test and save-corruption recovery test.
- **CI/CD:** GitHub Actions for lint/test/validation and Android APK/AAB build
  with automated release attachment.
- **Docs:** full documentation suite (architecture, technical/game design,
  build, release, testing, contributing, security, roadmap).
- **Android:** export preset and configuration targeting Android 8.0+.

[Unreleased]: https://github.com/itisuniqueofficial-gh/neon-dash/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/itisuniqueofficial-gh/neon-dash/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/itisuniqueofficial-gh/neon-dash/releases/tag/v0.1.0
